Imports System.Text
Imports System.Xml
Imports System.Windows.Forms
Imports System.Drawing

Public Class SQLOverviewMonitorEditor
    Inherits PolyMon.MonitorEditors.GenericMonitorEditor

#Region "Private Fields"

    Private mXMLTemplate As String

    '── Tab Control ──────────────────────────────────────────────────────────────
    Private tcMain As New TabControl
    Private tpJobs As New TabPage
    Private tpHealth As New TabPage
    Private tpPerf As New TabPage
    Private tpCounters As New TabPage

    '── Tab 1: Connection ────────────────────────────────────────────────────────
    Private gbConn As New GroupBox
    Private txtHostName As New TextBox
    Private txtInstanceName As New TextBox

    '── Tab 1: SQL Agent Service ─────────────────────────────────────────────────
    Private gbAgent As New GroupBox
    Private WithEvents chkAgentService As New CheckBox
    Private cboAgentSev As New ComboBox

    '── Tab 1: Daily Full Backup ─────────────────────────────────────────────────
    Private gbDailyBak As New GroupBox
    Private WithEvents chkDailyBackup As New CheckBox
    Private txtDailyJob As New TextBox
    Private nudDailyMaxDays As New NumericUpDown
    Private cboDailySev As New ComboBox

    '── Tab 1: Weekly Full Backup ────────────────────────────────────────────────
    Private gbWeeklyBak As New GroupBox
    Private WithEvents chkWeeklyBackup As New CheckBox
    Private txtWeeklyJob As New TextBox
    Private nudWeeklyMaxDays As New NumericUpDown
    Private cboWeeklySev As New ComboBox

    '── Tab 1: Transaction Log Backup ────────────────────────────────────────────
    Private gbTranslog As New GroupBox
    Private WithEvents chkTranslogBackup As New CheckBox
    Private txtTranslogJob As New TextBox
    Private nudTranslogMaxMin As New NumericUpDown
    Private cboTranslogSev As New ComboBox

    '── Tab 1: Integrity Check ───────────────────────────────────────────────────
    Private gbIntegrity As New GroupBox
    Private WithEvents chkIntegrityJobs As New CheckBox
    Private txtIntegrityJob As New TextBox
    Private nudIntegrityMaxDays As New NumericUpDown
    Private cboIntegritySev As New ComboBox

    '── Tab 2: Exhaustive Backup ─────────────────────────────────────────────────
    Private gbExhaustive As New GroupBox
    Private WithEvents chkExhaustiveBackup As New CheckBox
    Private cboExhSev As New ComboBox
    Private nudExhMaxDays As New NumericUpDown
    Private txtExhIgnore As New TextBox

    '── Tab 2: DB Status ─────────────────────────────────────────────────────────
    Private gbDBStatus As New GroupBox
    Private WithEvents chkDBStatus As New CheckBox
    Private cboDBStatusSev As New ComboBox

    '── Tab 2: Recovery Model ────────────────────────────────────────────────────
    Private gbRecovModel As New GroupBox
    Private WithEvents chkRecoveryModel As New CheckBox
    Private cboRecovSev As New ComboBox
    Private txtApprovedSimple As New TextBox

    '── Tab 2: Log File Ratio ────────────────────────────────────────────────────
    Private gbLogRatio As New GroupBox
    Private WithEvents chkLogfileRatio As New CheckBox
    Private nudLogRatioMaxPct As New NumericUpDown
    Private cboLogRatioSev As New ComboBox

    '── Tab 2: DB Datafile Freespace ─────────────────────────────────────────────
    Private gbDBFreespace As New GroupBox
    Private WithEvents chkDBFreespace As New CheckBox
    Private nudDBFreeWarnPct As New NumericUpDown
    Private nudDBFreeFailPct As New NumericUpDown

    '── Tab 2: DBs on C: Drive ───────────────────────────────────────────────────
    Private chkDBsOnCDrive As New CheckBox

    '── Tab 3: Drive Freespace ───────────────────────────────────────────────────
    Private gbDriveFreespace As New GroupBox
    Private WithEvents chkDriveFreespace As New CheckBox
    Private nudDriveFreeWarnPct As New NumericUpDown
    Private nudDriveFreeFailPct As New NumericUpDown

    '── Tab 3: Page Life Expectancy ──────────────────────────────────────────────
    Private gbPLE As New GroupBox
    Private WithEvents chkPLE As New CheckBox
    Private nudPLEWarn As New NumericUpDown
    Private nudPLEFail As New NumericUpDown

    '── Tab 3: Blocking ──────────────────────────────────────────────────────────
    Private gbBlocking As New GroupBox
    Private WithEvents chkBlocking As New CheckBox
    Private nudBlockWarnSec As New NumericUpDown
    Private nudBlockFailSec As New NumericUpDown

    '── Tab 3: Memory Grants ─────────────────────────────────────────────────────
    Private gbMemGrants As New GroupBox
    Private WithEvents chkMemoryGrants As New CheckBox
    Private cboMemGrantsSev As New ComboBox

    '── Tab 3: Error Log ─────────────────────────────────────────────────────────
    Private gbErrorLog As New GroupBox
    Private WithEvents chkErrorLog As New CheckBox
    Private nudErrorLogMin As New NumericUpDown
    Private cboErrorLogSev As New ComboBox

    '── Tab 4: Counters ──────────────────────────────────────────────────────────
    Private gbCounters As New GroupBox
    Private chkRecordUserCount As New CheckBox
    Private chkRecordBackupDuration As New CheckBox

    '── Tab 4: SQL Server Version ────────────────────────────────────────────────
    Private gbSQLVersion As New GroupBox
    Private WithEvents chkSQLVersion As New CheckBox
    Private WithEvents nudMinSQLVersion As New NumericUpDown
    Private lblVersionName As New Label
    Private cboVersionSev As New ComboBox

    '── Tab 4: Output ────────────────────────────────────────────────────────────
    Private gbOutput As New GroupBox
    Private cboDetailLevel As New ComboBox

#End Region

#Region "Constructor"

    Public Sub New()
        InitializeComponent()
    End Sub

#End Region

#Region "Public Interface"

    Public Overrides Property XMLTemplate() As String
        Get
            Return mXMLTemplate
        End Get
        Set(ByVal value As String)
            mXMLTemplate = value
        End Set
    End Property

    Public Overrides Property XMLSettings() As String
        Get
            Return BuildXML()
        End Get
        Set(ByVal value As String)
            LoadXML(value)
        End Set
    End Property

    Public Overrides Sub LoadTemplateDefaults()
        LoadXML(mXMLTemplate)
    End Sub

#End Region

