# MIS 自動化助理系統 - 故障排除指南

遇到問題了?這份指南提供常見問題的解決方案和診斷步驟。

---

## 🔍 快速診斷

當系統出現問題時,先執行快速診斷:

```powershell
cd C:\mis-assistant

# 1. 檢查所有服務狀態
docker-compose ps

# 2. 執行完整測試
.\test-all.ps1

# 3. 查看最近錯誤
docker-compose logs --tail=100 | Select-String "ERROR|FATAL"
```

---

## 問題分類

### 🔴 緊急問題 (立即需要修復)
- n8n 容器無法啟動
- 所有 Docker 容器停止
- 收不到任何 Telegram 通知
- 備份完全失敗

### 🟡 重要問題 (需要盡快處理)
- 部分容器異常
- 備份部分失敗
- API 調用失敗
- 監控漏報

### 🟢 一般問題 (可稍後處理)
- 效能輕微下降
- 日誌檔案過大
- 工作流程需要優化

---

## 常見問題與解決方案

### 1. n8n 問題

#### 問題 1.1: n8n 容器無法啟動

**症狀**:
- `docker-compose ps` 顯示 n8n 容器 Exit 或 Restarting
- 無法訪問 http://localhost:5678

**診斷**:
```powershell
# 查看詳細錯誤
docker-compose logs n8n --tail=50
```

**可能原因與解決方案**:

**原因 A: 連接埠被佔用**
```powershell
# 檢查 5678 連接埠
netstat -ano | findstr :5678

# 解決方式 1: 關閉佔用的程式
# 找到 PID 後
taskkill /PID <PID> /F

# 解決方式 2: 更改 n8n 連接埠
# 編輯 docker-compose.yml
ports:
  - "5679:5678"  # 改用 5679
```

**原因 B: .env 檔案錯誤**
```powershell
# 檢查 .env 檔案
Get-Content C:\mis-assistant\.env

# 確認必要變數存在
N8N_USER=...
N8N_PASSWORD=...
```

**原因 C: Volume 權限問題**
```powershell
# 刪除舊的 volume 重新建立
docker-compose down -v
docker-compose up -d
```

**原因 D: 記憶體不足**
```powershell
# 檢查可用記憶體
Get-CimInstance Win32_OperatingSystem | Select FreePhysicalMemory

# 解決: 減少 docker-compose.yml 中的記憶體限制
memory: 1G  # 從 2G 改為 1G
```

#### 問題 1.2: n8n Web 介面無法載入

**症狀**:
- 容器運行正常
- 瀏覽器顯示 "無法連線" 或一直載入

**解決方案**:

```powershell
# 1. 檢查容器健康狀態
docker inspect n8n-mis | Select-String -Pattern "Health"

# 2. 重啟容器
docker-compose restart n8n

# 3. 等待 30 秒後測試
Start-Sleep -Seconds 30
Invoke-WebRequest -Uri "http://localhost:5678" -Method GET

# 4. 清除瀏覽器快取
# Chrome: Ctrl+Shift+Delete
# Edge: Ctrl+Shift+Delete
```

#### 問題 1.3: n8n 工作流程無法執行

**症狀**:
- 工作流程沒有自動觸發
- 手動執行顯示錯誤

**診斷步驟**:

1. **檢查工作流程是否啟動**
   - 在 n8n UI 右上角確認 "Active" 開關是開啟的

2. **檢查錯誤訊息**
   - 點選工作流程節點查看錯誤詳情
   - 查看 Executions 頁面的錯誤日誌

3. **測試個別節點**
   - 點選節點
   - 點選 "Execute Node"
   - 查看輸出

**常見錯誤**:

**錯誤: "Cannot find module"**
```
解決: 重啟 n8n 容器
docker-compose restart n8n
```

**錯誤: "Timeout"**
```
解決: 增加 timeout 設定或檢查網路連線
```

**錯誤: "Unauthorized"**
```
解決: 檢查 API 金鑰是否正確
```

---

### 2. Docker 監控問題

#### 問題 2.1: 收不到監控通知

**症狀**:
- Telegram 沒有收到任何監控訊息

**診斷與解決**:

```powershell
# 1. 檢查 n8n 容器運行狀態
docker ps | findstr n8n

# 2. 檢查監控工作流程是否啟動
# 在 n8n UI 中查看 "1-docker-monitor" 工作流程

# 3. 手動執行監控腳本測試
powershell.exe -ExecutionPolicy Bypass -File C:\mis-assistant\scripts\docker-monitor.ps1 -Verbose

# 4. 檢查 Telegram 設定
# 在 n8n 的 Telegram 節點中測試發送
```

