#Requires -Version 3.0
<#
.SYNOPSIS
    Sample PolyMon monitor script using PolyMon_SQLHealth.
    Copy this file, adjust the parameters for the target server, and paste
    the contents into a PolyMon PowerShell monitor definition.
#>

Import-Module "$PSScriptRoot\PolyMon_SQLHealth.psm1" -Force

SQL_Overview `

    # ── Connection ─────────────────────────────────────────────────────────────
    -HostName        "SQLSERVER01" `       # required — hostname or IP
    -InstanceName    "default" `           # named instance e.g. "SQLEXPRESS", or omit/leave "default"

    # ── SQL Agent service ──────────────────────────────────────────────────────
    # Recommended: if Agent is down, all job checks return silent false negatives
    -CheckAgentService `
    -AgentServiceSeverity   "Fail" `

    # ── Daily full backup job ──────────────────────────────────────────────────
    -CheckDailyBackup `
    -DailyBackupJobName     "DBA Daily Full Backup*" `   # wildcards OK
    -DailyBackupSeverity    "Warn" `
    -DailyBackupMaxDays     1 `                          # alert if no success in last N days

    # ── Weekly full backup job ─────────────────────────────────────────────────
    # -CheckWeeklyBackup `
    # -WeeklyBackupJobName  "DBA Weekly Full Backup*" `
    # -WeeklyBackupSeverity "Warn" `
    # -WeeklyBackupMaxDays  7 `

    # ── Transaction log backup job ─────────────────────────────────────────────
    -CheckTranslogBackup `
    -TranslogJobName        "BackupUser.Logs*" `
    -TranslogSeverity       "Warn" `
    -TranslogMaxMinutes     60 `                         # alert if no success in last N minutes

    # ── Integrity check job ────────────────────────────────────────────────────
    -CheckIntegrityJobs `
    -IntegrityJobName       "DBA Integrity*" `
    -IntegritySeverity      "Warn" `
    -IntegrityMaxDays       14 `                         # DBCC typically runs weekly or biweekly

    # ── Per-database exhaustive backup check ───────────────────────────────────
    # Catches databases not covered by the named backup jobs above
    -CheckExhaustiveBackup `
    -ExhaustiveBackupSeverity "Warn" `
    -ExhaustiveBackupMaxDays  30 `
    -ExhaustiveBackupIgnore   @("tempdb","Scratch","ReportCache") `

    # ── Database status (SUSPECT, RECOVERY_PENDING, etc.) ─────────────────────
    -CheckDBStatus `
    -DBStatusSeverity       "Fail" `

    # ── Recovery model ─────────────────────────────────────────────────────────
    -CheckRecoveryModel `
    -RecoveryModelSeverity  "Warn" `
    -ApprovedSimpleDBs      @("ReportCache","Scratch") ` # known Simple-model DBs — no alert

    # ── Log file to database size ratio ───────────────────────────────────────
    -CheckLogfileRatio `
    -LogfileRatioSeverity   "Warn" `
    -LogfileRatioMaxPct     40 `                         # alert if log > 40% of total DB size

    # ── Database datafile free space ───────────────────────────────────────────
    # -CheckDBFreespace `
    # -DBFreespaceWarnPct   10 `
    # -DBFreespaceFailPct   5 `

    # ── Databases on C: drive ──────────────────────────────────────────────────
    # -CheckDBsOnCDrive `

    # ── Host drive free space (WMI) ────────────────────────────────────────────
    -CheckDriveFreespace `
    -DriveFreespaceWarnPct  10 `                         # warn below 10% free
    -DriveFreespaceFailPct  5 `                          # fail below 5% free

    # ── Page Life Expectancy ───────────────────────────────────────────────────
    -CheckPLE `
    -PLEWarnThreshold       1000 `                       # warn below 1000s (~4GB buffer pool)
    -PLEFailThreshold       500 `

    # ── Blocking ───────────────────────────────────────────────────────────────
    -CheckBlocking `
    -BlockingWarnSeconds    30 `                         # warn if any session blocked > 30s
    -BlockingFailSeconds    120 `                        # fail if blocked > 2 minutes

    # ── Memory grants pending ──────────────────────────────────────────────────
    -CheckMemoryGrants `
    -MemoryGrantsSeverity   "Warn" `

    # ── SQL error log scan (severity 17+) ──────────────────────────────────────
    -CheckErrorLog `
    -ErrorLogMinutes        60 `                         # match your monitor interval
    -ErrorLogSeverity       "Warn" `

    # ── Counters ───────────────────────────────────────────────────────────────
    -RecordUserCount `                                   # total active connections
    -RecordBackupDuration `                              # last full backup job runtime (min)

    # ── SQL Server version ─────────────────────────────────────────────────────
    -CheckSQLVersion `
    -MinSQLVersion          13 `                         # 11=2012, 12=2014, 13=2016, 14=2017, 15=2019, 16=2022
    -SQLVersionSeverity     "Warn" `

    # ── Output ─────────────────────────────────────────────────────────────────
    -DetailLevel            0                            # 0=problems only, 1=include OK items
