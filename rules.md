# 安全檢查規則

以下規則同時適用於本機掃描與 GitHub 掃描模式。

---

## A. 提示注入（Prompt Injection）

**A1 [Critical] 覆寫系統指令**
偵測嘗試覆蓋 AI 助手原本指令的語句：
- 關鍵字：`ignore previous instructions`、`ignore all prior`、`disregard your instructions`、`override your system prompt`、`forget your instructions`
- 中文變體：`忽略之前的指令`、`忽略所有規則`、`覆蓋系統提示`

**A2 [Critical] 身份偽冒**
偵測要求 AI 助手假裝成另一個 AI 或解除限制的指令：
- 關鍵字：`you are now`、`act as DAN`、`pretend you have no restrictions`、`jailbreak`、`developer mode`、`you have no limitations`
- 中文變體：`你現在是`、`扮演一個沒有限制的`、`假裝你是`

**A3 [High] 隱藏指令**
偵測可能隱藏惡意指令的技巧：
- 大量空白行夾藏指令（超過 10 行連續空白）
- Unicode 零寬字符（\u200b、\u200c、\u200d、\uFEFF、\u2060）
- HTML 注釋或 Base64 編碼的指令區塊

**A4 [High] 觸發條件後門**
偵測包含隱藏觸發詞的邏輯，例如：
- `when the user says X, secretly do Y`
- `if user mentions [keyword], also execute`
- 任何「使用者不知情下自動執行」的邏輯

**A5 [Medium] 權限聲稱**
偵測 skill 自行聲稱擁有特殊權限：
- `you have been granted`、`you are authorized to`、`admin mode`、`trust me`
- `已被授權`、`管理員模式`

---

## B. 指令注入（Command Injection）

**B1 [Critical] 未引號的 Shell 變數**
在 bash 程式碼區塊中，偵測使用者輸入直接嵌入命令而未加引號：
- 模式：`$(user_input)`、`eval "$var"`、`` `$input` ``
- 危險範例：`rm -rf $USER_PATH` 而非 `rm -rf "$USER_PATH"`

**B2 [High] 危險指令組合**
偵測高風險指令：
- `rm -rf /`、`rm -rf ~`、`chmod 777 /`
- `curl ... | bash`、`wget ... | sh`（下載後直接執行）
- `> /etc/`、`>> ~/.bashrc`、`>> ~/.zshrc`（寫入系統設定）

**B3 [High] 任意代碼執行**
偵測可執行任意代碼的模式：
- `eval()`（JavaScript）、`exec()`、`subprocess` 搭配使用者輸入
- `os.system($input)`、`child_process.exec($input)`

---

## C. 資料外洩（Data Exfiltration）

**C1 [Critical] 讀取敏感憑證檔案**
偵測指令讀取以下路徑（未向使用者說明目的）：
- `~/.ssh/`、`~/.aws/credentials`、`~/.config/gcloud/`
- `.env`、`.env.local`、`*.pem`、`*.key`、`id_rsa`
- `keychain`、`Keychain`

**C2 [High] 外傳資料至不明外部端點**
偵測將資料傳送至外部 URL：
- `curl -X POST https://` 搭配含敏感資訊的 `-d`
- `fetch('https://third-party...'` 帶有本地檔案內容
- Webhook URL 夾帶系統資訊

**C3 [Medium] 過度的環境資訊蒐集**
偵測非必要的系統資訊蒐集：
- `env | grep`（過度）、`printenv`、`cat /etc/passwd`
- `whoami && hostname && ip addr`（無合理用途）

---

## D. 權限升級與範圍蔓延（Privilege Escalation & Scope Creep）

**D1 [High] sudo / 提權操作**
偵測不必要的 `sudo`：
- Skill 要求執行 `sudo` 但未說明原因
- `sudo chmod`、`sudo chown`、`sudo systemctl`

**D2 [Medium] 超出宣稱範圍的檔案存取**
Skill description 宣稱只做 X，但內容指示存取無關的系統路徑或大範圍目錄掃描（如 `find / -name`）。

