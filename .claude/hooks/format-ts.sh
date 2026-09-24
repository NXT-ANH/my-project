#!/usr/bin/env bash
# PostToolUse (Write|Edit): format and lint TypeScript written inside backend/ or frontend/.
#
# Each submodule carries its own prettier/eslint, so the file's own submodule
# root is resolved first and the tools are run from there via the local bin.
# Never blocks: every failure path exits 0. Unfixable lint errors are reported
# back to the model as additionalContext instead.
set -uo pipefail

payload=$(cat)
file=$(printf '%s' "$payload" | jq -r '.tool_response.filePath // .tool_input.file_path // empty')

[ -n "$file" ] || exit 0
case "$file" in
  *.ts | *.tsx) ;;
  *) exit 0 ;;
esac

proj="${CLAUDE_PROJECT_DIR:-$PWD}"
case "$file" in
  "$proj"/backend/*)  root="$proj/backend" ;;
  "$proj"/frontend/*) root="$proj/frontend" ;;
  *) exit 0 ;;
esac

# node_modules must be installed for the local bin to resolve.
[ -d "$root/node_modules" ] || exit 0

rel="${file#"$root"/}"
cd "$root" || exit 0

npx --no-install prettier --write "$rel" >/dev/null 2>&1

if ! lint_out=$(npx --no-install eslint --fix "$rel" 2>&1); then
  jq -n --arg ctx "ESLint still reports problems in $rel after --fix:"$'\n'"$lint_out" \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
fi

exit 0
