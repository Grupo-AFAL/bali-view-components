# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Project Overview

bali-view-components — TODO: describe what this project does.

## Session Memory

This project uses `.ai-sessions/` for session continuity between Docker sandbox runs.

**How it works:**
- **SessionStart hook** (`bin/hooks/session-memory-load.sh`): Automatically injects `.ai-sessions/latest.md` into every new session
- **Stop hook** (`bin/hooks/session-memory-save.sh`): Reminds you to write a session summary before exiting

**When ending a session**, write a summary to `.ai-sessions/<timestamp>.md` and copy it to `.ai-sessions/latest.md`. Include:
- What was accomplished
- What remains to be done
- Key decisions made
- Any blockers or issues
