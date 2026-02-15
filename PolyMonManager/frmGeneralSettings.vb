Imports System.Drawing
Imports System.Data.sqlclient

Public Class frmGeneralSettings

#Region "Private Attributes"
	Private mSysSettings As PolyMon.General.SysSettings
	Private mRetentionSettings As PolyMon.General.DefaultRetentionSettings
    Private mUserSettings As New UserSettings
#End Region

#Region "Event Handlers"
    Private Sub frmGeneralSettings_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        'Populate Color Pick List with known colors
        cboMDIBackColor.Items.Clear()
        Dim ColName As String
        For Each ColName In System.Enum.GetNames(GetType(KnownColor))
            Me.cboMDIBackColor.Items.Add(ColName)
        Next

        'Populate Push Service picker
        cboPushService.Items.Clear()
        cboPushService.Items.Add("None")
        cboPushService.Items.Add("ntfy")
        cboPushService.Items.Add("Pushover")
        cboPushService.Items.Add("Telegram")
        cboPushService.Items.Add("Matrix")

        'Load System Settings
        If mSysSettings Is Nothing Then LoadSysSettings()

        'Load User Settings
        LoadUserSettings()
    End Sub
    Private Sub tsbSave_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles tsbSave.Click
        Me.Cursor = Cursors.WaitCursor
        SaveSysSettings()
        Me.Cursor = Cursors.Default
    End Sub
    Private Sub tsbCancel_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles tsbCancel.Click
        Me.Cursor = Cursors.WaitCursor
        LoadSysSettings()
        Me.Cursor = Cursors.Default
    End Sub

    Private Sub cboTimerIntervals_SelectedIndexChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cboTimerIntervals.SelectedIndexChanged
        Dim myTimerInterval As UserSettings.TimerInterval = CType(Me.cboTimerIntervals.SelectedItem, UserSettings.TimerInterval)
        mUserSettings.RefreshIntervalIndex = Me.cboTimerIntervals.SelectedIndex
        CType(Me.MdiParent, frmMain).SetTimerInterval()
    End Sub
    Private Sub chkAudioAlert_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles chkAudioAlert.CheckedChanged
        Me.mUserSettings.AudibleAlertsEnabled = Me.chkAudioAlert.Checked
    End Sub
    Private Sub chkBalloonAlerts_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles chkBalloonAlerts.CheckedChanged
        Me.mUserSettings.BalloonAlertsEnabled = Me.chkBalloonAlerts.Checked
    End Sub
    Private Sub cboMDIBackColor_SelectedIndexChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cboMDIBackColor.SelectedIndexChanged
        Dim NewColor As Color
        NewColor = Color.FromName(CStr(cboMDIBackColor.SelectedItem))
        mUserSettings.MDIBackColor = NewColor
        'Change MDI form background color
        Dim c As Control
        For Each c In Me.ParentForm.Controls
            If c.GetType.Name = "MdiClient" Then
                c.BackColor = NewColor
                Exit For
            End If
        Next
	End Sub

	Private Sub cboPushService_SelectedIndexChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cboPushService.SelectedIndexChanged
		Dim svc As String = CStr(cboPushService.SelectedItem)
		Select Case svc
			Case "None"
				txtPushServerURL.Enabled = False
				txtPushToken.Enabled = False
				btnSendTestPush.Enabled = False
				lblPushServerURL.Text = "Server URL"
				lblPushToken.Text = "Token / API Key"
				lblPushServerURL.Visible = False
				txtPushServerURL.Visible = False
				lblPushHelp.Text = "Select a push notification service to enable push alerts alongside email notifications."
			Case "ntfy"
				txtPushServerURL.Enabled = True
				txtPushToken.Enabled = True
				btnSendTestPush.Enabled = True
				lblPushServerURL.Text = "Server URL"
				lblPushToken.Text = "Access Token (optional)"
				lblPushServerURL.Visible = True
				txtPushServerURL.Visible = True
				lblPushHelp.Text = "Free, open-source push notifications. Create a unique topic name and subscribe to it in the ntfy app." & vbCrLf & vbCrLf & "Default server: ntfy.sh" & vbCrLf & "Docs: ntfy.sh/docs"
			Case "Pushover"
				txtPushServerURL.Enabled = False
				txtPushToken.Enabled = True
				btnSendTestPush.Enabled = True
				lblPushServerURL.Visible = False
				txtPushServerURL.Visible = False
				lblPushToken.Text = "App API Token"
				lblPushHelp.Text = "Simple push notifications ($5 one-time per device platform). Register an application at pushover.net to get your API token." & vbCrLf & vbCrLf & "Docs: pushover.net/api"
			Case "Telegram"
				txtPushServerURL.Enabled = False
				txtPushToken.Enabled = True
				btnSendTestPush.Enabled = True
				lblPushServerURL.Visible = False
				txtPushServerURL.Visible = False
				lblPushToken.Text = "Bot Token"
				lblPushHelp.Text = "Free push via Telegram. Create a bot with @BotFather to get a token. Each user sends /start to the bot, then uses their Chat ID as their key." & vbCrLf & vbCrLf & "Docs: core.telegram.org/bots"
			Case "Matrix"
				txtPushServerURL.Enabled = True
				txtPushToken.Enabled = True
				btnSendTestPush.Enabled = True
				lblPushServerURL.Text = "Homeserver URL"
				lblPushToken.Text = "Access Token"
				lblPushServerURL.Visible = True
				txtPushServerURL.Visible = True
				lblPushHelp.Text = "Send alerts to a Matrix room (can be bridged to Signal, Slack, etc.)." & vbCrLf & vbCrLf & "Enter your homeserver URL and an access token. Each operator's Push Key is their Matrix room ID."
		End Select
	End Sub

	Private Sub btnSendTestPush_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnSendTestPush.Click
		Dim PushAddress As String = Nothing
		PushAddress = InputBox("Please enter the push notification address/key to test." & vbCrLf & "(ntfy: topic name, Pushover: user key, Telegram: chat ID, Matrix: room ID)", "PolyMon - Push Notification Test")
		If String.IsNullOrEmpty(PushAddress) Then
			MsgBox("Test not sent - address was blank or cancelled.")
		Else
			Try
				Dim svc As String = CStr(cboPushService.SelectedItem)
				Dim serverURL As String = txtPushServerURL.Text.Trim()
				Dim token As String = txtPushToken.Text.Trim()
				Dim pusher As New PolyMon.Notifier.PolyMonPushNotifier(svc, serverURL, token)
				pusher.SendPush(PushAddress, "PolyMon - Test", "PolyMon push notification test. Please ignore.")
				MsgBox("Test push notification sent successfully.", MsgBoxStyle.Information, "PolyMon")
			Catch ex As Exception
				MsgBox("An error occurred sending push notification." & vbCrLf & ex.ToString(), MsgBoxStyle.Exclamation Or MsgBoxStyle.OkOnly, "PolyMon - Push Notification Error")
			End Try
		End If
	End Sub

	Private Sub btnSendTestMail_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnSendTestMail.Click
		'First get TO email address from user
		Dim EmailTO As String = Nothing

		EmailTO = InputBox("Please enter recipient's email address.", "PolyMon - Email Notifier Tester")
		If String.IsNullOrEmpty(EmailTO) Then
			MsgBox("Message was not sent - Email address was blank or cancelled")
		Else
			Try
				Dim PolyMonMail As New PolyMon.Notifier.PolyMonMailer()
				PolyMonMail.SendMail(EmailTO, Nothing, "PolyMon - Test", "PolyMon Test" & vbCrLf & "Please ignore.", False)
			Catch ex As Exception
				MsgBox("An error occurred sending email." & vbCrLf & ex.ToString(), MsgBoxStyle.Exclamation Or MsgBoxStyle.OkOnly, "Polymon - Email Notifier Error")
			End Try
		End If
	End Sub

	Private Sub trRaw_ValueChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles trRaw.ValueChanged
		Me.lblRaw.Text = String.Format("{0} Months", trRaw.Value.ToString())
		If trDaily.Value < trRaw.Value Then trDaily.Value = trRaw.Value
	End Sub
	Private Sub trDaily_ValueChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles trDaily.ValueChanged
		Me.lblDaily.Text = String.Format("{0} Months", trDaily.Value.ToString())
		If trWeekly.Value < trDaily.Value Then trWeekly.Value = trDaily.Value
		If trDaily.Value < trRaw.Value Then trDaily.Value = trRaw.Value
	End Sub
	Private Sub trWeekly_ValueChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles trWeekly.ValueChanged
		Me.lblWeekly.Text = String.Format("{0} Months", trWeekly.Value.ToString())
		If trMonthly.Value < trWeekly.Value Then trMonthly.Value = trWeekly.Value
		If trWeekly.Value < trDaily.Value Then trWeekly.Value = trDaily.Value
	End Sub
	Private Sub trMonthly_ValueChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles trMonthly.ValueChanged
		Me.lblMonthly.Text = String.Format("{0} Months", trMonthly.Value.ToString())
		If trMonthly.Value < trWeekly.Value Then trMonthly.Value = trWeekly.Value
    End Sub

    Private Sub tsbSaveRetentionScheme_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles tsbSaveRetentionScheme.Click
        Me.Cursor = Cursors.WaitCursor
        SaveRetentionSettings()
        Me.Cursor = Cursors.Default
    End Sub