**如果腳本正常但 n8n 不執行**:
- 檢查 Schedule Trigger 設定
- 檢查工作流程的 Execute Command 節點路徑
- 查看 n8n 日誌: `docker-compose logs n8n | Select-String "monitor"`

#### 問題 2.2: 監控腳本執行失敗

**症狀**:
- 工作流程顯示錯誤
- 監控日誌沒有生成

**診斷**:
```powershell
# 手動執行並查看錯誤
powershell.exe -ExecutionPolicy Bypass -File C:\mis-assistant\scripts\docker-monitor.ps1 -Verbose
```

**常見錯誤**:

**錯誤: "Docker daemon not running"**
```
解決: 啟動 Docker Desktop
```

**錯誤: "Access denied"**
```
解決: 確保 n8n 容器有存取 Docker socket 的權限
檢查 docker-compose.yml 中的 volume 掛載:
- //./pipe/docker_engine://./pipe/docker_engine
```

**錯誤: "Cannot find path"**
```
解決: 檢查腳本路徑
確認 scripts 目錄已正確掛載到容器
```

---

### 3. 資料庫備份問題

#### 問題 3.1: 備份完全沒有執行

**症狀**:
- 凌晨 2:00 沒有收到通知
- backups 目錄是空的

**診斷**:

```powershell
# 1. 檢查備份工作流程
# 在 n8n UI 查看 "2-database-backup" 是否啟動

# 2. 檢查 Cron 設定
# 確認是 "0 2 * * *" (每天 02:00)

# 3. 手動執行測試
powershell.exe -ExecutionPolicy Bypass -File C:\mis-assistant\scripts\backup-databases.ps1 -Verbose

# 4. 查看 n8n 執行歷史
# Executions → 篩選 "database-backup"
```

#### 問題 3.2: 備份部分失敗

**症狀**:
- 收到通知但部分資料庫備份失敗
- 備份檔案不完整

**診斷**:
```powershell
# 查看備份日誌
$latestLog = Get-ChildItem C:\mis-assistant\logs\backup-*.json | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Get-Content $latestLog | ConvertFrom-Json | ConvertTo-Json -Depth 10

# 檢查失敗的資料庫
```

**常見原因**:

**原因 A: MySQL 容器沒有運行**
```powershell
docker ps | findstr mysql
# 如果沒有,啟動容器
docker start <container-name>
```

**原因 B: MySQL 密碼錯誤**
```powershell
# 測試連線
docker exec <mysql-container> mysql -uroot -p<password> -e "SHOW DATABASES;"
```

**原因 C: 磁碟空間不足**
```powershell
# 檢查空間
Get-PSDrive C
```

#### 問題 3.3: 備份檔案無法解壓

**症狀**:
- 備份檔案存在
- 解壓縮時報錯

**解決**:
```powershell
# 測試解壓
$testFile = "C:\mis-assistant\backups\20260128\test.sql.gz"

try {
    $sourceStream = [System.IO.File]::OpenRead($testFile)
    $targetStream = [System.IO.File]::Create("$testFile.uncompressed")
    $gzipStream = New-Object System.IO.Compression.GZipStream($sourceStream, [System.IO.Compression.CompressionMode]::Decompress)
    $gzipStream.CopyTo($targetStream)
    $gzipStream.Close()
    $targetStream.Close()
    $sourceStream.Close()
    Write-Host "解壓成功!" -ForegroundColor Green
} catch {
    Write-Host "解壓失敗: $($_.Exception.Message)" -ForegroundColor Red
}
```

如果失敗,備份檔案可能已損壞。檢查:
- 備份時磁碟是否有足夠空間
- 備份過程是否被中斷
- 重新執行備份

---

### 4. Telegram 問題

#### 問題 4.1: Bot 完全收不到訊息

**症狀**:
- Telegram 沒有任何通知
- 測試發送也失敗

**診斷與解決**:

```powershell
# 1. 測試 Telegram API 連線
$botToken = "YOUR_BOT_TOKEN"
Invoke-WebRequest -Uri "https://api.telegram.org/bot$botToken/getMe" -Method GET

# 如果失敗,檢查:
# - Bot Token 是否正確
# - 網路連線是否正常
# - 是否被防火牆阻擋

# 2. 檢查 Chat ID
$chatId = "YOUR_CHAT_ID"
$url = "https://api.telegram.org/bot$botToken/sendMessage"
$body = @{
    chat_id = $chatId
    text = "Test message"
} | ConvertTo-Json

Invoke-RestMethod -Uri $url -Method POST -ContentType "application/json" -Body $body
```

**常見問題**:

**問題: "Unauthorized"**
- Bot Token 錯誤
- 複製時多了空格或少了字元
- 解決: 重新從 BotFather 取得 Token

**問題: "Chat not found"**
- Chat ID 錯誤
- 沒有先對 Bot 發送 /start
- 解決:
  1. 在 Telegram 找到你的 Bot
  2. 發送 /start
  3. 重新取得 Chat ID

**問題: "Bad Gateway" / "Timeout"**
- 網路問題
- Telegram 伺服器暫時故障
- 解決: 等待幾分鐘後重試

#### 問題 4.2: n8n 中 Telegram 節點失敗

**症狀**:
- 工作流程執行到 Telegram 節點時失敗

**解決**:

1. **檢查 Telegram 憑證設定**
   - 在 n8n 左側選單點選 "Credentials"
   - 檢查 Telegram API Credentials
   - 確認 Access Token 正確

2. **測試 Telegram 節點**
   - 建立測試工作流程
   - 只包含一個 Telegram 節點
   - 手動執行測試

3. **查看錯誤訊息**
   - 點選失敗的節點
   - 查看詳細錯誤資訊
   - 根據錯誤訊息處理

---

### 5. Groq API 問題

#### 問題 5.1: API 調用失敗

**症狀**:
- 會議記錄整理失敗
- 新聞翻譯失敗

**診斷**:
```powershell
# 測試 Groq API
$apiKey = "YOUR_GROQ_API_KEY"

$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type" = "application/json"
}

$body = @{
    model = "llama-3.3-70b-versatile"
    messages = @(
        @{
            role = "user"
            content = "Test"
        }
    )
    max_tokens = 10
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "https://api.groq.com/openai/v1/chat/completions" -Method POST -Headers $headers -Body $body
    Write-Host "API 調用成功!" -ForegroundColor Green
    $response.choices[0].message.content
} catch {
    Write-Host "API 調用失敗: $($_.Exception.Message)" -ForegroundColor Red
}
```

**常見錯誤**:

**錯誤 401: "Invalid API Key"**
- API Key 錯誤或過期
- 解決:
  1. 登入 https://console.groq.com
  2. 重新生成 API Key
  3. 更新 .env 檔案

**錯誤 429: "Too Many Requests"**
- 超過請求限制 (30/分鐘)
- 解決:
  1. 等待一分鐘
  2. 減少請求頻率
  3. 在 n8n 中加入 Delay 節點

**錯誤 500: "Internal Server Error"**
- Groq 伺服器問題
- 解決:
  1. 檢查 https://status.groq.com
  2. 等待幾分鐘後重試
  3. 暫時禁用相關工作流程

#### 問題 5.2: AI 輸出格式不正確

**症狀**:
- AI 回覆但格式混亂
- 無法解析 AI 輸出

**解決**:

1. **優化 Prompt**
   ```javascript
   // 在 n8n 的 HTTP Request 節點中
   {
     "messages": [
       {
         "role": "system",
         "content": "你必須只回傳 JSON 格式,不要其他文字。"
       },
       {
         "role": "user",
         "content": "..."
       }
     ]
   }
   ```

2. **降低 Temperature**
   - 從 0.7 改為 0.3
   - 獲得更穩定的輸出

3. **增加範例**
   - 在 Prompt 中提供輸出範例
   - AI 會更容易理解預期格式

---

### 6. PowerShell 腳本問題

#### 問題 6.1: 腳本無法執行

**症狀**:
- 雙擊腳本沒反應
- 或顯示 "無法載入"

**解決**:

```powershell
# 檢查執行政策
Get-ExecutionPolicy

# 如果是 Restricted,改為 RemoteSigned
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# 或使用 Bypass 執行
powershell.exe -ExecutionPolicy Bypass -File "C:\mis-assistant\scripts\docker-monitor.ps1"
```

#### 問題 6.2: 腳本輸出亂碼

**症狀**:
- 中文顯示為問號或亂碼

**解決**:
```powershell
# 設定控制台編碼
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001

# 重新執行腳本
.\scripts\docker-monitor.ps1 -Verbose
```

