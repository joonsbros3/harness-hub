#!/bin/bash
# harness-hub/bin/check-skills.sh
# 도메인 스킬의 SKILL.md가 참조하는 knowledge 파일 존재 여부 확인
#
# 사용:
#   bash bin/check-skills.sh                     # 기본: ~/.claude/skills
#   bash bin/check-skills.sh /path/to/skills     # 커스텀 경로
#   bash bin/check-skills.sh --bootstrap         # 누락 파일 빈 템플릿 생성

set -e

SKILLS_DIR="${1:-$HOME/.claude/skills}"
BOOTSTRAP=false
missing_count=0
checked_count=0
created_count=0

# --bootstrap 플래그 처리
for arg in "$@"; do
  if [[ "$arg" == "--bootstrap" ]]; then
    BOOTSTRAP=true
    # SKILLS_DIR이 --bootstrap이면 기본값으로
    if [[ "$SKILLS_DIR" == "--bootstrap" ]]; then
      SKILLS_DIR="$HOME/.claude/skills"
    fi
  fi
done

echo ""
echo "🔍 스킬 knowledge 파일 health check"
echo "   스킬 디렉토리: $SKILLS_DIR"
if [[ "$BOOTSTRAP" == true ]]; then
  echo "   모드: bootstrap (누락 파일 자동 생성)"
fi
echo ""

for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
  [ -f "$skill_md" ] || continue
  skill_dir="$(dirname "$skill_md")"
  skill_name="$(basename "$skill_dir")"

  # SKILL.md에서 참조되는 .md 파일명 추출 (backtick 안의 *.md 패턴)
  referenced_files=$(grep -oE '`[a-zA-Z0-9_-]+\.md`' "$skill_md" 2>/dev/null | tr -d '`' | sort -u)

  [ -z "$referenced_files" ] && continue

  skill_missing=0
  missing_list=""

  while IFS= read -r ref_file; do
    # SKILL.md 자체는 건너뜀
    [ "$ref_file" = "SKILL.md" ] && continue
    checked_count=$((checked_count + 1))

    if [ ! -f "$skill_dir/$ref_file" ]; then
      skill_missing=$((skill_missing + 1))
      missing_count=$((missing_count + 1))

      if [[ "$BOOTSTRAP" == true ]]; then
        # 빈 템플릿 생성
        cat > "$skill_dir/$ref_file" << TMPL
# ${ref_file%.md}

> TODO: ${skill_name} 스킬의 knowledge 파일. 내용을 채워주세요.
> 참조: ${skill_name}/SKILL.md 태스크-지식 매핑 테이블
TMPL
        created_count=$((created_count + 1))
        missing_list="$missing_list    ✚ $ref_file (템플릿 생성됨)\n"
      else
        missing_list="$missing_list    ✗ $ref_file\n"
      fi
    fi
  done <<< "$referenced_files"

  if [ "$skill_missing" -gt 0 ]; then
    echo "⚠️  $skill_name — $skill_missing개 파일 누락:"
    printf "$missing_list"
  else
    echo "✅ $skill_name — 참조 파일 모두 존재"
  fi
done

echo ""
if [[ "$BOOTSTRAP" == true ]] && [ "$created_count" -gt 0 ]; then
  echo "결과: $checked_count개 확인, $created_count개 템플릿 생성됨"
  echo "  → 생성된 파일에 도메인 knowledge를 채워주세요."
elif [ "$missing_count" -gt 0 ]; then
  echo "결과: $checked_count개 확인, $missing_count개 누락"
  echo "  → bash bin/check-skills.sh --bootstrap 으로 빈 템플릿을 생성할 수 있습니다."
else
  echo "결과: $checked_count개 확인, 모두 정상 ✅"
fi
echo ""
