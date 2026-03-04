Namespace My
    Partial Friend Class MyApplication
        Private Sub MyApplication_StartupNextInstance(sender As Object, e As Microsoft.VisualBasic.ApplicationServices.StartupNextInstanceEventArgs) Handles Me.StartupNextInstance
            ' User clicked the shortcut while app is already running (hidden in tray).
            ' Restore the main window.
            Dim main As frmMain = CType(Me.MainForm, frmMain)
            main.RestoreFromTray()
        End Sub
    End Class
End Namespace
