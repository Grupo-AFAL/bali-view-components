# Review All Components

Autonomous batch review of multiple Bali ViewComponents in parallel.

## Usage

```
/review-all $ARGUMENTS
```

Where `$ARGUMENTS` is:
- No arguments - Review ALL components
- Component names - Review specific components (e.g., `Button Modal Card`)
- `--parallel:N` - Number of parallel reviews (default: 6)
- `--list` - List components and their review status
- `--pending` - Only review components that haven't been reviewed yet
- `--failed` - Only retry components that failed previous review

## Overview

This command orchestrates parallel autonomous review cycles:

```
┌─────────────────────────────────────────────────────────────┐
│                    REVIEW ALL ORCHESTRATOR                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Component 1 ──► /review-cycle ──► Result                 │
│   Component 2 ──► /review-cycle ──► Result     (parallel)  │
│   Component 3 ──► /review-cycle ──► Result                 │
│   ...                                                       │
│                                                             │
│   ┌─────────────┐                                          │
│   │  Aggregate  │ ──► Summary Report                       │
│   │   Results   │ ──► Update MIGRATION_STATUS.md           │
│   └─────────────┘                                          │
└─────────────────────────────────────────────────────────────┘
```

## Workflow

### Phase 1: Discovery

1. **List components** from `app/components/bali/`:
   ```bash
   ls -1 app/components/bali/ | grep -v application
   ```

2. **Filter by status** (if `--pending` or `--failed`):
   - Read `.claude/review-results/*.json` for previous results
   - Skip components with `status: SUCCESS` and `score >= 9`

3. **Display plan**:
   ```
   Found 40 components
   Already reviewed (score ≥ 9): 15
   Pending review: 25

   Will review: 25 components
   Parallel: 6
   Estimated batches: 5
   ```

### Phase 2: Parallel Execution

For each batch of N components:

1. **Launch background agents** using Task tool:
   ```
   Task(subagent_type: "general-purpose", run_in_background: true)
   Prompt: "/review-cycle [ComponentName]"
   ```

2. **Monitor progress**:
   - Check output files periodically
   - Report completions as they happen
   - Track failures for retry

3. **Collect results**:
   - Parse final scores and status
   - Save to `.claude/review-results/[name].json`

### Phase 3: Aggregation

After all reviews complete:

1. **Generate summary report**:
   ```markdown
   # Batch Review Summary

   | Component | Score | Status | Issues Fixed |
   |-----------|-------|--------|--------------|
   | Button    | 9/10  | ✅     | 3            |
   | Modal     | 8/10  | ⚠️     | 5            |
   | Card      | 9/10  | ✅     | 2            |

   Total: 25 reviewed
   Passed (≥9): 20
   Partial (7-8): 4
   Blocked (<7): 1
   ```

2. **Update MIGRATION_STATUS.md** with review results

3. **Create PR** (optional) with all changes

## Execution Modes

### Mode 1: In-Session (Interactive)

Run from Claude Code session - uses background Task agents:

```
/review-all Button Modal Card Dropdown
```

- Runs up to 6 parallel background agents
- Shows progress in real-time
- Best for smaller batches (< 20 components)

### Mode 2: Shell Script (Headless)

Run from terminal - uses git worktrees + headless Claude:

```bash
./scripts/batch-review.sh --parallel 6
```

- True parallel isolation with worktrees
- Can handle all 40+ components
- Best for overnight batch processing
- Results saved to `.claude/review-results/`

### Mode 3: Hybrid

Start batch from Claude, let it run in background:

```
/review-all --pending --background
```

## Progress Tracking

Results are saved to `.claude/review-results/[component].json`:

```json
{
  "component": "Button",
  "reviewed_at": "2025-01-16T10:30:00Z",
  "status": "SUCCESS",
  "score": 9,
  "iterations": 2,
  "issues_fixed": 4,
  "commit": "abc1234",
  "files_changed": [
    "app/components/bali/button/component.rb",
    "spec/bali/components/button_spec.rb"
  ]
}
```

Logs are saved to `.claude/review-logs/[component].log`.

## Example Execution

