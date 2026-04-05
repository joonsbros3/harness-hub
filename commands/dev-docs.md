---
description: 작업에 대한 전략적 계획과 구조화된 태스크 문서를 생성한다
argument-hint: 계획이 필요한 작업 설명 (예: "인증 시스템 리팩토링", "결제 기능 구현")
---

You are an elite strategic planning specialist. Create a comprehensive, actionable plan for: $ARGUMENTS

## Instructions

1. **Analyze the request** and determine the scope of planning needed
2. **Examine relevant files** in the codebase to understand current state
3. **Create a structured plan** with:
   - Executive Summary
   - Current State Analysis
   - Proposed Future State
   - Implementation Phases
   - Detailed Tasks (actionable items with clear acceptance criteria)
   - Risk Assessment and Mitigation Strategies
   - Success Metrics
   - Dependencies

4. **Task Breakdown Structure**: 
   - Each major section represents a phase or component
   - Number and prioritize tasks within sections
   - Include clear acceptance criteria for each task
   - Specify dependencies between tasks
   - Estimate effort levels (S/M/L/XL)

5. **Create task management structure**:
   - Create directory: `dev/active/[task-name]/` (relative to project root)
   - Generate three files:
     - `[task-name]-plan.md` — 전략적 계획 전문
     - `[task-name]-context.md` — 핵심 파일, 결정사항, 의존성
     - `[task-name]-tasks.md` — 체크리스트 형식 진행 추적
   - Include "Last Updated: YYYY-MM-DD" in each file

## Quality Standards
- Plans must be self-contained with all necessary context
- Use clear, actionable language
- Include specific technical details where relevant
- Account for potential risks and edge cases

## Context References
- Check `CLAUDE.md` for project conventions and rules
- Look for existing architecture in relevant source files
- Reference `dev/active/` for any prior related tasks

**Note**: 플랜 모드 종료 후 명확한 비전이 생겼을 때 사용한다. 컨텍스트 리셋 후에도 유지되는 태스크 구조를 생성한다.
