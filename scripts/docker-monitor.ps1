# ========================================
# Docker Container Health Monitor
# ========================================
# Purpose: Monitor all Docker containers health status
# Output: JSON format report for n8n
# Author: Barron
# Version: 1.0.0

param(
    [int]$CpuThreshold = 80,
    [int]$MemoryThreshold = 90,
    [int]$DiskThreshold = 10,
    [int]$RestartThreshold = 3,
    [switch]$Verbose
)

# Set output encoding to UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Read thresholds from environment variables if set
if ($env:CPU_THRESHOLD) { $CpuThreshold = [int]$env:CPU_THRESHOLD }
if ($env:MEMORY_THRESHOLD) { $MemoryThreshold = [int]$env:MEMORY_THRESHOLD }
if ($env:DISK_THRESHOLD) { $DiskThreshold = [int]$env:DISK_THRESHOLD }
if ($env:RESTART_THRESHOLD) { $RestartThreshold = [int]$env:RESTART_THRESHOLD }

# Initialize
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$alerts = @()
$warnings = @()
$info = @()

if ($Verbose) {
    Write-Host "========================================"  -ForegroundColor Cyan
    Write-Host "  Docker Container Health Monitor" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Time: $timestamp" -ForegroundColor White
    Write-Host "CPU Threshold: $CpuThreshold%" -ForegroundColor White
    Write-Host "Memory Threshold: $MemoryThreshold%" -ForegroundColor White
    Write-Host "Disk Threshold: $DiskThreshold%" -ForegroundColor White
    Write-Host "Restart Threshold: $RestartThreshold times" -ForegroundColor White
    Write-Host "========================================`n" -ForegroundColor Cyan
}

# ========================================
# 1. Check if Docker is running
# ========================================
try {
    $dockerVersion = docker version --format '{{.Server.Version}}' 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker is not running or cannot connect"
    }
    if ($Verbose) {
        Write-Host "[OK] Docker version: $dockerVersion`n" -ForegroundColor Green
    }
} catch {
    $errorReport = @{
        Timestamp = $timestamp
        Error = "Docker service error"
        Message = $_.Exception.Message
        Alerts = @(@{
            Type = "CRITICAL"
            Message = "Docker service is not running or cannot connect"
            Icon = "ERROR"
        })
        Warnings = @()
        Info = @()
    }
    Write-Output ($errorReport | ConvertTo-Json -Depth 5)
    exit 1
}

# ========================================
# 2. Get all containers information
# ========================================
try {
    $containersJson = docker ps -a --format "{{json .}}" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Cannot get container list"
    }

    $containers = $containersJson | ForEach-Object {
        $_ | ConvertFrom-Json
    }

    $totalContainers = $containers.Count
    $runningContainers = ($containers | Where-Object { $_.State -eq "running" }).Count

    if ($Verbose) {
        Write-Host "[INFO] Container Statistics:" -ForegroundColor Yellow
        Write-Host "  Total: $totalContainers" -ForegroundColor White
        Write-Host "  Running: $runningContainers" -ForegroundColor Green
        Write-Host "  Stopped: $($totalContainers - $runningContainers)" -ForegroundColor Red
        Write-Host ""
    }

} catch {
    $errorReport = @{
        Timestamp = $timestamp
        Error = "Failed to get container info"
        Message = $_.Exception.Message
        Alerts = @(@{
            Type = "ERROR"
            Message = "Cannot get Docker container list"
            Icon = "ERROR"
        })
    }
    Write-Output ($errorReport | ConvertTo-Json -Depth 5)
    exit 1
}

