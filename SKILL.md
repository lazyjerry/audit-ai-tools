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
| **本機掃描** | 「掃描 skill」、「skill 資安檢查」 | 掃描已安裝在本機的 skills/agents/commands/rules/AGENTS.md 等 AI 擴充 |
| **GitHub 掃描** | 貼上 GitHub URL（如 `https://github.com/user/repo`） | 從遠端倉庫拉取內容，分析類型與安全風險 |

---

## 模式一：本機掃描

### 步驟 0：詢問掃描範圍

掃描開始前，先詢問使用者要掃描哪個範圍：

> 請選擇掃描範圍：
> 1. **當前工作區**（預設）：掃描目前工作目錄下的 AI 設定檔與擴充
> 2. **全域設定**：掃描家目錄下所有已知 AI 工具的全域設定路徑
> 3. **自訂路徑**：請輸入要掃描的目錄路徑

- 若使用者選擇 **1** 或直接按 Enter，以 `$CWD`（當前工作目錄）作為根目錄掃描
- 若使用者選擇 **2**，進入全域掃描流程（見下方「全域掃描路徑邏輯」）
- 若使用者選擇 **3** 或輸入路徑，以指定路徑作為根目錄掃描

---

### 已知 AI 工具路徑對應表（KNOWN_PATTERNS）

每列格式為：`工具目錄 | 工具名稱 | agents_md 檔 | rules 目錄 | commands 目錄 | skills 目錄 | agents 目錄`
（`.` 表示與工具根目錄相同，略過不另建子目錄）

| 工具目錄 | 名稱 | agents_md | rules | commands | skills | agents |
|---------|------|----------|-------|---------|--------|--------|
| `~/.claude` | Claude Code | `CLAUDE.md` | `.` | `commands` | `skills` | `agents` |
| `~/.codex` | OpenAI Codex | `AGENTS.md` | `rules` | `.` | `skills` | `agents` |
| `~/.cursor` | Cursor | `AGENTS.md` | `rules` | `commands` | `skills` | `agents` |
| `~/.factory` | Factory Droid | `AGENTS.md` | `rules` | `commands` | `skills` | `droids` |
| `~/.amp` | Amp | `AGENTS.md` | `rules` | `commands` | `skills` | `.` |
| `~/.gemini` | Gemini CLI | `GEMINI.md` | `.` | `.` | `skills` | `.` |
| `~/.kiro` | Kiro CLI | `steering/AGENTS.md` | `steering` | `.` | `skills` | `agents` |
| `~/.config/opencode` | OpenCode | `AGENTS.md` | `.` | `command` | `skill` | `agents` |
| `~/.qoder` | Qoder | `AGENTS.md` | `rules` | `commands` | `skills` | `agents` |
| `~/.qodo` | Qodo | `AGENTS.md` | `.` | `.` | `.` | `agents` |
| `~/.copilot` | GitHub Copilot | `AGENTS.md` | `.` | `.` | `skills` | `agents` |
| `~/.continue` | Continue | `AGENTS.md` | `rules` | `.` | `.` | `.` |
| `~/.codeium/windsurf` | Windsurf | `AGENTS.md` | `rules` | `.` | `skills` | `.` |
| `~/.roo` | Roo Code | `AGENTS.md` | `rules` | `commands` | `skills` | `.` |
| `~/.cline` | Cline | `AGENTS.md` | `rules` | `.` | `skills` | `.` |
| `~/.blackbox` | Blackbox AI | `.` | `.` | `.` | `skills` | `.` |
| `~/.goose` | Goose AI | `AGENTS.md` | `.` | `.` | `skills` | `.` |
| `~/.augment` | Augment | `AGENTS.md` | `rules` | `commands` | `.` | `agents` |
| `~/.clawdbot` | Clawdbot Code | `AGENTS.md` | `.` | `.` | `skills` | `subagents` |
| `~/.commandcode` | Command Code | `AGENTS.md` | `.` | `.` | `skills` | `.` |
| `~/.kilocode` | Kilo Code | `AGENTS.md` | `rules` | `commands` | `skills` | `.` |
| `~/.neovate` | Neovate | `AGENTS.md` | `.` | `commands` | `skills` | `agents` |
| `~/.openhands` | OpenHands | `AGENTS.md` | `.` | `.` | `skills` | `.` |
| `~/.trae` | TRAE | `AGENTS.md` | `rules` | `.` | `skills` | `.` |
| `~/.zencoder` | Zencoder | `AGENTS.md` | `rules` | `.` | `skills` | `.` |

---

### 全域掃描路徑邏輯

#### 步驟 L0：偵測 `~/.ai-global/` 與 symlink

