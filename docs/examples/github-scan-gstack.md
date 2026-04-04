╔══════════════════════════════════════════════════════╗
║        GitHub 倉庫資安掃描報告                       ║
╠══════════════════════════════════════════════════════╣
║  倉庫：garrytan/gstack                               ║
║  網址：https://github.com/garrytan/gstack            ║
║  掃描時間：2026-04-04T02:12:00Z                      ║
╚══════════════════════════════════════════════════════╝

## 倉庫基本資訊

| 項目 | 值 |
|------|----|
| 類型 | **混合型**：Claude AGENTS.md + CLAUDE.md + Claude Skill（30+ 個）+ Chrome Extension（manifest.json） |
| 說明 | Garry Tan 的 Claude Code 工作流程：23 個 AI 工程 skill，涵蓋 CEO、設計師、工程主管、QA 等角色，含快速 headless 瀏覽器 |
| 星數 | 63,078 |
| Fork | 8,467 |
| 授權 | MIT License |
| 最後更新 | 2026-04-03 |
| CI/CD | 有（5 個 GitHub Actions workflow） |
| 版本 | 0.15.2.1 |

## 偵測到的 AI 工具擴充

### Claude AGENTS.md + CLAUDE.md
- 檔案：`AGENTS.md`、`CLAUDE.md`
- 用途摘要：定義可用 skill 清單、開發指令、測試流程
- 安裝後影響：提供 Claude Code 的全域行為指引

### Claude Skill（30+ 個）
- 檔案：根目錄 `SKILL.md` + 各子目錄的 `SKILL.md`
- 用途摘要：QA 測試、程式碼審核、設計審查、部署、瀏覽器自動化、安全審計等
- 安裝後影響：在 `~/.claude/skills/` 建立 symlink，每個 skill 在 preamble 中執行 bash 腳本（含遙測紀錄）

### Chrome Extension
- 檔案：`extension/manifest.json`
- 用途摘要：側邊面板連接 browse CLI 的 Chrome 擴充
- 安裝後影響：提供瀏覽器內的 gstack 互動介面

---

## 風險摘要

| 嚴重性   | 數量 |
|---------|------|
| Critical |  0  |
| High     |  4  |
| Medium   |  4  |
| Low      |  2  |

---

## 詳細發現

### ⚠️ [High] F2 - 記錄敏感專案中繼資料（本地 JSONL）

- 位置：`SKILL.md`:53、`bin/gstack-telemetry-log`:175-177、多個子 skill 的 preamble
- 內容：
  ```bash
  echo '{"skill":"gstack","ts":"...","repo":"'$(basename "$(git rev-parse --show-toplevel ...)")'"}'  >> ~/.gstack/analytics/skill-usage.jsonl
  ```
  以及 `bin/gstack-telemetry-log` 中：
  ```bash
  REPO_SLUG="$(git remote get-url origin ... )"
  BRANCH="$(git rev-parse --abbrev-ref HEAD ...)"
  ```
  寫入欄位包含 `_repo_slug` 和 `_branch`。
- 說明：每次執行 skill 時，**本地 JSONL** 會記錄 repo 名稱（basename）、repo slug（從 git remote URL 提取 `org-repo`）、分支名稱。這些資訊可能洩漏專案結構、客戶代號或功能名稱。標記為 `_` 前綴表示本地專用欄位，但**仍持久化至 `~/.gstack/analytics/skill-usage.jsonl`**。

### ⚠️ [High] F3 - 持久追蹤識別碼

- 位置：`bin/gstack-telemetry-log`:149-162
- 內容：
  ```bash
  ID_FILE="$HOME/.gstack/installation-id"
  INSTALL_ID="$(uuidgen | tr '[:upper:]' '[:lower:]')"
  printf '%s' "$INSTALL_ID" > "$ID_FILE"
  ```
- 說明：在 `community` tier 下，工具會使用 `uuidgen` 產生 UUID 並永久儲存於 `~/.gstack/installation-id`。此 ID 在多次 session 間重複使用，可用於跨 session 關聯使用者行為。ID 會被包含在遠端上傳 payload 中（`community` tier）。

### ⚠️ [High] F4 - 自動同步至遠端伺服器

- 位置：`bin/gstack-telemetry-sync`（全檔）、`supabase/config.sh`、`supabase/functions/telemetry-ingest/index.ts`
- 內容：
  ```bash
  GSTACK_SUPABASE_URL="https://frugpmstpnojnhfyimgv.supabase.co"
  curl -s ... -X POST "${SUPABASE_URL}/functions/v1/telemetry-ingest" ... -d "$BATCH"
  ```
- 說明：`gstack-telemetry-sync` 每 5 分鐘（rate limit）以背景方式將本地 JSONL 事件 POST 至 Supabase edge function。上傳前會剝離 `_repo_slug`、`_branch`、`repo` 欄位。`anonymous` tier 下會額外剝離 `installation_id`。上傳端點為 Supabase（`frugpmstpnojnhfyimgv.supabase.co`），使用公開 anon key。

### ⚠️ [High] G4-6 - CLAUDE.md 路由規則注入

- 位置：多個 skill 的 SKILL.md（`benchmark/SKILL.md`:168-205、`design-html/SKILL.md`:174-211 等）
- 內容：Skill 會檢查專案根目錄的 `CLAUDE.md` 是否存在 routing 規則，若無，會**提示使用者建立或修改 CLAUDE.md** 以加入 gstack 的 skill routing 區段。
- 說明：這會修改使用者專案的 AI 助手指令檔，導致 Claude 行為被 gstack 的路由規則控制。雖有徵求使用者同意（透過 AskUserQuestion），但**自動化程度高**，且會 commit 變更。

### ⚠️ [Medium] F5 - 遙測 Opt-out 架構偏差

