#!/bin/zsh
# harness-hub/bin/install.sh
# harness-hub → ~/.claude/ 심볼릭 링크 설치
# 재실행해도 안전 (idempotent)

set -e

HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

# ─────────────────────────────────────────────────────────────
# 헬퍼 함수
# ─────────────────────────────────────────────────────────────
link_item() {
  local name="$1"
  local src="$HARNESS_DIR/$name"
  local dst="$CLAUDE_DIR/$name"

  if [[ ! -e "$src" ]]; then
    return
  fi

  if [[ -L "$dst" ]]; then
    local current_target
    current_target="$(readlink "$dst")"
    if [[ "$current_target" == "$src" ]]; then
      echo "  ✓ $name (이미 연결됨)"
    else
      echo "  ↺ $name (다른 링크 대체: $current_target → $src)"
      ln -sf "$src" "$dst"
    fi
  elif [[ -e "$dst" ]]; then
    echo "  ⚠ $name 이미 존재 → $dst.bak 으로 백업 후 링크"
    mv "$dst" "${dst}.bak"
    ln -s "$src" "$dst"
  else
    ln -s "$src" "$dst"
    echo "  ✓ $name 연결됨"
  fi
}

# ─────────────────────────────────────────────────────────────
# 설치
# ─────────────────────────────────────────────────────────────
echo ""
echo "harness-hub 설치"
echo "  소스: $HARNESS_DIR"
echo "  대상: $CLAUDE_DIR"
echo ""

# ~/.claude 디렉토리가 없으면 생성 (깨끗한 환경 대응)
mkdir -p "$CLAUDE_DIR"

# 디렉토리
for dir in agents skills hooks commands; do
  link_item "$dir"
done

# 파일 (CLAUDE.md는 글로벌 지침으로 ~/.claude/CLAUDE.md에 설치됨)
for file in settings.json keybindings.json CLAUDE.md; do
  link_item "$file"
done

echo ""
echo "완료. 확인:"
echo "  ls -la $CLAUDE_DIR/agents $CLAUDE_DIR/skills"
echo ""
