Imports System.Xml
Imports System.Text
Public Class PowerShellMonitorEditor
#Region "Private Attributes"
	Private mXMLTemplate As String
#End Region

#Region "Public Interface"
	Public Sub New()
		' This call is required by the Windows Form Designer.
		InitializeComponent()

		' Add any initialization after the InitializeComponent() call.
		InitForm()
	End Sub
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
			Return BuildXMLParams()
		End Get
		Set(ByVal value As String)
			LoadXMLValues(value)
		End Set
	End Property
	Public Overrides Sub LoadTemplateDefaults()
		LoadXMLValues(mXMLTemplate)
	End Sub
#End Region

#Region "Event Handlers"
	Private Sub InitForm()
		With Me.tcbFontSize
			.Items.Clear()
			.Items.Add("8.25 pt")
			.Items.Add("9 pt")
			.Items.Add("10 pt")
			.Items.Add("11 pt")
			.Items.Add("12 pt")
			.Items.Add("14 pt")
			.Items.Add("16 pt")
			.SelectedIndex = 2
		End With
	End Sub
	Private Sub tbtnUndo_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles tbtnUndo.Click
		If txtScript.CanUndo Then
			txtScript.Undo()
		End If
	End Sub
	Private Sub tbtnRedo_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles tbtnRedo.Click
		If txtScript.CanRedo Then
			txtScript.Redo()
		End If
	End Sub
	Private Sub tcbFontSize_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles tcbFontSize.SelectedIndexChanged
		Dim emSize As Single
		Dim FontSize As String
		FontSize = CStr(Me.tcbFontSize.SelectedItem).Trim
		emSize = CSng(FontSize.Substring(0, FontSize.Length - 3))
		Me.txtScript.Font = New System.Drawing.Font("Consolas", emSize, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
	End Sub
#End Region

#Region "Private Methods"
	Private Sub LoadXMLValues(ByVal XML As String)
		'Get default data from XML template (mXMLTemplate)
		Dim XMLDoc As New XmlDocument

		If XML Is Nothing OrElse XML.Trim.Length = 0 Then
			txtScript.Text = Nothing
		Else
			XMLDoc.LoadXml(XML)
			Dim RootNode As XmlNode = XMLDoc.DocumentElement

			Dim XMLNode As XmlNode = Nothing

			'Script
			XMLNode = RootNode.SelectSingleNode("Script")
			If XMLNode Is Nothing OrElse String.IsNullOrEmpty(XMLNode.InnerText) Then
				txtScript.Text = Nothing
			Else
				txtScript.Text = CStr(XMLNode.InnerText)
			End If
			XMLNode = Nothing

		End If
	End Sub
	Private Function BuildXMLParams() As String
		Dim s As New StringBuilder

		s.Append("<PowerShellMonitor>" & vbCrLf)
		s.AppendFormat("<Script>{0}</Script>" & vbCrLf, XMLEncode(Me.txtScript.Text))
		s.Append("</PowerShellMonitor>" & vbCrLf)

		Return s.ToString()
	End Function
	Private Function XMLEncode(ByVal XMLString As String) As String
		If XMLString Is Nothing Then
			Return Nothing
		Else
			Dim tmpStr As String = XMLString

			tmpStr = tmpStr.Replace("&", "&amp;")
			tmpStr = tmpStr.Replace("<", "&lt;")
			tmpStr = tmpStr.Replace(">", "&gt;")
			tmpStr = tmpStr.Replace("""", "&quot;")
			tmpStr = tmpStr.Replace("'", "&apos;")

			Return tmpStr
		End If
	End Function
#End Region
End Class
