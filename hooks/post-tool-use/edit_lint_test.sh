#!/usr/bin/env bash
set -euo pipefail

LOG=".claude/.local/hooks.log"
mkdir -p .claude/.local

FILE_PATH="$(cat | jq -r '.tool_input.file_path // empty')"
[ -z "${FILE_PATH}" ] && echo "[edit_lint_test] $(date -u +"%Y-%m-%dT%H:%M:%SZ") skipped (empty)" >> "$LOG" && exit 0

# 예시: Node 프로젝트
if [ -f package.json ]; then
  if command -v npm >/dev/null 2>&1; then
    echo "[edit_lint_test] $(date -u +"%Y-%m-%dT%H:%M:%SZ") running npm lint" >> "$LOG"
    npm run -s lint || exit 2
    # 선택: 변경 파일이 test면 해당만, 아니면 스모크 테스트만
    if [[ "$FILE_PATH" == *test* || "$FILE_PATH" == *.spec.* ]]; then
      echo "[edit_lint_test] $(date -u +"%Y-%m-%dT%H:%M:%SZ") running npm test (test file)" >> "$LOG"
      npm test -s || exit 2
    else
      echo "[edit_lint_test] $(date -u +"%Y-%m-%dT%H:%M:%SZ") running npm test (related tests)" >> "$LOG"
      npm test -s -- --runInBand --findRelatedTests "$FILE_PATH" 2>/dev/null || true
    fi
  fi
fi

# 예시: Go 프로젝트
if [ -f go.mod ]; then
  echo "[edit_lint_test] $(date -u +"%Y-%m-%dT%H:%M:%SZ") running go test" >> "$LOG"
  go test ./... || exit 2
fi

# C#/.NET 프로젝트
if [[ "$FILE_PATH" == *.cs ]]; then
  SLN=$(find . -maxdepth 3 -name "*.sln" 2>/dev/null | head -1)
  CSPROJ=$(find . -maxdepth 4 -name "*.csproj" 2>/dev/null | head -1)
  TARGET="${SLN:-$CSPROJ}"
  if [ -n "$TARGET" ] && command -v dotnet >/dev/null 2>&1; then
    echo "[edit_lint_test] $(date -u +"%Y-%m-%dT%H:%M:%SZ") running dotnet build" >> "$LOG"
    dotnet build "$TARGET" -v q --nologo || exit 2
    echo "[edit_lint_test] $(date -u +"%Y-%m-%dT%H:%M:%SZ") running dotnet test" >> "$LOG"
    dotnet test "$TARGET" -v q --nologo --no-build || exit 2
  fi
fi

echo "[edit_lint_test] $(date -u +"%Y-%m-%dT%H:%M:%SZ") completed" >> "$LOG"
exit 0
