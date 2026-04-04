---
name: skill-security-scan-patterns
description: 已知 AI 工具路徑對應表（KNOWN_PATTERNS），供本機掃描使用
type: reference
---

# 已知 AI 工具路徑對應表（KNOWN_PATTERNS）

每列格式：`工具目錄 | 工具名稱 | agents_md 檔 | rules 目錄 | commands 目錄 | skills 目錄 | agents 目錄`

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
