#!/bin/bash
set -e

cd ~/.claude/hooks
cat | npx tsx skill-activation-prompt.ts
