# PolyMon

**Open-source network and system monitoring for Windows / SQL Server.**

PolyMon monitors network resources on a schedule, logs results to SQL Server, generates email and push alerts, and provides historical trend analysis through a Windows management console.

Originally created by [Fred Baptiste](https://github.com/fbaptiste/polymon) on CodePlex (~2008), PolyMon was archived in 2019. This fork modernizes the codebase for .NET Framework 4.8 and SQL Server 2019+, adds new features, and provides a single-file installer.

---

## Architecture

| Component | Description |
|-----------|-------------|
| **PolyMon Manager** | Windows Forms GUI for configuration, monitor definitions, operators, alerts, and trend analysis |
| **PolyMon Executive** | Windows service that runs monitors on schedule, logs results, and triggers notifications |
| **SQL Server Database** | Stores monitor configs, event history, alert rules, operator contacts, and system settings |

## Built-in Monitor Plug-ins

CPU, Disk, File (age/count), Windows Performance Counters, Ping, PowerShell, SQL Query, TCP Port, URL (HTML), URL (XML), Windows Service, WMI, and NRS Portal.

Monitors use a plug-in architecture — new monitors can be added by inheriting from a base class and dropping the DLL into the Monitors folder. PowerShell monitors allow fully custom scripts with status and counter feedback.

**SNMP** is supported via the included `PSModules\SNMPMonitor\SNMPMonitor.ps1` PowerShell monitor sample, which uses the [`Indented.Net.Snmp`](https://www.powershellgallery.com/packages/Indented.Net.Snmp) module (`Install-Module -Name Indented.Net.Snmp -Scope AllUsers`).

## What's New in This Fork

### DB 1.40
- **Monitor History** — tracks all changes to monitor definitions with undo/revert support via trigger-based history table and UI button in Monitor Definitions

### DB 1.50
- **Push Notifications** — ntfy, Pushover, and Telegram support alongside existing SMTP email. Configured per-system (service + server) and per-operator (push address/key)
- **Failure Notification Bug Fix** — "Notify on failure" now fires on the first failure instead of requiring two consecutive failures when "Notify on FailToOK" is disabled

### DB 1.51
- **Push config notes** — free-text Notes field on System Settings for documenting push notification configuration

### DB 1.52
- **Email Relay GUI** — configuration UI for an external email relay API (EmailRelayKey stored in SysSettings)
- **Matrix push support** — Matrix/Synapse room browser for selecting a push destination room via the Manager UI

### DB 1.53
- **Graph visibility defaults** — System Settings controls which chart types (Status Frequency, Uptime) are shown by default in the Reports view

### DB 1.54
- **Maintenance Mode** — silence a monitor for a specified number of minutes directly from the Monitor Definitions grid. Executive re-enables it automatically when the window expires

### DB 1.55
- **Parallel monitor execution** — monitors run concurrently up to a configurable limit (`MonitorConcurrency`, default 10). Timeout is configurable as a percentage of the cycle interval (`MonitorTimeoutPct`, default 80%)

### DB 1.56
- **Monitor run logging toggle** — enable/disable the Executive's per-monitor run log via System Settings (`MonitorRunLog`)

### DB 1.57
- **SQL-based run logging** — `MonitorRunLog` table records each monitor's start/end time every cycle. `EndDT IS NULL` identifies monitors that hung and were abandoned. Cycle-level timeouts are recorded as a sentinel row (`[CYCLE TIMEOUT]`)
- **Cycle watchdog** — overlapping monitor cycles are now detected and blocked using a live thread reference check rather than a boolean flag, eliminating the race condition that could start a second concurrent cycle

### v1.58 — Repo hygiene & CI
- **GitHub Actions CI** — every push builds the full solution, stages the installer payload, compiles InnoSetup, and uploads `PolyMon-Setup.exe` as a workflow artifact. Tags push the artifact to a GitHub Release automatically
- **Binaries removed from git** — tracked `bin/` and `obj/` output replaced by a clean build; repo size reduced significantly
- **COM interop relocated** — `Interop.MSScriptControl.dll` moved from `bin/` to `lib/` in each referencing project
- **SNMP PowerShell adapter** — `PSModules/SNMPMonitor/SNMPMonitor.ps1` ships as a working sample using `Indented.Net.Snmp`; native SNMP DLL projects removed
- **TFS relics removed** — `.vspscc`, `.vssscc`, `BuildProcessTemplates/`, and other source-control artifacts cleaned from the tree

### UI Improvements
- PowerShell Monitor Editor toolbar: font size selector, undo/redo buttons, Consolas default font
- Ctrl+A shortcut conflict resolved (Alerts moved to Ctrl+Shift+A)
- Cleaned up Monitor Definitions toolbar

### Reliability & Security
- Email send failures are now logged to the Windows Event Log and do not mark the alert as sent — it will retry next cycle
- HTTP push requests have a 10-second timeout (previously unlimited, could stall the notification loop)
- TLS certificate bypass scoped to per-operation instead of process-wide (fixes a session-wide cert validation hole in the Matrix and Email Relay forms)

### Installer
- **InnoSetup-based installer** (`PolyMon-Setup.exe`) handles fresh install, upgrade, and repair in a single executable
- Full-stack: deploys Manager, Executive, SQL scripts, and PowerShell modules; manages the Windows service (stop/uninstall before copy, reinstall after); writes shortcuts and Add/Remove Programs entry
- Config files preserved on upgrade (`onlyifdoesntexist`) — connection strings survive re-runs
- Database upgrade delegated to `Install-PolyMon.ps1 -DbOnly` (single source of truth for the SQL chain)
- `Get-DbVersion` reads `SysSettings.DBVersion` — fixes a silent failure that caused the upgrade chain to be skipped on every existing-database path

## Requirements

- Windows 10+ / Windows Server 2016+
- .NET Framework 4.8
- SQL Server 2014+ (SQL Express works fine)
- sqlcmd (for installer DB setup, optional)

## Installation

### From Installer

Download `PolyMon-Setup.exe` from the [Releases](../../releases) page and run it. The installer will:

1. Stop and remove the existing PolyMon Executive service (if present)
2. Install PolyMon Manager and Executive to `C:\Program Files\PolyMon\`
3. Deploy PowerShell modules to `C:\Program Files\WindowsPowerShell\Modules\`
4. Register and start the PolyMon Executive service
5. Run the database create/upgrade chain via `Install-PolyMon.ps1 -DbOnly`

### From Source

1. Open `PolyMon(CodePlex).sln` in Visual Studio 2019+ and build (Release)
2. Run `.\Build-PolyMonPackage.ps1 -Build` to stage files into `PolyMonInstall\`
3. Run SQL scripts from `PolymonSQL\Create Scripts\` to set up the database
4. Use `Install-PolyMon.ps1` or compile the InnoSetup installer with `iscc PolyMon-Setup.iss`


## Database Upgrade Path

| From | To | Script |
|------|----|--------|
| Fresh | 1.30 | `DB Version 1.30.sql` |
| 1.00 | 1.10 | `Update DB 1.00 to 1.10.sql` |
| 1.10 | 1.30 | `Update DB 1.10 to 1.30.sql` |
| 1.30 | 1.40 | `Update DB 1.30 to 1.40.sql` |
| 1.40 | 1.50 | `Update DB 1.40 to 1.50.sql` |
| 1.50 | 1.51 | `Update DB 1.50 to 1.51.sql` |
| 1.51 | 1.52 | `Update DB 1.51 to 1.52.sql` |
| 1.52 | 1.53 | `Update DB 1.52 to 1.53.sql` |
| 1.53 | 1.54 | `Update DB 1.53 to 1.54.sql` |
| 1.54 | 1.55 | `Update DB 1.54 to 1.55.sql` |
| 1.55 | 1.56 | `Update DB 1.55 to 1.56.sql` |
| 1.56 | 1.57 | `Update DB 1.56 to 1.57.sql` |

Run `TSData-Extend.sql` after any upgrade to extend time-series lookup tables through 2035.

The installer handles the full upgrade chain automatically. To run it manually:

```powershell
.\Install-PolyMon.ps1 -SqlInstance ".\SQLEXPRESS" -DbName "polymon"
```

## Security Notes

SMTP passwords, push notification tokens, the Matrix bearer token, and the Email Relay API key are stored as plaintext in the `SysSettings` table. This is a known limitation. For a LAN-hosted tool, SQL Server's own access controls (Windows authentication, network isolation) are the primary defense. Restrict database access accordingly and do not expose the SQL Server instance to untrusted networks.

## License

MIT License (inherited from original project).

## Credits

Originally created by Fred Baptiste. Modernized and extended by Bob Neumann.
