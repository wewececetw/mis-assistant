$token = "TELEGRAM_TOKEN_REMOVED"
$commands = @(
    @{ command = "status"; description = "Check container status now" },
    @{ command = "backup"; description = "Run database backup now" },
    @{ command = "news"; description = "Generate tech news summary" },
    @{ command = "meeting"; description = "AI meeting notes (text or voice)" },
    @{ command = "help"; description = "Show available commands" }
) | ConvertTo-Json -Compress

$body = "{`"commands`":$commands}"
$r = Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/setMyCommands" -Method POST -ContentType "application/json" -Body $body
Write-Host "Result: ok=$($r.ok)"
if ($r.result) {
    Write-Host "Registered commands:"
    $r.result | ForEach-Object { Write-Host "  /$($_.command) - $($_.description)" }
}
