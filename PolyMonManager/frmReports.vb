Imports System.Data.SqlClient

Public Class frmReports
#Region "Private Attributes"
	Private mMonitorID As Integer
	Private mSQLConn As String
	Private mSysSettings As PolyMon.General.SysSettings

	' Chart toggle tracking: maps TableLayoutPanel -> (chart title -> FormsPlot)
	Private mChartRegistry As New Dictionary(Of TableLayoutPanel, Dictionary(Of String, ScottPlot.FormsPlot))

	Private Const cFormatDate As String = "MMM dd, yyyy"
	Private Const cFormatDateHM As String = "MMM dd, yyyy HH:mm"
	Private Const cFormatDateHMS As String = "MMM dd, yyyy HH:mm:ss"
	Private Const cFormatDateHMSm As String = "MMM dd, yyyy HH:mm:ss.fff"

	Private Const cChartWidth As Integer = 460
	Private Const cChartHeight As Integer = 220

	Private mMonitorStatusDateRanges As MonitorStatusDateRanges

	Private mStatusData_Daily As DataTable = Nothing
	Private mStatusData_Weekly As DataTable = Nothing
	Private mStatusData_Monthly As DataTable = Nothing
	Private mStatusData_Custom As DataTable = Nothing

	Private mCounterData_Daily As DataTable = Nothing
	Private mCounterData_Weekly As DataTable = Nothing
	Private mCounterData_Monthly As DataTable = Nothing
	Private mCounterData_Custom As DataTable = Nothing

	Private cDefSymbolMaxPts As Integer = 100
	Private cDefMaxDataPts As Integer = 4000
	Private mMaxDataPts As Integer
	Private mSymbolMaxPts As Integer
	Private Const cMaxReachedMsg As String = "Charts can display a maximum of {0} data points." & vbCrLf & "Limit exceeded." & vbCrLf & "Please view data by clicking on the ""View Data"" button."
#End Region

#Region "Public Interface"
	Public Sub New(ByVal MonitorID As Integer)
		' This call is required by the Windows Form Designer.
		InitializeComponent()

		' Add any initialization after the InitializeComponent() call.
		mMonitorID = MonitorID
		mSQLConn = CStr(System.Configuration.ConfigurationManager.AppSettings("SQLConn"))
		If System.Configuration.ConfigurationManager.AppSettings("ChartMaxDataPts") Is Nothing Then
			mMaxDataPts = cDefMaxDataPts
		Else
			mMaxDataPts = CInt(System.Configuration.ConfigurationManager.AppSettings("ChartMaxDataPts"))
		End If
		If System.Configuration.ConfigurationManager.AppSettings("SymbolMaxPts") Is Nothing Then
			mSymbolMaxPts = cDefSymbolMaxPts
		Else
			mSymbolMaxPts = CInt(System.Configuration.ConfigurationManager.AppSettings("SymbolMaxPts"))
		End If

		Try
			mMonitorStatusDateRanges = New MonitorStatusDateRanges(MonitorID, mSQLConn)
		Finally
			'Do nothing!
		End Try

		Try
			mSysSettings = New PolyMon.General.SysSettings()
		Catch ex As Exception
			' If settings can't be loaded, mSysSettings remains Nothing; defaults will apply
		End Try
	End Sub
#End Region

#Region "Event Handlers"
	Private Sub frmReports_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        Me.Cursor = Cursors.WaitCursor
        WireFlpPanel(flpChartsOverview, ChartsOverview)
        WireFlpPanel(flpChartsDaily, ChartsDaily)
        WireFlpPanel(flpChartsWeekly, ChartsWeekly)
        WireFlpPanel(flpChartsMonthly, ChartsMonthly)
        WireFlpPanel(flpChartsCustom, ChartsCustom)
        RefreshOverview()
        Me.Cursor = Cursors.Default
    End Sub

    ''' <summary>
    ''' Constrains a FlowLayoutPanel to wrap checkboxes within its width,
    ''' and repositions the TableLayoutPanel below it when it grows.
    ''' </summary>
    Private Const cCheckboxPanelMaxHeight As Integer = 130

    Private Sub WireFlpPanel(ByVal flp As FlowLayoutPanel, ByVal tlp As TableLayoutPanel)
        ' Cap checkbox panel height so it never pushes the chart area off-screen
        flp.MaximumSize = New System.Drawing.Size(flp.Width, cCheckboxPanelMaxHeight)
        flp.AutoScroll = True
        AddHandler flp.SizeChanged, Sub(s As Object, ev As EventArgs)
            tlp.Top = flp.Bottom + 4
            If tlp.Parent IsNot Nothing Then
                tlp.Height = tlp.Parent.ClientSize.Height - tlp.Top - 4
            End If
        End Sub
    End Sub

	Private Sub btnRunDaily_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnRunDaily.Click
		Me.Cursor = Cursors.WaitCursor
		RunDaily()
		Me.Cursor = Cursors.Default
	End Sub
	Private Sub btnRunWeekly_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnRunWeekly.Click
		Me.Cursor = Cursors.WaitCursor
		RunWeekly()
		Me.Cursor = Cursors.Default
	End Sub
	Private Sub btnRunMonthly_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnRunMonthly.Click
		Me.Cursor = Cursors.WaitCursor
		RunMonthly()
		Me.Cursor = Cursors.Default
	End Sub
    Private Sub chkCustomGrouped_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles chkCustomGrouped.CheckedChanged
        nudCustomFrequency.Enabled = chkCustomGrouped.Checked
        cboCustomTimePeriods.Enabled = chkCustomGrouped.Checked
    End Sub
	Private Sub btnRunCustom_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnRunCustom.Click
		Me.Cursor = Cursors.WaitCursor
		RunCustom()
		Me.Cursor = Cursors.Default
	End Sub
    Private Sub btnRefresh_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnRefresh.Click
		Me.Cursor = Cursors.WaitCursor
        RefreshOverview()
        Me.Cursor = Cursors.Default
	End Sub
	Private Sub btnViewData_Daily_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnViewData_Daily.Click
		Dim StatusData As DataTable = Nothing
		Dim CounterData As DataTable = Nothing
		Dim MonitorName As String = Nothing
		Dim MonitorType As String = Nothing

		MonitorName = lblMonitor.Text
		MonitorType = lblMonitorType.Text
		If mStatusData_Daily IsNot Nothing Then StatusData = mStatusData_Daily.Copy()
		If mCounterData_Daily IsNot Nothing Then CounterData = mCounterData_Daily.Copy()

		Dim DailyData As New frmReportData(mMonitorID, MonitorName, MonitorType, StatusData, CounterData)
		DailyData.MdiParent = Me.ParentForm
		DailyData.Show()
	End Sub
	Private Sub btnViewData_Weekly_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnViewData_Weekly.Click
		Dim StatusData As DataTable = Nothing
		Dim CounterData As DataTable = Nothing
		Dim MonitorName As String = Nothing
		Dim MonitorType As String = Nothing

		MonitorName = lblMonitor.Text
		MonitorType = lblMonitorType.Text

		If mStatusData_Weekly IsNot Nothing Then StatusData = mStatusData_Weekly.Copy()
		If mCounterData_Weekly IsNot Nothing Then CounterData = mCounterData_Weekly.Copy()

		Dim DailyData As New frmReportData(mMonitorID, MonitorName, MonitorType, StatusData, CounterData)
		DailyData.MdiParent = Me.ParentForm
		DailyData.Show()
	End Sub
	Private Sub btnViewData_Monthly_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnViewData_Monthly.Click
		Dim StatusData As DataTable = Nothing
		Dim CounterData As DataTable = Nothing
		Dim MonitorName As String = Nothing
		Dim MonitorType As String = Nothing

		MonitorName = lblMonitor.Text
		MonitorType = lblMonitorType.Text

		If mStatusData_Monthly IsNot Nothing Then StatusData = mStatusData_Monthly.Copy()
		If mCounterData_Monthly IsNot Nothing Then CounterData = mCounterData_Monthly.Copy()

		Dim DailyData As New frmReportData(mMonitorID, MonitorName, MonitorType, StatusData, CounterData)
		DailyData.MdiParent = Me.ParentForm
		DailyData.Show()
	End Sub
	Private Sub btnViewData_Custom_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnViewData_Custom.Click
		Dim StatusData As DataTable = Nothing
		Dim CounterData As DataTable = Nothing
		Dim MonitorName As String = Nothing
		Dim MonitorType As String = Nothing

		MonitorName = lblMonitor.Text
		MonitorType = lblMonitorType.Text

		If mStatusData_Custom IsNot Nothing Then StatusData = mStatusData_Custom.Copy()
		If mCounterData_Custom IsNot Nothing Then CounterData = mCounterData_Custom.Copy()

		Dim DailyData As New frmReportData(mMonitorID, MonitorName, MonitorType, StatusData, CounterData)
		DailyData.MdiParent = Me.ParentForm
		DailyData.Show()
	End Sub
#End Region

