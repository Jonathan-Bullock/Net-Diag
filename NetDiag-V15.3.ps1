cls
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
$outputBox.Location = New-Object System.Drawing.Point(10, 35)
$outputBox.Size = New-Object System.Drawing.Size(560, 300)
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$outputBox.Anchor = "Top,Left,Right,Bottom"
$form.Controls.Add($outputBox)
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 10)

# Create a progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 345)
$progressBar.Size = New-Object System.Drawing.Size(560, 20)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$progressBar.Anchor = "Bottom, Left, Right"
$form.Controls.Add($progressBar)

# Create a status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 375)
$statusLabel.Size = New-Object System.Drawing.Size(560, 20)
$statusLabel.Text = "Status: Idle"
$statusLabel.Anchor = "Bottom, Left, Right"
$form.Controls.Add($statusLabel)

# Create a FlowLayoutPanel for buttons to handle layout dynamically
$buttonPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$buttonPanel.Location = New-Object System.Drawing.Point(10, 405)
$buttonPanel.Size = New-Object System.Drawing.Size(560, 200)
$buttonPanel.FlowDirection = "LeftToRight"
$buttonPanel.WrapContents = $true
$buttonPanel.Anchor = "Bottom, Left, Right"
$buttonPanel.Padding = New-Object System.Windows.Forms.Padding(5)
$buttonPanel.AutoScroll = $true

$form.Controls.Add($buttonPanel)

# Create a credit label in the lower right corner
$creditLabel = New-Object System.Windows.Forms.Label
$creditLabel.Text = "jo-labs.tech"
$creditLabel.AutoSize = $true
$creditLabel.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - 200), ($form.ClientSize.Height - 20))
$creditLabel.Anchor = "Bottom,Right"
$form.Controls.Add($creditLabel)

# Create a ToolTip object for adding tooltips to controls
$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.AutoPopDelay = 5000  # Time the tooltip remains visible (ms)
$toolTip.InitialDelay = 500   # Time before tooltip appears (ms)
$toolTip.ReshowDelay = 500    # Time before subsequent tooltips appear (ms)
$toolTip.ShowAlways = $true   # Show tooltip even if control is disabled

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



<#-----------------------------------------Menu Bar----------------------------------------#>
# Create the Menu Bar
$menuStrip = New-Object System.Windows.Forms.MenuStrip

# 1. Advanced Menu
$advancedMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$advancedMenu.Text = "&Advanced"

$flushDnsItem = New-Object System.Windows.Forms.ToolStripMenuItem
$flushDnsItem.Text = "Flush DNS Cache"
$flushDnsItem.Add_Click({ 
    ipconfig /flushdns | Out-Null
    Write-OutputBox "DNS Cache Flushed successfully." "Blue"
})

$IPConfig = New-Object System.Windows.Forms.ToolStripMenuItem
$IPConfig.Text = "IP Configuration"
$IPConfig.Add_Click({ 
    Get-IPConfig
})

$advancedMenu.DropDownItems.Add($flushDnsItem)
$advancedMenu.DropDownItems.Add($IPConfig)

# 2. Credits Menu
$creditsMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$creditsMenu.Text = "&Credits"
$creditsMenu.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("NetDiag `nDeveloped by Jo-Labs`nWeb: jo-labs.tech `n `nWAN IP Resolution by ipinfo.io", "About NetDiag")
})

# 3. Donations Menu
$donationsMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$donationsMenu.Text = "&Donations"
$donationsMenu.Add_Click({
    # You can point this to a URL later
    [System.Windows.Forms.MessageBox]::Show("Support for Jo-Labs is appreciated! Link coming soon.", "Donations")
})

# Add items to the strip and the strip to the form
$menuStrip.Items.Add($advancedMenu) | Out-Null
$menuStrip.Items.Add($creditsMenu) | Out-Null
$menuStrip.Items.Add($donationsMenu) | Out-Null
$form.MainMenuStrip = $menuStrip
$form.Controls.Add($menuStrip)

<#-----------------------------------------Individual Tests----------------------------------------#>

