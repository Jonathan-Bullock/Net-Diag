
#Want to add check if there is a DNS Stitic/static IP address settings since this can impact network settings

#check if there is a static Reserved IP
$udf13 = (Get-NetIPAddress | where SuffixOrigin -EQ Manual | ft ipaddress -HideTableHeaders | Out-String -Width 250).Trim()
if ($udf13.Length -eq 0) {$udf13 = "No Static IP"}

#check if the DNS Is set static Seperate of DHCP
function Check-StaticDNS {
    $StaticDNSSearch = (netsh int ip show dnsservers) | Select-String "Statically" | Where-Object { $_.Line -notlike "*None*" }
    if ($StaticDNSSearch -ne $null){
    $results = ($StaticDNSSearch.ToString()).Trim()}
    return $results
}

#Prepend 
$StaticDNS = Check-StaticDNS
if (($StaticDNS).Length -ne 0) {
    $udf13 = $udf13 + " There is Static DNS set."
    }
$udf13
$StaticDNS

Set-ItemProperty "HKLM:\Software\CentraStage" -Name "Custom13$env:usrUDF13" -Value $udf13