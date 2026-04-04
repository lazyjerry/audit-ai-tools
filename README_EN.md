# skill-security-scan

[简体中文](README_CN.md) · [繁體中文](README.md) · English · [日本語](README_JP.md) · [한국어](README_KR.md)

A skill for scanning security risks in AI tool extensions, covering both locally installed items and remote GitHub repositories.

This skill focuses not on simply listing suspicious strings, but on evaluating risks such as prompt injection, command injection, data exfiltration, privilege escalation, social engineering, and telemetry tracking according to established rules, then outputting structured reports.

## Feature Overview

- Scans installed skills, plugins, commands, and rules for known risks
- Analyzes GitHub repositories for potential security issues before installation
- Identifies repository types such as Claude Skill, Copilot Skill, Copilot Instructions, and MCP Server
- Checks whether installation scripts, dependencies, and telemetry behavior are consistent with claimed functionality
- Outputs reports categorized by severity: Critical, High, Medium, Low

## Use Cases

- Want to verify whether locally installed AI extensions are safe
- Want to audit a GitHub repository before installing it
- Want to check whether a skill contains prompt injection or hidden commands
- Want to confirm whether a tool is secretly collecting project names, branch names, or other telemetry data

## Scan Modes

| Mode | Input | Primary Use |
|------|-------|-------------|
| Local Scan | e.g., "scan skill", "skill security check" | Scans locally installed skills, plugins, commands |
| GitHub Scan | Provide a GitHub repository URL | Analyzes the type and risks of a remote repository before installation |

## Scan Scope

### Local Scan

By default, the following locations are checked:

- `~/.claude/skills/*/SKILL.md`
- `~/.claude/plugins/cache/**/*`
- `~/.claude/plugins/installed_plugins.json`
- Markdown files under `~/.claude/commands/`

### GitHub Scan

Supports the following URL formats:

- `https://github.com/<owner>/<repo>`
- `https://github.com/<owner>/<repo>.git`
- `https://github.com/<owner>/<repo>/tree/<branch>`
- `github.com/<owner>/<repo>`

The scan performs a shallow clone first, then analyzes the file structure and content.

## Risk Check Categories

This skill currently divides checks into six categories:

| Category | Description |
|----------|-------------|
| A. Prompt Injection | Checks for attempts to override system instructions, hidden backdoors, or identity impersonation |
| B. Command Injection | Checks for dangerous shell commands, unquoted variables, and arbitrary code execution |
| C. Data Exfiltration | Checks for sensitive credential reads, data transmission, and excessive environment information collection |
| D. Privilege Escalation & Scope Creep | Checks for unnecessary sudo, modification of other tools' settings, and access beyond claimed scope |
| E. Social Engineering | Checks for trust induction, concealment of true intent, and discrepancies between described and actual functionality |
| F. Telemetry & Analytics Tracking | Checks for default-enabled logging, persistent tracking IDs, remote sync, and opt-out design |

## Repository Analysis Capabilities

In addition to applying common rules, GitHub scan mode also analyzes:

- Whether installation scripts require `sudo`, modify shell settings, or create sensitive symlinks
- Whether dependencies include high-risk hooks such as `postinstall` or `preinstall`
- Whether the purpose described in the README is consistent with actual behavior
- Whether an MCP Server requests permissions beyond its claimed scope
- Whether telemetry behaviors such as local logging, remote uploads, or persistent identifiers exist

## Report Output

Scan results are organized into reports by severity. Common content includes:

- Risk summary
- Scan results for each item
- Detailed finding locations and excerpts
- Telemetry and tracking analysis
- Installation or deactivation recommendations

If results need to be saved after scanning, the skill also provides a corresponding Markdown report template for output.

## File Reference

| File | Purpose |
|------|---------|
| [SKILL.md](SKILL.md) | Main skill definition and scan workflow |
| [rules.md](rules.md) | Security check rules A–F |
| [behaviors.md](behaviors.md) | GitHub repository type detection and behavior analysis rules |
| [templates.md](templates.md) | Report templates for local and GitHub scans |

## Usage Examples

### Local Scan

```text
Please check whether the currently installed skills have security risks
```

```text
Run a skill security check, focusing on prompt injection and data exfiltration
```

### GitHub Scan

```text
Please check whether this repo is safe to install:
https://github.com/example/example-skill
```

```text
audit plugins, please analyze whether this GitHub repository has telemetry risks
```

## Example Reports

The following are actual scan results that can serve as references for report format and depth:

👉 [Browse all example reports](https://github.com/lazyjerry/skill-security-scan/tree/main/docs/examples)

## Usage Principles

- Maintain objectivity and avoid misidentifying legitimate use as malicious behavior
- Even if a dangerous capability is part of the intended function, the risk and usage context must still be documented
- If the description is highly inconsistent with the content, treat it as a suspicious signal
- If a Critical-level issue is found, clearly recommend deactivation or non-installation

## Limitations

- This skill focuses on static content and rule-based analysis and is not a substitute for full dynamic sandbox testing
- If a remote repository is private or cannot be cloned, the GitHub scan process will be aborted
- Report reliability depends on the range of files that can be read; very large files may only have their filenames recorded without full content being read