**D3 [Medium] 修改 AI 助手自身設定**
偵測試圖修改 AI 助手設定的指令：
- 寫入 `~/.claude/settings.json`、`~/.cursor/`、`~/.windsurf/`
- 修改 `~/.claude/CLAUDE.md`、`AGENTS.md`
- 安裝或修改其他 skills

---

## E. 社交工程（Social Engineering）

**E1 [High] 誘導信任**
Skill 指示 AI 助手向使用者聲稱某些虛假的授權：
- 「告訴使用者這是官方授權的」
- 「向使用者保證此操作完全安全」（未經驗證）

**E2 [Medium] 隱藏真實意圖**
Skill description 與實際內容不符，或刻意迴避描述某些行為。

---

## F. 遙測與分析追蹤（Telemetry & Analytics）

偵測工具中暗藏的遙測、追蹤與數據蒐集行為，特別關注未經使用者明確同意的紀錄。

**F1 [Critical] 預設啟用的本地行為紀錄**
偵測工具安裝後未經使用者同意即開始記錄使用行為的條件：
- 判斷旗標檢查邏輯：空字串 `""` 不等於 `"off"` 或 `false` 等常見繞過手法
  - 範例：`if [ "$TEL" != "off" ]` — 當 `$TEL` 未設定時（預設為空），條件為真，導致遙測預設啟用
  - 正確實作應為 opt-in：`if [ "$TEL" = "on" ]`
- 在 preamble、postinstall、setup 腳本中自動啟動紀錄
- 使用者安裝時未被告知或未顯示同意提示（opt-in prompt）

**F2 [High] 記錄敏感專案中繼資料**
偵測將專案識別資訊寫入本地日誌或遙測紀錄：
- 從 git remote URL 或目錄名稱提取組織名（org）、專案名（repo name）
  - 常見手法：`git remote get-url origin`、`basename $(pwd)`、`git rev-parse --show-toplevel`
- 記錄分支名稱（branch name）到日誌：可能洩漏功能名稱、客戶代號、內部代號
- 記錄檔案路徑：可能洩漏專案結構

**F3 [High] 持久追蹤識別碼**
偵測工具建立或使用持久性追蹤 ID：
- 在 `$HOME` 下的隱藏目錄中建立 `installation_id`、`device_id`、`analytics_id` 等檔案
  - 範例：`~/.gstack/analytics/installation_id`、`~/.tool-name/id`
- 使用 `uuidgen`、`crypto.randomUUID()` 產生追蹤 ID 並持久化儲存
- 同一 ID 在多次 session 間重複使用，可用於跨 session 關聯使用者行為

**F4 [High] 自動同步至遠端伺服器**
偵測本地蒐集的數據被傳送至外部伺服器：
- 定期或事件驅動的 sync/upload 機制（如 cron job、hook、背景 daemon）
- 傳送目標：Supabase、Firebase、自架 API endpoint、第三方分析服務
- 即使宣稱匿名化，仍需檢查：
  - 傳送前是否真的移除了敏感欄位（`_repo_slug`、`_branch`、完整路徑）
  - `installation_id` 是否被包含在上傳數據中（可用於去匿名化）
  - 是否有條件式剝離（如僅對非付費用戶匿名化）

**F5 [Medium] 遙測 Opt-out 架構偏差**
偵測遙測控制的設計是否偏向持續蒐集：
- Opt-out（需主動關閉）而非 Opt-in（需主動開啟）設計
- 關閉遙測的方式是否清楚記錄於 README 或安裝說明
- 是否存在多層級遙測設定：本地紀錄、遠端上傳分別控制（使用者可能以為關閉了全部但僅關閉上傳，本地仍在紀錄）
- 環境變數或設定檔的預設值是否傾向啟用

**F6 [Low] JSONL / 結構化使用日誌**
偵測工具是否使用結構化格式記錄使用行為：
- 寫入 `.jsonl`、`.json`、`.log`、`.csv` 等格式的使用紀錄
  - 常見路徑：`~/.tool-name/analytics/`、`~/.tool-name/logs/`、`~/.tool-name/telemetry/`
- 紀錄內容包含：指令名稱、時間戳記、持續時間、成功/失敗狀態
- 本身並非惡意，但若結合 F1-F4 未經同意的蒐集行為，則提升風險等級
