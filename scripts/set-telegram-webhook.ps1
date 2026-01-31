$token = "TELEGRAM_TOKEN_REMOVED"
$webhookUrl = "https://nucboxg3-plus.tail2f559.ts.net/webhook/telegram-bot"

# Delete existing webhook first
$delResult = Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/deleteWebhook"
Write-Host "Delete webhook: $($delResult.ok) - $($delResult.description)"

# Set new webhook
$body = @{
    url = $webhookUrl
    allowed_updates = @("message")
} | ConvertTo-Json

$result = Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/setWebhook" -Method POST -ContentType "application/json" -Body $body
Write-Host "Set webhook: $($result.ok) - $($result.description)"
Write-Host "Webhook URL: $webhookUrl"

# Get webhook info
$info = Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/getWebhookInfo"
Write-Host "`nWebhook Info:"
Write-Host "  URL: $($info.result.url)"
Write-Host "  Pending updates: $($info.result.pending_update_count)"
