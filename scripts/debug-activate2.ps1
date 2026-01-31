$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"
$headers = @{ "X-N8N-API-KEY" = $apiKey }

# Get workflow details
$wf = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows/docker-monitor-workflow" -Method GET -Headers $headers
$json = $wf | ConvertTo-Json -Depth 20
Write-Host $json.Substring(0, [Math]::Min(3000, $json.Length))
