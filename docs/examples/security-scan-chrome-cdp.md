```
╔══════════════════════════════════════════════════════╗
║           AI 工具 資安掃描報告                        ║
╠══════════════════════════════════════════════════════╣
║  掃描時間：2026-04-04 12:54                          ║
║  掃描範圍：自訂路徑：                                 ║
║            /Users/lazyjerry/.claude/skills/chrome-cdp ║
║  掃描項目：1 skill                                   ║
╚══════════════════════════════════════════════════════╝
```

## 倉庫基本資訊

| 項目 | 值 |
|------|----|
| 類型 | **Claude Skill** |
| 檔案 | `SKILL.md`、`scripts/cdp.mjs` |
| 說明 | 透過 Chrome DevTools Protocol（CDP）控制本機 Chrome 瀏覽器：截圖、JS 執行、元素點擊、導航、無障礙樹快照等。無 Puppeteer 依賴，使用 Node.js 22+ 內建 WebSocket。 |
| 外部依賴 | 無（純 Node.js 標準模組）|

---

## 風險摘要

| 嚴重性 | 數量 |
|--------|------|
| Critical | **0** |
| High | **0** |
| Medium | **2** |
| Low | **1** |

---

## 各項目掃描結果

### ⚠️ chrome-cdp（發現風險）

---

**[Medium] B3 - eval / evalraw 任意代碼執行（預期用途，已知風險）**

- 位置：`scripts/cdp.mjs` 第 277–287 行（`evalStr`）、第 459–468 行（`evalRawStr`）
- 內容：
  ```js
  // eval 執行任意 JS
  const result = await cdp.send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true }, sid);
  // evalraw 傳送任意 CDP 方法
  const result = await cdp.send(method, params, sid);
  ```
- 說明：`eval` 允許在瀏覽器分頁中執行任意 JavaScript；`evalraw` 更進一步，允許傳送任意 CDP Protocol 指令（包括 `Page.navigate`、`Network.enable`、`DOM.getDocument` 等完整 CDP API）。這是 CDP 工具的**核心設計**，屬於預期功能而非惡意行為。然而，使用者應理解：**此工具賦予 Claude 在瀏覽器中執行任意 JS 的能力**，SKILL.md 中的「only on explicit user approval」為 AI 行為指引，並無技術層面的強制執行機制。

---

**[Medium] D2 - shot 命令接受任意檔案路徑寫入**

- 位置：`scripts/cdp.mjs` 第 289–325 行（`shotStr`）
- 內容：
  ```js
  const out = filePath || resolve(RUNTIME_DIR, `screenshot-${...}.png`);
  writeFileSync(out, Buffer.from(data, 'base64'));
  ```
- 說明：`shot <target> [file]` 的 `file` 參數直接作為 `writeFileSync` 的路徑，**無路徑範圍限制**。若 AI 指定任意絕對路徑（例如 `~/Desktop/secret.png`），工具將直接寫入。預設路徑為 `~/.cache/cdp/`（權限 0700），屬安全範圍；但自訂路徑無防護。實際風險有限（僅能寫入 PNG 截圖），但需知情。

---

**[Low] G4-3 - 授權機制純依賴 AI 指令遵守**

- 位置：`SKILL.md` 第 3 行（description）
- 內容：`only on explicit user approval after being asked to inspect, debug, or interact with a page open in Chrome`
- 說明：授權限制（需使用者明確同意才使用）僅寫在 SKILL.md 的 description 中，作為 AI 助手的行為指引。技術層面**無任何強制機制**——腳本不驗證是否取得授權，亦無確認步驟。若 AI 助手誤判或被誘導，可能在使用者未明確同意下執行瀏覽器操作。

---

## ✅ 無問題項目

| 規則 | 說明 |
|------|------|
| A. 提示注入 | SKILL.md 無覆寫指令、無身份偽冒、無隱藏觸發詞 |
| C1. 憑證讀取 | 僅讀取 `DevToolsActivePort`（瀏覽器調試端口），非 SSH/AWS 等敏感憑證 |
| C2. 資料外洩 | **無任何外部 HTTP 呼叫**，所有操作僅在本機 WebSocket（127.0.0.1） |
| D1. 提權操作 | 無 `sudo`，無系統目錄修改 |
| D3. 修改 AI 設定 | 無寫入 `~/.claude/`、`~/.cursor/` 等 AI 工具設定 |
| E. 社交工程 | description 與實際行為一致，無誤導性聲稱 |
| F. 遙測追蹤 | **完全無遙測**——無 analytics、無追蹤 ID、無遠端上傳、無本地結構化日誌 |

### 🔒 安全亮點

- `process.umask(0o077)`（第 23 行）：確保所有建立的檔案預設為 600/700 權限
- RUNTIME_DIR 使用 `mode: 0o700` 建立（第 29 行）
- 頁面快取 `pages.json` 使用 `mode: 0o600`（第 785、803 行）
- `nav` 指令強制驗證 URL 協議（只允許 http/https，第 361–366 行）
- 連線僅至 `127.0.0.1`（localhost），不允許遠端連線

---

## 遙測與追蹤分析

| 項目 | 結果 |
|------|------|
| 本地紀錄 | 無 |
| 遠端上傳 | 無 |
| 追蹤 ID | 無 |
| 持久化資料 | 僅 `~/.cache/cdp/pages.json`（分頁清單快取，非追蹤用途）|

---

## 安裝建議

### ✅ 建議安裝

**理由：**
- 程式碼簡潔透明（870 行，單一檔案），功能與宣稱完全一致
- 無任何遙測、無外部網路呼叫、無憑證存取
- 安全基礎扎實（umask、socket 權限、URL 協議驗證）
- 純本機操作，唯一網路目標為 `127.0.0.1`（Chrome 調試端口）

**安裝後注意事項：**
1. **Chrome 遠端調試需手動啟用**：需在 `chrome://inspect/#remote-debugging` 開啟，並非預設啟用
2. **eval 執行能力**：此工具允許 Claude 在瀏覽器中執行任意 JS，使用時請確認 Claude 已取得您的明確同意
3. **evalraw 指令**：暴露完整 CDP API，功能強大，建議僅在了解 CDP 協議時使用
4. **截圖路徑**：使用 `shot` 時若需自訂路徑，請注意路徑安全性

---

> ⚠️ **提醒**：本報告由 AI 自動產生，結果可能存在誤判（false positive）或遺漏（false negative）。所有發現皆需經人工核實與驗證，不應作為唯一的安全評估依據。
