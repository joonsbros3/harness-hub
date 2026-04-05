#!/bin/bash
# skill-activation-prompt hook wrapper
# 실패 시 조용히 종료 (훅 실패가 Claude 세션을 막으면 안 됨)
cd ~/.claude/hooks 2>/dev/null || exit 0
cat | npx tsx skill-activation-prompt.ts 2>/dev/null || exit 0