#Region "Event Handlers"

    Private Sub chkAgentService_CheckedChanged(s As Object, e As EventArgs) Handles chkAgentService.CheckedChanged
        ToggleGroup(gbAgent, chkAgentService)
    End Sub
    Private Sub chkDailyBackup_CheckedChanged(s As Object, e As EventArgs) Handles chkDailyBackup.CheckedChanged
        ToggleGroup(gbDailyBak, chkDailyBackup)
    End Sub
    Private Sub chkWeeklyBackup_CheckedChanged(s As Object, e As EventArgs) Handles chkWeeklyBackup.CheckedChanged
        ToggleGroup(gbWeeklyBak, chkWeeklyBackup)
    End Sub
    Private Sub chkTranslogBackup_CheckedChanged(s As Object, e As EventArgs) Handles chkTranslogBackup.CheckedChanged
        ToggleGroup(gbTranslog, chkTranslogBackup)
    End Sub
    Private Sub chkIntegrityJobs_CheckedChanged(s As Object, e As EventArgs) Handles chkIntegrityJobs.CheckedChanged
        ToggleGroup(gbIntegrity, chkIntegrityJobs)
    End Sub
    Private Sub chkExhaustiveBackup_CheckedChanged(s As Object, e As EventArgs) Handles chkExhaustiveBackup.CheckedChanged
        ToggleGroup(gbExhaustive, chkExhaustiveBackup)
    End Sub
    Private Sub chkDBStatus_CheckedChanged(s As Object, e As EventArgs) Handles chkDBStatus.CheckedChanged
        ToggleGroup(gbDBStatus, chkDBStatus)
    End Sub
    Private Sub chkRecoveryModel_CheckedChanged(s As Object, e As EventArgs) Handles chkRecoveryModel.CheckedChanged
        ToggleGroup(gbRecovModel, chkRecoveryModel)
    End Sub
    Private Sub chkLogfileRatio_CheckedChanged(s As Object, e As EventArgs) Handles chkLogfileRatio.CheckedChanged
        ToggleGroup(gbLogRatio, chkLogfileRatio)
    End Sub
    Private Sub chkDBFreespace_CheckedChanged(s As Object, e As EventArgs) Handles chkDBFreespace.CheckedChanged
        ToggleGroup(gbDBFreespace, chkDBFreespace)
    End Sub
    Private Sub chkDriveFreespace_CheckedChanged(s As Object, e As EventArgs) Handles chkDriveFreespace.CheckedChanged
        ToggleGroup(gbDriveFreespace, chkDriveFreespace)
    End Sub
    Private Sub chkPLE_CheckedChanged(s As Object, e As EventArgs) Handles chkPLE.CheckedChanged
        ToggleGroup(gbPLE, chkPLE)
    End Sub
    Private Sub chkBlocking_CheckedChanged(s As Object, e As EventArgs) Handles chkBlocking.CheckedChanged
        ToggleGroup(gbBlocking, chkBlocking)
    End Sub
    Private Sub chkMemoryGrants_CheckedChanged(s As Object, e As EventArgs) Handles chkMemoryGrants.CheckedChanged
        ToggleGroup(gbMemGrants, chkMemoryGrants)
    End Sub
    Private Sub chkErrorLog_CheckedChanged(s As Object, e As EventArgs) Handles chkErrorLog.CheckedChanged
        ToggleGroup(gbErrorLog, chkErrorLog)
    End Sub
    Private Sub chkSQLVersion_CheckedChanged(s As Object, e As EventArgs) Handles chkSQLVersion.CheckedChanged
        ToggleGroup(gbSQLVersion, chkSQLVersion)
    End Sub

    Private Sub nudMinSQLVersion_ValueChanged(s As Object, e As EventArgs) Handles nudMinSQLVersion.ValueChanged
        lblVersionName.Text = "= " & VersionLabel(CInt(nudMinSQLVersion.Value))
    End Sub

#End Region

