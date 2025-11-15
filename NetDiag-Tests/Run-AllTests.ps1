# Create Run All Tests button
$runAllButton = New-Object System.Windows.Forms.Button
$runAllButton.Size = New-Object System.Drawing.Size(130, 35)
$runAllButton.Text = "Run All Tests"
$runAllButton.TextAlign = "MiddleCenter"
$runAllButton.Add_Click({
    Write-OutputBox "=== Running All Tests ===`r`n" "Black"
    Update-Progress 0 "Starting Tests..."
    $results = @()
    $totalTests = $tests.Count
    $completed = 0
    
    foreach ($test in $tests) {
        $result = & $test.Func
        $results += @{Name=$test.Name; Passed=$result}
        $completed++
        Update-Progress ([math]::Round(($completed / $totalTests) * 100)) "Running Tests: $completed of $totalTests complete..."
    }
    
    $summary = "`r`n=== Test Summary ===`r`n"
    foreach ($result in $results) {
        $status = if ($result.Passed) { "PASSED" } else { "FAILED" }
        $summary += "$($result.Name): $status`r`n"
    }
    Write-OutputBox $summary "Black"
    Update-Progress 100 "All Tests Complete"
    $statusLabel.Text = "Status: Idle"
    [System.Windows.Forms.MessageBox]::Show($summary, "Test Results")
})
$buttonPanel.Controls.Add($runAllButton)