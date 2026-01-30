# MIS 自動化助理系統

> 基於 n8n + Docker 的 NUC 完整監控與自動化解決方案

## 系統概述

這是一個部署在 Windows 11 Pro NUC 上的 MIS 自動化助理系統,提供 Docker 容器監控、資料庫備份、AI 會議記錄整理和科技新聞摘要等功能。

### 主要功能

#### 1. Docker 容器健康監控
- 每 3 分鐘自動檢查所有 Docker 容器狀態
- 監控 CPU、記憶體使用率
- 監控容器重啟次數
- 監控磁碟空間
- 異常時立即 Telegram 通知

#### 2. 資料庫自動備份
- 每天凌晨 2:00 自動備份
- 自動偵測所有 MySQL 容器
- 自動壓縮備份檔 (gzip)
- 保留最近 7 天備份
- 自動清理舊備份

#### 3. 會議記錄 AI 整理
- 透過 Telegram 發送會議記錄文字
- 使用 Groq API (Llama 3.3 70B) 智慧整理
- 提取主題、決議、待辦事項、負責人
- 生成結構化摘要

#### 4. 每日科技新聞摘要
- 每天早上 7:30 自動推送
- 抓取 TechCrunch、The Verge、Hacker News 等來源
- AI 翻譯成繁體中文
- 精選 10 則重要新聞
- 分類整理 (AI/硬體/軟體)

## 技術架構

```
┌─────────────────────────────────────────────────────────┐
│                    Windows 11 Pro NUC                   │
│                  Intel N97 | 16GB DDR5                  │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │        Docker Desktop + WSL2          │
        └───────────────────┬───────────────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
┌───────▼────────┐                   ┌─────────▼─────────┐
│   n8n 容器     │                   │  現有 Docker 容器  │
│ (自動化引擎)    │◄──────監控────────│  - Laravel 專案   │
│                │                   │  - MySQL          │
│  ┌──────────┐  │                   │  - Redis          │
│  │工作流程1 │  │                   │  - Nginx          │
│  │監控容器  │  │                   └───────────────────┘
│  └──────────┘  │
│  ┌──────────┐  │
│  │工作流程2 │  │
│  │備份資料庫│  │
│  └──────────┘  │                   ┌───────────────────┐
│  ┌──────────┐  │                   │   外部 API 服務   │
│  │工作流程3 │  │◄──────調用────────│  - Groq API       │
│  │會議記錄  │  │                   │  - Telegram Bot   │
│  └──────────┘  │                   │  - RSS Feeds      │
│  ┌──────────┐  │                   └───────────────────┘
│  │工作流程4 │  │
│  │科技新聞  │  │
│  └──────────┘  │
└────────────────┘
        │
        └──────► Telegram 通知
```

## 技術棧

| 類別 | 技術 | 版本 | 用途 |
|------|------|------|------|
| 作業系統 | Windows 11 Pro | Build 26200+ | 宿主機作業系統 |
| 容器化 | Docker Desktop | 29+ | 容器運行環境 |
| 容器編排 | Docker Compose | 2.40+ | 服務編排 |
| 自動化引擎 | n8n | latest | 工作流程自動化 |
| AI 服務 | Groq API | - | 自然語言處理 |
| AI 模型 | Llama 3.3 70B | - | 會議記錄整理、新聞翻譯 |
| 通知服務 | Telegram Bot API | - | 即時通知推送 |
| 腳本語言 | PowerShell | 5.1+ | 監控與備份腳本 |
| 監控工具 | cAdvisor | latest | 容器監控 UI (可選) |

## 快速開始

### 前置需求

- Windows 11 Pro
- Docker Desktop (已安裝並運行)
- 至少 10GB 可用磁碟空間
- 穩定的網路連線

### 安裝步驟

1. **克隆專案** (或下載所有檔案到 `C:\mis-assistant`)

2. **申請 API 金鑰**
   - Groq API: https://console.groq.com
   - Telegram Bot: 在 Telegram 搜尋 @BotFather