#Region "XML Load / Save"

    Private Sub LoadXML(ByVal xml As String)
        If String.IsNullOrEmpty(xml) Then Return

        Dim doc As New XmlDocument
        doc.LoadXml(xml)
        Dim root As XmlNode = doc.DocumentElement

        ' Connection
        txtHostName.Text = ReadNode(root, "HostName")
        txtInstanceName.Text = ReadNode(root, "InstanceName")

        ' Agent Service
        chkAgentService.Checked = NodeBool(root, "CheckAgentService")
        SetCombo(cboAgentSev, ReadNode(root, "AgentServiceSeverity"))

        ' Daily Backup
        chkDailyBackup.Checked = NodeBool(root, "CheckDailyBackup")
        txtDailyJob.Text = ReadNode(root, "DailyBackupJobName")
        nudDailyMaxDays.Value = NodeInt(root, "DailyBackupMaxDays", 1)
        SetCombo(cboDailySev, ReadNode(root, "DailyBackupSeverity"))

        ' Weekly Backup
        chkWeeklyBackup.Checked = NodeBool(root, "CheckWeeklyBackup")
        txtWeeklyJob.Text = ReadNode(root, "WeeklyBackupJobName")
        nudWeeklyMaxDays.Value = NodeInt(root, "WeeklyBackupMaxDays", 7)
        SetCombo(cboWeeklySev, ReadNode(root, "WeeklyBackupSeverity"))

        ' Translog Backup
        chkTranslogBackup.Checked = NodeBool(root, "CheckTranslogBackup")
        txtTranslogJob.Text = ReadNode(root, "TranslogJobName")
        nudTranslogMaxMin.Value = NodeInt(root, "TranslogMaxMinutes", 60)
        SetCombo(cboTranslogSev, ReadNode(root, "TranslogSeverity"))

        ' Integrity
        chkIntegrityJobs.Checked = NodeBool(root, "CheckIntegrityJobs")
        txtIntegrityJob.Text = ReadNode(root, "IntegrityJobName")
        nudIntegrityMaxDays.Value = NodeInt(root, "IntegrityMaxDays", 14)
        SetCombo(cboIntegritySev, ReadNode(root, "IntegritySeverity"))

        ' Exhaustive Backup
        chkExhaustiveBackup.Checked = NodeBool(root, "CheckExhaustiveBackup")
        SetCombo(cboExhSev, ReadNode(root, "ExhaustiveBackupSeverity"))
        nudExhMaxDays.Value = NodeInt(root, "ExhaustiveBackupMaxDays", 30)
        txtExhIgnore.Text = ReadNode(root, "ExhaustiveBackupIgnore")

        ' DB Status
        chkDBStatus.Checked = NodeBool(root, "CheckDBStatus")
        SetCombo(cboDBStatusSev, ReadNode(root, "DBStatusSeverity"))

        ' Recovery Model
        chkRecoveryModel.Checked = NodeBool(root, "CheckRecoveryModel")
        SetCombo(cboRecovSev, ReadNode(root, "RecoveryModelSeverity"))
        txtApprovedSimple.Text = ReadNode(root, "ApprovedSimpleDBs")

        ' Log File Ratio
        chkLogfileRatio.Checked = NodeBool(root, "CheckLogfileRatio")
        nudLogRatioMaxPct.Value = NodeInt(root, "LogfileRatioMaxPct", 40)
        SetCombo(cboLogRatioSev, ReadNode(root, "LogfileRatioSeverity"))

        ' DB Freespace
        chkDBFreespace.Checked = NodeBool(root, "CheckDBFreespace")
        nudDBFreeWarnPct.Value = NodeInt(root, "DBFreespaceWarnPct", 10)
        nudDBFreeFailPct.Value = NodeInt(root, "DBFreespaceFailPct", 5)

        ' DBs on C Drive
        chkDBsOnCDrive.Checked = NodeBool(root, "CheckDBsOnCDrive")

        ' Drive Freespace
        chkDriveFreespace.Checked = NodeBool(root, "CheckDriveFreespace")
        nudDriveFreeWarnPct.Value = NodeInt(root, "DriveFreespaceWarnPct", 10)
        nudDriveFreeFailPct.Value = NodeInt(root, "DriveFreespaceFailPct", 5)

        ' PLE
        chkPLE.Checked = NodeBool(root, "CheckPLE")
        nudPLEWarn.Value = NodeInt(root, "PLEWarnThreshold", 1000)
        nudPLEFail.Value = NodeInt(root, "PLEFailThreshold", 500)

        ' Blocking
        chkBlocking.Checked = NodeBool(root, "CheckBlocking")
        nudBlockWarnSec.Value = NodeInt(root, "BlockingWarnSeconds", 30)
        nudBlockFailSec.Value = NodeInt(root, "BlockingFailSeconds", 120)

        ' Memory Grants
        chkMemoryGrants.Checked = NodeBool(root, "CheckMemoryGrants")
        SetCombo(cboMemGrantsSev, ReadNode(root, "MemoryGrantsSeverity"))

        ' Error Log
        chkErrorLog.Checked = NodeBool(root, "CheckErrorLog")
        nudErrorLogMin.Value = NodeInt(root, "ErrorLogMinutes", 60)
        SetCombo(cboErrorLogSev, ReadNode(root, "ErrorLogSeverity"))

        ' Counters
        chkRecordUserCount.Checked = NodeBool(root, "RecordUserCount")
        chkRecordBackupDuration.Checked = NodeBool(root, "RecordBackupDuration")

        ' SQL Version
        chkSQLVersion.Checked = NodeBool(root, "CheckSQLVersion")
        Dim minVer As Integer = NodeInt(root, "MinSQLVersion", 13)
        If minVer < 7 Then minVer = 7
        If minVer > 16 Then minVer = 16
        nudMinSQLVersion.Value = minVer
        lblVersionName.Text = "= " & VersionLabel(minVer)
        SetCombo(cboVersionSev, ReadNode(root, "SQLVersionSeverity"))

        ' Detail Level
        Dim detail As Integer = NodeInt(root, "DetailLevel", 0)
        cboDetailLevel.SelectedIndex = If(detail = 1, 1, 0)

        ' Apply enabled/disabled state for all groups
        ToggleGroup(gbAgent, chkAgentService)
        ToggleGroup(gbDailyBak, chkDailyBackup)
        ToggleGroup(gbWeeklyBak, chkWeeklyBackup)
        ToggleGroup(gbTranslog, chkTranslogBackup)
        ToggleGroup(gbIntegrity, chkIntegrityJobs)
        ToggleGroup(gbExhaustive, chkExhaustiveBackup)
        ToggleGroup(gbDBStatus, chkDBStatus)
        ToggleGroup(gbRecovModel, chkRecoveryModel)
        ToggleGroup(gbLogRatio, chkLogfileRatio)
        ToggleGroup(gbDBFreespace, chkDBFreespace)
        ToggleGroup(gbDriveFreespace, chkDriveFreespace)
        ToggleGroup(gbPLE, chkPLE)
        ToggleGroup(gbBlocking, chkBlocking)
        ToggleGroup(gbMemGrants, chkMemoryGrants)
        ToggleGroup(gbErrorLog, chkErrorLog)
        ToggleGroup(gbSQLVersion, chkSQLVersion)
    End Sub

    Private Function BuildXML() As String
        Dim sb As New StringBuilder
        sb.AppendLine("<SQLOverviewMonitor>")

        ' Connection
        sb.AppendLine("  <HostName>" & XMLEncode(txtHostName.Text.Trim()) & "</HostName>")
        sb.AppendLine("  <InstanceName>" & XMLEncode(txtInstanceName.Text.Trim()) & "</InstanceName>")

        ' Agent Service
        sb.AppendLine("  <CheckAgentService>" & BoolNode(chkAgentService) & "</CheckAgentService>")
        sb.AppendLine("  <AgentServiceSeverity>" & cboAgentSev.Text & "</AgentServiceSeverity>")

        ' Daily Backup
        sb.AppendLine("  <CheckDailyBackup>" & BoolNode(chkDailyBackup) & "</CheckDailyBackup>")
        sb.AppendLine("  <DailyBackupJobName>" & XMLEncode(txtDailyJob.Text.Trim()) & "</DailyBackupJobName>")
        sb.AppendLine("  <DailyBackupSeverity>" & cboDailySev.Text & "</DailyBackupSeverity>")
        sb.AppendLine("  <DailyBackupMaxDays>" & CInt(nudDailyMaxDays.Value).ToString() & "</DailyBackupMaxDays>")

        ' Weekly Backup
        sb.AppendLine("  <CheckWeeklyBackup>" & BoolNode(chkWeeklyBackup) & "</CheckWeeklyBackup>")
        sb.AppendLine("  <WeeklyBackupJobName>" & XMLEncode(txtWeeklyJob.Text.Trim()) & "</WeeklyBackupJobName>")
        sb.AppendLine("  <WeeklyBackupSeverity>" & cboWeeklySev.Text & "</WeeklyBackupSeverity>")
        sb.AppendLine("  <WeeklyBackupMaxDays>" & CInt(nudWeeklyMaxDays.Value).ToString() & "</WeeklyBackupMaxDays>")

        ' Translog Backup
        sb.AppendLine("  <CheckTranslogBackup>" & BoolNode(chkTranslogBackup) & "</CheckTranslogBackup>")
        sb.AppendLine("  <TranslogJobName>" & XMLEncode(txtTranslogJob.Text.Trim()) & "</TranslogJobName>")
        sb.AppendLine("  <TranslogSeverity>" & cboTranslogSev.Text & "</TranslogSeverity>")
        sb.AppendLine("  <TranslogMaxMinutes>" & CInt(nudTranslogMaxMin.Value).ToString() & "</TranslogMaxMinutes>")

        ' Integrity
        sb.AppendLine("  <CheckIntegrityJobs>" & BoolNode(chkIntegrityJobs) & "</CheckIntegrityJobs>")
        sb.AppendLine("  <IntegrityJobName>" & XMLEncode(txtIntegrityJob.Text.Trim()) & "</IntegrityJobName>")
        sb.AppendLine("  <IntegritySeverity>" & cboIntegritySev.Text & "</IntegritySeverity>")
        sb.AppendLine("  <IntegrityMaxDays>" & CInt(nudIntegrityMaxDays.Value).ToString() & "</IntegrityMaxDays>")

        ' Exhaustive Backup
        sb.AppendLine("  <CheckExhaustiveBackup>" & BoolNode(chkExhaustiveBackup) & "</CheckExhaustiveBackup>")
        sb.AppendLine("  <ExhaustiveBackupSeverity>" & cboExhSev.Text & "</ExhaustiveBackupSeverity>")
        sb.AppendLine("  <ExhaustiveBackupMaxDays>" & CInt(nudExhMaxDays.Value).ToString() & "</ExhaustiveBackupMaxDays>")
        sb.AppendLine("  <ExhaustiveBackupIgnore>" & XMLEncode(txtExhIgnore.Text.Trim()) & "</ExhaustiveBackupIgnore>")

        ' DB Status
        sb.AppendLine("  <CheckDBStatus>" & BoolNode(chkDBStatus) & "</CheckDBStatus>")
        sb.AppendLine("  <DBStatusSeverity>" & cboDBStatusSev.Text & "</DBStatusSeverity>")

        ' Recovery Model
        sb.AppendLine("  <CheckRecoveryModel>" & BoolNode(chkRecoveryModel) & "</CheckRecoveryModel>")
        sb.AppendLine("  <RecoveryModelSeverity>" & cboRecovSev.Text & "</RecoveryModelSeverity>")
        sb.AppendLine("  <ApprovedSimpleDBs>" & XMLEncode(txtApprovedSimple.Text.Trim()) & "</ApprovedSimpleDBs>")

        ' Log File Ratio
        sb.AppendLine("  <CheckLogfileRatio>" & BoolNode(chkLogfileRatio) & "</CheckLogfileRatio>")
        sb.AppendLine("  <LogfileRatioSeverity>" & cboLogRatioSev.Text & "</LogfileRatioSeverity>")
        sb.AppendLine("  <LogfileRatioMaxPct>" & CInt(nudLogRatioMaxPct.Value).ToString() & "</LogfileRatioMaxPct>")

        ' DB Freespace
        sb.AppendLine("  <CheckDBFreespace>" & BoolNode(chkDBFreespace) & "</CheckDBFreespace>")
        sb.AppendLine("  <DBFreespaceWarnPct>" & CInt(nudDBFreeWarnPct.Value).ToString() & "</DBFreespaceWarnPct>")
        sb.AppendLine("  <DBFreespaceFailPct>" & CInt(nudDBFreeFailPct.Value).ToString() & "</DBFreespaceFailPct>")

        ' DBs on C Drive
        sb.AppendLine("  <CheckDBsOnCDrive>" & BoolNode(chkDBsOnCDrive) & "</CheckDBsOnCDrive>")

        ' Drive Freespace
        sb.AppendLine("  <CheckDriveFreespace>" & BoolNode(chkDriveFreespace) & "</CheckDriveFreespace>")
        sb.AppendLine("  <DriveFreespaceWarnPct>" & CInt(nudDriveFreeWarnPct.Value).ToString() & "</DriveFreespaceWarnPct>")
        sb.AppendLine("  <DriveFreespaceFailPct>" & CInt(nudDriveFreeFailPct.Value).ToString() & "</DriveFreespaceFailPct>")

        ' PLE
        sb.AppendLine("  <CheckPLE>" & BoolNode(chkPLE) & "</CheckPLE>")
        sb.AppendLine("  <PLEWarnThreshold>" & CInt(nudPLEWarn.Value).ToString() & "</PLEWarnThreshold>")
        sb.AppendLine("  <PLEFailThreshold>" & CInt(nudPLEFail.Value).ToString() & "</PLEFailThreshold>")

        ' Blocking
        sb.AppendLine("  <CheckBlocking>" & BoolNode(chkBlocking) & "</CheckBlocking>")
        sb.AppendLine("  <BlockingWarnSeconds>" & CInt(nudBlockWarnSec.Value).ToString() & "</BlockingWarnSeconds>")
        sb.AppendLine("  <BlockingFailSeconds>" & CInt(nudBlockFailSec.Value).ToString() & "</BlockingFailSeconds>")

        ' Memory Grants
        sb.AppendLine("  <CheckMemoryGrants>" & BoolNode(chkMemoryGrants) & "</CheckMemoryGrants>")
        sb.AppendLine("  <MemoryGrantsSeverity>" & cboMemGrantsSev.Text & "</MemoryGrantsSeverity>")

        ' Error Log
        sb.AppendLine("  <CheckErrorLog>" & BoolNode(chkErrorLog) & "</CheckErrorLog>")
        sb.AppendLine("  <ErrorLogMinutes>" & CInt(nudErrorLogMin.Value).ToString() & "</ErrorLogMinutes>")
        sb.AppendLine("  <ErrorLogSeverity>" & cboErrorLogSev.Text & "</ErrorLogSeverity>")

        ' Counters
        sb.AppendLine("  <RecordUserCount>" & BoolNode(chkRecordUserCount) & "</RecordUserCount>")
        sb.AppendLine("  <RecordBackupDuration>" & BoolNode(chkRecordBackupDuration) & "</RecordBackupDuration>")

        ' SQL Version
        sb.AppendLine("  <CheckSQLVersion>" & BoolNode(chkSQLVersion) & "</CheckSQLVersion>")
        sb.AppendLine("  <MinSQLVersion>" & CInt(nudMinSQLVersion.Value).ToString() & "</MinSQLVersion>")
        sb.AppendLine("  <SQLVersionSeverity>" & cboVersionSev.Text & "</SQLVersionSeverity>")

        ' Detail Level
        sb.AppendLine("  <DetailLevel>" & cboDetailLevel.SelectedIndex.ToString() & "</DetailLevel>")

        sb.Append("</SQLOverviewMonitor>")
        Return sb.ToString()
    End Function

