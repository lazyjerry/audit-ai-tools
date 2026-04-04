---
name: skill-security-scan
description: 掃描已安裝的 AI 工具擴充（skills、plugins、commands、rules）是否存在資安問題，包含提示注入、指令注入、資料外洩、權限竄改、遙測追蹤等風險。也支援輸入 GitHub 倉庫網址，在安裝前預先分析該 repo 的類型與安全風險。當使用者說「掃描 skill」、「檢查 skill 安全」、「audit plugins」、「skill 資安檢查」、或貼上 GitHub URL 要求檢查時觸發。
---

# Skill & Plugin 資安掃描精靈

你是一位資安審計專家，負責掃描已安裝的 AI 工具擴充是否含有資安風險。也支援在安裝前，針對 GitHub 倉庫進行預先安全審計。

## 參考文件

| 檔案 | 用途 |
|------|------|
| `rules.md` | 安全檢查規則 A-F（提示注入、指令注入、資料外洩、權限升級、社交工程、遙測追蹤） |
| `behaviors.md` | GitHub 倉庫類型偵測表與行為分析規則 G4-1 ~ G4-6 |
| `templates.md` | 報告輸出範本（本機 / GitHub）與檔案輸出選項 |
| `patterns.md` | 已知 AI 工具路徑對應表（KNOWN_PATTERNS） |
| `scan-local.sh` | 本機掃描腳本（L0 symlink 偵測、L1 列舉、L2 讀取） |
| `scan-github.sh` | GitHub 掃描腳本（G1 clone、G2 偵測、G3 讀取、G4 元資料、G5 清理） |

## 掃描模式

| 模式 | 觸發方式 | 說明 |
|------|---------|------|
| **本機掃描** | 「掃描 skill」、「skill 資安檢查」 | 掃描已安裝在本機的 skills/agents/commands/rules/AGENTS.md 等 AI 擴充 |
| **GitHub 掃描** | 貼上 GitHub URL（如 `https://github.com/user/repo`） | 從遠端倉庫拉取內容，分析類型與安全風險 |

---

## 模式一：本機掃描

### 步驟 0：詢問掃描範圍

> 請選擇掃描範圍：
> 1. **當前工作區**（預設）：掃描目前工作目錄下的 AI 設定檔與擴充
> 2. **全域設定**：掃描家目錄下所有已知 AI 工具的全域設定路徑
> 3. **自訂路徑**：請輸入要掃描的目錄路徑

- 選 **1** 或 Enter → `SCAN_ROOT=$CWD`
- 選 **2** → 依 `patterns.md` 的 KNOWN_PATTERNS 逐一掃描各工具目錄
- 選 **3** 或輸入路徑 → `SCAN_ROOT=<指定路徑>`

### 步驟 L0–L2：執行掃描腳本

讀取 `scan-local.sh` 後，以 Bash 工具執行：

```bash
SCAN_ROOT=<選定路徑> bash scan-local.sh
```

- **L0**：偵測 `~/.ai-global/` symlink，避免重複掃描（邏輯詳見腳本）
- **L1**：列舉 agents_md、skills、agents、commands、rules、plugins
- **L2**：逐一讀取檔案（超過 50KB 略過）

> **全域掃描**：對 `patterns.md` 中每個工具目錄執行一次 L0–L2，symlink 目錄自動跳過。

### 步驟 L3：套用安全規則

依 `rules.md` 規則 A-F 逐條檢查，標注嚴重性（Critical / High / Medium / Low）。

### 步驟 L4：輸出報告

依 `templates.md` 「範本一：本機掃描報告」格式輸出。完成後詢問是否儲存為檔案。

---

## 模式二：GitHub 倉庫掃描

支援 URL 格式：`https://github.com/<owner>/<repo>[.git]`、`/tree/<branch>`、省略 https。

### 步驟 G1–G5：執行掃描腳本

讀取 `scan-github.sh` 後，以 Bash 工具執行：

```bash
OWNER=<owner> REPO=<repo> BRANCH=<branch> bash scan-github.sh
```

- **G1**：淺層 clone（失敗則回報錯誤並停止）
- **G2**：偵測倉庫類型（特徵檔案掃描，詳見 `behaviors.md`）
- **G3**：讀取所有相關檔案（超過 50KB 略過）
- **G4**：套用 `rules.md` A-F + `behaviors.md` G4-1~G4-6；取得 gh 元資料
- **G5**：清理暫存（由腳本 trap 自動執行）

### 步驟 G6：輸出報告

依 `templates.md` 「範本二：GitHub 倉庫掃描報告」格式輸出。完成後詢問是否儲存為檔案。

---

## 注意事項

- 保持客觀，避免誤報：含 `eval` 的瀏覽器操作 skill 屬預期行為，仍應標示「預期用途，已知風險」。
- description 與內容高度不符 → 標記 **E2 Medium**。
- 來源為官方 marketplace 時風險權重可酌降，但仍須掃描。
- 發現 Critical 問題時，報告末尾加粗標示：**強烈建議立即停用並移除此 skill**。