#Region "Private Methods/Classes"
	Private Sub LoadCurrentStatus(ByVal MonitorID As Integer)
		Dim SQLConn As New SqlConnection(mSQLConn)

		Dim prmMonitorID As New SqlParameter
		With prmMonitorID
			.ParameterName = "@MonitorID"
			.SqlDbType = SqlDbType.Int
			.Direction = ParameterDirection.Input
			.Value = MonitorID
		End With

		Dim SQLCmd As New SqlCommand
		With SQLCmd
			.Connection = SQLConn
			.CommandType = CommandType.StoredProcedure
			.CommandTimeout = 180 '3 minutes
			.CommandText = "rpt_CurrentStatus"
			.Parameters.Add(prmMonitorID)
		End With

		Dim drResults As SqlDataReader

		Try
			SQLConn.Open()
			drResults = SQLCmd.ExecuteReader(CommandBehavior.CloseConnection)
			While drResults.Read()
				SetCurrentStatus(CInt(drResults.Item("LastStatusID")))
				Me.lblStatusDate.Text = "(" & Format(CDate(drResults.Item("LastEventDT_Display")), cFormatDateHMSm) & ")"
				DrawUptimeGauge(CDbl(drResults.Item("LifetimePercUptime")))
			End While
		Catch ex As Exception
			MsgBox("Error running Current Status report." & vbCrLf & ex.ToString, MsgBoxStyle.Exclamation Or MsgBoxStyle.OkOnly, "PolyMon Error")
		Finally
			If SQLConn.State <> ConnectionState.Closed Then SQLConn.Close()
			SQLConn.Dispose()
		End Try
	End Sub
	Private Sub SetCurrentStatus(ByVal StatusID As Integer)
		Select Case StatusID
			Case 1 'OK
				With lblOK
					.ForeColor = Color.Black
					.BackColor = Color.SkyBlue
				End With
				With lblWarning
					.ForeColor = Color.Gray
					.BackColor = Color.WhiteSmoke
				End With
				With lblFailure
					.ForeColor = Color.Gray
					.BackColor = Color.WhiteSmoke
				End With
			Case 2 ' Warning
				With lblOK
					.ForeColor = Color.Gray
					.BackColor = Color.WhiteSmoke
				End With
				With lblWarning
					.ForeColor = Color.White
					.BackColor = Color.Orange
				End With
				With lblFailure
					.ForeColor = Color.Gray
					.BackColor = Color.WhiteSmoke
				End With
			Case 3 ' Failure
				With lblOK
					.ForeColor = Color.Gray
					.BackColor = Color.WhiteSmoke
				End With
				With lblWarning
					.ForeColor = Color.Gray
					.BackColor = Color.WhiteSmoke
				End With
				With lblFailure
					.ForeColor = Color.White
					.BackColor = Color.Red
				End With
			Case Else
				With lblOK
					.ForeColor = Color.Gray
					.BackColor = Color.WhiteSmoke
				End With
				With lblWarning
					.ForeColor = Color.Gray
					.BackColor = Color.WhiteSmoke
				End With
				With lblFailure
					.ForeColor = Color.Gray
					.BackColor = Color.WhiteSmoke
				End With
		End Select
	End Sub
	Private Sub DrawUptimeGauge(ByVal uptimePercent As Double)
		Dim tileColor As Color
		If uptimePercent >= 99.0 Then
			tileColor = Color.SeaGreen
		ElseIf uptimePercent >= 95.0 Then
			tileColor = Color.DodgerBlue
		ElseIf uptimePercent >= 90.0 Then
			tileColor = Color.DarkOrange
		Else
			tileColor = Color.Crimson
		End If
		lblLifetimePercUptime.BackColor = tileColor
		lblLifetimePercUptime.ForeColor = Color.White
		lblLifetimePercUptime.Text = uptimePercent.ToString("F2") & "%" & Environment.NewLine & "Lifetime Uptime"
	End Sub
	Private Sub InitForm(ByVal MonitorID As Integer)
		SetCurrentStatus(-1)
		Me.lblStatusDate.Text = Nothing
		Me.lblLifetimePercUptime.Text = Nothing
		Me.lblLifetimePercUptime.BackColor = Color.LightGray

		Dim MonitorMetadata As New PolyMon.Monitors.MonitorMetadata(MonitorID)
		lblMonitor.Text = MonitorMetadata.MonitorName
		lblMonitorType.Text = MonitorMetadata.MonitorType

		'Date/Time Pickers
		With Me.dtpDailyStartDT
			.CustomFormat = cFormatDate
			.Format = DateTimePickerFormat.Custom
		End With
		With Me.dtpDailyEndDT
			.CustomFormat = cFormatDate
			.Format = DateTimePickerFormat.Custom
		End With
		With Me.dtpMonthlyStartDT
			.CustomFormat = cFormatDate
			.Format = DateTimePickerFormat.Custom
		End With
		With Me.dtpMonthlyEndDT
			.CustomFormat = cFormatDate
			.Format = DateTimePickerFormat.Custom
		End With
		With Me.dtpWeeklyStartDT
			.CustomFormat = cFormatDate
			.Format = DateTimePickerFormat.Custom
		End With
		With Me.dtpWeeklyEndDT
			.CustomFormat = cFormatDate
			.Format = DateTimePickerFormat.Custom
		End With
		With Me.dtpCustomStartDT
			.CustomFormat = cFormatDate
			.Format = DateTimePickerFormat.Custom
		End With
		With Me.dtpCustomEndDT
			.CustomFormat = cFormatDate
			.Format = DateTimePickerFormat.Custom
		End With

		'Daily
		Me.lblDailyStartDT.Text = Format(mMonitorStatusDateRanges.DailyStartDT, cFormatDate)
		Me.lblDailyEndDT.Text = Format(mMonitorStatusDateRanges.DailyEndDT, cFormatDate)

		Me.dtpDailyStartDT.MinDate = mMonitorStatusDateRanges.DailyStartDT
		Me.dtpDailyStartDT.MaxDate = mMonitorStatusDateRanges.DailyEndDT
		Me.dtpDailyEndDT.MinDate = mMonitorStatusDateRanges.DailyStartDT
		Me.dtpDailyEndDT.MaxDate = mMonitorStatusDateRanges.DailyEndDT

		Me.dtpDailyStartDT.Value = mMonitorStatusDateRanges.DailyStartDT
		Me.dtpDailyEndDT.Value = mMonitorStatusDateRanges.DailyEndDT

		'Weekly
		Me.dtpWeeklyStartDT.MinDate = mMonitorStatusDateRanges.WeeklyStartDT
		Me.dtpWeeklyStartDT.MaxDate = mMonitorStatusDateRanges.WeeklyEndDT
		Me.dtpWeeklyEndDT.MinDate = mMonitorStatusDateRanges.WeeklyStartDT
		Me.dtpWeeklyEndDT.MaxDate = mMonitorStatusDateRanges.WeeklyEndDT

		Me.dtpWeeklyStartDT.Value = mMonitorStatusDateRanges.WeeklyStartDT
		Me.dtpWeeklyEndDT.Value = mMonitorStatusDateRanges.WeeklyEndDT

		Me.lblWeeklyStartDT.Text = Format(mMonitorStatusDateRanges.WeeklyStartDT, cFormatDate)
		Me.lblWeeklyEndDT.Text = Format(mMonitorStatusDateRanges.WeeklyEndDT, cFormatDate)

		'Monthly
		Me.dtpMonthlyStartDT.MinDate = mMonitorStatusDateRanges.MonthlyStartDT
		Me.dtpMonthlyStartDT.MaxDate = mMonitorStatusDateRanges.MonthlyEndDT
		Me.dtpMonthlyEndDT.MinDate = mMonitorStatusDateRanges.MonthlyStartDT
		Me.dtpMonthlyEndDT.MaxDate = mMonitorStatusDateRanges.MonthlyEndDT

		Me.dtpMonthlyStartDT.Value = mMonitorStatusDateRanges.MonthlyStartDT
		Me.dtpMonthlyEndDT.Value = mMonitorStatusDateRanges.MonthlyEndDT

		Me.lblMonthlyStartDT.Text = Format(mMonitorStatusDateRanges.MonthlyStartDT, cFormatDate)
		Me.lblMonthlyEndDT.Text = Format(mMonitorStatusDateRanges.MonthlyEndDT, cFormatDate)

		'Custom
		Me.dtpCustomStartDT.MinDate = mMonitorStatusDateRanges.RawStartDT
		Me.dtpCustomStartDT.MaxDate = mMonitorStatusDateRanges.RawEndDT
		Me.dtpCustomEndDT.MinDate = mMonitorStatusDateRanges.RawStartDT
		Me.dtpCustomEndDT.MaxDate = mMonitorStatusDateRanges.RawEndDT

		Me.dtpCustomEndDT.Value = mMonitorStatusDateRanges.RawEndDT

		If DateDiff(DateInterval.Day, mMonitorStatusDateRanges.RawStartDT, mMonitorStatusDateRanges.RawEndDT) > 31 Then
			Me.dtpCustomStartDT.Value = DateAdd(DateInterval.Month, -1, mMonitorStatusDateRanges.RawEndDT)
		Else
			Me.dtpCustomStartDT.Value = mMonitorStatusDateRanges.RawStartDT
		End If

		Me.lblCustomStartDT.Text = Format(mMonitorStatusDateRanges.RawStartDT, cFormatDate)
		Me.lblCustomEndDT.Text = Format(mMonitorStatusDateRanges.RawEndDT, cFormatDate)

		'Time Periods
		With Me.cboCustomTimePeriods
			.Items.Clear()

			.Items.Add("Minute")
			.Items.Add("Hour")
			.Items.Add("Day")

			.SelectedIndex = 1
		End With

		Me.chkCustomGrouped.Checked = False
		Me.nudCustomFrequency.Enabled = False
		Me.cboCustomTimePeriods.Enabled = False
	End Sub

	Private Sub RefreshOverview()
		InitForm(mMonitorID)
		LoadCurrentStatus(mMonitorID)

		Dim CurrDate As Date = Now()

		Dim ChartList As Dictionary(Of Integer, ScottPlot.FormsPlot)

		With ChartsOverview
			.ColumnCount = 2
			.Controls.Clear()
			.RowCount = 1
			.RowStyles.Clear()
		End With
		flpChartsOverview.Controls.Clear()
		If mChartRegistry.ContainsKey(ChartsOverview) Then mChartRegistry.Remove(ChartsOverview)

		'Daily Status Charts
		ChartList = GenChartsStatusDaily(mMonitorID, DateAdd(DateInterval.Day, -14, CurrDate), CurrDate)
		AddChartsToPanel(ChartList, ChartsOverview, 1, flpChartsOverview)

		'Weekly Status Charts
		ChartList = GenChartsStatusWeekly(mMonitorID, DateAdd(DateInterval.WeekOfYear, -12, CurrDate), CurrDate)
		AddChartsToPanel(ChartList, ChartsOverview, 1, flpChartsOverview)

		'Monthly Status Charts
		ChartList = GenChartsStatusMonthly(mMonitorID, DateAdd(DateInterval.Month, -24, CurrDate), CurrDate)
		AddChartsToPanel(ChartList, ChartsOverview, 1, flpChartsOverview)

		'Raw Counter Charts
		ChartList = GenChartsCountersRaw(mMonitorID, DateAdd(DateInterval.Hour, -24, CurrDate), CurrDate)
		AddChartsToPanel(ChartList, ChartsOverview, 1, flpChartsOverview)

		'Daily Counter Charts
		ChartList = GenChartsCountersDaily(mMonitorID, DateAdd(DateInterval.Day, -14, CurrDate), CurrDate)
		AddChartsToPanel(ChartList, ChartsOverview, 1, flpChartsOverview)

		'Weekly Counter Charts
		ChartList = GenChartsCountersWeekly(mMonitorID, DateAdd(DateInterval.WeekOfYear, -12, CurrDate), CurrDate)
		AddChartsToPanel(ChartList, ChartsOverview, 1, flpChartsOverview)

		'Monthly Counter Charts
		ChartList = GenChartsCountersMonthly(mMonitorID, DateAdd(DateInterval.Month, -24, CurrDate), CurrDate)
		AddChartsToPanel(ChartList, ChartsOverview, 1, flpChartsOverview)
	End Sub

	Private Sub RunDaily()
		With ChartsDaily
			.ColumnCount = 2
			.Controls.Clear()
			.RowCount = 1
			.RowStyles.Clear()
		End With
		flpChartsDaily.Controls.Clear()
		If mChartRegistry.ContainsKey(ChartsDaily) Then mChartRegistry.Remove(ChartsDaily)

		Me.btnViewData_Daily.Enabled = True
		mStatusData_Daily = Nothing
		mCounterData_Daily = Nothing

		Dim StartDT As Date = dtpDailyStartDT.Value
		Dim EndDT As Date = dtpDailyEndDT.Value

		'Strip out any times...
		StartDT = CDate(Format(StartDT, "MMM dd, yyyy") & " 00:00:00")
		EndDT = CDate(Format(EndDT, "MMM dd, yyyy") & " 23:59:59")

		Dim ChartList As Dictionary(Of Integer, ScottPlot.FormsPlot)

		'Daily Status Charts
		ChartList = GenChartsStatusDaily(mMonitorID, StartDT, EndDT)
		AddChartsToPanel(ChartList, ChartsDaily, 1, flpChartsDaily)

		'Daily Counter Charts
		ChartList = GenChartsCountersDaily(mMonitorID, StartDT, EndDT)
		AddChartsToPanel(ChartList, ChartsDaily, 1, flpChartsDaily)
	End Sub

	Private Sub RunWeekly()
		With ChartsWeekly
			.ColumnCount = 2
			.Controls.Clear()
			.RowCount = 1
			.RowStyles.Clear()
		End With
		flpChartsWeekly.Controls.Clear()
		If mChartRegistry.ContainsKey(ChartsWeekly) Then mChartRegistry.Remove(ChartsWeekly)
		btnViewData_Weekly.Enabled = True

		Dim StartDT As Date = dtpWeeklyStartDT.Value
		Dim EndDT As Date = dtpWeeklyEndDT.Value

		'Strip out any times...
		StartDT = CDate(Format(StartDT, "MMM dd, yyyy") & " 00:00:00")
		EndDT = CDate(Format(EndDT, "MMM dd, yyyy") & " 23:59:59")

		Dim ChartList As Dictionary(Of Integer, ScottPlot.FormsPlot)

		'Weekly Status Charts
		ChartList = GenChartsStatusWeekly(mMonitorID, StartDT, EndDT)
		AddChartsToPanel(ChartList, ChartsWeekly, 1, flpChartsWeekly)

		'Weekly Counter Charts
		ChartList = GenChartsCountersWeekly(mMonitorID, StartDT, EndDT)
		AddChartsToPanel(ChartList, ChartsWeekly, 1, flpChartsWeekly)
	End Sub

	Private Sub RunMonthly()
		With ChartsMonthly
			.ColumnCount = 2
			.Controls.Clear()
			.RowCount = 1
			.RowStyles.Clear()
		End With
		flpChartsMonthly.Controls.Clear()
		If mChartRegistry.ContainsKey(ChartsMonthly) Then mChartRegistry.Remove(ChartsMonthly)
		btnViewData_Monthly.Enabled = True

		Dim StartDT As Date = dtpMonthlyStartDT.Value
		Dim EndDT As Date = dtpMonthlyEndDT.Value

		'Strip out any times...
		StartDT = CDate(Format(StartDT, "MMM dd, yyyy") & " 00:00:00")
		EndDT = CDate(Format(EndDT, "MMM dd, yyyy") & " 23:59:59")

		Dim ChartList As Dictionary(Of Integer, ScottPlot.FormsPlot)

		'Monthly Status Charts
		ChartList = GenChartsStatusMonthly(mMonitorID, StartDT, EndDT)
		AddChartsToPanel(ChartList, ChartsMonthly, 1, flpChartsMonthly)

		'Monthly Counter Charts
		ChartList = GenChartsCountersMonthly(mMonitorID, StartDT, EndDT)
		AddChartsToPanel(ChartList, ChartsMonthly, 1, flpChartsMonthly)
	End Sub

	Private Sub RunCustom()
		Dim StartDT As Date = dtpCustomStartDT.Value
		Dim EndDT As Date = dtpCustomEndDT.Value
		Dim IsGrouped As Boolean = Me.chkCustomGrouped.Checked
		Dim Frequency As Integer
		Dim FrequencyMinutes As Integer
		Dim ChartList As Dictionary(Of Integer, ScottPlot.FormsPlot)

		With ChartsCustom
			.ColumnCount = 2
			.Controls.Clear()
			.RowCount = 1
			.RowStyles.Clear()
		End With
		flpChartsCustom.Controls.Clear()
		If mChartRegistry.ContainsKey(ChartsCustom) Then mChartRegistry.Remove(ChartsCustom)
		btnViewData_Custom.Enabled = True

		'Strip out any times...
		StartDT = CDate(Format(StartDT, "MMM dd, yyyy") & " 00:00:00")
		EndDT = CDate(Format(EndDT, "MMM dd, yyyy") & " 23:59:59")

		If IsGrouped Then
			Frequency = CInt(Me.nudCustomFrequency.Value)
			Select Case Me.cboCustomTimePeriods.Text
				Case "Minute"
					FrequencyMinutes = Frequency
				Case "Hour"
					FrequencyMinutes = Frequency * 60
				Case "Day"
					FrequencyMinutes = Frequency * 60 * 24
			End Select

			'Generate Status Frequency Charts
			ChartList = GenChartsStatusCustom(mMonitorID, StartDT, EndDT, FrequencyMinutes)
			AddChartsToPanel(ChartList, ChartsCustom, 2, flpChartsCustom)

			'Generate Grouped (Averaged) Counter Charts
			ChartList = GenChartsCountersCustom(mMonitorID, StartDT, EndDT, FrequencyMinutes)
			AddChartsToPanel(ChartList, ChartsCustom, 2, flpChartsCustom)
		Else
			'Status Charts
			ChartList = GenChartsStatusRaw(mMonitorID, StartDT, EndDT)
			AddChartsToPanel(ChartList, ChartsCustom, 2, flpChartsCustom)

			'Generate Counter Charts
			ChartList = GenChartsCountersRaw(mMonitorID, StartDT, EndDT)
			AddChartsToPanel(ChartList, ChartsCustom, 2, flpChartsCustom)
		End If
	End Sub

	Private Sub AddChartsToPanel(ByRef Charts As Dictionary(Of Integer, ScottPlot.FormsPlot), ByRef Panel As TableLayoutPanel, ByVal ColSpan As Integer, Optional ByVal CheckboxPanel As FlowLayoutPanel = Nothing)
		' Ensure registry entry exists for this panel
		If Not mChartRegistry.ContainsKey(Panel) Then
			mChartRegistry(Panel) = New Dictionary(Of String, ScottPlot.FormsPlot)
		End If

		Dim localPanel As TableLayoutPanel = Panel

		For Each ChartNum As Integer In Charts.Keys
			Dim Chart As ScottPlot.FormsPlot = Charts.Item(ChartNum)
			Dim chartTitle As String = CStr(Chart.Tag)

			' Register chart (overwrites if same title — handles re-run)
			mChartRegistry(Panel)(chartTitle) = Chart

			' Create checkbox if a checkbox panel was provided
			If CheckboxPanel IsNot Nothing Then
				Dim cb As New CheckBox()
				cb.Text = chartTitle
				cb.Checked = GetDefaultChecked(chartTitle)
				cb.AutoSize = True
				AddHandler cb.CheckedChanged, Sub(s As Object, e As EventArgs)
					RelayoutCharts(localPanel)
				End Sub
				CheckboxPanel.Controls.Add(cb)
			End If
		Next

		' Apply layout now (respects current checkbox state, including defaults)
		RelayoutCharts(Panel)
	End Sub

	Private Function GetDefaultChecked(ByVal chartTitle As String) As Boolean
		If chartTitle.StartsWith("Status Frequency") Then
			If mSysSettings IsNot Nothing Then
				Return mSysSettings.GraphDefaultStatusFreq
			End If
			Return True
		ElseIf chartTitle.StartsWith("% Uptime") Then
			If mSysSettings IsNot Nothing Then
				Return mSysSettings.GraphDefaultUptime
			End If
			Return True
		Else
			Return True  ' Counter charts and Status (raw) always on
		End If
	End Function

	Private Sub RelayoutCharts(ByVal panel As TableLayoutPanel)
		If Not mChartRegistry.ContainsKey(panel) Then Exit Sub
		Dim allCharts As Dictionary(Of String, ScottPlot.FormsPlot) = mChartRegistry(panel)

		' Find sibling FlowLayoutPanel (checkbox panel)
		Dim checkboxPanel As FlowLayoutPanel = Nothing
		If panel.Parent IsNot Nothing Then
			For Each ctrl As Control In panel.Parent.Controls
				If TypeOf ctrl Is FlowLayoutPanel Then
					checkboxPanel = DirectCast(ctrl, FlowLayoutPanel)
					Exit For
				End If
			Next
		End If

		' Build ordered list of visible chart titles from checkbox state
		Dim visibleTitles As New List(Of String)
		If checkboxPanel IsNot Nothing Then
			For Each ctrl As Control In checkboxPanel.Controls
				If TypeOf ctrl Is CheckBox Then
					Dim cb As CheckBox = DirectCast(ctrl, CheckBox)
					If cb.Checked Then visibleTitles.Add(cb.Text)
				End If
			Next
		Else
			For Each kvp As KeyValuePair(Of String, ScottPlot.FormsPlot) In allCharts
				visibleTitles.Add(kvp.Key)
			Next
		End If

		' Rebuild: single column, fixed-height rows, vertically scrollable
		panel.SuspendLayout()
		panel.Controls.Clear()
		panel.ColumnCount = 1
		panel.ColumnStyles.Clear()
		panel.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100.0F))
		panel.RowCount = 0
		panel.RowStyles.Clear()
		panel.AutoScroll = True

		For Each title As String In visibleTitles
			If Not allCharts.ContainsKey(title) Then Continue For
			Dim chart As ScottPlot.FormsPlot = allCharts(title)
			panel.RowCount += 1
			panel.RowStyles.Add(New RowStyle(SizeType.Absolute, cChartHeight))
			chart.Dock = DockStyle.Fill
			chart.MinimumSize = New System.Drawing.Size(0, 0)
			chart.MaximumSize = New System.Drawing.Size(0, 0)
			panel.Controls.Add(chart, 0, panel.RowCount - 1)
		Next

		panel.ResumeLayout()
	End Sub

	Private Class MonitorStatusDateRanges
		Private mRawStartDT As Date
		Private mRawEndDT As Date
		Private mDailyStartDT As Date
		Private mDailyEndDT As Date
		Private mWeeklyStartDT As Date
		Private mWeeklyEndDT As Date
		Private mMonthlyStartDT As Date
		Private mMonthlyEndDT As Date

		Public Sub New(ByVal MonitorID As Integer, ByVal SQLConnStr As String)
			Dim SQLConn As New SqlConnection(SQLConnStr)

			Dim prmMonitorID As New SqlParameter
			With prmMonitorID
				.ParameterName = "@MonitorID"
				.SqlDbType = SqlDbType.Int
				.Direction = ParameterDirection.Input
				.Value = MonitorID
			End With

			Dim SQLCmd As New SqlCommand
			With SQLCmd
				.Connection = SQLConn
				.CommandType = CommandType.StoredProcedure
				.CommandTimeout = 30 '30 seconds
				.CommandText = "rpt_GetStatusDateRanges"
				.Parameters.Add(prmMonitorID)
			End With

			Dim drResults As SqlDataReader

			Try
				SQLConn.Open()
				drResults = SQLCmd.ExecuteReader(CommandBehavior.CloseConnection)
				While drResults.Read()
					With drResults
						mRawStartDT = ExtractDate(.Item("RawStartDT"))
						mRawEndDT = ExtractDate(.Item("RawEndDT"))
						mDailyStartDT = ExtractDate(.Item("DailyStartDT"))
						mDailyEndDT = ExtractDate(.Item("DailyEndDT"))
						mWeeklyStartDT = ExtractDate(.Item("WeeklyStartDT"))
						mWeeklyEndDT = ExtractDate(.Item("WeeklyEndDT"))
						mMonthlyStartDT = ExtractDate(.Item("MonthlyStartDT"))
						mMonthlyEndDT = ExtractDate(.Item("MonthlyEndDT"))
					End With
				End While
			Catch ex As Exception
				MsgBox("Error running rpt_GetStatusDateRanges." & vbCrLf & ex.ToString, MsgBoxStyle.Exclamation Or MsgBoxStyle.OkOnly, "PolyMon Error")
			Finally
				If SQLConn.State <> ConnectionState.Closed Then SQLConn.Close()
				SQLConn.Dispose()
			End Try
		End Sub

		Public ReadOnly Property RawStartDT() As Date
			Get
				Return mRawStartDT
			End Get
		End Property
		Public ReadOnly Property RawEndDT() As Date
			Get
				Return mRawEndDT
			End Get
		End Property
		Public ReadOnly Property DailyStartDT() As Date
			Get
				Return mDailyStartDT
			End Get
		End Property
		Public ReadOnly Property DailyEndDT() As Date
			Get
				Return mDailyEndDT
			End Get
		End Property
		Public ReadOnly Property WeeklyStartDT() As Date
			Get
				Return mWeeklyStartDT
			End Get
		End Property
		Public ReadOnly Property WeeklyEndDT() As Date
			Get
				Return mWeeklyEndDT
			End Get
		End Property
		Public ReadOnly Property MonthlyStartDT() As Date
			Get
				Return mMonthlyStartDT
			End Get
		End Property
		Public ReadOnly Property MonthlyEndDT() As Date
			Get
				Return mMonthlyEndDT
			End Get
		End Property

		Private Function ExtractDate(ByRef Obj As Object) As Date
			Try
				If Obj Is Nothing OrElse IsDBNull(Obj) Then
					Return Now()
				Else
					Return CDate(Obj)
				End If
			Catch ex As Exception
				Return Now()
			End Try
		End Function
	End Class
