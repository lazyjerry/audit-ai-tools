```
╔══════════════════════════════════════════════════════╗
║        GitHub 倉庫資安掃描報告                       ║
╠══════════════════════════════════════════════════════╣
║  倉庫：YishenTu/claudian                             ║
║  網址：https://github.com/YishenTu/claudian          ║
║  掃描時間：2026-04-04 12:42:56                       ║
╚══════════════════════════════════════════════════════╝
```

## 倉庫基本資訊

| 項目 | 值 |
|------|----|
| 類型 | Claude Plugin（Obsidian 插件）、Claude AGENTS.md、Claude CLAUDE.md |
| 說明 | 將 Claude Code 嵌入 Obsidian 側欄的聊天介面。Vault 目錄成為 Claude 的工作目錄，提供完整 agentic 能力：檔案讀寫、Bash 指令、多步驟工作流程。 |
| 版本 | 1.3.72 |
| 授權 | MIT |
| 主要依賴 | `@anthropic-ai/claude-agent-sdk`, `@modelcontextprotocol/sdk` |
| CI/CD | GitHub Actions（lint / typecheck / test）|

---

## 偵測到的 AI 工具擴充

### Claude Plugin（Obsidian 插件）
- 檔案：`manifest.json`、`src/main.ts`（入口點）
- 用途摘要：透過 `@anthropic-ai/claude-agent-sdk` 將 Claude Code 嵌入 Obsidian，讓使用者可在 sidebar 與 Claude 互動。Vault 目錄為 Claude 的工作目錄。
- 安裝後影響：在 Obsidian 中新增 Claudian 側欄面板；Claude 可讀寫 vault 內所有檔案並執行 Bash 指令。這是明確宣告的功能，非隱藏行為。

### Claude AGENTS.md
- 檔案：`./AGENTS.md`
- 內容：`Read CLAUDE.md for the agent overview and instructions.`（僅一行導向）

### Claude CLAUDE.md（開發者文件）
- 檔案：`./CLAUDE.md`、`./src/core/CLAUDE.md`、`./src/style/CLAUDE.md`
- 用途：開發者架構說明文件，非指令注入。

---

## 風險摘要

| 嚴重性   | 數量 |
|---------|------|
| Critical |  0  |
| High     |  0  |
| Medium   |  1  |
| Low      |  1  |

---

## 詳細發現

### ✅ A. 提示注入（Prompt Injection）— 無問題

- `mainAgent.ts` 的系統提示內容經過完整審查：
  - 身份清楚聲明為 "Claudian"，無偽冒其他 AI 或解除限制的指令
  - 無 `ignore previous instructions`、`jailbreak`、`developer mode` 等關鍵字
  - 無大量空白夾藏指令、Unicode 零寬字符、Base64 隱藏指令
  - 無隱藏觸發詞後門邏輯

### ✅ B. 指令注入（Command Injection）— 無問題

- `customSpawn.ts` 動態解析 Node.js 執行路徑（解決 Obsidian GUI 的最小 PATH 問題），使用固定參數，無使用者輸入直接注入 shell 的情形
- `BashPathValidator` 有完整的路徑逸出防護
- 無 `curl | bash`、`rm -rf /` 等危險指令組合

### ✅ C. 資料外洩（Data Exfiltration）— 無問題

- 全程式碼庫無對外部第三方端點的 HTTP POST/fetch 呼叫
- README 明確聲明：「**No telemetry**: No tracking beyond your configured API provider.」
- 無讀取 `~/.ssh/`、`~/.aws/credentials`、`.env`、`id_rsa` 等敏感憑證檔案的指令
- 資料流向僅為：使用者 → Anthropic API（使用者自行設定端點）

### ✅ D. 權限升級（Privilege Escalation）— 無問題

- 無 `sudo` 相關操作
- 安全架構完整（三層防護）：
  1. `SecurityHooks.ts`：PreToolUse hook 強制 vault 限制與指令黑名單
  2. `BashPathValidator.ts`：防止 Bash 指令路徑逸出 vault
  3. `BlocklistChecker.ts`：阻擋平台相關危險指令

