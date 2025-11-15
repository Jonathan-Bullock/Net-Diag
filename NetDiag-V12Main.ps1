# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Network Diagnostics Tool"
$form.Size = New-Object System.Drawing.Size(800, 650)
$form.MinimumSize = New-Object System.Drawing.Size(600, 650)
$form.StartPosition = "CenterScreen"

# Create a progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 15)
$progressBar.Size = New-Object System.Drawing.Size(760, 25)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$progressBar.Anchor = "Top,Left,Right"
$form.Controls.Add($progressBar)

# Create a status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 45)
$statusLabel.Size = New-Object System.Drawing.Size(560, 20)
$statusLabel.Text = "Status: Idle"
$statusLabel.Anchor = "Top,Left,Right"
$form.Controls.Add($statusLabel)

# Create a text output box (using RichTextBox for color coding)
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Location = New-Object System.Drawing.Point(10, 65)
$outputBox.Size = New-Object System.Drawing.Size(760, 300)
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$outputBox.Anchor = "Top,Left,Right,Bottom"
$form.Controls.Add($outputBox)


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
$creditLabel.Text = "Created by: Jonathan Bullock"
$creditLabel.AutoSize = $true
$creditLabel.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - 200), ($form.ClientSize.Height - 20))
$creditLabel.Anchor = "Bottom,Right"
$form.Controls.Add($creditLabel)


<#-------------------Dyanamic Updates-------------------#>
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

Update-Progress -Value 30 -StatusText "Test Status"


Write-OutputBox -Text "Hellow World!" -Color "Blue"

# Network Diagnostic Functions
<#Logic that needs coded for Dependant functions
Should halt tests if physical link is down.
Very least should figure out some precidents to run tests in a specific order so that the first test that fails halts further testing or gives option to continue other tests.
need to make sure to structure tests at most local connection and then  work out from there. I.E. GW ping isn't going to work if physical link is down or there is no DHCP lease
IF GW is down it's not likely that external ping would work since it's not up. Could be that the local Gateway doesn't respond to ping?
#>



#MEthod 1 of dot sourcing
$Path = '.\NetDiag-Tests\'
$Functions = Get-Item -Path "$Path\*.ps1" # Get all .ps1 files in the specified directory
foreach ($Function in $Functions) {
    . "$($Path + $($Function.Name))" # Dot-source each file using the full path
}

#method 2 of Dot Sourcing
$Path = '.\NetDiag-Tests'
$Functions = Get-Item -Path "$Path\*.ps1"
foreach ($Function in $Functions) {
$Function.FullName
    & { . "$($Function.FullName)" } # Runs in a new script block, but functions aren't exported to current scope
}


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










# Show the form
[void]$form.ShowDialog()