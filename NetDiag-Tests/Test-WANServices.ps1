    Function Test-WANServices {
    $addresses = @(
        "8.8.8.8",           # Google Public DNS
        "1.1.1.1",           # Cloudflare Public DNS
        "9.9.9.9",           # Quad9 Public DNS
        "208.67.222.222",    # OpenDNS
        "google.com",
        "microsoft.com",
        "amazon.com",
        "apple.com",
        "facebook.com",
        "x.com",             # Formerly twitter.com
        "wikipedia.org",
        "github.com",
        "bing.com",
        "cloudflare.com",
        "pool.ntp.org"
    )

    $results = @() # Initialize an empty array to collect results

    foreach ($originalTarget in $addresses) { # $originalTarget will be "8.8.8.8", "google.com", etc.
        $pingObject = $null
        try {
            $pingObject = New-Object System.Net.NetworkInformation.Ping

            # Use $originalTarget for the ping operation
            $pingReply = $pingObject.Send($originalTarget, 200) # 200ms timeout

            # Add the original target string as a new property to the PingReply object.
            # We'll call it 'TargetHost' to distinguish it from PingReply.Address (which is the responder's IP).
            $pingReply | Add-Member -MemberType NoteProperty -Name "TargetHost" -Value $originalTarget -PassThru

            # Add the modified result to your array
            $results += $pingReply
        }
        finally {
            if ($pingObject -ne $null) {
                $pingObject.Dispose()
            }
        }
    }

    # Display the results, including the new 'TargetHost' column
    $results | Format-Table TargetHost, Status, Address, RoundtripTime -AutoSize
}