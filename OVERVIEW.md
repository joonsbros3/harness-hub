# Harness-Hub

> Claude Code를 위한 멀티에이전트 오케스트레이션 하네스

---

## 목차

1. [무엇을 해결하는가](#1-무엇을-해결하는가)
2. [설계 철학](#2-설계-철학)
3. [구조](#3-구조)
4. [진입점 선택](#4-진입점-선택)
5. [에이전트 시스템](#5-에이전트-시스템)
6. [스킬 시스템](#6-스킬-시스템)
7. [스킬 자동 활성화](#7-스킬-자동-활성화)
8. [훅 시스템](#8-훅-시스템)
9. [슬래시 커맨드](#9-슬래시-커맨드)
10. [플러그인](#10-플러그인)
11. [핵심 패턴](#11-핵심-패턴)
12. [QA & PR 프로세스](#12-qa--pr-프로세스)
13. [운영 체크리스트](#13-운영-체크리스트)
14. [트러블슈팅](#14-트러블슈팅)
15. [설치](#15-설치)

---

## 1. 무엇을 해결하는가

| 문제 | 해결 방법 |
|------|----------|
| 복잡한 작업에서 방향을 잃음 | Planner로 인터뷰 → 단계별 계획 수립 |
| 도메인 지식 없이 generic한 코드 생성 | 스킬 시스템으로 전문가 페르소나 + 지식 주입 |
| 하나의 에이전트가 모든 걸 처리하는 비효율 | 역할별 에이전트에 위임 + 병렬 실행 |
| 세션 간 컨텍스트 유실 | Notepad + dev-docs 3파일 패턴 |
| 스킬을 언제 써야 할지 기억하기 어려움 | 프롬프트 키워드 기반 스킬 자동 제안 훅 |

---

## 2. 설계 철학

1. **하네스는 얇게, 지능은 모델에** — 구조는 최소한으로. 판단과 추론은 Claude 모델이 담당한다.
2. **역할 분리** — 계획(Planner) / 실행(Orchestrator + Deep-Worker) / 전문 지식(Skills) / 검증(Oracle)을 명확히 구분한다.
3. **스킬 우선** — 새 도메인이 필요할 때 에이전트를 추가하지 않는다. 스킬로 전문가 지식을 주입한다.
4. **직접 탐색** — 코드베이스 탐색은 전용 에이전트가 아닌 Grep/Glob/Read 직접 도구로 수행한다.

---

## 3. 구조

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
│   ├── fe/  be/  macos/  designer/  po/  qa/  data-analyst/  ops-lead/
│   ├── commit-convention/  pdf/  pptx/  mcp-builder/  find-skills/
│   ├── remotion-best-practices/  vercel-react-best-practices/  web-design-guidelines/
│   └── skill-rules.json     스킬 자동 활성화 규칙
│
├── commands/            # 슬래시 커맨드
│   ├── init-deep.md         계층적 CLAUDE.md 생성
│   ├── ulw-loop.md          Oracle 검증 자기개선 루프
│   ├── dev-docs.md          작업 문서 3파일 생성
│   └── dev-docs-update.md   컨텍스트 압축 전 문서 갱신
│
├── hooks/               # 이벤트 훅
│   ├── skill-activation-prompt.sh   스킬 자동 제안 (UserPromptSubmit)
│   ├── post-tool-use-tracker.sh     파일 편집 추적 (PostToolUse)
│   ├── claude-remote-notification.sh  원격 알림
│   ├── claude-remote-session-start.sh 세션 시작 알림
│   └── claude-remote-stop.sh          세션 종료 알림
│
├── bin/
│   └── install.sh       harness-hub → ~/.claude/ 설치 스크립트
│
├── settings.json        # Claude Code 전역 설정
├── keybindings.json     # 키 바인딩
├── CLAUDE.md            # 프로젝트 가이드라인
└── OVERVIEW.md          # 이 문서
```

---

## 4. 진입점 선택

```
요청 유형                                      → 선택
──────────────────────────────────────────────────────
간단한 코드 수정, 파일 탐색                    → claude (기본 세션)
복잡한 구현, 도메인 전문성 필요                → claude --agent orchestrator
요구사항이 흐리거나 2개 이상 모듈이 얽힐 때    → claude --agent planner
아키텍처 자문, 어려운 디버깅                   → claude --agent oracle
```

**기본값은 orchestrator다.** planner는 루프 조짐이 보이거나 요구사항이 불명확할 때 전환한다.

| 상황 | orchestrator | planner |
|------|-------------|---------|
| 요구사항이 명확할 때 | ✅ 즉시 실행 | 과도함 |
| 2개 이상 모듈이 얽히거나 방향이 흐릴 때 | 잘못된 방향으로 갈 수 있음 | ✅ 인터뷰 후 계획 |
| 버그 수정 | ✅ 직접 | 오버엔지니어링 |
| 아키텍처 결정 | ✅ oracle 자문 | ✅ oracle 자문 포함 계획 |

---

## 5. 에이전트 시스템

### 5.1 에이전트 역할 맵

```
사용자 요청
    │
    ├─ orchestrator (메인 진입점)
    │       ├─ 직접 처리 (trivial 작업)
    │       ├─ deep-worker (도메인 스킬 + 구현)
    │       ├─ planner (계획 수립 필요 시)
    │       ├─ oracle (아키텍처 자문 필요 시)
    │       ├─ librarian (외부 문서 필요 시, background)
    │       └─ search (빠른 파일 탐색)
    │
    └─ planner (계획 수립 전용)
            ├─ 직접 탐색 (Grep/Glob/Read)
            ├─ librarian (외부 참조, background)
            └─ oracle (아키텍처 검토)
```

### 5.2 에이전트 상세

**Orchestrator** (Opus) — 메인 진입점. 요청 분류 → 도메인 감지 → 위임 → 결과 검증. `claude --agent orchestrator`

**Planner** (Opus) — 구현하지 않는 전략가. 인터뷰 → 코드베이스 탐색 → 갭 분석 → `.orchestrator/plans/{이름}.md` 생성. `claude --agent planner`

**Oracle** (Opus) — 읽기 전용 고난도 추론. 아키텍처 설계, 복잡한 디버깅. 코드를 작성하거나 수정하지 않는다. Orchestrator/Planner가 내부적으로 호출.

**Deep-Worker** (Opus) — 스킬이 로드된 상태에서 자율적으로 심층 작업 수행. Orchestrator가 `task(category=..., load_skills=[...])` 형태로 위임.

**Librarian** (Sonnet) — 외부 라이브러리 공식 문서·OSS 탐색. 항상 `run_in_background=true`로 실행.

**Search** (Haiku) — 빠른 파일·사실 검색. 단순 검색에 사용.

**Ops-Lead** (Sonnet) — 운영, 프로젝트 관리, CI/CD. `claude --agent ops-lead`

**Code-Architecture-Reviewer** (Sonnet) — 구현 완료 후 코드 아키텍처 검토. 결과를 `dev/active/{태스크}/code-review.md`에 저장. 수정 사항을 자동으로 구현하지 않고 승인 요청. `claude --agent code-architecture-reviewer`

**Auto-Error-Resolver** — TypeScript 컴파일 오류 자동 수정. `post-tool-use-tracker`가 캐시한 영향받은 레포를 감지해 TSC 오류를 체계적으로 수정. `claude --agent auto-error-resolver`

---

## 6. 스킬 시스템

스킬은 에이전트에게 도메인 전문 지식과 전문가 페르소나를 주입하는 메커니즘이다.

### 6.1 스킬의 두 가지 역할

**도메인 지식 저장소** — SKILL.md의 태스크-지식 매핑 테이블이 핵심이다. 작업 유형별로 어떤 참조 파일을 읽어야 하는지 명시되어 있어, Claude가 필요한 지식만 선택적으로 로드한다.

**Domain Expert Persona** — 각 SKILL.md 끝의 `## Domain Expert Persona` 섹션이 워커 에이전트의 정체성을 정의한다. 스킬이 로드되면 Claude는 해당 도메인 전문가처럼 판단하고 동작한다.

### 6.2 도메인 스킬

| 스킬 | 커버 영역 | 스택 |
|------|----------|------|
| `fe` | 프론트엔드 | React, Next.js, TypeScript, Zustand, TanStack Query, Vitest |
| `be` | 백엔드 | Node.js/Fastify + Python/Django, PostgreSQL, Redis |
| `macos` | macOS 앱 | SwiftUI, AppKit, Swift Concurrency, XCTest |
| `designer` | UI/UX | Figma, 디자인 시스템, 접근성 |
| `po` | 프로덕트 | PRD, 로드맵, 우선순위, OKR |
| `qa` | 품질 보증 | 테스트 전략, E2E, 성능/보안 |
| `data-analyst` | 데이터 분석 | SQL, A/B 테스트, 퍼널/코호트 |
| `ops-lead` | DevOps | CI/CD, 배포, 프로젝트 관리 |

### 6.3 유틸리티 스킬

| 스킬 | 역할 |
|------|------|
| `commit-convention` | Conventional Commits 기반 커밋 컨벤션 |
| `skill-developer` | 스킬 생성·관리, skill-rules.json 설계 |
| `pdf` | PDF 읽기·병합·분할·OCR |
| `pptx` | PPTX 읽기·생성·편집 |
| `mcp-builder` | MCP 서버 설계·구축 |
| `find-skills` | 오픈 스킬 생태계 검색·설치 |
| `remotion-best-practices` | Remotion (React 비디오) |
| `vercel-react-best-practices` | React/Next.js 성능 최적화 |
| `web-design-guidelines` | UI 접근성·UX 가이드라인 |

### 6.4 BE 스킬 스택 명시

BE 스킬은 Python과 Node.js를 모두 커버하므로 프롬프트에 스택을 명시해야 한다.

```
load_skills=["be"], prompt="... Node.js/Fastify 스택. Fastify 5, Drizzle ORM, Vitest ..."
load_skills=["be"], prompt="... Python/Django 스택. Django 5+, DRF, pytest ..."
```

---

## 7. 스킬 자동 활성화

`skill-activation-prompt` 훅이 사용자 프롬프트를 보내기 전에 실행된다.

1. `skill-rules.json`에서 스킬 규칙 로드 (프로젝트 → 글로벌 폴백)
2. 프롬프트를 키워드 + 인텐트 패턴으로 분석
3. 매칭된 스킬을 Claude에게 주입

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 SKILL ACTIVATION CHECK
📚 RECOMMENDED SKILLS: → fe → qa
ACTION: Use Skill tool BEFORE responding
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**skill-rules.json enforcement 레벨**: `suggest` (제안) / `warn` (경고) / `block` (차단)

프로젝트별 오버라이드: `{project}/.claude/skills/skill-rules.json` (글로벌보다 우선)

---

## 8. 훅 시스템

| 훅 파일 | 이벤트 | 역할 |
|--------|--------|------|
| `skill-activation-prompt.sh` | UserPromptSubmit | 프롬프트 분석 → 스킬 자동 제안 |
| `post-tool-use-tracker.sh` | PostToolUse (Edit/Write) | 편집 파일 추적, TSC 커맨드 캐시 |
| `claude-remote-notification.sh` | Notification | 원격 서버로 알림 전송 |
| `claude-remote-session-start.sh` | SessionStart | 세션 시작 알림 |
| `claude-remote-stop.sh` | Stop | 세션 종료 알림 |

**post-tool-use-tracker** — 편집 로그를 `.claude/tsc-cache/{session_id}/`에 기록. `auto-error-resolver`가 이 캐시를 읽어 TypeScript 오류를 자동 수정한다.

**원격 알림 훅** — `CLAUDE_REMOTE_API_KEY` 환경변수 필요. 장시간 작업을 모바일에서 모니터링할 때 유용.

---

## 9. 슬래시 커맨드

**`/init-deep`** — 프로젝트 디렉토리를 분석해 계층적 CLAUDE.md 파일을 자동 생성한다. 루트 + 서브디렉토리별 고유 규칙.

**`/ulw-loop`** — ULW (Understand → Look → Work) 자기개선 루프. Oracle이 작업 결과를 검증하고, OKAY 판정까지 반복 개선.

**`/dev-docs`** — 현재 작업에 대한 구조화된 문서 3파일 생성.
```
dev/active/{태스크명}/
├── {태스크명}-plan.md      전략적 계획 (변경 없음)
├── {태스크명}-context.md   현재 상태·결정사항 (세션마다 업데이트)
└── {태스크명}-tasks.md     체크리스트 (진행률 추적)
```

**`/dev-docs-update`** — 컨텍스트 압축 임박 시 현재 진행 상태를 문서에 저장. 다음 세션에서 `context.md`를 읽으면 바로 재개 가능.

---

## 10. 플러그인

`settings.json`의 `enabledPlugins`에 선언. Claude Code가 자동으로 설치·업데이트한다.

| 플러그인 | 역할 |
|---------|------|
| `superpowers` | 스킬 자동 평가·활성화 |
| `context7` | 라이브러리 공식 문서 실시간 검색 |
| `code-review` | 멀티 에이전트 코드 리뷰 |
| `feature-dev` | 탐색 → 설계 → 구현 → 리뷰 워크플로우 |
| `frontend-design` | 프론트엔드 UI/UX 디자인 |
| `skill-creator` | 스킬 생성·테스트·개선 |
| `typescript-lsp` | TypeScript 타입 진단 |
| `playwright` | E2E 테스트 자동화 |
| `github` | GitHub 이슈·PR 관리 |
| `vercel` | Vercel 배포 연동 |

---

## 11. 핵심 패턴

### 11.1 위임 프롬프트

**단순 작업** — 3섹션으로 충분하다:
```
1. TASK: 무엇을 해야 하는가
5. MUST NOT DO: 하지 말아야 할 것
6. CONTEXT: 관련 파일 경로
```

**복잡한 작업** — 6섹션 전체:
```
1. TASK: 무엇을 해야 하는가 (동사 + 목적어)
2. EXPECTED OUTCOME: 완료 기준 (검증 가능한 형태)
3. REQUIRED TOOLS: 사용할 도구 목록
4. MUST DO: 참조 파일, 패턴, 스타일
5. MUST NOT DO: 사이드 이펙트, 금지 패턴
6. CONTEXT: 관련 파일 경로, 배경 설명
```

### 11.2 도메인 스킬 위임 패턴

```typescript
// FE 작업
task(category="visual-engineering", load_skills=["fe"], prompt="...")

// BE 작업 (스택 명시)
task(category="unspecified-high", load_skills=["be"], prompt="...Node.js/Fastify 스택...")

// 복합 스킬
task(category="unspecified-high", load_skills=["be", "qa"], prompt="...")

// Background 위임 (librarian)
task(subagent_type="librarian", run_in_background=true, load_skills=[],
     prompt="Fastify 5 공식 문서: 플러그인 시스템...")
```

독립적인 FE/BE 작업은 동시에 위임한다. QA는 구현 완료 후 별도로 실행한다.

### 11.3 계획 기반 실행 워크플로우

```
1. claude --agent planner
   → 인터뷰 (요구사항 명확화)
   → Grep/Glob/Read로 코드베이스 직접 탐색
   → 갭 분석
   → [선택] High Accuracy 모드 (자기검토 루프, 되돌리기 비싼 작업에만)
   → .orchestrator/plans/{이름}.md 생성

2. claude --agent orchestrator
   → 계획 파일 읽기 → Wave별 병렬 위임
   → issues.md로 서브에이전트 간 동기화

3. code-architecture-reviewer (선택)
   → 구현 결과 검토 → 승인 후 수정 진행

4. auto-error-resolver (필요 시)
   → TypeScript 오류 자동 수정
```

**계획 파일 기준**: 1개 파일에 전체 작업 (분할하면 orchestrator가 의존성을 놓친다). 태스크당 1-3개 파일, wave당 5-8개 태스크가 좋은 앵커지만 절대 규칙이 아니다.

### 11.4 Notepad 시스템

```
.orchestrator/
├── plans/{계획명}.md         작업 계획 (읽기 전용)
├── notepads/{계획명}/
│   └── issues.md             문제점·주의사항 (먼저 시작)
│   (필요 시 learnings.md, decisions.md 추가)
└── evidence/task-{N}-{시나리오}.ext
```

- 서브에이전트 위임 전: issues.md 읽기
- 서브에이전트 완료 후: 발견한 문제·주의사항 append (덮어쓰기 금지)

### 11.5 세션 연속성

실패하거나 후속 작업이 있을 때 새 세션을 시작하지 말고 기존 세션을 재개한다.

```typescript
// 기존 세션 재개 (컨텍스트 보존 + 토큰 절약)
task(session_id="ses_xyz789", prompt="Fix error: [specific error message]")
```

---

## 12. QA & PR 프로세스

```
1. FE/BE 구현 완료
2. QA 사전 검증 (qa 스킬 로드 워커)
3. 이슈 발견 → FE/BE 수정 → QA 재검증 (반복)
4. QA 통과 후 PR 생성
5. CI/CD 대기 (run_in_background)
6. 코드 리뷰 반영 후 머지 승인 요청
```

QA 워커 호출 시 MUST NOT DO에 "코드 수정 금지 (검증만 수행)"를 반드시 명시한다.

---

## 13. 운영 체크리스트

### 세션 시작 전
- [ ] 올바른 에이전트를 선택했는가? (orchestrator vs planner)
- [ ] 관련 스킬을 파악했는가? (`load_skills=["?"]`)
- [ ] 기존 계획 파일이 있는가? (`.orchestrator/plans/`)

### 위임 전
- [ ] 프롬프트 섹션 선택 (둘 중 하나):
  - 단순 작업 → TASK + MUST NOT DO + CONTEXT
  - 복잡한 작업 → 6섹션 전체
- [ ] 참조 파일 경로가 구체적인가? (`src/auth.ts:45-78`)
- [ ] planner 기반이라면 issues.md를 먼저 읽었는가?

### 위임 후
- [ ] 결과가 MUST NOT DO를 위반하지 않는가?
- [ ] lsp_diagnostics가 깨끗한가?
- [ ] 세션 ID를 저장했는가? (실패 시 재개용)

### PR 생성 전
- [ ] QA 검증을 통과했는가?
- [ ] 모든 테스트가 통과하는가?
- [ ] 커밋 컨벤션을 준수했는가? (`commit-convention` 스킬 참조)

---

## 14. 트러블슈팅

**워커가 잘못된 스택으로 구현할 때**
→ CONTEXT에 "Node.js/Fastify 스택" 또는 "Python/Django 스택"을 명시

**스킬이 로드되지 않을 때**
→ `~/.claude/skills/{domain}/SKILL.md` 경로 확인

**계획 실행 중 컨텍스트 손실**
→ `.orchestrator/notepads/{name}/issues.md` 점검. 없으면 생성 후 발견 내용 기록

**oracle 결과를 기다리지 않고 답변**
→ background_output을 final answer 전에 수집
→ `background_cancel(all=true)` 사용 금지 (oracle 취소됨)

**QA 통과 전 PR 생성 시도**
→ CLAUDE.md PR 프로세스 재확인: QA 통과 후 PR 생성

---

## 15. 설치

```bash
cd /path/to/harness-hub
bash bin/install.sh
```

harness-hub의 `agents/`, `skills/`, `hooks/`, `commands/`, `settings.json`, `keybindings.json`을 `~/.claude/`에 심볼릭 링크로 연결한다. 기존 파일이 있으면 `.bak`으로 백업 후 링크.

**훅 의존성 설치** (skill-activation-prompt.sh가 Node.js 사용):
```bash
cd ~/.claude/hooks && npm install
```

**원격 알림 설정** (선택):
```bash
export CLAUDE_REMOTE_API_KEY="your-api-key"
```

---

## 빠른 참조

```bash
claude --agent orchestrator        # 일반 작업 (기본)
claude --agent planner             # 요구사항 불명확 / 루프 조짐
claude --agent oracle              # 아키텍처 자문
claude --agent auto-error-resolver # TypeScript 오류 수정

/init-deep                         # CLAUDE.md 계층 생성
/ulw-loop                          # 자기개선 루프
/dev-docs {태스크명}                # 작업 문서 3파일 생성
```

스킬 로드는 에이전트 프롬프트 내 `load_skills=["fe"]` 형태로 지정한다.
