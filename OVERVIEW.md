# Harness-Hub 완전 가이드

> Claude Code를 위한 멀티에이전트 오케스트레이션 하네스

---

## 목차

1. [소개](#1-소개)
2. [설계 철학](#2-설계-철학)
3. [전체 구조](#3-전체-구조)
4. [에이전트 시스템](#4-에이전트-시스템)
5. [스킬 시스템](#5-스킬-시스템)
6. [스킬 자동 활성화](#6-스킬-자동-활성화)
7. [훅 시스템](#7-훅-시스템)
8. [슬래시 커맨드](#8-슬래시-커맨드)
9. [플러그인](#9-플러그인)
10. [핵심 패턴](#10-핵심-패턴)
11. [주요 워크플로우](#11-주요-워크플로우)
12. [설치 및 설정](#12-설치-및-설정)

---

## 1. 소개

**Harness-Hub**는 Claude Code를 위한 멀티에이전트 오케스트레이션 하네스다.

복잡한 소프트웨어 개발 작업을 **계획(Plan) → 실행(Execute) → 검증(Verify)** 사이클로 구조화하고, 도메인별 전문 지식을 스킬 시스템으로 주입하여 Claude가 시니어 엔지니어 수준으로 작업할 수 있게 한다.

### 무엇을 해결하는가

| 문제 | 해결 방법 |
|------|----------|
| 복잡한 작업에서 Claude가 방향을 잃음 | Planner 에이전트로 인터뷰 → 단계별 계획 수립 |
| 도메인 전문 지식 없이 generic한 코드 생성 | 스킬 시스템으로 전문가 페르소나 + 지식 주입 |
| 하나의 에이전트가 모든 걸 처리하는 비효율 | 역할별 전문 에이전트에 위임 + 병렬 실행 |
| 세션 간 컨텍스트 유실 | Notepad 시스템 + 개발 문서 3파일 패턴 |
| 스킬을 언제 써야 할지 기억하기 어려움 | 프롬프트 키워드 기반 스킬 자동 제안 훅 |

---

## 2. 설계 철학

### 4대 원칙

**1. 하네스는 얇게, 지능은 모델에**
구조와 규칙은 최소한으로 유지한다. 실제 판단과 추론은 Claude 모델이 담당한다. 과도한 규칙은 오히려 품질을 떨어뜨린다.

**2. 역할 분리**
계획(Planner) / 실행(Orchestrator + Deep-Worker) / 전문 지식(Skills) / 검증(Oracle)을 명확히 구분한다. 한 에이전트가 모든 역할을 수행하지 않는다.

**3. 스킬 우선**
새 도메인이 필요할 때 에이전트를 추가하지 않는다. 스킬로 전문가 지식을 주입하고, 기존 에이전트가 그 지식을 활용한다.

**4. 직접 탐색**
코드베이스 탐색은 전용 에이전트가 아닌 Grep/Glob/Read 직접 도구로 수행한다. 에이전트 위임 오버헤드 없이 더 빠르고 정확하다.

---

## 3. 전체 구조

```
harness-hub/
├── agents/              # 핵심 에이전트 9개
│   ├── orchestrator.md      메인 오케스트레이터 (Opus)
│   ├── planner.md           전략적 계획 수립 (Opus)
│   ├── oracle.md            아키텍처 자문·디버깅 (Opus, 읽기 전용)
│   ├── deep-worker.md       자율 심층 작업 실행 (Opus)
│   ├── librarian.md         외부 문서·OSS 탐색 (Sonnet)
│   ├── search.md            빠른 파일·사실 검색 (Haiku)
│   ├── ops-lead.md          운영·프로세스 관리 (Sonnet)
│   ├── code-architecture-reviewer.md   코드 리뷰 (Sonnet)
│   └── auto-error-resolver.md          TypeScript 오류 수정
│
├── skills/              # 도메인 지식 + 전문가 페르소나
│   ├── fe/                  React/Next.js/TypeScript
│   ├── be/                  Node.js/Fastify + Python/Django
│   ├── macos/               SwiftUI/AppKit/Swift
│   ├── designer/            UI/UX 디자인
│   ├── po/                  프로덕트 오너십
│   ├── qa/                  품질 보증·테스트
│   ├── data-analyst/        데이터 분석·SQL
│   ├── ops-lead/            운영·CI/CD
│   ├── skill-developer/     스킬 생성·관리 메타 스킬
│   ├── commit-convention/   Conventional Commits
│   ├── pdf/                 PDF 처리
│   ├── pptx/                PowerPoint 처리
│   ├── mcp-builder/         MCP 서버 설계·구축
│   ├── find-skills/         오픈 스킬 생태계 탐색
│   ├── remotion-best-practices/   React 비디오
│   ├── vercel-react-best-practices/  React 성능 최적화
│   ├── web-design-guidelines/     UI 접근성·UX
│   └── skill-rules.json     스킬 자동 활성화 규칙
│
├── commands/            # 슬래시 커맨드 4개
│   ├── init-deep.md         계층적 CLAUDE.md 생성
│   ├── ulw-loop.md          Oracle 검증 자기개선 루프
│   ├── dev-docs.md          작업 문서 3파일 생성
│   └── dev-docs-update.md   컨텍스트 압축 전 문서 갱신
│
├── hooks/               # 이벤트 훅
│   ├── skill-activation-prompt.sh/.ts   스킬 자동 제안
│   ├── post-tool-use-tracker.sh          파일 편집 추적
│   ├── claude-remote-notification.sh     원격 알림
│   ├── claude-remote-session-start.sh    세션 시작 알림
│   └── claude-remote-stop.sh             세션 종료 알림
│
├── settings.json        # Claude Code 전역 설정
├── CLAUDE.md            # 프로젝트 가이드라인
├── OVERVIEW.md          # 이 문서
├── GUIDE.md             # 아키텍처 가이드
└── STRATEGY.md          # 활용 전략
```

---

## 4. 에이전트 시스템

에이전트는 `claude --agent {이름}` 또는 Task 도구로 서브에이전트로 실행된다.

### 4.1 에이전트 역할 맵

```
사용자 요청
    │
    ├─ orchestrator (메인 진입점)
    │       │
    │       ├─ 직접 처리 (trivial 작업)
    │       ├─ deep-worker (도메인 스킬 + 구현)
    │       ├─ planner (계획 수립 필요 시)
    │       ├─ oracle (아키텍처 자문 필요 시)
    │       ├─ librarian (외부 문서 필요 시, background)
    │       └─ search (빠른 파일 탐색)
    │
    ├─ planner (계획 수립 전용)
    │       │
    │       ├─ 직접 탐색 (Grep/Glob/Read)
    │       ├─ librarian (외부 참조, background)
    │       └─ oracle (아키텍처 검토)
    │
    └─ oracle (읽기 전용 자문)
```

### 4.2 에이전트 상세

#### Orchestrator
- **모델**: Claude Opus
- **역할**: 메인 진입점. 요청 분류 → 도메인 감지 → 적절한 에이전트/스킬로 위임 → 결과 검증
- **핵심 능력**:
  - 요청 유형 자동 분류 (Trivial / Explicit / Exploratory / Ambiguous)
  - 도메인 트리거 감지 시 강제 위임 (FE → `load_skills=["fe"]`)
  - 병렬 코드베이스 탐색
  - Notepad 시스템으로 서브에이전트 간 지식 공유
- **실행**: `claude --agent orchestrator`

#### Planner
- **모델**: Claude Opus
- **역할**: 구현하지 않는 전략가. 인터뷰 → 코드베이스 탐색 → 갭 분석 → 실행 계획 생성
- **핵심 능력**:
  - 요구사항 인터뷰 (모호한 요청 명확화)
  - 병렬 Grep/Glob/Read로 직접 코드베이스 탐색
  - 내부 갭 분석 체크리스트 (누락된 요구사항 검출)
  - High Accuracy 모드: 계획 생성 후 자기검토 루프 (최대 3회)
  - 계획 파일 출력: `.orchestrator/plans/{이름}.md`
- **실행**: `claude --agent planner`
- **주의**: 이 에이전트는 코드를 작성하지 않는다. 계획만 생성한다.

#### Oracle
- **모델**: Claude Opus
- **역할**: 읽기 전용 고난도 추론 전문가. 아키텍처 설계, 복잡한 디버깅
- **핵심 능력**:
  - 코드베이스 구조 분석 및 설계 결함 발견
  - 실용적 최소주의 원칙: 가장 단순한 해결책 선호
  - 예상 작업 시간 태깅 (Quick/Short/Medium/Large)
- **실행**: Orchestrator/Planner가 내부적으로 호출
- **주의**: 코드를 작성하거나 수정하지 않는다.

#### Deep-Worker
- **모델**: Claude Opus
- **역할**: 스킬이 로드된 상태에서 자율적으로 심층 작업 수행
- **핵심 능력**:
  - 6-섹션 프롬프트(TASK/OUTCOME/TOOLS/MUST DO/MUST NOT DO/CONTEXT) 기반 작업 수행
  - 스킬에서 로드된 전문가 페르소나로 작동
  - Notepad에서 선행 작업 컨텍스트 읽기 → 작업 후 발견사항 기록
- **실행**: Orchestrator가 `task(category=..., load_skills=[...])` 형태로 위임

#### Librarian
- **모델**: Claude Sonnet
- **역할**: 외부 라이브러리 공식 문서 및 OSS 탐색 전문가
- **핵심 능력**:
  - 공식 문서, GitHub README, 변경 이력 수집
  - 항상 `run_in_background=true`로 실행 (다른 작업과 병렬)
- **실행**: `task(subagent_type="librarian", run_in_background=true, ...)`

#### Search
- **모델**: Claude Haiku
- **역할**: 빠른 파일/사실 검색
- **핵심 능력**: 특정 파일 위치, 함수명, 구현 패턴 빠른 탐색
- **실행**: Orchestrator가 단순 검색에 사용

#### Ops-Lead
- **모델**: Claude Sonnet
- **역할**: 운영, 프로젝트 관리, CI/CD
- **실행**: `claude --agent ops-lead` 또는 Orchestrator 위임

#### Code-Architecture-Reviewer
- **모델**: Claude Sonnet
- **역할**: 구현 완료 후 코드 아키텍처 검토
- **핵심 능력**:
  - 타입 안전성, 에러 처리, 네이밍 컨벤션 검토
  - 설계 결정 질문 ("왜 이 접근법을 선택했는가?")
  - 시스템 통합 일관성 검증
  - 결과를 `dev/active/[태스크]/[태스크]-code-review.md`에 저장
  - 수정 사항을 자동으로 구현하지 않고 승인 요청
- **실행**: `claude --agent code-architecture-reviewer`

#### Auto-Error-Resolver
- **역할**: TypeScript 컴파일 오류 자동 수정
- **핵심 능력**:
  - `post-tool-use-tracker`가 캐시한 영향받은 레포 감지
  - TSC 오류 분류 후 체계적 수정 (import 오류 → 타입 불일치 → 속성 오류 순)
  - 수정 후 TSC 재실행으로 검증
  - `@ts-ignore` 대신 근본 원인 수정 원칙
- **실행**: `claude --agent auto-error-resolver`

---

## 5. 스킬 시스템

스킬은 에이전트에게 **도메인 전문 지식**과 **전문가 페르소나**를 주입하는 메커니즘이다.

### 5.1 스킬의 두 가지 역할

#### 1. 도메인 지식 저장소
각 스킬 디렉토리에는 해당 도메인의 검증된 패턴, 컨벤션, 안티패턴이 담긴 참조 파일들이 있다.

```
~/.claude/skills/fe/
├── SKILL.md               # 태스크-지식 매핑 테이블 (진입점)
├── code-quality.md        # 코드 품질 원칙
├── component-patterns.md  # 컴포넌트 패턴
├── state-management.md    # 상태 관리
├── testing.md             # 테스트 전략
├── performance.md         # 성능 최적화
└── ...                    # 20+ 참조 파일
```

SKILL.md의 **태스크-지식 매핑 테이블**이 핵심이다. 작업 유형별로 어떤 파일을 읽어야 하는지 명시되어 있어, Claude가 필요한 지식만 선택적으로 로드한다.

```markdown
| 태스크 유형 | 판단 기준 | Read할 파일 |
|---|---|---|
| 컴포넌트 작성 | UI 구조·분리가 핵심 | code-quality.md + component-patterns.md |
| API 연동 | fetch·mutation·캐싱 | async-patterns.md + data-fetching.md |
| 테스트 작성 | 유틸·훅 단위 테스트 | testing.md + testing-vitest-setup.md |
```

#### 2. Domain Expert Persona
각 SKILL.md 끝의 `## Domain Expert Persona` 섹션이 워커 에이전트의 정체성을 정의한다. 이 스킬이 로드되면 Claude는 해당 도메인 전문가처럼 판단하고 작동한다.

```markdown
## Domain Expert Persona

이 스킬이 로드될 때, 너는 **시니어 프론트엔드 엔지니어** 역할로 작업한다.

**코드 철학**: "변경하기 쉬운 코드 = 좋은 코드"
**4대 원칙**: 가독성, 예측 가능성, 응집도, 결합도

**Work Principles**:
- 기존 패턴을 먼저 파악한 뒤 작업을 시작한다
- 단순한 해결책을 선호한다. 과도한 추상화를 피한다
- 사용자의 결정을 존중한다. 대안을 제시하되 강요하지 않는다
```

### 5.2 도메인 스킬 목록

| 스킬 | 커버 영역 | 스택 |
|------|----------|------|
| `fe` | 프론트엔드 개발 | React, Next.js, TypeScript, Zustand, TanStack Query, Vitest, Playwright |
| `be` | 백엔드 개발 | Node.js/Fastify + Python/Django, PostgreSQL, Redis, BullMQ |
| `macos` | macOS 앱 개발 | SwiftUI, AppKit, Swift Concurrency, XCTest |
| `designer` | UI/UX 디자인 | Figma, 디자인 시스템, 접근성, 사용성 |
| `po` | 프로덕트 오너십 | PRD, 로드맵, 우선순위, OKR |
| `qa` | 품질 보증 | 테스트 전략, E2E, 성능/보안 테스트 |
| `data-analyst` | 데이터 분석 | SQL, A/B 테스트, 퍼널/코호트 분석, 대시보드 |
| `ops-lead` | 운영·DevOps | CI/CD, 프로젝트 관리, 배포 |

### 5.3 유틸리티 스킬 목록

| 스킬 | 역할 |
|------|------|
| `skill-developer` | 스킬 생성·관리, skill-rules.json, 훅 시스템 설계 |
| `commit-convention` | Conventional Commits 기반 커밋 컨벤션 |
| `pdf` | PDF 읽기·병합·분할·OCR |
| `pptx` | PPTX 읽기·생성·편집 |
| `mcp-builder` | MCP 서버 설계·구축 |
| `find-skills` | 오픈 스킬 생태계 검색·설치 |
| `remotion-best-practices` | Remotion (React 비디오) 베스트 프랙티스 |
| `vercel-react-best-practices` | React/Next.js 성능 최적화 64개 규칙 |
| `web-design-guidelines` | UI 접근성·UX 가이드라인 |

### 5.4 스킬 호출 방식

**직접 호출** (사용자 또는 에이전트):
```
Skill("fe")          → FE 스킬 로드
Skill("be")          → BE 스킬 로드
Skill("commit-convention")  → 커밋 컨벤션 확인
```

**Orchestrator 위임** (자동):
```typescript
// FE 작업 감지 시 자동 위임
task(
  category="visual-engineering",
  load_skills=["fe"],
  prompt=`
1. TASK: UserProfile 컴포넌트 리팩토링
2. EXPECTED OUTCOME: 4대 원칙 기반 분리, 테스트 포함
3. REQUIRED TOOLS: Read, Write, Edit, Grep
4. MUST DO: fe 스킬의 code-quality.md 참조
5. MUST NOT DO: 전역 상태 변경 금지
6. CONTEXT: src/components/UserProfile.tsx
`)
```

---

## 6. 스킬 자동 활성화

가장 좋은 스킬은 생각하지 않아도 활성화되는 스킬이다.

### 6.1 동작 방식

`skill-activation-prompt` 훅이 **사용자 프롬프트를 보내기 전**에 실행된다:

1. `skill-rules.json`에서 모든 스킬 규칙 로드
2. 프롬프트 텍스트를 키워드 + 인텐트 패턴으로 분석
3. 매칭된 스킬을 우선순위별로 Claude에게 주입

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 SKILL ACTIVATION CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 RECOMMENDED SKILLS:
  → fe
  → qa

ACTION: Use Skill tool BEFORE responding
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 6.2 skill-rules.json 구조

```json
{
  "fe": {
    "type": "domain",
    "enforcement": "suggest",
    "priority": "high",
    "promptTriggers": {
      "keywords": ["react", "component", "typescript", "프론트엔드"],
      "intentPatterns": [
        "(create|add|build).*?(component|page|ui)",
        "(fix|debug).*?(frontend|react)"
      ]
    }
  }
}
```

**enforcement 레벨**:
- `suggest` — 제안만 (대부분의 스킬)
- `block` — 스킬 로드 전 실행 차단 (critical guardrail)
- `warn` — 경고만

**우선순위 레벨**: `critical` > `high` > `medium` > `low`

### 6.3 규칙 오버라이드

글로벌 규칙 (`~/.claude/skills/skill-rules.json`)을 프로젝트별로 오버라이드할 수 있다:

```
my-project/
└── .claude/
    └── skills/
        └── skill-rules.json  # 이 파일이 글로벌보다 우선
```

---

## 7. 훅 시스템

### 7.1 훅 목록

| 훅 파일 | 이벤트 | 역할 |
|--------|--------|------|
| `skill-activation-prompt.sh` | UserPromptSubmit | 프롬프트 분석 → 스킬 자동 제안 |
| `post-tool-use-tracker.sh` | PostToolUse (Edit/Write) | 편집 파일 추적, TSC 커맨드 캐시 |
| `claude-remote-notification.sh` | Notification | 원격 서버로 알림 전송 |
| `claude-remote-session-start.sh` | SessionStart | 세션 시작 알림 전송 |
| `claude-remote-stop.sh` | Stop | 세션 종료 알림 전송 |

### 7.2 skill-activation-prompt 훅 상세

**기술 스택**: TypeScript (tsx 런타임)

**데이터 흐름**:
```
사용자 프롬프트 입력
    → skill-activation-prompt.sh 실행
    → skill-activation-prompt.ts 실행
    → skill-rules.json 로드 (프로젝트 → 글로벌 폴백)
    → 키워드·인텐트 패턴 매칭
    → 매칭된 스킬 목록을 stdout으로 Claude에게 주입
    → Claude가 프롬프트 처리 시작
```

**에러 처리**: 훅 실패 시 `exit 0`으로 조용히 종료. Claude 실행을 막지 않는다.

### 7.3 post-tool-use-tracker 훅 상세

Edit/Write/MultiEdit 도구 실행 후 동작:

1. 편집된 파일 경로에서 레포 감지
2. 편집 로그 기록: `.claude/tsc-cache/{session_id}/edited-files.log`
3. 영향받은 레포 목록: `affected-repos.txt`
4. TSC 커맨드 저장: `commands.txt`

`auto-error-resolver` 에이전트가 이 캐시를 읽어 TypeScript 오류를 자동 수정한다.

### 7.4 원격 알림 훅

세션 상태(시작, 알림, 종료)를 원격 서버로 전송한다. 장시간 실행 작업을 모바일에서 모니터링할 때 유용하다.

**환경 변수**:
```bash
export CLAUDE_REMOTE_API_KEY="your-api-key"
```

---

## 8. 슬래시 커맨드

### `/init-deep`

프로젝트 디렉토리를 분석하여 **계층적 CLAUDE.md 파일**을 자동 생성한다.

- 루트 `CLAUDE.md`: 프로젝트 전체 컨벤션
- 서브디렉토리별 `CLAUDE.md`: 해당 모듈 고유 규칙

### `/ulw-loop`

**ULW (Understand → Look → Work) 자기개선 루프**. Oracle 에이전트가 작업 결과를 검증하고, 통과할 때까지 반복 개선한다.

1. 작업 수행
2. Oracle에게 결과 검토 요청
3. Oracle이 이슈 발견 시 수정 후 재검토
4. Oracle이 OKAY 판정 시 완료

### `/dev-docs`

현재 작업에 대한 **구조화된 문서 3파일**을 자동 생성한다.

```
dev/active/{태스크명}/
├── {태스크명}-plan.md      # 전략적 계획 전문
├── {태스크명}-context.md   # 핵심 파일, 결정사항, 의존성
└── {태스크명}-tasks.md     # 체크리스트 형식 진행 추적
```

**언제 쓰나**: 복잡한 기능 구현 시작 전, 장기 작업 중에 구조화가 필요할 때

### `/dev-docs-update`

컨텍스트 압축이 임박했을 때 현재 세션의 진행 상황을 문서에 저장한다.

- 완료된 태스크 ✅ 체크
- 이번 세션의 주요 결정사항 기록
- 다음 세션에서 바로 재개할 수 있는 핸드오프 노트 작성

---

## 9. 플러그인

`settings.json`의 `enabledPlugins`에 선언. Claude Code가 자동으로 설치·업데이트한다.

| 플러그인 | 역할 |
|---------|------|
| `superpowers` | 스킬 자동 평가·활성화 |
| `context7` | 라이브러리 공식 문서 실시간 검색 |
| `code-review` | 멀티 에이전트 코드 리뷰 |
| `feature-dev` | 탐색 → 설계 → 구현 → 리뷰 워크플로우 |
| `frontend-design` | 프론트엔드 UI/UX 디자인 |
| `skill-creator` | 스킬 생성·테스트·개선 |
| `typescript-lsp` | TypeScript 타입 진단 (IDE 수준) |
| `playwright` | 브라우저 자동화 E2E 테스트 |
| `github` | GitHub 이슈·PR 관리 |
| `vercel` | Vercel 배포 연동 |

---

## 10. 핵심 패턴

### 10.1 6-섹션 위임 프롬프트

Orchestrator가 서브에이전트에게 작업을 위임할 때 사용하는 구조화된 형식이다. 모호한 지시를 방지한다.

```
1. TASK: 무엇을 해야 하는가 (동사 + 목적어)
2. EXPECTED OUTCOME: 완료 기준 (검증 가능한 형태)
3. REQUIRED TOOLS: 사용할 도구 목록
4. MUST DO: 반드시 해야 할 것 (참조 파일, 패턴, 스타일)
5. MUST NOT DO: 절대 하지 말아야 할 것 (사이드 이펙트, 금지 패턴)
6. CONTEXT: 관련 파일 경로, 배경 설명
```

### 10.2 Notepad 시스템

계획 파일을 Orchestrator가 실행할 때, 서브에이전트 간 지식을 공유하기 위한 파일 기반 메모 시스템이다.

```
.orchestrator/
├── plans/
│   └── {계획명}.md            # 작업 계획 (읽기 전용)
├── notepads/
│   └── {계획명}/
│       ├── learnings.md       # 발견한 패턴·컨벤션
│       ├── decisions.md       # 아키텍처 결정사항
│       └── issues.md          # 문제점·주의사항
└── evidence/
    └── task-{N}-{시나리오}.ext  # QA 증거 파일
```

**규칙**:
- 서브에이전트 위임 **전**: notepad 읽기
- 서브에이전트 완료 **후**: 발견사항 append (덮어쓰기 금지)

### 10.3 계획 기반 실행 워크플로우

대규모 기능 개발의 표준 흐름:

```
1. claude --agent planner
   → 인터뷰 (요구사항 명확화)
   → 직접 코드베이스 탐색 (Grep/Glob/Read)
   → 갭 분석 (내부 체크리스트)
   → [선택] High Accuracy 모드 (자기검토 루프)
   → .orchestrator/plans/{이름}.md 생성

2. claude --agent orchestrator
   → 계획 파일 읽기
   → Wave별 태스크 분석
   → 스킬 로드 후 병렬 위임
   → notepad로 서브에이전트 간 동기화

3. code-architecture-reviewer
   → 구현 결과 검토
   → dev/active/{태스크}/code-review.md 저장
   → 승인 후 수정 진행

4. auto-error-resolver (필요 시)
   → TypeScript 오류 자동 수정
```

### 10.4 도메인 스킬 + category 위임 패턴

```typescript
// FE 작업
task(category="visual-engineering", load_skills=["fe"], prompt="...")

// BE 작업 (스택 명시 필수)
task(category="unspecified-high", load_skills=["be"], prompt="...Node.js/Fastify 스택...")

// 복합 스킬 (백엔드 구현 + 테스트)
task(category="unspecified-high", load_skills=["be", "qa"], prompt="...")

// Background 위임 (librarian)
task(subagent_type="librarian", run_in_background=true, load_skills=[],
     prompt="Fastify 5 공식 문서: 플러그인 시스템, 라이프사이클 훅...")
```

### 10.5 개발 문서 3파일 패턴

컨텍스트 리셋 후에도 작업을 이어갈 수 있게 하는 구조:

```
dev/active/{태스크}/
├── {태스크}-plan.md      전략적 계획 (변경 없음)
├── {태스크}-context.md   현재 상태·결정사항 (세션마다 업데이트)
└── {태스크}-tasks.md     체크리스트 (진행률 추적)
```

컨텍스트 압축이 임박하면 `/dev-docs-update`로 현재 상태를 저장한다. 다음 세션에서 `context.md`를 읽으면 바로 재개 가능하다.

---

## 11. 주요 워크플로우

### 일반 개발 작업 (orchestrator)

```bash
claude --agent orchestrator
# → "UserProfile 컴포넌트에 아바타 업로드 기능 추가해줘"
# orchestrator가 FE 도메인 감지 → fe 스킬 로드 → deep-worker 위임
```

### 대규모 기능 개발

```bash
# 1단계: 계획 수립
claude --agent planner
# → "소셜 로그인 기능 구현 계획 만들어줘"
# → .orchestrator/plans/social-login.md 생성

# 2단계: 계획 실행
claude --agent orchestrator
# → "social-login 계획 실행해줘"
```

### 아키텍처 자문

```bash
claude --agent oracle
# → "현재 인증 구조에서 멀티 테넌시를 어떻게 도입하면 좋을까?"
```

### TypeScript 오류 수정

```bash
claude --agent auto-error-resolver
# → 자동으로 TSC 오류 감지 및 수정
```

### 작업 문서화 (장기 프로젝트)

```
/dev-docs 결제 시스템 구현
# → dev/active/결제-시스템-구현/ 에 3파일 생성

# ... 작업 진행 ...

/dev-docs-update
# → 현재 진행 상태를 context.md, tasks.md에 저장
```

---

## 12. 설치 및 설정

### 12.1 요구사항

- Claude Code CLI
- Node.js 18+ (skill-activation-prompt 훅용)
- macOS (원격 알림 훅은 선택사항)

### 12.2 설치

```bash
# 1. 레포 클론
git clone https://github.com/{your-repo}/harness-hub ~/.claude-harness

# 2. symlink 또는 복사
cp -r ~/.claude-harness/agents ~/.claude/agents
cp -r ~/.claude-harness/skills ~/.claude/skills
cp -r ~/.claude-harness/commands ~/.claude/commands
cp -r ~/.claude-harness/hooks ~/.claude/hooks
cp ~/.claude-harness/settings.json ~/.claude/settings.json

# 3. 훅 의존성 설치
cd ~/.claude/hooks && npm install

# 4. 원격 알림 설정 (선택사항)
export CLAUDE_REMOTE_API_KEY="your-api-key"
```

### 12.3 프로젝트별 skill-rules.json 설정

```bash
mkdir -p {your-project}/.claude/skills
cp ~/.claude/skills/skill-rules.json {your-project}/.claude/skills/
# → 프로젝트 고유 키워드로 커스터마이징
```

### 12.4 새 도메인 스킬 추가

```bash
# 1. 스킬 디렉토리 생성
mkdir ~/.claude/skills/new-domain

# 2. SKILL.md 작성 (500줄 이하)
# - frontmatter (name, description)
# - 핵심 원칙
# - 태스크-지식 매핑 테이블
# - 참조 파일 목록
# - ## Domain Expert Persona 섹션

# 3. 참조 파일들 추가

# 4. skill-rules.json에 트리거 규칙 추가

# 5. Orchestrator 도메인 트리거에 추가
```

자세한 스킬 생성 방법은 `skill-developer` 스킬을 참조: `Skill("skill-developer")`

### 12.5 settings.json 주요 설정

```json
{
  "permissions": {
    "allow": ["Bash(*)", "Read(*)", "Write(*)", "Edit(*)",
              "Glob(*)", "Grep(*)", "WebFetch(*)", "WebSearch(*)",
              "Task(*)", "mcp__*", "Skill(*)"]
  },
  "hooks": {
    "UserPromptSubmit": [{ "hooks": [{ "command": "~/.claude/hooks/skill-activation-prompt.sh" }] }],
    "PostToolUse": [{ "matcher": "Edit|Write|MultiEdit", "hooks": [{ "command": "~/.claude/hooks/post-tool-use-tracker.sh" }] }]
  },
  "enabledPlugins": { ... },
  "effortLevel": "high"
}
```

---

## 부록: 빠른 참조

### 에이전트 선택 가이드

```
작업 유형                              → 선택
──────────────────────────────────────────────
일반 개발 작업 (요구사항 명확)         → orchestrator
대규모 기능 (요구사항 모호)           → planner → orchestrator
아키텍처 자문, 복잡한 디버깅          → oracle
TypeScript 오류 수정                   → auto-error-resolver
코드 리뷰                             → code-architecture-reviewer
운영, CI/CD, 프로세스                  → ops-lead
```

### 스킬 선택 가이드

```
작업 내용                      → 스킬          → category
──────────────────────────────────────────────────────────
React, Next.js, 컴포넌트       → fe            → visual-engineering
Node.js/Fastify API            → be (Node 명시) → unspecified-high
Python/Django API              → be (Python 명시) → unspecified-high
SwiftUI, macOS 앱              → macos          → unspecified-high
UI/UX 디자인                   → designer       → visual-engineering
PRD, 로드맵, 우선순위          → po             → unspecified-high
테스트 전략, 자동화            → qa             → unspecified-high
SQL, A/B 테스트, 지표          → data-analyst   → unspecified-high
```
