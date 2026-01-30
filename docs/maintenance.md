# MIS 自動化助理系統 - 維護指南

本指南提供系統的日常維護、定期檢查和更新說明,確保系統長期穩定運行。

---

## 維護概覽

### 維護頻率

| 維護項目 | 頻率 | 所需時間 | 說明 |
|---------|------|---------|------|
| 檢查 Telegram 通知 | 每天 | 1 分鐘 | 確認監控正常運作 |
| 檢查備份完整性 | 每週 | 5 分鐘 | 驗證備份檔案存在 |
| 測試備份還原 | 每月 | 15 分鐘 | 確保備份可用 |
| 清理舊日誌 | 每月 | 2 分鐘 | 釋放磁碟空間 |
| 更新 Docker 映像 | 每月 | 10 分鐘 | 獲取最新功能和安全更新 |
| 匯出 n8n 工作流程 | 每月 | 5 分鐘 | 備份自動化設定 |
| 檢查 API 配額 | 每週 | 2 分鐘 | 確保未超過限制 |
| 系統完整檢查 | 每季 | 30 分鐘 | 全面健康檢查 |

---

## 每日維護

### 1. 檢查 Telegram 監控通知

**目的**: 確認 Docker 容器監控正常運作

**步驟**:
1. 檢查 Telegram 是否收到監控報告 (每 3 分鐘一次)
2. 查看是否有警報或警告
3. 如果有異常,立即處理

**正常情況**:
- 收到定期的容器狀態報告
- 所有容器都在運行
- CPU/記憶體使用率在閾值內
- 磁碟空間充足

**異常情況處理**:
- **收不到通知**: 檢查 n8n 容器是否運行,檢查網路連線
- **容器停止**: 手動重啟容器或檢查容器日誌
- **資源使用率高**: 檢查是否有程式異常,考慮重啟

### 2. 檢查備份執行

**目的**: 確認凌晨 2:00 的自動備份成功

**步驟**:
1. 檢查 Telegram 是否收到備份完成通知
2. 查看備份資料夾:
   ```powershell
   Get-ChildItem C:\mis-assistant\backups -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 3
   ```

**預期結果**:
- 最新的備份資料夾日期為今天
- 包含所有 MySQL 容器的備份檔案
- 備份檔案大小合理 (非 0 KB)

---

## 每週維護

### 1. 檢查備份完整性

**目的**: 確保備份檔案可用且完整

**步驟**:

```powershell
# 列出最近 7 天的備份
$backupPath = "C:\mis-assistant\backups"
Get-ChildItem $backupPath -Directory |
    Where-Object { $_.Name -match '^\d{8}$' } |
    Sort-Object Name -Descending |
    Select-Object -First 7 |
    ForEach-Object {
        $files = Get-ChildItem $_.FullName -File
        $totalSize = ($files | Measure-Object -Property Length -Sum).Sum / 1MB
        [PSCustomObject]@{
            Date = $_.Name
            FileCount = $files.Count
            TotalSizeMB = [math]::Round($totalSize, 2)
        }
    } | Format-Table
```

**檢查項目**:
- [ ] 是否有 7 天的備份?
- [ ] 每天的備份檔案數量是否一致?
- [ ] 檔案大小是否合理 (沒有突然變小)?
- [ ] 舊備份是否被正確清理?

### 2. 檢查 API 配額使用情況

**Groq API**:
1. 登入 https://console.groq.com
2. 點選左側 "Usage"
3. 查看本週的請求數

**預期使用量**:
- 每天約 15-30 次請求
- 每週約 100-200 次請求

如果超過預期,檢查 n8n 工作流程是否有異常觸發。

### 3. 檢查磁碟空間

```powershell
# 檢查磁碟使用情況
$drive = Get-PSDrive C
$freePercent = [math]::Round(($drive.Free / ($drive.Used + $drive.Free)) * 100, 2)
Write-Host "C: 磁碟可用空間: $freePercent%"

# 檢查備份佔用空間
$backupSize = (Get-ChildItem C:\mis-assistant\backups -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1GB
Write-Host "備份總大小: $([math]::Round($backupSize, 2)) GB"

# 檢查日誌佔用空間
$logSize = (Get-ChildItem C:\mis-assistant\logs -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "日誌總大小: $([math]::Round($logSize, 2)) MB"
```

**建議**:
- 備份大小不應超過 50GB
- 日誌大小不應超過 500MB
- 磁碟可用空間應保持 > 20%

---

## 每月維護

### 1. 測試備份還原

**目的**: 確保備份真的可以還原 (最重要!)

**步驟**:

