function Test-PhysicalLink { 
Update-Status -Value 0 -StatusText "Testing Physical Link..."
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    if ($adapters){$success = $true
        $tableOutput = $adapters | Format-Table -AutoSize | Out-String
        Write-OutputBox -Text $tableOutput.Trim()
        
        }
    else {$success = $false
            Write-outputbox -text "All Network Interfaces are down" -Color red}

Update-Status -Value 100 -StatusText "Testing Physical Link complete"
        return $success
}
 