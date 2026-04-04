# 安全審計報告：`YishenTu/claudian`

> 審計日期：2026-04-04

## 📦 套件類型

**Obsidian 外掛（桌面專用）**，將 Anthropic Claude Code CLI 嵌入 Obsidian 作為 AI 代理人，具備完整的檔案讀寫、bash 指令執行、MCP 整合等能力。版本：`1.3.72`

---

## 🔴 高風險

| # | 問題 | 說明 |
|---|------|------|
| 1 | **YOLO 模式為預設值** | README 明確指出「YOLO mode: No approval prompts; all tool calls execute automatically (default)」。安裝後 AI 可直接執行任意 bash 指令、讀寫檔案，無需使用者確認。 |
| 2 | **提示注入風險（Prompt Injection）** | 外掛會自動載入聚焦的 Obsidian 筆記作為 AI 上下文。若 vault 中存在惡意內容（如從外部來源同步的筆記），可透過提示注入操控 AI 行為，在 vault 範圍內執行非預期操作。 |

---

## 🟠 中風險

| # | 問題 | 說明 |
|---|------|------|
| 3 | **Bash 路徑解析為「最佳努力」** | `BashPathValidator.ts` 原始碼注釋明確說明：「This is a best-effort tokenizer; full bash parsing is out of scope」。複雜的 bash 語法（如變數展開 `$VAR`、heredoc、process substitution `<(...)` 等）無法被正確偵測，可能繞過 vault 限制。 |
| 4 | **載入使用者 Claude 設定可繞過安全模式** | 設定項「Load user Claude settings」會載入 `~/.claude/settings.json`，文件說明「may bypass Safe mode」。這允許全域 Claude Code 設定覆蓋外掛的安全控制。 |
| 5 | **Skills/Agents 自動從磁碟載入** | 外掛自動掃描 `~/.claude/skills/`、`~/.claude/agents/`、`~/.claude/plugins/` 中的檔案。若這些目錄被入侵或遭投毒，惡意的 skill/agent 定義將自動被 AI 使用。 |
| 6 | **ANTHROPIC_BASE_URL 可被自訂** | 環境變數設定允許使用者覆蓋 `ANTHROPIC_BASE_URL`，可將 API 流量導向非 Anthropic 端點，存在中間人攻擊風險。 |

---

## 🟡 低風險

| # | 問題 | 說明 |
|---|------|------|
| 7 | **ReDoS 潛在風險** | `BlocklistChecker.ts` 將使用者輸入的字串直接編譯為 `RegExp`，雖有 `MAX_PATTERN_LENGTH = 500` 限制，但惡意正規表達式仍可能造成效能問題。 |
| 8 | **API 金鑰儲存於 vault** | 環境變數（含 `ANTHROPIC_API_KEY`）儲存在 `.claude/settings.json`，若 vault 是 git repo 且未設定 `.gitignore`，可能意外提交至遠端倉庫。（`.gitignore` 僅忽略 `settings.local.json`） |
| 9 | **External Contexts 具完整讀寫權限** | 使用者透過 UI 加入的外部目錄（External Contexts）享有完整讀寫存取，範圍超出 vault 之外。 |

---

## ✅ 安全設計亮點

- **Vault 封閉機制**：透過 `realpath` 驗證 symlink，防止路徑遍歷逃逸
- **Safe/Plan 模式**：可啟用逐一工具呼叫審核
- **阻止清單（Blocklist）**：可設定正規表達式封鎖危險指令
- **Export paths 為唯寫**：`~/Desktop`、`~/Downloads` 等路徑僅允許寫入
- **純開發依賴、無可疑第三方套件**：核心依賴僅 `@anthropic-ai/claude-agent-sdk` 與 `@modelcontextprotocol/sdk`

---

## 📋 安裝前建議

> ⚠️ 這是一個 **高權限 AI 代理人外掛**，本質上允許 AI 控制你的電腦（僅限 vault 目錄及已設定路徑）。

**安裝前請確認：**
1. **立即切換至 Safe 模式**（設定 → Safety），避免使用預設 YOLO 模式
2. **不要在包含不可信內容的 vault 使用**（提防提示注入）
3. **勿在 vault 中儲存 API 金鑰**，或確保 vault 不被 git 追蹤敏感檔案
4. **定期檢查** `~/.claude/skills/` 與 `~/.claude/agents/` 的內容
