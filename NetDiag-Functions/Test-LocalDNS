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
