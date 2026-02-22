#!/bin/bash
# SessionStart hook: injects previous session context into the new session.
# This runs automatically — the agent receives context without needing to remember to read anything.
LATEST=".ai-sessions/latest.md"
if [ -f "$LATEST" ]; then
  echo "## Previous Session Context"
  echo ""
  cat "$LATEST"
  echo ""
  echo "---"
  echo "Use this context to continue where the previous session left off."
fi