```
User: /review-all --pending --parallel:6

AI: Discovering components to review...

## Discovery

| Status | Count |
|--------|-------|
| Total components | 42 |
| Already passing (≥9) | 12 |
| Need review | 30 |

## Execution Plan

Will review 30 components in 5 batches of 6.

Starting batch 1/5: Button, Modal, Card, Dropdown, Tabs, Table

═══════════════════════════════════════════════════════════════
                     BATCH 1 OF 5
═══════════════════════════════════════════════════════════════

Launching 6 parallel review agents...

[1/6] Button ──► Started (agent_abc123)
[2/6] Modal ──► Started (agent_def456)
[3/6] Card ──► Started (agent_ghi789)
[4/6] Dropdown ──► Started (agent_jkl012)
[5/6] Tabs ──► Started (agent_mno345)
[6/6] Table ──► Started (agent_pqr678)

Progress:
✓ Button: Score 9/10 - SUCCESS (2 iterations)
✓ Card: Score 9/10 - SUCCESS (1 iteration)
⚠ Modal: Score 8/10 - PARTIAL (3 iterations)
✓ Dropdown: Score 9/10 - SUCCESS (2 iterations)
✓ Tabs: Score 10/10 - SUCCESS (1 iteration)
✓ Table: Score 9/10 - SUCCESS (3 iterations)

Batch 1 complete: 5 passed, 1 partial

═══════════════════════════════════════════════════════════════
                     BATCH 2 OF 5
═══════════════════════════════════════════════════════════════

[... continues ...]

═══════════════════════════════════════════════════════════════
                     FINAL SUMMARY
═══════════════════════════════════════════════════════════════

## Results

| Status | Count | Components |
|--------|-------|------------|
| ✅ SUCCESS (≥9) | 26 | Button, Card, Dropdown, ... |
| ⚠️ PARTIAL (7-8) | 3 | Modal, Stepper, Timeline |
| ❌ BLOCKED (<7) | 1 | GanttChart |

## Statistics

- Total reviewed: 30
- Pass rate: 87%
- Average score: 8.7/10
- Total issues fixed: 89
- Total commits: 26

## Files Updated

- MIGRATION_STATUS.md - Updated review status
- 26 commits pushed to origin/tailwind-migration

## Next Steps

Components needing attention:
1. Modal (8/10) - Missing accessibility tests
2. Stepper (7/10) - Template logic could be cleaner
3. Timeline (8/10) - Could use more test coverage
4. GanttChart (5/10) - Needs significant refactoring

Run `/review-cycle [component]` on these for focused attention.
```

## Shell Script Usage

For maximum parallelism and overnight runs:

```bash
# Review all components
./scripts/batch-review.sh

# Review specific components
./scripts/batch-review.sh Button Modal Card

# Adjust parallelism
./scripts/batch-review.sh --parallel 8

# Dry run (see what would happen)
./scripts/batch-review.sh --dry-run

# Keep worktrees for debugging
./scripts/batch-review.sh --skip-cleanup

# List available components
./scripts/batch-review.sh --list
```

## Troubleshooting

### Agent times out
- Reduce `--parallel` to give each agent more resources
- Check `.claude/review-logs/[component].log` for errors

### File conflicts
- Shell script uses worktrees to avoid this
- In-session mode: ensure no uncommitted changes

### Permission prompts
Add missing permissions to `.claude/settings.local.json`. Required permissions:

```json
{
  "permissions": {
    "allow": [
      "Skill(review-cycle)",
      "Skill(review)",
      "Skill(review-all)",
      "Bash(bundle exec rspec:*)",
      "Bash(bundle exec rubocop:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(git push:*)",
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git worktree:*)",
      "Bash(jq:*)",
      "Bash(mkdir -p /tmp/:*)",
      "Bash(mkdir -p /path/to/bali/:*)",
      "Bash(rm -f /tmp/:*)",
      "Bash(rm -f /path/to/bali/:*)",
      "Bash(rmdir /tmp/:*)",
      "Bash(sed -i.bak:*)",
      "Bash(cat:*)",
      "Bash(ruby -e:*)",
      "Bash(./scripts/:*)"
    ]
  }
}
```

**Note**: Scope `mkdir` and `rm` permissions to `/tmp/` and your project directory only.

### Memory issues
- Reduce `--parallel` count
- Close other applications
- Use shell script mode (separate processes)
