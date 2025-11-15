    function Test-CloudServices{
    # 1. Define your addresses as an array of custom objects
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

    $results = @() # Initialize an empty array to collect results

    # 2. Loop through the new address structure
    foreach ($item in $addresses) { # Renamed loop variable to $item for clarity
        $pingObject = $null
        try {
            $pingObject = New-Object System.Net.NetworkInformation.Ping

            # Use $item.Target for the ping operation
            $pingReply = $pingObject.Send($item.Target, 200) # 200ms timeout

            # 3. Add the 'Name' from your custom object as a new property to the PingReply object
            #    Use -PassThru to allow piping the modified object
            $pingReply | Add-Member -MemberType NoteProperty -Name "ServerName" -Value $item.Name -PassThru

            # Add the modified result to your array
            $results += $pingReply
        }
        finally {
            if ($pingObject -ne $null) {
                $pingObject.Dispose()
            }
        }
    }

    # 4. Display the results, including the new 'ServerName' column
    $results | Format-Table ServerName, Status, Address, RoundtripTime, @{N='Time (ms)'; E={$_.RoundtripTime}} -AutoSize
}