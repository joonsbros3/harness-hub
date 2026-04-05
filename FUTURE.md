# Harness-Hub의 다음 단계

> solo harness를 안정화한 뒤, 언제 어떻게 Claude Agent Team으로 확장할지에 대한 메모

**요약**: 현재는 solo harness 안정화가 우선이다. 에이전트 팀은 맞는 미래 방향이지만, 기능이 실험적이고 여러 Opus 인스턴스를 동시에 쓰는 만큼 비용이 크다. 루프 방지 원칙이 검증된 뒤 병렬성이 실제로 이득인 작업에만 팀을 도입한다.

---

## 1. 결론 먼저

지금 harness-hub의 방향은 맞다.

- 현재 우선순위는 **팀화 자체**가 아니라 **루프 방지와 재현성 확보**다.
- Agent Team은 장기적으로 유효한 확장 방향이지만, **기본 운영체제가 안정화된 뒤** 들어가는 것이 맞다.
- 당분간의 기본 구조는 `orchestrator 중심 + 필요 시 planner + QA 게이트 + issues.md 축적`으로 유지한다.

즉:

1. 먼저 solo harness를 실전에서 검증한다.
2. 반복적으로 병목이 생기는 영역만 팀으로 올린다.
3. 최종적으로는 Claude Agent Team을 사용하는 하네스로 발전시킨다.

---

## 2. 왜 지금 방향이 맞는가

### 2.1 내가 해결하려는 핵심 문제

현재 문제는 "에이전트가 부족해서"가 아니라 아래에 가깝다.

- 요구사항이 흐려진 상태에서 계속 밀고 나가며 루프가 발생
- 세션이 바뀔 때 컨텍스트가 다시 초기화됨
- 구현 후 검증 없이 다음 단계로 넘어가 되감기 비용이 커짐
- 도메인별 판단 기준이 세션마다 흔들림

이 문제들은 Agent Team 없이도 크게 줄일 수 있다.

- planner 전환 기준 명확화
- 스킬 로드
- QA 게이트
- `/dev-docs-update`
- `.orchestrator/notepads/{plan-name}/issues.md`

이 다섯 가지가 먼저 안정화되어야 한다.

### 2.2 Agent Team은 강력하지만 공짜가 아니다

Claude Code 공식 문서 기준으로 Agent Team은 다음 성격을 가진다.

- 여러 Claude Code 세션을 팀으로 묶어 병렬 작업 수행
- shared task list 기반 협업
- 팀원끼리 직접 메시지 가능
- 리드가 팀 생성, 조율, 결과 종합

하지만 동시에:

- **experimental** 기능이다
- 기본 비활성화 상태다
- 세션 재개, 태스크 조정, 종료 동작에 알려진 제한이 있다
- 단일 세션보다 토큰 사용량이 더 크다
- 순차 작업, 같은 파일 편집, 의존성이 많은 작업에는 오히려 비효율적이다

따라서 "항상 팀"이 아니라 "병렬성이 실제로 이득일 때만 팀"이 맞다.

---

## 3. 공식 자료 기준으로 본 판단

### 3.1 Subagents는 이미 현재 구조와 잘 맞는다

Claude Code 공식 문서는 specialized subagent 사용을 권장한다.

- 역할이 명확한 작업에 잘 맞는다
- 각 subagent는 자체 컨텍스트를 가진다
- 결과는 메인 에이전트로 돌아온다
- 빠르고 집중된 작업에 적합하다

harness-hub의 현재 구조는 여기에 잘 맞는다.

- orchestrator가 메인 진입점
- planner는 계획 전용
- oracle은 읽기 전용 고난도 자문
- deep-worker는 구현
- librarian은 외부 자료 조사

즉 현재 구조는 이미 Claude Code의 공식 하위 에이전트 철학과 충돌하지 않는다.

### 3.2 Agent Team은 "협업이 필요한 경우"에만 맞는다

공식 문서가 제시하는 Agent Team의 강한 유스케이스:

- research / review
- 서로 다른 가설을 병렬 검증하는 debugging
- frontend / backend / test처럼 cross-layer coordination
- 서로 독립적인 새 기능 단위 병렬 구현

공식 문서가 덜 맞다고 말하는 케이스:

- 순차 작업
- 같은 파일을 자주 건드리는 작업
- 의존성이 복잡하게 얽힌 작업
- 단일 세션으로 충분한 작업

이 기준은 harness-hub의 철학과 잘 맞는다.

