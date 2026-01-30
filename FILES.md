# 📂 MIS 自動化助理系統 - 完整檔案清單

這個檔案列出專案中所有重要檔案及其用途。

---

## 📋 目錄結構總覽

```
C:\mis-assistant\
├── 核心配置檔案 (4)
├── 說明文件 (4)
├── workflows/ (4 個工作流程)
├── scripts/ (3 個腳本)
├── docs/ (4 份文件)
├── backups/ (自動生成)
└── logs/ (自動生成)
```

**總計**: 約 20 個核心檔案

---

## 🎯 核心配置檔案

### docker-compose.yml
- **類型**: Docker 服務定義
- **用途**: 定義 n8n 和 cAdvisor 容器配置
- **重要性**: ⭐⭐⭐⭐⭐
- **修改**: 可調整資源限制、連接埠

### .env.example
- **類型**: 環境變數範本
- **用途**: 提供配置範例
- **重要性**: ⭐⭐⭐⭐
- **操作**: 複製為 `.env` 並填入實際值

### .env
- **類型**: 環境變數 (需自行建立)
- **用途**: 儲存 API 金鑰和密碼
- **重要性**: ⭐⭐⭐⭐⭐
- **安全**: 🔒 不要提交到 Git!

### test-all.ps1
- **類型**: PowerShell 測試腳本
- **用途**: 驗證系統所有組件
- **重要性**: ⭐⭐⭐⭐
- **執行**: `.\test-all.ps1`

---

## 📖 說明文件

### START-HERE.md
- **用途**: 首次使用指南
- **內容**: 歡迎訊息、快速導覽
- **適合**: 剛完成部署的新手
- **閱讀時間**: 2 分鐘

### QUICK-START.md ⭐⭐⭐
- **用途**: 20 分鐘快速部署指南
- **內容**: 詳細的 step-by-step 教學
- **適合**: 想立即啟動系統
- **閱讀時間**: 跟著做 20 分鐘

### README.md
- **用途**: 完整系統說明
- **內容**: 架構、功能、使用方式
- **適合**: 想深入了解系統
- **閱讀時間**: 10 分鐘

### CHECKLIST.md
- **用途**: 詳細部署檢查清單
- **內容**: 逐項檢查的部署步驟
- **適合**: 喜歡一步一步確認
- **閱讀時間**: 跟著做 30-60 分鐘

### FILES.md
- **用途**: 檔案清單 (本檔案)
- **內容**: 所有檔案的說明
- **適合**: 想了解專案結構
- **閱讀時間**: 5 分鐘

---

## 🤖 n8n 工作流程 (workflows/)

### 1-docker-monitor.json
- **功能**: Docker 容器健康監控
- **觸發**: Schedule (每 3 分鐘)
- **節點數**: 8 個
- **複雜度**: ⭐⭐⭐
- **輸出**: Telegram 通知

**節點流程**:
```
Schedule → Execute Script → Parse JSON →
Check Issues → Format Message → Send Telegram
```

### 2-database-backup.json
- **功能**: MySQL 資料庫自動備份
- **觸發**: Cron (每天 02:00)
- **節點數**: 9 個
- **複雜度**: ⭐⭐⭐⭐
- **輸出**: 備份檔案 + Telegram 通知

**節點流程**:
```
Cron → Execute Backup → Parse Result →
Check Success → Format Message → Send Telegram → Cleanup
```

### 3-meeting-notes.json
- **功能**: AI 會議記錄整理
- **觸發**: Webhook / Telegram Message
- **節點數**: 8 個
- **複雜度**: ⭐⭐⭐⭐
- **AI**: Groq Llama 3.3 70B
- **輸出**: AI 整理的摘要

**節點流程**:
```
Webhook/Telegram → Extract Text → Call Groq API →
Parse AI Response → Reply
```

### 4-tech-news.json
- **功能**: 每日科技新聞摘要
- **觸發**: Cron (每天 07:30)
- **節點數**: 11 個
- **複雜度**: ⭐⭐⭐⭐⭐
- **AI**: Groq Llama 3.3 70B (翻譯)
- **來源**: 4 個 RSS feed

