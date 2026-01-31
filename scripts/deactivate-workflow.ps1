param([string]$WorkflowId)
$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"
$headers = @{ "X-N8N-API-KEY" = $apiKey; "Content-Type" = "application/json" }
$wf = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows/$WorkflowId" -Method GET -Headers $headers
$wf.active = $false
$body = $wf | ConvertTo-Json -Depth 20 -Compress
$r = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows/$WorkflowId" -Method PUT -Headers $headers -Body $body
Write-Host "Deactivated: $WorkflowId - active=$($r.active)"
