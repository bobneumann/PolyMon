Imports System.IO
Imports System.Net
Imports System.Net.Security
Imports System.Security.Cryptography.X509Certificates
Imports System.Text
Imports System.Web.Script.Serialization

Public Class frmEmailRelayConfig

    Private mSysSettings As PolyMon.General.SysSettings

    Public Sub New(ByVal settings As PolyMon.General.SysSettings)
        InitializeComponent()
        mSysSettings = settings
    End Sub

    Private Sub frmEmailRelayConfig_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        txtApiKey.Text = If(mSysSettings.EmailRelayKey, "")
        LoadData()
    End Sub

    Private Sub btnRefresh_Click(sender As Object, e As EventArgs) Handles btnRefresh.Click
        LoadData()
    End Sub

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        SaveAll()
    End Sub

    Private Sub btnAdd_Click(sender As Object, e As EventArgs) Handles btnAdd.Click
        If lvAvailable.SelectedItems.Count = 0 Then Return
        Dim item As ListViewItem = lvAvailable.SelectedItems(0)
        lvAvailable.Items.Remove(item)
        lvForwardTo.Items.Add(item)
    End Sub

    Private Sub btnRemove_Click(sender As Object, e As EventArgs) Handles btnRemove.Click
        If lvForwardTo.SelectedItems.Count = 0 Then Return
        Dim item As ListViewItem = lvForwardTo.SelectedItems(0)
        lvForwardTo.Items.Remove(item)
        ' Add back to available if it's a known room
        lvAvailable.Items.Add(item)
    End Sub

    Private Sub lvAvailable_DoubleClick(sender As Object, e As EventArgs) Handles lvAvailable.DoubleClick
        btnAdd_Click(sender, e)
    End Sub

    Private Sub lvForwardTo_DoubleClick(sender As Object, e As EventArgs) Handles lvForwardTo.DoubleClick
        btnRemove_Click(sender, e)
    End Sub

    Private Sub LoadData()
        If String.IsNullOrEmpty(mSysSettings.PushService) OrElse mSysSettings.PushService <> "Matrix" Then
            lblStatus.Text = "Error: Push service must be set to Matrix."
            Return
        End If
        If String.IsNullOrEmpty(mSysSettings.PushServerURL) OrElse String.IsNullOrEmpty(mSysSettings.PushToken) Then
            lblStatus.Text = "Error: Matrix homeserver URL and access token must be configured."
            Return
        End If

        lblStatus.Text = "Loading..."
        btnRefresh.Enabled = False
        btnSave.Enabled = False
        Me.Cursor = Cursors.WaitCursor
        Application.DoEvents()

        ' Bypass SSL cert validation
        ServicePointManager.ServerCertificateValidationCallback =
            Function(s As Object, cert As X509Certificate, chain As X509Chain, errs As SslPolicyErrors) True

        Try
            ' Step 1: Load all Matrix Signal-bridged rooms (left panel)
            Dim allRooms As New List(Of KeyValuePair(Of String, String)) ' (displayName, roomId)
            allRooms = LoadMatrixRooms()

            ' Step 2: Load rooms currently configured on VM (right panel)
            Dim configuredRoomIds As New List(Of String)
            configuredRoomIds = LoadConfiguredRooms()

            ' Step 3: Build a display-name lookup map from Matrix rooms
            Dim roomNameMap As New Dictionary(Of String, String) ' roomId -> displayName
            For Each kvp As KeyValuePair(Of String, String) In allRooms
                If Not roomNameMap.ContainsKey(kvp.Value) Then
                    roomNameMap.Add(kvp.Value, kvp.Key)
                End If
            Next

            ' Step 4: Populate left panel (available = all Matrix rooms NOT in configured list)
            lvAvailable.Items.Clear()
            For Each kvp As KeyValuePair(Of String, String) In allRooms
                If Not configuredRoomIds.Contains(kvp.Value) Then
                    Dim item As New ListViewItem(kvp.Key)
                    item.SubItems.Add(kvp.Value)
                    lvAvailable.Items.Add(item)
                End If
            Next

            ' Step 5: Populate right panel (configured rooms)
            lvForwardTo.Items.Clear()
            For Each roomId As String In configuredRoomIds
                Dim displayName As String = If(roomNameMap.ContainsKey(roomId), roomNameMap(roomId), roomId)
                Dim item As New ListViewItem(displayName)
                item.SubItems.Add(roomId)
                lvForwardTo.Items.Add(item)
            Next

            lblStatus.Text = String.Format("{0} available room(s), {1} configured", allRooms.Count, configuredRoomIds.Count)

        Catch ex As Exception
            lblStatus.Text = "Error loading: " & ex.Message
        Finally
            btnRefresh.Enabled = True
            btnSave.Enabled = True
            Me.Cursor = Cursors.Default
        End Try
    End Sub

    Private Function LoadMatrixRooms() As List(Of KeyValuePair(Of String, String))
        Dim result As New List(Of KeyValuePair(Of String, String))
        Dim serverURL As String = mSysSettings.PushServerURL.TrimEnd("/"c)
        Dim token As String = mSysSettings.PushToken
        Dim ser As New JavaScriptSerializer()

        ' Get joined rooms
        Dim roomsJson As String = MatrixGet(serverURL, token, "/_matrix/client/v3/joined_rooms")
        Dim roomsDict As Dictionary(Of String, Object) = ser.Deserialize(Of Dictionary(Of String, Object))(roomsJson)
        Dim roomIds As ArrayList = CType(roomsDict("joined_rooms"), ArrayList)

        For Each roomId As Object In roomIds
            Dim rid As String = CStr(roomId)
            Try
                Dim membersJson As String = MatrixGet(serverURL, token, "/_matrix/client/v3/rooms/" & Uri.EscapeDataString(rid) & "/members?membership=join")
                Dim membersDict As Dictionary(Of String, Object) = ser.Deserialize(Of Dictionary(Of String, Object))(membersJson)
                Dim chunks As ArrayList = CType(membersDict("chunk"), ArrayList)

                Dim signalNames As New List(Of String)
                For Each chunk As Object In chunks
                    Dim evt As Dictionary(Of String, Object) = CType(chunk, Dictionary(Of String, Object))
                    Dim stateKey As String = If(evt.ContainsKey("state_key"), CStr(evt("state_key")), "")
                    If stateKey.StartsWith("@signal_") Then
                        Dim displayName As String = ""
                        Try
                            Dim profileJson As String = MatrixGet(serverURL, token, "/_matrix/client/v3/profile/" & Uri.EscapeDataString(stateKey) & "/displayname")
                            Dim profileDict As Dictionary(Of String, Object) = ser.Deserialize(Of Dictionary(Of String, Object))(profileJson)
                            If profileDict.ContainsKey("displayname") AndAlso profileDict("displayname") IsNot Nothing Then
                                displayName = CStr(profileDict("displayname"))
                            End If
                        Catch
                            displayName = stateKey
                        End Try
                        If String.IsNullOrEmpty(displayName) Then displayName = stateKey
                        signalNames.Add(displayName)
                    End If
                Next

                If signalNames.Count > 0 Then
                    Dim bestName As String = signalNames(0)
                    For Each n As String In signalNames
                        If Not n.StartsWith("+") AndAlso Not n.StartsWith("@") Then
                            bestName = n
                            Exit For
                        End If
                    Next
                    result.Add(New KeyValuePair(Of String, String)(bestName, rid))
                End If
            Catch
                ' Skip rooms we can't read
            End Try
        Next

        Return result
    End Function

    Private Function LoadConfiguredRooms() As List(Of String)
        Dim result As New List(Of String)
        Dim apiKey As String = txtApiKey.Text.Trim()
        If String.IsNullOrEmpty(apiKey) Then Return result

        Dim serverURL As String = mSysSettings.PushServerURL.TrimEnd("/"c)
        Dim json As String = RelayApiGet(serverURL, apiKey, "/email-relay/rooms")

        Dim ser As New JavaScriptSerializer()
        Dim data As Dictionary(Of String, Object) = ser.Deserialize(Of Dictionary(Of String, Object))(json)
        If data.ContainsKey("rooms") AndAlso data("rooms") IsNot Nothing Then
            Dim rooms As ArrayList = CType(data("rooms"), ArrayList)
            For Each r As Object In rooms
                result.Add(CStr(r))
            Next
        End If
        Return result
    End Function

    Private Sub SaveAll()
        Me.Cursor = Cursors.WaitCursor
        btnSave.Enabled = False
        lblStatus.Text = "Saving..."
        Application.DoEvents()

        Try
            ' 1. Save API key to SysSettings
            mSysSettings.SetEmailRelayKey(txtApiKey.Text.Trim())
            mSysSettings.Save()

            ' 2. Build room list from right panel
            Dim rooms As New List(Of String)
            For Each item As ListViewItem In lvForwardTo.Items
                rooms.Add(item.SubItems(1).Text)
            Next

            ' 3. PUT to VM API
            Dim ser As New JavaScriptSerializer()
            Dim payload As New Dictionary(Of String, Object)
            payload("rooms") = rooms
            Dim body As String = ser.Serialize(payload)

            Dim serverURL As String = mSysSettings.PushServerURL.TrimEnd("/"c)
            Dim apiKey As String = txtApiKey.Text.Trim()
            RelayApiPut(serverURL, apiKey, "/email-relay/rooms", body)

            lblStatus.Text = String.Format("Saved. {0} room(s) configured.", rooms.Count)
            MsgBox("Email relay rooms saved successfully.", MsgBoxStyle.Information, "PolyMon")

        Catch ex As Exception
            lblStatus.Text = "Error saving: " & ex.Message
            MsgBox("Error saving: " & ex.Message, MsgBoxStyle.Exclamation, "PolyMon")
        Finally
            btnSave.Enabled = True
            Me.Cursor = Cursors.Default
        End Try
    End Sub

    Private Function MatrixGet(ByVal serverURL As String, ByVal token As String, ByVal path As String) As String
        Dim url As String = serverURL & path
        Dim request As HttpWebRequest = CType(WebRequest.Create(url), HttpWebRequest)
        request.Method = "GET"
        request.Headers.Add("Authorization", "Bearer " & token)
        request.Timeout = 15000
        Using response As HttpWebResponse = CType(request.GetResponse(), HttpWebResponse)
            Using reader As New StreamReader(response.GetResponseStream(), Encoding.UTF8)
                Return reader.ReadToEnd()
            End Using
        End Using
    End Function

    Private Function RelayApiGet(ByVal serverURL As String, ByVal apiKey As String, ByVal path As String) As String
        Dim url As String = serverURL & path
        Dim request As HttpWebRequest = CType(WebRequest.Create(url), HttpWebRequest)
        request.Method = "GET"
        request.Headers.Add("Authorization", "Bearer " & apiKey)
        request.Timeout = 15000
        Using response As HttpWebResponse = CType(request.GetResponse(), HttpWebResponse)
            Using reader As New StreamReader(response.GetResponseStream(), Encoding.UTF8)
                Return reader.ReadToEnd()
            End Using
        End Using
    End Function

    Private Sub RelayApiPut(ByVal serverURL As String, ByVal apiKey As String, ByVal path As String, ByVal body As String)
        Dim url As String = serverURL & path
        Dim request As HttpWebRequest = CType(WebRequest.Create(url), HttpWebRequest)
        request.Method = "PUT"
        request.Headers.Add("Authorization", "Bearer " & apiKey)
        request.ContentType = "application/json"
        request.Timeout = 15000
        Dim bodyBytes As Byte() = Encoding.UTF8.GetBytes(body)
        request.ContentLength = bodyBytes.Length
        Using stream As Stream = request.GetRequestStream()
            stream.Write(bodyBytes, 0, bodyBytes.Length)
        End Using
        Using response As HttpWebResponse = CType(request.GetResponse(), HttpWebResponse)
            ' consume response
            Using reader As New StreamReader(response.GetResponseStream(), Encoding.UTF8)
                reader.ReadToEnd()
            End Using
        End Using
    End Sub

End Class
