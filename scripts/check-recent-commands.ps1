$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"
$headers = @{ "X-N8N-API-KEY" = $apiKey }

$execs = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/executions?limit=15&workflowId=telegram-bot-workflow&includeData=true" -Method GET -Headers $headers

foreach ($exec in $execs.data) {
    $parseData = $exec.data.resultData.runData.'Parse Message'
    if ($parseData -and $parseData[0].data.main[0]) {
        $cmd = $parseData[0].data.main[0][0].json.command
        $type = $parseData[0].data.main[0][0].json.type
        Write-Host "ID=$($exec.id) type=$type command=$cmd time=$($exec.startedAt)"
    }
}