### ✅ E. 社交工程（Social Engineering）— 無問題

- README 與原始碼行為高度一致，無隱藏意圖
- 系統提示誠實呈現 Claudian 的角色與限制，無虛假授權聲稱

### ✅ F. 遙測與分析追蹤（Telemetry）— 無問題

- 全程式碼庫無 analytics、telemetry、tracking 相關函式
- 無 JSONL/結構化使用日誌寫入
- 無 `installation_id`、`device_id` 等持久追蹤識別碼
- 無遠端上傳機制

### ⚠️ [Medium] D2 - 超出範圍的檔案系統存取（設計選項）

- 位置：`src/core/prompts/mainAgent.ts`、設定項 `allowExternalAccess`
- 內容：當使用者開啟「Allow External Access」選項時，Claude 可存取 vault 以外的整個檔案系統
- 說明：此為使用者可自行選擇的功能，README 有明確說明，屬已知設計行為。**非惡意**，但使用者應理解開啟此選項的影響範圍。

### ℹ️ [Low] G4-1 - postinstall 腳本（低風險）

- 位置：`scripts/postinstall.mjs`
- 內容：
  ```js
  // Skip in CI environments
  if (process.env.CI) { process.exit(0); }
  // Only copies .env.local.example → .env.local if file doesn't exist
  copyFileSync(example, target);
  ```
- 說明：行為透明，無 sudo、無遠端下載、無 shell 設定修改。僅在非 CI 環境下建立本機開發設定範本，屬預期行為。

---

## 遙測與追蹤分析

### 本地紀錄行為
- 無任何遙測紀錄行為

### 遠端上傳行為
- 無第三方上傳端點
- 所有 API 呼叫僅指向 Anthropic API（`ANTHROPIC_BASE_URL` 可由使用者自訂）

### 追蹤 ID
- 是否存在持久 ID：**否**
- 無任何識別碼建立或跨 session 追蹤機制

---

## GitHub Actions 安全分析

| 工作流程 | 使用的 Action | 風險評估 |
|---------|------------|---------|
| `ci.yml` | `actions/checkout@v4`、`actions/setup-node@v4` | ✅ 標準 |
| `claude-code-review.yml` | `anthropics/claude-code-action@v1` | ✅ Anthropic 官方 |
| `claude.yml` | `anthropics/claude-code-action@v1` | ✅ Anthropic 官方（需 `@claude` 觸發）|
| `release.yml` | 標準 release 流程 | ✅ 標準 |

- `claude.yml` 需 issue/PR 評論中包含 `@claude` 才觸發，設計合理
- `CLAUDE_CODE_OAUTH_TOKEN` 使用 GitHub Secrets 儲存，未硬編碼於程式碼

---

## 安裝建議

✅ **建議安裝**

**理由：**
- 程式碼透明、架構清晰，README 描述與實際行為完全一致
- 具備完整的安全防護機制（SecurityHooks、BashPathValidator、BlocklistChecker）
- 明確聲明無遙測追蹤，並經程式碼驗證屬實
- 使用 Anthropic 官方 SDK，依賴關係最小化
- MIT 授權，開放原始碼
- 具完整 CI/CD（lint / typecheck / test）

**安裝後注意事項：**
1. **Vault 存取範圍**：Claude 預設可讀寫整個 vault，請確認 vault 內無不應讓 AI 操作的敏感資料
2. **External Access 選項**：若不需要，請保持此選項關閉，避免 Claude 存取 vault 以外的檔案系統
3. **API Key 安全**：API Key 儲存於 Obsidian 設定中，請確保設備本身的安全性
4. **MCP Server**：如需使用 MCP 功能，請僅設定可信任的 MCP server

---

> ⚠️ **提醒**：本報告由 AI 自動產生，結果可能存在誤判（false positive）或遺漏（false negative）。所有發現皆需經人工核實與驗證，不應作為唯一的安全評估依據。
