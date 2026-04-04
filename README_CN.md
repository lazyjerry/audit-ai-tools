# skill-security-scan

简体中文 · [繁體中文](README.md) · [English](README_EN.md) · [日本語](README_JP.md) · [한국어](README_KR.md)

用于扫描 AI 工具扩展的安全风险，涵盖本机已安装项目与远端 GitHub 仓库两种场景。

此 skill 的重点不是单纯列出可疑字符串，而是依照既定规则评估提示注入、命令注入、数据泄露、权限蔓延、社会工程与遥测追踪等风险，并输出结构化报告。

## 功能概览

- 扫描已安装的 skills、plugins、commands、rules 是否存在已知风险
- 分析 GitHub 仓库在安装前的潜在安全问题
- 判断仓库类型，例如 Claude Skill、Copilot Skill、Copilot Instructions、MCP Server
- 检查安装脚本、依赖包、遥测行为与宣称功能是否一致
- 按严重性输出报告，区分 Critical、High、Medium、Low

## 适用场景

- 想检查本机已安装的 AI 扩展是否安全
- 想在安装前先审核某个 GitHub 仓库
- 想盘点某个 skill 是否包含提示注入或隐藏命令
- 想确认工具是否偷偷收集项目名称、分支名称或其他遥测数据

## 扫描模式

| 模式 | 输入方式 | 主要用途 |
|------|----------|----------|
| 本机扫描 | 例如“扫描 skill”、“skill 安全检查” | 扫描本机已安装的 skills、plugins、commands |
| GitHub 扫描 | 提供 GitHub 仓库网址 | 在安装前分析远端仓库的类型与风险 |

## 扫描范围

### 本机扫描

默认会检查以下位置：

- `~/.claude/skills/*/SKILL.md`
- `~/.claude/plugins/cache/**/*`
- `~/.claude/plugins/installed_plugins.json`
- `~/.claude/commands/` 下的 Markdown 文件

### GitHub 扫描

支持以下网址格式：

- `https://github.com/<owner>/<repo>`
- `https://github.com/<owner>/<repo>.git`
- `https://github.com/<owner>/<repo>/tree/<branch>`
- `github.com/<owner>/<repo>`

扫描时会先进行浅层 clone，再依据文件结构与内容做分析。

## 风险检查类别

本 skill 目前将检查项目分为六大类：

| 类别 | 说明 |
|------|------|
| A. 提示注入 | 检查是否尝试覆写系统指令、隐藏后门、冒充身份 |
| B. 命令注入 | 检查危险 shell 命令、未加引号变量、任意代码执行 |
| C. 数据泄露 | 检查敏感凭证读取、外传数据与过度收集环境信息 |
| D. 权限升级与范围蔓延 | 检查不必要的 sudo、修改其他工具设置、超出宣称范围的访问 |
| E. 社会工程 | 检查诱导信任、隐藏真实意图、功能描述不符 |
| F. 遥测与分析追踪 | 检查默认启用记录、持久追踪 ID、远端同步与 opt-out 设计 |

## 仓库分析能力

GitHub 扫描模式除了套用通用规则，还会额外分析：

- 安装脚本是否要求 `sudo`、修改 shell 设置、创建敏感软链
- 依赖包是否包含高风险 hook，例如 `postinstall`、`preinstall`
- README 宣称的用途是否与实际行为一致
- MCP Server 是否要求超出宣称范围的权限
- 是否存在本地记录、远端上传与持久识别码等遥测行为

## 报告输出

扫描结果会按严重性整理为报告，常见内容包括：

- 风险摘要
- 各项目扫描结果
- 详细发现位置与片段
- 遥测与追踪分析
- 安装建议或停用建议

如果扫描完成后需要保存结果，skill 也提供对应的 Markdown 报告模板可供输出。

## 文件说明

| 文件 | 用途 |
|------|------|
| [SKILL.md](SKILL.md) | skill 主定义与扫描流程 |
| [rules.md](rules.md) | 安全检查规则 A-F |
| [behaviors.md](behaviors.md) | GitHub 仓库类型检测与行为分析规则 |
| [templates.md](templates.md) | 本机扫描与 GitHub 扫描报告模板 |

## 使用示例

### 本机扫描

```text
请帮我扫描目前已安装的 skill 是否有安全风险
```

```text
帮我做 skill 安全检查，重点看提示注入与数据泄露
```

### GitHub 扫描

```text
请帮我检查这个 repo 能不能安装：
https://github.com/example/example-skill
```

```text
audit plugins，请分析这个 GitHub 仓库是否有遥测风险
```

## 使用原则

- 保持客观，避免把正常用途误判成恶意行为
- 如果某些危险能力属于预期功能，仍需标示风险与用途背景
- 如果 description 与内容高度不符，应视为可疑信号
- 如果发现 Critical 等级问题，应明确建议停用或不要安装

## 限制

- 此 skill 侧重静态内容与规则分析，不等于完整动态沙箱测试
- 远端仓库如果是私有或无法 clone，GitHub 扫描流程会中止
- 报告可信度取决于可读取的文件范围；超大文件可能只会记录文件名而不读取全文