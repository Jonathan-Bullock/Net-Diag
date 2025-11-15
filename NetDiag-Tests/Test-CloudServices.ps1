    function Test-CloudServices{
    $success = $false
    Update-Status -Value 0 -StatusText "Testing Cloud Services..."
    # Addresses array 
        $addresses = @(
        [PSCustomObject]@{Name = "Google Public DNS"; Target = "8.8.8.8"},
        [PSCustomObject]@{Name = "Cloudflare DNS"; Target = "1.1.1.1"},
        [PSCustomObject]@{Name = "Quad9 DNS"; Target = "9.9.9.9"},
        [PSCustomObject]@{Name = "OpenDNS"; Target = "208.67.222.222"},
        [PSCustomObject]@{Name = "Google.com"; Target = "google.com"},
        [PSCustomObject]@{Name = "Microsoft.com"; Target = "microsoft.com"},
        [PSCustomObject]@{Name = "Amazon.com"; Target = "amazon.com"},
        [PSCustomObject]@{Name = "Apple.com"; Target = "apple.com"},
        [PSCustomObject]@{Name = "Facebook.com"; Target = "facebook.com"},
        [PSCustomObject]@{Name = "X.com"; Target = "x.com"},
        [PSCustomObject]@{Name = "Wikipedia.org"; Target = "wikipedia.org"},
        [PSCustomObject]@{Name = "Github.com"; Target = "github.com"},
        [PSCustomObject]@{Name = "Bing.com"; Target = "bing.com"},
        [PSCustomObject]@{Name = "Cloudflare.com"; Target = "cloudflare.com"},
        [PSCustomObject]@{Name = "NTP Pool"; Target = "pool.ntp.org"}
    )
$Success = 0
$Failure = 0
$results = @() # Initialize array
Update-Status -Value 10 -StatusText "Testing Cloud Services..."
    # 2. Loop through address list
    foreach ($item in $addresses) {
        $pingObject = $null
        try {
            $pingObject = New-Object System.Net.NetworkInformation.Ping
            # Use $item.Target for ping
            ($pingReply = $pingObject.Send($item.Target, 200)) | Out-Null # 200ms timeout 
            #Add the 'Name' field as a new property to the PingReply object
           $pingReply | Add-Member -MemberType NoteProperty -Name "ServerName" -Value $item.Name -PassThru | Out-Null
            # Add the modified result to your array
            $results += $pingReply
            if ($pingReply.Status -like "Success") {$Success++}
            else {$Failure++}
        }
        finally {
            if ($pingObject -ne $null) {
                $pingObject.Dispose()
            }
        }
    }
Update-Status -Value 30 -StatusText "Testing Cloud Services..."
#calculate the percentage of failed tests
$FailureRate = $Failure/($Success+$Failure)*100
    # Convert table to string for GUI display (Doesn't work in Terminal)
$tableOutput = $results | Format-Table ServerName, Status, Address, RoundtripTime, @{N='Time (ms)'; E={$_.RoundtripTime}} -AutoSize | Out-String
Write-OutputBox -Text $tableOutput.Trim()
Update-Status -Value 100 -StatusText "Testing Cloud Services..."
if($FailureRate -gt 50){Write-OutputBox -Text "High Failure Rate: $($Failure) of $($Success)" -Color "red"
$success = $false }
if($FailureRate -gt 2){Write-OutputBox -Text "Moderate Failure Rate $($Failure) of $($Success)" -Color "Orange"
$success = $true}
if($FailureRate -lt 2 ){Write-OutputBox -Text "Normal Failure Rate" -Color "Green"
$success = $true}
return $success
}
