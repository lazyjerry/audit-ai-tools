#!/usr/bin/env bash
# scan-github.sh — GitHub 倉庫掃描輔助腳本
# 供 Claude 參照執行，變數由呼叫端設定：OWNER, REPO, BRANCH（可選）

set -euo pipefail

OWNER="${OWNER:-}"
REPO="${REPO:-}"
BRANCH="${BRANCH:-}"   # 空字串表示使用預設分支

CLONE_URL="https://github.com/${OWNER}/${REPO}.git"
SCAN_TMP=$(mktemp -d)

cleanup() { rm -rf "$SCAN_TMP"; }
trap cleanup EXIT

# ── G1：淺層 Clone ─────────────────────────────────────────────────────────

CLONE_ARGS=(--depth 1)
[ -n "$BRANCH" ] && CLONE_ARGS+=(--branch "$BRANCH")

if ! git clone "${CLONE_ARGS[@]}" "$CLONE_URL" "$SCAN_TMP/repo" 2>&1; then
  echo "ERROR: 無法 clone $CLONE_URL（倉庫不存在或為私有）"
  exit 1
fi

cd "$SCAN_TMP/repo"

# ── G2：偵測倉庫類型（特徵檔案掃描）──────────────────────────────────────

echo "=== 根目錄列表 ==="
ls -la

echo "=== 特徵檔案偵測 ==="
find . -maxdepth 3 -type f \( \
  -name "SKILL.md" -o -name "AGENTS.md" -o -name "CLAUDE.md" -o \
  -name ".cursorrules" -o -name ".windsurfrules" -o -name "GEMINI.md" -o \
  -name "mcp.json" -o -name "mcp-config.json" -o -name "manifest.json" -o \
  -name "copilot-instructions.md" -o -name "*.agent.md" -o \
  -name "*.prompt.md" -o -name "*.instructions.md" \
\) 2>/dev/null | sort

# ── G3：讀取所有相關檔案（超過 50KB 略過）────────────────────────────────

echo "=== 相關檔案內容 ==="
find . -type f \( \
  -name "*.md" -o -name "*.json" -o -name "*.js" -o -name "*.ts" -o \
  -name "*.sh" -o -name "*.py" -o -name "*.yaml" -o -name "*.yml" -o \
  -name "*.toml" -o -name ".cursorrules" -o -name ".windsurfrules" \
\) ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | sort | \
while IFS= read -r FILE; do
  SIZE=$(wc -c < "$FILE" 2>/dev/null || echo 0)
  if [ "$SIZE" -gt 51200 ]; then
    echo "[SKIP: 超過 50KB] $FILE"
  else
    echo "=== $FILE ==="
    cat "$FILE"
  fi
done

# ── G4：取得倉庫元資料（需安裝 gh CLI）────────────────────────────────────

echo "=== 倉庫元資料 ==="
gh repo view "${OWNER}/${REPO}" \
  --json stargazerCount,forkCount,updatedAt,licenseInfo,description \
  2>/dev/null || echo "[INFO] gh CLI 未安裝或無法取得元資料"

# G5：清理由 trap EXIT 自動執行
