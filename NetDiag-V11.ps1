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

function Test-ISPGatewayPing {
    Update-Progress 50 "Testing ISP Gateway Ping..."
    try {
        $response = Invoke-WebRequest -Uri "https://ipinfo.io/json" -UseBasicParsing | ConvertFrom-Json
        $wanIP = $response.ip
        $isp = $response.org
        $result = "ISP Gateway Ping Test:`r`n"
        $result += " - WAN IP: ${wanIP}`r`n"
        $result += " - ISP: ${isp}`r`n"
        $color = "Red"
        if (Test-Connection -ComputerName $wanIP -Count 2 -Quiet) {
            $result += " - WAN IP Ping: PASSED`r`n"
            $color = "Green"
        } else {
            $result += " - WAN IP Ping: FAILED`r`n"
        }
    } catch {
        $result = "ISP Gateway Ping Test: FAILED`r`nError retrieving ISP information: $_`r`n"
        $color = "Red"
    }
    Write-OutputBox $result $color
    Update-Progress 100 "ISP Gateway Test Complete"
    return $result.Contains("PASSED")
}

function Test-LocalDNS {
    Update-Progress 70 "Testing Local DNS Resolution..."
    $result = "Local DNS Resolution Test:`r`n"
    $success = $false
    $color = "Red"
    
    # Test localhost
    try {
        $localHost = [System.Net.Dns]::GetHostByName("localhost")
        if ($localHost) {
            $result += " - localhost resolution: PASSED`r`n"
            $success = $true
            $color = "Green"
        } else {
            $result += " - localhost resolution: FAILED`r`n"
        }
    } catch {
        $result += " - localhost resolution: FAILED`r`nError: $_`r`n"
    }
    
    # Test local NIC DNS resolution
    $interfaces = Get-NetIPConfiguration
    foreach ($interface in $interfaces) {
        $dnsServers = $interface.DNSServer.ServerAddresses
        if ($dnsServers) {
            $result += " - Interface $($interface.InterfaceAlias) DNS:`r`n"
            foreach ($dns in $dnsServers) {
                try {
                    $dnsResult = Resolve-DnsName -Name "localhost" -Server $dns -ErrorAction Stop
                    if ($dnsResult) {
                        $result += "   - DNS Server ${dns}: PASSED`r`n"
                        $success = $true
                        $color = "Green"
                    } else {
                        $result += "   - DNS Server ${dns}: FAILED`r`n"
                    }
                } catch {
                    $result += "   - DNS Server ${dns}: FAILED (Error: $_)`r`n"
                }
            }
        }
    }
    
    # Test AD domain if joined
    try {
        $domain = (Get-WmiObject Win32_ComputerSystem).Domain
        if ($domain -and $domain -ne "WORKGROUP") {
            $result += " - Active Directory Domain Test ($domain):`r`n"
            $domainControllers = Resolve-DnsName -Name $domain -Type SRV -ErrorAction SilentlyContinue
            if ($domainControllers) {
                $result += "   - Domain DNS Resolution: PASSED`r`n"
                $success = $true
                $color = "Green"
                foreach ($dc in $domainControllers) {
                    if (Test-Connection -ComputerName $dc.NameTarget -Count 2 -Quiet) {
                        $result += "   - DC $($dc.NameTarget): Ping PASSED`r`n"
                    } else {
                        $result += "   - DC $($dc.NameTarget): Ping FAILED`r`n"
                    }
                }
            } else {
                $result += "   - Domain DNS Resolution: FAILED`r`n"
            }
        } else {
            $result += " - Active Directory Test: SKIPPED (Not domain-joined)`r`n"
            $color = if ($success) { "Green" } else { "Blue" }
        }
    } catch {
        $result += " - Active Directory Test: FAILED (Error: $_)`r`n"
    }
    
    Write-OutputBox $result $color
    Update-Progress 100 "Local DNS Test Complete"
    return $success
}

