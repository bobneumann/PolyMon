<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class PowerShellMonitorEditor
	Inherits PolyMon.MonitorEditors.GenericMonitorEditor

    'UserControl overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()> _
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()> _
    Private Sub InitializeComponent()
		Me.ToolStrip1 = New System.Windows.Forms.ToolStrip
		Me.tbtnUndo = New System.Windows.Forms.ToolStripButton
		Me.tbtnRedo = New System.Windows.Forms.ToolStripButton
		Me.ToolStripSeparator1 = New System.Windows.Forms.ToolStripSeparator
		Me.tcbFontSize = New System.Windows.Forms.ToolStripComboBox
		Me.txtScript = New System.Windows.Forms.RichTextBox
		Me.ToolStrip1.SuspendLayout()
		Me.SuspendLayout()
		'
		'ToolStrip1
		'
		Me.ToolStrip1.Anchor = CType(((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Left) _
					Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
		Me.ToolStrip1.AutoSize = False
		Me.ToolStrip1.Dock = System.Windows.Forms.DockStyle.None
		Me.ToolStrip1.Items.AddRange(New System.Windows.Forms.ToolStripItem() {Me.tbtnUndo, Me.tbtnRedo, Me.ToolStripSeparator1, Me.tcbFontSize})
		Me.ToolStrip1.Location = New System.Drawing.Point(3, 0)
		Me.ToolStrip1.Name = "ToolStrip1"
		Me.ToolStrip1.Size = New System.Drawing.Size(321, 25)
		Me.ToolStrip1.TabIndex = 1
		'
		'tbtnUndo
		'
		Me.tbtnUndo.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Text
		Me.tbtnUndo.Name = "tbtnUndo"
		Me.tbtnUndo.Size = New System.Drawing.Size(40, 22)
		Me.tbtnUndo.Text = "Undo"
		Me.tbtnUndo.ToolTipText = "Undo"
		'
		'tbtnRedo
		'
		Me.tbtnRedo.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Text
		Me.tbtnRedo.Name = "tbtnRedo"
		Me.tbtnRedo.Size = New System.Drawing.Size(38, 22)
		Me.tbtnRedo.Text = "Redo"
		Me.tbtnRedo.ToolTipText = "Redo"
		'
		'ToolStripSeparator1
		'
		Me.ToolStripSeparator1.Name = "ToolStripSeparator1"
		Me.ToolStripSeparator1.Size = New System.Drawing.Size(6, 25)
		'
		'tcbFontSize
		'
		Me.tcbFontSize.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList
		Me.tcbFontSize.Name = "tcbFontSize"
		Me.tcbFontSize.Size = New System.Drawing.Size(75, 25)
		Me.tcbFontSize.ToolTipText = "Select Font Size"
		'
		'txtScript
		'
		Me.txtScript.AcceptsTab = True
		Me.txtScript.Anchor = CType((((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom) _
					Or System.Windows.Forms.AnchorStyles.Left) _
					Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
		Me.txtScript.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle
		Me.txtScript.DetectUrls = False
		Me.txtScript.Font = New System.Drawing.Font("Consolas", 10.0!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
		Me.txtScript.Location = New System.Drawing.Point(3, 28)
		Me.txtScript.Name = "txtScript"
		Me.txtScript.Size = New System.Drawing.Size(321, 155)
		Me.txtScript.TabIndex = 0
		Me.txtScript.Text = ""
		Me.txtScript.WordWrap = False
		'
		'PowerShellMonitorEditor
		'
		Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
		Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
		Me.Controls.Add(Me.txtScript)
		Me.Controls.Add(Me.ToolStrip1)
		Me.Name = "PowerShellMonitorEditor"
		Me.Size = New System.Drawing.Size(327, 186)
		Me.ToolStrip1.ResumeLayout(False)
		Me.ToolStrip1.PerformLayout()
		Me.ResumeLayout(False)

	End Sub
	Friend WithEvents ToolStrip1 As System.Windows.Forms.ToolStrip
	Friend WithEvents tbtnUndo As System.Windows.Forms.ToolStripButton
	Friend WithEvents tbtnRedo As System.Windows.Forms.ToolStripButton
	Friend WithEvents ToolStripSeparator1 As System.Windows.Forms.ToolStripSeparator
	Friend WithEvents tcbFontSize As System.Windows.Forms.ToolStripComboBox
	Friend WithEvents txtScript As System.Windows.Forms.RichTextBox

End Class
