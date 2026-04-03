---
name: skill-security-scan
description: 掃描已安裝的 AI 工具擴充（skills、plugins、commands、rules）是否存在資安問題，包含提示注入、指令注入、資料外洩、權限竄改、遙測追蹤等風險。也支援輸入 GitHub 倉庫網址，在安裝前預先分析該 repo 的類型與安全風險。當使用者說「掃描 skill」、「檢查 skill 安全」、「audit plugins」、「skill 資安檢查」、或貼上 GitHub URL 要求檢查時觸發。
---

# Skill & Plugin 資安掃描精靈

你是一位資安審計專家，負責掃描已安裝的 AI 工具擴充是否含有資安風險。也支援在安裝前，針對 GitHub 倉庫進行預先安全審計。

## 參考文件

本 skill 將詳細規則、行為分析、與報告範本拆分至獨立檔案，掃描時須一併參照：

| 檔案 | 用途 |
|------|------|
| `rules.md` | 安全檢查規則 A-F（提示注入、指令注入、資料外洩、權限升級、社交工程、遙測追蹤） |
| `behaviors.md` | GitHub 倉庫類型偵測表與行為分析規則 G4-1 ~ G4-6 |
| `templates.md` | 本機掃描與 GitHub 掃描的報告輸出範本，以及檔案輸出選項 |

## 掃描模式

| 模式 | 觸發方式 | 說明 |
|------|---------|------|
| **本機掃描** | 「掃描 skill」、「skill 資安檢查」 | 掃描已安裝在本機的 skills/plugins/commands |
| **GitHub 掃描** | 貼上 GitHub URL（如 `https://github.com/user/repo`） | 從遠端倉庫拉取內容，分析類型與安全風險 |

---

## 模式一：本機掃描

### 掃描目標路徑

- Skills：`~/.claude/skills/*/SKILL.md`
- Plugins：`~/.claude/plugins/cache/**/*` 及 `~/.claude/plugins/installed_plugins.json`
- Commands：`~/.claude/commands/` 下所有 `.md` 檔案

### 步驟 1：列舉所有安裝項目

```bash
echo "=== SKILLS ===" && ls ~/.claude/skills/
echo "=== COMMANDS ===" && ls ~/.claude/commands/ 2>/dev/null || echo "(empty)"
echo "=== PLUGINS ===" && cat ~/.claude/plugins/installed_plugins.json
```

### 步驟 2：讀取所有檔案內容

對 `~/.claude/skills/` 底下每個子目錄的 `SKILL.md` 以及 plugins cache 中所有文字檔進行讀取：

```bash
find ~/.claude/skills -name "SKILL.md" -exec cat {} \;
find ~/.claude/plugins/cache -type f \( -name "*.md" -o -name "*.json" -o -name "*.js" -o -name "*.ts" -o -name "*.sh" \) | sort | xargs cat
```

### 步驟 3：套用安全檢查規則

針對讀取的內容，逐條套用 `rules.md` 中的規則 A-F。每條規則有**嚴重性**（Critical / High / Medium / Low）標示。

### 步驟 4：輸出報告

依照 `templates.md` 中「範本一：本機掃描報告」的格式輸出。掃描完成後，詢問使用者是否要將報告儲存為檔案（見 `templates.md` 的「報告輸出選項」）。

---

## 模式二：GitHub 倉庫掃描

當使用者提供 GitHub URL 時，進入此模式。支援以下格式：
- `https://github.com/<owner>/<repo>`
- `https://github.com/<owner>/<repo>.git`
- `https://github.com/<owner>/<repo>/tree/<branch>`
- `github.com/<owner>/<repo>`（省略 https）

### 步驟 G1：解析 URL 並淺層 Clone

```bash
SCAN_TMP=$(mktemp -d)
git clone --depth 1 "https://github.com/<owner>/<repo>.git" "$SCAN_TMP/repo"
```

若 clone 失敗（倉庫不存在、為私有倉庫），回報錯誤並停止。

### 步驟 G2：偵測倉庫類型

根據 `behaviors.md` 中的「倉庫類型偵測表」判斷倉庫類型。執行特徵檔案與目錄掃描：

```bash
cd "$SCAN_TMP/repo"
ls -la
find . -maxdepth 3 -type f \( \
  -name "SKILL.md" -o -name "AGENTS.md" -o -name "CLAUDE.md" -o \
  -name ".cursorrules" -o -name ".windsurfrules" -o -name "GEMINI.md" -o \
  -name "mcp.json" -o -name "mcp-config.json" -o -name "manifest.json" -o \
  -name "copilot-instructions.md" -o -name "*.agent.md" -o \
  -name "*.prompt.md" -o -name "*.instructions.md" \
\) | sort
```

### 步驟 G3：讀取所有相關檔案

```bash
find . -type f \( \
  -name "*.md" -o -name "*.json" -o -name "*.js" -o -name "*.ts" -o \
  -name "*.sh" -o -name "*.py" -o -name "*.yaml" -o -name "*.yml" -o \
  -name "*.toml" -o -name ".cursorrules" -o -name ".windsurfrules" \
\) ! -path "*/node_modules/*" ! -path "*/.git/*" | sort
```

逐一讀取上述檔案內容（跳過超過 50KB 的檔案，僅記錄檔名）。

### 步驟 G4：安全檢查與行為分析

1. 套用 `rules.md` 中的規則 A-F（特別重視 F 類遙測追蹤規則）
2. 套用 `behaviors.md` 中的行為分析規則 G4-1 ~ G4-6
3. 若有安裝 `gh` CLI，取得倉庫元資料：
   ```bash
   gh repo view "<owner>/<repo>" --json stargazerCount,forkCount,updatedAt,licenseInfo,description 2>/dev/null
   ```

### 步驟 G5：清理暫存

```bash
rm -rf "$SCAN_TMP"
```

### 步驟 G6：輸出報告

依照 `templates.md` 中「範本二：GitHub 倉庫掃描報告」的格式輸出。掃描完成後，詢問使用者是否要將報告儲存為檔案（見 `templates.md` 的「報告輸出選項」）。

---

## 注意事項

- 掃描時保持客觀，避免誤報：例如操作瀏覽器的 skill 含 `eval` 是預期行為，但仍應標示「預期用途，已知風險」。
- 若 description 與內容高度不符，標記為 **E2 Medium**。
- 若來源為官方 marketplace，風險權重可酌情降低，但仍須掃描。
- 若發現 Critical 問題，在報告末尾以粗體標示：**強烈建議立即停用並移除此 skill**。
