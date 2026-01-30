# 🚀 MIS 自動化助理系統 - 部署檢查清單

完成日期: ___________
部署人員: ___________

---

## ✅ Phase 1: 環境準備 (15 分鐘)

### 1.1 系統需求檢查
- [ ] Windows 11 Pro 已安裝
- [ ] Docker Desktop 已安裝並運行 (版本 >= 4.0)
- [ ] WSL2 已啟用
- [ ] PowerShell 7+ 已安裝 (可選,系統內建的也可用)
- [ ] 至少 10GB 可用磁碟空間
- [ ] 網路連線正常

**驗證指令:**
```powershell
# 檢查 Docker
docker --version
docker-compose --version
docker ps

# 檢查磁碟空間
Get-PSDrive C
```

### 1.2 目錄結構建立
- [ ] 主目錄已建立: `C:\mis-assistant`
- [ ] 子目錄已建立:
  - [ ] `workflows/` - n8n 工作流程定義
  - [ ] `scripts/` - PowerShell 監控腳本
  - [ ] `backups/` - 資料庫備份儲存
  - [ ] `logs/` - 系統日誌
  - [ ] `docs/` - 說明文件

**驗證指令:**
```powershell
Get-ChildItem C:\mis-assistant -Directory
```

### 1.3 初始檔案建立
- [ ] `.env.example` 已建立
- [ ] `docker-compose.yml` 已建立
- [ ] `CHECKLIST.md` 已建立 (本檔案)

---

## ✅ Phase 2: API 金鑰申請 (10 分鐘)

### 2.1 Groq API 金鑰
- [ ] 前往 https://console.groq.com
- [ ] 使用 Google/GitHub 帳號註冊登入
- [ ] 點選左側 "API Keys"
- [ ] 點選 "Create API Key"
- [ ] 複製金鑰 (格式: `gsk_...`)
- [ ] 妥善保存金鑰 (只顯示一次!)

**免費額度:**
- 30 requests/minute
- 14,400 requests/day
- 足夠個人使用

### 2.2 Telegram Bot 建立
- [ ] 在 Telegram 搜尋 `@BotFather`
- [ ] 發送指令: `/newbot`
- [ ] 設定 Bot 名稱 (例如: MIS Assistant)
- [ ] 設定 Bot 用戶名 (例如: my_mis_assistant_bot)
- [ ] 複製 Bot Token (格式: `1234567890:ABCdef...`)
- [ ] 發送 `/setcommands` 設定指令清單 (可選)

**建議指令清單:**
```
status - 查看系統狀態
logs - 查看最新日誌
restart - 重啟異常容器
backup - 手動執行備份
help - 顯示幫助訊息
```

### 2.3 取得 Telegram Chat ID
- [ ] 在 Telegram 搜尋 `@userinfobot`
- [ ] 發送任意訊息給它
- [ ] 複製你的 User ID (純數字,例如: 123456789)
- [ ] 或在 Telegram 搜尋你剛建立的 Bot
- [ ] 對 Bot 發送 `/start` 啟動對話

### 2.4 建立 .env 檔案
- [ ] 複製 `.env.example` 為 `.env`
- [ ] 填入 `GROQ_API_KEY`
- [ ] 填入 `TELEGRAM_BOT_TOKEN`
- [ ] 填入 `TELEGRAM_CHAT_ID`
- [ ] 設定 `N8N_PASSWORD` (至少 16 字元)
- [ ] 檢查其他參數是否需要調整

**驗證指令:**
```powershell
# 檢查 .env 檔案存在且包含必要變數
Get-Content C:\mis-assistant\.env | Select-String -Pattern "GROQ_API_KEY|TELEGRAM_BOT_TOKEN|TELEGRAM_CHAT_ID|N8N_PASSWORD"
```

---

## ✅ Phase 3: 核心腳本建立 (20 分鐘)

### 3.1 Docker 監控腳本
- [ ] `scripts/docker-monitor.ps1` 已建立
- [ ] 測試執行成功 (無語法錯誤)
- [ ] 輸出 JSON 格式正確
- [ ] 日誌檔案正常寫入 `logs/` 目錄

**測試指令:**
```powershell
cd C:\mis-assistant
powershell.exe -ExecutionPolicy Bypass -File .\scripts\docker-monitor.ps1
```

