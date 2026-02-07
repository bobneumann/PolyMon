# PolyMon Upgrade - Work PC Deployment Guide

## Background
- PolyMon has been in production at work for ~15 years
- Old codebase and embedded PowerShell engine are causing strain
- Code updated on home laptop (this machine), needs to get to work PC
- Work PC cannot reach AI websites
- Remote desktop from home to work: can paste text/images IN, but copying
  text OUT requires screenshotting and reading from the image

---

## 1. PREREQUISITES ON WORK PC

Before deploying, verify/install on the work PC:

### Already there (likely, since PolyMon has been running):
- .NET Framework 4.8 Runtime (comes with Windows 10 1903+)
- SQL Server (whatever instance PolyMon currently uses)
- PolyMon database (existing production data - DO NOT touch yet)

### May need to install for building from source:
- .NET Framework 4.8 Developer Pack (for MSBuild to compile)
  - Download: search "net framework 4.8 developer pack" on Microsoft
  - OR just deploy pre-built binaries (see Option A below)

---

## 2. GETTING THE CODE TO WORK PC

### Option A: Deploy Pre-Built Binaries Only (Simplest)
No build tools needed on work PC. Build at home, transfer binaries.

1. On home laptop, do a clean Release build:
   ```
   MSBuild "PolyMon(CodePlex).sln" /t:Rebuild /p:Configuration=Release
   ```

