# Telegram Bot 設定指南

本指南將協助你建立並設定 Telegram Bot,用於接收 MIS 助理系統的通知。

## 前置需求

- 擁有 Telegram 帳號
- 已安裝 Telegram 應用程式 (手機或桌面版)

---

## 步驟 1: 建立 Telegram Bot

### 1.1 找到 BotFather

1. 開啟 Telegram
2. 在搜尋欄輸入: `@BotFather`
3. 點選官方的 BotFather (會有藍色勾勾驗證標記)
4. 點選 "開始" 或發送 `/start`

### 1.2 建立新 Bot

1. 發送指令: `/newbot`
2. BotFather 會要求你提供 Bot 的名稱
   - 輸入例如: `MIS Assistant`
   - 這是顯示名稱,可以包含空格和中文

3. 接著要求你設定 Bot 的用戶名 (username)
   - 必須以 `bot` 結尾
   - 只能包含英文、數字和底線
   - 例如: `my_mis_assistant_bot`

4. 如果用戶名可用,BotFather 會建立 Bot 並提供:
   - Bot Token (格式: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`)
   - Bot 的連結

**⚠️ 重要: 請妥善保管 Bot Token,任何人擁有此 Token 都能控制你的 Bot!**

### 範例對話

```
You: /newbot

BotFather: Alright, a new bot. How are we going to call it? Please choose a name for your bot.

You: MIS Assistant

BotFather: Good. Now let's choose a username for your bot. It must end in `bot`. Like this, for example: TetrisBot or tetris_bot.

You: my_mis_assistant_bot

BotFather: Done! Congratulations on your new bot. You will find it at t.me/my_mis_assistant_bot. You can now add a description, about section and profile picture for your bot, see /help for a list of commands.

Use this token to access the HTTP API:
1234567890:ABCdefGHIjklMNOpqrsTUVwxyz

For a description of the Bot API, see this page: https://core.telegram.org/bots/api
```

---

## 步驟 2: 設定 Bot 指令 (可選)

為了讓使用更方便,你可以為 Bot 設定指令選單。

### 2.1 設定指令清單

1. 在 BotFather 聊天中發送: `/setcommands`
2. 選擇你剛建立的 Bot
3. 發送以下指令清單:

```
status - 查看系統狀態
logs - 查看最新日誌
restart - 重啟異常容器
backup - 手動執行備份
help - 顯示幫助訊息
```

4. 完成後,在 Bot 聊天視窗中點選輸入欄旁的 `/` 按鈕就能看到指令清單

### 2.2 設定 Bot 描述 (可選)

```
/setdescription
選擇你的 Bot
輸入描述: "MIS 自動化助理 - Docker 容器監控、資料庫備份、會議記錄整理"
```

### 2.3 設定 Bot 關於 (可選)

```
/setabouttext
選擇你的 Bot
輸入: "自動監控 Docker 容器並發送通知"
```

---

## 步驟 3: 取得你的 Chat ID

Bot Token 只能讓程式發送訊息,但還需要知道要發送給誰。這就是 Chat ID 的用途。

### 方法 1: 使用 userinfobot

1. 在 Telegram 搜尋: `@userinfobot`
2. 點選 "開始" 或發送任意訊息
3. Bot 會回覆你的資訊,包括 `Id`
4. 複製這個數字 (例如: `123456789`)

### 方法 2: 使用你的 Bot

1. 在 Telegram 搜尋你剛建立的 Bot
2. 點選 "開始" 或發送 `/start`
3. 開啟瀏覽器,訪問:
   ```
   https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
   ```
   將 `<YOUR_BOT_TOKEN>` 替換成你的 Bot Token

4. 你會看到 JSON 格式的回應,找到 `"chat":{"id":123456789}`
5. 這個數字就是你的 Chat ID

---

## 步驟 4: 測試 Bot

使用以下 PowerShell 指令測試 Bot 是否能發送訊息:

```powershell
$botToken = "YOUR_BOT_TOKEN_HERE"
$chatId = "YOUR_CHAT_ID_HERE"
$message = "Hello from MIS Assistant!"

$url = "https://api.telegram.org/bot$botToken/sendMessage"
$body = @{
    chat_id = $chatId
    text = $message
} | ConvertTo-Json

Invoke-RestMethod -Uri $url -Method POST -ContentType "application/json" -Body $body
```

如果成功,你會在 Telegram 收到測試訊息!

---

## 步驟 5: 設定 .env 檔案

將 Bot Token 和 Chat ID 填入 `C:\mis-assistant\.env` 檔案:

```env
# Telegram Bot 設定
TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_CHAT_ID=123456789
```

---

## 進階設定

### 允許 Bot 接收指令

如果你希望 Bot 能接收你發送的指令 (例如 `/status`),需要:

1. 對 BotFather 發送: `/setprivacy`
2. 選擇你的 Bot
3. 選擇 "Disable" (關閉隱私模式)

這樣 Bot 就能接收所有訊息了。

### 設定 Bot 頭像

1. 對 BotFather 發送: `/setuserpic`
2. 選擇你的 Bot
3. 上傳一張圖片作為頭像

### 建立 Bot 選單按鈕

n8n 支援建立 Telegram 鍵盤選單,讓使用者可以點選按鈕而不用輸入指令。

範例:
```javascript
// 在 n8n 的 Telegram 節點中
{
  "reply_markup": {
    "keyboard": [
      [{"text": "📊 系統狀態"}],
      [{"text": "🔄 執行備份"}, {"text": "📝 查看日誌"}],
      [{"text": "❓ 說明"}]
    ],
    "resize_keyboard": true
  }
}
```

---

## 常見問題

### Q: 我忘記 Bot Token 了怎麼辦?

A: 無法找回舊的 Token,但可以生成新的:
1. 對 BotFather 發送 `/mybots`
2. 選擇你的 Bot
3. 選擇 "API Token"
4. 選擇 "Revoke current token" (撤銷舊 Token 並生成新的)

### Q: 可以讓多個人接收通知嗎?

A: 可以。有兩種方式:
1. 建立 Telegram 群組,將 Bot 加入群組,使用群組的 Chat ID
2. 在 n8n 中設定多個 Telegram 發送節點,每個節點使用不同的 Chat ID

要取得群組的 Chat ID:
1. 將 Bot 加入群組
2. 在群組中發送訊息
3. 訪問 `https://api.telegram.org/bot<TOKEN>/getUpdates`
4. 找到群組的 Chat ID (通常是負數,例如 `-123456789`)

### Q: Bot 收不到訊息怎麼辦?

A: 檢查以下項目:
1. 確認 Bot Token 正確
2. 確認 Chat ID 正確
3. 確認已對 Bot 發送過 `/start`
4. 檢查網路連線
5. 確認 Bot 沒有被封鎖

### Q: 如何刪除 Bot?

A: 對 BotFather 發送 `/deletebot`,選擇要刪除的 Bot。

**注意: 此操作無法復原!**

---

## 安全建議

1. **不要分享 Bot Token**: Token 等同於密碼,任何人有了 Token 就能控制你的 Bot
2. **定期更換 Token**: 如果懷疑 Token 洩漏,立即撤銷並生成新的
3. **使用環境變數**: 不要把 Token 直接寫在程式碼中
4. **限制 Bot 權限**: 只給 Bot 必要的權限
5. **監控 Bot 活動**: 定期檢查 Bot 的訊息歷史

---

## 參考資源

- [Telegram Bot API 官方文件](https://core.telegram.org/bots/api)
- [BotFather 完整指令列表](https://core.telegram.org/bots#botfather)
- [Telegram Bot 最佳實踐](https://core.telegram.org/bots/tutorial)

---

**下一步**: 設定 Groq API → 請參考 [groq-setup.md](groq-setup.md)
