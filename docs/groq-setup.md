# Groq API 設定指南

本指南將協助你申請並設定 Groq API,用於 AI 會議記錄整理和科技新聞翻譯功能。

## 什麼是 Groq?

Groq 是一個高效能 AI 推理平台,提供超快速的 LLM (大型語言模型) API 服務。相比其他 AI 服務:

- **速度極快**: 推理速度比傳統 GPU 快 10 倍以上
- **免費額度充足**: 每分鐘 30 次請求,每天 14,400 次
- **模型選擇多**: 支援 Llama 3.3, Mixtral, Gemma 等
- **API 相容 OpenAI**: 使用方式與 OpenAI API 相同

**本系統使用 Llama 3.3 70B 模型,在免費額度內足夠個人使用。**

---

## 步驟 1: 註冊 Groq 帳號

### 1.1 訪問 Groq Console

開啟瀏覽器訪問: https://console.groq.com

### 1.2 選擇註冊方式

你可以選擇以下任一方式註冊:

- **Google 帳號**: 點選 "Continue with Google"
- **GitHub 帳號**: 點選 "Continue with GitHub"
- **Email**: 輸入 Email 和密碼註冊

**建議使用 Google 或 GitHub 帳號,註冊更快速。**

### 1.3 完成註冊

1. 選擇你的註冊方式並授權
2. 閱讀並同意服務條款
3. 完成 Email 驗證 (如果需要)
4. 進入 Groq Console 主頁

---

## 步驟 2: 建立 API 金鑰

### 2.1 進入 API Keys 頁面

1. 登入後,在左側選單點選 **"API Keys"**
2. 或直接訪問: https://console.groq.com/keys

### 2.2 建立新的 API Key

1. 點選右上角的 **"Create API Key"** 按鈕
2. 輸入 Key 的名稱 (例如: `MIS Assistant`)
3. 點選 **"Submit"**

### 2.3 複製 API Key

**⚠️ 重要**: API Key 只會顯示一次!

1. 建立後會立即顯示 API Key
2. 格式: `gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
3. 點選 **"Copy"** 按鈕複製
4. 妥善保存這個 Key (可以貼到記事本暫存)

**如果不小心關閉視窗,只能刪除舊的 Key 並建立新的。**

---

## 步驟 3: 了解 Groq API 配額

### 免費方案限制

| 項目 | 限制 |
|------|------|
| **Requests/minute** | 30 |
| **Requests/day** | 14,400 |
| **Tokens/minute** | 6,000 |
| **Tokens/day** | 無限制 |

### 什麼是 Token?

Token 是 AI 模型處理文字的基本單位:
- 1 個英文單字 ≈ 1-2 tokens
- 1 個中文字 ≈ 2-3 tokens
- 平均 1,000 tokens ≈ 750 英文單字或 400 中文字

### 本系統的使用量估算

**會議記錄整理** (每次):
- 輸入: 1,000 字會議記錄 ≈ 2,000 tokens
- 輸出: 500 字摘要 ≈ 1,000 tokens
- 總計: ≈ 3,000 tokens

**科技新聞翻譯** (每天):
- 輸入: 10 則英文新聞 ≈ 3,000 tokens
- 輸出: 翻譯和摘要 ≈ 2,000 tokens
- 總計: ≈ 5,000 tokens

**結論**: 免費額度足夠每天:
- 整理 2 次會議記錄
- 翻譯 1 次科技新聞
- 其他臨時使用

---

## 步驟 4: 測試 API

使用以下 PowerShell 指令測試 API 是否可用:

```powershell
$apiKey = "YOUR_GROQ_API_KEY_HERE"

$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type" = "application/json"
}

