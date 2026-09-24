#!/usr/bin/env bash
# PreToolUse (Write|Edit): refuse to write secret-bearing .env files.
#
# .env.example is the tracked template and stays editable; every other .env*
# variant holds real secrets (JWT signing keys, DATABASE_URL) and must be
# changed by a human, not by an agent.
set -uo pipefail

payload=$(cat)
file=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')
[ -n "$file" ] || exit 0

name=$(basename "$file")

case "$name" in
  .env.example | .env.sample | .env.template) exit 0 ;;
  .env | .env.*)
    jq -n --arg f "$file" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: ($f + " holds real secrets and is blocked by the block-env-edit hook. Edit .env.example instead, or ask the user to change this file themselves.")
      }
    }'
    exit 0
    ;;
esac

exit 0
