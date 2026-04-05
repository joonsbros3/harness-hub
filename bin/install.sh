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
# 사전 확인
# ─────────────────────────────────────────────────────────────
echo ""
echo "harness-hub 설치"
echo "  소스: $HARNESS_DIR"
echo "  대상: $CLAUDE_DIR"
echo ""

# 필수 의존성 확인
if ! command -v node &>/dev/null; then
  echo "  ⚠ Node.js가 설치되지 않았습니다"
  echo "    skill-activation-prompt 훅에 필요합니다"
  echo "    brew install node 또는 https://nodejs.org 에서 설치하세요"
  echo ""
fi

if ! command -v jq &>/dev/null; then
  echo "  ⚠ jq가 설치되지 않았습니다"
  echo "    post-tool-use-tracker 훅에 필요합니다"
  echo "    brew install jq 로 설치하세요"
  echo ""
fi

# ─────────────────────────────────────────────────────────────
# 설치
# ─────────────────────────────────────────────────────────────

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

# 훅 파일 실행 권한 부여
chmod +x "$HARNESS_DIR"/hooks/*.sh 2>/dev/null || true

# ─────────────────────────────────────────────────────────────
# 설치 후 안내
# ─────────────────────────────────────────────────────────────
echo ""
echo "완료."
echo ""

# 훅 의존성 안내
if [[ -f "$CLAUDE_DIR/hooks/package.json" ]]; then
  if [[ ! -d "$CLAUDE_DIR/hooks/node_modules" ]]; then
    echo "📦 훅 의존성 설치가 필요합니다:"
    echo "  cd $CLAUDE_DIR/hooks && npm install"
    echo ""
  fi
fi

# 스킬 health check
if [[ -f "$HARNESS_DIR/bin/check-skills.sh" ]]; then
  echo "🔍 스킬 상태 확인:"
  bash "$HARNESS_DIR/bin/check-skills.sh" "$CLAUDE_DIR/skills" 2>/dev/null || true
fi

echo "확인:"
echo "  ls -la $CLAUDE_DIR/agents $CLAUDE_DIR/skills"
echo ""
