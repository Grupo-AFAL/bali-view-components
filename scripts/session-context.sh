#!/bin/bash
#
# Session Context Hook for Claude Code
# Outputs migration progress summary at session start
#

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATUS_FILE="$REPO_ROOT/MIGRATION_STATUS.md"

# Count components in verification matrix (lines starting with "| " followed by capital letter)
total=$(grep -E "^\| [A-Z]" "$STATUS_FILE" 2>/dev/null | wc -l | tr -d ' ')

# Count fully verified (all 4 checkmarks in Tests, AI Visual, DaisyUI, Manual columns)
verified=$(grep -E "^\| [A-Z].*\|.*✅.*\|.*✅.*\|.*✅.*\|.*✅" "$STATUS_FILE" 2>/dev/null | wc -l | tr -d ' ')

# Count quality-scored components (have X/10 in the Quality column)
quality_scored=$(grep -E "[0-9]+/10" "$STATUS_FILE" 2>/dev/null | wc -l | tr -d ' ')

# Get current branch
branch=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo "unknown")

# Count pending changes
pending=$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

echo "Bali Migration: $verified/$total verified, $quality_scored quality-scored | Branch: $branch | Pending: $pending files"
