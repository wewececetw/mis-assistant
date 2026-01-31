$body = @{
    text = @"
Meeting: Weekly Team Standup
Date: 2026-01-31
Participants: Alice, Bob, Charlie

1. Alice reported the new login feature is 80% complete, expected to finish by Friday.
2. Bob found a critical bug in the payment module - needs immediate fix.
3. Charlie will handle the database migration next week.
4. Decision: We will use Podman instead of Docker for the production environment.
5. Next meeting scheduled for Monday 10AM.
"@
} | ConvertTo-Json

$r = Invoke-RestMethod -Uri "http://localhost:5678/webhook/meeting-notes" -Method POST -Body $body -ContentType "application/json"
Write-Host "Response:"
$r | ConvertTo-Json -Depth 5
