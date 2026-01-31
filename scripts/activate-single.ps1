param([string]$WorkflowId)
$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"
$headers = @{ "X-N8N-API-KEY" = $apiKey; "Content-Type" = "application/json" }
$body = '{"active": true}'
$r = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows/$WorkflowId/activate" -Method POST -Headers $headers -Body $body
Write-Host "Activated: $WorkflowId - active=$($r.active)"
