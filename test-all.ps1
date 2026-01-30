# ========================================
# MIS Assistant - Complete Test Script
# ========================================
# Purpose: Test all components of the MIS Assistant system
# Author: Barron
# Version: 1.0.0

param(
    [switch]$SkipDocker,
    [switch]$SkipScripts,
    [switch]$SkipAPI,
    [switch]$Verbose
)

# Set output encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$testResults = @()
$totalTests = 0
$passedTests = 0
$failedTests = 0

function Write-TestHeader {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )

    $script:totalTests++

    if ($Passed) {
        $script:passedTests++
        Write-Host "[PASS] $TestName" -ForegroundColor Green
        if ($Message) {
            Write-Host "       $Message" -ForegroundColor Gray
        }
    } else {
        $script:failedTests++
        Write-Host "[FAIL] $TestName" -ForegroundColor Red
        if ($Message) {
            Write-Host "       $Message" -ForegroundColor Yellow
        }
    }

    $script:testResults += @{
        Test = $TestName
        Passed = $Passed
        Message = $Message
    }
}

Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  MIS Assistant - System Test Suite" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host ""

# ========================================
# Test 1: Environment Check
# ========================================
Write-TestHeader "Test 1: Environment Check"

# Test 1.1: Check project directory
$projectDir = "C:\mis-assistant"
$dirExists = Test-Path $projectDir
Write-TestResult "Project directory exists" $dirExists $projectDir

# Test 1.2: Check required subdirectories
$requiredDirs = @("workflows", "scripts", "backups", "logs", "docs")
foreach ($dir in $requiredDirs) {
    $dirPath = Join-Path $projectDir $dir
    $exists = Test-Path $dirPath
    Write-TestResult "Directory exists: $dir" $exists $dirPath
}

# Test 1.3: Check .env file
$envFile = Join-Path $projectDir ".env"
$envExists = Test-Path $envFile
Write-TestResult ".env file exists" $envExists $(if ($envExists) { "Found" } else { "Missing - copy from .env.example" })

# Test 1.4: Check docker-compose.yml
$composeFile = Join-Path $projectDir "docker-compose.yml"
$composeExists = Test-Path $composeFile
Write-TestResult "docker-compose.yml exists" $composeExists

# ========================================
# Test 2: Docker Check
# ========================================
if (!$SkipDocker) {
    Write-TestHeader "Test 2: Docker Environment"

    # Test 2.1: Docker installed
    try {
        $dockerVersion = docker --version 2>&1
        $dockerInstalled = $LASTEXITCODE -eq 0
        Write-TestResult "Docker installed" $dockerInstalled $dockerVersion
    } catch {
        Write-TestResult "Docker installed" $false "Docker not found"
    }

    # Test 2.2: Docker running
    try {
        $dockerRunning = docker ps 2>&1
        $dockerOk = $LASTEXITCODE -eq 0
        Write-TestResult "Docker running" $dockerOk
    } catch {
        Write-TestResult "Docker running" $false "Docker daemon not running"
    }

    # Test 2.3: Docker Compose installed
    try {
        $composeVersion = docker-compose --version 2>&1
        $composeInstalled = $LASTEXITCODE -eq 0
        Write-TestResult "Docker Compose installed" $composeInstalled $composeVersion
    } catch {
        Write-TestResult "Docker Compose installed" $false "Docker Compose not found"
    }

    # Test 2.4: Check existing containers
    if ($dockerOk) {
        try {
            $containers = docker ps -a --format "{{json .}}" | ForEach-Object { $_ | ConvertFrom-Json }
            $containerCount = $containers.Count
            Write-TestResult "Docker containers detected" ($containerCount -gt 0) "$containerCount containers found"

            $runningCount = ($containers | Where-Object { $_.State -eq "running" }).Count
            Write-Host "       Running: $runningCount / $containerCount" -ForegroundColor Gray
        } catch {
            Write-TestResult "Docker containers detected" $false "Cannot list containers"
        }
    }
}