# Network Diagnostic Functions
function Test-PhysicalLink {
    Update-Progress 10 "Testing Physical Links..."
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    $result = "Physical Link Test:`r`n"
    $connected = $false
    $color = "Red"
    
    if ($adapters) {
        $result += "Connected Adapters:`r`n"
        foreach ($adapter in $adapters) {
            $result += " - $($adapter.Name): $($adapter.Status)`r`n"
            $result += " - MAC: $($adapter.MacAddress)`r`n"
            $result += " - Link Speed: $($adapter.LinkSpeed)`r`n"
            #if Wi-fi show signal strength
            if ($adapter.Name -eq "Wi-Fi"){
                $SignalStrength = ((netsh wlan show interfaces) -Match '^\s+Signal' -Replace '^\s+Signal\s+:\s+','') | Out-String
                $result += " - Signal Strength: $($SignalStrength)"
                }


            $connected = $true
        


            $color = "Green"
            
        }
    } else {
        $result += "No connected adapters found.`r`n"
    }
    Write-OutputBox $result $color
    Update-Progress 100 "Physical Link Test Complete"
    return $connected
}

function Test-LocalGatewayPing {
    Update-Progress 30 "Testing Local Gateway Ping..."
    $physicalConnected = Test-PhysicalLink
    if (-not $physicalConnected) {
        $result = "Local Gateway Ping Test: SKIPPED`r`n - Reason: Physical link is disconnected.`r`n"
        Write-OutputBox $result "Black"
        Update-Progress 100 "Local Gateway Test Skipped"
        return $false
    }
    
    $gateways = (Get-NetRoute -DestinationPrefix "0.0.0.0/0").NextHop
    $result = "Local Gateway Ping Test:`r`n"
    $success = $false
    $color = "Red"
    
    $gatewayCount = $gateways.Count
    $processed = 0
    foreach ($gateway in $gateways) {
        if ($gateway -and (Test-Connection -ComputerName $gateway -Count 2 -Quiet)) {
            $result += " - Gateway ${gateway}: PASSED`r`n"
            $success = $true
            $color = "Green"
        } else {
            $result += " - Gateway ${gateway}: FAILED`r`n"
        }
        $processed++
        Update-Progress (30 + ($processed / $gatewayCount * 10)) "Testing Gateway $processed of $gatewayCount..."
    }
    Write-OutputBox $result $color
    Update-Progress 100 "Local Gateway Test Complete"
    return $success
}

function Test-ISPGatewayPing {
    Update-Progress -Value 0 -StatusText "Testing ISP Gateway WAN IP Ping..."
    Write-OutputBox -Text "Connecting to https://ipinfo.io API to Get WAN IP address" -Color "black"
    try {
        $response = Invoke-WebRequest -Uri "https://ipinfo.io/json" -UseBasicParsing | ConvertFrom-Json
        $wanIP = $response.ip
        $isp = $response.org
        Write-OutputBox "ISP Gateway Ping Test:" Black
        Write-OutputBox " - WAN IP: ${wanIP}" Black
        Write-OutputBox " - ISP: ${isp}" Black
        $color = "Yellow"
    Write-OutputBox -Text "Trying to Ping $($wanIP)" -Color "black"
        if (Test-Connection -ComputerName $wanIP -Count 2 -Quiet) {
            $result += " - WAN IP Ping: PASSED`r`n"
            $color = "Green"
        } else {
            $result += " - WAN IP Ping: FAILED`r`n"
            $result += "Note: Failed Ping is expected for many business/Enterprise networks since they block this traffic`r`n"
        }
    } catch {
        $result = "ISP Gateway Ping Test: FAILED`r`nError retrieving ISP information: $_`r`n"
        $color = "Red"
    }
    Write-OutputBox $result $color
    Update-Progress -Value 100 -StatusText "Testing ISP Gateway Ping..."
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
    $interfaces = Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -ne "Disconnected" }
    
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

function Get-IPConfig {
$addapter = Get-NetAdapter 
    Write-OutputBox "=== Down Interfaces ===" "Red"
    $downAdapters = $addapter | Where-Object -Property status -NE up | Format-Table Name,MacAddress,LinkSpeed,InterfaceDescription | Out-String
    Write-OutputBox $downAdapters "Black"

    Write-OutputBox "=== Up Interfaces ===" "Green"
    $upAdapters = $addapter | Where-Object -Property status -EQ up | Format-List Name,MediaConnectionState,MacAddress,LinkSpeed,SystemName,InterfaceDescription | Out-String
    Write-OutputBox $upAdapters "Black"
    
    Write-OutputBox "=== IP Configuration ===" "Blue"
    $ipConfig = Get-NetIPConfiguration | Out-String
    Write-OutputBox $ipConfig "Black"
    
}
    
