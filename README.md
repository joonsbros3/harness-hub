# harness-hub

Claude Code 개인 하네스 설정 저장소.

에이전트, 스킬, 커맨드, 훅, 플러그인, 글로벌 설정을 포함한다.

## 구조

```
harness-hub/
├── agents/          # 핵심 에이전트 (9개)
├── skills/          # 도메인 스킬 + 유틸리티 스킬
├── commands/        # 슬래시 커맨드 (4개)
├── hooks/           # 이벤트 훅 스크립트 (sh + ts)
├── bin/
│   ├── install.sh   # ~/.claude/ 설치 스크립트
│   └── check-skills.sh  # 스킬 health check
├── CLAUDE.md        # 글로벌 지침
├── settings.json    # Claude Code 설정
├── keybindings.json # 키 바인딩
├── OVERVIEW.md      # 전체 구조·사용법 가이드
└── BACKGROUND.md    # 철학·구축 히스토리·개인화 방법
```

## 설치

```bash
bash bin/install.sh
```

`agents/`, `skills/`, `hooks/`, `commands/`, `settings.json`, `keybindings.json`, `CLAUDE.md`를 `~/.claude/`에 심볼릭 링크로 연결한다. 기존 파일은 `.bak`으로 백업.

**훅 의존성 설치** (`skill-activation-prompt` 훅이 Node.js + tsx 사용):

```bash
cd ~/.claude/hooks && npm install
```

### 필수 의존성

| 의존성 | 용도 | 설치 |
|--------|------|------|
| Node.js | skill-activation-prompt 훅 | `brew install node` |
| jq | post-tool-use-tracker 훅 | `brew install jq` |

## Knowledge 파일 정책

도메인 스킬(`fe`, `be`, `qa` 등)의 SKILL.md는 git에 추적되지만, SKILL.md가 참조하는 **knowledge 파일은 git에 포함되지 않는다** (`.gitignore`로 제외).

### 왜 knowledge 파일이 비어 있는가

이 레포를 클론하면 `skills/fe/SKILL.md`는 있지만 `skills/fe/code-quality.md` 같은 knowledge 파일은 없다. 이는 의도된 설계다:

- SKILL.md는 **태스크-지식 매핑 테이블** (어떤 작업에 어떤 파일을 읽어야 하는지)을 정의한다
- Knowledge 파일은 **개인의 기술 스택·프로젝트 컨벤션에 맞게 커스터마이징**하는 파일이다
- 동일한 `fe` 스킬이라도 Zustand를 쓰는 사람과 Redux를 쓰는 사람의 knowledge는 다르다

### 새 환경에서 bootstrap하는 법

```bash
# 1. 설치
bash bin/install.sh

# 2. 누락된 knowledge 파일 확인
bash bin/check-skills.sh

# 3. 빈 템플릿 자동 생성
bash bin/check-skills.sh --bootstrap

# 4. 각 템플릿을 열고 도메인 knowledge를 채운다
#    또는 Skill("skill-developer")를 로드하여 Claude가 생성하도록 한다
```

**유틸리티 스킬**(commit-convention, pdf, pptx 등)은 SKILL.md 자체에 모든 knowledge가 포함되어 있어 별도 파일이 불필요하다.

## 에이전트·스킬 관리 원칙

### 공통 규칙 중복 관리

`orchestrator.md`와 `deep-worker.md`에 동일한 규칙이 반복되는 지점이 있다 (예: `background_cancel` 정책, 검증 절차, 코드 품질 규칙). 이 중복은 의도적이다 — 각 에이전트가 독립적으로 실행되므로 자체 프롬프트에 규칙이 포함되어야 한다.

**관리 원칙:**
- 중복된 규칙을 수정할 때, **양쪽을 반드시 동시에 수정**한다
- 충돌이 발생하면 orchestrator를 정본(source of truth)으로 한다
- 향후 중복이 3개 이상 에이전트에 퍼지면, `skills/shared-rules/SKILL.md`로 추출하여 `load_skills`로 주입하는 것을 검토한다

## 에이전트 (9개)

