# Import and activate Telegram Bot workflow

$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"
$headers = @{
    "X-N8N-API-KEY" = $apiKey
    "Content-Type" = "application/json"
}

Write-Host "=== Importing Telegram Bot Workflow ==="

# Read workflow
$workflowFile = "C:\mis-assistant\workflows\5-telegram-bot.json"
$workflow = Get-Content $workflowFile -Raw | ConvertFrom-Json

# Check if exists
$existingWfs = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows" -Headers $headers
$existing = $existingWfs.data | Where-Object { $_.name -eq "5. Telegram Bot Command Router" }

if ($existing) {
    Write-Host "Found existing workflow, updating..."
    $workflow.id = $existing.id
    $workflow.active = $true
    $body = $workflow | ConvertTo-Json -Depth 20 -Compress
    $result = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows/$($existing.id)" -Method PUT -Headers $headers -Body $body
    Write-Host "✓ Updated and activated: $($result.name)"
} else {
    Write-Host "Creating new workflow..."
    $workflow.PSObject.Properties.Remove('id')
    $workflow.active = $true
    $body = $workflow | ConvertTo-Json -Depth 20 -Compress
    $result = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows" -Method POST -Headers $headers -Body $body
    Write-Host "✓ Created and activated: $($result.name)"
}

Write-Host ""
Write-Host "=== Workflow Ready! ==="
Write-Host "ID: $($result.id)"
Write-Host "Active: $($result.active)"
Write-Host ""
Write-Host "Test with these commands in Telegram:"
Write-Host "  /start"
Write-Host "  /status"
Write-Host "  /help"
