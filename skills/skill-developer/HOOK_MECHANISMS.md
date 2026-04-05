# Hook Mechanisms - Deep Dive

harness-hub 훅의 내부 동작 상세. 현재 구현된 훅과 참조 패턴을 포함한다.

## Table of Contents

- [UserPromptSubmit — skill-activation-prompt (구현됨)](#userpromptsubmit-hook-flow)
- [PostToolUse — post-tool-use-tracker (구현됨)](#posttooluse-hook-flow)
- [PreToolUse 참조 패턴 (미구현)](#pretooluse-참조-패턴)
- [Exit Code Behavior](#exit-code-behavior-critical)
- [Performance Considerations](#performance-considerations)

---

## UserPromptSubmit Hook Flow

### Execution Sequence

```
User submits prompt
    ↓
.claude/settings.json registers hook
    ↓
skill-activation-prompt.sh executes
    ↓
npx tsx skill-activation-prompt.ts
    ↓
Hook reads stdin (JSON with prompt)
    ↓
Loads skill-rules.json
    ↓
Matches keywords + intent patterns
    ↓
Groups matches by priority (critical → high → medium → low)
    ↓
Outputs formatted message to stdout
    ↓
stdout becomes context for Claude (injected before prompt)
    ↓
Claude sees: [skill suggestion] + user's prompt
```

### Key Points

- **Exit code**: Always 0 (allow)
- **stdout**: → Claude's context (injected as system message)
- **Timing**: Runs BEFORE Claude processes prompt
- **Behavior**: Non-blocking, advisory only
- **Purpose**: Make Claude aware of relevant skills

### Input Format

```json
{
  "session_id": "abc-123",
  "transcript_path": "/path/to/transcript.json",
  "cwd": "/root/git/your-project",
  "permission_mode": "normal",
  "hook_event_name": "UserPromptSubmit",
  "prompt": "how does the layout system work?"
}
```

### Output Format (to stdout)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 SKILL ACTIVATION CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 RECOMMENDED SKILLS:
  → project-catalog-developer

ACTION: Use Skill tool BEFORE responding
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Claude sees this output as additional context before processing the user's prompt.

---

## PostToolUse Hook Flow

### 현재 구현: post-tool-use-tracker

```
Claude가 Edit/Write/MultiEdit 도구 실행 완료
    ↓
settings.json의 PostToolUse 훅이 트리거 (matcher: Edit|Write|MultiEdit)
    ↓
post-tool-use-tracker.sh 실행
    ↓
stdin에서 tool_name, file_path, session_id 파싱 (jq 사용)
    ↓
마크다운 파일이면 스킵
    ↓
파일 경로에서 소속 레포 감지 (detect_repo)
    ↓
.claude/tsc-cache/{session_id}/ 에 기록:
  - edited-files.log (타임스탬프:파일경로:레포)
  - affected-repos.txt (영향받은 레포 목록)
  - commands.txt (레포별 TSC 커맨드)
    ↓
exit 0 (항상)
```

### Key Points

- **Exit code**: 항상 0 (PostToolUse는 차단 불가)
- **Timing**: 도구 실행 완료 후
- **Purpose**: 편집 파일 추적 + TSC 커맨드 캐싱
- **Consumer**: `auto-error-resolver` 에이전트
- **Fail open**: jq 없으면 조용히 종료

### Input Format

```json
{
  "session_id": "abc-123",
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/path/to/project/frontend/src/app.ts"
  }
}
```

---

## PreToolUse 참조 패턴

> ⚠️ 현재 harness-hub에 미구현. guardrail 스킬이 필요할 때 참조하는 패턴.

PreToolUse 훅은 Claude가 도구를 실행하기 **전에** 가로채어 차단할 수 있다.

### 동작 원리

```
Claude가 Edit/Write 도구 호출 시도
    ↓
settings.json의 PreToolUse 훅 트리거
    ↓
훅 스크립트가 stdin에서 tool_name, tool_input 파싱
    ↓
스킬 규칙과 매칭 (파일 경로 패턴, 콘텐츠 패턴 등)
    ↓
IF 매칭 AND 스킵 조건 미충족:
  stderr에 차단 메시지 출력
  exit 2 (BLOCK) → 도구 실행 차단, stderr → Claude
ELSE:
  exit 0 (ALLOW) → 도구 정상 실행
```

### 핵심: exit code 2

- PreToolUse에서 Claude에게 메시지를 전달하는 **유일한** 방법
- stderr 내용이 Claude에게 자동 전달됨
- Claude는 차단 메시지를 보고 스킬을 사용한 후 재시도

### 구현 시 settings.json 추가 예시

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/skill-verification-guard.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Exit Code Behavior (CRITICAL)

### Exit Code Reference Table

| Hook Event | Exit Code | stdout | stderr | 도구 실행 | Claude가 보는 것 |
|------------|-----------|--------|--------|-----------|-----------------|
| UserPromptSubmit | 0 | → Claude 컨텍스트 | → User only | N/A | stdout 내용 |
| PostToolUse | 0 | → User only | → User only | 이미 완료 | Nothing |
| PreToolUse | 0 | → User only | → User only | **실행됨** | Nothing |
| PreToolUse | 2 | → User only | → **CLAUDE** | **차단됨** | stderr 내용 |
| 기타 | any | → User only | → User only | 차단됨 | Nothing |

### PreToolUse exit code 2가 중요한 이유

PreToolUse에서 Claude에게 메시지를 전달하는 **유일한** 방법:

1. stderr 내용이 Claude에게 자동 전달됨
2. Claude는 차단 메시지를 보고 스킬을 사용
3. 도구 실행이 방지됨
4. 재시도 시 세션 트래킹으로 허용

---

---

## Performance Considerations

### 현재 병목

**skill-activation-prompt (UserPromptSubmit):**
- `npx tsx`로 TypeScript 트랜스파일 + 실행 → cold start ~500ms-1.5s
- 매 프롬프트마다 실행되므로 체감 가능
- **개선안**: `tsc`로 사전 컴파일 후 `node dist/skill-activation-prompt.js`로 실행 (~50ms)

**post-tool-use-tracker (PostToolUse):**
- 순수 bash + jq → ~20-50ms, 병목 아님

### 최적화 전략

**skill-rules.json 패턴 관리:**
- 불필요한 패턴 제거 (매칭 시간 감소)
- 유사한 패턴 병합
- 정규식 단순화

---

**Related Files:**
- [SKILL.md](SKILL.md) - Main skill guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Debug hook issues
- [SKILL_RULES_REFERENCE.md](SKILL_RULES_REFERENCE.md) - Configuration reference
