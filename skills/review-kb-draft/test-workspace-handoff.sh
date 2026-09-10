#!/usr/bin/env bash
set -euo pipefail

SKILL_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/SKILL.md"

grep -Fq 'workspaceUrl' "$SKILL_FILE"
grep -Fq '## Codex Workspace handoff' "$SKILL_FILE"
grep -Fq 'open_in_codex' "$SKILL_FILE"
grep -Fq 'When `open_in_codex` is available' "$SKILL_FILE"
grep -Fq '## Claude fallback' "$SKILL_FILE"
grep -Fq 'full or expandable Draft' "$SKILL_FILE"

echo 'review draft workspace handoff contract verified'