#End Region

#Region "Private Methods"
    Private Sub LoadSysSettings()
        Try
            mSysSettings = New PolyMon.General.SysSettings
            With mSysSettings
                Me.chkSysEnabled.Checked = .IsEnabled
                Me.txtSysName.Text = .Name
                Me.txtSysServiceServer.Text = .ServiceServer
                Me.udSysMainTimerInterval.Value = .MainTimerInterval
                Me.txtSysSMTPServer.Text = .ExtSMTPServer
                Me.upSysSMTPPort.Value = .ExtSMTPPort
                Me.txtSysSMTPUserID.Text = .ExtSMTPUserID
                Me.txtSysSMTPPwd.Text = .ExtSMTPPwd
                Me.txtSysSMTPFromName.Text = .SMTPFromName
				Me.txtSysSMTPFromAddress.Text = .SMTPFromAddress
				Me.chkSysSMTPUseSSL.Checked = .ExtSMTPUseSSL

				'Push Notification settings
				If Not String.IsNullOrEmpty(.PushService) Then
					Me.cboPushService.SelectedItem = .PushService
				Else
					Me.cboPushService.SelectedIndex = 0 'None
				End If
				Me.txtPushServerURL.Text = If(.PushServerURL, "")
				Me.txtPushToken.Text = If(.PushToken, "")
			End With

			mRetentionSettings = New PolyMon.General.DefaultRetentionSettings
			With mRetentionSettings
				Me.trMonthly.Value = .Monthly
				Me.trWeekly.Value = .Weekly
				Me.trDaily.Value = .Daily
				Me.trRaw.Value = .Raw
			End With
        Catch ex As Exception
            MsgBox("Error retrieving data from database:" & vbCrLf & ex.Message & vbCrLf & vbCrLf & ex.InnerException.Message, MsgBoxStyle.Exclamation, "PolyMon Error")
        End Try
    End Sub
    Private Sub SaveSysSettings()
        Try
            With mSysSettings
                .Name = Me.txtSysName.Text
                .IsEnabled = Me.chkSysEnabled.Checked
                .ServiceServer = Me.txtSysServiceServer.Text
                .MainTimerInterval = CInt(Me.udSysMainTimerInterval.Value)
				.UseInternalSMTP = False 'For now we do not have an embedded SMTP service

				.SetExtSMTP(Me.txtSysSMTPServer.Text, CInt(Me.upSysSMTPPort.Value), Me.txtSysSMTPUserID.Text, Me.txtSysSMTPPwd.Text, Me.chkSysSMTPUseSSL.Checked)
				If Me.txtSysSMTPServer.Text.Trim().Length > 0 Then
					.SetSMTPFrom(Me.txtSysSMTPFromName.Text, Me.txtSysSMTPFromAddress.Text)
				End If
				.SetPushNotification(CStr(Me.cboPushService.SelectedItem), Me.txtPushServerURL.Text, Me.txtPushToken.Text)

                .Save()
            End With
        Catch ex As Exception
            If ex.InnerException Is Nothing Then
                MsgBox("Error Saving Settings:" & vbCrLf & ex.Message, MsgBoxStyle.Exclamation, "PolyMon Error")
            Else
                MsgBox("Error Saving Settings:" & vbCrLf & ex.Message & vbCrLf & vbCrLf & ex.InnerException.Message, MsgBoxStyle.Exclamation, "PolyMon Error")
            End If

        End Try
    End Sub
	Private Sub SaveRetentionSettings()
		Try
			With mRetentionSettings
				.Raw = trRaw.Value
				.Daily = trDaily.Value
				.Weekly = trWeekly.Value
				.Monthly = trMonthly.Value

				.Save()
			End With
		Catch ex As Exception
			MsgBox("Error Saving Retention Settings:" & vbCrLf & ex.ToString(), MsgBoxStyle.Exclamation Or MsgBoxStyle.OkOnly, "PolyMon Error")
		End Try
	End Sub
    Private Sub LoadUserSettings()
        Dim Interval As UserSettings.TimerInterval
        With Me.cboTimerIntervals
            .DisplayMember = "Name"
            .ValueMember = "Interval"
            .Items.Clear()
            For Each Interval In mUserSettings.RefreshIntervals
                .Items.Add(Interval)
            Next

            'Pre-select current value
            .SelectedIndex = mUserSettings.RefreshIntervalIndex
        End With

        'Set Audio On/Off
        Me.chkAudioAlert.Checked = mUserSettings.AudibleAlertsEnabled

        'Set Balloon On/Off
        Me.chkBalloonAlerts.Checked = mUserSettings.BalloonAlertsEnabled

        'MDI Back Color
        Me.cboMDIBackColor.Text = mUserSettings.MDIBackColor.Name
    End Sub
