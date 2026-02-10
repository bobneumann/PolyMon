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

CPU, Disk, File (age/count), Windows Performance Counters, Ping, PowerShell, SQL Query, SNMP, TCP Port, URL (HTML), URL (XML), Windows Service, WMI, and NRS Portal.

Monitors use a plug-in architecture -- new monitors can be added by inheriting from a base class and dropping the DLL into the Monitors folder. PowerShell monitors allow fully custom scripts with status and counter feedback.

## What's New in This Fork

### DB 1.40
- **Monitor History** -- tracks all changes to monitor definitions with undo/revert support via trigger-based history table and UI button in Monitor Definitions

### DB 1.50
- **Push Notifications** -- ntfy, Pushover, and Telegram support alongside existing SMTP email. Configured per-system (service + server) and per-operator (push address/key)
- **Failure Notification Bug Fix** -- "Notify on failure" now fires on the first failure instead of requiring two consecutive failures when "Notify on FailToOK" is disabled. Root cause: transition detection was comparing against last *alert* status instead of last *event* status

### UI Improvements
- PowerShell Monitor Editor toolbar: font size selector, undo/redo buttons, Consolas default font
- Ctrl+A shortcut conflict resolved (Alerts moved to Ctrl+Shift+A)
- Cleaned up Monitor Definitions toolbar

### Installer
- **InnoSetup-based installer** (`PolyMon-Setup.exe`) handles fresh install, upgrade, and repair in a single executable
- Deploys Manager, Executive, SQL scripts, and PowerShell modules (SSH-Sessions, SQL_Server_Overview, SQL_Server_Overview2)
- Service management via InstallUtil (auto stop/uninstall on upgrade, reinstall after)
- Optional database setup wizard (create new DB or upgrade existing through all versions)
- Config files preserved on upgrade (`onlyifdoesntexist`)

## Requirements

- Windows 10+ / Windows Server 2016+
- .NET Framework 4.8
- SQL Server 2014+ (SQL Express works fine)
- sqlcmd (for installer DB setup, optional)

## Installation

### From Installer

Download `PolyMon-Setup.exe` from the [Releases](../../releases) page and run it. The installer will:

1. Install PolyMon Manager and Executive to `C:\Program Files\PolyMon\`
2. Deploy PowerShell modules to `C:\Program Files\WindowsPowerShell\Modules\`
3. Register and start the PolyMon Executive service
4. Optionally create/upgrade the database via sqlcmd

### From Source

1. Open `PolyMon(CodePlex).sln` in Visual Studio 2019+ and build (Release)
2. Run `.\Build-PolyMonPackage.ps1 -Build` to stage files
3. Run SQL scripts from `PolymonSQL\Create Scripts\` to set up the database
4. Use `Install-PolyMon.ps1` or compile the InnoSetup installer with `iscc.exe PolyMon-Setup.iss`

## Database Upgrade Path

| From | To | Script |
|------|----|--------|
| Fresh | 1.30 | `DB Version 1.30.sql` |
| 1.00 | 1.10 | `Update DB 1.00 to 1.10.sql` |
| 1.10 | 1.30 | `Update DB 1.10 to 1.30.sql` |
| 1.30 | 1.40 | `Update DB 1.30 to 1.40.sql` |
| 1.40 | 1.50 | `Update DB 1.40 to 1.50.sql` |

Run `TSData-Extend.sql` after any upgrade to extend time-series lookup tables through 2035.

## License

MIT License (inherited from original project).

## Credits

Originally created by Fred Baptiste. Modernized and extended by Bob Neumann.
