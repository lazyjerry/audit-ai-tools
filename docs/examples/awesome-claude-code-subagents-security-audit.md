# 安全審計報告：`VoltAgent/awesome-claude-code-subagents`

> 審計日期：2026-04-04

## 📦 套件類型

**Claude Code Subagent 社群集合**，收錄 129 個專用 AI 代理人定義（Markdown + YAML frontmatter），分為 10 大類別。提供互動式安裝腳本與 `.claude-plugin` 格式的 Marketplace 整合。

---

## 🔴 高風險

| # | 問題 | 說明 |
|---|------|------|
| 1 | **`settings.local.json` 已提交至 repo，且預先授權 Bash 指令** | `.claude/settings.local.json` 被提交進版本控制，內容包含 `"Bash(for:*)"` 及 `"Bash(python3:*)"` 的全域允許規則。任何克隆此 repo 並以其為工作目錄使用 Claude Code 的人，都會繼承這些預先授權，無需審核即可執行 for 迴圈和任意 Python 程式碼。 |
| 2 | **安裝腳本下載內容時無完整性驗證** | `install-agents.sh` 使用 `curl -sS "$url" -o "$dest_path"` 直接從 GitHub main 分支下載 agent 定義，**完全沒有** checksum、hash 或簽章驗證。若 repo 遭到供應鏈攻擊（帳號劫持、惡意 PR 合併），惡意 agent 定義會直接寫入使用者的 `~/.claude/agents/`，且無任何警告。 |
| 3 | **社群貢獻 repo，缺乏 agent 內容安全審查機制** | 這是公開接受 PR 的社群集合，但 CONTRIBUTING.md 中沒有描述任何針對 agent 提示內容的安全審查程序。惡意貢獻者可偽裝成正常 agent 提交含有提示注入或濫用指令的定義。 |

---

## 🟠 中風險

| # | 問題 | 說明 |
|---|------|------|
| 4 | **多數 agent 預設授予完整 Bash 存取** | 大量 agent（包含 `penetration-tester`、`agent-installer`、`it-ops-orchestrator` 等）在 frontmatter 中宣告 `tools: Bash`，並以 `model: opus` 執行。這些 agent 一旦被 auto-select 或呼叫，即可執行任意 shell 指令。 |
| 5 | **`agent-installer` meta-agent 可從網路下載並安裝任意 agent** | `agent-installer.md` 具備 `tools: Bash, WebFetch, Read, Write`，設計上會從 GitHub 取得 agent 定義並寫入檔案系統。若被提示注入劫持，可用來下載並安裝任意惡意 agent。 |
| 6 | **永遠從 `main` 分支拉取，無版本鎖定** | 所有遠端安裝均從 `GITHUB_RAW_BASE/.../main/...` 拉取，不綁定特定 commit 或 tag。更新不需使用者確認，靜默上線。 |
| 7 | **`penetration-tester` agent 具備主動攻擊能力描述** | 該 agent 包含 reconnaissance、exploit development、lateral movement、persistence mechanisms 等詳細攻擊步驟，並有 Bash 存取權限。雖標榜「授權測試」，但若被誤觸或提示注入，實際執行環境無法保證是否合法。 |

---

## 🟡 低風險

| # | 問題 | 說明 |
|---|------|------|
| 8 | **Agent `description` 欄位用於 auto-selection，可被設計為自動觸發** | Claude Code 依據 description 自動選擇 agent。若某 agent description 故意描述得過於廣泛，可能在非預期情境被自動呼叫，擴大其工具存取範圍。 |
| 9 | **安裝腳本解析 GitHub API JSON 使用 grep/sed，易受格式變化影響** | 腳本以 `grep -o '"name": "[^"]*"' | sed ...` 解析 JSON，無法正確處理跳脫字元或格式異常，邊緣情況可能導致誤安裝或安裝失敗。 |
| 10 | **GitHub API 速率限制（60 次/小時）無驗證機制** | 未認證的 API 請求易被限速，腳本雖有提示但缺乏令牌設定選項，可能在批次安裝時中斷。 |

---

## ✅ 設計亮點

- **安裝前明確確認**：`confirm_and_apply()` 會顯示將安裝/移除的 agent 清單，要求 `y/N` 確認
- **支援 global/local 兩種安裝模式**：可限制 agent 作用範圍至單一專案
- **分類結構清晰**：10 個類別有助於使用者了解各 agent 的用途與風險範圍
- **多數 read-only agent 正確限縮工具**：reviewer、auditor 類 agent 僅宣告 `Read, Grep, Glob`

---

## 📋 安裝前建議

> ⚠️ 這是一個**社群維護的 AI 代理人集合**，安裝後 agent 定義會直接影響 Claude Code 的行為與工具存取權限。

**安裝前請確認：**
1. **逐一審閱每個 agent 的 YAML frontmatter**，確認 `tools:` 欄位中有無不必要的 `Bash` 或 `Write` 權限
2. **優先選擇 local 安裝**（`.claude/agents/`）而非 global，縮小影響範圍
3. **不要直接克隆此 repo 作為工作目錄**，否則 `.claude/settings.local.json` 的 `Bash(for:*)` 等預授權將立即生效
4. **下載後以文字編輯器檢查 `.md` 內容**，再手動複製至 agents 目錄，勿盲目執行安裝腳本的 remote 模式
5. **定期審查** `~/.claude/agents/` 目錄，移除不再使用的 agent