#End Region

#Region "Chart/Report Generators"

	''' <summary>
	''' Creates and configures a new ScottPlot.FormsPlot with standard chart styling.
	''' </summary>
	Private Function CreateChart(ByVal title As String, ByVal xFormat As String, ByVal isDateTimeX As Boolean) As ScottPlot.FormsPlot
		Dim chart As New ScottPlot.FormsPlot()
		Dim plt As ScottPlot.Plot = chart.Plot
		plt.Style(figureBackground:=Color.White, dataBackground:=Color.WhiteSmoke)
		plt.Title(title)
		If isDateTimeX Then
			plt.XAxis.DateTimeFormat(True)
			plt.XAxis.TickLabelFormat(xFormat, dateTimeFormat:=True)
		End If
		plt.XAxis.TickLabelStyle(fontSize:=9)
		plt.YAxis.TickLabelStyle(fontSize:=9)
		chart.Tag = title

		' Hover tooltip setup — declared here so MouseLeave can reference it
		Dim tooltipDateFmt As String
		Select Case xFormat
			Case "HH:mm" : tooltipDateFmt = "MMM d, yyyy HH:mm"
			Case "MMM yyyy" : tooltipDateFmt = "MMM yyyy"
			Case Else : tooltipDateFmt = "MMM d, yyyy"
		End Select
		Dim tt As New ToolTip()
		tt.UseAnimation = False
		tt.ShowAlways = True
		Dim lastTip As String = ""
		Dim lastBestIdx As Integer = -1
		Dim pendingTip As String = ""
		Dim pendingMousePos As Point = Point.Empty

		' Timer fires after mouse pauses — only then show/update tooltip
		Dim tipTimer As New System.Windows.Forms.Timer()
		tipTimer.Interval = 600
		AddHandler tipTimer.Tick, Sub(s As Object, ev As EventArgs)
			tipTimer.Stop()
			If pendingTip <> "" AndAlso pendingTip <> lastTip Then
				tt.Show(pendingTip, chart, pendingMousePos.X + 12, pendingMousePos.Y - 8, 30000)
				lastTip = pendingTip
			End If
		End Sub

		chart.Configuration.ScrollWheelZoom = True
		chart.Configuration.DoubleClickBenchmark = False
		AddHandler chart.MouseEnter, Sub(s As Object, ev As EventArgs)
			DirectCast(s, ScottPlot.FormsPlot).Focus()
		End Sub
		AddHandler chart.MouseLeave, Sub(s As Object, ev As EventArgs)
			tipTimer.Stop()
			tt.Hide(DirectCast(s, ScottPlot.FormsPlot))
			lastTip = ""
			lastBestIdx = -1
			pendingTip = ""
		End Sub

		RemoveHandler chart.RightClicked, AddressOf chart.DefaultRightClickEvent
		Dim cms As New ContextMenuStrip()
		Dim openItem As New ToolStripMenuItem("Open in new window")
		AddHandler openItem.Click, Sub(s As Object, e As EventArgs)
			Dim viewer As New ScottPlot.FormsPlotViewer(chart.Plot, 900, 500, CStr(chart.Tag))
			viewer.Show()
		End Sub
		Dim resetItem As New ToolStripMenuItem("Reset zoom")
		AddHandler resetItem.Click, Sub(s As Object, e As EventArgs)
			chart.Plot.AxisAuto()
			chart.Refresh()
		End Sub
		cms.Items.Add(openItem)
		cms.Items.Add(resetItem)
		chart.ContextMenuStrip = cms
		AddHandler chart.MouseMove, Sub(s As Object, ev As MouseEventArgs)
			Dim fp As ScottPlot.FormsPlot = DirectCast(s, ScottPlot.FormsPlot)
			Try
				Dim mouseX As Double = fp.GetMouseCoordinates().Item1
				Dim bestIdx As Integer = -1
				Dim bestX As Double = Double.NaN
				Dim bestDist As Double = Double.MaxValue
				For Each p As ScottPlot.Plottable.IPlottable In fp.Plot.GetPlottables()
					If TypeOf p Is ScottPlot.Plottable.ScatterPlot Then
						Dim sc As ScottPlot.Plottable.ScatterPlot = DirectCast(p, ScottPlot.Plottable.ScatterPlot)
						If sc.Xs IsNot Nothing Then
							For i As Integer = 0 To sc.Xs.Length - 1
								Dim d As Double = Math.Abs(sc.Xs(i) - mouseX)
								If d < bestDist Then
									bestDist = d : bestIdx = i : bestX = sc.Xs(i)
								End If
							Next
						End If
					End If
				Next
				If bestIdx < 0 Then
					tipTimer.Stop()
					If lastTip <> "" Then tt.Hide(fp) : lastTip = "" : lastBestIdx = -1
					Exit Sub
				End If
				' Only restart the timer when the snapped index actually changes
				If bestIdx = lastBestIdx Then Exit Sub
				tipTimer.Stop()
				Dim sb As New System.Text.StringBuilder()
				If isDateTimeX Then
					sb.AppendLine(DateTime.FromOADate(bestX).ToString(tooltipDateFmt))
				Else
					sb.AppendLine(bestX.ToString("G"))
				End If
				For Each p As ScottPlot.Plottable.IPlottable In fp.Plot.GetPlottables()
					If TypeOf p Is ScottPlot.Plottable.ScatterPlot Then
						Dim sc As ScottPlot.Plottable.ScatterPlot = DirectCast(p, ScottPlot.Plottable.ScatterPlot)
						If sc.Xs IsNot Nothing AndAlso bestIdx < sc.Ys.Length Then
							Dim yVal As Double = sc.Ys(bestIdx)
							Dim seriesLabel As String = If(sc.Label <> "", sc.Label, "Value")
							Dim yStr As String
							If title.StartsWith("% Uptime") Then
								yStr = yVal.ToString("F1") & "%"
							ElseIf title.StartsWith("Status Frequency") Then
								yStr = yVal.ToString("F0")
							Else
								yStr = yVal.ToString("G")
							End If
							sb.AppendLine(seriesLabel & ": " & yStr)
						End If
					End If
				Next
				lastBestIdx = bestIdx
				pendingTip = sb.ToString().TrimEnd()
				pendingMousePos = New Point(ev.X, ev.Y)
				tipTimer.Start()
			Catch
			End Try
		End Sub

		Return chart
	End Function

	''' <summary>
	''' Sets an error/watermark annotation on a chart when data limits are exceeded.
	''' </summary>
	Private Sub SetErrorWatermark(ByVal ErrMsg As String, ByVal chart As ScottPlot.FormsPlot)
		chart.Plot.AddAnnotation(ErrMsg)
	End Sub

	Private Function GenChartsStatusRaw(ByVal MonitorID As Integer, ByVal StartDT As Date, ByVal EndDT As Date) As Dictionary(Of Integer, ScottPlot.FormsPlot)
		Dim ChartNum As Integer = 0
		GenChartsStatusRaw = New Dictionary(Of Integer, ScottPlot.FormsPlot)

		'Retrieve data
		Dim SQLConn As New SqlConnection(mSQLConn)

		Dim prmMonitorID As New SqlParameter
		With prmMonitorID
			.ParameterName = "@MonitorID"
			.SqlDbType = SqlDbType.Int
			.Direction = ParameterDirection.Input
			.Value = MonitorID
		End With

		Dim prmStartDT As New SqlParameter
		With prmStartDT
			.ParameterName = "@StartDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = StartDT
		End With

		Dim prmEndDT As New SqlParameter
		With prmEndDT
			.ParameterName = "@EndDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = EndDT
		End With

		Dim SQLCmd As New SqlCommand
		With SQLCmd
			.Connection = SQLConn
			.CommandType = CommandType.StoredProcedure
			.CommandTimeout = 180 '3 minutes
			.CommandText = "rpt_StatusData_Raw"
			.Parameters.Add(prmMonitorID)
			.Parameters.Add(prmStartDT)
			.Parameters.Add(prmEndDT)
		End With

		Dim tblResults As DataTable
		Dim dsResults As New DataSet
		Dim daSQL As New SqlDataAdapter(SQLCmd)

		Try
			SQLConn.Open()
			daSQL.Fill(dsResults)
			If dsResults.Tables.Count > 0 Then
				tblResults = dsResults.Tables(0)

				tblResults.Columns("DT_Raw").ExtendedProperties.Add("Visible", False)
				With tblResults.Columns("DT_Display")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Event Date"
				End With
				With tblResults.Columns("IsOK")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Is OK"
				End With
				With tblResults.Columns("IsWarning")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Is Warning"
				End With
				With tblResults.Columns("IsFailure")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Is Failure"
				End With
				With tblResults.Columns("UpTime")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "UpTime"
				End With
				With tblResults.Columns("DownTime")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "DownTime"
				End With
				mStatusData_Custom = tblResults

				'Do not plot anything if rows exceed mMaxDataPts
				If tblResults.Rows.Count > mMaxDataPts Then
					Dim dummy As ScottPlot.FormsPlot = CreateChart("Status", "HH:mm", True)
					SetErrorWatermark(String.Format(cMaxReachedMsg, mMaxDataPts), dummy)
					dummy.Refresh()
					GenChartsStatusRaw.Add(ChartNum, dummy)
					ChartNum += 1
					Exit Function
				End If

				' Build X and Y arrays from DataTable
				Dim xs As New List(Of Double)
				Dim ysOK As New List(Of Double)
				Dim ysWarning As New List(Of Double)
				Dim ysFailure As New List(Of Double)

				For Each row As DataRow In tblResults.Rows
					xs.Add(CDate(row("DT_Raw")).ToOADate())
					ysOK.Add(CDbl(row("IsOK")))
					ysWarning.Add(CDbl(row("IsWarning")))
					ysFailure.Add(CDbl(row("IsFailure")))
				Next

				Dim Chart As ScottPlot.FormsPlot = CreateChart("Status", "HH:mm", True)
				Dim plt As ScottPlot.Plot = Chart.Plot

				If xs.Count > 0 Then
					Dim curveOK As ScottPlot.Plottable.ScatterPlot = plt.AddScatterStep(xs.ToArray(), ysOK.ToArray(), Color.Blue)
					curveOK.Label = "OK"
					curveOK.LineWidth = 1.5
					curveOK.MarkerSize = 0
	
					Dim curveWarning As ScottPlot.Plottable.ScatterPlot =plt.AddScatterStep(xs.ToArray(), ysWarning.ToArray(), Color.Orange)
					curveWarning.Label = "Warning"
					curveWarning.LineWidth = 1.5
					curveWarning.MarkerSize = 0
	
					Dim curveFailure As ScottPlot.Plottable.ScatterPlot =plt.AddScatterStep(xs.ToArray(), ysFailure.ToArray(), Color.Red)
					curveFailure.Label = "Failure"
					curveFailure.LineWidth = 1.5
					curveFailure.MarkerSize = 0
	
					plt.Legend()
					plt.SetAxisLimitsY(-0.1, 1.1)
				End If
				Chart.Refresh()

				GenChartsStatusRaw.Add(ChartNum, Chart)
				ChartNum += 1
			End If

		Catch ex As Exception
			MsgBox("Error running report:" & vbCrLf & ex.ToString, MsgBoxStyle.Exclamation Or MsgBoxStyle.OkOnly, "PolyMon Error")
		Finally
			If SQLConn.State <> ConnectionState.Closed Then SQLConn.Close()
			daSQL.Dispose()
			SQLConn.Dispose()
		End Try
	End Function

	Private Function GenChartsStatusDaily(ByVal MonitorID As Integer, ByVal StartDT As Date, ByVal EndDT As Date) As Dictionary(Of Integer, ScottPlot.FormsPlot)
		GenChartsStatusDaily = New Dictionary(Of Integer, ScottPlot.FormsPlot)
		Dim ChartNum As Integer = 0

		'Retrieve data
		Dim SQLConn As New SqlConnection(mSQLConn)

		Dim prmMonitorID As New SqlParameter
		With prmMonitorID
			.ParameterName = "@MonitorID"
			.SqlDbType = SqlDbType.Int
			.Direction = ParameterDirection.Input
			.Value = MonitorID
		End With

		Dim prmStartDT As New SqlParameter
		With prmStartDT
			.ParameterName = "@StartDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = StartDT
		End With

		Dim prmEndDT As New SqlParameter
		With prmEndDT
			.ParameterName = "@EndDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = EndDT
		End With

		Dim SQLCmd As New SqlCommand
		With SQLCmd
			.Connection = SQLConn
			.CommandType = CommandType.StoredProcedure
			.CommandTimeout = 180 '3 minutes
			.CommandText = "rpt_StatusData_Daily"
			.Parameters.Add(prmMonitorID)
			.Parameters.Add(prmStartDT)
			.Parameters.Add(prmEndDT)
		End With

		Dim tblResults As DataTable
		Dim dsResults As New DataSet
		Dim daSQL As New SqlDataAdapter(SQLCmd)

		Try
			SQLConn.Open()
			daSQL.Fill(dsResults)
			If dsResults.Tables.Count > 0 Then
				tblResults = dsResults.Tables(0)

				tblResults.Columns("DT_Raw").ExtendedProperties.Add("Visible", False)
				With tblResults.Columns("DT_Display")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Date"
				End With
				With tblResults.Columns("OKCount")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "# OK"
				End With
				With tblResults.Columns("WarningCount")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "# Warnings"
				End With
				With tblResults.Columns("FailureCount")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "# Failures"
				End With
				With tblResults.Columns("TotalUpTime")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Total UpTime (secs)"
				End With
				With tblResults.Columns("TotalDownTime")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Total DownTime (secs)"
				End With
				With tblResults.Columns("PercUpTime")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "% UpTime"
				End With
				mStatusData_Daily = tblResults

				' Build arrays from DataTable
				Dim xs As New List(Of Double)
				Dim ysWarning As New List(Of Double)
				Dim ysFailure As New List(Of Double)
				Dim ysPercUpTime As New List(Of Double)

				For Each row As DataRow In tblResults.Rows
					xs.Add(CDate(row("DT_Raw")).ToOADate())
					ysWarning.Add(CDbl(row("WarningCount")))
					ysFailure.Add(CDbl(row("FailureCount")))
					ysPercUpTime.Add(CDbl(row("PercUptime")))
				Next

				' Status Frequency Chart
				Dim ChartStatus As ScottPlot.FormsPlot = CreateChart("Status Frequency - Daily", "MMM dd", True)
				Dim pltStatus As ScottPlot.Plot = ChartStatus.Plot

				If xs.Count > 0 Then
					Dim curveWarning As ScottPlot.Plottable.ScatterPlot =pltStatus.AddScatterStep(xs.ToArray(), ysWarning.ToArray(), Color.Orange)
					curveWarning.Label = "Warning"
					curveWarning.LineWidth = 1.5
					curveWarning.MarkerSize = 0
	
					Dim curveFailure As ScottPlot.Plottable.ScatterPlot =pltStatus.AddScatterStep(xs.ToArray(), ysFailure.ToArray(), Color.Red)
					curveFailure.Label = "Failure"
					curveFailure.LineWidth = 1.5
					curveFailure.MarkerSize = 0
	
					pltStatus.Legend()
				End If
				ChartStatus.Refresh()
				GenChartsStatusDaily.Add(ChartNum, ChartStatus)
				ChartNum += 1

				' % Uptime Chart
				Dim ChartUptime As ScottPlot.FormsPlot = CreateChart("% Uptime - Daily", "MMM dd", True)
				Dim pltUptime As ScottPlot.Plot = ChartUptime.Plot

				If xs.Count > 0 Then
					Dim curvePercUpTime As ScottPlot.Plottable.ScatterPlot =pltUptime.AddScatter(xs.ToArray(), ysPercUpTime.ToArray(), Color.Blue)
					curvePercUpTime.Label = "% Uptime"
					curvePercUpTime.LineWidth = 1.5
					If tblResults.Rows.Count > mSymbolMaxPts Then
						curvePercUpTime.MarkerSize = 0
					Else
						curvePercUpTime.MarkerSize = 7
				End If
				End If

				pltUptime.Legend()
				ChartUptime.Refresh()
				GenChartsStatusDaily.Add(ChartNum, ChartUptime)
				ChartNum += 1
			End If

		Catch ex As Exception
			MsgBox("Error running report:" & vbCrLf & ex.ToString, MsgBoxStyle.Exclamation Or MsgBoxStyle.OkOnly, "PolyMon Error")
		Finally
			If SQLConn.State <> ConnectionState.Closed Then SQLConn.Close()
			daSQL.Dispose()
			SQLConn.Dispose()
		End Try
	End Function

	Private Function GenChartsStatusWeekly(ByVal MonitorID As Integer, ByVal StartDT As Date, ByVal EndDT As Date) As Dictionary(Of Integer, ScottPlot.FormsPlot)
		GenChartsStatusWeekly = New Dictionary(Of Integer, ScottPlot.FormsPlot)
		Dim ChartNum As Integer = 0

		'Retrieve data
		Dim SQLConn As New SqlConnection(mSQLConn)

		Dim prmMonitorID As New SqlParameter
		With prmMonitorID
			.ParameterName = "@MonitorID"
			.SqlDbType = SqlDbType.Int
			.Direction = ParameterDirection.Input
			.Value = MonitorID
		End With

		Dim prmStartDT As New SqlParameter
		With prmStartDT
			.ParameterName = "@StartDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = StartDT
		End With

		Dim prmEndDT As New SqlParameter
		With prmEndDT
			.ParameterName = "@EndDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = EndDT
		End With

		Dim SQLCmd As New SqlCommand
		With SQLCmd
			.Connection = SQLConn
			.CommandType = CommandType.StoredProcedure
			.CommandTimeout = 180 '3 minutes
			.CommandText = "rpt_StatusData_Weekly"
			.Parameters.Add(prmMonitorID)
			.Parameters.Add(prmStartDT)
			.Parameters.Add(prmEndDT)
		End With

		Dim tblResults As DataTable
		Dim dsResults As New DataSet
		Dim daSQL As New SqlDataAdapter(SQLCmd)

		Try
			SQLConn.Open()
			daSQL.Fill(dsResults)
			If dsResults.Tables.Count > 0 Then
				tblResults = dsResults.Tables(0)

				tblResults.Columns("StartDT_Raw").ExtendedProperties.Add("Visible", False)
				tblResults.Columns("EndDT_Raw").ExtendedProperties.Add("Visible", False)
				With tblResults.Columns("Year")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Year"
				End With
				With tblResults.Columns("WeekOfYear")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Week"
				End With
				With tblResults.Columns("StartDT_Display")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Start Date"
				End With
				With tblResults.Columns("EndDT_Display")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "End Date"
				End With
				With tblResults.Columns("OKCount")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "# OK"
				End With
				With tblResults.Columns("WarningCount")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "# Warnings"
				End With
				With tblResults.Columns("FailureCount")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "# Failures"
				End With
				With tblResults.Columns("TotalUpTime")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Total UpTime (secs)"
				End With
				With tblResults.Columns("TotalDownTime")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Total DownTime (secs)"
				End With
				With tblResults.Columns("PercUpTime")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "% UpTime"
				End With
				mStatusData_Weekly = tblResults

				' Build arrays from DataTable
				Dim xs As New List(Of Double)
				Dim ysWarning As New List(Of Double)
				Dim ysFailure As New List(Of Double)
				Dim ysPercUpTime As New List(Of Double)

				For Each row As DataRow In tblResults.Rows
					xs.Add(CDate(row("StartDT_Raw")).ToOADate())
					ysWarning.Add(CDbl(row("WarningCount")))
					ysFailure.Add(CDbl(row("FailureCount")))
					ysPercUpTime.Add(CDbl(row("PercUptime")))
				Next

				' Status Frequency Chart
				Dim ChartStatus As ScottPlot.FormsPlot = CreateChart("Status Frequency - Weekly", "MMM dd", True)
				Dim pltStatus As ScottPlot.Plot = ChartStatus.Plot

				If xs.Count > 0 Then
					Dim curveWarning As ScottPlot.Plottable.ScatterPlot =pltStatus.AddScatterStep(xs.ToArray(), ysWarning.ToArray(), Color.Orange)
					curveWarning.Label = "Warning"
					curveWarning.LineWidth = 1.5
					curveWarning.MarkerSize = 0
	
					Dim curveFailure As ScottPlot.Plottable.ScatterPlot =pltStatus.AddScatterStep(xs.ToArray(), ysFailure.ToArray(), Color.Red)
					curveFailure.Label = "Failure"
					curveFailure.LineWidth = 1.5
					curveFailure.MarkerSize = 0
	
					pltStatus.Legend()
				End If
				ChartStatus.Refresh()
				GenChartsStatusWeekly.Add(ChartNum, ChartStatus)
				ChartNum += 1

				' % Uptime Chart
				Dim ChartUptime As ScottPlot.FormsPlot = CreateChart("% Uptime - Weekly", "MMM dd", True)
				Dim pltUptime As ScottPlot.Plot = ChartUptime.Plot

				If xs.Count > 0 Then
					Dim curvePercUpTime As ScottPlot.Plottable.ScatterPlot =pltUptime.AddScatter(xs.ToArray(), ysPercUpTime.ToArray(), Color.Blue)
					curvePercUpTime.Label = "% Uptime"
					curvePercUpTime.LineWidth = 1.5
					If tblResults.Rows.Count > mSymbolMaxPts Then
						curvePercUpTime.MarkerSize = 0
					Else
						curvePercUpTime.MarkerSize = 7
				End If
				End If

				pltUptime.Legend()
				ChartUptime.Refresh()
				GenChartsStatusWeekly.Add(ChartNum, ChartUptime)
				ChartNum += 1
			End If

		Catch ex As Exception
			MsgBox("Error running report:" & vbCrLf & ex.ToString, MsgBoxStyle.Exclamation Or MsgBoxStyle.OkOnly, "PolyMon Error")
		Finally
			If SQLConn.State <> ConnectionState.Closed Then SQLConn.Close()
			daSQL.Dispose()
			SQLConn.Dispose()
		End Try
	End Function

	Private Function GenChartsStatusMonthly(ByVal MonitorID As Integer, ByVal StartDT As Date, ByVal EndDT As Date) As Dictionary(Of Integer, ScottPlot.FormsPlot)
		GenChartsStatusMonthly = New Dictionary(Of Integer, ScottPlot.FormsPlot)
		Dim ChartNum As Integer = 0

		'Retrieve data
		Dim SQLConn As New SqlConnection(mSQLConn)

		Dim prmMonitorID As New SqlParameter
		With prmMonitorID
			.ParameterName = "@MonitorID"
			.SqlDbType = SqlDbType.Int
			.Direction = ParameterDirection.Input
			.Value = MonitorID
		End With

		Dim prmStartDT As New SqlParameter
		With prmStartDT
			.ParameterName = "@StartDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = StartDT
		End With

		Dim prmEndDT As New SqlParameter
		With prmEndDT
			.ParameterName = "@EndDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = EndDT
		End With

		Dim SQLCmd As New SqlCommand
		With SQLCmd
			.Connection = SQLConn
			.CommandType = CommandType.StoredProcedure
			.CommandTimeout = 180 '3 minutes
			.CommandText = "rpt_StatusData_Monthly"
			.Parameters.Add(prmMonitorID)
			.Parameters.Add(prmStartDT)
			.Parameters.Add(prmEndDT)
		End With

		Dim tblResults As DataTable
		Dim dsResults As New DataSet
		Dim daSQL As New SqlDataAdapter(SQLCmd)

		Try
			SQLConn.Open()
			daSQL.Fill(dsResults)
			If dsResults.Tables.Count > 0 Then
				tblResults = dsResults.Tables(0)

				tblResults.Columns("StartDT_Raw").ExtendedProperties.Add("Visible", False)
				tblResults.Columns("EndDT_Raw").ExtendedProperties.Add("Visible", False)
				With tblResults.Columns("Year")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Year"
				End With
				With tblResults.Columns("Month")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Month"
				End With
				With tblResults.Columns("StartDT_Display")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Start Date"
				End With
				With tblResults.Columns("EndDT_Display")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "End Date"
				End With
				With tblResults.Columns("OKCount")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "# OK"
				End With
				With tblResults.Columns("WarningCount")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "# Warnings"
				End With
				With tblResults.Columns("FailureCount")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "# Failures"
				End With
				With tblResults.Columns("TotalUpTime")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Total UpTime (secs)"
				End With
				With tblResults.Columns("TotalDownTime")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Total DownTime (secs)"
				End With
				With tblResults.Columns("PercUpTime")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "% UpTime"
				End With
				mStatusData_Monthly = tblResults

				' Build arrays from DataTable
				Dim xs As New List(Of Double)
				Dim ysWarning As New List(Of Double)
				Dim ysFailure As New List(Of Double)
				Dim ysPercUpTime As New List(Of Double)

				For Each row As DataRow In tblResults.Rows
					xs.Add(CDate(row("StartDT_Raw")).ToOADate())
					ysWarning.Add(CDbl(row("WarningCount")))
					ysFailure.Add(CDbl(row("FailureCount")))
					ysPercUpTime.Add(CDbl(row("PercUptime")))
				Next

				' Status Frequency Chart
				Dim ChartStatus As ScottPlot.FormsPlot = CreateChart("Status Frequency - Monthly", "MMM yyyy", True)
				Dim pltStatus As ScottPlot.Plot = ChartStatus.Plot

				If xs.Count > 0 Then
					Dim curveWarning As ScottPlot.Plottable.ScatterPlot =pltStatus.AddScatterStep(xs.ToArray(), ysWarning.ToArray(), Color.Orange)
					curveWarning.Label = "Warning"
					curveWarning.LineWidth = 1.5
					curveWarning.MarkerSize = 0
	
					Dim curveFailure As ScottPlot.Plottable.ScatterPlot =pltStatus.AddScatterStep(xs.ToArray(), ysFailure.ToArray(), Color.Red)
					curveFailure.Label = "Failure"
					curveFailure.LineWidth = 1.5
					curveFailure.MarkerSize = 0
	
					pltStatus.Legend()
				End If
				ChartStatus.Refresh()
				GenChartsStatusMonthly.Add(ChartNum, ChartStatus)
				ChartNum += 1

				' % Uptime Chart
				Dim ChartUptime As ScottPlot.FormsPlot = CreateChart("% Uptime - Monthly", "MMM yyyy", True)
				Dim pltUptime As ScottPlot.Plot = ChartUptime.Plot

				If xs.Count > 0 Then
					Dim curvePercUpTime As ScottPlot.Plottable.ScatterPlot =pltUptime.AddScatter(xs.ToArray(), ysPercUpTime.ToArray(), Color.Blue)
					curvePercUpTime.Label = "% Uptime"
					curvePercUpTime.LineWidth = 1.5
					If tblResults.Rows.Count > mSymbolMaxPts Then
						curvePercUpTime.MarkerSize = 0
					Else
						curvePercUpTime.MarkerSize = 7
				End If
				End If

				pltUptime.Legend()
				ChartUptime.Refresh()
				GenChartsStatusMonthly.Add(ChartNum, ChartUptime)
				ChartNum += 1
			End If

		Catch ex As Exception
			MsgBox("Error running report:" & vbCrLf & ex.ToString, MsgBoxStyle.Exclamation Or MsgBoxStyle.OkOnly, "PolyMon Error")
		Finally
			If SQLConn.State <> ConnectionState.Closed Then SQLConn.Close()
			daSQL.Dispose()
			SQLConn.Dispose()
		End Try
	End Function

	Private Function GenChartsStatusCustom(ByVal MonitorID As Integer, ByVal StartDT As Date, ByVal EndDT As Date, ByVal TPMinutes As Integer) As Dictionary(Of Integer, ScottPlot.FormsPlot)
		GenChartsStatusCustom = New Dictionary(Of Integer, ScottPlot.FormsPlot)
		Dim ChartNum As Integer = 0

		'Retrieve data
		Dim SQLConn As New SqlConnection(mSQLConn)

		Dim prmMonitorID As New SqlParameter
		With prmMonitorID
			.ParameterName = "@MonitorID"
			.SqlDbType = SqlDbType.Int
			.Direction = ParameterDirection.Input
			.Value = MonitorID
		End With

		Dim prmStartDT As New SqlParameter
		With prmStartDT
			.ParameterName = "@StartDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = StartDT
		End With

		Dim prmEndDT As New SqlParameter
		With prmEndDT
			.ParameterName = "@EndDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = EndDT
		End With

		Dim prmTPMinutes As New SqlParameter
		With prmTPMinutes
			.ParameterName = "@TPMinutes"
			.SqlDbType = SqlDbType.Int
			.Direction = ParameterDirection.Input
			.Value = TPMinutes
		End With

		Dim SQLCmd As New SqlCommand
		With SQLCmd
			.Connection = SQLConn
			.CommandType = CommandType.StoredProcedure
			.CommandTimeout = 180 '3 minutes
			.CommandText = "rpt_StatusData_CustomFreq"
			.Parameters.Add(prmMonitorID)
			.Parameters.Add(prmStartDT)
			.Parameters.Add(prmEndDT)
			.Parameters.Add(prmTPMinutes)
		End With

		Dim tblResults As DataTable
		Dim dsResults As New DataSet
		Dim daSQL As New SqlDataAdapter(SQLCmd)

		Try
			SQLConn.Open()
			daSQL.Fill(dsResults)
			If dsResults.Tables.Count > 0 Then
				tblResults = dsResults.Tables(0)

				tblResults.Columns("TPNum").ExtendedProperties.Add("Visible", False)
				tblResults.Columns("StartDT_Raw").ExtendedProperties.Add("Visible", False)
				tblResults.Columns("EndDT_Raw").ExtendedProperties.Add("Visible", False)
				With tblResults.Columns("StartDT_Display")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "Start Date"
				End With
				With tblResults.Columns("EndDT_Display")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "End Date"
				End With
				With tblResults.Columns("OKCount")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "# OK"
				End With
				With tblResults.Columns("WarningCount")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "# Warnings"
				End With
				With tblResults.Columns("FailureCount")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "# Failures"
				End With
				With tblResults.Columns("PercUpTime")
					.ExtendedProperties.Add("Visible", True)
					.Caption = "% UpTime"
				End With
				mStatusData_Custom = tblResults

				'Do not plot anything if rows exceed mMaxDataPts
				If tblResults.Rows.Count > mMaxDataPts Then
					Dim dummy As ScottPlot.FormsPlot = CreateChart("Status Frequency", "MMM dd", True)
					SetErrorWatermark(String.Format(cMaxReachedMsg, mMaxDataPts), dummy)
					dummy.Refresh()
					GenChartsStatusCustom.Add(ChartNum, dummy)
					ChartNum += 1
					Exit Function
				End If

				' Build arrays from DataTable
				Dim xs As New List(Of Double)
				Dim ysWarning As New List(Of Double)
				Dim ysFailure As New List(Of Double)
				Dim ysPercUpTime As New List(Of Double)

				For Each row As DataRow In tblResults.Rows
					xs.Add(CDate(row("StartDT_Raw")).ToOADate())
					ysWarning.Add(CDbl(row("WarningCount")))
					ysFailure.Add(CDbl(row("FailureCount")))
					ysPercUpTime.Add(CDbl(row("PercUptime")))
				Next

				' Status Frequency Chart
				Dim ChartStatus As ScottPlot.FormsPlot = CreateChart("Status Frequency", "MMM dd", True)
				Dim pltStatus As ScottPlot.Plot = ChartStatus.Plot

				If xs.Count > 0 Then
					Dim curveWarning As ScottPlot.Plottable.ScatterPlot =pltStatus.AddScatterStep(xs.ToArray(), ysWarning.ToArray(), Color.Orange)
					curveWarning.Label = "Warning"
					curveWarning.LineWidth = 1.5
					curveWarning.MarkerSize = 0
	
					Dim curveFailure As ScottPlot.Plottable.ScatterPlot =pltStatus.AddScatterStep(xs.ToArray(), ysFailure.ToArray(), Color.Red)
					curveFailure.Label = "Failure"
					curveFailure.LineWidth = 1.5
					curveFailure.MarkerSize = 0
	
					pltStatus.Legend()
				End If
				ChartStatus.Refresh()
				GenChartsStatusCustom.Add(ChartNum, ChartStatus)
				ChartNum += 1

				' % Uptime Chart
				Dim ChartUptime As ScottPlot.FormsPlot = CreateChart("% Uptime", "MMM dd", True)
				Dim pltUptime As ScottPlot.Plot = ChartUptime.Plot

				If xs.Count > 0 Then
					Dim curvePercUpTime As ScottPlot.Plottable.ScatterPlot =pltUptime.AddScatter(xs.ToArray(), ysPercUpTime.ToArray(), Color.Blue)
					curvePercUpTime.Label = "% Uptime"
					curvePercUpTime.LineWidth = 1.5
					If tblResults.Rows.Count > mSymbolMaxPts Then
						curvePercUpTime.MarkerSize = 0
					Else
						curvePercUpTime.MarkerSize = 7
				End If
				End If

				pltUptime.Legend()
				ChartUptime.Refresh()
				GenChartsStatusCustom.Add(ChartNum, ChartUptime)
				ChartNum += 1
			End If

		Catch ex As Exception
			MsgBox("Error running report:" & vbCrLf & ex.ToString, MsgBoxStyle.Exclamation Or MsgBoxStyle.OkOnly, "PolyMon Error")
		Finally
			If SQLConn.State <> ConnectionState.Closed Then SQLConn.Close()
			daSQL.Dispose()
			SQLConn.Dispose()
		End Try
	End Function

	Private Function GenChartsCountersRaw(ByVal MonitorID As Integer, ByVal StartDT As Date, ByVal EndDT As Date) As Dictionary(Of Integer, ScottPlot.FormsPlot)
		GenChartsCountersRaw = New Dictionary(Of Integer, ScottPlot.FormsPlot)
		Dim ChartNum As Integer = 0

		'Retrieve data
		Dim SQLConn As New SqlConnection(mSQLConn)

		Dim prmMonitorID As New SqlParameter
		With prmMonitorID
			.ParameterName = "@MonitorID"
			.SqlDbType = SqlDbType.Int
			.Direction = ParameterDirection.Input
			.Value = MonitorID
		End With

		Dim prmStartDT As New SqlParameter
		With prmStartDT
			.ParameterName = "@StartDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = StartDT
		End With

		Dim prmEndDT As New SqlParameter
		With prmEndDT
			.ParameterName = "@EndDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = EndDT
		End With

		Dim SQLCmd As New SqlCommand
		With SQLCmd
			.Connection = SQLConn
			.CommandType = CommandType.StoredProcedure
			.CommandTimeout = 180 '3 minutes
			.CommandText = "rpt_CounterData_Raw"
			.Parameters.Add(prmMonitorID)
			.Parameters.Add(prmStartDT)
			.Parameters.Add(prmEndDT)
		End With

		Dim tblResults As DataTable
		Dim dsResults As New DataSet
		Dim daSQL As New SqlDataAdapter(SQLCmd)

		Try
			SQLConn.Open()
			daSQL.Fill(dsResults)
			If dsResults.Tables.Count > 0 Then
				tblResults = dsResults.Tables(0)

				For Each col As DataColumn In tblResults.Columns
					If col.ColumnName = "DT_Raw" Then
						col.ExtendedProperties.Add("Visible", False)
					Else
						col.ExtendedProperties.Add("Visible", True)
					End If
					If col.ColumnName = "DT_Display" Then
						col.Caption = "Event Date"
					Else
						col.Caption = col.ColumnName
					End If
				Next
				mCounterData_Custom = tblResults

				'Do not plot anything if rows exceed mMaxDataPts
				If tblResults.Rows.Count > mMaxDataPts Then
					Dim dummy As ScottPlot.FormsPlot = CreateChart("Counter", "HH:mm", True)
					SetErrorWatermark(String.Format(cMaxReachedMsg, mMaxDataPts), dummy)
					dummy.Refresh()
					GenChartsCountersRaw.Add(ChartNum, dummy)
					ChartNum += 1
					Exit Function
				End If

				' Build X array (common to all counter columns)
				Dim xs As New List(Of Double)
				For Each row As DataRow In tblResults.Rows
					xs.Add(CDate(row("DT_Raw")).ToOADate())
				Next
				Dim xsArr As Double() = xs.ToArray()

				Dim ColName As String
				Dim Column As DataColumn
				For Each Column In tblResults.Columns
					ColName = Column.ColumnName
					If Not (ColName = "DT_Raw" OrElse ColName = "DT_Display") Then
						' Build Y array for this counter
						Dim ys As New List(Of Double)
						For Each row As DataRow In tblResults.Rows
							ys.Add(CDbl(row(ColName)))
						Next

						Dim Chart As ScottPlot.FormsPlot = CreateChart(String.Format("{0} - Detail", ColName), "HH:mm", True)
						Dim plt As ScottPlot.Plot = Chart.Plot

						If xs.Count > 0 Then
							Dim curveData As ScottPlot.Plottable.ScatterPlot =plt.AddScatter(xsArr, ys.ToArray(), Color.Blue)
							curveData.Label = ColName
							curveData.LineWidth = 1.5
							curveData.MarkerSize = 0
						End If

						Chart.Refresh()
						GenChartsCountersRaw.Add(ChartNum, Chart)
						ChartNum += 1
					End If
				Next
			End If

		Catch ex As Exception
			MsgBox("Error running report:" & vbCrLf & ex.ToString, MsgBoxStyle.Exclamation Or MsgBoxStyle.OkOnly, "PolyMon Error")
		Finally
			If SQLConn.State <> ConnectionState.Closed Then SQLConn.Close()
			daSQL.Dispose()
			SQLConn.Dispose()
		End Try
	End Function

	Private Function GenChartsCountersDaily(ByVal MonitorID As Integer, ByVal StartDT As Date, ByVal EndDT As Date) As Dictionary(Of Integer, ScottPlot.FormsPlot)
		GenChartsCountersDaily = New Dictionary(Of Integer, ScottPlot.FormsPlot)

		'Retrieve data
		Dim SQLConn As New SqlConnection(mSQLConn)

		Dim prmMonitorID As New SqlParameter
		With prmMonitorID
			.ParameterName = "@MonitorID"
			.SqlDbType = SqlDbType.Int
			.Direction = ParameterDirection.Input
			.Value = MonitorID
		End With

		Dim prmStartDT As New SqlParameter
		With prmStartDT
			.ParameterName = "@StartDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = StartDT
		End With

		Dim prmEndDT As New SqlParameter
		With prmEndDT
			.ParameterName = "@EndDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = EndDT
		End With

		Dim SQLCmd As New SqlCommand
		With SQLCmd
			.Connection = SQLConn
			.CommandType = CommandType.StoredProcedure
			.CommandTimeout = 180 '3 minutes
			.CommandText = "rpt_CounterData_Daily"
			.Parameters.Add(prmMonitorID)
			.Parameters.Add(prmStartDT)
			.Parameters.Add(prmEndDT)
		End With

		Dim tblResults As DataTable
		Dim dsResults As New DataSet
		Dim daSQL As New SqlDataAdapter(SQLCmd)

		Try
			SQLConn.Open()
			daSQL.Fill(dsResults)
			If dsResults.Tables.Count > 0 Then
				tblResults = dsResults.Tables(0)

				For Each col As DataColumn In tblResults.Columns
					If col.ColumnName = "DT_Raw" Then
						col.ExtendedProperties.Add("Visible", False)
					Else
						col.ExtendedProperties.Add("Visible", True)
					End If
					If col.ColumnName = "DT_Display" Then
						col.Caption = "Date"
					Else
						col.Caption = col.ColumnName
					End If
				Next
				mCounterData_Daily = tblResults

				' Build X array (common to all counter columns)
				Dim xs As New List(Of Double)
				For Each row As DataRow In tblResults.Rows
					xs.Add(CDate(row("DT_Raw")).ToOADate())
				Next
				Dim xsArr As Double() = xs.ToArray()

				Dim ChartNum As Integer = 0
				Dim ColName As String
				Dim Column As DataColumn
				For Each Column In tblResults.Columns
					ColName = Column.ColumnName
					If Not (ColName = "DT_Raw" OrElse ColName = "DT_Display" OrElse ColName.EndsWith("Avg") OrElse ColName.EndsWith("(# Samples)")) Then
						' Build Y array for this counter
						Dim ys As New List(Of Double)
						For Each row As DataRow In tblResults.Rows
							ys.Add(CDbl(row(ColName)))
						Next

						Dim Chart As ScottPlot.FormsPlot = CreateChart(String.Format("{0} - Daily", ColName), "MMM dd", True)
						Dim plt As ScottPlot.Plot = Chart.Plot

						If xs.Count > 0 Then
							Dim curveData As ScottPlot.Plottable.ScatterPlot =plt.AddScatter(xsArr, ys.ToArray(), Color.Blue)
							curveData.Label = ColName
							curveData.LineWidth = 1.5
							If tblResults.Rows.Count > mSymbolMaxPts Then
								curveData.MarkerSize = 0
							Else
								curveData.MarkerSize = 7
						End If
						End If

						Chart.Refresh()
						GenChartsCountersDaily.Add(ChartNum, Chart)
						ChartNum += 1
					End If
				Next
			End If

		Catch ex As Exception
			MsgBox("Error running report:" & vbCrLf & ex.ToString, MsgBoxStyle.Exclamation Or MsgBoxStyle.OkOnly, "PolyMon Error")
		Finally
			If SQLConn.State <> ConnectionState.Closed Then SQLConn.Close()
			daSQL.Dispose()
			SQLConn.Dispose()
		End Try
	End Function

	Private Function GenChartsCountersWeekly(ByVal MonitorID As Integer, ByVal StartDT As Date, ByVal EndDT As Date) As Dictionary(Of Integer, ScottPlot.FormsPlot)
		GenChartsCountersWeekly = New Dictionary(Of Integer, ScottPlot.FormsPlot)
		Dim ChartNum As Integer = 0

		'Retrieve data
		Dim SQLConn As New SqlConnection(mSQLConn)

		Dim prmMonitorID As New SqlParameter
		With prmMonitorID
			.ParameterName = "@MonitorID"
			.SqlDbType = SqlDbType.Int
			.Direction = ParameterDirection.Input
			.Value = MonitorID
		End With

		Dim prmStartDT As New SqlParameter
		With prmStartDT
			.ParameterName = "@StartDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = StartDT
		End With

		Dim prmEndDT As New SqlParameter
		With prmEndDT
			.ParameterName = "@EndDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = EndDT
		End With

		Dim SQLCmd As New SqlCommand
		With SQLCmd
			.Connection = SQLConn
			.CommandType = CommandType.StoredProcedure
			.CommandTimeout = 180 '3 minutes
			.CommandText = "rpt_CounterData_Weekly"
			.Parameters.Add(prmMonitorID)
			.Parameters.Add(prmStartDT)
			.Parameters.Add(prmEndDT)
		End With

		Dim tblResults As DataTable
		Dim dsResults As New DataSet
		Dim daSQL As New SqlDataAdapter(SQLCmd)

		Try
			SQLConn.Open()
			daSQL.Fill(dsResults)
			If dsResults.Tables.Count > 0 Then
				tblResults = dsResults.Tables(0)

				For Each col As DataColumn In tblResults.Columns
					If col.ColumnName = "StartDT_Raw" OrElse col.ColumnName = "EndDT_Raw" Then
						col.ExtendedProperties.Add("Visible", False)
					Else
						col.ExtendedProperties.Add("Visible", True)
					End If
					If col.ColumnName = "StartDT_Display" Then
						col.Caption = "Start Date"
					ElseIf col.ColumnName = "EndDT_Display" Then
						col.Caption = "End Date"
					ElseIf col.ColumnName = "WeekOfYear" Then
						col.Caption = "Week"
					Else
						col.Caption = col.ColumnName
					End If
				Next
				mCounterData_Weekly = tblResults

				' Build X array (common to all counter columns)
				Dim xs As New List(Of Double)
				For Each row As DataRow In tblResults.Rows
					xs.Add(CDate(row("StartDT_Raw")).ToOADate())
				Next
				Dim xsArr As Double() = xs.ToArray()

				Dim ColName As String
				Dim Column As DataColumn
				For Each Column In tblResults.Columns
					ColName = Column.ColumnName
					If Not (ColName = "StartDT_Raw" OrElse ColName = "StartDT_Display" OrElse ColName = "EndDT_Raw" OrElse ColName = "EndDT_Display" OrElse ColName = "Year" OrElse ColName = "WeekOfYear" OrElse ColName.EndsWith("Avg") OrElse ColName.EndsWith("(# Samples)")) Then
						' Build Y array for this counter
						Dim ys As New List(Of Double)
						For Each row As DataRow In tblResults.Rows
							ys.Add(CDbl(row(ColName)))
						Next

						Dim Chart As ScottPlot.FormsPlot = CreateChart(String.Format("{0} - Weekly", ColName), "MMM dd", True)
						Dim plt As ScottPlot.Plot = Chart.Plot

						If xs.Count > 0 Then
							Dim curveData As ScottPlot.Plottable.ScatterPlot =plt.AddScatter(xsArr, ys.ToArray(), Color.Blue)
							curveData.Label = ColName
							curveData.LineWidth = 1.5
							If tblResults.Rows.Count > mSymbolMaxPts Then
								curveData.MarkerSize = 0
							Else
								curveData.MarkerSize = 7
						End If
						End If

						Chart.Refresh()
						GenChartsCountersWeekly.Add(ChartNum, Chart)
						ChartNum += 1
					End If
				Next
			End If

		Catch ex As Exception
			MsgBox("Error running report:" & vbCrLf & ex.ToString, MsgBoxStyle.Exclamation Or MsgBoxStyle.OkOnly, "PolyMon Error")
		Finally
			If SQLConn.State <> ConnectionState.Closed Then SQLConn.Close()
			daSQL.Dispose()
			SQLConn.Dispose()
		End Try
	End Function

	Private Function GenChartsCountersMonthly(ByVal MonitorID As Integer, ByVal StartDT As Date, ByVal EndDT As Date) As Dictionary(Of Integer, ScottPlot.FormsPlot)
		GenChartsCountersMonthly = New Dictionary(Of Integer, ScottPlot.FormsPlot)
		Dim ChartNum As Integer = 0

		'Retrieve data
		Dim SQLConn As New SqlConnection(mSQLConn)

		Dim prmMonitorID As New SqlParameter
		With prmMonitorID
			.ParameterName = "@MonitorID"
			.SqlDbType = SqlDbType.Int
			.Direction = ParameterDirection.Input
			.Value = MonitorID
		End With

		Dim prmStartDT As New SqlParameter
		With prmStartDT
			.ParameterName = "@StartDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = StartDT
		End With

		Dim prmEndDT As New SqlParameter
		With prmEndDT
			.ParameterName = "@EndDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = EndDT
		End With

		Dim SQLCmd As New SqlCommand
		With SQLCmd
			.Connection = SQLConn
			.CommandType = CommandType.StoredProcedure
			.CommandTimeout = 180 '3 minutes
			.CommandText = "rpt_CounterData_Monthly"
			.Parameters.Add(prmMonitorID)
			.Parameters.Add(prmStartDT)
			.Parameters.Add(prmEndDT)
		End With

		Dim tblResults As DataTable
		Dim dsResults As New DataSet
		Dim daSQL As New SqlDataAdapter(SQLCmd)

		Try
			SQLConn.Open()
			daSQL.Fill(dsResults)
			If dsResults.Tables.Count > 0 Then
				tblResults = dsResults.Tables(0)

				For Each col As DataColumn In tblResults.Columns
					If col.ColumnName = "StartDT_Raw" OrElse col.ColumnName = "EndDT_Raw" Then
						col.ExtendedProperties.Add("Visible", False)
					Else
						col.ExtendedProperties.Add("Visible", True)
					End If
					If col.ColumnName = "StartDT_Display" Then
						col.Caption = "Start Date"
					ElseIf col.ColumnName = "EndDT_Display" Then
						col.Caption = "End Date"
					Else
						col.Caption = col.ColumnName
					End If
				Next
				mCounterData_Monthly = tblResults

				' Build X array (common to all counter columns)
				Dim xs As New List(Of Double)
				For Each row As DataRow In tblResults.Rows
					xs.Add(CDate(row("StartDT_Raw")).ToOADate())
				Next
				Dim xsArr As Double() = xs.ToArray()

				Dim ColName As String
				Dim Column As DataColumn
				For Each Column In tblResults.Columns
					ColName = Column.ColumnName
					If Not (ColName = "StartDT_Raw" OrElse ColName = "StartDT_Display" OrElse ColName = "EndDT_Raw" OrElse ColName = "EndDT_Display" OrElse ColName = "Year" OrElse ColName = "Month" OrElse ColName.EndsWith("Avg") OrElse ColName.EndsWith("(# Samples)")) Then
						' Build Y array for this counter
						Dim ys As New List(Of Double)
						For Each row As DataRow In tblResults.Rows
							ys.Add(CDbl(row(ColName)))
						Next

						Dim Chart As ScottPlot.FormsPlot = CreateChart(String.Format("{0} - Monthly", ColName), "MMM yyyy", True)
						Dim plt As ScottPlot.Plot = Chart.Plot

						If xs.Count > 0 Then
							Dim curveData As ScottPlot.Plottable.ScatterPlot =plt.AddScatter(xsArr, ys.ToArray(), Color.Blue)
							curveData.Label = ColName
							curveData.LineWidth = 1.5
							If tblResults.Rows.Count > mSymbolMaxPts Then
								curveData.MarkerSize = 0
							Else
								curveData.MarkerSize = 7
						End If
						End If

						Chart.Refresh()
						GenChartsCountersMonthly.Add(ChartNum, Chart)
						ChartNum += 1
					End If
				Next
			End If

		Catch ex As Exception
			MsgBox("Error running report:" & vbCrLf & ex.ToString, MsgBoxStyle.Exclamation Or MsgBoxStyle.OkOnly, "PolyMon Error")
		Finally
			If SQLConn.State <> ConnectionState.Closed Then SQLConn.Close()
			daSQL.Dispose()
			SQLConn.Dispose()
		End Try
	End Function

	Private Function GenChartsCountersCustom(ByVal MonitorID As Integer, ByVal StartDT As Date, ByVal EndDT As Date, ByVal TPMinutes As Integer) As Dictionary(Of Integer, ScottPlot.FormsPlot)
		GenChartsCountersCustom = New Dictionary(Of Integer, ScottPlot.FormsPlot)
		Dim ChartNum As Integer = 0

		'Retrieve data
		Dim SQLConn As New SqlConnection(mSQLConn)

		Dim prmMonitorID As New SqlParameter
		With prmMonitorID
			.ParameterName = "@MonitorID"
			.SqlDbType = SqlDbType.Int
			.Direction = ParameterDirection.Input
			.Value = MonitorID
		End With

		Dim prmStartDT As New SqlParameter
		With prmStartDT
			.ParameterName = "@StartDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = StartDT
		End With

		Dim prmEndDT As New SqlParameter
		With prmEndDT
			.ParameterName = "@EndDT"
			.SqlDbType = SqlDbType.DateTime
			.Direction = ParameterDirection.Input
			.Value = EndDT
		End With

		Dim prmTPMinutes As New SqlParameter
		With prmTPMinutes
			.ParameterName = "@TPMinutes"
			.SqlDbType = SqlDbType.Int
			.Direction = ParameterDirection.Input
			.Value = TPMinutes
		End With

		Dim SQLCmd As New SqlCommand
		With SQLCmd
			.Connection = SQLConn
			.CommandType = CommandType.StoredProcedure
			.CommandTimeout = 180 '3 minutes
			.CommandText = "rpt_CounterData_CustomAverage"
			.Parameters.Add(prmMonitorID)
			.Parameters.Add(prmStartDT)
			.Parameters.Add(prmEndDT)
			.Parameters.Add(prmTPMinutes)
		End With

		Dim tblResults As DataTable
		Dim dsResults As New DataSet
		Dim daSQL As New SqlDataAdapter(SQLCmd)

		Try
			SQLConn.Open()
			daSQL.Fill(dsResults)
			If dsResults.Tables.Count > 0 Then
				tblResults = dsResults.Tables(0)

				For Each col As DataColumn In tblResults.Columns
					If col.ColumnName = "StartDT_Raw" OrElse col.ColumnName = "EndDT_Raw" Then
						col.ExtendedProperties.Add("Visible", False)
					Else
						col.ExtendedProperties.Add("Visible", True)
					End If
					If col.ColumnName = "StartDT_Display" Then
						col.Caption = "Start Date"
					ElseIf col.ColumnName = "EndDT_Display" Then
						col.Caption = "End Date"
					ElseIf col.ColumnName = "WeekOfYear" Then
						col.Caption = "Week"
					Else
						col.Caption = col.ColumnName
					End If
				Next
				mCounterData_Custom = tblResults

				'Do not plot anything if rows exceed mMaxDataPts
				If tblResults.Rows.Count > mMaxDataPts Then
					Dim dummy As ScottPlot.FormsPlot = CreateChart("Counter", "MMM dd", True)
					SetErrorWatermark(String.Format(cMaxReachedMsg, mMaxDataPts), dummy)
					dummy.Refresh()
					GenChartsCountersCustom.Add(ChartNum, dummy)
					ChartNum += 1
					Exit Function
				End If

				' Build X array (common to all counter columns)
				Dim xs As New List(Of Double)
				For Each row As DataRow In tblResults.Rows
					xs.Add(CDate(row("StartDT_Raw")).ToOADate())
				Next
				Dim xsArr As Double() = xs.ToArray()

				Dim ColName As String
				Dim Column As DataColumn
				For Each Column In tblResults.Columns
					ColName = Column.ColumnName
					If Not (ColName = "StartDT_Raw" OrElse ColName = "StartDT_Display" OrElse ColName = "EndDT_Raw" OrElse ColName = "EndDT_Display" OrElse ColName.EndsWith("Avg") OrElse ColName.EndsWith("(# Samples)")) Then
						' Build Y array for this counter
						Dim ys As New List(Of Double)
						For Each row As DataRow In tblResults.Rows
							ys.Add(CDbl(row(ColName)))
						Next

						Dim Chart As ScottPlot.FormsPlot = CreateChart(ColName, "MMM dd", True)
						Dim plt As ScottPlot.Plot = Chart.Plot

						If xs.Count > 0 Then
							Dim curveData As ScottPlot.Plottable.ScatterPlot =plt.AddScatter(xsArr, ys.ToArray(), Color.Blue)
							curveData.Label = ColName
							curveData.LineWidth = 1.5
							If tblResults.Rows.Count > mSymbolMaxPts Then
								curveData.MarkerSize = 0
							Else
								curveData.MarkerSize = 7
						End If
						End If

						Chart.Refresh()
						GenChartsCountersCustom.Add(ChartNum, Chart)
						ChartNum += 1
					End If
				Next
			End If

		Catch ex As Exception
			MsgBox("Error running report:" & vbCrLf & ex.ToString, MsgBoxStyle.Exclamation Or MsgBoxStyle.OkOnly, "PolyMon Error")
		Finally
			If SQLConn.State <> ConnectionState.Closed Then SQLConn.Close()
			daSQL.Dispose()
			SQLConn.Dispose()
		End Try
	End Function

#End Region
End Class
