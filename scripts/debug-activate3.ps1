$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"
$headers = @{ "X-N8N-API-KEY" = $apiKey }

$ids = @("docker-monitor-workflow", "database-backup-workflow", "meeting-notes-workflow")

foreach ($id in $ids) {
    Write-Host "=== $id ==="
    try {
        $r = Invoke-WebRequest -Uri "http://localhost:5678/api/v1/workflows/$id/activate" -Method POST -Headers $headers -ContentType "application/json" -UseBasicParsing
        Write-Host "OK: $($r.Content)"
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Status: $statusCode"
        try {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $body = $reader.ReadToEnd()
            Write-Host "Body: $body"
        } catch {
            Write-Host "Cannot read body"
        }
    }
    Write-Host ""
}
