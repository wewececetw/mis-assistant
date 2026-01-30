# ========================================
# 資料庫自動備份腳本
# ========================================
# 用途: 自動偵測並備份所有 MySQL 容器內的資料庫
# 輸出: JSON 格式報告給 n8n 使用
# 作者: Barron
# 版本: 1.0.0

param(
    [string]$BackupPath = "C:\mis-assistant\backups",
    [int]$RetentionDays = 7,
    [switch]$TestMode,
    [switch]$Verbose
)

# 設定輸出編碼為 UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 從環境變數讀取設定
if ($env:BACKUP_PATH) { $BackupPath = $env:BACKUP_PATH }
if ($env:BACKUP_RETENTION_DAYS) { $RetentionDays = [int]$env:BACKUP_RETENTION_DAYS }

# 初始化
$startTime = Get-Date
$timestamp = $startTime.ToString("yyyy-MM-dd HH:mm:ss")
$dateFolder = $startTime.ToString("yyyyMMdd")
$backupFolder = Join-Path $BackupPath $dateFolder

$successBackups = @()
$failedBackups = @()
$totalSize = 0

if ($Verbose) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  資料庫自動備份" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "開始時間: $timestamp" -ForegroundColor White
    Write-Host "備份路徑: $backupFolder" -ForegroundColor White
    Write-Host "保留天數: $RetentionDays 天" -ForegroundColor White
    Write-Host "測試模式: $(if ($TestMode) { '是' } else { '否' })" -ForegroundColor White
    Write-Host "========================================`n" -ForegroundColor Cyan
}

# ========================================
# 1. 建立備份目錄
# ========================================
if (!$TestMode) {
    try {
        if (!(Test-Path $backupFolder)) {
            New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
            if ($Verbose) {
                Write-Host "✅ 建立備份目錄: $backupFolder`n" -ForegroundColor Green
            }
        } else {
            if ($Verbose) {
                Write-Host "✅ 備份目錄已存在: $backupFolder`n" -ForegroundColor Green
            }
        }
    } catch {
        $errorReport = @{
            Timestamp = $timestamp
            Success = $false
            Error = "無法建立備份目錄"
            Message = $_.Exception.Message
        }
        Write-Output ($errorReport | ConvertTo-Json -Depth 5)
        exit 1
    }
}

# ========================================
# 2. 偵測所有 MySQL 容器
# ========================================
if ($Verbose) {
    Write-Host "🔍 掃描 MySQL 容器..." -ForegroundColor Yellow
}

try {
    # 取得所有運行中的容器
    $containersJson = docker ps --format "{{json .}}" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "無法取得容器清單"
    }

    $allContainers = $containersJson | ForEach-Object {
        $_ | ConvertFrom-Json
    }

    # 過濾出 MySQL 容器 (根據映像名稱或容器名稱)
    $mysqlContainers = $allContainers | Where-Object {
        $_.Image -match "mysql" -or $_.Names -match "mysql"
    }

    if ($mysqlContainers.Count -eq 0) {
        if ($Verbose) {
            Write-Host "⚠️  未找到任何 MySQL 容器`n" -ForegroundColor Yellow
        }

        $report = @{
            Timestamp = $timestamp
            Success = $true
            MySQLContainersFound = 0
            Backups = @()
            TotalSizeBytes = 0
            TotalSizeMB = 0
            Duration = "0s"
            Message = "未找到任何 MySQL 容器"
        }
        Write-Output ($report | ConvertTo-Json -Depth 10)
        exit 0
    }

    if ($Verbose) {
        Write-Host "✅ 找到 $($mysqlContainers.Count) 個 MySQL 容器:`n" -ForegroundColor Green
        foreach ($container in $mysqlContainers) {
            Write-Host "  📦 $($container.Names) ($($container.Image))" -ForegroundColor White
        }
        Write-Host ""
    }

} catch {
    $errorReport = @{
        Timestamp = $timestamp
        Success = $false
        Error = "容器掃描失敗"
        Message = $_.Exception.Message
    }
    Write-Output ($errorReport | ConvertTo-Json -Depth 5)
    exit 1
}

