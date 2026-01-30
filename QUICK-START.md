# 🚀 MIS 自動化助理 - 20 分鐘快速部署指南

**歡迎回來 Barron!** 所有工作流程都已經準備好了,現在讓我們在 20 分鐘內把系統啟動起來!

---

## ✅ 你已經有的 API 金鑰

你提供的 Groq API Key:
```
GROQ_API_KEY_REMOVED
```

---

## 📋 快速檢查清單

在開始之前,確認以下項目:

- [ ] Docker Desktop 正在運行
- [ ] 已申請 Telegram Bot (如果還沒有,看下面「步驟 1」)
- [ ] 已取得 Telegram Chat ID
- [ ] 網路連線正常
- [ ] 至少 10GB 可用磁碟空間

---

## 🎯 部署步驟

### 步驟 1: 申請 Telegram Bot (5 分鐘)

**如果你還沒有 Telegram Bot,按照以下步驟:**

1. **開啟 Telegram**,搜尋 `@BotFather`
2. **發送** `/newbot`
3. **Bot 名稱**: 輸入 `MIS Assistant` (或你喜歡的名稱)
4. **Bot 用戶名**: 輸入 `<你的名字>_mis_assistant_bot` (必須以 bot 結尾)
5. **複製 Bot Token** (格式: `1234567890:ABCdef...`)
6. **保存 Token** 到記事本

**取得 Chat ID:**

1. 在 Telegram 搜尋 `@userinfobot`
2. 發送任意訊息
3. 複製你的 `Id` (純數字,例如: 123456789)

**測試 Bot:**

1. 在 Telegram 搜尋你剛建立的 Bot
2. 發送 `/start` 啟動對話

**詳細說明**: 如果遇到問題,參考 [`docs/telegram-setup.md`](docs/telegram-setup.md)

---

### 步驟 2: 設定環境變數 (2 分鐘)

**1. 複製環境變數範本:**

```powershell
cd C:\mis-assistant
Copy-Item .env.example .env
```

**2. 編輯 .env 檔案:**

```powershell
notepad .env
```

**3. 填入以下資訊:**

```env
# n8n 登入資訊
N8N_USER=barron
N8N_PASSWORD=<設定至少16字元的強密碼>

# Groq API (已提供)
GROQ_API_KEY=GROQ_API_KEY_REMOVED

# Telegram Bot (填入你的)
TELEGRAM_BOT_TOKEN=<你的 Bot Token>
TELEGRAM_CHAT_ID=<你的 Chat ID>

# 其他設定 (保持預設即可)
CPU_THRESHOLD=80
MEMORY_THRESHOLD=90
DISK_THRESHOLD=10
RESTART_THRESHOLD=3
BACKUP_RETENTION_DAYS=7
```

**4. 儲存並關閉**

**⚠️ 重要**: 確保沒有多餘的空格或換行!

---

### 步驟 3: 啟動 Docker 服務 (3 分鐘)

**1. 確認 Docker Desktop 運行中:**

```powershell
docker --version
```

如果顯示版本號,表示 Docker 正常運作。

**2. 啟動 n8n 服務:**

```powershell
cd C:\mis-assistant
docker-compose up -d
```

**預期輸出:**
```
Creating network "mis-network" with the default driver
Creating volume "n8n_mis_data" with local driver
Creating n8n-mis ... done
```

**3. 等待服務啟動 (30 秒):**

```powershell
Start-Sleep -Seconds 30
```

**4. 檢查容器狀態:**

```powershell
docker-compose ps
```

**預期輸出:**
```
    Name                   Command               State           Ports
--------------------------------------------------------------------------------
n8n-mis        tini -- /docker-entrypoint ...   Up      0.0.0.0:5678->5678/tcp
```

狀態應該是 `Up` 或 `Up (healthy)`

**5. 測試 n8n 網頁介面:**

```powershell
start http://localhost:5678
```

瀏覽器應該開啟並顯示 n8n 登入頁面。

**如果無法開啟,檢查:**
```powershell
docker-compose logs n8n --tail=50
```

---

### 步驟 4: 登入 n8n 並設定 Telegram 憑證 (3 分鐘)