- 모든 일을 팀으로 올리지 않는다
- 병렬성이 진짜 이득일 때만 팀을 만든다
- solo mode가 기본이고 team mode는 확장이다

### 3.3 Hooks는 팀 모드에서도 중요성이 더 커진다

공식 Agent Team 문서에는 `TaskCreated`, `TaskCompleted`, `TeammateIdle` 같은 이벤트에 훅을 붙여
quality gate를 걸 수 있다고 나온다.

이건 harness-hub에 좋은 신호다.

왜냐하면 지금도 hooks 기반 구조를 이미 쓰고 있기 때문이다.

- `UserPromptSubmit` → skill recommendation
- `PostToolUse` → 편집 추적
- `Notification` → 원격 알림

즉 나중에 Agent Team으로 확장하더라도, 기존 hooks 철학은 버리는 것이 아니라 **강화**되는 방향이다.

---

## 4. 지금 당장 Team 중심으로 가지 않는 이유

### 4.1 먼저 검증해야 할 것은 "운영 원칙"이다

아직 확인해야 할 것:

- planner 전환 기준이 실제로 루프를 줄이는가
- skills 로드가 판단 품질을 안정화하는가
- QA 게이트가 되감기 비용을 줄이는가
- issues.md 축적이 재발 방지에 실제로 기여하는가

이건 Team을 쓰기 전에 알아야 한다.

운영 원칙이 검증되지 않은 상태에서 Team으로 가면,
문제가 구조 부족 때문인지 팀 조율 비용 때문인지 구분하기 어려워진다.

### 4.2 Agent 수가 늘수록 예전 문제로 회귀할 수 있다

이미 한 번 에이전트 수가 많아졌을 때:

- 책임 경계가 흐려지고
- 어느 에이전트를 써야 할지 판단 비용이 생기고
- 그것 자체가 루프를 만들었다

Agent Team도 잘못 쓰면 같은 문제가 생긴다.

특히 아래 상황은 위험하다.

- 역할을 너무 잘게 쪼갬
- 같은 파일을 여러 팀원이 만짐
- 리드가 계속 coordination에만 시간을 씀
- solo로 충분한 작업도 팀으로 올림

### 4.3 팀은 "문제를 풀기 위한 병렬화"여야 한다

팀을 쓰는 이유는 화려함이 아니라 다음이어야 한다.

- 서로 다른 시야가 동시에 필요함
- 독립적인 작업 단위가 명확함
- 팀원 간 토론이나 상호 검증이 실제 가치를 만듦

이 기준이 아니면 subagent나 solo orchestrator가 더 낫다.

---

## 5. 미래 방향: 3단계 로드맵

## Stage 1. Solo Harness 안정화

목표:

- 지금 구조가 실제로 루프를 줄이는지 검증
- 불필요한 규칙 제거
- 최소 운영체제 확정

운영 원칙:

- 기본은 `claude` 또는 `claude --agent orchestrator`
- 방향이 흐리거나 2개 이상 모듈이 얽히면 `planner`
- 구현 후 반드시 QA 게이트
- 실패 패턴은 `issues.md`에 축적
- 컨텍스트 리셋 전 `/dev-docs-update`

성공 기준:

- 같은 설명을 반복하는 빈도가 눈에 띄게 줄어듦
- 엉뚱한 방향으로 구현되는 비율 감소
- QA 없이 PR로 가는 일이 사라짐
- 실제로 자주 쓰는 스킬/훅/커맨드가 정리됨

이 단계에서 할 일:

1. 2~4주 정도 실제 작업에 harness-hub 적용
2. 루프가 생긴 사례를 `issues.md`에 계속 기록
3. 거의 안 쓰는 규칙/문구/패턴은 제거
4. 자주 쓰는 스킬만 남기고 나머지는 약화

## Stage 2. Small Team Experiments

목표:

- Team이 진짜 가치 있는 구간만 찾기
- coordination overhead의 실제 체감 확인

추천 시작 조합:

- `FE + BE + QA`
- 또는 `Research + Devil's Advocate + Reviewer`

좋은 실험 과제:

- cross-layer feature
- 독립적인 가설이 있는 debugging
- 병렬 review / research
- 새 모듈 여러 개를 동시에 설계/탐색하는 작업

좋지 않은 실험 과제:

- 같은 파일 중심 리팩터링
- dependency chain이 긴 순차 작업
- 단순 버그 수정
- solo orchestrator로 충분한 작업

