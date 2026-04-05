---
description: 컨텍스트 압축 전 개발 문서를 업데이트한다
argument-hint: 선택사항 — 집중할 특정 컨텍스트나 태스크 (비우면 전체 업데이트)
---

We're approaching context limits. Please update the development documentation to ensure seamless continuation after context reset.

## Required Updates

### 1. Update Active Task Documentation
For each task in `/dev/active/`:
- Update `[task-name]-context.md` with:
  - Current implementation state
  - Key decisions made this session
  - Files modified and why
  - Any blockers or issues discovered
  - Next immediate steps
  - Last Updated timestamp

- Update `[task-name]-tasks.md` with:
  - Mark completed tasks as ✅ 
  - Add any new tasks discovered
  - Update in-progress tasks with current status
  - Reorder priorities if needed

### 2. Capture Session Context
Include any relevant information about:
- Complex problems solved
- Architectural decisions made
- Tricky bugs found and fixed
- Integration points discovered
- Testing approaches used

### 3. Document Unfinished Work
- What was being worked on when context limit approached
- Exact state of any partially completed features
- Commands that need to be run on restart
- Any temporary workarounds that need permanent fixes

### 4. Create Handoff Notes
If switching to a new conversation:
- Exact file and line being edited
- The goal of current changes
- Any uncommitted changes that need attention
- Test commands to verify work

## Additional Context: $ARGUMENTS

**Priority**: 코드에서 재발견하기 어려운 정보 위주로 캡처한다.
