param([string]$ExecId = "34")
$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"
$headers = @{ "X-N8N-API-KEY" = $apiKey }

$r = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/executions/$ExecId`?includeData=true" -Method GET -Headers $headers

# Check for top-level error
if ($r.data.resultData.error) {
    Write-Host "TOP ERROR: $($r.data.resultData.error.message)"
    Write-Host "Context: $($r.data.resultData.error.context | ConvertTo-Json -Depth 5)"
}

# Check each node
$nodes = $r.data.resultData.runData
foreach ($nodeName in $nodes.PSObject.Properties.Name) {
    $nodeData = $nodes.$nodeName[0]
    Write-Host "`nNode: $nodeName"
    Write-Host "  Status: $($nodeData.executionStatus)"
    if ($nodeData.error) {
        Write-Host "  Error: $($nodeData.error.message)"
    }
}