#End Region



	''Private Sub TabControl1_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles TabControl1.SelectedIndexChanged
	''	If TabControl1.SelectedTab Is Me.tpDBSettings Then
	''		'Refresh Database Connection info
	''		Dim ManagerConnString As String = CStr(System.Configuration.ConfigurationManager.AppSettings("SQLConn"))

	''		Me.lblServer_Manager.Text = Nothing
	''		Me.lblDatabase_Manager.Text = Nothing
	''		Me.chkIntegratedSecurity_Manager.Checked = False
	''		Me.lblUserID_Manager.Text = Nothing
	''		Me.lblPassword_Manager.Text = Nothing

	''		If Not String.IsNullOrEmpty(ManagerConnString) Then
	''			Try
	''				Dim Conn As New SqlConnectionStringBuilder(ManagerConnString)

	''				Me.lblServer_Manager.Text = Conn.DataSource
	''				Me.lblDatabase_Manager.Text = Conn.InitialCatalog
	''				Me.chkIntegratedSecurity_Manager.Checked = Conn.IntegratedSecurity
	''				If Not (Conn.IntegratedSecurity) Then
	''					Me.lblUserID_Manager.Text = Conn.UserID
	''					Me.lblPassword_Manager.Text = Conn.Password
	''				End If

	''				pcbStatus_Manager.Image = Me.imglstStatus.Images(0)
	''			Catch ex As Exception
	''				pcbStatus_Manager.Image = Me.imglstStatus.Images(1)
	''				lblStatus_Manager.Text = ex.Message
	''			End Try

	''			'Refresh PolyMon Executive
	''		End If
	''	End If
	''End Sub
End Class