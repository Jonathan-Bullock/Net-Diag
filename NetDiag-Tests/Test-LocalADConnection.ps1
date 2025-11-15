    # Test AD domain if joined
function Test-LocalADConnection {
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
