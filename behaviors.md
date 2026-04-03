# GitHub 掃描行為分析

本文件定義 GitHub 倉庫掃描時的類型偵測與行為分析規則。

---

## 倉庫類型偵測表

根據倉庫檔案結構判斷其屬於何種 AI 工具擴充類型。依下表的特徵檔案進行比對：

| 類型 | 特徵檔案/目錄 | 說明 |
|------|-------------|------|
| **Claude Skill** | `SKILL.md` 存在於根目錄或子目錄 | Claude Code 的 skill 擴充 |
| **Claude Command** | `.claude/commands/*.md` 或根目錄下 `commands/*.md` | Claude 自訂指令 |
| **Claude Plugin** | `package.json` 含 `claude-plugin` 關鍵字，或 `manifest.json` | Claude 插件 |
| **Claude AGENTS.md** | 根目錄或 `.claude/` 下有 `AGENTS.md` 或 `CLAUDE.md` | Claude 的全域/專案指令 |
| **Copilot Skill** | `SKILL.md` 搭配 `.github/copilot-instructions.md` | GitHub Copilot 的 skill |
| **Copilot Instructions** | `.github/copilot-instructions.md` 或 `.instructions.md` 檔案 | Copilot 客製化指令 |
| **Copilot Agent** | `*.agent.md` 檔案 | Copilot 自訂 agent 模式 |
| **Copilot Prompt** | `*.prompt.md` 或 `prompts/*.prompt.md` | Copilot 可重複使用的提示 |
| **Cursor Rules** | `.cursor/rules/` 或 `.cursorrules` 檔案 | Cursor 編輯器規則 |
| **Windsurf Rules** | `.windsurfrules` 或 `.windsurf/rules/` | Windsurf 編輯器規則 |
| **Gemini Config** | `.gemini/` 目錄或 `GEMINI.md` | Google Gemini 設定 |
| **MCP Server** | `mcp.json`、`mcp-config.json`、或 `package.json` 含 MCP 相關依賴 | Model Context Protocol 伺服器 |
| **通用 Prompt 集** | 含有大量 `.md` 提示檔但無上述工具特定標記 | 純提示詞集合 |
| **混合型** | 同時符合多個類型 | 列出所有偵測到的類型 |

---

## 行為分析規則（G4 系列）

在套用共用安全檢查規則（見 `rules.md`）之外，額外針對遠端倉庫進行以下行為分析：

### G4-1 [High] 安裝腳本行為

檢查倉庫是否含有安裝腳本（`install.sh`、`setup.sh`、`postinstall.js`、`Makefile`），若有：
- 是否要求 `sudo` 或寫入系統目錄
- 是否下載並執行額外遠端腳本（`curl | bash` 鏈式）
- 是否修改 shell 設定檔（`.bashrc`、`.zshrc`、`.profile`）
- 是否建立 symlink 到敏感路徑

### G4-2 [High] 依賴風險

檢查 `package.json`、`requirements.txt`、`go.mod` 等依賴清單：
- 是否包含已知惡意或高風險套件
- 是否有 `postinstall` 或 `preinstall` hook 執行腳本
- 依賴數量是否異常龐大（skill/prompt 類型不應有過多依賴）

### G4-3 [Medium] 宣稱 vs 實際行為差異

比對：
- README 描述的功能 vs 實際指令檔內容
- 若 README 宣稱為「文件生成工具」但包含大量 shell 命令或網路請求，標記為可疑

### G4-4 [Medium] MCP Server 特殊檢查

若偵測為 MCP Server 類型：
- 是否需要敏感權限（檔案系統完整存取、網路連線、環境變數讀取）
- 提供的 tools 是否超出宣稱範圍
- 是否轉發請求至第三方服務

### G4-5 [Low] 倉庫可信度指標

蒐集以下參考資訊（不作為判定依據，僅供輔助）：
- 倉庫星數、fork 數（若可透過 `gh` CLI 取得）
- 最後更新時間
- 是否有 LICENSE 檔案
- 貢獻者數量
- 是否有 CI/CD 設定（`.github/workflows/`）

### G4-6 [High] 遙測與追蹤行為深度分析

在 `rules.md` 的 F 類別基礎上，針對 GitHub 倉庫進行更深入的遙測行為分析：

**自動化紀錄啟動點偵測：**
- 檢查 `preamble`、`postinstall`、`setup`、`init` 腳本中是否呼叫遙測相關函式
- 追蹤 shell 腳本中的 `source` 鏈：A 腳本 source B 腳本再 source C 腳本，最終執行遙測
- 偵測 `trap` 指令是否在退出時自動觸發上傳

**本地日誌內容分析：**
- 搜尋寫入 `*.jsonl`、`*.log`、`*.csv` 的程式碼路徑
- 分析寫入的欄位是否包含：repo 名稱、branch、路徑、使用者名稱、指令參數
- 識別從 git 取得中繼資料的模式：
  ```
  git remote get-url origin
  git rev-parse --abbrev-ref HEAD
  git rev-parse --show-toplevel
  basename "$(pwd)"
  ```

**遠端上傳分析：**
- 找出所有 `curl`、`fetch`、`axios`、`http.request`、`wget` 的呼叫
- 追蹤上傳的數據流：從本地日誌讀取 → 組合 payload → 傳送至 endpoint
- 比對上傳前是否有欄位剝離（strip）邏輯，驗證宣稱的匿名化是否真實：
  - 若宣稱不上傳 repo 名稱，但 `_repo_slug` 在 payload 建構時未被移除 → 標記不實
  - 若僅對特定 tier（如免費用戶）匿名化 → 標記差異化處理

**遙測控制機制分析：**
- 找出所有與遙測開關相關的環境變數與設定檔
- 分析 opt-out 路徑是否完整（本地紀錄 + 遠端上傳是否分別可控）
- 偵測「部分關閉」陷阱：關閉上傳但本地仍持續紀錄
