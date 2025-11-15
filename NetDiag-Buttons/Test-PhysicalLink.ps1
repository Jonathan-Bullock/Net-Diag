function Test-PhysicalLink {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

    if ($adapters){
        foreach ($adapter in $adapters) {
        $results += $adapter | Format-Table Name, LinkSpeed, MediaType, MacAddress}
        
        }
    else {$results = $false
            Write-Error "All Network Interfaces are down"}

        return $results
 }
