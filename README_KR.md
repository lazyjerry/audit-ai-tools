# skill-security-scan

[简体中文](README_CN.md) · [繁體中文](README.md) · [English](README_EN.md) · [日本語](README_JP.md) · 한국어

AI 도구 확장의 보안 위험을 스캔하기 위한 skill입니다. 로컬에 이미 설치된 항목과 원격 GitHub 저장소 두 가지 상황을 모두 다룹니다.

이 skill의 핵심은 단순히 의심스러운 문자열을 나열하는 데 있지 않습니다. 정해진 규칙에 따라 프롬프트 인젝션, 명령어 인젝션, 데이터 유출, 권한 확장, 사회공학, 텔레메트리 추적 위험을 평가하고 구조화된 보고서를 출력합니다.

## 주요 기능

- 설치된 skills, plugins, commands, rules에 알려진 위험이 있는지 스캔합니다
- GitHub 저장소를 설치 전에 분석하여 잠재적인 보안 문제를 확인합니다
- Claude Skill, Copilot Skill, Copilot Instructions, MCP Server 같은 저장소 유형을 판별합니다
- 설치 스크립트, 의존 패키지, 텔레메트리 동작이 설명된 기능과 일치하는지 점검합니다
- 심각도에 따라 보고서를 출력하고 Critical, High, Medium, Low를 구분합니다

## 사용 상황

- 로컬에 설치된 AI 확장이 안전한지 확인하고 싶을 때
- 설치 전에 특정 GitHub 저장소를 먼저 검토하고 싶을 때
- 특정 skill에 프롬프트 인젝션이나 숨겨진 명령어가 포함되어 있는지 점검하고 싶을 때
- 도구가 프로젝트 이름, 브랜치 이름 또는 다른 텔레메트리 데이터를 몰래 수집하는지 확인하고 싶을 때

## 스캔 모드

| 모드 | 입력 방식 | 주요 용도 |
|------|----------|----------|
| 로컬 스캔 | 예: “scan skill”, “skill security check” | 로컬에 설치된 skills, plugins, commands를 스캔합니다 |
| GitHub 스캔 | GitHub 저장소 URL 제공 | 설치 전에 원격 저장소의 유형과 위험을 분석합니다 |

## 스캔 범위

### 로컬 스캔

기본적으로 다음 위치를 확인합니다.

- `~/.claude/skills/*/SKILL.md`
- `~/.claude/plugins/cache/**/*`
- `~/.claude/plugins/installed_plugins.json`
- `~/.claude/commands/` 아래의 Markdown 파일

### GitHub 스캔

다음 URL 형식을 지원합니다.

- `https://github.com/<owner>/<repo>`
- `https://github.com/<owner>/<repo>.git`
- `https://github.com/<owner>/<repo>/tree/<branch>`
- `github.com/<owner>/<repo>`

스캔할 때는 먼저 shallow clone을 수행한 뒤, 파일 구조와 내용을 기준으로 분석합니다.

## 위험 점검 범주

이 skill은 현재 점검 항목을 여섯 가지 범주로 나누어 분석합니다.

| 범주 | 설명 |
|------|------|
| A. 프롬프트 인젝션 | 시스템 지시 덮어쓰기, 숨겨진 백도어, 신원 사칭 시도가 있는지 확인합니다 |
| B. 명령어 인젝션 | 위험한 shell 명령어, 따옴표가 없는 변수, 임의 코드 실행을 확인합니다 |
| C. 데이터 유출 | 민감한 자격 증명 읽기, 외부 전송, 과도한 환경 정보 수집을 확인합니다 |
| D. 권한 상승 및 범위 확장 | 불필요한 sudo, 다른 도구 설정 수정, 설명 범위를 넘는 접근을 확인합니다 |
| E. 사회공학 | 신뢰 유도, 실제 의도 은폐, 기능 설명 불일치를 확인합니다 |
| F. 텔레메트리 및 분석 추적 | 기본 활성화된 기록, 지속 추적 ID, 원격 동기화, opt-out 설계를 확인합니다 |

## 저장소 분석 기능

GitHub 스캔 모드는 공통 규칙 외에도 다음 항목을 추가로 분석합니다.

- 설치 스크립트가 `sudo`를 요구하는지, shell 설정을 수정하는지, 민감한 symlink를 생성하는지
- 의존 패키지에 `postinstall`, `preinstall` 같은 고위험 hook이 포함되어 있는지
- README에 설명된 용도와 실제 동작이 일치하는지
- MCP Server가 설명 범위를 넘는 권한을 요구하는지
- 로컬 기록, 원격 업로드, 지속 식별자 같은 텔레메트리 동작이 존재하는지

## 보고서 출력

스캔 결과는 심각도에 따라 정리된 보고서로 출력되며, 일반적으로 다음 내용을 포함합니다.

- 위험 요약
- 각 항목의 스캔 결과
- 상세 발견 위치와 발췌
- 텔레메트리 및 추적 분석
- 설치 권고 또는 비활성화 권고

스캔 후 결과를 저장해야 하는 경우, 이 skill에는 이에 대응하는 Markdown 보고서 템플릿도 제공됩니다.

## 파일 설명

| 파일 | 용도 |
|------|------|
| [SKILL.md](SKILL.md) | skill 본체 정의와 스캔 절차 |
| [rules.md](rules.md) | 보안 점검 규칙 A-F |
| [behaviors.md](behaviors.md) | GitHub 저장소 유형 감지 및 동작 분석 규칙 |
| [templates.md](templates.md) | 로컬 스캔 및 GitHub 스캔 보고서 템플릿 |

## 사용 예시

### 로컬 스캔

```text
현재 설치된 skill에 보안 위험이 있는지 검사해 주세요
```

```text
skill 보안 점검을 해 주세요. 프롬프트 인젝션과 데이터 유출을 중점적으로 봐 주세요
```

### GitHub 스캔

```text
이 repo를 설치해도 되는지 확인해 주세요:
https://github.com/example/example-skill
```

```text
audit plugins. 이 GitHub 저장소에 텔레메트리 위험이 있는지 분석해 주세요
```

## 사용 원칙

- 정상적인 용도를 악의적인 동작으로 오판하지 않도록 객관성을 유지합니다
- 위험한 기능이 예상된 목적에 속하더라도 위험과 사용 맥락을 표시해야 합니다
- description과 실제 내용이 크게 다르면 의심 신호로 간주해야 합니다
- Critical 등급 문제를 발견하면 비활성화 또는 미설치를 명확히 권고해야 합니다

## 제한 사항

- 이 skill은 정적 콘텐츠와 규칙 분석에 중점을 두며, 완전한 동적 샌드박스 테스트를 대체하지 않습니다
- 원격 저장소가 비공개이거나 clone할 수 없으면 GitHub 스캔 절차가 중단됩니다
- 보고서 신뢰도는 읽을 수 있는 파일 범위에 따라 달라지며, 매우 큰 파일은 파일명만 기록하고 전체 내용을 읽지 않을 수 있습니다