**節點流程**:
```
Cron → Fetch RSS (x4) → Merge & Filter →
Translate (AI) → Format → Send Telegram
```

---

## 🔧 PowerShell 腳本 (scripts/)

### docker-monitor.ps1
- **功能**: 監控 Docker 容器健康狀態
- **輸入**: 閾值參數 (可選)
- **輸出**: JSON 格式報告
- **測試**: ✅ 已測試成功
- **日誌**: `logs/monitor-*.json`

**執行範例**:
```powershell
.\scripts\docker-monitor.ps1 -Verbose
.\scripts\docker-monitor.ps1 -CpuThreshold 90
```

**檢查項目**:
- 容器狀態 (running/stopped)
- CPU 使用率
- 記憶體使用率
- 重啟次數
- 磁碟空間

### backup-databases.ps1
- **功能**: 備份所有 MySQL 容器
- **輸入**: 備份路徑、保留天數 (可選)
- **輸出**: 壓縮的 .sql.gz 備份檔
- **位置**: `backups/YYYYMMDD/`
- **日誌**: `logs/backup-*.json`

**執行範例**:
```powershell
.\scripts\backup-databases.ps1 -Verbose
.\scripts\backup-databases.ps1 -TestMode
```

**執行流程**:
1. 掃描 MySQL 容器
2. 執行 mysqldump
3. Gzip 壓縮
4. 儲存備份檔
5. 生成報告

### cleanup-old-backups.ps1
- **功能**: 刪除舊備份檔案
- **輸入**: 保留天數 (預設 7 天)
- **輸出**: 清理報告
- **日誌**: `logs/cleanup-*.json`

**執行範例**:
```powershell
.\scripts\cleanup-old-backups.ps1 -Verbose
.\scripts\cleanup-old-backups.ps1 -WhatIf  # 預覽模式
.\scripts\cleanup-old-backups.ps1 -RetentionDays 14
```

---

## 📚 詳細文件 (docs/)

### telegram-setup.md
- **內容**: Telegram Bot 完整設定教學
- **章節**:
  - 建立 Bot
  - 取得 Token
  - 取得 Chat ID
  - 測試發送
  - 常見問題
- **閱讀時間**: 10 分鐘
- **實作時間**: 5 分鐘

### groq-setup.md
- **內容**: Groq API 完整設定教學
- **章節**:
  - Groq 簡介
  - 申請 API Key
  - API 配額說明
  - 模型選擇
  - 測試 API
  - 常見問題
- **閱讀時間**: 10 分鐘
- **實作時間**: 3 分鐘

### maintenance.md
- **內容**: 系統維護指南
- **章節**:
  - 每日/每週/每月維護
  - 備份驗證
  - 系統更新
  - 效能優化
  - 維護檢查清單
- **閱讀時間**: 15 分鐘
- **適合**: 系統管理員

### troubleshooting.md
- **內容**: 故障排除指南
- **章節**:
  - 快速診斷
  - n8n 問題
  - Docker 問題
  - Telegram 問題
  - Groq API 問題
  - PowerShell 問題
  - 緊急恢復
- **閱讀時間**: 20 分鐘
- **適合**: 遇到問題時查閱

---

## 📁 自動生成目錄

### backups/
- **用途**: 儲存資料庫備份
- **結構**: `YYYYMMDD/*.sql.gz`
- **管理**: 自動清理 7 天前的檔案
- **大小**: 視資料庫大小而定

**範例**:
```
backups/
├── 20260128/
│   ├── laravel_prod-mysql-20260128-020015.sql.gz
│   └── analytics-mysql-20260128-020112.sql.gz
├── 20260129/
│   └── ...
```

### logs/
- **用途**: 儲存系統日誌
- **類型**:
  - `monitor-*.json` - 監控日誌
  - `backup-*.json` - 備份日誌
  - `cleanup-*.json` - 清理日誌
  - `test-results-*.json` - 測試結果