3. **設定環境變數**
   ```powershell
   cd C:\mis-assistant
   cp .env.example .env
   # 編輯 .env 填入你的 API 金鑰
   notepad .env
   ```

4. **啟動服務**
   ```powershell
   docker-compose up -d
   ```

5. **訪問 n8n**
   - 開啟瀏覽器: http://localhost:5678
   - 使用 .env 中設定的帳號密碼登入

6. **匯入工作流程**
   - 在 n8n UI 中匯入 `workflows/` 目錄下的 4 個工作流程
   - 啟動所有工作流程

7. **測試驗證**
   ```powershell
   .\test-all.ps1
   ```

詳細步驟請參考 [CHECKLIST.md](CHECKLIST.md)

## 專案結構

```
C:\mis-assistant\
├── docker-compose.yml          # Docker 服務定義
├── .env                        # 環境變數配置 (需自行建立)
├── .env.example                # 環境變數範例
├── README.md                   # 本檔案
├── CHECKLIST.md                # 詳細部署檢查清單
├── test-all.ps1                # 完整測試腳本
│
├── workflows/                  # n8n 工作流程定義
│   ├── 1-docker-monitor.json   # Docker 監控工作流程
│   ├── 2-database-backup.json  # 資料庫備份工作流程
│   ├── 3-meeting-notes.json    # 會議記錄整理工作流程
│   └── 4-tech-news.json        # 科技新聞摘要工作流程
│
├── scripts/                    # PowerShell 腳本
│   ├── docker-monitor.ps1      # Docker 容器監控腳本
│   ├── backup-databases.ps1    # 資料庫備份腳本
│   └── cleanup-old-backups.ps1 # 清理舊備份腳本
│
├── backups/                    # 資料庫備份儲存目錄
│   └── YYYYMMDD/               # 按日期分類
│       └── *.sql.gz            # 壓縮的備份檔
│
├── logs/                       # 系統日誌
│   ├── monitor-*.json          # 監控日誌
│   └── backup-*.log            # 備份日誌
│
└── docs/                       # 說明文件
    ├── telegram-setup.md       # Telegram Bot 設定指南
    ├── groq-setup.md           # Groq API 設定指南
    ├── maintenance.md          # 維護指南
    └── troubleshooting.md      # 故障排除
```

## 監控警報規則

| 項目 | 條件 | 等級 | 通知頻率 |
|------|------|------|---------|
| 容器停止 | 狀態 != running | 🚨 錯誤 | 立即 |
| 容器重啟過多 | 重啟次數 > 3/小時 | ⚠️ 警告 | 立即 |
| CPU 使用率高 | CPU > 80% | ⚠️ 警告 | 立即 |
| 記憶體使用率高 | Memory > 90% | ⚠️ 警告 | 立即 |
| 磁碟空間不足 | Free < 10% | 🚨 緊急 | 立即 |

可在 `.env` 檔案中調整閾值:
```env
CPU_THRESHOLD=80
MEMORY_THRESHOLD=90
DISK_THRESHOLD=10
RESTART_THRESHOLD=3
```

## 使用說明

### Docker 監控

監控自動每 3 分鐘運行一次。如需手動檢查:

```powershell
# 執行監控腳本
.\scripts\docker-monitor.ps1

# 查看監控日誌
Get-Content .\logs\monitor-*.json | ConvertFrom-Json | Format-List
```

### 資料庫備份

備份自動每天凌晨 2:00 運行。如需手動備份:

```powershell
# 執行備份腳本
.\scripts\backup-databases.ps1

# 列出備份檔案
Get-ChildItem .\backups -Recurse -Filter *.sql.gz
```

### 會議記錄整理

直接在 Telegram 對你的 Bot 發送會議記錄文字,會自動回覆整理後的摘要。

### 科技新聞摘要

每天早上 7:30 自動推送。如需立即獲取:

在 n8n UI 中手動執行 "4-tech-news" 工作流程。

## 維護

### 每日維護
- 檢查 Telegram 監控通知
- 處理異常警報

### 每週維護
- 檢查備份檔案完整性
- 檢查磁碟空間
- 清理舊日誌 (30 天前)