```powershell
# 1. 選擇一個備份檔案
$backupFile = "C:\mis-assistant\backups\20260128\laravel_test.sql.gz"

# 2. 解壓縮
$extractPath = "C:\mis-assistant\backups\test-restore.sql"
$sourceStream = [System.IO.File]::OpenRead($backupFile)
$targetStream = [System.IO.File]::Create($extractPath)
$gzipStream = New-Object System.IO.Compression.GZipStream($sourceStream, [System.IO.Compression.CompressionMode]::Decompress)
$gzipStream.CopyTo($targetStream)
$gzipStream.Close()
$targetStream.Close()
$sourceStream.Close()

# 3. 查看檔案內容
Get-Content $extractPath -TotalCount 50

# 4. 清理測試檔案
Remove-Item $extractPath
```

如果能成功解壓並看到 SQL 語句,表示備份檔案正常。

### 2. 匯出 n8n 工作流程 (重要!)

**目的**: 備份你的自動化設定

**方法 1: 使用 n8n UI**
1. 開啟 http://localhost:5678
2. 進入每個工作流程
3. 點選右上角 "..." → "Download"
4. 儲存到安全的地方

**方法 2: 使用 CLI**
```powershell
docker-compose exec n8n n8n export:workflow --all --output=/workflows/backup-$(Get-Date -Format 'yyyyMMdd').json
```

備份檔案會儲存在容器內,需要複製出來:
```powershell
docker cp n8n-mis:/workflows/backup-20260128.json C:\mis-assistant\backups\
```

### 3. 更新 Docker 映像

**目的**: 獲取最新的安全更新和功能

**步驟**:

```powershell
# 1. 進入專案目錄
cd C:\mis-assistant

# 2. 備份當前配置 (以防萬一)
Copy-Item docker-compose.yml docker-compose.yml.backup

# 3. 停止服務
docker-compose down

# 4. 拉取最新映像
docker-compose pull

# 5. 重新啟動服務
docker-compose up -d

# 6. 檢查服務狀態
docker-compose ps

# 7. 查看日誌
docker-compose logs -f --tail=50 n8n
```

**注意事項**:
- 更新前先備份 n8n 工作流程
- 更新後測試所有工作流程是否正常
- 如果有問題,可以回滾到舊版本

**回滾方法**:
```powershell
# 指定舊版本號
docker-compose down
# 編輯 docker-compose.yml,將 n8nio/n8n:latest 改為 n8nio/n8n:1.20.0
docker-compose up -d
```

### 4. 清理舊日誌

**目的**: 釋放磁碟空間

```powershell
# 刪除 30 天前的日誌
$logPath = "C:\mis-assistant\logs"
$cutoffDate = (Get-Date).AddDays(-30)

Get-ChildItem $logPath -File |
    Where-Object { $_.LastWriteTime -lt $cutoffDate } |
    ForEach-Object {
        Write-Host "刪除舊日誌: $($_.Name)" -ForegroundColor Yellow
        Remove-Item $_.FullName -Force
    }
```

或使用清理腳本:
```powershell
powershell.exe -ExecutionPolicy Bypass -File C:\mis-assistant\scripts\cleanup-old-backups.ps1 -Verbose
```

### 5. 檢查容器健康狀態

```powershell
# 檢查所有容器的重啟次數
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.RestartCount}}" | Sort-Object

# 檢查 Docker 日誌錯誤
docker-compose logs --tail=100 | Select-String -Pattern "error|ERROR|fatal|FATAL"
```

**警告信號**:
- 任何容器的重啟次數 > 5
- 日誌中頻繁出現錯誤訊息
- 容器經常處於 unhealthy 狀態

---

## 每季維護

### 1. 系統完整健康檢查

**執行完整測試**:
```powershell
cd C:\mis-assistant
.\test-all.ps1 -Verbose
```

檢查所有項目是否通過。

### 2. 審查自動化工作流程

**檢查項目**:
- [ ] 監控閾值是否需要調整?
- [ ] 備份保留天數是否合適?
- [ ] 新聞來源是否需要更新?
- [ ] 工作流程是否有優化空間?

### 3. 安全檢查

```powershell
# 檢查 .env 檔案權限
Get-Acl C:\mis-assistant\.env | Format-List

# 檢查是否有不必要的連接埠開放
netstat -ano | Select-String -Pattern "5678|8080"

# 檢查 Docker 映像安全性 (使用 Docker Scout)
docker scout cves n8nio/n8n:latest
```

### 4. 效能優化

```powershell
# 清理 Docker 系統
docker system prune -a --volumes

# 壓縮 n8n 資料庫 (如果使用 SQLite)
docker-compose exec n8n sqlite3 /home/node/.n8n/database.sqlite "VACUUM;"
```

