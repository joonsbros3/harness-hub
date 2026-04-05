# Harness-Hub 아키텍처 가이드

> 재설계 완료 기준: 2026-04-04 (Wave 1~5 적용 후)

---

## 개요

Harness-Hub는 Claude Code를 위한 **멀티에이전트 오케스트레이션 하네스**다.
복잡한 소프트웨어 작업을 계획, 위임, 검증하는 구조화된 에이전트 시스템이다.

### 핵심 설계 원칙

1. **하네스는 얇게, 지능은 모델에** — 구조는 단순하게, 추론은 모델이 담당
2. **역할 분리** — 계획(Planner) / 실행(Orchestrator) / 전문 지식(Skills) / 검증(Oracle) 명확히 구분
3. **스킬 우선** — 도메인 에이전트 대신 Skills로 전문가 지식 주입
4. **직접 탐색** — 코드베이스 탐색은 에이전트 위임이 아닌 직접 도구(Grep/Glob/Read)로

---

## 디렉토리 구조

```
harness-hub/
├── agents/           # 핵심 에이전트 7개
│   ├── orchestrator.md   # 메인 오케스트레이터
│   ├── planner.md        # 전략적 계획 수립
│   ├── oracle.md         # 고난도 추론 / 아키텍처 자문
│   ├── deep-worker.md    # 자율적 심층 작업 실행
│   ├── librarian.md      # 외부 문서/OSS 탐색
│   ├── search.md         # 빠른 파일/사실 검색
│   └── ops-lead.md       # 운영/프로세스 관리
│
├── skills/           # 도메인 지식 + 전문가 페르소나
│   ├── fe/               # 프론트엔드 (React/Next.js/TypeScript)
│   ├── be/               # 백엔드 (Node.js/Fastify + Python/Django)
│   ├── macos/            # macOS 앱 (SwiftUI/AppKit/Swift)
│   ├── designer/         # UI/UX 디자인
│   ├── po/               # 프로덕트 오너십
│   ├── qa/               # 품질 보증 / 테스트
│   ├── data-analyst/     # 데이터 분석 / SQL
│   ├── ops-lead/         # 운영 / 프로세스
│   ├── commit-convention/ # 커밋 메시지 컨벤션
│   ├── fe, be, macos... 각 도메인 참조 파일들
│   └── (유틸리티 스킬: pdf, pptx, mcp-builder, remotion-best-practices 등)
│
├── commands/         # 슬래시 커맨드
│   ├── init-deep.md      # CLAUDE.md 계층 생성
│   └── ulw-loop.md       # Oracle 검증 자기개선 루프
│
├── hooks/            # 이벤트 훅 스크립트
├── bin/              # claude-team CLI 래퍼
├── settings.json     # Claude Code 전역 설정
├── CLAUDE.md         # 프로젝트 가이드라인
├── GUIDE.md          # 이 파일 — 구조 설명
└── STRATEGY.md       # 활용 전략 문서
```

---

## 에이전트 역할 & 관계

### 현재 에이전트 (7개)

| 에이전트 | 모델 | 역할 | 호출 방식 |
|---------|------|------|---------|
| `orchestrator` | opus | 메인 진입점. 요청 분류 → 위임 → 검증 | `claude --agent orchestrator` |
| `planner` | opus | 인터뷰 → 갭 분석 → 작업 계획 생성 | `claude --agent planner` |
| `oracle` | opus | 아키텍처 자문, 디버깅, 자기 검토 (읽기 전용) | orchestrator가 위임 |
| `deep-worker` | opus | 자율 심층 작업 실행 | orchestrator가 위임 |
| `librarian` | sonnet | 외부 문서/OSS 탐색 | orchestrator/planner가 background로 위임 |
| `search` | haiku | 빠른 사실/파일 검색 | orchestrator가 위임 |
| `ops-lead` | sonnet | 운영, 프로젝트 관리 | 직접 또는 orchestrator 위임 |

### 제거된 에이전트 (Wave 1~4에서 제거)

| 제거된 에이전트 | 흡수된 곳 |
|--------------|---------|
| `pre-planner` | planner 내부 갭 분석 체크리스트 |
| `plan-reviewer` | planner 내부 자기검토 루프 |
| `analyzer` | orchestrator/planner의 직접 Grep/Glob/Read |
| `media-reader` | Read 도구 (Claude Code는 PDF/이미지 네이티브 지원) |
| `delegator` | orchestrator의 notepad 시스템 + 6-섹션 프롬프트 |
| `fe-dev` | skills/fe/SKILL.md 전문가 페르소나 |
| `be-dev-nodejs` | skills/be/SKILL.md 전문가 페르소나 |
| `be-dev-python` | skills/be/SKILL.md 전문가 페르소나 |
| `macos-dev` | skills/macos/SKILL.md (신규 생성) |
| `designer` | skills/designer/SKILL.md 전문가 페르소나 |
| `po` | skills/po/SKILL.md 전문가 페르소나 |
| `qa` | skills/qa/SKILL.md 전문가 페르소나 |
| `data-analyst` | skills/data-analyst/SKILL.md 전문가 페르소나 |

---

## 스킬 시스템

### 스킬의 두 가지 역할

**1. 도메인 지식 저장소** (기존)
- 태스크-지식 매핑 테이블
- 참조 파일 (패턴, 컨벤션, 안티패턴)
- 기본 경로: `~/.claude/skills/{domain}/`

**2. 전문가 페르소나** (Wave 2에서 추가)
- 각 SKILL.md 끝의 `## Domain Expert Persona` 섹션
- 이 스킬이 로드될 때 워커 에이전트가 해당 도메인 전문가처럼 동작하게 만드는 identity/원칙

