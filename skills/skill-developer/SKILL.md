---
name: skill-developer
description: Create and manage Claude Code skills following Anthropic best practices. Use when creating new skills, modifying skill-rules.json, understanding trigger patterns, working with hooks, debugging skill activation, or implementing progressive disclosure. Covers skill structure, YAML frontmatter, trigger types (keywords, intent patterns, file paths, content patterns), enforcement levels (block, suggest, warn), hook mechanisms (UserPromptSubmit, PreToolUse), session tracking, and the 500-line rule.
---

# Skill Developer Guide

## Purpose

Comprehensive guide for creating and managing skills in Claude Code with auto-activation system, following Anthropic's official best practices including the 500-line rule and progressive disclosure pattern.

## When to Use This Skill

Automatically activates when you mention:
- Creating or adding skills
- Modifying skill triggers or rules
- Understanding how skill activation works
- Debugging skill activation issues
- Working with skill-rules.json
- Hook system mechanics
- Claude Code best practices
- Progressive disclosure
- YAML frontmatter
- 500-line rule

---

## System Overview

### Hook Architecture (현재 구현)

harness-hub에는 2개의 훅이 구현되어 있다:

**1. UserPromptSubmit — skill-activation-prompt** (스킬 제안)
- **래퍼**: `~/.claude/hooks/skill-activation-prompt.sh`
- **구현체**: `~/.claude/hooks/skill-activation-prompt.ts` (npx tsx로 실행)
- **트리거**: 사용자 프롬프트 전송 직전
- **동작**: `skill-rules.json`의 keywords/intentPatterns으로 프롬프트 분석 → 매칭된 스킬 제안 메시지를 stdout으로 출력 → Claude 컨텍스트에 삽입
- **특성**: Non-blocking, advisory only (exit code 항상 0)

**2. PostToolUse — post-tool-use-tracker** (파일 편집 추적)
- **파일**: `~/.claude/hooks/post-tool-use-tracker.sh`
- **트리거**: Edit/Write/MultiEdit 도구 실행 후
- **동작**: 편집된 파일과 소속 레포를 `.claude/tsc-cache/{session_id}/`에 기록. `auto-error-resolver` 에이전트가 이 캐시를 읽어 TypeScript 오류를 수정
- **특성**: Non-blocking, 추적 전용

### 추가 가능한 훅 (Claude Code 지원, 현재 미구현)

Claude Code는 다음 훅 이벤트도 지원한다. 필요 시 `settings.json`의 hooks 섹션에 추가:

- **PreToolUse**: 도구 실행 전 가로채기. exit code 2로 차단 가능 → guardrail 스킬 구현에 사용
- **Stop**: Claude 응답 완료 후. 결과 검증, 알림에 사용
- **SubagentStop**: 서브에이전트 완료 후

### Configuration File

**Location**: `~/.claude/skills/skill-rules.json`

정의하는 것:
- 모든 스킬과 트리거 조건 (keywords, intentPatterns)
- Enforcement 레벨 (suggest, warn, block)
- 우선순위 (critical, high, medium, low)

프로젝트별 오버라이드: `{project}/.claude/skills/skill-rules.json` (글로벌보다 우선)

---

## Skill Types

### 1. Guardrail Skills (PreToolUse 훅 필요 — 현재 미구현)

**Purpose:** 크리티컬한 실수를 방지하는 강제 스킬

> ⚠️ Guardrail 스킬은 PreToolUse 훅으로 Edit/Write를 차단해야 동작한다.
> 현재 harness-hub에는 PreToolUse 훅이 구현되어 있지 않다.
> 구현 시 `settings.json`의 hooks에 PreToolUse 이벤트를 추가하고,
> exit code 2로 차단 + stderr 메시지를 Claude에 전달하는 훅 스크립트를 작성한다.
> 상세 패턴은 [HOOK_MECHANISMS.md](HOOK_MECHANISMS.md)의 "PreToolUse 참조 패턴" 참조.

**Characteristics:**
- Type: `"guardrail"`
- Enforcement: `"block"`
- Priority: `"critical"` or `"high"`
- PreToolUse 훅이 Edit/Write를 차단
- Claude가 스킬을 사용한 후 재시도

**When to Use:**
- 런타임 에러를 유발하는 실수 방지
- 데이터 정합성 보호
- 크리티컬한 호환성 이슈

### 2. Domain Skills

**Purpose:** Provide comprehensive guidance for specific areas

**Characteristics:**
- Type: `"domain"`
- Enforcement: `"suggest"`
- Priority: `"high"` or `"medium"`
- Advisory, not mandatory
- Topic or domain-specific
- Comprehensive documentation