```bash
# 檢查 ~/.ai-global/ 是否存在
AI_GLOBAL_EXISTS=false
[ -d "$HOME/.ai-global" ] && AI_GLOBAL_EXISTS=true

# 若存在，記錄其規範路徑
AI_GLOBAL_REAL=$(realpath "$HOME/.ai-global" 2>/dev/null)
```

對 KNOWN_PATTERNS 中每個工具目錄，在掃描前先判斷：

```bash
for TOOL_DIR in ~/.claude ~/.copilot ~/.cursor ...; do
  [ -d "$TOOL_DIR" ] || continue
  # 逐一檢查各子目錄是否為指向 ~/.ai-global/ 的 symlink
  for SUBDIR in skills agents commands rules; do
    TARGET="$TOOL_DIR/$SUBDIR"
    if [ -L "$TARGET" ]; then
      LINK_DEST=$(realpath "$TARGET" 2>/dev/null)
      if [ "$AI_GLOBAL_EXISTS" = true ] && [[ "$LINK_DEST" == "$AI_GLOBAL_REAL"* ]]; then
        echo "SKIP_SYMLINK: $TARGET -> $LINK_DEST（已由 ~/.ai-global/ 涵蓋）"
        # 標記此路徑為已跳過，掃描 ~/.ai-global/ 一次即可
      fi
    fi
  done
done
```

**原則：若 `~/.ai-global/` 存在，且工具目錄內的子目錄為指向 `~/.ai-global/` 的 symlink，則僅掃描 `~/.ai-global/` 一次，跳過所有 symlink 路徑，避免重複掃描。**

#### 步驟 L1：列舉所有安裝項目

針對每個**非 symlink**（或首次出現的 `~/.ai-global/`）目錄，列舉以下內容：

```bash
# agents_md（如 CLAUDE.md / AGENTS.md / GEMINI.md）
find "$SCAN_ROOT" -maxdepth 3 -name "AGENTS.md" -o -name "CLAUDE.md" -o -name "GEMINI.md" | grep -v "/.git/"

# skills
find "$SCAN_ROOT/skills" -name "SKILL.md" 2>/dev/null
find "$SCAN_ROOT/skill" -name "SKILL.md" 2>/dev/null   # opencode 用 skill/

# agents
find "$SCAN_ROOT/agents" -maxdepth 2 -name "*.md" 2>/dev/null
find "$SCAN_ROOT/droids" -maxdepth 2 -name "*.md" 2>/dev/null   # factory
find "$SCAN_ROOT/subagents" -maxdepth 2 -name "*.md" 2>/dev/null  # clawdbot

# commands
find "$SCAN_ROOT/commands" -name "*.md" 2>/dev/null
find "$SCAN_ROOT/command" -name "*.md" 2>/dev/null    # opencode 用 command/

# rules
find "$SCAN_ROOT/rules" -name "*.md" -o -name "*.txt" -o -name "*.cursorrules" 2>/dev/null
find "$SCAN_ROOT/steering" -name "*.md" 2>/dev/null   # kiro 用 steering/

# plugins（Claude 特有）
[ -f "$SCAN_ROOT/plugins/installed_plugins.json" ] && cat "$SCAN_ROOT/plugins/installed_plugins.json"
find "$SCAN_ROOT/plugins/cache" -type f \( -name "*.md" -o -name "*.json" -o -name "*.js" -o -name "*.ts" -o -name "*.sh" \) 2>/dev/null | sort
```

#### 步驟 L2：讀取所有檔案內容

對列舉出的每個檔案逐一讀取（跳過超過 50KB 的檔案，僅記錄檔名）：

```bash
for FILE in $SCANNED_FILES; do
  SIZE=$(wc -c < "$FILE")
  if [ "$SIZE" -gt 51200 ]; then
    echo "[SKIP: 超過 50KB] $FILE"
  else
    echo "=== $FILE ===" && cat "$FILE"
  fi
done
```

---

### 當前工作區 / 自訂路徑掃描

以選定的目錄（`$CWD` 或使用者指定路徑）作為根目錄，進行相同的掃描邏輯（步驟 L1、L2），但不套用 symlink 跳過規則（工作區目錄本身不應是 symlink）。

掃描時一律讀取：
- 根目錄下的 `AGENTS.md`、`CLAUDE.md`、`GEMINI.md`
- `skills/`、`skill/` 目錄下的所有 `SKILL.md`
- `agents/`、`droids/`、`subagents/` 目錄下的所有 `.md`
- `commands/`、`command/` 目錄下的所有 `.md`
- `rules/`、`steering/` 目錄下的所有 `.md`、`.txt`、`.cursorrules`

---

### 步驟 L3：套用安全檢查規則

針對讀取的內容，逐條套用 `rules.md` 中的規則 A-F。每條規則有**嚴重性**（Critical / High / Medium / Low）標示。

### 步驟 L4：輸出報告

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