#End Region

#Region "InitializeComponent"

    Private Sub InitializeComponent()
        Dim W As Integer = 550  ' GroupBox width
        Dim X As Integer = 5    ' GroupBox left

        '── UserControl ───────────────────────────────────────────────────────────
        Me.Size = New Size(580, 525)
        Me.AutoScroll = False

        '── TabControl ────────────────────────────────────────────────────────────
        tcMain.Location = New Point(2, 2)
        tcMain.Size = New Size(574, 515)
        tcMain.TabPages.Add(tpJobs)
        tcMain.TabPages.Add(tpHealth)
        tcMain.TabPages.Add(tpPerf)
        tcMain.TabPages.Add(tpCounters)
        Me.Controls.Add(tcMain)

        tpJobs.Text = "Backup Jobs"
        tpHealth.Text = "Database Health"
        tpPerf.Text = "Performance"
        tpCounters.Text = "Counters && Version"

        '════════════════════════════════════════════════════════════════════════
        '  TAB 1 – Backup Jobs
        '════════════════════════════════════════════════════════════════════════

        '── Connection ────────────────────────────────────────────────────────────
        gbConn.Text = "Connection"
        gbConn.Location = New Point(X, 5)
        gbConn.Size = New Size(W, 65)
        tpJobs.Controls.Add(gbConn)

        gbConn.Controls.Add(MakeLbl("Host name:", 10, 22))
        txtHostName.Location = New Point(90, 19)
        txtHostName.Size = New Size(200, 21)
        gbConn.Controls.Add(txtHostName)

        gbConn.Controls.Add(MakeLbl("Instance:", 300, 22))
        txtInstanceName.Location = New Point(360, 19)
        txtInstanceName.Size = New Size(100, 21)
        gbConn.Controls.Add(txtInstanceName)
        gbConn.Controls.Add(MakeLbl("(blank = default)", 465, 22, Color.Gray))

        '── SQL Agent Service ─────────────────────────────────────────────────────
        gbAgent.Text = "SQL Agent Service"
        gbAgent.Location = New Point(X, 75)
        gbAgent.Size = New Size(W, 50)
        tpJobs.Controls.Add(gbAgent)

        chkAgentService.Text = "Check SQL Agent service is running"
        chkAgentService.AutoSize = True
        chkAgentService.Location = New Point(10, 18)
        gbAgent.Controls.Add(chkAgentService)
        gbAgent.Controls.Add(MakeLbl("Severity:", 330, 20))
        cboAgentSev.Location = New Point(385, 17)
        cboAgentSev.Size = New Size(80, 21)
        AddSevItems(cboAgentSev)
        gbAgent.Controls.Add(cboAgentSev)

        '── Daily Full Backup ─────────────────────────────────────────────────────
        gbDailyBak.Text = "Daily Full Backup"
        gbDailyBak.Location = New Point(X, 130)
        gbDailyBak.Size = New Size(W, 75)
        tpJobs.Controls.Add(gbDailyBak)

        chkDailyBackup.Text = "Check daily full backup job"
        chkDailyBackup.AutoSize = True
        chkDailyBackup.Location = New Point(10, 15)
        gbDailyBak.Controls.Add(chkDailyBackup)
        gbDailyBak.Controls.Add(MakeLbl("Job name:", 10, 45))
        txtDailyJob.Location = New Point(75, 42)
        txtDailyJob.Size = New Size(190, 21)
        gbDailyBak.Controls.Add(txtDailyJob)
        gbDailyBak.Controls.Add(MakeLbl("Max days:", 275, 45))
        nudDailyMaxDays.Location = New Point(333, 42)
        nudDailyMaxDays.Size = New Size(50, 21)
        nudDailyMaxDays.Minimum = 1
        nudDailyMaxDays.Maximum = 365
        gbDailyBak.Controls.Add(nudDailyMaxDays)
        gbDailyBak.Controls.Add(MakeLbl("Severity:", 393, 45))
        cboDailySev.Location = New Point(448, 42)
        cboDailySev.Size = New Size(80, 21)
        AddSevItems(cboDailySev)
        gbDailyBak.Controls.Add(cboDailySev)

        '── Weekly Full Backup ────────────────────────────────────────────────────
        gbWeeklyBak.Text = "Weekly Full Backup"
        gbWeeklyBak.Location = New Point(X, 210)
        gbWeeklyBak.Size = New Size(W, 75)
        tpJobs.Controls.Add(gbWeeklyBak)

        chkWeeklyBackup.Text = "Check weekly full backup job"
        chkWeeklyBackup.AutoSize = True
        chkWeeklyBackup.Location = New Point(10, 15)
        gbWeeklyBak.Controls.Add(chkWeeklyBackup)
        gbWeeklyBak.Controls.Add(MakeLbl("Job name:", 10, 45))
        txtWeeklyJob.Location = New Point(75, 42)
        txtWeeklyJob.Size = New Size(190, 21)
        gbWeeklyBak.Controls.Add(txtWeeklyJob)
        gbWeeklyBak.Controls.Add(MakeLbl("Max days:", 275, 45))
        nudWeeklyMaxDays.Location = New Point(333, 42)
        nudWeeklyMaxDays.Size = New Size(50, 21)
        nudWeeklyMaxDays.Minimum = 1
        nudWeeklyMaxDays.Maximum = 365
        gbWeeklyBak.Controls.Add(nudWeeklyMaxDays)
        gbWeeklyBak.Controls.Add(MakeLbl("Severity:", 393, 45))
        cboWeeklySev.Location = New Point(448, 42)
        cboWeeklySev.Size = New Size(80, 21)
        AddSevItems(cboWeeklySev)
        gbWeeklyBak.Controls.Add(cboWeeklySev)

        '── Transaction Log Backup ────────────────────────────────────────────────
        gbTranslog.Text = "Transaction Log Backup"
        gbTranslog.Location = New Point(X, 290)
        gbTranslog.Size = New Size(W, 75)
        tpJobs.Controls.Add(gbTranslog)

        chkTranslogBackup.Text = "Check transaction log backup job"
        chkTranslogBackup.AutoSize = True
        chkTranslogBackup.Location = New Point(10, 15)
        gbTranslog.Controls.Add(chkTranslogBackup)
        gbTranslog.Controls.Add(MakeLbl("Job name:", 10, 45))
        txtTranslogJob.Location = New Point(75, 42)
        txtTranslogJob.Size = New Size(190, 21)
        gbTranslog.Controls.Add(txtTranslogJob)
        gbTranslog.Controls.Add(MakeLbl("Max min:", 275, 45))
        nudTranslogMaxMin.Location = New Point(333, 42)
        nudTranslogMaxMin.Size = New Size(50, 21)
        nudTranslogMaxMin.Minimum = 1
        nudTranslogMaxMin.Maximum = 1440
        gbTranslog.Controls.Add(nudTranslogMaxMin)
        gbTranslog.Controls.Add(MakeLbl("Severity:", 393, 45))
        cboTranslogSev.Location = New Point(448, 42)
        cboTranslogSev.Size = New Size(80, 21)
        AddSevItems(cboTranslogSev)
        gbTranslog.Controls.Add(cboTranslogSev)

        '── Integrity Check ───────────────────────────────────────────────────────
        gbIntegrity.Text = "Integrity Check (DBCC)"
        gbIntegrity.Location = New Point(X, 370)
        gbIntegrity.Size = New Size(W, 75)
        tpJobs.Controls.Add(gbIntegrity)

        chkIntegrityJobs.Text = "Check integrity check job"
        chkIntegrityJobs.AutoSize = True
        chkIntegrityJobs.Location = New Point(10, 15)
        gbIntegrity.Controls.Add(chkIntegrityJobs)
        gbIntegrity.Controls.Add(MakeLbl("Job name:", 10, 45))
        txtIntegrityJob.Location = New Point(75, 42)
        txtIntegrityJob.Size = New Size(190, 21)
        gbIntegrity.Controls.Add(txtIntegrityJob)
        gbIntegrity.Controls.Add(MakeLbl("Max days:", 275, 45))
        nudIntegrityMaxDays.Location = New Point(333, 42)
        nudIntegrityMaxDays.Size = New Size(50, 21)
        nudIntegrityMaxDays.Minimum = 1
        nudIntegrityMaxDays.Maximum = 365
        gbIntegrity.Controls.Add(nudIntegrityMaxDays)
        gbIntegrity.Controls.Add(MakeLbl("Severity:", 393, 45))
        cboIntegritySev.Location = New Point(448, 42)
        cboIntegritySev.Size = New Size(80, 21)
        AddSevItems(cboIntegritySev)
        gbIntegrity.Controls.Add(cboIntegritySev)

        '════════════════════════════════════════════════════════════════════════
        '  TAB 2 – Database Health
        '════════════════════════════════════════════════════════════════════════

        '── Exhaustive Backup Check ───────────────────────────────────────────────
        gbExhaustive.Text = "Exhaustive Backup Check"
        gbExhaustive.Location = New Point(X, 5)
        gbExhaustive.Size = New Size(W, 95)
        tpHealth.Controls.Add(gbExhaustive)

        chkExhaustiveBackup.Text = "Check all databases have been backed up recently"
        chkExhaustiveBackup.AutoSize = True
        chkExhaustiveBackup.Location = New Point(10, 15)
        gbExhaustive.Controls.Add(chkExhaustiveBackup)
        gbExhaustive.Controls.Add(MakeLbl("Severity:", 10, 45))
        cboExhSev.Location = New Point(65, 42)
        cboExhSev.Size = New Size(80, 21)
        AddSevItems(cboExhSev)
        gbExhaustive.Controls.Add(cboExhSev)
        gbExhaustive.Controls.Add(MakeLbl("Max days:", 155, 45))
        nudExhMaxDays.Location = New Point(213, 42)
        nudExhMaxDays.Size = New Size(50, 21)
        nudExhMaxDays.Minimum = 1
        nudExhMaxDays.Maximum = 365
        gbExhaustive.Controls.Add(nudExhMaxDays)
        gbExhaustive.Controls.Add(MakeLbl("Ignore DBs (comma-separated):", 10, 72))
        txtExhIgnore.Location = New Point(210, 69)
        txtExhIgnore.Size = New Size(328, 21)
        gbExhaustive.Controls.Add(txtExhIgnore)

        '── Database Status ───────────────────────────────────────────────────────
        gbDBStatus.Text = "Database Status"
        gbDBStatus.Location = New Point(X, 105)
        gbDBStatus.Size = New Size(W, 50)
        tpHealth.Controls.Add(gbDBStatus)

        chkDBStatus.Text = "Check for unhealthy database states (SUSPECT, RECOVERY_PENDING, etc.)"
        chkDBStatus.AutoSize = True
        chkDBStatus.Location = New Point(10, 17)
        gbDBStatus.Controls.Add(chkDBStatus)
        gbDBStatus.Controls.Add(MakeLbl("Severity:", 390, 20))
        cboDBStatusSev.Location = New Point(445, 17)
        cboDBStatusSev.Size = New Size(80, 21)
        AddSevItems(cboDBStatusSev)
        gbDBStatus.Controls.Add(cboDBStatusSev)

        '── Recovery Model ────────────────────────────────────────────────────────
        gbRecovModel.Text = "Recovery Model"
        gbRecovModel.Location = New Point(X, 160)
        gbRecovModel.Size = New Size(W, 75)
        tpHealth.Controls.Add(gbRecovModel)

        chkRecoveryModel.Text = "Check recovery model (alert on unexpected Simple-mode databases)"
        chkRecoveryModel.AutoSize = True
        chkRecoveryModel.Location = New Point(10, 15)
        gbRecovModel.Controls.Add(chkRecoveryModel)
        gbRecovModel.Controls.Add(MakeLbl("Severity:", 390, 18))
        cboRecovSev.Location = New Point(445, 15)
        cboRecovSev.Size = New Size(80, 21)
        AddSevItems(cboRecovSev)
        gbRecovModel.Controls.Add(cboRecovSev)
        gbRecovModel.Controls.Add(MakeLbl("Allow Simple model on:", 10, 47))
        txtApprovedSimple.Location = New Point(155, 44)
        txtApprovedSimple.Size = New Size(383, 21)
        gbRecovModel.Controls.Add(txtApprovedSimple)

        '── Log File Ratio ────────────────────────────────────────────────────────
        gbLogRatio.Text = "Log File Size Ratio"
        gbLogRatio.Location = New Point(X, 240)
        gbLogRatio.Size = New Size(W, 50)
        tpHealth.Controls.Add(gbLogRatio)

        chkLogfileRatio.Text = "Alert if transaction log is large relative to database size"
        chkLogfileRatio.AutoSize = True
        chkLogfileRatio.Location = New Point(10, 17)
        gbLogRatio.Controls.Add(chkLogfileRatio)
        gbLogRatio.Controls.Add(MakeLbl("Max %:", 330, 20))
        nudLogRatioMaxPct.Location = New Point(375, 17)
        nudLogRatioMaxPct.Size = New Size(50, 21)
        nudLogRatioMaxPct.Minimum = 1
        nudLogRatioMaxPct.Maximum = 100
        gbLogRatio.Controls.Add(nudLogRatioMaxPct)
        gbLogRatio.Controls.Add(MakeLbl("Severity:", 435, 20))
        cboLogRatioSev.Location = New Point(490, 17)
        cboLogRatioSev.Size = New Size(50, 21)
        AddSevItems(cboLogRatioSev)
        gbLogRatio.Controls.Add(cboLogRatioSev)

        '── DB Datafile Freespace ─────────────────────────────────────────────────
        gbDBFreespace.Text = "Database Datafile Free Space"
        gbDBFreespace.Location = New Point(X, 295)
        gbDBFreespace.Size = New Size(W, 50)
        tpHealth.Controls.Add(gbDBFreespace)

        chkDBFreespace.Text = "Check database datafile free space"
        chkDBFreespace.AutoSize = True
        chkDBFreespace.Location = New Point(10, 17)
        gbDBFreespace.Controls.Add(chkDBFreespace)
        gbDBFreespace.Controls.Add(MakeLbl("Warn %:", 300, 20))
        nudDBFreeWarnPct.Location = New Point(350, 17)
        nudDBFreeWarnPct.Size = New Size(50, 21)
        nudDBFreeWarnPct.Minimum = 1
        nudDBFreeWarnPct.Maximum = 99
        gbDBFreespace.Controls.Add(nudDBFreeWarnPct)
        gbDBFreespace.Controls.Add(MakeLbl("Fail %:", 410, 20))
        nudDBFreeFailPct.Location = New Point(452, 17)
        nudDBFreeFailPct.Size = New Size(50, 21)
        nudDBFreeFailPct.Minimum = 1
        nudDBFreeFailPct.Maximum = 99
        gbDBFreespace.Controls.Add(nudDBFreeFailPct)

        '── DBs on C: Drive (standalone) ─────────────────────────────────────────
        chkDBsOnCDrive.Text = "Alert if any database files are located on the C: drive"
        chkDBsOnCDrive.AutoSize = True
        chkDBsOnCDrive.Location = New Point(X + 5, 352)
        tpHealth.Controls.Add(chkDBsOnCDrive)

        '════════════════════════════════════════════════════════════════════════
        '  TAB 3 – Performance
        '════════════════════════════════════════════════════════════════════════

        '── Drive Freespace (WMI) ─────────────────────────────────────────────────
        gbDriveFreespace.Text = "Host Drive Free Space (WMI)"
        gbDriveFreespace.Location = New Point(X, 5)
        gbDriveFreespace.Size = New Size(W, 50)
        tpPerf.Controls.Add(gbDriveFreespace)

        chkDriveFreespace.Text = "Check host drive free space via WMI"
        chkDriveFreespace.AutoSize = True
        chkDriveFreespace.Location = New Point(10, 17)
        gbDriveFreespace.Controls.Add(chkDriveFreespace)
        gbDriveFreespace.Controls.Add(MakeLbl("Warn %:", 300, 20))
        nudDriveFreeWarnPct.Location = New Point(350, 17)
        nudDriveFreeWarnPct.Size = New Size(50, 21)
        nudDriveFreeWarnPct.Minimum = 1
        nudDriveFreeWarnPct.Maximum = 99
        gbDriveFreespace.Controls.Add(nudDriveFreeWarnPct)
        gbDriveFreespace.Controls.Add(MakeLbl("Fail %:", 410, 20))
        nudDriveFreeFailPct.Location = New Point(452, 17)
        nudDriveFreeFailPct.Size = New Size(50, 21)
        nudDriveFreeFailPct.Minimum = 1
        nudDriveFreeFailPct.Maximum = 99
        gbDriveFreespace.Controls.Add(nudDriveFreeFailPct)

        '── Page Life Expectancy ──────────────────────────────────────────────────
        gbPLE.Text = "Page Life Expectancy"
        gbPLE.Location = New Point(X, 60)
        gbPLE.Size = New Size(W, 50)
        tpPerf.Controls.Add(gbPLE)

        chkPLE.Text = "Check Page Life Expectancy"
        chkPLE.AutoSize = True
        chkPLE.Location = New Point(10, 17)
        gbPLE.Controls.Add(chkPLE)
        gbPLE.Controls.Add(MakeLbl("Warn (sec):", 240, 20))
        nudPLEWarn.Location = New Point(308, 17)
        nudPLEWarn.Size = New Size(70, 21)
        nudPLEWarn.Minimum = 100
        nudPLEWarn.Maximum = 100000
        gbPLE.Controls.Add(nudPLEWarn)
        gbPLE.Controls.Add(MakeLbl("Fail (sec):", 390, 20))
        nudPLEFail.Location = New Point(455, 17)
        nudPLEFail.Size = New Size(70, 21)
        nudPLEFail.Minimum = 100
        nudPLEFail.Maximum = 100000
        gbPLE.Controls.Add(nudPLEFail)

        '── Blocking ──────────────────────────────────────────────────────────────
        gbBlocking.Text = "Blocking"
        gbBlocking.Location = New Point(X, 115)
        gbBlocking.Size = New Size(W, 50)
        tpPerf.Controls.Add(gbBlocking)

        chkBlocking.Text = "Check for blocking"
        chkBlocking.AutoSize = True
        chkBlocking.Location = New Point(10, 17)
        gbBlocking.Controls.Add(chkBlocking)
        gbBlocking.Controls.Add(MakeLbl("Warn (sec):", 200, 20))
        nudBlockWarnSec.Location = New Point(268, 17)
        nudBlockWarnSec.Size = New Size(60, 21)
        nudBlockWarnSec.Minimum = 1
        nudBlockWarnSec.Maximum = 3600
        gbBlocking.Controls.Add(nudBlockWarnSec)
        gbBlocking.Controls.Add(MakeLbl("Fail (sec):", 340, 20))
        nudBlockFailSec.Location = New Point(403, 17)
        nudBlockFailSec.Size = New Size(60, 21)
        nudBlockFailSec.Minimum = 1
        nudBlockFailSec.Maximum = 3600
        gbBlocking.Controls.Add(nudBlockFailSec)

        '── Memory Grants Pending ─────────────────────────────────────────────────
        gbMemGrants.Text = "Memory Grants Pending"
        gbMemGrants.Location = New Point(X, 170)
        gbMemGrants.Size = New Size(W, 50)
        tpPerf.Controls.Add(gbMemGrants)

        chkMemoryGrants.Text = "Alert if memory grants are pending (memory pressure indicator)"
        chkMemoryGrants.AutoSize = True
        chkMemoryGrants.Location = New Point(10, 17)
        gbMemGrants.Controls.Add(chkMemoryGrants)
        gbMemGrants.Controls.Add(MakeLbl("Severity:", 380, 20))
        cboMemGrantsSev.Location = New Point(435, 17)
        cboMemGrantsSev.Size = New Size(80, 21)
        AddSevItems(cboMemGrantsSev)
        gbMemGrants.Controls.Add(cboMemGrantsSev)

        '── Error Log ─────────────────────────────────────────────────────────────
        gbErrorLog.Text = "SQL Error Log (Severity 17+)"
        gbErrorLog.Location = New Point(X, 225)
        gbErrorLog.Size = New Size(W, 75)
        tpPerf.Controls.Add(gbErrorLog)

        chkErrorLog.Text = "Scan SQL error log for severity 17+ errors"
        chkErrorLog.AutoSize = True
        chkErrorLog.Location = New Point(10, 15)
        gbErrorLog.Controls.Add(chkErrorLog)
        gbErrorLog.Controls.Add(MakeLbl("Look-back (min):", 10, 47))
        nudErrorLogMin.Location = New Point(115, 44)
        nudErrorLogMin.Size = New Size(60, 21)
        nudErrorLogMin.Minimum = 1
        nudErrorLogMin.Maximum = 1440
        gbErrorLog.Controls.Add(nudErrorLogMin)
        gbErrorLog.Controls.Add(MakeLbl("Severity:", 185, 47))
        cboErrorLogSev.Location = New Point(238, 44)
        cboErrorLogSev.Size = New Size(80, 21)
        AddSevItems(cboErrorLogSev)
        gbErrorLog.Controls.Add(cboErrorLogSev)

        '════════════════════════════════════════════════════════════════════════
        '  TAB 4 – Counters & Version
        '════════════════════════════════════════════════════════════════════════

        '── Counters ──────────────────────────────────────────────────────────────
        gbCounters.Text = "Counters (for graphing)"
        gbCounters.Location = New Point(X, 5)
        gbCounters.Size = New Size(W, 60)
        tpCounters.Controls.Add(gbCounters)

        chkRecordUserCount.Text = "Record active user connection count"
        chkRecordUserCount.AutoSize = True
        chkRecordUserCount.Location = New Point(10, 15)
        gbCounters.Controls.Add(chkRecordUserCount)

        chkRecordBackupDuration.Text = "Record last full backup job duration (minutes)"
        chkRecordBackupDuration.AutoSize = True
        chkRecordBackupDuration.Location = New Point(10, 35)
        gbCounters.Controls.Add(chkRecordBackupDuration)

        '── SQL Server Version ────────────────────────────────────────────────────
        gbSQLVersion.Text = "SQL Server Version"
        gbSQLVersion.Location = New Point(X, 70)
        gbSQLVersion.Size = New Size(W, 80)
        tpCounters.Controls.Add(gbSQLVersion)

        chkSQLVersion.Text = "Alert if SQL Server is below minimum version"
        chkSQLVersion.AutoSize = True
        chkSQLVersion.Location = New Point(10, 15)
        gbSQLVersion.Controls.Add(chkSQLVersion)
        gbSQLVersion.Controls.Add(MakeLbl("Min version:", 10, 48))
        nudMinSQLVersion.Location = New Point(90, 45)
        nudMinSQLVersion.Size = New Size(50, 21)
        nudMinSQLVersion.Minimum = 7
        nudMinSQLVersion.Maximum = 16
        nudMinSQLVersion.Value = 13
        gbSQLVersion.Controls.Add(nudMinSQLVersion)
        lblVersionName.Text = "= " & VersionLabel(13)
        lblVersionName.AutoSize = True
        lblVersionName.Location = New Point(148, 48)
        lblVersionName.ForeColor = Color.MediumBlue
        gbSQLVersion.Controls.Add(lblVersionName)
        gbSQLVersion.Controls.Add(MakeLbl("Severity:", 380, 48))
        cboVersionSev.Location = New Point(435, 45)
        cboVersionSev.Size = New Size(80, 21)
        AddSevItems(cboVersionSev)
        gbSQLVersion.Controls.Add(cboVersionSev)

        '── Output ────────────────────────────────────────────────────────────────
        gbOutput.Text = "Output"
        gbOutput.Location = New Point(X, 155)
        gbOutput.Size = New Size(W, 50)
        tpCounters.Controls.Add(gbOutput)

        gbOutput.Controls.Add(MakeLbl("Detail level:", 10, 20))
        cboDetailLevel.Location = New Point(88, 17)
        cboDetailLevel.Size = New Size(200, 21)
        cboDetailLevel.DropDownStyle = ComboBoxStyle.DropDownList
        cboDetailLevel.Items.Add("0 - Problems only")
        cboDetailLevel.Items.Add("1 - Include OK items")
        cboDetailLevel.SelectedIndex = 0
        gbOutput.Controls.Add(cboDetailLevel)
    End Sub

