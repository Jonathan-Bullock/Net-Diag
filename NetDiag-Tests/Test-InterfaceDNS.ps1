function Test-DNSServersPerInterface {
    Update-Status -Value 0 -StatusText "Testing DNS Servers per Interface..."
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
    Update-Status -Value 100 -StatusText "DNS Servers Test Complete"
    return $success
}