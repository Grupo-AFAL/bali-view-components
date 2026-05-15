# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Project Overview

**Bali** is AFAL's open-source ViewComponent library providing 40+ reusable UI components for Rails applications, styled with Tailwind CSS and DaisyUI.

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

## Codebase Search (SocratiCode)

This repo is indexed by SocratiCode (hybrid semantic + BM25 search, file watcher active). For exploratory questions ("where is X?", "how does Y work?", "find code that does Z"), reach for `codebase_search` **before** `Grep` or speculative `Read` calls — it returns ranked snippets across the whole repo in one tool call.

**Workflow:**
1. `codebase_search` to find relevant code
2. `codebase_graph_query` for imports/dependents on JS/JSX (Ruby is mostly Zeitwerk-autoloaded, so the graph is less useful there)
3. `Read` only after search has narrowed to 1–3 files

**Skip search for:** known file paths (use `Read`), single-file symbol lookups (use `Grep`), edits/writes (search is read-only).

**Cross-project:** pass `includeLinked: true` to search linked projects defined in `.socraticode.json` or `SOCRATICODE_LINKED_PROJECTS`.

## Browser Verification (MANDATORY)

**ALWAYS verify UI/UX changes through the browser before claiming they work.** Curl-testing APIs and passing Ruby tests is NOT sufficient for frontend features.

After making changes to JavaScript, Stimulus controllers, React components, or any user-facing behavior:
1. Start the dummy app (`cd spec/dummy && bin/dev`)
2. Open the relevant page in the browser
3. Manually test the full user flow end-to-end
4. Take screenshots to confirm visual correctness
5. Only then claim the feature works

Backend API tests passing ≠ the feature works in the browser.
