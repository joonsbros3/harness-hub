# Harness-Hub 활용 전략

> 재설계 후 harness-hub를 최대한 활용하기 위한 운영 전략

---

## 1. 진입점 선택 전략

### 언제 무엇을 쓸까

```
요청 유형                           → 선택
─────────────────────────────────────────────
간단한 코드 수정, 파일 탐색           → claude (기본 세션)
복잡한 구현, 도메인 전문성 필요        → claude --agent orchestrator
대규모 기능 설계, 요구사항 불명확      → claude --agent planner
아키텍처 자문, 어려운 디버깅          → claude --agent oracle
팀 기반 풀 제품 개발                  → claude-team {full|prod|dev}
```

### orchestrator vs planner

| 상황 | orchestrator | planner |
|------|-------------|---------|
| 요구사항이 명확할 때 | ✅ 즉시 실행 | ❌ 과도함 |
| 요구사항이 모호할 때 | ❌ 잘못된 방향으로 실행 위험 | ✅ 인터뷰 후 계획 |
| 대규모 기능 개발 | ✅ 계획 파일 실행 | ✅ 계획 파일 생성 |
| 버그 수정 | ✅ 직접 | ❌ 오버엔지니어링 |
| 아키텍처 결정 | ✅ oracle 자문 요청 | ✅ oracle 자문 포함 계획 |

**권장 조합**: planner → 계획 파일 생성 → orchestrator → 실행

---

## 2. 도메인 스킬 활용 전략

### 스킬 로드의 효과

`load_skills=["fe"]`를 지정하면:
1. `skills/fe/SKILL.md`의 **전문가 페르소나**가 로드됨
2. **태스크-지식 매핑 테이블**에서 관련 참조 파일을 Read
3. 워커 에이전트가 시니어 FE 엔지니어처럼 판단하고 구현

### 스킬 선택 가이드

| 작업 내용 | 로드할 스킬 | category |
|---------|-----------|---------|
| React 컴포넌트, Next.js, 스타일링 | `fe` | `visual-engineering` |
| Node.js/Fastify API, PostgreSQL | `be` | `unspecified-high` |
| Python/Django REST, Celery | `be` | `unspecified-high` |
| SwiftUI, macOS 앱 | `macos` | `unspecified-high` |
| UI/UX 디자인, 와이어프레임 | `designer` | `visual-engineering` |
| PRD, 로드맵, 우선순위 | `po` | `unspecified-high` |
| 테스트 전략, 자동화 | `qa` | `unspecified-high` |
| SQL, A/B 테스트, 지표 | `data-analyst` | `unspecified-high` |

**복합 스킬**: 여러 도메인이 겹칠 때 함께 로드 가능
```typescript
task(category="unspecified-high", load_skills=["be", "qa"], prompt="...")
// 백엔드 구현 + 테스트 작성
```

### 스택 명시 (BE 공통 스킬)

BE 스킬은 Python과 Node.js를 모두 커버한다. prompt에 스택을 명시해야 한다:
```
// Python 스택
load_skills=["be"], prompt="... Python/Django 스택 사용. Django 5+, DRF, pytest ..."

// Node.js 스택  
load_skills=["be"], prompt="... Node.js/Fastify 스택 사용. Fastify 5, Drizzle ORM, Vitest ..."
```

---

## 3. 계획 기반 실행 전략 (대규모 작업)

### 플로우

```
1. claude --agent planner
   → 인터뷰 → 갭 분석 → .orchestrator/plans/{name}.md 생성

2. claude --agent orchestrator
   → 계획 파일 읽기 → 태스크 분석 → 병렬 실행

3. 실행 중 notepad 활용
   .orchestrator/notepads/{name}/
   → 위임 전 항상 읽기, 완료 후 항상 append
```

### 계획 파일 품질 기준

