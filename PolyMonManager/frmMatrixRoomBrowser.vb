Imports System.IO
Imports System.Net
Imports System.Text
Imports System.Web.Script.Serialization

Public Class frmMatrixRoomBrowser

    Private mServerURL As String
    Private mToken As String

    Public Property SelectedRoomId As String

    Public Sub New(ByVal ServerURL As String, ByVal Token As String)
        InitializeComponent()
        mServerURL = ServerURL.TrimEnd("/"c)
        mToken = Token
    End Sub

    Private Sub frmMatrixRoomBrowser_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        LoadRooms()
    End Sub

    Private Sub btnRefresh_Click(sender As Object, e As EventArgs) Handles btnRefresh.Click
        LoadRooms()
    End Sub

    Private Sub btnSelect_Click(sender As Object, e As EventArgs) Handles btnSelect.Click
        SelectRoom()
    End Sub

    Private Sub lvRooms_DoubleClick(sender As Object, e As EventArgs) Handles lvRooms.DoubleClick
        SelectRoom()
    End Sub

    Private Sub SelectRoom()
        If lvRooms.SelectedItems.Count = 0 Then
            MessageBox.Show("Please select a room.", "No Selection", MessageBoxButtons.OK, MessageBoxIcon.Information)
            Return
        End If
        SelectedRoomId = lvRooms.SelectedItems(0).SubItems(1).Text
        Me.DialogResult = DialogResult.OK
        Me.Close()
    End Sub

    Private Sub LoadRooms()
        lvRooms.Items.Clear()
        lblStatus.Text = "Loading rooms..."
        btnRefresh.Enabled = False
        Me.Cursor = Cursors.WaitCursor
        Application.DoEvents()

        Try
            ' Step 1: Get joined rooms
            Dim roomsJson As String = MatrixGet("/_matrix/client/v3/joined_rooms")
            Dim ser As New JavaScriptSerializer()
            Dim roomsDict As Dictionary(Of String, Object) = ser.Deserialize(Of Dictionary(Of String, Object))(roomsJson)
            Dim roomIds As ArrayList = CType(roomsDict("joined_rooms"), ArrayList)

            Dim roomCount As Integer = 0

            ' Step 2: For each room, find signal bridge members (one row per room)
            For Each roomId As Object In roomIds
                Dim rid As String = CStr(roomId)
                Try
                    Dim membersJson As String = MatrixGet("/_matrix/client/v3/rooms/" & Uri.EscapeDataString(rid) & "/members?membership=join")
                    Dim membersDict As Dictionary(Of String, Object) = ser.Deserialize(Of Dictionary(Of String, Object))(membersJson)
                    Dim chunks As ArrayList = CType(membersDict("chunk"), ArrayList)

                    ' Collect all signal members in this room
                    Dim signalNames As New List(Of String)
                    For Each chunk As Object In chunks
                        Dim evt As Dictionary(Of String, Object) = CType(chunk, Dictionary(Of String, Object))
                        Dim stateKey As String = If(evt.ContainsKey("state_key"), CStr(evt("state_key")), "")
                        If stateKey.StartsWith("@signal_") Then
                            Dim displayName As String = ""
                            Try
                                Dim profileJson As String = MatrixGet("/_matrix/client/v3/profile/" & Uri.EscapeDataString(stateKey) & "/displayname")
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

                    ' Add one row per room, picking the best display name
                    ' Prefer a real name (no leading +) over a phone number
                    If signalNames.Count > 0 Then
                        Dim bestName As String = signalNames(0)
                        For Each n As String In signalNames
                            If Not n.StartsWith("+") AndAlso Not n.StartsWith("@") Then
                                bestName = n
                                Exit For
                            End If
                        Next
                        Dim item As New ListViewItem(bestName)
                        item.SubItems.Add(rid)
                        lvRooms.Items.Add(item)
                        roomCount += 1
                    End If
                Catch
                    ' Skip rooms we can't read members for
                End Try
            Next

            lblStatus.Text = roomCount & " bridged room(s) found"

        Catch ex As Exception
            lblStatus.Text = "Error: " & ex.Message
        Finally
            btnRefresh.Enabled = True
            Me.Cursor = Cursors.Default
        End Try
    End Sub

    Private Function MatrixGet(ByVal path As String) As String
        Dim url As String = mServerURL & path
        Dim request As HttpWebRequest = CType(WebRequest.Create(url), HttpWebRequest)
        request.Method = "GET"
        request.Headers.Add("Authorization", "Bearer " & mToken)
        request.Timeout = 15000

        Using response As HttpWebResponse = CType(request.GetResponse(), HttpWebResponse)
            Using reader As New StreamReader(response.GetResponseStream(), Encoding.UTF8)
                Return reader.ReadToEnd()
            End Using
        End Using
    End Function

End Class
