$ErrorActionPreference = "Stop"

$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"
$headers = @{ "X-N8N-API-KEY" = $apiKey }

# Try to activate and capture full error
$id = "docker-monitor-workflow"
try {
    $r = Invoke-WebRequest -Uri "http://localhost:5678/api/v1/workflows/$id/activate" -Method POST -Headers $headers -ContentType "application/json" -UseBasicParsing
    Write-Host "Success: $($r.Content)"
} catch {
    Write-Host "Status: $($_.Exception.Response.StatusCode)"
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $responseBody = $reader.ReadToEnd()
    Write-Host "Error body: $responseBody"
}
