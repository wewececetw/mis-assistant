$ErrorActionPreference = "Stop"

$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"
$baseUrl = "http://localhost:5678/api/v1"
$headers = @{ "X-N8N-API-KEY" = $apiKey }

$ids = @("docker-monitor-workflow", "database-backup-workflow", "meeting-notes-workflow", "tech-news-workflow")

foreach ($id in $ids) {
    try {
        $r = Invoke-RestMethod -Uri "$baseUrl/workflows/$id/activate" -Method POST -Headers $headers -ContentType "application/json"
        Write-Host "Activated: $id"
    } catch {
        # Try PUT method
        try {
            $wf = Invoke-RestMethod -Uri "$baseUrl/workflows/$id" -Method GET -Headers $headers
            # Build minimal update body
            $body = @{ active = $true } | ConvertTo-Json
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
            $r = Invoke-RestMethod -Uri "$baseUrl/workflows/$id" -Method PUT -Headers $headers -ContentType "application/json" -Body $bytes
            Write-Host "Activated (PUT): $id"
        } catch {
            Write-Host "Failed: $id - $($_.Exception.Message)"
        }
    }
}

# Verify
Write-Host ""
Write-Host "=== Verification ==="
$all = Invoke-RestMethod -Uri "$baseUrl/workflows" -Method GET -Headers $headers
foreach ($wf in $all.data) {
    $status = if ($wf.active) { "ACTIVE" } else { "INACTIVE" }
    Write-Host "$($wf.name): $status"
}