# ========================================
# 3. Check each container
# ========================================
foreach ($container in $containers) {
    $name = $container.Names
    $status = $container.Status
    $state = $container.State
    $image = $container.Image

    if ($Verbose) {
        Write-Host "[CHECK] Container: $name" -ForegroundColor Yellow
        Write-Host "  Image: $image" -ForegroundColor Gray
        Write-Host "  Status: $status" -ForegroundColor Gray
    }

    # Check container state
    if ($state -ne "running") {
        $alert = @{
            Type = "ERROR"
            Container = $name
            Message = "Container stopped"
            Status = $status
            State = $state
            Image = $image
            Icon = "ALERT"
        }
        $alerts += $alert

        if ($Verbose) {
            Write-Host "  [ERROR] Container stopped!" -ForegroundColor Red
        }
        continue
    }

    # Container is running, check details
    try {
        # Get container detailed info
        $inspectJson = docker inspect $name 2>&1 | ConvertFrom-Json
        $restartCount = $inspectJson[0].RestartCount
        $startedAt = $inspectJson[0].State.StartedAt

        # Check restart count
        if ($restartCount -gt $RestartThreshold) {
            $warning = @{
                Type = "WARNING"
                Container = $name
                Message = "Too many restarts: $restartCount times"
                RestartCount = $restartCount
                Icon = "WARNING"
            }
            $warnings += $warning

            if ($Verbose) {
                Write-Host "  [WARNING] Restart count: $restartCount (exceeds threshold $RestartThreshold)" -ForegroundColor Yellow
            }
        } elseif ($Verbose) {
            Write-Host "  [OK] Restart count: $restartCount" -ForegroundColor Green
        }

        # Get container resource usage
        $statsJson = docker stats --no-stream --format "{{json .}}" $name 2>&1
        if ($LASTEXITCODE -eq 0 -and $statsJson) {
            $stats = $statsJson | ConvertFrom-Json

            # CPU usage
            $cpuPercStr = $stats.CPUPerc -replace '%',''
            $cpuPercent = [double]$cpuPercStr

            if ($cpuPercent -gt $CpuThreshold) {
                $warning = @{
                    Type = "WARNING"
                    Container = $name
                    Message = "High CPU usage: $cpuPercent%"
                    CPUPercent = $cpuPercent
                    Icon = "CPU"
                }
                $warnings += $warning

                if ($Verbose) {
                    Write-Host "  [WARNING] CPU: $cpuPercent% (exceeds threshold $CpuThreshold%)" -ForegroundColor Yellow
                }
            } elseif ($Verbose) {
                Write-Host "  [OK] CPU: $cpuPercent%" -ForegroundColor Green
            }

            # Memory usage
            $memPercStr = $stats.MemPerc -replace '%',''
            $memPercent = [double]$memPercStr

            if ($memPercent -gt $MemoryThreshold) {
                $warning = @{
                    Type = "WARNING"
                    Container = $name
                    Message = "High memory usage: $memPercent%"
                    MemoryPercent = $memPercent
                    MemoryUsage = $stats.MemUsage
                    Icon = "MEMORY"
                }
                $warnings += $warning

                if ($Verbose) {
                    Write-Host "  [WARNING] Memory: $memPercent% ($($stats.MemUsage)) (exceeds threshold $MemoryThreshold%)" -ForegroundColor Yellow
                }
            } elseif ($Verbose) {
                Write-Host "  [OK] Memory: $memPercent% ($($stats.MemUsage))" -ForegroundColor Green
            }

            # Network I/O
            $netIO = $stats.NetIO

            # Block I/O
            $blockIO = $stats.BlockIO

            # Normal running container info
            $containerInfo = @{
                Container = $name
                Image = $image
                Status = "Running normally"
                State = $state
                CPU = "$cpuPercent%"
                Memory = $stats.MemUsage
                MemoryPercent = "$memPercent%"
                NetworkIO = $netIO
                BlockIO = $blockIO
                RestartCount = $restartCount
                StartedAt = $startedAt
            }
            $info += $containerInfo

        } else {
            if ($Verbose) {
                Write-Host "  [WARNING] Cannot get resource stats" -ForegroundColor Yellow
            }
        }

    } catch {
        if ($Verbose) {
            Write-Host "  [WARNING] Check failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    if ($Verbose) {
        Write-Host ""
    }
}

# ========================================
# 4. Check disk space
# ========================================
if ($Verbose) {
    Write-Host "[CHECK] Disk space..." -ForegroundColor Yellow
}

try {
    $drive = Get-PSDrive C
    $usedGB = [math]::Round($drive.Used / 1GB, 2)
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    $totalGB = $usedGB + $freeGB
    $freePercent = [math]::Round(($freeGB / $totalGB) * 100, 2)

    if ($Verbose) {
        Write-Host "  Total: $totalGB GB" -ForegroundColor White
        Write-Host "  Used: $usedGB GB" -ForegroundColor White
        Write-Host "  Free: $freeGB GB ($freePercent%)" -ForegroundColor $(if ($freePercent -lt $DiskThreshold) { "Red" } else { "Green" })
    }

    if ($freePercent -lt $DiskThreshold) {
        $alert = @{
            Type = "CRITICAL"
            Message = "Low disk space: $freePercent% remaining"
            FreePercent = $freePercent
            FreeGB = $freeGB
            TotalGB = $totalGB
            Icon = "DISK"
        }
        $alerts += $alert
    }

} catch {
    if ($Verbose) {
        Write-Host "  [WARNING] Cannot get disk info: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    $freePercent = -1
    $freeGB = -1
    $totalGB = -1
}

# ========================================
# 5. Generate report
# ========================================
$report = @{
    Timestamp = $timestamp
    TotalContainers = $totalContainers
    RunningContainers = $runningContainers
    StoppedContainers = $totalContainers - $runningContainers
    Alerts = $alerts
    Warnings = $warnings
    Info = $info
    DiskFreePercent = $freePercent
    DiskFreeGB = $freeGB
    DiskTotalGB = $totalGB
    Thresholds = @{
        CPU = $CpuThreshold
        Memory = $MemoryThreshold
        Disk = $DiskThreshold
        Restart = $RestartThreshold
    }
}

$reportJson = $report | ConvertTo-Json -Depth 10 -Compress:$false

# ========================================
# 6. Save log
# ========================================
try {
    $logDir = "C:\mis-assistant\logs"
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $logFile = Join-Path $logDir "monitor-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $reportJson | Out-File -FilePath $logFile -Encoding UTF8

    if ($Verbose) {
        Write-Host "`n[INFO] Log saved: $logFile" -ForegroundColor Cyan
    }
} catch {
    if ($Verbose) {
        Write-Host "`n[WARNING] Cannot save log: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# ========================================
# 7. Output summary (Verbose mode)
# ========================================
if ($Verbose) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Monitor Report Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Time: $timestamp" -ForegroundColor White
    Write-Host "Total Containers: $totalContainers" -ForegroundColor White
    Write-Host "Running: $runningContainers" -ForegroundColor Green
    Write-Host "Stopped: $($totalContainers - $runningContainers)" -ForegroundColor $(if ($totalContainers - $runningContainers -gt 0) { "Red" } else { "Green" })
    Write-Host "Errors: $($alerts.Count)" -ForegroundColor $(if ($alerts.Count -gt 0) { "Red" } else { "Green" })
    Write-Host "Warnings: $($warnings.Count)" -ForegroundColor $(if ($warnings.Count -gt 0) { "Yellow" } else { "Green" })
    Write-Host "Disk Free: $freePercent%" -ForegroundColor $(if ($freePercent -lt $DiskThreshold) { "Red" } else { "Green" })
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

# ========================================
# 8. Output JSON for n8n
# ========================================
Write-Output $reportJson

# ========================================
# 9. Set exit code
# ========================================
if ($alerts.Count -gt 0) {
    exit 1  # Critical errors
} elseif ($warnings.Count -gt 0) {
    exit 2  # Warnings
} else {
    exit 0  # All OK
}