좋은 계획 파일의 조건:
- **1개 파일에 전체 작업** (분할 금지)
- **태스크당 1-3개 파일** (더 많으면 분리)
- **파형(wave)당 5-8개 태스크** (병렬 실행 최적화)
- **에이전트 실행 가능한 수락 기준** (사람 행동 없이 검증 가능)
- **구체적인 참조 파일** (`src/auth.ts:45-78`)

### High Accuracy 모드 사용 시점

| 상황 | 권장 |
|------|-----|
| 빠른 프로토타입 | ❌ Skip — Start Work 선택 |
| 프로덕션 기능 | ✅ High Accuracy 선택 |
| 복잡한 리팩토링 | ✅ High Accuracy 선택 |
| 버그 수정 계획 | ❌ Skip — 과도함 |

---

## 4. 코드베이스 탐색 전략

Wave 3에서 analyzer 에이전트 제거 후, 코드베이스 탐색은 직접 도구로 수행한다.

### 탐색 패턴

**단일 검색** (알고 있을 때):
```
Grep("function login", "src/**/*.ts")
Read("src/auth/login.ts")
```

**병렬 다중 탐색** (모를 때):
```
// 동시에 실행
Grep("authentication", "src/**/*.ts")
Glob("**/auth/**")
Read("src/middleware/auth.ts")
Bash("git log --oneline src/auth/")
```

**패턴 발견** (새 기능 추가 전):
```
Glob("src/**/[similar]/**")      // 유사 구현체 디렉토리
Read("src/[similar]/index.ts")   // 진입점 구조
Grep("export", "src/[similar]")  // export 패턴
```

### 외부 참조 (librarian)

외부 라이브러리/문서가 필요할 때만 librarian을 사용한다:
```typescript
// 항상 background로 실행, 다음 작업과 병렬
task(subagent_type="librarian", run_in_background=true, load_skills=[], 
     prompt="Find official Fastify 5 docs: plugin system, lifecycle hooks, error handling...")
```

---

## 5. QA 전략 (CLAUDE.md PR 프로세스)

### 필수 PR 프로세스

```
1. FE/BE 구현 완료
2. QA 사전 검증 (qa 스킬 로드 워커)
3. 이슈 발견 → FE/BE 수정 → QA 재검증 (반복)
4. QA 통과 확인 후 PR 생성
5. CI/CD 대기 (run_in_background)
6. 코드 리뷰 반영 후 머지 승인 요청
```

### QA 워커 호출 패턴

```typescript
task(
  category="unspecified-high",
  load_skills=["qa"],
  prompt=`
1. TASK: 구현된 [기능]에 대한 QA 검증
2. EXPECTED OUTCOME: 
   - 모든 테스트 통과 확인
   - 엣지 케이스 검증 완료
   - 이슈 목록 (있는 경우)
3. REQUIRED TOOLS: Bash, Read, Grep
4. MUST DO: 
   - Happy path 검증
   - Error case 검증  
   - 경계값 테스트
5. MUST NOT DO: 
   - 코드 수정 금지 (검증만 수행)
6. CONTEXT: [구현된 파일 경로들]
`)
```

---

## 6. 성능 최적화 전략

### 비용 vs 품질 균형

| 작업 | 모델 선택 | 이유 |
|------|---------|------|
| 아키텍처 결정 | opus (oracle) | 최고 추론 필요 |
| 도메인 구현 | opus (deep-worker + skill) | 복잡한 코드 작성 |
| 외부 문서 검색 | sonnet (librarian) | 검색은 reasoning보다 검색력 |
| 빠른 파일 탐색 | haiku (search) | 단순 검색 |

### 병렬 실행으로 속도 향상

```typescript
// 독립적인 작업은 동시에 위임
task(category="visual-engineering", load_skills=["fe"], prompt="FE Task A...")
task(category="unspecified-high", load_skills=["be"], prompt="BE Task B...")
task(category="unspecified-high", load_skills=["qa"], prompt="QA Task C...")
// 세 태스크가 동시에 실행됨
```

### 세션 연속성 (토큰 절약)

