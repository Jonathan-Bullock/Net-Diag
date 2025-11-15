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
