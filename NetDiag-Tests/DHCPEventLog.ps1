$events = Get-WinEvent -FilterHashtable @{
    ProviderName = 'Microsoft-Windows-Dhcp-Client'
    #ID = 1000,1001,1002,1003
    Level = 1,2
    StartTime = (Get-Date).AddDays(-3)
} -ErrorAction SilentlyContinue

write-host '<-Start Result->' 
$events | Select-Object -First 1 | fl TimeCreated, message | Out-String
write-host '<-End Result->' 

if ($events.Count -gt 0){
    #return Error Status
    $exitcode = 1}
else{#return Good Status
    $exitcode = 0}

Write-host "status Code: $($exitcode)"


#exit $exitcode #Comment this line for testing