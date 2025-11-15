#Function only currently works for IPv4 connections
function Test-LocalGatewayPing {
    $gateways = (Get-NetRoute -DestinationPrefix "0.0.0.0/0").NextHop #Use this method to get Gateways since there are cases where devices might have more than one connection
    if ($gateways.Count -gt 1){Write-Warning "Device has multiple Gateways"}
    if($gateways){
    $gateways
        foreach ($gateway in $gateways) {
            (New-Object System.Net.NetworkInformation.Ping).Send($gateway) | ft Status, Address, RoundtripTime
            }
        }       
    else {$result = $false}


    return $results
}


<#----------------------------------------------------------------------#>
function Test-LocalGatewayPing {
    Update-Progress 30 "Testing Local Gateway Ping..."
    <# Commenting out this test for the time being since this test write out when it's ran and I want to keep flow structure simple for the time being.
                $physicalConnected = Test-PhysicalLink
                if (-not $physicalConnected) {
                    $result = "Local Gateway Ping Test: SKIPPED`r`n - Reason: Physical link is disconnected.`r`n"
                    Write-OutputBox $result "Black"
                    Update-Progress 100 "Local Gateway Test Skipped"
                    return $false
                }
    #>
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