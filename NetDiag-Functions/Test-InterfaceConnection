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