---

## 緊急維護

### 當系統出現問題時

#### 1. 快速診斷

```powershell
# 檢查所有服務狀態
docker-compose ps

# 查看最近的錯誤
docker-compose logs --tail=100 | Select-String "ERROR"

# 執行健康檢查
.\test-all.ps1
```

#### 2. 重啟服務

```powershell
# 重啟 n8n
docker-compose restart n8n

# 完整重啟所有服務
docker-compose down && docker-compose up -d
```

#### 3. 檢查網路連線

```powershell
# 測試 Groq API
Invoke-WebRequest -Uri "https://api.groq.com" -Method GET

# 測試 Telegram API
Invoke-WebRequest -Uri "https://api.telegram.org" -Method GET
```

---

## 維護檢查清單範本

複製並填寫:

```
# MIS 自動化助理系統 - 每月維護記錄

**維護日期**: ___________
**維護人員**: ___________

## 檢查項目

### 系統運作
- [ ] 所有 Docker 容器運行正常
- [ ] n8n 工作流程全部激活
- [ ] 收到每日監控通知
- [ ] 收到每日新聞摘要
- [ ] 備份正常執行

### 備份檢查
- [ ] 最近 7 天備份完整
- [ ] 測試還原一個備份檔案
- [ ] 備份檔案大小正常
- [ ] 舊備份正確清理

### 資源使用
- [ ] 磁碟空間充足 (> 20%)
- [ ] 記憶體使用正常
- [ ] CPU 使用正常
- [ ] 備份總大小 < 50GB
- [ ] 日誌總大小 < 500MB

### API 配額
- [ ] Groq API 使用量 < 80%
- [ ] Telegram API 正常運作

### 更新與備份
- [ ] Docker 映像已更新
- [ ] n8n 工作流程已匯出
- [ ] .env 檔案已備份

### 其他
- [ ] 閱讀系統日誌無異常
- [ ] 清理 30 天前的日誌
- [ ] 檢查並修正發現的問題

## 發現的問題

1. ___________
2. ___________

## 已修正的問題

1. ___________
2. ___________

## 建議改進

1. ___________
2. ___________

**簽名**: ___________
```

---

## 維護最佳實踐

### 1. 保持記錄

建立維護日誌,記錄:
- 維護日期和時間
- 執行的操作
- 發現的問題
- 解決方案

### 2. 定期審查

每季度審查:
- 系統是否達成目標?
- 有哪些可以改進?
- 是否需要新功能?

### 3. 保持更新

訂閱相關資源:
- [n8n 更新日誌](https://github.com/n8n-io/n8n/releases)
- [Docker 安全公告](https://www.docker.com/blog/)
- [Groq 狀態頁面](https://status.groq.com)

### 4. 備份策略

遵循 3-2-1 原則:
- **3** 份備份
- **2** 種不同媒體
- **1** 份異地備份

建議:
- 主要: NUC 本機備份
- 次要: 定期複製到外接硬碟
- 異地: 上傳關鍵備份到 Google Drive (可選)

---

## 自動化維護

### 建立每月維護腳本

建立 `C:\mis-assistant\scripts\monthly-maintenance.ps1`:

```powershell
Write-Host "開始每月維護..." -ForegroundColor Cyan

# 1. 匯出 n8n 工作流程
Write-Host "`n1. 匯出 n8n 工作流程..."
docker-compose exec n8n n8n export:workflow --all --output=/workflows/backup-$(Get-Date -Format 'yyyyMMdd').json

# 2. 清理舊日誌
Write-Host "`n2. 清理舊日誌..."
.\scripts\cleanup-old-backups.ps1 -Verbose

# 3. 檢查系統健康
Write-Host "`n3. 執行系統健康檢查..."
.\test-all.ps1

# 4. 顯示統計資訊
Write-Host "`n4. 系統統計:"
$backupSize = (Get-ChildItem .\backups -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1GB
Write-Host "備份總大小: $([math]::Round($backupSize, 2)) GB"

$logSize = (Get-ChildItem .\logs -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "日誌總大小: $([math]::Round($logSize, 2)) MB"

Write-Host "`n每月維護完成!" -ForegroundColor Green
```

在每月第一天執行:
```powershell
cd C:\mis-assistant
.\scripts\monthly-maintenance.ps1
```

---

## 總結

定期維護能確保系統:
- ✅ 持續穩定運行
- ✅ 備份可靠可用
- ✅ 及時發現問題
- ✅ 保持最佳效能

**記住**: 最好的維護是預防性維護,而不是等問題發生後才處理!

---

**相關資源**:
- [故障排除指南](troubleshooting.md)
- [系統 README](../README.md)