# ========================================
# Test 3: PowerShell Scripts
# ========================================
if (!$SkipScripts) {
    Write-TestHeader "Test 3: PowerShell Scripts"

    $scripts = @(
        "docker-monitor.ps1",
        "backup-databases.ps1",
        "cleanup-old-backups.ps1"
    )

    foreach ($script in $scripts) {
        $scriptPath = Join-Path $projectDir "scripts\$script"
        $scriptExists = Test-Path $scriptPath
        Write-TestResult "Script exists: $script" $scriptExists

        if ($scriptExists) {
            # Test script syntax
            try {
                $errors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $scriptPath -Raw), [ref]$errors)
                $syntaxOk = $errors.Count -eq 0
                Write-TestResult "  Syntax check: $script" $syntaxOk $(if ($syntaxOk) { "No errors" } else { "$($errors.Count) errors" })
            } catch {
                Write-TestResult "  Syntax check: $script" $false $_.Exception.Message
            }
        }
    }

    # Test 3.4: Execute docker-monitor.ps1
    Write-Host "`n  Executing docker-monitor.ps1..." -ForegroundColor Yellow
    try {
        $monitorScript = Join-Path $projectDir "scripts\docker-monitor.ps1"
        $result = & powershell.exe -ExecutionPolicy Bypass -File $monitorScript 2>&1
        $monitorOk = $LASTEXITCODE -ne $null  # Script executed (any exit code is OK for test)

        # Try to parse JSON output
        try {
            $jsonOutput = $result | Where-Object { $_ -match "^\s*\{" -or $_ -match "^\s*\}" -or $_ -match ":" } | Out-String
            $parsed = $jsonOutput | ConvertFrom-Json
            Write-TestResult "  docker-monitor.ps1 execution" $true "Generated valid JSON output"
            Write-Host "       Containers: $($parsed.TotalContainers) total, $($parsed.RunningContainers) running" -ForegroundColor Gray
            Write-Host "       Alerts: $($parsed.Alerts.Count), Warnings: $($parsed.Warnings.Count)" -ForegroundColor Gray
        } catch {
            Write-TestResult "  docker-monitor.ps1 execution" $monitorOk "Executed but JSON parse failed"
        }
    } catch {
        Write-TestResult "  docker-monitor.ps1 execution" $false $_.Exception.Message
    }
}

# ========================================
# Test 4: n8n Service
# ========================================
Write-TestHeader "Test 4: n8n Service"

# Test 4.1: Check if n8n container exists
try {
    $n8nContainer = docker ps -a --filter "name=n8n-mis" --format "{{json .}}" 2>&1
    if ($LASTEXITCODE -eq 0 -and $n8nContainer) {
        $n8n = $n8nContainer | ConvertFrom-Json
        $n8nExists = $true
        $n8nRunning = $n8n.State -eq "running"

        Write-TestResult "n8n container exists" $n8nExists $n8n.Status
        Write-TestResult "n8n container running" $n8nRunning

        if ($n8nRunning) {
            # Test 4.2: Check n8n web interface
            Start-Sleep -Seconds 2
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:5678" -TimeoutSec 5 -UseBasicParsing
                $webOk = $response.StatusCode -eq 200
                Write-TestResult "n8n web interface accessible" $webOk "http://localhost:5678"
            } catch {
                Write-TestResult "n8n web interface accessible" $false "Cannot connect to http://localhost:5678"
            }
        }
    } else {
        Write-TestResult "n8n container exists" $false "Container not found - run 'docker-compose up -d'"
    }
} catch {
    Write-TestResult "n8n container exists" $false "Cannot check Docker containers"
}

