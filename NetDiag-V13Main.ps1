Set-Location "C:\GitRepo\Net-Diag\Net-Diag" #used for testing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Network Diagnostics Tool"
$form.Size = New-Object System.Drawing.Size(800, 650)
$form.MinimumSize = New-Object System.Drawing.Size(600, 650)
$form.StartPosition = "CenterScreen"

# Create a ToolTip object for adding tooltips to controls
$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.AutoPopDelay = 5000  # Time the tooltip remains visible (ms)
$toolTip.InitialDelay = 500   # Time before tooltip appears (ms)
$toolTip.ReshowDelay = 500    # Time before subsequent tooltips appear (ms)
$toolTip.ShowAlways = $true   # Show tooltip even if control is disabled

# Create a progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 15)
$progressBar.Size = New-Object System.Drawing.Size(760, 25)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$progressBar.Anchor = "Top,Left,Right"
$form.Controls.Add($progressBar)
$toolTip.SetToolTip($progressBar, "Shows the progress of the current test.")

# Create a status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 45)
$statusLabel.Size = New-Object System.Drawing.Size(560, 20)
$statusLabel.Text = "Status: Idle"
$statusLabel.Anchor = "Top,Left,Right"
$form.Controls.Add($statusLabel)
$toolTip.SetToolTip($statusLabel, "Displays the current status of the tool.")

# Create a text output box (using RichTextBox for color coding)
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Location = New-Object System.Drawing.Point(10, 65)
$outputBox.Size = New-Object System.Drawing.Size(760, 300)
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$outputBox.Anchor = "Top,Left,Right,Bottom"
$form.Controls.Add($outputBox)
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 10) #Needed to make tables columns to allign
$toolTip.SetToolTip($outputBox, "Displays detailed output from network tests. Use color coding for results.")

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
$toolTip.SetToolTip($creditLabel, "Credits to the tool's creator.")

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
function Update-Status {
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

Update-Status -Value 0 -StatusText "Loading Functions..."
Write-OutputBox -Text "Loading Test Functions..." -Color "Blue"

#MEthod 1 of dot sourcing
$Path = '.\NetDiag-Tests\'
$Functions = Get-Item -Path "$Path\*.ps1" # Get all .ps1 files in the specified directory
foreach ($Function in $Functions) {
    $Function.FullName #Used for Diagnostic to show full file path of the called function
    . "$($Path + $($Function.Name))" # Dot-source each file using the full path
}

$outputBox.Clear()
Update-Status -Value 100 -StatusText "Ready"
Write-OutputBox -Text "Select Test to run." -Color "Blue"

<# Create buttons for individual tests
$tests = @() #initualize perameter list for test functions
$tests = @(
    foreach ($Function in $Functions) {
        @{Name=$Function; Func={$Function}}
    }
)#>

# Create buttons for individual tests
$tests = @(
    @{Name="Physical Link"; Func={Test-PhysicalLink}; Description="Checks if the network adapter has a physical connection or that Wi-Fi radio has a data layer link"},
    @{Name="Local Gateway Ping"; Func={Test-LocalGatewayPing}; Description="Pings the local gateway to verify connection."},
    @{Name="ISP Gateway Ping"; Func={Test-ISPGatewayPing}; Description="Pings the ISP gateway to verify your WAN IP address is accessible."},
    @{Name="Loop Back DNS"; Func={Test-LoopbackDNS}; Description="Tests DNS resolution using loopback address. `n `n IF this doesn't work it's a good indication that there is issue with services on the local machine."},
    @{Name="Public DNS"; Func={Test-PublicDNS}; Description="Tests connectivity to public DNS servers. `n `n NOTE: This is different from Interface DNS and uses common WAN DNS Servers since this is likely differant than what is set by your network administrator. `n should be paired with Cloud services Ping to issolate if it's a network routing or DNS Resolution issue."},
    @{Name="All Interface DNS"; Func={Test-DNSServersPerInterface}; Description="Checks DNS servers for all network interfaces. `n `n Collects DNS Servers from all interfaces regardless if they were set static or via DHCP or if they are a loop back address to make sure there aren't and DNS Timeouts."},
    @{Name="External Ping"; Func={Test-ExternalPing}; Description="Pings external Google and Cloudflare DNS Servers which are reputable open global DNS Providers `n `n If this works and Public DNS Fails your computer may not be able to resolve DNS. But if Both fail there's an issue with your data connection."},
    @{Name="Cloud Services"; Func={Test-CloudServices}; Description="Tests ping connectivity to common cloud services. `n `n Hope to add other services besides ping since some cloud services periodically decide not to respond to this protocal"},
    @{Name="TCP Port Check"; Func={Test-PortConnectivity}; Description="Checks if Google.com is reachable using port 443 and 80"}
)

foreach ($test in $tests) {
    $button = New-Object System.Windows.Forms.Button
    $button.Size = New-Object System.Drawing.Size(130, 35)
    $button.Text = $test.Name
    $button.TextAlign = "MiddleCenter"
    $button.Add_Click($test.Func)
    $buttonPanel.Controls.Add($button)
    $toolTip.SetToolTip($button, $test.Description)  # Set tooltip for this button
}

# Show the form
[void]$form.ShowDialog()