# ========================================
# 3. 備份每個 MySQL 容器
# ========================================
foreach ($container in $mysqlContainers) {
    $containerName = $container.Names

    if ($Verbose) {
        Write-Host "🗄️  處理容器: $containerName" -ForegroundColor Yellow
    }

    # 取得容器的環境變數以獲取 MySQL 配置
    try {
        $inspectJson = docker inspect $containerName 2>&1 | ConvertFrom-Json
        $envVars = $inspectJson[0].Config.Env

        # 解析環境變數
        $mysqlUser = "root"
        $mysqlPassword = ""
        $mysqlDatabase = ""

        foreach ($env in $envVars) {
            if ($env -match "^MYSQL_ROOT_PASSWORD=(.+)$") {
                $mysqlPassword = $matches[1]
            }
            elseif ($env -match "^MYSQL_USER=(.+)$") {
                $mysqlUser = $matches[1]
            }
            elseif ($env -match "^MYSQL_PASSWORD=(.+)$") {
                $mysqlPassword = $matches[1]
            }
            elseif ($env -match "^MYSQL_DATABASE=(.+)$") {
                $mysqlDatabase = $matches[1]
            }
        }

        if ($Verbose) {
            Write-Host "  📋 MySQL 使用者: $mysqlUser" -ForegroundColor Gray
            Write-Host "  📋 MySQL 密碼: $(if ($mysqlPassword) { '***' } else { '(空)' })" -ForegroundColor Gray
        }

        # 列出所有資料庫
        $listDbCmd = "mysql -u$mysqlUser"
        if ($mysqlPassword) {
            $listDbCmd += " -p$mysqlPassword"
        }
        $listDbCmd += " -e 'SHOW DATABASES;'"

        $databasesOutput = docker exec $containerName sh -c $listDbCmd 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "無法列出資料庫: $databasesOutput"
        }

        # 解析資料庫清單 (排除系統資料庫)
        $databases = $databasesOutput -split "`n" | Where-Object {
            $_ -and
            $_ -notmatch "^Database$" -and
            $_ -notmatch "^information_schema$" -and
            $_ -notmatch "^performance_schema$" -and
            $_ -notmatch "^mysql$" -and
            $_ -notmatch "^sys$" -and
            $_.Trim() -ne ""
        } | ForEach-Object { $_.Trim() }

        if ($databases.Count -eq 0) {
            if ($Verbose) {
                Write-Host "  ⚠️  未找到可備份的資料庫`n" -ForegroundColor Yellow
            }
            continue
        }

        if ($Verbose) {
            Write-Host "  ✅ 找到 $($databases.Count) 個資料庫: $($databases -join ', ')" -ForegroundColor Green
        }

        # 備份每個資料庫
        foreach ($db in $databases) {
            $backupFile = "$db-$containerName-$(Get-Date -Format 'yyyyMMdd-HHmmss').sql"
            $backupFilePath = Join-Path $backupFolder $backupFile
            $compressedFile = "$backupFilePath.gz"

            if ($Verbose) {
                Write-Host "`n  🔄 備份資料庫: $db" -ForegroundColor Cyan
            }

            if (!$TestMode) {
                try {
                    # 執行 mysqldump
                    $dumpCmd = "mysqldump -u$mysqlUser"
                    if ($mysqlPassword) {
                        $dumpCmd += " -p$mysqlPassword"
                    }
                    $dumpCmd += " --single-transaction --quick --lock-tables=false $db"

                    # 執行備份並儲存到檔案
                    $dumpOutput = docker exec $containerName sh -c $dumpCmd 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "mysqldump 執行失敗: $dumpOutput"
                    }

                    # 寫入檔案
                    $dumpOutput | Out-File -FilePath $backupFilePath -Encoding UTF8

                    # 檢查檔案大小
                    $fileInfo = Get-Item $backupFilePath
                    $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)

                    if ($Verbose) {
                        Write-Host "    ✅ SQL 備份完成: $fileSizeMB MB" -ForegroundColor Green
                    }

                    # 壓縮檔案 (使用 7-Zip 或 PowerShell 壓縮)
                    if ($Verbose) {
                        Write-Host "    🗜️  壓縮中..." -ForegroundColor Cyan
                    }

                    # 使用 .NET 壓縮
                    try {
                        $sourceStream = [System.IO.File]::OpenRead($backupFilePath)
                        $targetStream = [System.IO.File]::Create($compressedFile)
                        $gzipStream = New-Object System.IO.Compression.GZipStream($targetStream, [System.IO.Compression.CompressionMode]::Compress)

                        $sourceStream.CopyTo($gzipStream)

                        $gzipStream.Close()
                        $targetStream.Close()
                        $sourceStream.Close()

                        # 刪除原始 SQL 檔案
                        Remove-Item $backupFilePath -Force

                        # 取得壓縮後檔案大小
                        $compressedInfo = Get-Item $compressedFile
                        $compressedSizeMB = [math]::Round($compressedInfo.Length / 1MB, 2)
                        $compressionRatio = [math]::Round(($compressedInfo.Length / $fileInfo.Length) * 100, 2)

                        $totalSize += $compressedInfo.Length

                        if ($Verbose) {
                            Write-Host "    ✅ 壓縮完成: $compressedSizeMB MB (壓縮率: $compressionRatio%)" -ForegroundColor Green
                        }

                        $successBackups += @{
                            Container = $containerName
                            Database = $db
                            FileName = "$backupFile.gz"
                            OriginalSizeMB = $fileSizeMB
                            CompressedSizeMB = $compressedSizeMB
                            CompressionRatio = "$compressionRatio%"
                            Path = $compressedFile
                        }

                    } catch {
                        if ($Verbose) {
                            Write-Host "    ⚠️  壓縮失敗,保留原始檔案: $($_.Exception.Message)" -ForegroundColor Yellow
                        }

                        $successBackups += @{
                            Container = $containerName
                            Database = $db
                            FileName = $backupFile
                            SizeMB = $fileSizeMB
                            Compressed = $false
                            Path = $backupFilePath
                        }
                    }

                } catch {
                    if ($Verbose) {
                        Write-Host "    ❌ 備份失敗: $($_.Exception.Message)" -ForegroundColor Red
                    }

                    $failedBackups += @{
                        Container = $containerName
                        Database = $db
                        Error = $_.Exception.Message
                    }
                }
            } else {
                # 測試模式,不實際備份
                if ($Verbose) {
                    Write-Host "    [測試模式] 將備份到: $compressedFile" -ForegroundColor Gray
                }
            }
        }

        if ($Verbose) {
            Write-Host ""
        }

    } catch {
        if ($Verbose) {
            Write-Host "  ❌ 容器處理失敗: $($_.Exception.Message)`n" -ForegroundColor Red
        }

        $failedBackups += @{
            Container = $containerName
            Error = $_.Exception.Message
        }
    }
}

