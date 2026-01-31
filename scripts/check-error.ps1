$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"
$headers = @{ "X-N8N-API-KEY" = $apiKey }

$r = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/executions" -Method GET -Headers $headers
$latest = $r.data[0]
Write-Host "Workflow: $($latest.workflowId)"
Write-Host "Status: $($latest.status)"
Write-Host "Started: $($latest.startedAt)"

# Get execution detail
$detail = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/executions/$($latest.id)" -Method GET -Headers $headers
$json = $detail | ConvertTo-Json -Depth 10
# Find error info
if ($json -match '"message"\s*:\s*"([^"]*error[^"]*)"') {
    Write-Host "Error: $($matches[1])"
}
Write-Host ""
Write-Host "Full detail (first 2000 chars):"
Write-Host $json.Substring(0, [Math]::Min(2000, $json.Length))
