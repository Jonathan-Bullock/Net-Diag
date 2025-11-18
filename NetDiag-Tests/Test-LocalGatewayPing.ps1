#Function only currently works for IPv4 connections

<# Developing Replacement simplified Function with custom ICMP client and continual GUI Update for improved user experiance
function Test-LocalGatewayPing {
     Update-Status -Value 20 -StatusText "Testing Gateway Ping..."
    $gateways = (Get-NetRoute -DestinationPrefix "0.0.0.0/0").NextHop #Use this method to get Gateways since there are cases where devices might have more than one connection. This uses the Default/Primary Route.
    if ($gateways.Count -gt 1){Write-OutputBox -Text "Device has multiple Gateways" -Color "Orange"}
    if($gateways){
    $gateways
        foreach ($gateway in $gateways) {
            (New-Object System.Net.NetworkInformation.Ping).Send($gateway) | Format-Table Status, Address, RoundtripTime
            }
        }       
    else {$result = $false}


    return $results
}


    foreach ($item in $gateways) {
        $pingObject = $null
        try {
            $pingObject = New-Object System.Net.NetworkInformation.Ping
            # Use $item.Target for ping
            ($pingReply = $pingObject.Send($item.Target, 200)) | Out-Null # 200ms timeout 
            Write-OutputBox -text $pingReply -Color "black"
        }
        finally {
            if ($pingObject -ne $null) {
                $pingObject.Dispose()
            }
        }
    }
#>

<#----------------------------------------------------------------------#>
function Test-LocalGatewayPing {
    Update-Status -Value 30 -Text "Testing Local Gateway Ping..."
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
        Update-status -Value (30 + ($processed / $gatewayCount * 10)) -Text "Testing Gateway $processed of $gatewayCount..."
    }
    Write-OutputBox $result $color
    Update-status -value 100 -Text "Local Gateway Test Complete"
    return $success
}
