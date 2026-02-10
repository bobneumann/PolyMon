Imports System.IO
Imports System.Net
Imports System.Text

Namespace Notifier
	Public Class PolyMonPushNotifier
		Private mPushService As String
		Private mPushServerURL As String
		Private mPushToken As String

		''' <summary>
		''' Creates a push notifier using saved SysSettings from the database.
		''' </summary>
		Public Sub New()
			Dim SysSettings As New PolyMon.General.SysSettings()
			mPushService = SysSettings.PushService
			mPushServerURL = SysSettings.PushServerURL
			mPushToken = SysSettings.PushToken
		End Sub

		''' <summary>
		''' Creates a push notifier with explicit settings (used for test sends).
		''' </summary>
		Public Sub New(ByVal Service As String, ByVal ServerURL As String, ByVal Token As String)
			mPushService = Service
			mPushServerURL = ServerURL
			mPushToken = Token
		End Sub

		Public ReadOnly Property IsEnabled() As Boolean
			Get
				Return Not String.IsNullOrEmpty(mPushService) AndAlso mPushService <> "None"
			End Get
		End Property

		Public Sub SendPush(ByVal Address As String, ByVal Subject As String, ByVal Body As String)
			If Not IsEnabled Then Exit Sub
			If String.IsNullOrEmpty(Address) Then Exit Sub

			Select Case mPushService
				Case "ntfy"
					SendNtfy(Address, Subject, Body)
				Case "Pushover"
					SendPushover(Address, Subject, Body)
				Case "Telegram"
					SendTelegram(Address, Subject, Body)
			End Select
		End Sub

		Private Sub SendNtfy(ByVal Topic As String, ByVal Subject As String, ByVal Body As String)
			Dim ServerURL As String = mPushServerURL
			If String.IsNullOrEmpty(ServerURL) Then ServerURL = "https://ntfy.sh"
			ServerURL = ServerURL.TrimEnd("/"c)

			Dim url As String = ServerURL & "/" & Topic
			Dim request As HttpWebRequest = CType(WebRequest.Create(url), HttpWebRequest)
			request.Method = "POST"
			request.ContentType = "text/plain"

			If Not String.IsNullOrEmpty(Subject) Then
				request.Headers.Add("Title", Subject)
			End If

			If Not String.IsNullOrEmpty(mPushToken) Then
				request.Headers.Add("Authorization", "Bearer " & mPushToken)
			End If

			Dim messageText As String = If(Body, "")
			Dim data As Byte() = Encoding.UTF8.GetBytes(messageText)
			request.ContentLength = data.Length

			Using stream As Stream = request.GetRequestStream()
				stream.Write(data, 0, data.Length)
			End Using

			Using response As HttpWebResponse = CType(request.GetResponse(), HttpWebResponse)
				' Success if no exception thrown
			End Using
		End Sub

		Private Sub SendPushover(ByVal UserKey As String, ByVal Subject As String, ByVal Body As String)
			Dim url As String = "https://api.pushover.net/1/messages.json"
			Dim request As HttpWebRequest = CType(WebRequest.Create(url), HttpWebRequest)
			request.Method = "POST"
			request.ContentType = "application/x-www-form-urlencoded"

			Dim messageText As String = If(Body, "")
			Dim postData As String = "token=" & Uri.EscapeDataString(If(mPushToken, "")) &
				"&user=" & Uri.EscapeDataString(UserKey) &
				"&title=" & Uri.EscapeDataString(If(Subject, "")) &
				"&message=" & Uri.EscapeDataString(messageText)

			Dim data As Byte() = Encoding.UTF8.GetBytes(postData)
			request.ContentLength = data.Length

			Using stream As Stream = request.GetRequestStream()
				stream.Write(data, 0, data.Length)
			End Using

			Using response As HttpWebResponse = CType(request.GetResponse(), HttpWebResponse)
				' Success if no exception thrown
			End Using
		End Sub

		Private Sub SendTelegram(ByVal ChatId As String, ByVal Subject As String, ByVal Body As String)
			Dim messageText As String = If(Subject, "")
			If Not String.IsNullOrEmpty(Body) Then
				messageText = messageText & vbLf & Body
			End If

			Dim url As String = "https://api.telegram.org/bot" & If(mPushToken, "") & "/sendMessage"
			Dim request As HttpWebRequest = CType(WebRequest.Create(url), HttpWebRequest)
			request.Method = "POST"
			request.ContentType = "application/x-www-form-urlencoded"

			Dim postData As String = "chat_id=" & Uri.EscapeDataString(ChatId) &
				"&text=" & Uri.EscapeDataString(messageText)

			Dim data As Byte() = Encoding.UTF8.GetBytes(postData)
			request.ContentLength = data.Length

			Using stream As Stream = request.GetRequestStream()
				stream.Write(data, 0, data.Length)
			End Using

			Using response As HttpWebResponse = CType(request.GetResponse(), HttpWebResponse)
				' Success if no exception thrown
			End Using
		End Sub
	End Class
End Namespace