---

### 7. 效能問題

#### 問題 7.1: n8n 回應緩慢

**症狀**:
- Web 介面載入慢
- 工作流程執行慢

**診斷**:
```powershell
# 檢查容器資源使用
docker stats --no-stream n8n-mis

# 檢查系統資源
Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
Get-CimInstance Win32_OperatingSystem | Select FreePhysicalMemory,TotalVisibleMemorySize
```

**解決方案**:

1. **增加容器資源**
   ```yaml
   # docker-compose.yml
   deploy:
     resources:
       limits:
         cpus: '3.0'  # 從 2.0 增加到 3.0
         memory: 3G   # 從 2G 增加到 3G
   ```

2. **清理 n8n 執行歷史**
   - 在 n8n UI: Settings → Executions
   - 設定自動清理舊執行記錄
   - 或手動刪除舊記錄

3. **優化工作流程**
   - 減少不必要的節點
   - 使用 Split In Batches 處理大量資料
   - 加入延遲避免 API 限制

#### 問題 7.2: Docker 整體效能下降

**症狀**:
- 所有容器都變慢
- 系統回應遲緩

**解決**:
```powershell
# 1. 清理 Docker 系統
docker system prune -a --volumes

# 2. 重啟 Docker Desktop

# 3. 減少運行中的容器數量
docker stop <不必要的容器>

# 4. 檢查磁碟空間
Get-PSDrive C
```

---

## 🆘 緊急恢復程序

當系統完全無法運作時:

### 步驟 1: 完全停止

```powershell
cd C:\mis-assistant
docker-compose down
```

### 步驟 2: 備份重要資料

```powershell
# 備份 n8n 工作流程
docker-compose up n8n -d
docker-compose exec n8n n8n export:workflow --all --output=/workflows/emergency-backup.json
docker cp n8n-mis:/workflows/emergency-backup.json ./emergency-backup.json
docker-compose down

# 備份 .env
Copy-Item .env .env.emergency.backup
```

### 步驟 3: 清理並重建

```powershell
# 刪除所有 volume
docker-compose down -v

# 重新啟動
docker-compose up -d

# 等待服務啟動
Start-Sleep -Seconds 30

# 檢查狀態
docker-compose ps
```

### 步驟 4: 恢復工作流程

1. 開啟 http://localhost:5678
2. 重新設定憑證 (Telegram, Groq)
3. 匯入工作流程
   - 從 emergency-backup.json
   - 或從 workflows/*.json
4. 啟動所有工作流程

### 步驟 5: 測試驗證

```powershell
.\test-all.ps1
```

---

## 📞 取得協助

### 檢查日誌

```powershell
# n8n 日誌
docker-compose logs n8n --tail=100

# 所有服務日誌
docker-compose logs --tail=100

# 特定容器日誌
docker-compose logs <container-name> --tail=50 --follow
```

### 產生診斷報告

```powershell
# 建立診斷報告
$reportPath = "C:\mis-assistant\logs\diagnostic-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

@"
=== MIS Assistant 診斷報告 ===
生成時間: $(Get-Date)

=== 系統資訊 ===
$(systeminfo | Select-String "OS Name|OS Version|System Type")

=== Docker 版本 ===
$(docker --version)
$(docker-compose --version)

=== 容器狀態 ===
$(docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}")

=== n8n 日誌 (最近 50 行) ===
$(docker-compose logs n8n --tail=50)

=== 磁碟空間 ===
$(Get-PSDrive C | Format-Table)

=== 測試結果 ===
$(.\test-all.ps1)
"@ | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "診斷報告已生成: $reportPath" -ForegroundColor Cyan
```

### 尋求社群協助

- [n8n 社群論壇](https://community.n8n.io/)
- [n8n GitHub Issues](https://github.com/n8n-io/n8n/issues)
- [Docker 文件](https://docs.docker.com/)

---

## 預防措施

### 定期檢查

- 每週執行 `test-all.ps1`
- 每月測試備份還原
- 每季更新 Docker 映像

### 保持備份

- 定期匯出 n8n 工作流程
- 備份 .env 檔案
- 測試備份可用性

### 監控警報

- 注意 Telegram 通知
- 檢查異常警報
- 及時處理問題

---

**記住: 遇到問題不要慌,按照步驟診斷,通常都能解決!** 💪

---

**相關文件**:
- [維護指南](maintenance.md)
- [系統 README](../README.md)