실패하거나 후속 작업이 있을 때, 새 세션을 시작하지 말고 기존 세션을 재개한다:
```typescript
// ❌ WRONG: 새 세션 시작 (컨텍스트 손실 + 토큰 낭비)
task(category="visual-engineering", load_skills=["fe"], prompt="Fix the error...")

// ✅ CORRECT: 기존 세션 재개 (컨텍스트 보존 + 70% 토큰 절약)
task(session_id="ses_xyz789", prompt="Fix error: [specific error message]")
```

---

## 7. 스킬 생성 전략

### 새 도메인 스킬 추가 절차

1. `skills/{domain}/` 디렉토리 생성
2. `SKILL.md` 작성:
   - frontmatter (name, description)
   - 핵심 원칙
   - 태스크-지식 매핑 테이블
   - `## Domain Expert Persona` 섹션
3. 참조 파일들 추가 (`{topic}.md`)
4. orchestrator의 도메인 트리거에 추가

### 기존 스킬 업데이트

참조 파일이 오래된 경우:
1. skill-creator 플러그인 사용 또는
2. 직접 해당 `~/.claude/skills/{domain}/{file}.md` 수정

---

## 8. 운영 체크리스트

### 세션 시작 전

- [ ] 올바른 에이전트를 선택했는가? (orchestrator vs planner)
- [ ] 관련 스킬을 파악했는가? (`load_skills=["?"]`)
- [ ] 기존 계획 파일이 있는가? (`.orchestrator/plans/`)

### 위임 전

- [ ] 6-섹션 프롬프트를 작성했는가? (30줄 이상)
- [ ] MUST DO / MUST NOT DO가 명시되었는가?
- [ ] 참조 파일 경로가 구체적인가? (`src/auth.ts:45-78`)
- [ ] planner 기반이라면 notepad를 먼저 읽었는가?

### 위임 후

- [ ] 결과가 MUST DO를 충족하는가?
- [ ] 결과가 MUST NOT DO를 위반하지 않는가?
- [ ] lsp_diagnostics가 깨끗한가?
- [ ] 세션 ID를 저장했는가? (실패 시 재개용)

### PR 생성 전

- [ ] QA 검증을 통과했는가?
- [ ] 모든 테스트가 통과하는가?
- [ ] 커밋 컨벤션을 준수했는가? (`commit-convention` 스킬 참조)

---

## 9. 트러블슈팅

### 자주 발생하는 문제

**워커가 잘못된 스택으로 구현할 때 (BE 공통 스킬)**
→ prompt 6. CONTEXT에 "Node.js/Fastify 스택" 또는 "Python/Django 스택"을 명시

**스킬이 로드되지 않을 때**
→ `skill` 도구로 사용 가능한 스킬 목록 확인
→ `~/.claude/skills/{domain}/SKILL.md` 경로 확인

**계획 실행 중 컨텍스트 손실**
→ notepad 시스템 활성화: `.orchestrator/notepads/{name}/learnings.md` 점검

**oracle 결과를 기다리지 않고 답변**
→ background_output을 final answer 전에 반드시 수집
→ `background_cancel(all=true)` 절대 금지 (oracle 취소됨)

**QA 통과 전 PR 생성 시도**
→ CLAUDE.md PR 프로세스 재확인: QA 통과 후 PR 생성이 필수

---

## 10. 빠른 참조

```bash
# 에이전트 모드 실행
claude --agent orchestrator        # 일반 작업
claude --agent planner             # 계획 수립
claude --agent oracle              # 아키텍처 자문

# 팀 모드 실행
claude-team full "태스크"          # PO+Designer+FE+BE+QA+OPS+DA
claude-team prod "태스크"          # PO+Designer+FE+BE+QA
claude-team dev "태스크"           # FE+BE+QA+OPS+DA

# 슬래시 커맨드
/init-deep                         # CLAUDE.md 계층 생성
/ulw-loop                          # 자기개선 루프

# 스킬 도구
Skill("fe")                        # FE 스킬 로드
Skill("be")                        # BE 스킬 로드
Skill("commit-convention")         # 커밋 컨벤션 확인
```