function Test-CloudServices{
    $success = $false
    Update-progress -Value 0 -StatusText "Testing Cloud Services..."
    # Addresses array 
        $addresses = @(
        [PSCustomObject]@{Name = "Google Public DNS"; Target = "8.8.8.8"},
        [PSCustomObject]@{Name = "Cloudflare DNS"; Target = "1.1.1.1"},
        [PSCustomObject]@{Name = "Quad9 DNS"; Target = "9.9.9.9"},
        [PSCustomObject]@{Name = "OpenDNS"; Target = "208.67.222.222"},
        [PSCustomObject]@{Name = "Google.com"; Target = "google.com"},
        [PSCustomObject]@{Name = "Microsoft.com"; Target = "microsoft.com"},
        [PSCustomObject]@{Name = "Amazon.com"; Target = "amazon.com"},
        [PSCustomObject]@{Name = "Apple.com"; Target = "apple.com"},
        [PSCustomObject]@{Name = "Facebook.com"; Target = "facebook.com"},
        [PSCustomObject]@{Name = "X.com"; Target = "x.com"},
        [PSCustomObject]@{Name = "Wikipedia.org"; Target = "wikipedia.org"},
        [PSCustomObject]@{Name = "Github.com"; Target = "github.com"},
        [PSCustomObject]@{Name = "Bing.com"; Target = "bing.com"},
        [PSCustomObject]@{Name = "Cloudflare.com"; Target = "cloudflare.com"},
        [PSCustomObject]@{Name = "NTP Pool"; Target = "pool.ntp.org"}
    )
$Success = 0
$Failure = 0
$results = @() # Initialize array
Update-progress -Value 10 -StatusText "Testing Cloud Services..."
    # 2. Loop through address list
    foreach ($item in $addresses) {
        $pingObject = $null
        try {
            $pingObject = New-Object System.Net.NetworkInformation.Ping
            # Use $item.Target for ping
            ($pingReply = $pingObject.Send($item.Target, 200)) | Out-Null # 200ms timeout 
            #Add the 'Name' field as a new property to the PingReply object
           $pingReply | Add-Member -MemberType NoteProperty -Name "ServerName" -Value $item.Name -PassThru | Out-Null
            # Add the modified result to your array
            $results += $pingReply
            if ($pingReply.Status -like "Success") {$Success++}
            else {$Failure++}
        }
        finally {
            if ($pingObject -ne $null) {
                $pingObject.Dispose()
            }
        }
    }
Update-progress -Value 30 -StatusText "Testing Cloud Services..."
#calculate the percentage of failed tests
$FailureRate = $Failure/($Success+$Failure)*100
    # Convert table to string for GUI display (Doesn't work in Terminal)
$tableOutput = $results | Format-Table ServerName, Status, Address, RoundtripTime, @{N='Time (ms)'; E={$_.RoundtripTime}} -AutoSize | Out-String
Write-OutputBox -Text $tableOutput.Trim()
Update-progress -Value 100 -StatusText "Testing Cloud Services..."
if($FailureRate -gt 50){Write-OutputBox -Text "High Failure Rate: $($Failure) of $($Success)" -Color "red"
$success = $false }
if($FailureRate -gt 2){Write-OutputBox -Text "Moderate Failure Rate $($Failure) of $($Success)" -Color "Orange"
$success = $true}
if($FailureRate -lt 2 ){Write-OutputBox -Text "Normal Failure Rate" -Color "Green"
$success = $true}
return $success
}


<#-----------------------------------------Grouped Function Tests----------------------------------------#>
function Test-DNS {
Test-DNSServersPerInterface 
Test-LocalDNS
Test-DNSServersPerInterface}

function Test-GateWay {
Test-LocalGatewayPing
Test-ISPGatewayPing
<# Contemplating adding these tests to this group
Test-LocalDNS
Test-DNSServersPerInterface
#>
}


function External-Tests {
Test-ExternalPing
Test-PortConnectivity
Test-CloudServices

}
# Create buttons for individual tests
$tests = @(
    @{Name="Physical Link"; Func={Test-PhysicalLink}; Description="Checks if the network adapter has a physical connection or that Wi-Fi radio has a data layer link"},
    @{Name="DNS"; Func={Test-DNS}; Description="Runs all local and interface DNS resolution tests."},
    @{Name="GateWay"; Func={Test-GateWay}; Description="Pings the local gateway and ISP gateway to verify routing."},
    @{Name="External"; Func={External-Tests}; Description="Tests external ping and port connectivity to public servers."}
)

foreach ($test in $tests) {
    $button = New-Object System.Windows.Forms.Button
    $button.Size = New-Object System.Drawing.Size(130, 35)
    $button.Text = $test.Name
    $button.TextAlign = "MiddleCenter"
    $button.Add_Click($test.Func)
    $buttonPanel.Controls.Add($button)
    $toolTip.SetToolTip($button, $test.Description)
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
