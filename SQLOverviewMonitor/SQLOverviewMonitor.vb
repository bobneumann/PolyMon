Imports System.IO
Imports System.Text
Imports System.Xml
Imports System.Management.Automation
Imports PolyMon.Status

Namespace Monitors
    Public Class SQLOverviewMonitor
        Inherits PolyMon.Monitors.MonitorExecutor

        Public Sub New(ByVal MonitorID As Integer)
            MyBase.New(MonitorID)
        End Sub

        Protected Overrides Function MonitorTest(ByRef StatusMessage As String, ByRef Counters As CounterList) As MonitorExecutor.MonitorStatus
            Dim myRunspace As Runspaces.Runspace = Nothing

            Try
                Dim myStatus As New PSStatus()
                Dim myCounters As New PSCounters()

                Dim script As String = BuildScript()

                myRunspace = Runspaces.RunspaceFactory.CreateRunspace()
                myRunspace.Open()

                Dim myPipeline As Runspaces.Pipeline = myRunspace.CreatePipeline(script)
                myRunspace.SessionStateProxy.SetVariable("Status", myStatus)
                myRunspace.SessionStateProxy.SetVariable("Counters", myCounters)
                myPipeline.Invoke()

                StatusMessage = myStatus.StatusText
                For Each myCounter As PSCounter In myCounters.Items
                    Counters.Add(New Counter(myCounter.CounterName, myCounter.CounterValue))
                Next
                Return CType(myStatus.StatusID, PolyMon.Monitors.MonitorExecutor.MonitorStatus)
            Catch ex As Exception
                StatusMessage = ex.Message
                If ex.InnerException IsNot Nothing Then
                    StatusMessage &= vbCrLf & ex.InnerException.Message
                End If
                Return MonitorExecutor.MonitorStatus.Fail
            Finally
                If myRunspace IsNot Nothing Then
                    If myRunspace.RunspaceStateInfo.State <> Runspaces.RunspaceState.Closed Then myRunspace.Close()
                    myRunspace.Dispose()
                End If
            End Try
        End Function

        Private Function BuildScript() As String
            Dim root As XmlNode = Me.MonitorXML.DocumentElement
            Dim modulePath As String = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "PSModules", "PolyMon_SQLHealth", "PolyMon_SQLHealth.psm1")

            Dim params As New List(Of String)

            ' Connection (always present)
            params.Add("    HostName = '" & Esc(ReadNode(root, "HostName")) & "'")
            params.Add("    InstanceName = '" & Esc(ReadNode(root, "InstanceName")) & "'")

            ' SQL Agent Service
            If NodeBool(root, "CheckAgentService") Then
                params.Add("    CheckAgentService = $true")
                params.Add("    AgentServiceSeverity = '" & ReadNode(root, "AgentServiceSeverity") & "'")
            End If

            ' Daily Full Backup
            If NodeBool(root, "CheckDailyBackup") Then
                params.Add("    CheckDailyBackup = $true")
                params.Add("    DailyBackupJobName = '" & Esc(ReadNode(root, "DailyBackupJobName")) & "'")
                params.Add("    DailyBackupSeverity = '" & ReadNode(root, "DailyBackupSeverity") & "'")
                params.Add("    DailyBackupMaxDays = " & ReadNode(root, "DailyBackupMaxDays"))
            End If

            ' Weekly Full Backup
            If NodeBool(root, "CheckWeeklyBackup") Then
                params.Add("    CheckWeeklyBackup = $true")
                params.Add("    WeeklyBackupJobName = '" & Esc(ReadNode(root, "WeeklyBackupJobName")) & "'")
                params.Add("    WeeklyBackupSeverity = '" & ReadNode(root, "WeeklyBackupSeverity") & "'")
                params.Add("    WeeklyBackupMaxDays = " & ReadNode(root, "WeeklyBackupMaxDays"))
            End If

            ' Transaction Log Backup
            If NodeBool(root, "CheckTranslogBackup") Then
                params.Add("    CheckTranslogBackup = $true")
                params.Add("    TranslogJobName = '" & Esc(ReadNode(root, "TranslogJobName")) & "'")
                params.Add("    TranslogSeverity = '" & ReadNode(root, "TranslogSeverity") & "'")
                params.Add("    TranslogMaxMinutes = " & ReadNode(root, "TranslogMaxMinutes"))
            End If

            ' Integrity Check
            If NodeBool(root, "CheckIntegrityJobs") Then
                params.Add("    CheckIntegrityJobs = $true")
                params.Add("    IntegrityJobName = '" & Esc(ReadNode(root, "IntegrityJobName")) & "'")
                params.Add("    IntegritySeverity = '" & ReadNode(root, "IntegritySeverity") & "'")
                params.Add("    IntegrityMaxDays = " & ReadNode(root, "IntegrityMaxDays"))
            End If

            ' Exhaustive Backup Check
            If NodeBool(root, "CheckExhaustiveBackup") Then
                params.Add("    CheckExhaustiveBackup = $true")
                params.Add("    ExhaustiveBackupSeverity = '" & ReadNode(root, "ExhaustiveBackupSeverity") & "'")
                params.Add("    ExhaustiveBackupMaxDays = " & ReadNode(root, "ExhaustiveBackupMaxDays"))
                Dim ignoreList As String = ReadNode(root, "ExhaustiveBackupIgnore")
                If Not String.IsNullOrEmpty(ignoreList.Trim()) Then
                    params.Add("    ExhaustiveBackupIgnore = " & ToPSArray(ignoreList))
                End If
            End If

            ' Database Status
            If NodeBool(root, "CheckDBStatus") Then
                params.Add("    CheckDBStatus = $true")
                params.Add("    DBStatusSeverity = '" & ReadNode(root, "DBStatusSeverity") & "'")
            End If

            ' Recovery Model
            If NodeBool(root, "CheckRecoveryModel") Then
                params.Add("    CheckRecoveryModel = $true")
                params.Add("    RecoveryModelSeverity = '" & ReadNode(root, "RecoveryModelSeverity") & "'")
                Dim approvedSimple As String = ReadNode(root, "ApprovedSimpleDBs")
                If Not String.IsNullOrEmpty(approvedSimple.Trim()) Then
                    params.Add("    ApprovedSimpleDBs = " & ToPSArray(approvedSimple))
                End If
            End If

            ' Log File Ratio
            If NodeBool(root, "CheckLogfileRatio") Then
                params.Add("    CheckLogfileRatio = $true")
                params.Add("    LogfileRatioSeverity = '" & ReadNode(root, "LogfileRatioSeverity") & "'")
                params.Add("    LogfileRatioMaxPct = " & ReadNode(root, "LogfileRatioMaxPct"))
            End If

            ' DB Datafile Freespace
            If NodeBool(root, "CheckDBFreespace") Then
                params.Add("    CheckDBFreespace = $true")
                params.Add("    DBFreespaceWarnPct = " & ReadNode(root, "DBFreespaceWarnPct"))
                params.Add("    DBFreespaceFailPct = " & ReadNode(root, "DBFreespaceFailPct"))
            End If

            ' Databases on C: Drive
            If NodeBool(root, "CheckDBsOnCDrive") Then
                params.Add("    CheckDBsOnCDrive = $true")
            End If

            ' Drive Freespace (WMI)
            If NodeBool(root, "CheckDriveFreespace") Then
                params.Add("    CheckDriveFreespace = $true")
                params.Add("    DriveFreespaceWarnPct = " & ReadNode(root, "DriveFreespaceWarnPct"))
                params.Add("    DriveFreespaceFailPct = " & ReadNode(root, "DriveFreespaceFailPct"))
            End If

            ' Page Life Expectancy
            If NodeBool(root, "CheckPLE") Then
                params.Add("    CheckPLE = $true")
                params.Add("    PLEWarnThreshold = " & ReadNode(root, "PLEWarnThreshold"))
                params.Add("    PLEFailThreshold = " & ReadNode(root, "PLEFailThreshold"))
            End If

            ' Blocking
            If NodeBool(root, "CheckBlocking") Then
                params.Add("    CheckBlocking = $true")
                params.Add("    BlockingWarnSeconds = " & ReadNode(root, "BlockingWarnSeconds"))
                params.Add("    BlockingFailSeconds = " & ReadNode(root, "BlockingFailSeconds"))
            End If

            ' Memory Grants Pending
            If NodeBool(root, "CheckMemoryGrants") Then
                params.Add("    CheckMemoryGrants = $true")
                params.Add("    MemoryGrantsSeverity = '" & ReadNode(root, "MemoryGrantsSeverity") & "'")
            End If

            ' Error Log
            If NodeBool(root, "CheckErrorLog") Then
                params.Add("    CheckErrorLog = $true")
                params.Add("    ErrorLogMinutes = " & ReadNode(root, "ErrorLogMinutes"))
                params.Add("    ErrorLogSeverity = '" & ReadNode(root, "ErrorLogSeverity") & "'")
            End If

            ' Counters
            If NodeBool(root, "RecordUserCount") Then params.Add("    RecordUserCount = $true")
            If NodeBool(root, "RecordBackupDuration") Then params.Add("    RecordBackupDuration = $true")

            ' SQL Server Version
            If NodeBool(root, "CheckSQLVersion") Then
                params.Add("    CheckSQLVersion = $true")
                params.Add("    MinSQLVersion = " & ReadNode(root, "MinSQLVersion"))
                params.Add("    SQLVersionSeverity = '" & ReadNode(root, "SQLVersionSeverity") & "'")
            End If

            ' Detail Level (always)
            params.Add("    DetailLevel = " & ReadNode(root, "DetailLevel"))

            Dim sb As New StringBuilder
            sb.AppendLine("Import-Module '" & modulePath.Replace("'", "''") & "' -Force")
            sb.AppendLine("$params = @{")
            sb.AppendLine(String.Join(vbCrLf, params))
            sb.AppendLine("}")
            sb.AppendLine("SQL_Overview @params")

            Return sb.ToString()
        End Function

        Private Function ReadNode(ByVal root As XmlNode, ByVal name As String) As String
            Dim node As XmlNode = root.SelectSingleNode(name)
            If node Is Nothing OrElse String.IsNullOrEmpty(node.InnerText) Then Return ""
            Return node.InnerText.Trim()
        End Function

        Private Function NodeBool(ByVal root As XmlNode, ByVal name As String) As Boolean
            Return ReadNode(root, name) = "1"
        End Function

        ''' <summary>Escape single quotes for use inside PS single-quoted strings.</summary>
        Private Function Esc(ByVal s As String) As String
            Return s.Replace("'", "''")
        End Function

        ''' <summary>Convert a comma-separated list to a PowerShell array literal: @('a','b','c')</summary>
        Private Function ToPSArray(ByVal csv As String) As String
            Dim items() As String = csv.Split(","c)
            Dim parts As New List(Of String)
            For Each item As String In items
                Dim trimmed As String = item.Trim()
                If trimmed.Length > 0 Then
                    parts.Add("'" & trimmed.Replace("'", "''") & "'")
                End If
            Next
            If parts.Count = 0 Then Return "@()"
            Return "@(" & String.Join(",", parts) & ")"
        End Function

        '─── Helper classes injected into PowerShell runspace ────────────────────

        Public Class PSStatus
            Private mStatusText As String
            Private mStatusID As StatusCodes

            Public Enum StatusCodes As Integer
                OK = 1
                Warn = 2
                Fail = 3
            End Enum

            Public Property StatusText() As String
                Get
                    Return mStatusText
                End Get
                Set(ByVal value As String)
                    mStatusText = value
                End Set
            End Property

            Public Property StatusID() As StatusCodes
                Get
                    Return mStatusID
                End Get
                Set(ByVal value As StatusCodes)
                    mStatusID = value
                End Set
            End Property
        End Class

        Public Class PSCounter
            Private mCounterName As String
            Private mCounterValue As Double

            Public Sub New(ByVal CounterName As String, ByVal CounterValue As Double)
                mCounterName = CounterName
                mCounterValue = CounterValue
            End Sub

            Public ReadOnly Property CounterName() As String
                Get
                    Return mCounterName
                End Get
            End Property

            Public ReadOnly Property CounterValue() As Double
                Get
                    Return mCounterValue
                End Get
            End Property
        End Class

        Public Class PSCounters
            Private mCounters As New List(Of PSCounter)

            Public Sub Add(ByVal CounterName As String, ByVal CounterValue As Double)
                mCounters.Add(New PSCounter(CounterName, CounterValue))
            End Sub

            Friend ReadOnly Property Items() As List(Of PSCounter)
                Get
                    Return mCounters
                End Get
            End Property
        End Class

    End Class
End Namespace
