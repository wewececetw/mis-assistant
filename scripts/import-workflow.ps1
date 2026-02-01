param([string]$WorkflowFile)

$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1ZjgyZjYxNS01MjFmLTQzOGUtODMwYy1lMzNmN2FhOGZjYTQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5Nzg5ODcwfQ.L-pQGcvO8MhO9lh0Qw7RzYBtbsvmS_DTqpQm-yoHth8"
$headers = @{
    "X-N8N-API-KEY" = $apiKey
    "Content-Type" = "application/json"
}

# Read workflow file
$workflow = Get-Content $WorkflowFile -Raw | ConvertFrom-Json

# Check if workflow already exists
$existingWfs = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows" -Headers $headers
$existing = $existingWfs.data | Where-Object { $_.name -eq $workflow.name }

if ($existing) {
    # Update existing workflow
    Write-Host "Updating existing workflow: $($workflow.name)"
    $workflow.id = $existing.id
    $body = $workflow | ConvertTo-Json -Depth 20 -Compress
    $result = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows/$($existing.id)" -Method PUT -Headers $headers -Body $body
    Write-Host "Updated: $($result.name) (ID: $($result.id))"
} else {
    # Create new workflow
    Write-Host "Creating new workflow: $($workflow.name)"
    $workflow.PSObject.Properties.Remove('id')
    $body = $workflow | ConvertTo-Json -Depth 20 -Compress
    $result = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows" -Method POST -Headers $headers -Body $body
    Write-Host "Created: $($result.name) (ID: $($result.id))"
}

Write-Host "Import complete!"
