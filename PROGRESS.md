# PolyMon Rebuild Project - Progress Notes
## Date: 2026-02-07

## COMPLETED:
- Phase 1: All 30/30 projects compile on .NET 4.8
- Git commit: f5eea91 (baseline)
- Changes: see git log for details

- Phase 2: Get PolyMon running with SQL Server database
  - Created PolyMon database from DB Version 1.30.sql on .\SQLEXPRESS
  - Extended TS date range from 2020 to 2035
  - Updated Retention Scheme monitor connection string to .\SQLEXPRESS
  - Fixed connection strings in all 3 app.config files (Manager, Executive, Tester)
  - Updated supportedRuntime from v4.5 to v4.8 in Manager and Executive configs
  - Fixed EventLog SecurityException crash in MonitorExecutor.vb constructor
  - Granted NT AUTHORITY\SYSTEM access to PolyMon database (db_datareader, db_datawriter, EXECUTE)
  - Copied monitor DLLs to Executive bin directory (not done by build automatically)
  - Installed PolyMonExecutive as Windows service via InstallUtil
  - PolyMonManager: launches, connects to DB, creates monitors, test runs OK
  - PolyMonExecutive: service starts, connects to SQL, runs monitors on schedule
  - End-to-end pipeline verified: monitor events logged to database with OK status

## TODO:
- Phase 3: Modernize the code

## KEY FILES/PATHS:
- Solution: C:\Users\Bob\Projects\PolyMon-Original\PolyMon(CodePlex).sln
- SQL Scripts: C:\Users\Bob\Projects\PolyMon-Original\PolymonSQL\Scripts\
- DB Create Script: C:\Users\Bob\Projects\PolyMon-Original\PolymonSQL\Create Scripts\DB Version 1.30.sql
- Main apps: PolyMonManager (GUI), PolyMonExecutive (service)
- Database: .\SQLEXPRESS / PolyMon (Windows Integrated Auth)

## BUGS FIXED:
- MonitorExecutor.vb: EventLog.SourceExists() throws SecurityException without admin
  privileges. Wrapped in try-catch to gracefully skip EventLog when not admin.

## NOTES:
- sqlcmd requires -C flag (trust certificate) for SQL Server 2025
- MSBuild location: C:\Windows\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe
- Must close PolyMonManager before rebuilding (DLL locking)
- Executive bin needs monitor DLLs copied manually (from PolyMonManager\bin\Monitors\)
- Service installed via: InstallUtil.exe PolyMonExecutive.exe (requires admin)
- Service runs as LocalSystem - needs NT AUTHORITY\SYSTEM DB permissions
