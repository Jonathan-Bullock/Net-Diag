function Test-ISPGatewayPing {
    Update-Progress 50 "Testing ISP Gateway Ping..."
    try {
        $response = Invoke-WebRequest -Uri "https://ipinfo.io/json" -UseBasicParsing | ConvertFrom-Json
        $wanIP = $response.ip
        $isp = $response.org
        $result = "ISP Gateway Ping Test:`r`n"
        $result += " - WAN IP: ${wanIP}`r`n"
        $result += " - ISP: ${isp}`r`n"
        $color = "Red"
        if (Test-Connection -ComputerName $wanIP -Count 2 -Quiet) {
            $result += " - WAN IP Ping: PASSED`r`n"
            $color = "Green"
        } else {
            $result += " - WAN IP Ping: FAILED`r`n"
        }
    } catch {
        $result = "ISP Gateway Ping Test: FAILED`r`nError retrieving ISP information: $_`r`n"
        $color = "Red"
    }
    Write-OutputBox $result $color
    Update-Progress 100 "ISP Gateway Test Complete"
    return $result.Contains("PASSED")
}