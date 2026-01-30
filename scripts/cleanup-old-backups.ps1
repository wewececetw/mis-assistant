# ========================================
# 清理舊備份腳本
# ========================================
# 用途: 刪除超過指定天數的舊備份檔案
# 作者: Barron
# 版本: 1.0.0

param(
    [string]$BackupPath = "C:\mis-assistant\backups",
    [int]$RetentionDays = 7,
    [switch]$WhatIf,
    [switch]$Verbose
)

# 設定輸出編碼為 UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 從環境變數讀取設定
if ($env:BACKUP_PATH) { $BackupPath = $env:BACKUP_PATH }
if ($env:BACKUP_RETENTION_DAYS) { $RetentionDays = [int]$env:BACKUP_RETENTION_DAYS }

# 初始化
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$cutoffDate = (Get-Date).AddDays(-$RetentionDays)

$deletedFolders = @()
$totalDeletedSize = 0
$totalDeletedFiles = 0

if ($Verbose) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  清理舊備份" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "執行時間: $timestamp" -ForegroundColor White
    Write-Host "備份路徑: $BackupPath" -ForegroundColor White
    Write-Host "保留天數: $RetentionDays 天" -ForegroundColor White
    Write-Host "截止日期: $($cutoffDate.ToString('yyyy-MM-dd'))" -ForegroundColor White
    Write-Host "預覽模式: $(if ($WhatIf) { '是' } else { '否' })" -ForegroundColor White
    Write-Host "========================================`n" -ForegroundColor Cyan
}

# ========================================
# 1. 檢查備份目錄是否存在
# ========================================
if (!(Test-Path $BackupPath)) {
    if ($Verbose) {
        Write-Host "⚠️  備份目錄不存在: $BackupPath" -ForegroundColor Yellow
    }

    $report = @{
        Timestamp = $timestamp
        Success = $true
        Message = "備份目錄不存在"
        BackupPath = $BackupPath
        DeletedFolders = 0
        DeletedFiles = 0
        FreedSpaceMB = 0
    }
    Write-Output ($report | ConvertTo-Json -Depth 5)
    exit 0
}

# ========================================
# 2. 掃描舊備份資料夾
# ========================================
if ($Verbose) {
    Write-Host "🔍 掃描舊備份資料夾..." -ForegroundColor Yellow
}

try {
    # 取得所有備份資料夾 (格式: YYYYMMDD)
    $allBackupFolders = Get-ChildItem -Path $BackupPath -Directory | Where-Object {
        $_.Name -match "^\d{8}$"
    }

    if ($allBackupFolders.Count -eq 0) {
        if ($Verbose) {
            Write-Host "ℹ️  沒有找到任何備份資料夾`n" -ForegroundColor Cyan
        }

        $report = @{
            Timestamp = $timestamp
            Success = $true
            Message = "沒有找到任何備份資料夾"
            BackupPath = $BackupPath
            DeletedFolders = 0
            DeletedFiles = 0
            FreedSpaceMB = 0
        }
        Write-Output ($report | ConvertTo-Json -Depth 5)
        exit 0
    }

    if ($Verbose) {
        Write-Host "✅ 找到 $($allBackupFolders.Count) 個備份資料夾`n" -ForegroundColor Green
    }

    # 篩選出需要刪除的舊資料夾
    $oldBackupFolders = $allBackupFolders | Where-Object {
        try {
            $folderDate = [DateTime]::ParseExact($_.Name, "yyyyMMdd", $null)
            $folderDate -lt $cutoffDate
        } catch {
            $false
        }
    }

    if ($oldBackupFolders.Count -eq 0) {
        if ($Verbose) {
            Write-Host "✅ 沒有需要清理的舊備份 (全部都在 $RetentionDays 天內)`n" -ForegroundColor Green
        }

        $report = @{
            Timestamp = $timestamp
            Success = $true
            Message = "沒有需要清理的舊備份"
            BackupPath = $BackupPath
            TotalFolders = $allBackupFolders.Count
            DeletedFolders = 0
            DeletedFiles = 0
            FreedSpaceMB = 0
        }
        Write-Output ($report | ConvertTo-Json -Depth 5)
        exit 0
    }

    if ($Verbose) {
        Write-Host "🗑️  找到 $($oldBackupFolders.Count) 個需要刪除的舊備份資料夾:`n" -ForegroundColor Yellow
    }

} catch {
    if ($Verbose) {
        Write-Host "❌ 掃描失敗: $($_.Exception.Message)`n" -ForegroundColor Red
    }

    $report = @{
        Timestamp = $timestamp
        Success = $false
        Error = "掃描失敗"
        Message = $_.Exception.Message
    }
    Write-Output ($report | ConvertTo-Json -Depth 5)
    exit 1
}