운영 원칙:

- 팀 크기는 작게 시작
- 역할은 3개 내외로 제한
- 같은 파일 ownership 충돌을 피함
- 리드는 항상 synthesis와 quality gate에 집중

성공 기준:

- solo보다 빨라졌는가
- 리뷰 품질이 좋아졌는가
- coordination cost가 감당 가능한가
- 팀원 직접 메시징이 실제로 도움이 되는가

이 단계에서 할 일:

1. Agent Team은 실험적 기능으로만 사용
2. 템플릿 팀을 1~2개만 정의
3. 팀이 유효한 작업 패턴을 기록
4. team이 오히려 손해인 패턴도 함께 기록

## Stage 3. Team-Native Harness

목표:

- 검증된 팀 패턴만 제도화
- hooks와 quality gate를 팀 구조에 맞게 확장

이 단계에서 가능한 발전:

- 팀별 템플릿 정의
- `TaskCreated` / `TaskCompleted` / `TeammateIdle` 훅 기반 품질 게이트
- plan approval 기준 자동화
- FE/BE/QA 또는 Research/Review 등 팀 조합 표준화
- 팀 리드용 운영 문서 별도화

예상되는 형태:

- solo mode: 기본 작업
- team mode: cross-layer / review / 병렬 연구 작업
- hooks: 팀 품질 게이트
- issues.md + 팀 실험 기록: 운영 데이터

성공 기준:

- 언제 solo / subagent / team을 쓸지 기준이 명확함
- 팀을 쓸 때 평균 성과가 solo보다 좋아짐
- coordination이 습관화되어도 과도한 오버헤드가 없음

---

## 6. 권장 의사결정 규칙

작업이 들어오면 아래 순서로 판단한다.

1. 단일 세션으로 충분한가?
2. subagent 수준 병렬화면 충분한가?
3. 팀원끼리 직접 소통해야 가치가 생기는가?
4. 파일 충돌 없이 ownership 분리가 가능한가?
5. coordination overhead를 감수할 만큼 병렬 이득이 큰가?

판단:

- 1이 yes면 solo
- 1이 no, 2가 yes면 subagents
- 2도 no이고 3~5가 yes면 Agent Team

이 규칙을 잃지 않는 것이 중요하다.

---

## 7. 향후 문서/기능 후보

### 문서

- `TEAMING.md`  
  Agent Team 실험 결과, 어떤 과제에 팀이 맞는지, ownership 규칙, 종료 절차 정리

- `TEAM_TEMPLATES.md`  
  FE/BE/QA, Research Trio, Review Squad 같은 팀 템플릿 문서

- `LOOPS.md`  
  반복적으로 생긴 실패 패턴 축적 문서

### 기능

- `TeammateIdle` 훅으로 idle teammate 재가동/피드백
- `TaskCreated` 훅으로 과도하게 큰 작업 차단
- `TaskCompleted` 훅으로 QA 없이 완료 처리되는 것 방지
- 보안 스킬 추가
- 린트/테스트 자동 quality gate

---

## 8. 현재 판단

정리하면:

- harness-hub의 현재 방향은 맞다
- Agent Team은 맞는 미래 방향이다
- 하지만 **지금 즉시 중심축으로 올리기보다, Stage 1 → Stage 2 → Stage 3 순서**가 더 안전하다
- 핵심은 "항상 팀"이 아니라 "팀이 진짜 이득인 작업만 팀으로 올린다"이다

이 문서의 기본 입장:

> solo harness를 먼저 완성하고,
> team은 검증된 패턴 위에 얹는다.

---

## 9. 참고 자료

- Claude Code Docs: [Subagents](https://code.claude.com/docs/en/sub-agents)
- Claude Code Docs: [Hooks](https://code.claude.com/docs/en/hooks)
- Claude Code Docs: [Common Workflows](https://code.claude.com/docs/en/common-workflows)
- Claude Code Docs: [Agent Teams](https://code.claude.com/docs/en/agent-teams)
- Claude Code Docs: [Settings](https://code.claude.com/docs/en/settings)
- Anthropic Docs: [Claude Code](https://docs.anthropic.com/claude-code)

### 메모

Agent Teams는 2026-04-05 기준 Claude Code 공식 문서에 존재하지만, experimental 기능으로 안내된다. 따라서 harness-hub의 장기 목표로 두는 것은 타당하나, 운영 중심축으로 삼기 전 충분한 실험이 필요하다.
