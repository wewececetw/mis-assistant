$h = @{"X-N8N-API-KEY"="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"; "Content-Type"="application/json"}

Write-Host "Importing V3 with FFmpeg and setting active=true..." -ForegroundColor Cyan

$v3 = Get-Content C:\mis-assistant\workflows\telegram-bot-v3-fixed.json -Raw | ConvertFrom-Json
$v3.active = $true

$body = $v3 | ConvertTo-Json -Depth 20 -Compress

try {
    $result = irm -Method POST http://localhost:5678/api/v1/workflows -Headers $h -Body $body
    Write-Host "[OK] V3 imported!" -ForegroundColor Green
    Write-Host "  ID: $($result.id)"
    Write-Host "  Name: $($result.name)"
    Write-Host "  Active: $($result.active)"
} catch {
    Write-Host "[FAIL] $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)"
}
