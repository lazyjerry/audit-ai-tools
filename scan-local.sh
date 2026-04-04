#!/usr/bin/env bash
# scan-local.sh — 本機掃描輔助腳本
# 供 Claude 參照執行，變數由呼叫端設定：SCAN_ROOT

set -euo pipefail

SCAN_ROOT="${SCAN_ROOT:-$PWD}"

# ── L0：偵測 ~/.ai-global/ 與 symlink ──────────────────────────────────────

AI_GLOBAL_EXISTS=false
[ -d "$HOME/.ai-global" ] && AI_GLOBAL_EXISTS=true
AI_GLOBAL_REAL=$(realpath "$HOME/.ai-global" 2>/dev/null || true)

# 對每個工具子目錄，判斷是否為指向 ~/.ai-global/ 的 symlink
# 若是，僅掃描 ~/.ai-global/ 一次，跳過重複路徑
check_symlink() {
  local TARGET="$1"
  if [ -L "$TARGET" ]; then
    local LINK_DEST
    LINK_DEST=$(realpath "$TARGET" 2>/dev/null || true)
    if [ "$AI_GLOBAL_EXISTS" = true ] && [[ "$LINK_DEST" == "$AI_GLOBAL_REAL"* ]]; then
      echo "SKIP_SYMLINK: $TARGET -> $LINK_DEST（已由 ~/.ai-global/ 涵蓋）"
      return 0  # 跳過
    fi
  fi
  return 1  # 不跳過
}

# ── L1：列舉所有安裝項目 ──────────────────────────────────────────────────

list_items() {
  local ROOT="$1"

  # agents_md（AGENTS.md / CLAUDE.md / GEMINI.md）
  find "$ROOT" -maxdepth 3 \( -name "AGENTS.md" -o -name "CLAUDE.md" -o -name "GEMINI.md" \) \
    2>/dev/null | grep -v "/.git/"

  # skills
  find "$ROOT/skills"  -name "SKILL.md" 2>/dev/null
  find "$ROOT/skill"   -name "SKILL.md" 2>/dev/null   # opencode

  # agents
  find "$ROOT/agents"    -maxdepth 2 -name "*.md" 2>/dev/null
  find "$ROOT/droids"    -maxdepth 2 -name "*.md" 2>/dev/null   # factory
  find "$ROOT/subagents" -maxdepth 2 -name "*.md" 2>/dev/null   # clawdbot

  # commands
  find "$ROOT/commands" -name "*.md" 2>/dev/null
  find "$ROOT/command"  -name "*.md" 2>/dev/null   # opencode

  # rules
  find "$ROOT/rules"    \( -name "*.md" -o -name "*.txt" -o -name "*.cursorrules" \) 2>/dev/null
  find "$ROOT/steering" -name "*.md" 2>/dev/null   # kiro

  # plugins（Claude 特有）
  [ -f "$ROOT/plugins/installed_plugins.json" ] && cat "$ROOT/plugins/installed_plugins.json"
  find "$ROOT/plugins/cache" -type f \
    \( -name "*.md" -o -name "*.json" -o -name "*.js" -o -name "*.ts" -o -name "*.sh" \) \
    2>/dev/null | sort
}

# ── L2：讀取所有檔案內容（超過 50KB 略過）───────────────────────────────────

read_files() {
  while IFS= read -r FILE; do
    local SIZE
    SIZE=$(wc -c < "$FILE" 2>/dev/null || echo 0)
    if [ "$SIZE" -gt 51200 ]; then
      echo "[SKIP: 超過 50KB] $FILE"
    else
      echo "=== $FILE ==="
      cat "$FILE"
    fi
  done
}

# ── 主流程 ───────────────────────────────────────────────────────────────────

echo "=== 掃描根目錄：$SCAN_ROOT ==="
list_items "$SCAN_ROOT" | sort -u | read_files
