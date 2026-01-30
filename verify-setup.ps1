# ========================================
# MIS Assistant - Setup Verification Script
# ========================================
# Purpose: Verify all files are created correctly
# Author: Claude Code
# Version: 1.0.0

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  MIS Assistant - Setup Verification" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

$projectRoot = "C:\mis-assistant"
$allFilesOK = $true
$totalFiles = 0
$foundFiles = 0

# Define expected files
$expectedFiles = @{
    "Core Files" = @(
        "docker-compose.yml",
        ".env.example",
        "test-all.ps1",
        "verify-setup.ps1"
    )
    "Documentation" = @(
        "START-HERE.md",
        "QUICK-START.md",
        "README.md",
        "CHECKLIST.md",
        "FILES.md"
    )
    "Workflows" = @(
        "workflows\1-docker-monitor.json",
        "workflows\2-database-backup.json",
        "workflows\3-meeting-notes.json",
        "workflows\4-tech-news.json"
    )
    "Scripts" = @(
        "scripts\docker-monitor.ps1",
        "scripts\backup-databases.ps1",
        "scripts\cleanup-old-backups.ps1"
    )
    "Docs" = @(
        "docs\telegram-setup.md",
        "docs\groq-setup.md",
        "docs\maintenance.md",
        "docs\troubleshooting.md"
    )
}

# Check each category
foreach ($category in $expectedFiles.Keys) {
    Write-Host "Checking $category..." -ForegroundColor Yellow

    foreach ($file in $expectedFiles[$category]) {
        $totalFiles++
        $fullPath = Join-Path $projectRoot $file

        if (Test-Path $fullPath) {
            $fileInfo = Get-Item $fullPath
            $sizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
            Write-Host "  [OK] $file ($sizeKB KB)" -ForegroundColor Green
            $foundFiles++
        } else {
            Write-Host "  [MISSING] $file" -ForegroundColor Red
            $allFilesOK = $false
        }
    }
    Write-Host ""
}

# Check directories
Write-Host "Checking Directories..." -ForegroundColor Yellow
$expectedDirs = @("workflows", "scripts", "backups", "logs", "docs")

foreach ($dir in $expectedDirs) {
    $dirPath = Join-Path $projectRoot $dir
    if (Test-Path $dirPath) {
        Write-Host "  [OK] $dir/" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $dir/" -ForegroundColor Red
        $allFilesOK = $false
    }
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  Verification Summary" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Total Files Expected: $totalFiles" -ForegroundColor White
Write-Host "Files Found: $foundFiles" -ForegroundColor $(if ($foundFiles -eq $totalFiles) { "Green" } else { "Yellow" })
Write-Host "Missing Files: $($totalFiles - $foundFiles)" -ForegroundColor $(if ($foundFiles -eq $totalFiles) { "Green" } else { "Red" })
Write-Host ""

if ($allFilesOK) {
    Write-Host "Status: ALL FILES READY!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Read START-HERE.md" -ForegroundColor White
    Write-Host "  2. Follow QUICK-START.md" -ForegroundColor White
    Write-Host "  3. Deploy in 20 minutes!" -ForegroundColor White
    Write-Host ""
    exit 0
} else {
    Write-Host "Status: SOME FILES MISSING" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check the missing files above." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
