Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Network Diagnostics Tool"
$form.Size = New-Object System.Drawing.Size(600, 650)
$form.MinimumSize = New-Object System.Drawing.Size(600, 650)
$form.StartPosition = "CenterScreen"

# Create a text output box (using RichTextBox for color coding)
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Location = New-Object System.Drawing.Point(10, 10)
$outputBox.Size = New-Object System.Drawing.Size(560, 300)
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$outputBox.Anchor = "Top,Left,Right,Bottom"
$form.Controls.Add($outputBox)

# Create a progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 320)
$progressBar.Size = New-Object System.Drawing.Size(560, 20)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$progressBar.Anchor = "Top,Left,Right"
$form.Controls.Add($progressBar)

# Create a status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 350)
$statusLabel.Size = New-Object System.Drawing.Size(560, 20)
$statusLabel.Text = "Status: Idle"
$statusLabel.Anchor = "Top,Left,Right"
$form.Controls.Add($statusLabel)

# Create a FlowLayoutPanel for buttons to handle layout dynamically
$buttonPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$buttonPanel.Location = New-Object System.Drawing.Point(10, 380)
$buttonPanel.Size = New-Object System.Drawing.Size(560, 200)
$buttonPanel.FlowDirection = "LeftToRight"
$buttonPanel.WrapContents = $true
$buttonPanel.Anchor = "Top,Left,Right"
$buttonPanel.Padding = New-Object System.Windows.Forms.Padding(5)
$buttonPanel.AutoScroll = $true
$form.Controls.Add($buttonPanel)

# Create a credit label in the lower right corner
$creditLabel = New-Object System.Windows.Forms.Label
$creditLabel.Text = "Coded by Grok and Jonathan Bullock"
$creditLabel.AutoSize = $true
$creditLabel.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - 200), ($form.ClientSize.Height - 20))
$creditLabel.Anchor = "Bottom,Right"
$form.Controls.Add($creditLabel)

# Function to append colored text to output box
function Write-OutputBox {
    param($Text, $Color = "Black")
    $outputBox.SelectionStart = $outputBox.TextLength
    $outputBox.SelectionLength = 0
    $outputBox.SelectionColor = $Color
    $outputBox.AppendText("$Text`r`n")
    $outputBox.SelectionColor = "Black"
    $outputBox.ScrollToCaret()
}

# Function to update progress bar and status
function Update-Progress {
    param($Value, $StatusText)
    $progressBar.Value = $Value
    $statusLabel.Text = "Status: $StatusText"
    $form.Refresh()
}

# Network Diagnostic Functions
<#Logic that needs coded for Dependant functions
Should halt tests if physical link is down.
Very least should figure out some precidents to run tests in a specific order so that the first test that fails halts further testing or gives option to continue other tests.
need to make sure to structure tests at most local connection and then  work out from there. I.E. GW ping isn't going to work if physical link is down or there is no DHCP lease
IF GW is down it's not likely that external ping would work since it's not up. Could be that the local Gateway doesn't respond to ping?
#>


    







# Create buttons for individual tests
$tests = @(
    @{Name="Physical Link"; Func={Test-PhysicalLink}},
    @{Name="Local Gateway Ping"; Func={Test-LocalGatewayPing}},
    @{Name="ISP Gateway Ping"; Func={Test-ISPGatewayPing}},
    @{Name="Local DNS"; Func={Test-LocalDNS}},
    @{Name="Public DNS"; Func={Test-PublicDNS}},
    @{Name="DNS Servers"; Func={Test-DNSServersPerInterface}},
    @{Name="External Ping"; Func={Test-ExternalPing}},
    @{Name="Port Connectivity"; Func={Test-PortConnectivity}}
)

foreach ($test in $tests) {
    $button = New-Object System.Windows.Forms.Button
    $button.Size = New-Object System.Drawing.Size(130, 35)
    $button.Text = $test.Name
    $button.TextAlign = "MiddleCenter"
    $button.Add_Click($test.Func)
    $buttonPanel.Controls.Add($button)
}

# Create Run All Tests button
$runAllButton = New-Object System.Windows.Forms.Button
$runAllButton.Size = New-Object System.Drawing.Size(130, 35)
$runAllButton.Text = "Run All Tests"
$runAllButton.TextAlign = "MiddleCenter"
$runAllButton.Add_Click({
    Write-OutputBox "=== Running All Tests ===`r`n" "Black"
    Update-Progress 0 "Starting Tests..."
    $results = @()
    $totalTests = $tests.Count
    $completed = 0
    
    foreach ($test in $tests) {
        $result = & $test.Func
        $results += @{Name=$test.Name; Passed=$result}
        $completed++
        Update-Progress ([math]::Round(($completed / $totalTests) * 100)) "Running Tests: $completed of $totalTests complete..."
    }
    
    $summary = "`r`n=== Test Summary ===`r`n"
    foreach ($result in $results) {
        $status = if ($result.Passed) { "PASSED" } else { "FAILED" }
        $summary += "$($result.Name): $status`r`n"
    }
    Write-OutputBox $summary "Black"
    Update-Progress 100 "All Tests Complete"
    $statusLabel.Text = "Status: Idle"
    [System.Windows.Forms.MessageBox]::Show($summary, "Test Results")
})
$buttonPanel.Controls.Add($runAllButton)

# Create Clear Output button
$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Size = New-Object System.Drawing.Size(130, 35)
$clearButton.Text = "Clear Output"
$clearButton.TextAlign = "MiddleCenter"
$clearButton.Add_Click({ 
    $outputBox.Clear()
    Update-Progress 0 "Idle"
    $statusLabel.Text = "Status: Idle"
})
$buttonPanel.Controls.Add($clearButton)

# Show the form
[void]$form.ShowDialog()
