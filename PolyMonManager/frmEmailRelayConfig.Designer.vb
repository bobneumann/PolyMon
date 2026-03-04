<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class frmEmailRelayConfig
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()> _
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        If disposing AndAlso components IsNot Nothing Then
            components.Dispose()
        End If
        MyBase.Dispose(disposing)
    End Sub

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    <System.Diagnostics.DebuggerStepThrough()> _
    Private Sub InitializeComponent()
        Me.tsToolbar = New System.Windows.Forms.ToolStrip()
        Me.btnSave = New System.Windows.Forms.ToolStripButton()
        Me.btnRefresh = New System.Windows.Forms.ToolStripButton()
        Me.lblApiKeyLabel = New System.Windows.Forms.Label()
        Me.txtApiKey = New System.Windows.Forms.TextBox()
        Me.lblDescription = New System.Windows.Forms.Label()
        Me.txtRelayEmail = New System.Windows.Forms.TextBox()
        Me.gbAvailable = New System.Windows.Forms.GroupBox()
        Me.lvAvailable = New System.Windows.Forms.ListView()
        Me.colAvailContact = CType(New System.Windows.Forms.ColumnHeader(), System.Windows.Forms.ColumnHeader)
        Me.colAvailRoom = CType(New System.Windows.Forms.ColumnHeader(), System.Windows.Forms.ColumnHeader)
        Me.pnlButtons = New System.Windows.Forms.Panel()
        Me.btnAdd = New System.Windows.Forms.Button()
        Me.btnRemove = New System.Windows.Forms.Button()
        Me.gbForwardTo = New System.Windows.Forms.GroupBox()
        Me.lvForwardTo = New System.Windows.Forms.ListView()
        Me.colFwdContact = CType(New System.Windows.Forms.ColumnHeader(), System.Windows.Forms.ColumnHeader)
        Me.colFwdRoom = CType(New System.Windows.Forms.ColumnHeader(), System.Windows.Forms.ColumnHeader)
        Me.lblStatus = New System.Windows.Forms.Label()
        Me.tsToolbar.SuspendLayout()
        Me.gbAvailable.SuspendLayout()
        Me.pnlButtons.SuspendLayout()
        Me.gbForwardTo.SuspendLayout()
        Me.SuspendLayout()
        '
        'tsToolbar
        '
        Me.tsToolbar.GripStyle = System.Windows.Forms.ToolStripGripStyle.Hidden
        Me.tsToolbar.Items.AddRange(New System.Windows.Forms.ToolStripItem() {Me.btnSave, Me.btnRefresh})
        Me.tsToolbar.Location = New System.Drawing.Point(0, 0)
        Me.tsToolbar.Name = "tsToolbar"
        Me.tsToolbar.Size = New System.Drawing.Size(664, 25)
        Me.tsToolbar.TabIndex = 0
        '
        'btnSave
        '
        Me.btnSave.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.ImageAndText
        Me.btnSave.Image = Global.PolyMonManager.My.Resources.Resources.saveHS
        Me.btnSave.ImageTransparentColor = System.Drawing.Color.Magenta
        Me.btnSave.Name = "btnSave"
        Me.btnSave.Size = New System.Drawing.Size(46, 22)
        Me.btnSave.Text = "Save"
        Me.btnSave.ToolTipText = "Save API key and room list to VM"
        '
        'btnRefresh
        '
        Me.btnRefresh.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.ImageAndText
        Me.btnRefresh.Image = Global.PolyMonManager.My.Resources.Resources.Edit_UndoHS
        Me.btnRefresh.ImageTransparentColor = System.Drawing.Color.Magenta
        Me.btnRefresh.Name = "btnRefresh"
        Me.btnRefresh.Size = New System.Drawing.Size(61, 22)
        Me.btnRefresh.Text = "Refresh"
        Me.btnRefresh.ToolTipText = "Reload rooms from Matrix and VM"
        '
        'lblApiKeyLabel
        '
        Me.lblApiKeyLabel.ForeColor = System.Drawing.SystemColors.ControlText
        Me.lblApiKeyLabel.Location = New System.Drawing.Point(12, 34)
        Me.lblApiKeyLabel.Name = "lblApiKeyLabel"
        Me.lblApiKeyLabel.Size = New System.Drawing.Size(90, 20)
        Me.lblApiKeyLabel.TabIndex = 1
        Me.lblApiKeyLabel.Text = "VM API Key:"
        Me.lblApiKeyLabel.TextAlign = System.Drawing.ContentAlignment.MiddleLeft
        '
        'txtApiKey
        '
        Me.txtApiKey.Location = New System.Drawing.Point(108, 34)
        Me.txtApiKey.MaxLength = 255
        Me.txtApiKey.Name = "txtApiKey"
        Me.txtApiKey.Size = New System.Drawing.Size(300, 20)
        Me.txtApiKey.TabIndex = 2
        '
        'lblDescription
        '
        Me.lblDescription.Location = New System.Drawing.Point(12, 60)
        Me.lblDescription.Name = "lblDescription"
        Me.lblDescription.Size = New System.Drawing.Size(360, 20)
        Me.lblDescription.TabIndex = 7
        Me.lblDescription.Text = "Choose which Signal accounts will receive forwarded emails from:"
        Me.lblDescription.TextAlign = System.Drawing.ContentAlignment.MiddleLeft
        '
        'txtRelayEmail
        '
        Me.txtRelayEmail.Location = New System.Drawing.Point(378, 60)
        Me.txtRelayEmail.MaxLength = 255
        Me.txtRelayEmail.Name = "txtRelayEmail"
        Me.txtRelayEmail.Size = New System.Drawing.Size(274, 20)
        Me.txtRelayEmail.TabIndex = 8
        '
        'gbAvailable
        '
        Me.gbAvailable.Anchor = CType(((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom) _
            Or System.Windows.Forms.AnchorStyles.Left), System.Windows.Forms.AnchorStyles)
        Me.gbAvailable.Controls.Add(Me.lvAvailable)
        Me.gbAvailable.ForeColor = System.Drawing.Color.MediumBlue
        Me.gbAvailable.Location = New System.Drawing.Point(12, 88)
        Me.gbAvailable.Name = "gbAvailable"
        Me.gbAvailable.Size = New System.Drawing.Size(270, 280)
        Me.gbAvailable.TabIndex = 3
        Me.gbAvailable.TabStop = False
        Me.gbAvailable.Text = "Available Rooms"
        '
        'lvAvailable
        '
        Me.lvAvailable.Anchor = CType((((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom) _
            Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.lvAvailable.Columns.AddRange(New System.Windows.Forms.ColumnHeader() {Me.colAvailContact, Me.colAvailRoom})
        Me.lvAvailable.FullRowSelect = True
        Me.lvAvailable.GridLines = True
        Me.lvAvailable.HideSelection = False
        Me.lvAvailable.Location = New System.Drawing.Point(6, 20)
        Me.lvAvailable.MultiSelect = False
        Me.lvAvailable.Name = "lvAvailable"
        Me.lvAvailable.Size = New System.Drawing.Size(258, 253)
        Me.lvAvailable.TabIndex = 0
        Me.lvAvailable.UseCompatibleStateImageBehavior = False
        Me.lvAvailable.View = System.Windows.Forms.View.Details
        '
        'colAvailContact
        '
        Me.colAvailContact.Text = "Signal Contact"
        Me.colAvailContact.Width = 140
        '
        'colAvailRoom
        '
        Me.colAvailRoom.Text = "Room ID"
        Me.colAvailRoom.Width = 110
        '
        'pnlButtons
        '
        Me.pnlButtons.Anchor = CType((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom), System.Windows.Forms.AnchorStyles)
        Me.pnlButtons.Controls.Add(Me.btnAdd)
        Me.pnlButtons.Controls.Add(Me.btnRemove)
        Me.pnlButtons.Location = New System.Drawing.Point(290, 88)
        Me.pnlButtons.Name = "pnlButtons"
        Me.pnlButtons.Size = New System.Drawing.Size(74, 280)
        Me.pnlButtons.TabIndex = 4
        '
        'btnAdd
        '
        Me.btnAdd.Location = New System.Drawing.Point(10, 110)
        Me.btnAdd.Name = "btnAdd"
        Me.btnAdd.Size = New System.Drawing.Size(54, 27)
        Me.btnAdd.TabIndex = 0
        Me.btnAdd.Text = ">>"
        Me.btnAdd.UseVisualStyleBackColor = True
        '
        'btnRemove
        '
        Me.btnRemove.Location = New System.Drawing.Point(10, 147)
        Me.btnRemove.Name = "btnRemove"
        Me.btnRemove.Size = New System.Drawing.Size(54, 27)
        Me.btnRemove.TabIndex = 1
        Me.btnRemove.Text = "<<"
        Me.btnRemove.UseVisualStyleBackColor = True
        '
        'gbForwardTo
        '
        Me.gbForwardTo.Anchor = CType((((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom) _
            Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.gbForwardTo.Controls.Add(Me.lvForwardTo)
        Me.gbForwardTo.ForeColor = System.Drawing.Color.MediumBlue
        Me.gbForwardTo.Location = New System.Drawing.Point(372, 88)
        Me.gbForwardTo.Name = "gbForwardTo"
        Me.gbForwardTo.Size = New System.Drawing.Size(278, 280)
        Me.gbForwardTo.TabIndex = 5
        Me.gbForwardTo.TabStop = False
        Me.gbForwardTo.Text = "Forward To"
        '
        'lvForwardTo
        '
        Me.lvForwardTo.Anchor = CType((((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom) _
            Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.lvForwardTo.Columns.AddRange(New System.Windows.Forms.ColumnHeader() {Me.colFwdContact, Me.colFwdRoom})
        Me.lvForwardTo.FullRowSelect = True
        Me.lvForwardTo.GridLines = True
        Me.lvForwardTo.HideSelection = False
        Me.lvForwardTo.Location = New System.Drawing.Point(6, 20)
        Me.lvForwardTo.MultiSelect = False
        Me.lvForwardTo.Name = "lvForwardTo"
        Me.lvForwardTo.Size = New System.Drawing.Size(266, 253)
        Me.lvForwardTo.TabIndex = 0
        Me.lvForwardTo.UseCompatibleStateImageBehavior = False
        Me.lvForwardTo.View = System.Windows.Forms.View.Details
        '
        'colFwdContact
        '
        Me.colFwdContact.Text = "Signal Contact"
        Me.colFwdContact.Width = 140
        '
        'colFwdRoom
        '
        Me.colFwdRoom.Text = "Room ID"
        Me.colFwdRoom.Width = 118
        '
        'lblStatus
        '
        Me.lblStatus.Anchor = CType(((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.lblStatus.Location = New System.Drawing.Point(12, 378)
        Me.lblStatus.Name = "lblStatus"
        Me.lblStatus.Size = New System.Drawing.Size(638, 20)
        Me.lblStatus.TabIndex = 6
        Me.lblStatus.Text = ""
        Me.lblStatus.TextAlign = System.Drawing.ContentAlignment.MiddleLeft
        '
        'frmEmailRelayConfig
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(664, 410)
        Me.Controls.Add(Me.lblStatus)
        Me.Controls.Add(Me.gbForwardTo)
        Me.Controls.Add(Me.pnlButtons)
        Me.Controls.Add(Me.gbAvailable)
        Me.Controls.Add(Me.txtRelayEmail)
        Me.Controls.Add(Me.lblDescription)
        Me.Controls.Add(Me.txtApiKey)
        Me.Controls.Add(Me.lblApiKeyLabel)
        Me.Controls.Add(Me.tsToolbar)
        Me.MaximizeBox = False
        Me.MinimizeBox = False
        Me.MinimumSize = New System.Drawing.Size(600, 404)
        Me.Name = "frmEmailRelayConfig"
        Me.ShowInTaskbar = False
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent
        Me.Text = "Email Relay Room Configuration"
        Me.tsToolbar.ResumeLayout(False)
        Me.tsToolbar.PerformLayout()
        Me.gbAvailable.ResumeLayout(False)
        Me.pnlButtons.ResumeLayout(False)
        Me.gbForwardTo.ResumeLayout(False)
        Me.ResumeLayout(False)
        Me.PerformLayout()

    End Sub
    Friend WithEvents tsToolbar As System.Windows.Forms.ToolStrip
    Friend WithEvents btnSave As System.Windows.Forms.ToolStripButton
    Friend WithEvents btnRefresh As System.Windows.Forms.ToolStripButton
    Friend WithEvents lblApiKeyLabel As System.Windows.Forms.Label
    Friend WithEvents txtApiKey As System.Windows.Forms.TextBox
    Friend WithEvents gbAvailable As System.Windows.Forms.GroupBox
    Friend WithEvents lvAvailable As System.Windows.Forms.ListView
    Friend WithEvents colAvailContact As System.Windows.Forms.ColumnHeader
    Friend WithEvents colAvailRoom As System.Windows.Forms.ColumnHeader
    Friend WithEvents pnlButtons As System.Windows.Forms.Panel
    Friend WithEvents btnAdd As System.Windows.Forms.Button
    Friend WithEvents btnRemove As System.Windows.Forms.Button
    Friend WithEvents gbForwardTo As System.Windows.Forms.GroupBox
    Friend WithEvents lvForwardTo As System.Windows.Forms.ListView
    Friend WithEvents colFwdContact As System.Windows.Forms.ColumnHeader
    Friend WithEvents colFwdRoom As System.Windows.Forms.ColumnHeader
    Friend WithEvents lblStatus As System.Windows.Forms.Label
    Friend WithEvents lblDescription As System.Windows.Forms.Label
    Friend WithEvents txtRelayEmail As System.Windows.Forms.TextBox
End Class
