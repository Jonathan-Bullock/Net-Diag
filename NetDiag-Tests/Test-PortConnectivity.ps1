function Test-PortConnectivity {
    Update-status -value (Get-Random -Minimum 1 -Maximum 30) -text "Testing Port Connectivity..."
    Write-OutputBox -Text "Port Connectivity Test:" -Color "black"
    #Target Host name, Port number, Display name
    $testTargets = @(
        @{Host="google.com"; Port=80; Name="HTTP"},
        @{Host="google.com"; Port=443; Name="HTTPS"}
    )
    
    foreach ($target in $testTargets) {
        try {
            $testResult = Test-NetConnection -ComputerName $target.Host -Port $target.Port -InformationLevel Quiet -ErrorAction Stop
            if ($testResult) {
                Write-OutputBox -Text " - $($target.Name) ($($target.Host):$($target.Port)): PASSED" -Color "Green"
                $success = $true
            } else {
                Write-OutputBox -Text " - $($target.Name) ($($target.Host):$($target.Port)): Failed" -Color "Red"
                    $success = $false
            }
        } catch {
            Write-OutputBox -Text " - $($target.Name) ($($target.Host):$($target.Port)): FAILED (Error: $_)" -Color "Red"
                $success = $false
        }
    }
    Update-Status -value 100 -text "Port Connectivity Test Complete"
    return $success
}