**Examples (harness-hub에 실제 존재):**
- `fe` - React/Next.js/TypeScript 프론트엔드 가이드
- `be` - Node.js/Fastify + Python/Django 백엔드 가이드
- `qa` - 테스트 전략, 자동화, 성능/보안 테스트

**When to Use:**
- Complex systems requiring deep knowledge
- Best practices documentation
- Architectural patterns
- How-to guides

---

## Quick Start: Creating a New Skill

### Step 1: Create Skill File

**Location:** `.claude/skills/{skill-name}/SKILL.md`

**Template:**
```markdown
---
name: my-new-skill
description: Brief description including keywords that trigger this skill. Mention topics, file types, and use cases. Be explicit about trigger terms.
---

# My New Skill

## Purpose
What this skill helps with

## When to Use
Specific scenarios and conditions

## Key Information
The actual guidance, documentation, patterns, examples
```

**Best Practices:**
- ✅ **Name**: Lowercase, hyphens, gerund form (verb + -ing) preferred
- ✅ **Description**: Include ALL trigger keywords/phrases (max 1024 chars)
- ✅ **Content**: Under 500 lines - use reference files for details
- ✅ **Examples**: Real code examples
- ✅ **Structure**: Clear headings, lists, code blocks

### Step 2: Add to skill-rules.json

See [SKILL_RULES_REFERENCE.md](SKILL_RULES_REFERENCE.md) for complete schema.

**Basic Template:**
```json
{
  "my-new-skill": {
    "type": "domain",
    "enforcement": "suggest",
    "priority": "medium",
    "promptTriggers": {
      "keywords": ["keyword1", "keyword2"],
      "intentPatterns": ["(create|add).*?something"]
    }
  }
}
```

### Step 3: Test Triggers

**Test UserPromptSubmit (skill-activation-prompt):**
```bash
echo '{"session_id":"test","prompt":"your test prompt"}' | \
  npx tsx ~/.claude/hooks/skill-activation-prompt.ts
```

매칭된 스킬이 있으면 `🎯 SKILL ACTIVATION CHECK` 배너가 출력된다.

### Step 4: Refine Patterns

Based on testing:
- Add missing keywords
- Refine intent patterns to reduce false positives
- Adjust file path patterns
- Test content patterns against actual files

### Step 5: Follow Anthropic Best Practices

✅ Keep SKILL.md under 500 lines
✅ Use progressive disclosure with reference files
✅ Add table of contents to reference files > 100 lines
✅ Write detailed description with trigger keywords
✅ Test with 3+ real scenarios before documenting
✅ Iterate based on actual usage

---

## Enforcement Levels

### BLOCK (Critical Guardrails — PreToolUse 훅 필요)

- PreToolUse 훅에서 exit code 2로 Edit/Write 실행을 차단
- stderr 메시지가 Claude에 전달되어 스킬 사용을 유도
- **현재 harness-hub에 미구현** — 구현 시 [HOOK_MECHANISMS.md](HOOK_MECHANISMS.md) 참조
- **Use For**: 크리티컬한 실수 방지, 데이터 정합성

### SUGGEST (Recommended)

- Reminder injected before Claude sees prompt
- Claude is aware of relevant skills
- Not enforced, just advisory
- **Use For**: Domain guidance, best practices, how-to guides

**Example:** Frontend development guidelines

### WARN (Optional)

- Low priority suggestions
- Advisory only, minimal enforcement
- **Use For**: Nice-to-have suggestions, informational reminders

**Rarely used** - most skills are either BLOCK or SUGGEST.

---

## Skip Conditions & User Control

현재 harness-hub의 훅은 모두 non-blocking(advisory)이므로 별도 skip 메커니즘이 필요하지 않다.

향후 PreToolUse guardrail 훅을 구현할 경우 다음 패턴을 사용할 수 있다:

- **Session tracking**: 세션당 1회만 차단 (`.claude/hooks/state/skills-used-{session_id}.json`)
- **File markers**: `// @skip-validation` 주석으로 영구 스킵
- **Environment variables**: `SKIP_SKILL_GUARDRAILS=true`로 긴급 비활성화

---

## Testing Checklist

스킬 생성 시 확인:

- [ ] `.claude/skills/{name}/SKILL.md` 파일 생성
- [ ] YAML frontmatter에 name과 description 포함
- [ ] `skill-rules.json`에 엔트리 추가
- [ ] Keywords를 실제 프롬프트로 테스트
- [ ] Intent patterns를 다양한 변형으로 테스트
- [ ] Priority 레벨이 중요도와 일치
- [ ] False positive/negative 없음
- [ ] JSON 유효성 검증: `jq . skill-rules.json`
- [ ] **SKILL.md 500줄 이하** ⭐
- [ ] Reference files 생성 (필요 시)
- [ ] 100줄 넘는 reference file에 목차 추가

---

## Reference Files

For detailed information on specific topics, see:

### [TRIGGER_TYPES.md](TRIGGER_TYPES.md)
Complete guide to all trigger types:
- Keyword triggers (explicit topic matching)
- Intent patterns (implicit action detection)
- File path triggers (glob patterns)
- Content patterns (regex in files)
- Best practices and examples for each
- Common pitfalls and testing strategies

### [SKILL_RULES_REFERENCE.md](SKILL_RULES_REFERENCE.md)
Complete skill-rules.json schema:
- Full TypeScript interface definitions
- Field-by-field explanations
- Complete guardrail skill example
- Complete domain skill example
- Validation guide and common errors

### [HOOK_MECHANISMS.md](HOOK_MECHANISMS.md)
훅 내부 동작 상세:
- UserPromptSubmit flow (skill-activation-prompt, 현재 구현)
- PostToolUse flow (post-tool-use-tracker, 현재 구현)
- PreToolUse 참조 패턴 (guardrail 구현 시 사용)
- Exit code 동작 테이블
- 성능 고려사항

### [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
Comprehensive debugging guide:
- Skill not triggering (UserPromptSubmit)
- PreToolUse not blocking
- False positives (too many triggers)
- Hook not executing at all
- Performance issues

### [PATTERNS_LIBRARY.md](PATTERNS_LIBRARY.md)
Ready-to-use pattern collection:
- Intent pattern library (regex)
- File path pattern library (glob)
- Content pattern library (regex)
- Organized by use case
- Copy-paste ready

### [ADVANCED.md](ADVANCED.md)
Future enhancements and ideas:
- Dynamic rule updates
- Skill dependencies
- Conditional enforcement
- Skill analytics
- Skill versioning

---

## Quick Reference Summary

### Create New Skill (5 Steps)

1. Create `.claude/skills/{name}/SKILL.md` with frontmatter
2. Add entry to `.claude/skills/skill-rules.json`
3. Test with `npx tsx` commands
4. Refine patterns based on testing
5. Keep SKILL.md under 500 lines

### Trigger Types (현재 구현)

- **Keywords**: 명시적 토픽 매칭 (대소문자 무시, 부분 문자열)
- **Intent Patterns**: 암묵적 의도 감지 (정규식)

> File path 트리거와 content 트리거는 Claude Code에서 지원하지만 현재 harness-hub에 미구현.
> 상세: [TRIGGER_TYPES.md](TRIGGER_TYPES.md)

### Enforcement

- **SUGGEST**: 컨텍스트 주입, 가장 일반적 (현재 구현)
- **WARN**: Advisory only (현재 구현)
- **BLOCK**: PreToolUse exit code 2로 차단 (현재 미구현)

### Skip Conditions

현재 harness-hub 훅은 모두 non-blocking이므로 skip 불필요.
Guardrail(PreToolUse) 구현 시: session tracking, file markers(`// @skip-validation`), env vars 사용 가능.

### Anthropic Best Practices

✅ **500-line rule**: Keep SKILL.md under 500 lines
✅ **Progressive disclosure**: Use reference files for details
✅ **Table of contents**: Add to reference files > 100 lines
✅ **One level deep**: Don't nest references deeply
✅ **Rich descriptions**: Include all trigger keywords (max 1024 chars)
✅ **Test first**: Build 3+ evaluations before extensive documentation
✅ **Gerund naming**: Prefer verb + -ing (e.g., "processing-pdfs")

### Troubleshoot

훅 수동 테스트:
```bash
# UserPromptSubmit (skill-activation-prompt)
echo '{"prompt":"react 컴포넌트 만들어줘"}' | npx tsx ~/.claude/hooks/skill-activation-prompt.ts

# PostToolUse (post-tool-use-tracker) — stdin에 JSON 전달
echo '{"tool_name":"Edit","tool_input":{"file_path":"src/app.ts"},"session_id":"test"}' | bash ~/.claude/hooks/post-tool-use-tracker.sh
```

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for complete debugging guide.

---

## Related Files

**Configuration:**
- `.claude/skills/skill-rules.json` - Master configuration
- `.claude/hooks/state/` - Session tracking
- `.claude/settings.json` - Hook registration

**Hooks:**
- `~/.claude/hooks/skill-activation-prompt.sh` → `skill-activation-prompt.ts` — UserPromptSubmit (스킬 제안)
- `~/.claude/hooks/post-tool-use-tracker.sh` — PostToolUse (파일 편집 추적)

**All Skills:**
- `.claude/skills/*/SKILL.md` - Skill content files

---

**Skill Status**: COMPLETE - Restructured following Anthropic best practices ✅
**Line Count**: < 500 (following 500-line rule) ✅
**Progressive Disclosure**: Reference files for detailed information ✅

**Next**: Create more skills, refine patterns based on usage
