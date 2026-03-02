Public Class frmReportData
	Private mMonitorID As Integer

	Public Sub New(ByVal MonitorID As Integer, ByVal MonitorName As String, ByVal MonitorType As String, ByVal tblStatus As DataTable, ByVal tblCounters As DataTable)
		InitializeComponent()


		mMonitorID = MonitorID
		Me.lblMonitor.Text = MonitorName
		Me.lblMonitorType.Text = MonitorType

		dgvStatus.BackgroundColor = Color.White
		dgvCounters.BackgroundColor = Color.White

		If tblStatus IsNot Nothing Then
			With dgvStatus
				.SuspendLayout()

				.DataSource = tblStatus

				.EnableHeadersVisualStyles = False
				.DefaultCellStyle.BackColor = Color.WhiteSmoke
				.AdvancedCellBorderStyle.All = DataGridViewAdvancedCellBorderStyle.None

				Dim HStyle As New DataGridViewCellStyle
				HStyle.ForeColor = Color.White
				HStyle.BackColor = Color.DarkBlue
				HStyle.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
				HStyle.Padding = New Padding(5)
				.ColumnHeadersDefaultCellStyle = HStyle

				.AdvancedColumnHeadersBorderStyle.All = DataGridViewAdvancedCellBorderStyle.None
				.AdvancedColumnHeadersBorderStyle.Bottom = DataGridViewAdvancedCellBorderStyle.Single

				.RowHeadersVisible = False

				.AllowUserToResizeRows = False
				.AllowUserToAddRows = False
				.AllowUserToDeleteRows = False
				.SelectionMode = DataGridViewSelectionMode.FullRowSelect
				.ReadOnly = True
				.AlternatingRowsDefaultCellStyle.BackColor = Color.LightSkyBlue

				For Each Col As DataColumn In tblStatus.Columns
					.Columns(Col.ColumnName).Visible = CBool(Col.ExtendedProperties("Visible"))
					.Columns(Col.ColumnName).HeaderText = Col.Caption
					.Columns(Col.ColumnName).AutoSizeMode = DataGridViewAutoSizeColumnMode.AllCells
					.Columns(Col.ColumnName).HeaderCell.Style.Alignment = DataGridViewContentAlignment.MiddleCenter
					.Columns(Col.ColumnName).DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter
				Next

				.AutoResizeColumns(DataGridViewAutoSizeColumnsMode.AllCells)
				For Each col As DataGridViewColumn In .Columns
					col.AutoSizeMode = DataGridViewAutoSizeColumnMode.None
				Next
				.ResumeLayout()
			End With
		End If

		If tblCounters IsNot Nothing Then
			With dgvCounters
				.SuspendLayout()
				.DataSource = tblCounters

				.EnableHeadersVisualStyles = False
				.DefaultCellStyle.BackColor = Color.WhiteSmoke
				.AdvancedCellBorderStyle.All = DataGridViewAdvancedCellBorderStyle.None

				Dim HStyle As New DataGridViewCellStyle
				HStyle.ForeColor = Color.White
				HStyle.BackColor = Color.DarkBlue
				HStyle.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
				HStyle.Padding = New Padding(5)
				.ColumnHeadersDefaultCellStyle = HStyle

				.AdvancedColumnHeadersBorderStyle.All = DataGridViewAdvancedCellBorderStyle.None
				.AdvancedColumnHeadersBorderStyle.Bottom = DataGridViewAdvancedCellBorderStyle.Single

				.RowHeadersVisible = False

				.AllowUserToResizeRows = False
				.AllowUserToAddRows = False
				.AllowUserToDeleteRows = False
				.SelectionMode = DataGridViewSelectionMode.FullRowSelect
				.ReadOnly = True
				.AlternatingRowsDefaultCellStyle.BackColor = Color.LightSkyBlue


				For Each Col As DataColumn In tblCounters.Columns
					.Columns(Col.ColumnName).Visible = CBool(Col.ExtendedProperties("Visible"))
					.Columns(Col.ColumnName).HeaderText = Col.Caption
					.Columns(Col.ColumnName).AutoSizeMode = DataGridViewAutoSizeColumnMode.AllCells
					.Columns(Col.ColumnName).HeaderCell.Style.Alignment = DataGridViewContentAlignment.MiddleCenter
					.Columns(Col.ColumnName).DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter
				Next

				.AutoResizeColumns(DataGridViewAutoSizeColumnsMode.AllCells)
				For Each col As DataGridViewColumn In .Columns
					col.AutoSizeMode = DataGridViewAutoSizeColumnMode.None
				Next
				.ResumeLayout()
				.Invalidate()
			End With
		End If

	End Sub

	Private Sub tsbExportStatus_Click(sender As Object, e As EventArgs) Handles tsbExportStatus.Click
		ExportToCsv(dgvStatus, "status_export.csv")
	End Sub

	Private Sub tsbExportCounters_Click(sender As Object, e As EventArgs) Handles tsbExportCounters.Click
		ExportToCsv(dgvCounters, "counters_export.csv")
	End Sub

	Private Sub ExportToCsv(ByVal dgv As DataGridView, ByVal defaultFileName As String)
		Using dlg As New SaveFileDialog()
			dlg.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
			dlg.FileName = defaultFileName
			If dlg.ShowDialog() <> DialogResult.OK Then Return
			Using sw As New System.IO.StreamWriter(dlg.FileName, False, System.Text.Encoding.UTF8)
				Dim visibleCols As New List(Of DataGridViewColumn)
				For Each col As DataGridViewColumn In dgv.Columns
					If col.Visible Then visibleCols.Add(col)
				Next
				Dim headers(visibleCols.Count - 1) As String
				For i As Integer = 0 To visibleCols.Count - 1
					headers(i) = CsvQuote(visibleCols(i).HeaderText)
				Next
				sw.WriteLine(String.Join(",", headers))
				For Each row As DataGridViewRow In dgv.Rows
					Dim cells(visibleCols.Count - 1) As String
					For i As Integer = 0 To visibleCols.Count - 1
						Dim v As Object = row.Cells(visibleCols(i).Index).Value
						cells(i) = CsvQuote(If(v Is Nothing, "", v.ToString()))
					Next
					sw.WriteLine(String.Join(",", cells))
				Next
			End Using
		End Using
	End Sub

	Private Function CsvQuote(ByVal s As String) As String
		If s.Contains(",") OrElse s.Contains("""") OrElse s.Contains(Chr(10)) OrElse s.Contains(Chr(13)) Then
			Return """" & s.Replace("""", """""") & """"
		End If
		Return s
	End Function

End Class