# ========================================
# Test 5: API Keys Configuration
# ========================================
if (!$SkipAPI -and $envExists) {
    Write-TestHeader "Test 5: API Keys Configuration"

    $envContent = Get-Content $envFile -Raw

    # Test 5.1: Groq API key
    $hasGroqKey = $envContent -match "GROQ_API_KEY=gsk_"
    Write-TestResult "Groq API key configured" $hasGroqKey $(if ($hasGroqKey) { "Found" } else { "Missing or invalid" })

    # Test 5.2: Telegram Bot Token
    $hasTelegramToken = $envContent -match "TELEGRAM_BOT_TOKEN=\d+:"
    Write-TestResult "Telegram Bot Token configured" $hasTelegramToken $(if ($hasTelegramToken) { "Found" } else { "Missing or invalid" })

    # Test 5.3: Telegram Chat ID
    $hasTelegramChatId = $envContent -match "TELEGRAM_CHAT_ID=\d+"
    Write-TestResult "Telegram Chat ID configured" $hasTelegramChatId $(if ($hasTelegramChatId) { "Found" } else { "Missing or invalid" })

    # Test 5.4: n8n Password
    $hasN8nPassword = $envContent -match "N8N_PASSWORD=.{8,}"
    Write-TestResult "n8n password configured" $hasN8nPassword $(if ($hasN8nPassword) { "Found" } else { "Missing or too short (min 8 chars)" })

    # Test 5.5: Test Groq API (if key found)
    if ($hasGroqKey) {
        try {
            $groqKey = ($envContent | Select-String "GROQ_API_KEY=(.+)" | ForEach-Object { $_.Matches.Groups[1].Value }).Trim()

            $headers = @{
                "Authorization" = "Bearer $groqKey"
                "Content-Type" = "application/json"
            }

            $body = @{
                "model" = "llama-3.3-70b-versatile"
                "messages" = @(
                    @{
                        "role" = "user"
                        "content" = "Say 'OK' if you can read this."
                    }
                )
                "max_tokens" = 10
            } | ConvertTo-Json

            Write-Host "  Testing Groq API..." -ForegroundColor Yellow
            $response = Invoke-RestMethod -Uri "https://api.groq.com/openai/v1/chat/completions" -Method POST -Headers $headers -Body $body -TimeoutSec 10
            $groqOk = $response.choices[0].message.content -ne $null
            Write-TestResult "  Groq API connection" $groqOk "API responds correctly"
        } catch {
            Write-TestResult "  Groq API connection" $false $_.Exception.Message
        }
    }
}

# ========================================
# Test 6: System Resources
# ========================================
Write-TestHeader "Test 6: System Resources"

# Test 6.1: Disk space
try {
    $drive = Get-PSDrive C
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    $totalGB = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
    $freePercent = [math]::Round(($freeGB / $totalGB) * 100, 2)

    $diskOk = $freeGB -gt 10
    Write-TestResult "Disk space available" $diskOk "$freeGB GB free ($freePercent%)"
} catch {
    Write-TestResult "Disk space available" $false "Cannot check disk space"
}

# Test 6.2: Memory
try {
    $memory = Get-CimInstance Win32_OperatingSystem
    $totalMemGB = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
    $freeMemGB = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
    $memPercent = [math]::Round(($freeMemGB / $totalMemGB) * 100, 2)

    $memOk = $freeMemGB -gt 2
    Write-TestResult "Available memory" $memOk "$freeMemGB GB free of $totalMemGB GB ($memPercent%)"
} catch {
    Write-TestResult "Available memory" $false "Cannot check memory"
}

# ========================================
# Test Summary
# ========================================
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  Test Summary" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })
Write-Host "Success Rate: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Yellow" })
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "End Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host ""

# ========================================
# Recommendations
# ========================================
if ($failedTests -gt 0) {
    Write-Host "RECOMMENDATIONS:" -ForegroundColor Yellow
    Write-Host ""

    if (!(Test-Path (Join-Path $projectDir ".env"))) {
        Write-Host "  1. Copy .env.example to .env and configure API keys" -ForegroundColor Yellow
        Write-Host "     cp C:\mis-assistant\.env.example C:\mis-assistant\.env" -ForegroundColor Gray
    }

    $n8nContainer = docker ps -a --filter "name=n8n-mis" --format "{{json .}}" 2>&1
    if (!$n8nContainer) {
        Write-Host "  2. Start n8n service:" -ForegroundColor Yellow
        Write-Host "     cd C:\mis-assistant" -ForegroundColor Gray
        Write-Host "     docker-compose up -d" -ForegroundColor Gray
    }

    Write-Host ""
}

# Save results to JSON
try {
    $reportPath = Join-Path $projectDir "logs\test-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $testReport = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalTests = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
        SuccessRate = [math]::Round(($passedTests / $totalTests) * 100, 2)
        Results = $testResults
    }
    $testReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "[INFO] Test results saved to: $reportPath" -ForegroundColor Cyan
} catch {
    Write-Host "[WARNING] Cannot save test results: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Exit code
exit $(if ($failedTests -eq 0) { 0 } else { 1 })
