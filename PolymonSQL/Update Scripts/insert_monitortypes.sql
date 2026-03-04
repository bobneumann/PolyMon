IF NOT EXISTS (SELECT 1 FROM MonitorType WHERE Name = 'SQL Server Overview')
BEGIN
    INSERT INTO MonitorType (Name, MonitorAssembly, EditorAssembly, MonitorXMLTemplate)
    VALUES (
        'SQL Server Overview',
        'SQLOverviewMonitor.dll',
        'SQLOverviewMonitorEditor.dll',
        '<SQLOverviewMonitor>
  <HostName>SERVERNAME</HostName>
  <InstanceName>default</InstanceName>
  <CheckAgentService>1</CheckAgentService>
  <AgentServiceSeverity>Fail</AgentServiceSeverity>
  <CheckDailyBackup>1</CheckDailyBackup>
  <DailyBackupJobName>DBA Daily Full Backup*</DailyBackupJobName>
  <DailyBackupSeverity>Warn</DailyBackupSeverity>
  <DailyBackupMaxDays>1</DailyBackupMaxDays>
  <CheckWeeklyBackup>0</CheckWeeklyBackup>
  <WeeklyBackupJobName>DBA Weekly Full Backup*</WeeklyBackupJobName>
  <WeeklyBackupSeverity>Warn</WeeklyBackupSeverity>
  <WeeklyBackupMaxDays>7</WeeklyBackupMaxDays>
  <CheckTranslogBackup>1</CheckTranslogBackup>
  <TranslogJobName>BackupUser.Logs*</TranslogJobName>
  <TranslogSeverity>Warn</TranslogSeverity>
  <TranslogMaxMinutes>60</TranslogMaxMinutes>
  <CheckIntegrityJobs>1</CheckIntegrityJobs>
  <IntegrityJobName>DBA Integrity*</IntegrityJobName>
  <IntegritySeverity>Warn</IntegritySeverity>
  <IntegrityMaxDays>14</IntegrityMaxDays>
  <CheckExhaustiveBackup>1</CheckExhaustiveBackup>
  <ExhaustiveBackupSeverity>Warn</ExhaustiveBackupSeverity>
  <ExhaustiveBackupMaxDays>30</ExhaustiveBackupMaxDays>
  <ExhaustiveBackupIgnore>tempdb</ExhaustiveBackupIgnore>
  <CheckDBStatus>1</CheckDBStatus>
  <DBStatusSeverity>Fail</DBStatusSeverity>
  <CheckRecoveryModel>1</CheckRecoveryModel>
  <RecoveryModelSeverity>Warn</RecoveryModelSeverity>
  <ApprovedSimpleDBs></ApprovedSimpleDBs>
  <CheckLogfileRatio>1</CheckLogfileRatio>
  <LogfileRatioSeverity>Warn</LogfileRatioSeverity>
  <LogfileRatioMaxPct>40</LogfileRatioMaxPct>
  <CheckDBFreespace>0</CheckDBFreespace>
  <DBFreespaceWarnPct>10</DBFreespaceWarnPct>
  <DBFreespaceFailPct>5</DBFreespaceFailPct>
  <CheckDBsOnCDrive>0</CheckDBsOnCDrive>
  <CheckDriveFreespace>1</CheckDriveFreespace>
  <DriveFreespaceWarnPct>10</DriveFreespaceWarnPct>
  <DriveFreespaceFailPct>5</DriveFreespaceFailPct>
  <CheckPLE>1</CheckPLE>
  <PLEWarnThreshold>1000</PLEWarnThreshold>
  <PLEFailThreshold>500</PLEFailThreshold>
  <CheckBlocking>1</CheckBlocking>
  <BlockingWarnSeconds>30</BlockingWarnSeconds>
  <BlockingFailSeconds>120</BlockingFailSeconds>
  <CheckMemoryGrants>1</CheckMemoryGrants>
  <MemoryGrantsSeverity>Warn</MemoryGrantsSeverity>
  <CheckErrorLog>1</CheckErrorLog>
  <ErrorLogMinutes>60</ErrorLogMinutes>
  <ErrorLogSeverity>Warn</ErrorLogSeverity>
  <RecordUserCount>1</RecordUserCount>
  <RecordBackupDuration>1</RecordBackupDuration>
  <CheckSQLVersion>0</CheckSQLVersion>
  <MinSQLVersion>13</MinSQLVersion>
  <SQLVersionSeverity>Warn</SQLVersionSeverity>
  <DetailLevel>0</DetailLevel>
</SQLOverviewMonitor>'
    )
    SELECT 'Inserted: SQL Server Overview' AS Result
END
ELSE
    SELECT 'Already exists: SQL Server Overview' AS Result