function Test-PublicDNS {
    Update-Progress 85 "Testing Public DNS Resolution..."
    $result = "Public DNS Resolution Test:`r`n"
    $success = $false
    $color = "Red"
    $testDomains = @("google.com", "cloudflare.com")
    
    # Test with default system DNS
    foreach ($domain in $testDomains) {
        try {
            $dnsResult = [System.Net.Dns]::GetHostAddresses($domain)
            if ($dnsResult) {
                $result += " - ${domain} resolution (System DNS): PASSED`r`n"
                $success = $true
                $color = "Green"
            } else {
                $result += " - ${domain} resolution (System DNS): FAILED`r`n"
            }
        } catch {
            $result += " - ${domain} resolution (System DNS): FAILED`r`nError: $_`r`n"
        }
    }
    
    # Test with Google and Cloudflare DNS servers
    $publicDnsServers = @("8.8.8.8", "1.1.1.1")
    foreach ($server in $publicDnsServers) {
        foreach ($domain in $testDomains) {
            try {
                $dnsResult = Resolve-DnsName -Name $domain -Server $server -ErrorAction Stop
                if ($dnsResult) {
                    $result += " - ${domain} resolution (DNS ${server}): PASSED`r`n"
                    $success = $true
                    $color = "Green"
                } else {
                    $result += " - ${domain} resolution (DNS ${server}): FAILED`r`n"
                }
            } catch {
                $result += " - ${domain} resolution (DNS ${server}): FAILED (Error: $_)`r`n"
            }
        }
    }
    
    # Test for DNS hijacking with fake DNS server
    $fakeServer = "5.5.5.5"
    $validHost = "google.com"
    $result += " - DNS Hijacking Test (Fake Server ${fakeServer}):`r`n"
    try {
        Resolve-DnsName -Server $fakeServer -QuickTimeout -DnsOnly -Name $validHost -ErrorAction Stop
        $result += "   - DNS Hijacking DETECTED (e.g., Xfinity SecurityEdge or similar)`r`n"
        $color = "Red"
    } catch [System.ComponentModel.Win32Exception] {
        if ($_.FullyQualifiedErrorId -and $_.FullyQualifiedErrorId.StartsWith("ERROR_TIMEOUT")) {
            $result += "   - DNS Hijacking NOT detected: PASSED`r`n"
            $success = $true
            $color = if ($success) { "Green" } else { "Red" }
        } else {
            $result += "   - Error: $($_.FullyQualifiedErrorId)`r`n"
        }
    } catch {
        $result += "   - Unknown error during hijacking test: $($_.Exception.GetType().FullName)`r`n"
    }
    
    Write-OutputBox $result $color
    Update-Progress 100 "Public DNS Test Complete"
    return $success
}

function Test-ExternalPing {
    Update-Progress 95 "Testing External Ping..."
    $result = "External Ping Test:`r`n"
    $success = $false
    $color = "Red"
    $testTargets = @("8.8.8.8", "1.1.1.1") # Google and Cloudflare public DNS servers
    
    foreach ($target in $testTargets) {
        if (Test-Connection -ComputerName $target -Count 2 -Quiet) {
            $result += " - Target ${target}: PASSED`r`n"
            $success = $true
            $color = "Green"
        } else {
            $result += " - Target ${target}: FAILED`r`n"
        }
    }
    Write-OutputBox $result $color
    Update-Progress 100 "External Ping Test Complete"
    return $success
}

function Test-DNSServersPerInterface {
    Update-Progress 25 "Testing DNS Servers per Interface..."
    $result = "DNS Servers Test per Interface:`r`n"
    $success = $false
    $color = "Red"
    $interfaces = Get-NetIPConfiguration
    
    foreach ($interface in $interfaces) {
        $result += "Interface: $($interface.InterfaceAlias)`r`n"
        $dnsServers = $interface.DNSServer.ServerAddresses
        if ($dnsServers) {
            foreach ($server in $dnsServers) {
                if (Test-Connection -ComputerName $server -Count 2 -Quiet) {
                    $result += " - DNS Server ${server}: PASSED`r`n"
                    $success = $true
                    $color = "Green"
                } else {
                    $result += " - DNS Server ${server}: FAILED`r`n"
                }
            }
        } else {
            $result += " - No DNS Servers configured`r`n"
            $color = "Black"
        }
        $result += "`r`n"
    }
    Write-OutputBox $result $color
    Update-Progress 100 "DNS Servers Test Complete"
    return $success
}

function Test-PortConnectivity {
    Update-Progress 90 "Testing Port Connectivity..."
    $result = "Port Connectivity Test:`r`n"
    $success = $false
    $color = "Red"
    $testTargets = @(
        @{Host="google.com"; Port=80; Name="HTTP"},
        @{Host="google.com"; Port=443; Name="HTTPS"}
    )
    
    foreach ($target in $testTargets) {
        try {
            $testResult = Test-NetConnection -ComputerName $target.Host -Port $target.Port -InformationLevel Quiet -ErrorAction Stop
            if ($testResult) {
                $result += " - $($target.Name) ($($target.Host):$($target.Port)): PASSED`r`n"
                $success = $true
                $color = "Green"
            } else {
                $result += " - $($target.Name) ($($target.Host):$($target.Port)): FAILED`r`n"
            }
        } catch {
            $result += " - $($target.Name) ($($target.Host):$($target.Port)): FAILED (Error: $_)`r`n"
        }
    }
    Write-OutputBox $result $color
    Update-Progress 100 "Port Connectivity Test Complete"
    return $success
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