# ========================================
# 3. 刪除舊備份資料夾
# ========================================
foreach ($folder in $oldBackupFolders) {
    try {
        $folderDate = [DateTime]::ParseExact($folder.Name, "yyyyMMdd", $null)
        $daysOld = [math]::Floor((Get-Date - $folderDate).TotalDays)

        # 計算資料夾大小和檔案數
        $files = Get-ChildItem -Path $folder.FullName -Recurse -File
        $fileCount = $files.Count
        $folderSize = ($files | Measure-Object -Property Length -Sum).Sum

        if ($folderSize -eq $null) {
            $folderSize = 0
        }

        $folderSizeMB = [math]::Round($folderSize / 1MB, 2)

        if ($Verbose) {
            Write-Host "📁 $($folder.Name) ($($folderDate.ToString('yyyy-MM-dd'))) - $daysOld 天前" -ForegroundColor Yellow
            Write-Host "   檔案數: $fileCount" -ForegroundColor Gray
            Write-Host "   大小: $folderSizeMB MB" -ForegroundColor Gray
        }

        if ($WhatIf) {
            if ($Verbose) {
                Write-Host "   [預覽] 將會刪除此資料夾`n" -ForegroundColor Cyan
            }
        } else {
            # 實際刪除
            Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction Stop

            if ($Verbose) {
                Write-Host "   ✅ 已刪除`n" -ForegroundColor Green
            }
        }

        # 記錄
        $deletedFolders += @{
            FolderName = $folder.Name
            Date = $folderDate.ToString('yyyy-MM-dd')
            DaysOld = $daysOld
            FileCount = $fileCount
            SizeMB = $folderSizeMB
            Path = $folder.FullName
        }

        $totalDeletedSize += $folderSize
        $totalDeletedFiles += $fileCount

    } catch {
        if ($Verbose) {
            Write-Host "   ❌ 刪除失敗: $($_.Exception.Message)`n" -ForegroundColor Red
        }
    }
}

# ========================================
# 4. 生成報告
# ========================================
$totalDeletedSizeMB = [math]::Round($totalDeletedSize / 1MB, 2)

$report = @{
    Timestamp = $timestamp
    Success = $true
    BackupPath = $BackupPath
    RetentionDays = $RetentionDays
    CutoffDate = $cutoffDate.ToString('yyyy-MM-dd')
    TotalFolders = $allBackupFolders.Count
    DeletedFolders = $deletedFolders.Count
    DeletedFiles = $totalDeletedFiles
    FreedSpaceMB = $totalDeletedSizeMB
    DeletedItems = $deletedFolders
    WhatIf = $WhatIf.IsPresent
}

$reportJson = $report | ConvertTo-Json -Depth 10 -Compress:$false

# ========================================
# 5. 儲存日誌
# ========================================
if (!$WhatIf) {
    try {
        $logDir = "C:\mis-assistant\logs"
        if (!(Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }

        $logFile = Join-Path $logDir "cleanup-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
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
# 6. 輸出摘要 (Verbose 模式)
# ========================================
if ($Verbose) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  📊 清理報告摘要" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "執行時間: $timestamp" -ForegroundColor White
    Write-Host "備份資料夾總數: $($allBackupFolders.Count)" -ForegroundColor White
    Write-Host "$(if ($WhatIf) { '將會刪除' } else { '已刪除' }): $($deletedFolders.Count) 個資料夾" -ForegroundColor $(if ($deletedFolders.Count -gt 0) { "Yellow" } else { "Green" })
    Write-Host "$(if ($WhatIf) { '將會刪除' } else { '已刪除' }): $totalDeletedFiles 個檔案" -ForegroundColor $(if ($totalDeletedFiles -gt 0) { "Yellow" } else { "Green" })
    Write-Host "$(if ($WhatIf) { '將會釋放' } else { '已釋放' }): $totalDeletedSizeMB MB" -ForegroundColor $(if ($totalDeletedSizeMB -gt 0) { "Yellow" } else { "Green" })
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

# ========================================
# 7. 輸出 JSON
# ========================================
Write-Output $reportJson

# ========================================
# 8. 設定退出碼
# ========================================
exit 0
