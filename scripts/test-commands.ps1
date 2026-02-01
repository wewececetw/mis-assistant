$BotToken = "TELEGRAM_TOKEN_REMOVED"
$ChatId = "8146798730"

Write-Host "Testing V3 commands..." -ForegroundColor Cyan
Write-Host ""

$commands = @("/start", "/help", "/meeting")

foreach ($cmd in $commands) {
    Write-Host "Testing: $cmd" -ForegroundColor Yellow

    $body = @{
        chat_id = $ChatId
        text = $cmd
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$BotToken/sendMessage" -Method POST -ContentType "application/json" -Body $body

        if ($response.ok) {
            Write-Host "  [OK] Sent" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL]" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [ERROR] $_" -ForegroundColor Red
    }

    Start-Sleep -Seconds 3
}

Write-Host ""
Write-Host "Check Telegram for responses!" -ForegroundColor Yellow
