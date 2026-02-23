Function Write-OutputBox {Write-Output} #Uncomment this line when testing

#check if there is a static Reserved IP
Update-status (Get-Random -Minimum 10 -Maximum 40) "Checking for local Static IP's"
$ManualIPs = (Get-NetIPAddress | where SuffixOrigin -EQ Manual | ft ipaddress -HideTableHeaders | Out-String -Width 250).Trim()
if ($ManualIPs.Length -eq 0) {
    Write-OutputBox -Color "Green" -Text "No Static IP"}
    else{ Write-OutputBox -Color "red" -Text "Static IP"}

  Update-status (Get-Random -Minimum 10 -Maximum 40) "Testing Server: $($dns)"

#check if the DNS Is set static Seperate of DHCP
Update-status (Get-Random -Minimum 30 -Maximum 60) "Checking for local Static DNS: $($ManualIPs)"
function Check-StaticDNS {
    $StaticDNSSearch = (netsh int ip show dnsservers) | Select-String "Statically" | Where-Object { $_.Line -notlike "*None*" }
    if ($StaticDNSSearch -ne $null){
    $results = ($StaticDNSSearch.ToString()).Trim()}
    return $results
}
#Prepend 
$StaticDNS = Check-StaticDNS
$StaticDNS
if (($StaticDNS).Length -ne 0) {
Write-OutputBox -Color "red" -Text "There is Static DNS set."
    }
$udf13
$StaticDNS