| 파일 | 모델 | 역할 |
|---|---|---|
| `orchestrator.md` | Opus | 메인 진입점. 요청 분류 → 스킬 기반 위임 → 검증 |
| `planner.md` | Opus | 인터뷰 → 갭 분석 → 작업 계획 수립 (구현 없음) |
| `oracle.md` | Opus | 아키텍처 설계, 고난이도 디버깅 (읽기 전용) |
| `deep-worker.md` | Opus | 자율 심층 작업 실행 |
| `librarian.md` | Sonnet | 외부 문서·OSS 탐색 |
| `search.md` | Haiku | 빠른 파일·사실 검색 |
| `ops-lead.md` | Sonnet | 운영, 프로젝트 관리 |
| `code-architecture-reviewer.md` | Sonnet | 코드 아키텍처 검토 |
| `auto-error-resolver.md` | Sonnet | TypeScript 컴파일 오류 자동 수정 |

## 스킬

### 도메인 스킬

| 스킬 | 커버 영역 |
|---|---|
| `fe` | React/Next.js, TypeScript, 상태관리, 테스트, 성능 |
| `be` | Node.js/Fastify + Python/Django, PostgreSQL, API |
| `macos` | SwiftUI, AppKit, Swift Concurrency, XCTest |
| `designer` | UI/UX, 디자인 시스템, 접근성 |
| `po` | 제품 전략, PRD, 우선순위, 로드맵 |
| `qa` | 테스트 전략, 자동화, 성능/보안 테스트 |
| `data-analyst` | SQL, A/B 테스트, 퍼널/코호트 분석 |
| `ops-lead` | 프로젝트 관리, CI/CD, 프로세스 |

### 유틸리티 스킬

| 스킬 | 역할 |
|---|---|
| `commit-convention` | Conventional Commits 기반 커밋 컨벤션 |
| `pdf` | PDF 읽기·병합·분할·OCR |
| `pptx` | PPTX 읽기·생성·편집 |
| `mcp-builder` | MCP 서버 설계 및 구축 |
| `remotion-best-practices` | Remotion(React 비디오) 베스트 프랙티스 |
| `vercel-react-best-practices` | React/Next.js 성능 최적화 64개 규칙 |
| `web-design-guidelines` | UI 접근성·UX 가이드 |
| `find-skills` | 오픈 스킬 생태계 검색·설치 |
| `skill-developer` | 스킬 생성·관리, skill-rules.json, 훅 시스템 |

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
| `skill-activation-prompt.sh` | UserPromptSubmit | 프롬프트 분석 → 관련 스킬 추천 메시지 출력 |
| `post-tool-use-tracker.sh` | PostToolUse | 편집 파일 추적 + TSC 커맨드 캐시 |

`skill-activation-prompt.sh`는 `skill-activation-prompt.ts`를 npx tsx로 실행하는 래퍼다.

## 플러그인 (10개)

`settings.json`의 `enabledPlugins`에 선언. Claude Code가 자동으로 설치·업데이트한다.

| 플러그인 | 용도 |
|---|---|
| `superpowers` | 스킬 자동 평가·활성화 |
| `context7` | 라이브러리 공식 문서 실시간 검색 |
| `code-review` | 멀티 에이전트 코드 리뷰 |
| `feature-dev` | 탐색→설계→구현→리뷰 워크플로우 |
| `frontend-design` | 프론트엔드 UI/UX 디자인 |
| `skill-creator` | 스킬 생성·테스트·개선 |
| `typescript-lsp` | TypeScript 타입 진단 |
| `playwright` | 브라우저 자동화 테스트 |
| `github` | GitHub 이슈·PR 관리 |
| `vercel` | Vercel 배포 연동 |

## 사용법

```bash
claude --agent orchestrator        # 일반 작업 (기본)
claude --agent planner             # 요구사항 불명확 / 루프 조짐
claude --agent oracle              # 아키텍처 자문
claude --agent auto-error-resolver # TypeScript 오류 수정
```

스킬 로드는 에이전트 프롬프트 내 `load_skills=["fe"]` 형태로 지정한다.

자세한 내용은 [OVERVIEW.md](OVERVIEW.md) 및 [BACKGROUND.md](BACKGROUND.md) 참조.
