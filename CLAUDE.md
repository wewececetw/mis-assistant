# Claude Code 專案指引

## 專案範圍限制

**此專案僅限於 `/Users/barronwang/RemoteWindows/mis-assistant` 資料夾內操作。**

請勿在此資料夾外進行任何檔案操作。

## 遠端環境

### SSH 連線
- **主機**: `nucboxg3-plus.tail2f559.ts.net`
- **使用者**: `barron`
- **Port**: 22
- **SSH Config**: 已設定在 `~/.ssh/config`

連線指令：
```bash
ssh nucboxg3-plus.tail2f559.ts.net "<command>"
```

### 容器管理
- **Runtime**: Podman (不是 Docker)
- Windows 環境，使用 cmd/powershell 語法

常用指令：
```bash
# 列出容器
ssh nucboxg3-plus.tail2f559.ts.net "podman ps -a"

# 重啟容器
ssh nucboxg3-plus.tail2f559.ts.net "podman restart <container_name>"

# 查看日誌
ssh nucboxg3-plus.tail2f559.ts.net "podman logs <container_name>"
```

### 容器列表
| 容器名稱 | 用途 |
|---------|------|
| `n8n-mis` | n8n 工作流程引擎 |
| `docker-api-proxy` | Docker API 代理 (socat) |
| `cadvisor-mis` | 容器監控 UI |

## n8n API

- **URL**: `https://nucboxg3-plus.tail2f559.ts.net`
- **API Key**: 使用時請用戶提供

API 操作範例：
```bash
# 列出 workflows
curl -s "https://nucboxg3-plus.tail2f559.ts.net/api/v1/workflows" \
  -H "X-N8N-API-KEY: <key>"

# 啟用 workflow
curl -s -X POST "https://nucboxg3-plus.tail2f559.ts.net/api/v1/workflows/<id>/activate" \
  -H "X-N8N-API-KEY: <key>"

# 停用 workflow
curl -s -X POST "https://nucboxg3-plus.tail2f559.ts.net/api/v1/workflows/<id>/deactivate" \
  -H "X-N8N-API-KEY: <key>"
```

## 專案結構

```
mis-assistant/
├── docker-compose.yml      # Docker Compose 配置
├── Dockerfile.n8n          # n8n 自訂映像檔
├── .env.example            # 環境變數範本
├── workflows/              # n8n 工作流程 JSON
│   ├── telegram-bot-v3-fixed.json   # 主要 Telegram Bot
│   ├── 1-docker-monitor.json        # Docker 監控
│   ├── 2-db-backup.json             # 資料庫備份
│   ├── 3-meeting-notes.json         # 會議記錄
│   └── 4-tech-news.json             # 科技新聞
├── scripts/                # PowerShell 腳本
├── backups/                # 備份檔案
└── logs/                   # 日誌檔案
```

## Credentials (n8n 內)

| ID | 名稱 | 用途 |
|----|------|------|
| `XfuqkzOYYEa0ar0n` | Telegram Bot | Telegram API |
| `06uVsarrbPv5XTZf` | Groq API | LLM / Whisper |

## 常見操作

### 匯入 workflow 到 n8n
```bash
curl -s -X POST "https://nucboxg3-plus.tail2f559.ts.net/api/v1/workflows" \
  -H "X-N8N-API-KEY: <key>" \
  -H "Content-Type: application/json" \
  -d @workflows/<filename>.json
```

### 重啟 n8n (重新註冊 Telegram webhook)
```bash
ssh nucboxg3-plus.tail2f559.ts.net "podman restart n8n-mis"
```

### 查看 n8n 日誌
```bash
ssh nucboxg3-plus.tail2f559.ts.net "podman logs --tail 50 n8n-mis"
```

## 注意事項

1. **Windows 環境**: NUC 是 Windows 11，Podman 在 WSL 或原生環境執行
2. **不要使用 Docker**: 這台機器用的是 Podman
3. **Telegram webhook**: 修改 workflow 後需重啟 n8n 或手動 deactivate/activate
4. **時區**: Asia/Taipei (UTC+8)