- 位置：`SKILL.md` 的 telemetry prompt 區段、`bin/gstack-config` 中的設定檔註解
- 內容：Preamble 讀取 `_TEL`，若未設定則預設為 `off`（`${_TEL:-off}`）。但在首次 "lake intro" 後，工具會**主動詢問**使用者啟用遙測，並以「A) Help gstack get better! (recommended)」作為推薦選項。若使用者選 B 拒絕 community，會再次追問 anonymous 模式。
- 說明：遙測預設為 `off`（符合 opt-in 設計），但有**兩階段推銷式詢問**。推薦選項均為啟用遙測，且 description 宣稱「No code, file paths, or repo names are ever sent」，但**本地 JSONL 確實記錄了 repo 和 branch 名稱**（即使遠端上傳時會剝離）。description 有輕微誤導。

### ⚠️ [Medium] D3 - 修改 AI 助手設定（專案級 CLAUDE.md）

- 位置：同 G4-6
- 說明：Skill 會指示 AI 修改或建立專案的 `CLAUDE.md`，注入 gstack skill routing 規則。雖然有使用者確認步驟，但此行為超出一般 skill 預期範圍。

### ⚠️ [Medium] F6 - 結構化使用日誌

- 位置：`~/.gstack/analytics/skill-usage.jsonl`
- 紀錄內容：skill 名稱、時間戳、repo 目錄名、duration、outcome、branch、session_id、installation_id、error_class
- 說明：使用 JSONL 格式詳細記錄每次 skill 呼叫。結合 F2 的敏感中繼資料，本地日誌內容豐富。`gstack-telemetry-log` 在 tier=off 時會直接 exit，不寫入日誌。

### ⚠️ [Medium] B3 - eval 用於 gstack-slug 輸出

- 位置：`SKILL.md`:69、多個子 skill 的 preamble
- 內容：
  ```bash
  eval "$(~/.claude/skills/gstack/bin/gstack-slug 2>/dev/null)" 2>/dev/null || true
  ```
- 說明：使用 `eval` 執行 `gstack-slug` 的輸出。`gstack-slug` 有做輸入消毒（`tr -cd 'a-zA-Z0-9._-'`），風險可控，但 `eval` 模式本身仍需注意。屬於**預期用途，已知風險**。

### [Low] F6 - Session timeline 本地日誌

- 位置：`bin/gstack-timeline-log`
- 說明：記錄 skill 啟動事件到本地 timeline，含 skill 名、branch、session ID。明確標註「local-only, never sent anywhere」。

### [Low] G4-5 - 倉庫可信度

- 星數 63,078、Fork 8,467 — 高知名度專案
- MIT 授權、有完整 CI/CD、活躍維護
- 作者 Garry Tan 為 Y Combinator CEO — 公眾人物，信譽風險低

---

## 遙測與追蹤分析

### 本地紀錄行為
- 紀錄位置：`~/.gstack/analytics/skill-usage.jsonl`
- 紀錄格式：JSONL
- 紀錄內容：`v`、`ts`、`event_type`、`skill`、`session_id`、`gstack_version`、`os`、`arch`、`duration_s`、`outcome`、`error_class`、`error_message`、`failed_step`、`used_browse`、`sessions`、`installation_id`、`source`、**`_repo_slug`**、**`_branch`**
- 觸發條件：telemetry 設為 `anonymous` 或 `community` 時透過 `gstack-telemetry-log` 記錄完整欄位；部分 preamble 在 `_TEL != "off"` 時也直接寫入基本事件。**`off` 時不記錄。**

### 遠端上傳行為
- 上傳端點：`https://frugpmstpnojnhfyimgv.supabase.co/functions/v1/telemetry-ingest`
- 上傳內容：`v`、`ts`、`event_type`、`skill`、`session_id`、`gstack_version`、`os`、`arch`、`duration_s`、`outcome`、`error_class`、`used_browse`、`sessions`、`installation_id`（僅 community）
- 匿名化程度：**部分匿名** — 上傳前確實使用 `sed` 剝離 `_repo_slug`、`_branch`、`repo` 欄位。`anonymous` tier 再額外剝離 `installation_id`。
- Opt-out 機制：有，執行 `gstack-config set telemetry off` 即可完全停止本地紀錄與遠端上傳。

### 追蹤 ID
- 是否存在持久 ID：**是**（`community` tier）
- 儲存位置：`~/.gstack/installation-id`
- 用途：跨 session 關聯使用者行為、Supabase `installations` 表 upsert

---

## 安裝建議

- ⚠️ **謹慎考慮**
- 理由：
  1. 專案本身為高品質、高知名度的開源工具，功能豐富且有活躍維護。
  2. 遙測系統設計有預設 `off` 的正向 opt-in，但有較積極的推銷式同意流程。
  3. 本地 JSONL 會記錄 repo slug 和 branch name，即使遠端上傳時會剝離。
  4. 安裝後會大量建立 symlink 至 `~/.claude/skills/`，並可能修改專案 `CLAUDE.md`。
  5. 無 Critical 風險，無提示注入、無惡意行為、無憑證竊取。
- 若決定安裝，建議注意事項：
  1. 在遙測詢問時**選擇 B→B（完全關閉）**，或安裝後執行 `gstack-config set telemetry off`
  2. 在 routing 詢問時**審慎考慮**是否允許修改專案 CLAUDE.md
  3. 定期檢查 `~/.gstack/analytics/` 確認無意外紀錄
  4. 了解安裝會建立 30+ 個 skill symlink，佔據較多 skill 命名空間

> ⚠️ **提醒**：本報告由 AI 自動產生，結果可能存在誤判（false positive）或遺漏（false negative）。所有發現皆需經人工核實與驗證，不應作為唯一的安全評估依據。