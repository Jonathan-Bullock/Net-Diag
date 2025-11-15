# Create Clear Output button
$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Size = New-Object System.Drawing.Size(130, 35)
$clearButton.Text = "Clear Output"
$clearButton.TextAlign = "MiddleCenter"
$clearButton.Add_Click({ 
    $outputBox.Clear()
    Update-Status -Value 0 -StatusText "Idle"
    $statusLabel.Text = "Status: Idle"
})
$buttonPanel.Controls.Add($clearButton)
