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