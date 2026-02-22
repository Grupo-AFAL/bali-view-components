#!/bin/bash
# Stop hook: reminds the agent to write a session summary before exiting.
# Fires at exactly the right moment — when the agent is about to stop.
SESSIONS_DIR=".ai-sessions"
TIMESTAMP=$(date +%Y-%m-%d-%H%M)

mkdir -p "$SESSIONS_DIR"

echo "SESSION MEMORY: Before finishing, write your session summary to $SESSIONS_DIR/$TIMESTAMP.md AND copy the same content to $SESSIONS_DIR/latest.md. Include: what was accomplished, what remains, key decisions, and any blockers."
