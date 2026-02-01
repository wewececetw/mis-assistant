$h = @{"X-N8N-API-KEY"="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"}

Write-Host "=== Cleaning up n8n workflows ===" -ForegroundColor Cyan
Write-Host ""

$all = irm http://localhost:5678/api/v1/workflows -Headers $h
$telegram = $all.data | ?{$_.name -match 'Telegram'}

Write-Host "Found $($telegram.Count) Telegram workflows:"
$telegram | select id,name,active | ft -AutoSize

Write-Host "`nDeleting ALL Telegram workflows..." -ForegroundColor Yellow
foreach ($wf in $telegram) {
    try {
        irm -Method DELETE http://localhost:5678/api/v1/workflows/$($wf.id) -Headers $h | Out-Null
        Write-Host "  [OK] Deleted: $($wf.name)" -ForegroundColor Green
    } catch {
        Write-Host "  [FAIL] $($wf.name): $_" -ForegroundColor Red
    }
}

Write-Host "`n=== Done! ===" -ForegroundColor Green