# ========================================
# 4. 清理舊備份
# ========================================
if (!$TestMode -and $RetentionDays -gt 0) {
    if ($Verbose) {
        Write-Host "🗑️  清理舊備份 (保留 $RetentionDays 天)..." -ForegroundColor Yellow
    }

    try {
        $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
        $oldBackups = Get-ChildItem -Path $BackupPath -Directory | Where-Object {
            $_.Name -match "^\d{8}$" -and [DateTime]::ParseExact($_.Name, "yyyyMMdd", $null) -lt $cutoffDate
        }

        $deletedCount = 0
        $deletedSize = 0

        foreach ($oldFolder in $oldBackups) {
            $folderSize = (Get-ChildItem -Path $oldFolder.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum
            Remove-Item -Path $oldFolder.FullName -Recurse -Force
            $deletedCount++
            $deletedSize += $folderSize

            if ($Verbose) {
                Write-Host "  ✅ 刪除: $($oldFolder.Name) ($([math]::Round($folderSize / 1MB, 2)) MB)" -ForegroundColor Green
            }
        }

        if ($deletedCount -eq 0) {
            if ($Verbose) {
                Write-Host "  ℹ️  沒有需要清理的舊備份" -ForegroundColor Cyan
            }
        } else {
            if ($Verbose) {
                Write-Host "  ✅ 共刪除 $deletedCount 個舊備份資料夾,釋放 $([math]::Round($deletedSize / 1MB, 2)) MB 空間" -ForegroundColor Green
            }
        }

    } catch {
        if ($Verbose) {
            Write-Host "  ⚠️  清理失敗: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    if ($Verbose) {
        Write-Host ""
    }
}

# ========================================
# 5. 生成報告
# ========================================
$endTime = Get-Date
$duration = $endTime - $startTime
$durationStr = "{0:hh\:mm\:ss}" -f $duration

$totalSizeMB = [math]::Round($totalSize / 1MB, 2)

$report = @{
    Timestamp = $timestamp
    Success = $failedBackups.Count -eq 0
    MySQLContainersFound = $mysqlContainers.Count
    SuccessfulBackups = $successBackups.Count
    FailedBackups = $failedBackups.Count
    Backups = $successBackups
    Failures = $failedBackups
    TotalSizeBytes = $totalSize
    TotalSizeMB = $totalSizeMB
    BackupFolder = $backupFolder
    Duration = $durationStr
    RetentionDays = $RetentionDays
}

$reportJson = $report | ConvertTo-Json -Depth 10 -Compress:$false

# ========================================
# 6. 儲存日誌
# ========================================
if (!$TestMode) {
    try {
        $logDir = "C:\mis-assistant\logs"
        if (!(Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }

        $logFile = Join-Path $logDir "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $reportJson | Out-File -FilePath $logFile -Encoding UTF8

        if ($Verbose) {
            Write-Host "📝 日誌已儲存: $logFile`n" -ForegroundColor Cyan
        }
    } catch {
        if ($Verbose) {
            Write-Host "⚠️  無法儲存日誌: $($_.Exception.Message)`n" -ForegroundColor Yellow
        }
    }
}

# ========================================
# 7. 輸出摘要 (Verbose 模式)
# ========================================
if ($Verbose) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  📊 備份報告摘要" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "完成時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
    Write-Host "執行時長: $durationStr" -ForegroundColor White
    Write-Host "成功: $($successBackups.Count)" -ForegroundColor Green
    Write-Host "失敗: $($failedBackups.Count)" -ForegroundColor $(if ($failedBackups.Count -gt 0) { "Red" } else { "Green" })
    Write-Host "總大小: $totalSizeMB MB" -ForegroundColor White
    Write-Host "儲存位置: $backupFolder" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

# ========================================
# 8. 輸出 JSON 給 n8n
# ========================================
Write-Output $reportJson

# ========================================
# 9. 設定退出碼
# ========================================
if ($failedBackups.Count -gt 0) {
    exit 1  # 有備份失敗
} else {
    exit 0  # 全部成功
}
