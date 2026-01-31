param([string]$ExecId = "34", [string]$NodeName = "Format Summary")
$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"
$headers = @{ "X-N8N-API-KEY" = $apiKey }

$r = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/executions/$ExecId`?includeData=true" -Method GET -Headers $headers
$nodeData = $r.data.resultData.runData.$NodeName[0]
$output = $nodeData.data.main[0] | ConvertTo-Json -Depth 10
Write-Host $output.Substring(0, [Math]::Min(3000, $output.Length))