$body = @{
    model = "llama-3.3-70b-versatile"
    messages = @(
        @{
            role = "user"
            content = "請用繁體中文回答: 你是誰?"
        }
    )
    temperature = 0.7
    max_tokens = 100
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod -Uri "https://api.groq.com/openai/v1/chat/completions" -Method POST -Headers $headers -Body $body

Write-Host "AI 回覆: $($response.choices[0].message.content)"
```

**預期輸出**:
```
AI 回覆: 我是一個 AI 助理...
```

---

## 步驟 5: 設定 .env 檔案

將 Groq API Key 填入 `C:\mis-assistant\.env` 檔案:

```env
# Groq API 設定
GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## 可用的 AI 模型

Groq 提供多個模型,本系統預設使用 **Llama 3.3 70B**。

### 推薦模型對比

| 模型名稱 | 速度 | 品質 | 適用場景 |
|---------|------|------|---------|
| **llama-3.3-70b-versatile** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 通用任務 (推薦) |
| llama-3.1-8b-instant | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | 簡單任務、快速回應 |
| mixtral-8x7b-32768 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 長文本處理 |
| gemma2-9b-it | ⭐⭐⭐⭐ | ⭐⭐⭐ | 對話、翻譯 |

**為什麼選擇 Llama 3.3 70B?**
- 繁體中文支援最好
- 理解能力強,適合會議記錄整理
- 翻譯品質高
- 速度與品質平衡

---

## 監控 API 使用量

### 查看用量統計

1. 登入 Groq Console
2. 點選左側選單的 **"Usage"**
3. 可以看到:
   - 每日/每月請求數
   - Token 使用量
   - 請求成功率

### 設定用量警告 (可選)

雖然 Groq 目前不支援自動警告,但你可以定期檢查用量:
- 每週檢查一次 Usage 頁面
- 如果接近限制,考慮減少請求頻率

---

## 進階使用

### 調整模型參數

在 n8n 工作流程中,你可以調整這些參數來優化結果:

#### Temperature (溫度)
- 範圍: 0-2
- 預設: 0.7
- **低 (0-0.5)**: 輸出更穩定、一致
- **中 (0.5-1.0)**: 平衡創意與穩定 (推薦)
- **高 (1.0-2.0)**: 輸出更有創意、隨機

#### Max Tokens (最大 Token 數)
- 限制輸出的長度
- 會議記錄推薦: 1500-2000
- 新聞摘要推薦: 800-1200

#### Top P
- 範圍: 0-1
- 預設: 1
- 控制輸出的多樣性

### 範例: 優化會議記錄整理

```json
{
  "model": "llama-3.3-70b-versatile",
  "temperature": 0.5,
  "max_tokens": 2000,
  "top_p": 0.9,
  "messages": [
    {
      "role": "system",
      "content": "你是一個專業的會議記錄整理助手,擅長提取重點、待辦事項和決議。"
    },
    {
      "role": "user",
      "content": "請整理以下會議記錄..."
    }
  ]
}
```

---

## 常見問題

### Q: Groq API 是免費的嗎?

A: 是的!Groq 目前提供慷慨的免費額度:
- 每分鐘 30 次請求
- 每天 14,400 次請求
- 足夠個人和小團隊使用

未來可能推出付費方案,但免費方案會持續提供。

### Q: 我的 API Key 過期了嗎?

A: Groq API Key 不會過期,除非你手動刪除它。

### Q: 達到請求限制會怎樣?

A: 會收到 HTTP 429 錯誤 (Too Many Requests),需要等待:
- 超過每分鐘限制: 等待到下一分鐘
- 超過每天限制: 等待到隔天 UTC 00:00

### Q: 如何管理多個 API Key?

A: 在 Groq Console 的 API Keys 頁面可以:
- 建立多個 Key (例如分別用於開發和正式環境)
- 隨時撤銷 (Revoke) 不需要的 Key
- 查看每個 Key 的建立日期

### Q: Groq 支援其他語言嗎?

A: 支援!Llama 3.3 70B 支援多種語言:
- 繁體中文 ✅
- 簡體中文 ✅
- 英文 ✅
- 日文 ✅
- 韓文 ✅
- 多數歐洲語言 ✅

### Q: 可以用於商業用途嗎?

A: 可以。Groq 的免費額度可用於商業用途,但請查看最新的使用條款。

---

## 錯誤排除

### 401 Unauthorized

**原因**: API Key 無效或格式錯誤

**解決方式**:
1. 檢查 API Key 是否正確複製 (包含 `gsk_` 前綴)
2. 確認 Key 沒有被撤銷
3. 重新建立新的 API Key

### 429 Too Many Requests

**原因**: 超過請求限制

**解決方式**:
1. 等待一分鐘後再試
2. 減少請求頻率
3. 考慮在 n8n 中加入延遲 (Delay) 節點

### 500 Internal Server Error

**原因**: Groq 伺服器問題

**解決方式**:
1. 等待幾分鐘後重試
2. 檢查 Groq 狀態頁面: https://status.groq.com
3. 如果持續發生,考慮切換到其他模型

### 輸出內容不符合預期

**解決方式**:
1. 調整 System Prompt (系統提示詞)
2. 降低 Temperature 獲得更穩定的輸出
3. 增加 Max Tokens 以獲得更完整的回應
4. 提供更明確的指令和範例

---

## 安全建議

1. **保護 API Key**
   - 不要提交到 Git 或公開分享
   - 使用環境變數存儲
   - 定期更換 Key

2. **監控使用量**
   - 每週檢查 Usage 頁面
   - 注意異常的請求數增長

3. **設定請求限制**
   - 在應用程式中實作 Rate Limiting
   - 避免在迴圈中無限制呼叫 API

4. **錯誤處理**
   - 實作重試機制 (但要加入延遲)
   - 記錄 API 錯誤以便排查

---

## 參考資源

- [Groq 官方文件](https://console.groq.com/docs)
- [API Reference](https://console.groq.com/docs/api-reference)
- [模型清單與規格](https://console.groq.com/docs/models)
- [Groq 狀態頁面](https://status.groq.com)
- [使用範例](https://github.com/groq/groq-python)

---

**下一步**: 部署 n8n 服務 → 請參考 [../README.md](../README.md)
