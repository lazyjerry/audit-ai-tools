# skill-security-scan

[简体中文](README_CN.md) · 繁體中文 · [English](README_EN.md) · [日本語](README_JP.md) · [한국어](README_KR.md)

用於掃描 AI 工具擴充的資安風險，涵蓋本機已安裝項目與遠端 GitHub 倉庫兩種情境。

此 skill 的重點不是單純列出可疑字串，而是依照既定規則評估提示注入、指令注入、資料外洩、權限蔓延、社交工程與遙測追蹤等風險，並輸出結構化報告。

## 功能概覽

- 掃描已安裝的 skills、plugins、commands、rules 是否存在已知風險
- 分析 GitHub 倉庫在安裝前的潛在安全問題
- 判斷倉庫類型，例如 Claude Skill、Copilot Skill、Copilot Instructions、MCP Server
- 檢查安裝腳本、相依套件、遙測行為與宣稱功能是否一致
- 依嚴重性輸出報告，區分 Critical、High、Medium、Low

## 適用情境

- 想檢查本機已安裝的 AI 擴充是否安全
- 想在安裝前先審核某個 GitHub 倉庫
- 想盤點某個 skill 是否含有提示注入或隱藏指令
- 想確認工具是否偷偷蒐集專案名稱、分支名稱或其他遙測資料

## 掃描模式

| 模式 | 輸入方式 | 主要用途 |
|------|----------|----------|
| 本機掃描 | 例如「掃描 skill」、「skill 資安檢查」 | 掃描本機已安裝的 skills、plugins、commands |
| GitHub 掃描 | 提供 GitHub 倉庫網址 | 在安裝前分析遠端倉庫的類型與風險 |

## 掃描範圍

### 本機掃描

預設會檢查以下位置：

- `~/.claude/skills/*/SKILL.md`
- `~/.claude/plugins/cache/**/*`
- `~/.claude/plugins/installed_plugins.json`
- `~/.claude/commands/` 下的 Markdown 檔案

### GitHub 掃描

支援以下網址格式：

- `https://github.com/<owner>/<repo>`
- `https://github.com/<owner>/<repo>.git`
- `https://github.com/<owner>/<repo>/tree/<branch>`
- `github.com/<owner>/<repo>`

掃描時會先進行淺層 clone，再依據檔案結構與內容做分析。

## 風險檢查類別

本 skill 目前將檢查項目分為六大類：

| 類別 | 說明 |
|------|------|
| A. 提示注入 | 檢查是否嘗試覆寫系統指令、隱藏後門、偽冒身份 |
| B. 指令注入 | 檢查危險 shell 指令、未加引號變數、任意代碼執行 |
| C. 資料外洩 | 檢查敏感憑證讀取、外傳資料與過度蒐集環境資訊 |
| D. 權限升級與範圍蔓延 | 檢查不必要的 sudo、修改其他工具設定、超出宣稱範圍的存取 |
| E. 社交工程 | 檢查誘導信任、隱藏真實意圖、功能描述不符 |
| F. 遙測與分析追蹤 | 檢查預設啟用紀錄、持久追蹤 ID、遠端同步與 opt-out 設計 |

## 倉庫分析能力

GitHub 掃描模式除了套用共通規則，還會額外分析：

- 安裝腳本是否要求 `sudo`、修改 shell 設定、建立敏感 symlink
- 相依套件是否包含高風險 hook，例如 `postinstall`、`preinstall`
- README 宣稱的用途是否與實際行為一致
- MCP Server 是否要求超出宣稱範圍的權限
- 是否存在本地紀錄、遠端上傳與持久識別碼等遙測行為

## 報告輸出

掃描結果會依嚴重性整理為報告，常見內容包括：

- 風險摘要
- 各項目掃描結果
- 詳細發現位置與片段
- 遙測與追蹤分析
- 安裝建議或停用建議

若掃描完成後需要保存結果，skill 也有對應的 Markdown 報告範本可供輸出。

## 檔案說明

| 檔案 | 用途 |
|------|------|
| [SKILL.md](SKILL.md) | skill 主定義與掃描流程 |
| [rules.md](rules.md) | 安全檢查規則 A-F |
| [behaviors.md](behaviors.md) | GitHub 倉庫類型偵測與行為分析規則 |
| [templates.md](templates.md) | 本機掃描與 GitHub 掃描報告範本 |

## 使用範例

### 本機掃描

```text
請幫我掃描目前已安裝的 skill 是否有資安風險
```

```text
幫我做 skill 資安檢查，重點看提示注入與資料外洩
```

### GitHub 掃描

```text
請幫我檢查這個 repo 能不能安裝：
https://github.com/example/example-skill
```

```text
audit plugins，請分析這個 GitHub 倉庫是否有遙測風險
```

## 範例報告

以下為實際掃描結果，可作為報告格式與內容深度的參考：

👉 [瀏覽所有範例報告](https://github.com/lazyjerry/skill-security-scan/tree/main/docs/examples)

## 使用原則

- 保持客觀，避免把正常用途誤判成惡意行為
- 若某些危險能力屬於預期功能，仍需標示風險與用途背景
- 若 description 與內容高度不符，應視為可疑訊號
- 若發現 Critical 等級問題，應明確建議停用或不要安裝

## 限制

- 此 skill 側重靜態內容與規則分析，不等於完整動態沙箱測試
- 遠端倉庫若為私有或無法 clone，GitHub 掃描流程會中止
- 報告可信度取決於可讀取的檔案範圍；超大檔案可能只會記錄檔名而不讀取全文