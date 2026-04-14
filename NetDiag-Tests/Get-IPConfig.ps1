function Get-IPConfig {Write-OutputBox (Ipconfig /all) black}

Get-NetAdapter | Where-Object -Property status -EQ up | format-list * | Out-String