**預期輸出:**
- 顯示所有容器狀態
- 顯示 CPU/記憶體使用率
- 顯示磁碟空間
- 生成 JSON 報告

### 3.2 資料庫備份腳本
- [ ] `scripts/backup-databases.ps1` 已建立
- [ ] 測試執行成功
- [ ] 能自動偵測 MySQL 容器
- [ ] 備份檔案正常生成

**測試指令:**
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\scripts\backup-databases.ps1 -TestMode
```

### 3.3 清理舊備份腳本
- [ ] `scripts/cleanup-old-backups.ps1` 已建立
- [ ] 測試執行成功
- [ ] 能正確識別舊備份檔案

**測試指令:**
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\scripts\cleanup-old-backups.ps1 -WhatIf
```

---

## ✅ Phase 4: Docker 服務部署 (10 分鐘)

### 4.1 啟動 n8n 服務
- [ ] 進入專案目錄: `cd C:\mis-assistant`
- [ ] 檢查 `.env` 檔案已正確設定
- [ ] 啟動服務: `docker-compose up -d`
- [ ] 檢查容器狀態: `docker-compose ps`
- [ ] 檢查容器日誌: `docker-compose logs -f n8n`

**預期結果:**
- `n8n-mis` 容器狀態為 `Up (healthy)`
- 可訪問 http://localhost:5678
- 登入頁面正常顯示

### 4.2 n8n 首次登入
- [ ] 瀏覽器開啟 http://localhost:5678
- [ ] 使用 `.env` 中的帳號密碼登入
- [ ] 進入 n8n 工作台
- [ ] 介面正常顯示

### 4.3 (可選) 啟動 cAdvisor
- [ ] 執行: `docker-compose --profile monitoring up -d`
- [ ] 訪問 http://localhost:8080
- [ ] 查看容器監控資訊

---

## ✅ Phase 5: n8n 工作流程匯入 (15 分鐘)

### 5.1 Docker 監控工作流程
- [ ] 開啟 n8n Web UI
- [ ] 點選右上角 "..." → "Import from File"
- [ ] 選擇 `workflows/1-docker-monitor.json`
- [ ] 啟動工作流程 (點選右上角 "Active")
- [ ] 檢查 Schedule 節點設定 (每 3 分鐘)
- [ ] 點選 "Execute Workflow" 測試執行
- [ ] 確認 Telegram 收到測試訊息

**檢查項目:**
- [ ] Schedule Trigger 設定正確
- [ ] Execute Command 路徑正確
- [ ] Telegram 節點設定正確
- [ ] 測試執行成功

### 5.2 資料庫備份工作流程
- [ ] 匯入 `workflows/2-database-backup.json`
- [ ] 啟動工作流程
- [ ] 檢查 Cron 節點設定 (每天 02:00)
- [ ] 測試執行
- [ ] 確認備份檔案生成

**檢查項目:**
- [ ] Cron 時間設定正確
- [ ] MySQL 容器自動偵測正常
- [ ] 備份檔案正確壓縮
- [ ] 清理舊備份正常運作

### 5.3 會議記錄整理工作流程
- [ ] 匯入 `workflows/3-meeting-notes.json`
- [ ] 設定 Webhook URL
- [ ] 測試 Webhook 觸發
- [ ] 確認 Groq API 調用正常
- [ ] 確認輸出格式正確

**測試資料:**
```
今天開會討論了新專案的進度。Barron 負責完成 API 開發，預計 2 月 5 日完成。TeamMember 負責測試，2 月 10 日前完成。決議使用 Laravel 11 框架。下次會議 2 月 5 日下午 2 點。
```

### 5.4 科技新聞摘要工作流程
- [ ] 匯入 `workflows/4-tech-news.json`
- [ ] 啟動工作流程
- [ ] 檢查 Cron 節點設定 (每天 07:30)
- [ ] 測試執行
- [ ] 確認 RSS 抓取正常
- [ ] 確認新聞翻譯正確

---

## ✅ Phase 6: 整合測試 (10 分鐘)

### 6.1 執行完整測試腳本
- [ ] 執行: `powershell.exe -ExecutionPolicy Bypass -File .\test-all.ps1`
- [ ] 所有測試項目通過

