$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"
$baseUrl = "http://localhost:5678/api/v1"
$headers = @{ "X-N8N-API-KEY" = $apiKey }

function Invoke-N8nApi {
    param($Method, $Path, $Body)
    $uri = "$baseUrl/$Path"
    $params = @{
        Uri = $uri
        Method = $Method
        Headers = $headers
        ContentType = "application/json; charset=utf-8"
    }
    if ($Body) {
        $json = $Body | ConvertTo-Json -Depth 10
        $params.Body = [System.Text.Encoding]::UTF8.GetBytes($json)
    }
    Invoke-RestMethod @params
}

# Step 1: Create Telegram credential
Write-Host "=== Creating Telegram credential ==="
$telegramCred = Invoke-N8nApi -Method POST -Path "credentials" -Body @{
    name = "Telegram Bot"
    type = "telegramApi"
    data = @{
        accessToken = "TELEGRAM_TOKEN_REMOVED"
    }
}
Write-Host "Telegram credential created: ID=$($telegramCred.id)"

# Step 2: Create Groq (Header Auth) credential
Write-Host "=== Creating Groq API credential ==="
$groqCred = Invoke-N8nApi -Method POST -Path "credentials" -Body @{
    name = "Groq API"
    type = "httpHeaderAuth"
    data = @{
        name = "Authorization"
        value = "Bearer GROQ_API_KEY_REMOVED"
    }
}
Write-Host "Groq API credential created: ID=$($groqCred.id)"

# Step 3: Activate all workflows
Write-Host "=== Activating workflows ==="
$workflowIds = @("docker-monitor-workflow", "database-backup-workflow", "meeting-notes-workflow", "tech-news-workflow")

foreach ($wfId in $workflowIds) {
    try {
        Invoke-N8nApi -Method POST -Path "workflows/$wfId/activate" -Body $null
        Write-Host "Activated: $wfId"
    } catch {
        try {
            Invoke-N8nApi -Method PUT -Path "workflows/$wfId" -Body @{ active = $true }
            Write-Host "Activated (PUT): $wfId"
        } catch {
            Write-Host "Failed to activate $wfId : $_"
        }
    }
}

Write-Host ""
Write-Host "=== Setup Complete ==="
Write-Host "Telegram Credential ID: $($telegramCred.id)"
Write-Host "Groq API Credential ID: $($groqCred.id)"