### 每月維護
- 測試備份還原
- 更新 Docker 映像
- 檢查 API 配額使用情況

```powershell
# 更新服務
docker-compose pull
docker-compose up -d

# 備份 n8n 工作流程
docker-compose exec n8n n8n export:workflow --all --output=/backups/n8n-workflows-backup.json

# 清理舊日誌
Get-ChildItem .\logs -Recurse | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item
```

## 故障排除

### n8n 無法啟動
1. 檢查 Docker Desktop 是否運行
2. 檢查 `.env` 檔案是否存在且正確
3. 檢查連接埠 5678 是否被佔用
4. 查看日誌: `docker-compose logs n8n`

### 監控腳本失敗
1. 檢查 PowerShell 執行政策
2. 手動執行腳本: `.\scripts\docker-monitor.ps1`
3. 檢查 Docker CLI 是否可用: `docker ps`

### Telegram 收不到訊息
1. 確認已對 Bot 發送 `/start`
2. 檢查 `TELEGRAM_BOT_TOKEN` 是否正確
3. 檢查 `TELEGRAM_CHAT_ID` 是否正確
4. 在 n8n 中測試 Telegram 節點

### Groq API 失敗
1. 檢查 API Key 是否正確
2. 檢查 API 配額: https://console.groq.com
3. 檢查網路連線

更多問題請參考 [docs/troubleshooting.md](docs/troubleshooting.md)

## 安全性建議

1. **保護 .env 檔案**
   - 不要提交到 Git
   - 設定適當的檔案權限
   - 定期更換密碼

2. **API 金鑰管理**
   - 使用專用的 API 金鑰
   - 設定 API 配額限制
   - 定期檢查使用情況

3. **網路安全**
   - 使用防火牆限制存取
   - 考慮使用 Tailscale VPN
   - 不要將 n8n 暴露到公網

4. **備份安全**
   - 加密敏感的備份檔案
   - 定期測試備份還原
   - 考慮異地備份

## 效能最佳化

### NUC 資源限制建議

```yaml
# docker-compose.yml
n8n:
  deploy:
    resources:
      limits:
        cpus: '2.0'      # 最多使用 2 個 CPU 核心
        memory: 2G       # 最多使用 2GB 記憶體
```

### 監控頻率調整

如果 NUC 負載過高,可調整監控頻率:

```env
# .env
MONITOR_INTERVAL=5  # 改為每 5 分鐘檢查一次
```

## API 配額

### Groq API (免費方案)
- 30 requests/minute
- 14,400 requests/day
- 足夠個人使用

### Telegram Bot API
- 無使用限制
- 每秒最多 30 則訊息

## 常見問題 (FAQ)

**Q: 可以監控非 Docker 服務嗎?**
A: 可以。可以新增 PowerShell 腳本監控 Windows 服務或其他應用程式。

**Q: 可以新增更多自動化工作流程嗎?**
A: 可以。n8n 支援超過 400 種整合,可以自由新增工作流程。

**Q: 備份可以上傳到雲端嗎?**
A: 可以。可以新增 Google Drive、OneDrive、S3 等節點。

**Q: 可以從遠端存取 n8n 嗎?**
A: 可以。建議使用 Tailscale VPN 安全存取,不建議直接暴露到公網。

**Q: NUC 效能夠用嗎?**
A: Intel N97 + 16GB RAM 足夠運行此系統加上多個 Laravel 專案容器。

## 更新日誌

### v1.0.0 (2026-01-28)
- 初始版本
- Docker 容器健康監控
- 資料庫自動備份
- 會議記錄 AI 整理
- 每日科技新聞摘要

## 授權

MIT License

## 貢獻

歡迎提交 Issue 和 Pull Request!

## 作者

Barron @ NUC Box G3 Plus

## 致謝

- [n8n](https://n8n.io) - 強大的工作流程自動化工具
- [Groq](https://groq.com) - 快速的 AI 推理服務
- [Telegram](https://telegram.org) - 即時通訊平台

---

**部署日期:** ___________
**維護人員:** ___________
**下次檢查:** ___________
