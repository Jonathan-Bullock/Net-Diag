function Test-DNSServersPerInterface {
    $success = $false #default Test Results
    Update-Status -Value 15 -StatusText "Testing Loopback DNS Resolution:"
    # Test local NIC DNS resolution
    $interfaces = Get-NetIPConfiguration
    foreach ($interface in $interfaces) {
                $dnsServers = $interface.DNSServer.ServerAddresses
        if ($dnsServers) {
            Write-OutputBox -Color "Black" -Text "Testing DNS for  $($interface.InterfaceAlias)"
            $result += " - Interface $($interface.InterfaceAlias) DNS:`r`n"
            foreach ($dns in $dnsServers) {
                Update-status (Get-Random -Minimum 10 -Maximum 40) "Testing Server: $($dns)"
                Start-Sleep .45 #throttle Requests since there are some cases with multiple interfaces with matching servers you can can hit limits on allowed rates for repeated quaries. (AKA Producer's switch)

                try {
                    $dnsResult = Resolve-DnsName -Name "localhost" -Server $dns -ErrorAction Stop
                    if ($dnsResult) {
                        Write-OutputBox -Color "Green" -Text "   - DNS Server ${dns}: PASSED"
                        $success = $true
                    } else {
                        Write-OutputBox -Color "Red" -Text "   - DNS Server ${dns}: FAILED"
                        $success = $false
                    }
                } catch {
                Write-OutputBox -Color "Red" -Text "   - DNS Server ${dns}: FAILED"
                $success = $false
                }
            }
        }
    }
Update-Status -Value 50 -StatusText "Testing Local Domain Resolution..."    
    # Test AD domain if joined
    try {
        $domain = (Get-WmiObject Win32_ComputerSystem).Domain
        if ($domain -and $domain -ne "WORKGROUP") {
            Write-OutputBox -Color "Black" -Text "This Device is not part of a WORKGROUP. Testing Connection to local Domain Controller:"
            $domainControllers = Resolve-DnsName -Name $domain -Type SRV -ErrorAction SilentlyContinue
            if ($domainControllers) {
                Write-OutputBox -Color "Green" -Text "   - Domain DNS Resolution: PASSED"
                $success = $true
                foreach ($dc in $domainControllers) {
                    if (Test-Connection -ComputerName $dc.NameTarget -Count 2 -Quiet) {
                        Write-OutputBox -Color "Green" -Text "   - DC $($dc.NameTarget): Ping PASSED"
                        $success = $true
                    } else {
                        Write-OutputBox -Color "Red" -Text "   - DC $($dc.NameTarget): Ping FAILED"
                    }
                }
            } else {
                Write-OutputBox -Color "Red" -Text "   - Domain DNS Resolution: FAILED`r`n"
                $success = $false
            }
        } else {
            Write-OutputBox -Color "Green" -Text " - Active Directory Test: SKIPPED (Not domain-joined)"
        }
    } catch {
        Write-OutputBox -Color "Green" -Text " - Active Directory Test: FAILED (Error: $_)"
    }
    Update-status 100 "Local DNS Test Complete"
    return $success
}
