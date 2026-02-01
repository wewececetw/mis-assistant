$h = @{"X-N8N-API-KEY"="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"}

Write-Host "=== n8n Cleanup ===" -ForegroundColor Cyan
Write-Host ""

# 1. 列出所有工作流程
Write-Host "Current workflows:" -ForegroundColor Yellow
$all = irm http://localhost:5678/api/v1/workflows -Headers $h
$all.data | select id,name,active | ft -AutoSize

Write-Host "Total: $($all.data.Count) workflows"
Write-Host ""

# 2. 保留的工作流程
$keep = @("Telegram Bot V3")

Write-Host "Deleting workflows (keeping only: $($keep -join ', '))..." -ForegroundColor Yellow
foreach ($wf in $all.data) {
    if ($wf.name -notin $keep) {
        try {
            irm -Method DELETE http://localhost:5678/api/v1/workflows/$($wf.id) -Headers $h | Out-Null
            Write-Host "  [OK] Deleted: $($wf.name)" -ForegroundColor Green
        } catch {
            Write-Host "  [FAIL] $($wf.name)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Final workflows:" -ForegroundColor Cyan
$final = irm http://localhost:5678/api/v1/workflows -Headers $h
$final.data | select id,name,active | ft -AutoSize

Write-Host "=== Done! ===" -ForegroundColor Green