**1. 登入 n8n:**
- 開啟 http://localhost:5678
- 使用者名稱: `barron` (或你在 .env 中設定的)
- 密碼: (你在 .env 中設定的密碼)

**2. 設定 Telegram 憑證:**

a. 點選左側選單的 **"Credentials"** (憑證)

b. 點選右上角 **"Add Credential"** (新增憑證)

c. 搜尋並選擇 **"Telegram API"**

d. 填入資訊:
   - **Credential Name**: `Telegram Bot` (必須完全一樣!)
   - **Access Token**: (你的 Telegram Bot Token)

e. 點選 **"Create"** (建立)

f. 點選 **"Test"** (測試) 確認連線成功

**3. 完成!** 憑證已設定。

---

### 步驟 5: 匯入工作流程 (5 分鐘)

現在匯入 4 個自動化工作流程!

#### 5.1 匯入工作流程 1: Docker 監控

1. 點選左側選單的 **"Workflows"** (工作流程)
2. 點選右上角 **"Add workflow"** 旁的下拉選單
3. 選擇 **"Import from File"** (從檔案匯入)
4. 選擇 `C:\mis-assistant\workflows\1-docker-monitor.json`
5. 點選 **"Import"** (匯入)

**工作流程應該載入,顯示多個節點和連線**

**設定 Telegram 節點:**
- 點選 **"Send Alert"** 節點
- 在 **"Credential to connect with"** 選擇 **"Telegram Bot"**
- 點選 **"Send Status (Silent)"** 節點,也選擇 **"Telegram Bot"**

**啟動工作流程:**
- 點選右上角的開關,從 **"Inactive"** 改為 **"Active"**
- 工作流程會變成綠色

**測試執行:**
- 點選 **"Every 3 minutes"** 節點
- 點選右側的 **"Execute Node"** (執行節點)
- 等待執行完成
- **檢查 Telegram** 是否收到監控報告!

#### 5.2 匯入工作流程 2: 資料庫備份

1. 回到 **"Workflows"** 頁面
2. 重複上面的步驟,匯入 `2-database-backup.json`
3. 設定所有 Telegram 節點的憑證
4. 啟動工作流程

**測試執行:**
- 點選 **"Daily at 2:00 AM"** 節點
- 點選 **"Execute Node"**
- 檢查 Telegram 是否收到備份報告

#### 5.3 匯入工作流程 3: 會議記錄整理

1. 匯入 `3-meeting-notes.json`
2. 設定 Telegram 節點憑證
3. 啟動工作流程

**測試執行:**
- 直接在 Telegram 對你的 Bot 發送測試會議記錄:
  ```
  今天開會討論了新專案。Barron 負責開發,預計 2 月完成。
  決議採用 Laravel 11 框架。下次會議 2 月 5 日。
  ```
- Bot 應該會回覆 AI 整理後的摘要!

#### 5.4 匯入工作流程 4: 科技新聞

1. 匯入 `4-tech-news.json`
2. 設定 Telegram 節點憑證
3. 啟動工作流程

**測試執行:**
- 點選 **"Daily at 7:30 AM"** 節點
- 點選 **"Execute Node"**
- 等待約 1-2 分鐘 (會抓取並翻譯新聞)
- 檢查 Telegram 是否收到新聞摘要

---

### 步驟 6: 驗證系統運作 (2 分鐘)

執行完整測試:

```powershell
cd C:\mis-assistant
.\test-all.ps1
```

**預期結果:**
- 大部分測試應該通過 (PASS)
- n8n 容器運行正常
- Groq API 連線成功
- Telegram 可以發送訊息

**如果有測試失敗:**
- 查看錯誤訊息
- 參考 [`docs/troubleshooting.md`](docs/troubleshooting.md)

---

## 🎉 完成! 系統已上線!

### 你現在擁有:

#### ✅ Docker 容器監控
- **頻率**: 每 3 分鐘自動檢查
- **功能**: 監控所有容器狀態、CPU、記憶體、磁碟空間
- **通知**: 有問題立即 Telegram 警報

#### ✅ 資料庫自動備份
- **時間**: 每天凌晨 2:00
- **功能**: 自動偵測所有 MySQL 容器並備份
- **保留**: 7 天,自動清理舊備份

