Public NotInheritable Class frmAboutPolyMon

    Private Sub frmAboutPolyMon_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        ' Set the title of the form.
        Dim ApplicationTitle As String
        If My.Application.Info.Title <> "" Then
            ApplicationTitle = My.Application.Info.Title
        Else
            ApplicationTitle = System.IO.Path.GetFileNameWithoutExtension(My.Application.Info.AssemblyName)
        End If
        Me.Text = String.Format("About {0}", ApplicationTitle)

		Me.LabelVersion.Text = String.Format("Version {0}", My.Application.Info.Version.ToString)
        Me.LabelCopyright.Text = My.Application.Info.Copyright
        Me.LabelCompanyName.Text = My.Application.Info.CompanyName

		Dim sbDescription As New System.Text.StringBuilder
		With sbDescription
			.Append("{\rtf1\ansi\ansicpg1252\deff0\deflang1033{\fonttbl{\f0\fswiss\fcharset0 Arial;}{\f1\fnil\fcharset2 Symbol;}}")
			.Append("{\colortbl ;\red0\green0\blue128;\red0\green128\blue0;}")
			.Append("{\*\generator Msftedit 5.41.15.1507;}\viewkind4\uc1\pard\cf1\b\f0\fs20 PolyMon\cf0\b0  is a distributed monitoring system that provides monitoring, alerting and historical analysis using the .NET framework and Microsoft SQL Server.\par ")
			.Append("\par ")
			.Append("Source code: https://github.com/bobneumann/PolyMon \par ")
			.Append("\par ")
			.Append("\b Acknowledgements\par")
			.Append("\b0 Originally created by Fred Baptiste. Many thanks to:\par")
			.Append("\pard{\pntext\f1\'B7\tab}{\*\pn\pnlvlblt\pnf1\pnindent0{\pntxtb\'B7}}\fi-360\li360\cf2\b ZedGraph \cf0\b0 (http://zedgraph.org) for charting components\par")
			.Append("}")
		End With

		Me.txtDescription.Rtf = sbDescription.ToString()
    End Sub

    Private Sub OKButton_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles OKButton.Click
        Me.Close()
    End Sub

    Private Sub txtDescription_LinkClicked(ByVal sender As Object, ByVal e As System.Windows.Forms.LinkClickedEventArgs) Handles txtDescription.LinkClicked
        System.Diagnostics.Process.Start(e.LinkText)
    End Sub
End Class
