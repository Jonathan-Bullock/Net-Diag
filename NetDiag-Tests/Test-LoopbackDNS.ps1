function Test-LoopbackDNS {
    Update-Status -Value 0 -StatusText "Testing DNS Resolution..."
    Write-OutputBox -Text "Local DNS Resolution Test" -Color "black"
     # Test localhost
    try {
        Update-Status -Value 30 -StatusText "Testing Loopback DNS Resolution:"
        $localHost = [System.Net.Dns]::GetHostByName("localhost")
        if ($localHost) {
            Write-OutputBox -Text " - localhost resolution: PASSED" -Color "Green"    
            $success = $true
        } else {
            $success = $false
            Write-OutputBox -Text " - localhost resolution: Failed" -Color "Red"  
        }
    } catch {
        Write-OutputBox -Text "Uncategorized Status Message: $($localHost)" -Color "Red"  
    }
Update-Status -Value 100 -StatusText "Loop Back DNS Test Complete."
return $success
}