2. Package these folders into a ZIP:
   ```
   PolyMonManager\bin\          (Manager app + Monitors subfolder)
   PolyMonExecutive\bin\        (Executive service)
   ```
   IMPORTANT: Make sure Executive\bin\ has all the monitor DLLs copied in
   (they don't get copied by the build automatically).

3. Transfer the ZIP to work PC via:
   - Email it to yourself (work email)
   - Upload to OneDrive/SharePoint/network share
   - USB drive if you have physical access
   - Paste a download link into the remote desktop session

### Option B: Transfer Full Source via Git Bundle
If you want the full source + git history on the work PC:

1. On home laptop:
   ```
   cd C:\Users\Bob\Projects\PolyMon-Original
   git bundle create polymon-bundle.git --all
   ```
   This creates a single file with the entire repo + history.

2. Transfer `polymon-bundle.git` to work PC (same methods as above).

3. On work PC:
   ```
   git clone polymon-bundle.git PolyMon-Original
   ```

4. To send incremental updates later:
   ```
   # Home laptop (after new commits):
   git bundle create polymon-update.git <last-deployed-commit>..HEAD

   # Work PC:
   cd PolyMon-Original
   git pull <path-to>\polymon-update.git master
   ```

### Option C: Transfer Source as ZIP (No Git)
1. ZIP the entire `C:\Users\Bob\Projects\PolyMon-Original` folder
   (exclude bin/obj folders to reduce size)
2. Transfer and extract on work PC

---

## 3. DATABASE UPGRADE PLAN

### CRITICAL: Back up the production database first!
```sql
BACKUP DATABASE PolyMon
TO DISK = 'C:\Backups\PolyMon_PreUpgrade_YYYYMMDD.bak'
WITH COMPRESSION;
```

### Check current DB version at work:
```sql
SELECT DBVersion FROM PolyMon..SysSettings
```

### If DB Version is 1.00:
Run: `Update Scripts\Update to DB Version 1.00.sql` (if needed)
Then: `Update Scripts\Update DB 1.00 to 1.10.sql`
Then: `Update Scripts\Update DB 1.10 to 1.30.sql`

### If DB Version is 1.10:
Run: `Update Scripts\Update DB 1.10 to 1.30.sql`

### If DB Version is already 1.30:
No schema changes needed.

### Time-Series Table Update
The TS lookup tables (TSDaily, TSWeekly, TSMonthly) may only go to 2020.
Check with:
```sql
SELECT MAX(DT) FROM TSDaily
SELECT MAX(EndDT) FROM TSWeekly
SELECT MAX(EndDT) FROM TSMonthly
```

If they stop at 2020, run the TS generation block from
`DB Version 1.30.sql` (lines ~6680-6783) with `@EndDT = '2035-12-31'`.
This block is idempotent - it deletes and regenerates all TS rows.
NOTE: Only do this during a maintenance window as it briefly clears TS tables.

---

## 4. DEPLOYMENT STEPS (AT WORK)

### Step 1: Preparation
- [ ] Back up the production PolyMon database
- [ ] Note the current SQL Server instance name (may differ from .\SQLEXPRESS)
- [ ] Note the current PolyMon install paths
- [ ] Export current monitor definitions (screenshot or query):
      ```sql
      SELECT MonitorID, Name, MonitorTypeID, IsEnabled, TriggerMod
      FROM Monitor ORDER BY Name
      ```
- [ ] Document the current PolyMonExecutive service account and startup type:
      ```
      sc qc PolyMonExecutive
      ```

### Step 2: Update Connection Strings
The config files are set for home laptop (.\SQLEXPRESS). Update for work:

**PolyMonManager\bin\PolyMonManager.exe.config:**
```xml
<add key="SQLConn" value="Data Source=YOUR_WORK_SQL_INSTANCE;Initial Catalog=PolyMon; Integrated Security=SSPI;"/>
```

**PolyMonExecutive\bin\PolyMonExecutive.exe.config:**
```xml
<add key="SQLConn" value="Data Source=YOUR_WORK_SQL_INSTANCE;Initial Catalog=PolyMon; Integrated Security=SSPI;"/>
```

### Step 3: Test with Manager First
1. Stop the OLD PolyMonExecutive service:
   ```
   net stop PolyMonExecutive
   ```
2. Run the NEW PolyMonManager.exe
3. Verify it connects and shows all existing monitors
4. Test a monitor using the Test tab
5. If anything is wrong, you can still fall back to the old version

### Step 4: Deploy Executive Service
1. Uninstall the OLD service (from old install path):
   ```
   C:\Windows\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe /u <OLD_PATH>\PolyMonExecutive.exe
   ```
2. Copy new Executive files to the production path
3. Make sure all monitor DLLs are in the Executive folder:
   - PingMonitor.dll, URLMonitor.dll, ServiceMonitor.dll,
     SQLMonitor.dll, WMIMonitor.dll, CPUMonitor.dll,
     DiskMonitor.dll, FileMonitor.dll, PerfMonitor.dll,
     SNMPMonitor.dll, TCPPortMonitor.dll, PowerShellMonitor.dll,
     URLXMLMonitor.dll, SNMP.dll, GenericMonitor.dll
4. Install new service:
   ```
   C:\Windows\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe <NEW_PATH>\PolyMonExecutive.exe
   ```
5. Configure the service account (if not LocalSystem):
   ```
   sc config PolyMonExecutive obj= "DOMAIN\ServiceAccount" password= "***"
   ```
6. Start the service:
   ```
   net start PolyMonExecutive
   ```

### Step 5: Verify
- Check Windows Event Log > PolyMon for startup messages
- Check the database for new MonitorEvent entries:
  ```sql
  SELECT TOP 10 e.EventID, m.Name, e.EventDT, s.Status
  FROM MonitorEvent e
  JOIN Monitor m ON e.MonitorID = m.MonitorID
  JOIN LookupEventStatus s ON e.StatusID = s.StatusID
  ORDER BY e.EventDT DESC
  ```
- Monitor for a full cycle (check MainTimerInterval in SysSettings)

---

## 5. ROLLBACK PLAN

If something goes wrong:

1. Stop the new PolyMonExecutive service
2. Uninstall it with InstallUtil /u
3. Restore the old PolyMonExecutive from backup
4. Reinstall and start the old service
5. If DB was modified, restore from backup:
   ```sql
   USE master;
   ALTER DATABASE PolyMon SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
   RESTORE DATABASE PolyMon FROM DISK = 'C:\Backups\PolyMon_PreUpgrade_YYYYMMDD.bak'
   WITH REPLACE;
   ALTER DATABASE PolyMon SET MULTI_USER;
   ```

---

## 6. KNOWN ISSUES / THINGS FIXED IN THIS UPDATE

| Issue | Fix Applied |
|-------|-------------|
| EventLog.SourceExists() crashes without admin | Wrapped in try-catch in MonitorExecutor.vb |
| Connection strings pointed to dev machines | Updated to .\SQLEXPRESS (update again for work) |
| supportedRuntime was v4.5 | Updated to v4.8 |
| TS lookup tables end at 2020 | Extended to 2035 in deploy script |

---

## 7. COMMUNICATING WITH CLAUDE FROM WORK

Since the work PC can't reach AI websites:

### Sending info TO Claude (from work):
1. Screenshot the work PC screen (error messages, config files, etc.)
2. The screenshot is on your HOME desktop (since you're in remote desktop)
3. Share the screenshot path with Claude on your home machine

### Getting instructions FROM Claude to work PC:
1. Claude outputs text on your home terminal
2. Select and copy the text
3. Paste it into Notepad/PowerShell on the remote work PC

### Transferring files:
- Use the remote desktop clipboard for small text
- For larger files, use email/OneDrive/network shares

---

## 8. FUTURE: PHASE 3 MODERNIZATION

After the current version is stable at work, Phase 3 goals include:
- Update embedded PowerShell engine (the main driver for this project)
- Modernize the codebase
- Details TBD - will plan in a future session

---

## Quick Reference

| Item | Home Laptop | Work PC |
|------|-------------|---------|
| Project Path | C:\Users\Bob\Projects\PolyMon-Original | TBD |
| SQL Instance | .\SQLEXPRESS | TBD - check existing config |
| Database | PolyMon | PolyMon |
| Git Commit (Phase 2) | 1156e9f | Deploy this |
| MSBuild | C:\Windows\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe | Same path if building |
| InstallUtil | C:\Windows\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe | Same path |