#### ✅ AI 會議記錄整理
- **觸發**: 在 Telegram 發送會議記錄文字給 Bot
- **功能**: Groq AI 自動整理成結構化摘要
- **輸出**: 主題、決議、待辦事項、下次會議

#### ✅ 每日科技新聞摘要
- **時間**: 每天早上 7:30
- **來源**: TechCrunch, The Verge, Ars Technica, Hacker News
- **功能**: AI 翻譯成繁體中文,分類整理
- **輸出**: 精選 10 則重要新聞

---

## 📱 如何使用

### 監控系統
- **自動**: 每 3 分鐘收到狀態更新 (正常時靜音)
- **異常**: 立即收到警報通知

### 備份資料庫
- **自動**: 每天凌晨 2:00 自動執行
- **手動**: 在 n8n 中點選工作流程執行

### 整理會議記錄
- **使用**: 在 Telegram 直接發送會議記錄文字給你的 Bot
- **回覆**: Bot 會立即回覆 AI 整理的摘要

### 獲取科技新聞
- **自動**: 每天早上 7:30 推送
- **手動**: 在 n8n 中點選工作流程執行

---

## 🔧 維護建議

### 每週
- 檢查 Telegram 通知是否正常
- 查看備份檔案是否生成
- 執行 `.\test-all.ps1` 健康檢查

### 每月
- 測試備份還原
- 匯出 n8n 工作流程備份
- 更新 Docker 映像

詳細維護指南: [`docs/maintenance.md`](docs/maintenance.md)

---

## 🆘 遇到問題?

### 常見問題

**Q: 收不到 Telegram 通知?**
- 確認 Bot Token 和 Chat ID 正確
- 確認已對 Bot 發送 `/start`
- 測試 Telegram 憑證

**Q: n8n 無法啟動?**
- 檢查 `.env` 檔案是否正確
- 查看日誌: `docker-compose logs n8n`
- 確認連接埠 5678 沒被佔用

**Q: 工作流程執行失敗?**
- 點選失敗的節點查看錯誤
- 檢查 API 金鑰是否正確
- 查看 Executions 頁面的詳細日誌

**完整故障排除**: [`docs/troubleshooting.md`](docs/troubleshooting.md)

---

## 📚 延伸閱讀

- [完整系統文件](README.md)
- [Telegram Bot 設定](docs/telegram-setup.md)
- [Groq API 設定](docs/groq-setup.md)
- [維護指南](docs/maintenance.md)
- [故障排除](docs/troubleshooting.md)

---

## 🚀 下一步

系統已經完全自動化運行了!你可以:

1. **體驗功能**: 發送會議記錄給 Bot 試試
2. **調整設定**: 修改監控閾值或備份時間
3. **新增工作流程**: n8n 支援 400+ 種整合
4. **優化系統**: 根據實際使用調整

---

## 💡 小技巧

### 檢查系統狀態
```powershell
# 快速查看容器狀態
docker-compose ps

# 查看 n8n 日誌
docker-compose logs -f n8n

# 執行健康檢查
.\test-all.ps1
```

### 手動執行腳本
```powershell
# Docker 監控
.\scripts\docker-monitor.ps1 -Verbose

# 資料庫備份
.\scripts\backup-databases.ps1 -Verbose

# 清理舊備份
.\scripts\cleanup-old-backups.ps1 -Verbose
```

### 訪問服務
- **n8n 介面**: http://localhost:5678
- **cAdvisor 監控** (可選): http://localhost:8080

---

## 🎊 恭喜!

你現在擁有一個完整的自動化 MIS 助理系統,全天候為你工作!

**系統亮點:**
- 💰 **完全免費** (Groq API 免費額度)
- 🔒 **安全可靠** (所有資料在本機)
- 🎨 **視覺化管理** (n8n 友善介面)
- 🔧 **高度自訂** (想加什麼功能都可以)
- 📱 **隨時掌握** (Telegram 即時通知)

**享受自動化帶來的便利吧!** 🚀

---

**有問題隨時問!**
文件都在 `docs/` 目錄中。

**祝使用愉快!** 😊
