# ccundo 完整安全審查報告

**工具：** `ccundo` v1.1.1 — Claude Code undo/redo CLI  
**來源：** https://github.com/RonitSachdev/ccundo  
**審查日期：** 2026-04-04  
**審查範圍：** 全部原始碼（12 個檔案）

---

### 整體評級：🟡 中等風險（無惡意，但有隱私與安全疑慮）

---

### ✅ 無惡意行為確認

| 項目 | 結果 |
|------|------|
| 外部網路請求 | ✅ 無 |
| 遙測 / 追蹤 | ✅ 無 |
| 竊取憑證或 API Key | ✅ 無 |
| 提示注入 (Prompt Injection) | ✅ 無 |
| 依賴套件風險 | ✅ 僅 `chalk`、`commander`、`inquirer`，均為主流套件 |

---

### ⚠️ 發現的安全疑慮

#### 🔴 高風險 1：讀取並暴露 Claude 完整對話歷史

**檔案：** `src/core/ClaudeSessionParser.js`

```js
this.claudeProjectsDir = path.join(os.homedir(), '.claude', 'projects');
// 讀取所有 .jsonl 對話記錄
const sessionFiles = files.filter(f => f.endsWith('.jsonl'));
```

工具解析 `~/.claude/projects/**/*.jsonl`，這些檔案包含**所有對話歷程**，包括您貼入的程式碼、可能的密碼、API Key 等敏感內容。

---

#### 🔴 高風險 2：備份含完整檔案內容，無加密

**檔案：** `src/hooks/claude-tracker.js`、`src/core/UndoManager.js`

```js
// Hook 讀取原始檔案完整內容
originalContent = await fs.readFile(input.parameters.file_path, 'utf8');
// 儲存到 ~/.ccundo/sessions/*.json（明文，無加密）
await fs.writeFile(backupPath, content);
```

每次 Claude 編輯檔案前，hook 都會讀取並儲存完整檔案內容到 `~/.ccundo/`，若專案含敏感資料（.env、私鑰等），將產生**明文副本**。

---

#### 🟡 中等風險 1：路徑穿越（Path Traversal）無防護

**檔案：** `UndoManager.js`、`RedoManager.js`

```js
// 直接使用 session 中的路徑，未過濾 ../
await fs.unlink(filePath);         // 可能刪除任意檔案
await fs.writeFile(filePath, content); // 可能覆寫任意檔案
await fs.rename(newPath, oldPath); // 可能移動任意路徑
```

若 session 檔案被竄改，攻擊者可透過 `../../../etc/passwd` 等路徑執行任意檔案操作。

---

#### 🟡 中等風險 2：Bash 命令的 Regex 解析不可靠

**檔案：** `src/hooks/claude-tracker.js`、`ClaudeSessionParser.js`

```js
// 無法正確處理引號、萬用字元、管線
const match = command.match(/rm\s+(?:-[rf]+\s+)?([^\s]+)/);
// `rm -rf "my file.txt"` → 會解析出 `"my` 而非 `my file.txt`
```

含空格檔名、glob 模式、管線的複雜指令會被解析錯誤，導致 undo 目標錯誤。

---

#### 🟡 中等風險 3：`process.argv` 無驗證直接 JSON.parse

**檔案：** `src/hooks/claude-tracker.js`

```js
const input = JSON.parse(process.argv[2] || '{}');
```

Hook 直接將命令列參數解析為 JSON，雖然資料來源是 Claude Code，但沒有任何 schema 驗證，惡意格式的輸入可能導致意外行為。

---

#### 🟢 低風險：備份路徑可預測

```js
const backupPath = path.join(this.backupDir, `${operation.id}-deleted`);
```

備份路徑格式固定且可預測，雖非直接漏洞，但缺乏存取控制或完整性驗證。

---

### 📋 安裝建議

| 建議 | 說明 |
|------|------|
| ⚠️ 敏感專案謹慎使用 | 包含 .env、私鑰、憑證的專案，備份檔會洩漏至 `~/.ccundo/` |
| 🧹 定期清理備份 | 定期執行 `rm -rf ~/.ccundo/sessions/ ~/.ccundo/backups/` |
| 🔒 設定目錄權限 | `chmod 700 ~/.ccundo` 限制其他使用者存取 |
| ✅ 可安全安裝 | 工具本身無惡意，可正常使用於一般開發專案 |

**最終結論：此工具為合法的開發輔助工具，無惡意行為，可以安裝。主要風險為本地隱私問題，而非安全攻擊。**
