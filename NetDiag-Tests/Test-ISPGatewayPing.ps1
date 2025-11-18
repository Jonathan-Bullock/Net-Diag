function Test-ISPGatewayPing {
    Update-Status -Value 0 -StatusText "Testing ISP Gateway WAN IP Ping..."
    Write-OutputBox -Text "Connecting to https://ipinfo.io API to Get WAN IP address" -Color "black"
    try {
        $response = Invoke-WebRequest -Uri "https://ipinfo.io/json" -UseBasicParsing | ConvertFrom-Json
        $wanIP = $response.ip
        $isp = $response.org
        $result = "ISP Gateway Ping Test:`r`n"
        $result += " - WAN IP: ${wanIP}`r`n"
        $result += " - ISP: ${isp}`r`n"
        $color = "Red"
    Write-OutputBox -Text "Trying to Ping $($wanIP)" -Color "black"
        if (Test-Connection -ComputerName $wanIP -Count 2 -Quiet) {
            $result += " - WAN IP Ping: PASSED`r`n"
            $color = "Green"
        } else {
            $result += " - WAN IP Ping: FAILED`r`n"
            $result += "Note: Failed Ping is expected for many business/Enterprise networks since they block this traffic`r`n"
        }
    } catch {
        $result = "ISP Gateway Ping Test: FAILED`r`nError retrieving ISP information: $_`r`n"
        $color = "Red"
    }
    Write-OutputBox $result $color
    Update-Status -Value 100 -StatusText "Testing ISP Gateway Ping..."
    return $result.Contains("PASSED")
}