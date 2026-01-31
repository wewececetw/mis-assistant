$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"
$headers = @{ "X-N8N-API-KEY" = $apiKey }
$wfs = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows" -Headers $headers
$wfs.data | Where-Object { $_.active -eq $true } | Select-Object id,name,active | Format-Table