- **管理**: 建議每月清理 30 天前的日誌

**範例**:
```
logs/
├── monitor-20260128-233545.json
├── backup-20260128-020530.json
├── cleanup-20260128-020845.json
└── test-results-20260128-100230.json
```

---

## 🔐 重要檔案安全提醒

### 需要保護的檔案

#### .env
- **內容**: API 金鑰、密碼
- **風險**: 🔴 高
- **建議**:
  - ❌ 不要提交到 Git
  - ✅ 定期備份到安全位置
  - ✅ 設定檔案權限

#### backups/*.sql.gz
- **內容**: 資料庫完整備份
- **風險**: 🟡 中
- **建議**:
  - ✅ 定期測試還原
  - ✅ 考慮加密敏感備份
  - ✅ 異地備份重要資料

#### logs/*.json
- **內容**: 系統運作記錄
- **風險**: 🟢 低
- **建議**:
  - ✅ 定期清理舊日誌
  - ✅ 檢查是否有敏感資訊

---

## 📊 檔案統計

### 按類型統計

| 類型 | 數量 | 總大小 (約) |
|------|------|------------|
| 配置檔案 | 2 | < 10 KB |
| 說明文件 | 5 | ~150 KB |
| 工作流程 JSON | 4 | ~50 KB |
| PowerShell 腳本 | 3 | ~40 KB |
| 詳細文件 | 4 | ~120 KB |
| **總計** | **18** | **~370 KB** |

### 按重要性統計

| 重要性 | 檔案數 |
|--------|--------|
| ⭐⭐⭐⭐⭐ 必要 | 5 |
| ⭐⭐⭐⭐ 重要 | 8 |
| ⭐⭐⭐ 建議 | 5 |

---

## 🎯 快速查找

### 我想...

#### 開始部署系統
→ 閱讀 [`QUICK-START.md`](QUICK-START.md)

#### 了解系統功能
→ 閱讀 [`README.md`](README.md)

#### 設定 Telegram Bot
→ 閱讀 [`docs/telegram-setup.md`](docs/telegram-setup.md)

#### 測試系統
→ 執行 `.\test-all.ps1`

#### 手動執行監控
→ 執行 `.\scripts\docker-monitor.ps1 -Verbose`

#### 手動備份資料庫
→ 執行 `.\scripts\backup-databases.ps1 -Verbose`

#### 解決問題
→ 閱讀 [`docs/troubleshooting.md`](docs/troubleshooting.md)

#### 維護系統
→ 閱讀 [`docs/maintenance.md`](docs/maintenance.md)

---

## 📝 版本資訊

- **專案版本**: 1.0.0
- **建立日期**: 2026-01-28
- **最後更新**: 2026-01-28
- **狀態**: ✅ Production Ready

---

## 🔄 更新記錄

### v1.0.0 (2026-01-28)
- ✅ 初始版本
- ✅ 4 個核心工作流程
- ✅ 3 個 PowerShell 腳本
- ✅ 完整文件系統
- ✅ 測試腳本
- ✅ 快速部署指南

---

## 💡 使用建議

### 新手路徑
1. 閱讀 `START-HERE.md` (2 分鐘)
2. 跟著 `QUICK-START.md` 操作 (20 分鐘)
3. 執行 `test-all.ps1` 驗證 (2 分鐘)
4. 開始使用系統!

### 進階路徑
1. 閱讀 `README.md` 了解架構
2. 研究 `workflows/*.json` 工作流程
3. 自訂 PowerShell 腳本
4. 參考 `docs/maintenance.md` 優化系統

---

## 🆘 需要協助?

- **部署問題**: 查看 `QUICK-START.md`
- **API 設定**: 查看 `docs/telegram-setup.md` 或 `docs/groq-setup.md`
- **系統錯誤**: 查看 `docs/troubleshooting.md`
- **日常維護**: 查看 `docs/maintenance.md`

---

**所有檔案都已準備就緒!** 🎉

現在開始部署你的自動化系統吧! → [`QUICK-START.md`](QUICK-START.md)
