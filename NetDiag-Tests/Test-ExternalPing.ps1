
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