### 도메인 스킬 목록

| 스킬 | 커버하는 도메인 | 로드 방식 |
|-----|------------|---------|
| `fe` | React/Next.js, TypeScript, 상태관리, 테스트 | `load_skills=["fe"]` |
| `be` | Node.js/Fastify + Python/Django, PostgreSQL, API | `load_skills=["be"]` |
| `macos` | SwiftUI, AppKit, Swift Concurrency, XCTest | `load_skills=["macos"]` |
| `designer` | UI/UX, 디자인 시스템, Figma, 사용성 | `load_skills=["designer"]` |
| `po` | 제품 전략, PRD, 우선순위, 로드맵 | `load_skills=["po"]` |
| `qa` | 테스트 전략, 자동화, 성능/보안 테스트 | `load_skills=["qa"]` |
| `data-analyst` | SQL, A/B 테스트, 퍼널/코호트 분석 | `load_skills=["data-analyst"]` |

### 도메인 위임 패턴

```typescript
// 이전 방식 (제거됨)
task(subagent_type="fe-dev", prompt="...")

// 현재 방식 (Wave 2 이후)
task(
  category="visual-engineering",
  load_skills=["fe"],
  prompt=`
1. TASK: UserProfile 컴포넌트 리팩토링
2. EXPECTED OUTCOME: 4대 원칙 기반 분리, 테스트 포함
3. REQUIRED TOOLS: Read, Write, Edit, Grep, Glob
4. MUST DO: fe 스킬의 code-quality.md 참조
5. MUST NOT DO: 전역 상태 변경 금지
6. CONTEXT: src/components/UserProfile.tsx
`)
```

---

## 핵심 워크플로우

### 1. 일반 작업 실행

```
사용자 → orchestrator
  │
  ├─ Trivial 요청 → 직접 처리 (단순 파일 수정 등)
  ├─ 도메인 작업 → task(category+load_skills) → deep-worker (스킬 로드됨)
  ├─ 복잡한 계획 필요 → task(planner) → 계획 파일 생성
  ├─ 외부 참조 필요 → task(librarian, background=true) → 결과 수집
  └─ 아키텍처/디버깅 → task(oracle) → 자문 수령
```

### 2. 계획 기반 작업

```
사용자 → planner
  │
  ├─ Phase 1: 인터뷰 (요구사항 명확화)
  │   ├─ 직접 탐색: Grep/Glob/Read 병렬 실행
  │   └─ 외부 참조: librarian background 위임
  │
  ├─ Phase 2: 갭 분석 (내부 체크리스트)
  │   └─ 갭 분석 → 즉시 계획 생성
  │
  └─ Phase 3: High Accuracy 모드 (선택)
      └─ 자기검토 루프 (OKAY 판정까지)
  
결과: .orchestrator/plans/{name}.md → orchestrator가 실행
```

### 3. 팀 협업 실행

```bash
# 전체 팀
claude-team full "다크모드 기능 추가"

# 개발 팀 (FE+BE+QA+OPS+DA)
claude-team dev "성능 최적화"

# 제품 팀 (PO+Designer+FE+BE+QA)
claude-team prod "신규 온보딩 플로우"
```

---

## Notepad 시스템 (플랜 실행 시)

플랜을 orchestrator가 실행할 때, 서브에이전트 간 지식 공유를 위해 notepad를 사용한다.

```
.orchestrator/
  plans/
    {plan-name}.md        # 작업 계획 (읽기 전용)
  notepads/
    {plan-name}/
      learnings.md        # 컨벤션, 패턴 발견
      decisions.md        # 아키텍처 결정
      issues.md           # 문제, 주의사항
  evidence/
    task-{N}-{scenario}.{ext}  # QA 증거 파일
  drafts/
    {name}.md             # 플래너 작업 중 초안
```

**규칙:**
- 위임 전: 항상 notepad 읽기
- 위임 후: 서브에이전트가 발견한 내용을 notepad에 append (덮어쓰기 금지)

---

## 권한 & 설정

### settings.json 핵심 설정

```json
{
  "permissions": {
    "allow": ["Bash(*)", "Read(*)", "Write(*)", "Edit(*)", "Glob(*)", "Grep(*)", 
              "WebFetch(*)", "WebSearch(*)", "Task(*)", "mcp__*", "Skill(*)"]
  },
  "enabledPlugins": {
    "playwright": true,    // E2E 테스트 자동화
    "typescript-lsp": true, // 타입 진단
    "github": true,        // PR/이슈 관리
    "context7": true,      // 외부 문서 검색
    "skill-creator": true, // 스킬 생성/관리
    ...
  }
}
```

### Hooks

| 이벤트 | 동작 |
|-------|------|
| `Notification` | 리모트 알림 + macOS 로컬 알림 |
| `SessionStart` | 세션 시작 알림 |
| `Stop` | 세션 종료 알림 |

훅 스크립트 위치: `~/.claude/hooks/` (홈 디렉토리 — 실제 경로로 수정 필요)

---

## 버전 히스토리

| Wave | 변경 사항 |
|------|---------|
| Wave 1 | pre-planner, plan-reviewer → planner 내부 통합 |
| Wave 2 | 도메인 에이전트 8개 → skills/*/SKILL.md 전문가 페르소나로 전환, macos 스킬 신규 생성 |
| Wave 3 | analyzer, media-reader 제거 → 직접 도구 사용 |
| Wave 4 | delegator → orchestrator 흡수 (notepad 시스템, 6-섹션 프롬프트 강화) |
| Wave 5 | settings.json 권한 정리, hooks 경로 표준화 |