#End Region

#Region "Helper Methods"

    ''' <summary>Enable or disable all controls inside a GroupBox except the anchor checkbox.</summary>
    Private Sub ToggleGroup(ByVal gb As GroupBox, ByVal anchor As CheckBox)
        For Each ctrl As Control In gb.Controls
            If ctrl IsNot anchor Then
                ctrl.Enabled = anchor.Checked
            End If
        Next
    End Sub

    ''' <summary>Create a label with optional foreground colour.</summary>
    Private Function MakeLbl(ByVal text As String, ByVal x As Integer, ByVal y As Integer,
                              Optional ByVal foreColor As Color = Nothing) As Label
        Dim l As New Label
        l.AutoSize = True
        l.Text = text
        l.Location = New Point(x, y)
        If Not foreColor.IsEmpty Then l.ForeColor = foreColor
        Return l
    End Function

    ''' <summary>Add "Warn" / "Fail" items to a severity ComboBox.</summary>
    Private Sub AddSevItems(ByVal cbo As ComboBox)
        cbo.DropDownStyle = ComboBoxStyle.DropDownList
        cbo.Items.Add("Warn")
        cbo.Items.Add("Fail")
        cbo.SelectedIndex = 0
    End Sub

    ''' <summary>Select a ComboBox item by text (case-insensitive), default to index 0.</summary>
    Private Sub SetCombo(ByVal cbo As ComboBox, ByVal value As String)
        For i As Integer = 0 To cbo.Items.Count - 1
            If String.Compare(cbo.Items(i).ToString(), value, StringComparison.OrdinalIgnoreCase) = 0 Then
                cbo.SelectedIndex = i
                Return
            End If
        Next
        If cbo.Items.Count > 0 Then cbo.SelectedIndex = 0
    End Sub

    ''' <summary>Read an XML node value; return empty string if missing.</summary>
    Private Function ReadNode(ByVal root As XmlNode, ByVal name As String) As String
        Dim node As XmlNode = root.SelectSingleNode(name)
        If node Is Nothing OrElse String.IsNullOrEmpty(node.InnerText) Then Return ""
        Return node.InnerText.Trim()
    End Function

    ''' <summary>Read an XML node as Boolean (1 = True).</summary>
    Private Function NodeBool(ByVal root As XmlNode, ByVal name As String) As Boolean
        Return ReadNode(root, name) = "1"
    End Function

    ''' <summary>Read an XML node as Integer; return default if missing or non-numeric.</summary>
    Private Function NodeInt(ByVal root As XmlNode, ByVal name As String, ByVal def As Integer) As Integer
        Dim val As String = ReadNode(root, name)
        Dim result As Integer
        If Integer.TryParse(val, result) Then Return result
        Return def
    End Function

    ''' <summary>Return "1" or "0" from a CheckBox's Checked state.</summary>
    Private Function BoolNode(ByVal chk As CheckBox) As String
        Return If(chk.Checked, "1", "0")
    End Function

    ''' <summary>Return friendly SQL Server name for a major version number.</summary>
    Private Function VersionLabel(ByVal major As Integer) As String
        Select Case major
            Case 7 : Return "SQL Server 7.0"
            Case 8 : Return "SQL Server 2000"
            Case 9 : Return "SQL Server 2005"
            Case 10 : Return "SQL Server 2008/R2"
            Case 11 : Return "SQL Server 2012"
            Case 12 : Return "SQL Server 2014"
            Case 13 : Return "SQL Server 2016"
            Case 14 : Return "SQL Server 2017"
            Case 15 : Return "SQL Server 2019"
            Case 16 : Return "SQL Server 2022"
            Case Else : Return "SQL Server (v" & major & ")"
        End Select
    End Function

    Private Function XMLEncode(ByVal s As String) As String
        If String.IsNullOrEmpty(s) Then Return s
        s = s.Replace("&", "&amp;")
        s = s.Replace("<", "&lt;")
        s = s.Replace(">", "&gt;")
        s = s.Replace("""", "&quot;")
        s = s.Replace("'", "&apos;")
        Return s
    End Function

#End Region

End Class
