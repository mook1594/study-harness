#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

echo "=== Study Harness 설치 ==="

# Claude Code 설치 확인
if ! command -v claude >/dev/null 2>&1; then
  echo "[오류] Claude Code가 설치되어 있지 않습니다."
  echo "  https://claude.ai/download 에서 설치 후 다시 실행하세요."
  exit 1
fi

# jq 확인
if ! command -v jq >/dev/null 2>&1; then
  echo "[오류] jq가 필요합니다."
  echo "  Mac: brew install jq"
  exit 1
fi

# 디렉토리 생성
mkdir -p "$CLAUDE_DIR/hooks/pre-tool-use"
mkdir -p "$CLAUDE_DIR/hooks/post-tool-use"

# CLAUDE.md 설치 (글로벌)
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  echo "[스킵] ~/.claude/CLAUDE.md 이미 존재 (덮어쓰지 않음)"
else
  cp "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  echo "[완료] ~/.claude/CLAUDE.md 설치"
fi

# Hook 스크립트 설치
cp "$SCRIPT_DIR/hooks/pre-tool-use/git_guard.py" "$CLAUDE_DIR/hooks/pre-tool-use/git_guard.py"
chmod +x "$CLAUDE_DIR/hooks/pre-tool-use/git_guard.py"
echo "[완료] git_guard.py 설치"

cp "$SCRIPT_DIR/hooks/post-tool-use/edit_lint_test.sh" "$CLAUDE_DIR/hooks/post-tool-use/edit_lint_test.sh"
chmod +x "$CLAUDE_DIR/hooks/post-tool-use/edit_lint_test.sh"
echo "[완료] edit_lint_test.sh 설치"

# settings.json에 hooks 등록
# 없으면 빈 구조로 생성
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

HARNESS_PRE_BASH='{"matcher":"Bash","hooks":[{"type":"command","command":"'"$CLAUDE_DIR"'/hooks/pre-tool-use/git_guard.py","timeout":10}]}'
HARNESS_POST_EDIT='{"matcher":"Write|Edit","hooks":[{"type":"command","command":"'"$CLAUDE_DIR"'/hooks/post-tool-use/edit_lint_test.sh","timeout":300}]}'

# 기존 PreToolUse/PostToolUse 배열에 추가 (중복 방지: git_guard 없을 때만)
ALREADY_PRE=$(jq '[.hooks.PreToolUse[]?.hooks[]?.command // ""] | map(select(contains("git_guard"))) | length' "$SETTINGS" 2>/dev/null || echo 0)
ALREADY_POST=$(jq '[.hooks.PostToolUse[]?.hooks[]?.command // ""] | map(select(contains("edit_lint_test"))) | length' "$SETTINGS" 2>/dev/null || echo 0)

if [ "$ALREADY_PRE" = "0" ]; then
  TMP=$(jq --argjson h "$HARNESS_PRE_BASH" '.hooks.PreToolUse = (.hooks.PreToolUse // []) + [$h]' "$SETTINGS")
  echo "$TMP" > "$SETTINGS"
  echo "[완료] settings.json: PreToolUse(Bash → git_guard) 등록"
else
  echo "[스킵] settings.json: git_guard 이미 등록됨"
fi

if [ "$ALREADY_POST" = "0" ]; then
  TMP=$(jq --argjson h "$HARNESS_POST_EDIT" '.hooks.PostToolUse = (.hooks.PostToolUse // []) + [$h]' "$SETTINGS")
  echo "$TMP" > "$SETTINGS"
  echo "[완료] settings.json: PostToolUse(Write|Edit → edit_lint_test) 등록"
else
  echo "[스킵] settings.json: edit_lint_test 이미 등록됨"
fi

# Skills 설치 (슬래시 커맨드)
mkdir -p "$CLAUDE_DIR/skills"
for skill in plan review commit; do
  SRC="$SCRIPT_DIR/skills/$skill"
  DEST="$CLAUDE_DIR/skills/$skill"
  if [ -d "$SRC" ]; then
    mkdir -p "$DEST"
    cp "$SRC/SKILL.md" "$DEST/SKILL.md"
    echo "[완료] /$skill 스킬 설치"
  fi
done

echo ""
echo "=== 설치 완료 ==="
echo "Claude Code를 재시작하면 하네스가 적용됩니다."
echo ""
echo "적용 내용:"
echo "  - TDD 개발 가이드 (CLAUDE.md)"
echo "  - main 브랜치 커밋 차단 (PreToolUse Bash → git_guard.py)"
echo "  - C#/.NET 자동 빌드/테스트 (PostToolUse Write|Edit → edit_lint_test.sh)"
echo "  - /plan  : TDD 구현 계획 작성"
echo "  - /review: 코드 리뷰"
echo "  - /commit: 커밋 메시지 생성 및 커밋"
