cls 
$addapter = Get-NetAdapter 
Write-Host "Interface Information: "
$addapter | Where-Object -Property status -EQ up | format-list Name,MediaConnectionState,MacAddress,LinkSpeed,SystemName,InterfaceDescription | Out-String

Write-Host "Down Interfaces: "
$addapter | Where-Object -Property status -NE up | format-list Name,MacAddress,LinkSpeed,InterfaceDescription | Out-String

Get-NetIPConfiguration | Out-String