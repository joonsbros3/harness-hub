# harness-hub

Claude Code 개인 하네스 설정 저장소.

에이전트, 스킬, 커맨드, 훅, 플러그인, 글로벌 설정을 포함한다.

## 구조

```
harness-hub/
├── agents/          # 핵심 에이전트 (7개)
├── skills/          # 도메인 스킬 + 유틸리티 스킬
├── commands/        # 슬래시 커맨드 (2개)
├── hooks/           # 이벤트 훅 스크립트
├── CLAUDE.md        # 글로벌 지침
├── settings.json    # Claude Code 설정
├── GUIDE.md         # 아키텍처 설명
└── STRATEGY.md      # 활용 전략
```

## 에이전트 (9개)

| 파일 | 모델 | 역할 |
|---|---|---|
| `orchestrator.md` | opus | 메인 진입점. 요청 분류 → 스킬 기반 위임 → 검증 |
| `planner.md` | opus | 인터뷰 → 갭 분석 → 작업 계획 수립 (구현 없음) |
| `oracle.md` | opus | 아키텍처 설계, 고난이도 디버깅, 자기 검토 (읽기 전용) |
| `deep-worker.md` | opus | 자율 심층 작업 실행 |
| `librarian.md` | sonnet | 외부 문서/OSS 탐색 |
| `search.md` | haiku | 빠른 파일/사실 검색 |
| `ops-lead.md` | sonnet | 운영, 프로젝트 관리 |
| `code-architecture-reviewer.md` | sonnet | 코드 아키텍처 검토, 품질 분석 |
| `auto-error-resolver.md` | — | TypeScript 컴파일 오류 자동 수정 |

## 스킬

### 도메인 스킬 (전문가 페르소나 + 지식 포함)

| 스킬 | 커버 영역 |
|---|---|
| `fe` | React/Next.js, TypeScript, 상태관리, 테스트, 성능, 접근성 |
| `be` | Node.js/Fastify + Python/Django, PostgreSQL, API, 보안 |
| `macos` | SwiftUI, AppKit, Swift Concurrency, XCTest |
| `designer` | UI/UX, 디자인 시스템, 와이어프레임, 사용성 |
| `po` | 제품 전략, PRD, 우선순위, 로드맵 |
| `qa` | 테스트 전략, 자동화, 성능/보안 테스트 |
| `data-analyst` | SQL, A/B 테스트, 퍼널/코호트 분석 |
| `ops-lead` | 프로젝트 관리, CI/CD, 프로세스 |

### 유틸리티 스킬

| 스킬 | 역할 |
|---|---|
| `commit-convention` | Conventional Commits 기반 커밋 컨벤션 |
| `pdf` | PDF 읽기·병합·분할·OCR 처리 |
| `pptx` | PPTX 읽기·생성·편집 |
| `mcp-builder` | MCP 서버 설계 및 구축 |
| `remotion-best-practices` | Remotion(React 비디오) 베스트 프랙티스 |
| `vercel-react-best-practices` | React/Next.js 성능 최적화 64개 규칙 |
| `web-design-guidelines` | UI 접근성·UX 가이드 |
| `find-skills` | 오픈 스킬 생태계 검색 및 설치 |
| `skill-developer` | 스킬 생성·관리, skill-rules.json, 훅 시스템 |

## 플러그인 (10개)

`settings.json`의 `enabledPlugins`에 선언. Claude Code가 자동으로 설치/업데이트한다.

| 플러그인 | 용도 |
|---|---|
| `superpowers` | 스킬 자동 평가/활성화 |
| `context7` | 라이브러리 공식 문서 실시간 검색 |
| `code-review` | 멀티 에이전트 코드 리뷰 |
| `feature-dev` | 탐색→설계→구현→리뷰 워크플로우 |
| `frontend-design` | 프론트엔드 UI/UX 디자인 |
| `skill-creator` | 스킬 생성·테스트·개선 |
| `typescript-lsp` | TypeScript 타입 진단 |
| `playwright` | 브라우저 자동화 테스트 |
| `github` | GitHub 이슈·PR 관리 |
| `vercel` | Vercel 배포 연동 |

## 커맨드 (4개)

| 커맨드 | 설명 |
|---|---|
| `/init-deep` | 계층적 CLAUDE.md 자동 생성 |
| `/ulw-loop` | Oracle 검증 기반 자기개선 루프 |
| `/dev-docs` | 작업 계획 + 컨텍스트 + 태스크 3파일 생성 |
| `/dev-docs-update` | 컨텍스트 압축 전 개발 문서 업데이트 |

## 훅

| 훅 | 이벤트 | 역할 |
|---|---|---|
| `skill-activation-prompt.sh` | UserPromptSubmit | 프롬프트 키워드 기반 스킬 자동 제안 |
| `post-tool-use-tracker.sh` | PostToolUse | 편집 파일 추적 + TSC 커맨드 캐시 |
| `claude-remote-notification.sh` | Notification | 원격 알림 전송 |
| `claude-remote-session-start.sh` | SessionStart | 세션 시작 알림 |
| `claude-remote-stop.sh` | Stop | 세션 종료 알림 |

훅 스크립트 위치: `~/.claude/hooks/`

> `skill-activation-prompt` 훅은 Node.js + tsx가 필요하다. 최초 설치 시 `~/.claude/hooks/`에서 `npm install` 실행.  
> `skill-rules.json`은 `~/.claude/skills/skill-rules.json` (글로벌) 또는 프로젝트의 `.claude/skills/skill-rules.json` (오버라이드)에서 읽는다.

## 사용법

### 기본

```bash
# 대부분의 작업
claude --agent orchestrator

# 복잡한 기능 설계 / 요구사항 불명확할 때
claude --agent planner

# 아키텍처 자문, 어려운 디버깅
claude --agent oracle
```

### 도메인 작업 위임 방식

orchestrator가 자동으로 처리하지만, 직접 위임할 때는 스킬을 로드한다.

```typescript
// FE 작업
task(category="visual-engineering", load_skills=["fe"], prompt="...")

// BE 작업 (Node.js)
task(category="unspecified-high", load_skills=["be"], prompt="...Node.js/Fastify 스택...")

// BE 작업 (Python)
task(category="unspecified-high", load_skills=["be"], prompt="...Python/Django 스택...")
```

## 환경 변수

원격 훅 스크립트가 API 키를 사용한다.

```bash
export CLAUDE_REMOTE_API_KEY="your-api-key"
```

셸 프로필(`~/.zshrc` 등)에 추가하면 영구 적용된다.