### 6.2 Docker 監控測試
- [ ] 等待 3 分鐘
- [ ] 檢查 Telegram 是否收到監控報告
- [ ] 故意停止一個測試容器
- [ ] 確認收到警報通知
- [ ] 重新啟動容器
- [ ] 確認收到恢復通知

### 6.3 資料庫備份測試
- [ ] 手動觸發備份工作流程
- [ ] 檢查 `backups/` 目錄
- [ ] 確認備份檔案已生成
- [ ] 檢查檔案可正常解壓
- [ ] 確認 Telegram 收到完成通知

### 6.4 會議記錄測試
- [ ] 對 Telegram Bot 發送會議記錄文字
- [ ] 確認收到 AI 整理後的摘要
- [ ] 檢查格式是否正確
- [ ] 檢查內容是否準確

### 6.5 科技新聞測試
- [ ] 手動觸發新聞工作流程
- [ ] 確認收到新聞摘要
- [ ] 檢查翻譯品質
- [ ] 檢查連結是否正常

---

## ✅ Phase 7: 文件閱讀與最佳化 (10 分鐘)

### 7.1 閱讀說明文件
- [ ] 閱讀 `README.md`
- [ ] 閱讀 `docs/telegram-setup.md`
- [ ] 閱讀 `docs/groq-setup.md`
- [ ] 閱讀 `docs/maintenance.md`

### 7.2 設定自動啟動 (可選)
- [ ] 設定 Docker Desktop 開機自動啟動
- [ ] 設定 n8n 容器自動重啟

### 7.3 效能最佳化
- [ ] 檢查 n8n 資源使用率
- [ ] 調整 `docker-compose.yml` 資源限制 (如需要)
- [ ] 設定日誌輪替
- [ ] 設定備份自動清理

---

## ✅ Phase 8: 維護與監控 (持續進行)

### 8.1 每日檢查
- [ ] 檢查 Telegram 是否收到監控報告
- [ ] 檢查是否有異常警報
- [ ] 查看 cAdvisor 儀表板 (可選)

### 8.2 每週檢查
- [ ] 檢查備份檔案是否正常生成
- [ ] 檢查磁碟空間使用情況
- [ ] 檢查 Docker 映像更新
- [ ] 檢查 n8n 版本更新

### 8.3 每月檢查
- [ ] 測試備份檔案還原
- [ ] 檢查工作流程執行歷史
- [ ] 清理舊日誌檔案
- [ ] 檢查 API 金鑰使用量

---

## 🔧 故障排除

### 常見問題

**問題 1: n8n 無法啟動**
- 檢查 `.env` 檔案是否存在
- 檢查 Docker Desktop 是否運行
- 檢查連接埠 5678 是否被佔用
- 查看日誌: `docker-compose logs n8n`

**問題 2: 監控腳本執行失敗**
- 檢查 PowerShell 執行政策
- 檢查 Docker CLI 是否可用
- 檢查腳本路徑是否正確
- 手動執行腳本測試

**問題 3: Telegram 無法收到訊息**
- 檢查 Bot Token 是否正確
- 檢查 Chat ID 是否正確
- 確認已對 Bot 發送 `/start`
- 測試 Telegram API 連線

**問題 4: Groq API 調用失敗**
- 檢查 API Key 是否正確
- 檢查 API 配額是否用盡
- 檢查網路連線
- 查看 n8n 執行日誌

**問題 5: 資料庫備份失敗**
- 檢查 MySQL 容器是否運行
- 檢查容器內 mysqldump 是否可用
- 檢查備份目錄權限
- 查看備份腳本輸出

---

## 📞 支援資源

- n8n 官方文件: https://docs.n8n.io
- Groq API 文件: https://console.groq.com/docs
- Telegram Bot API: https://core.telegram.org/bots/api
- Docker 文件: https://docs.docker.com

---

## ✨ 完成!

恭喜!你已經成功部署 MIS 自動化助理系統。

**接下來:**
- 定期檢查系統運作狀況
- 根據需求調整監控閾值
- 新增更多自動化工作流程
- 分享給團隊成員使用

**記得:**
- 定期備份 n8n 資料: `docker-compose exec n8n n8n export:workflow --all`
- 定期更新 Docker 映像: `docker-compose pull && docker-compose up -d`
- 妥善保管 API 金鑰和密碼

---

**部署完成日期:** ___________
**部署人員簽名:** ___________
**下次檢查日期:** ___________
