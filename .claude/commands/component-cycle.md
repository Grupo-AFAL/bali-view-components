# Component Cycle

Automated review→fix→review loop for Bali ViewComponents until all issues are resolved.

## Usage

```
/component-cycle $ARGUMENTS
```

Where `$ARGUMENTS` is:
- Component name (e.g., `Columns`, `Modal`, `Dropdown`)
- `--max-iterations:N` - Maximum fix attempts (default: 3)
- `--auto-commit` - Commit after successful cycle
- `--strict` - Fail on any warning, not just errors

## CRITICAL: Migration Log (MUST DO)

**At the START of every cycle**, read the migration log to understand context:
```bash
cat .claude/migration-log.md
```

**At the END of every cycle**, append an entry to the log:
```bash
# Use the Write tool to append to .claude/migration-log.md
```

### Log Entry Format (append after each cycle):

```markdown
---

## [ComponentName] - [YYYY-MM-DD HH:MM]

**Status**: SUCCESS | PARTIAL | BLOCKED
**Iterations**: X of N
**UX Score**: X/10

### Issues Found
- [Severity] Issue description

### Fixes Applied
- Description of fix
- Files modified: `path/to/file.rb`

### Class Mappings
| Old (Bulma) | New (Tailwind) |
|-------------|----------------|
| `old-class` | `new-class` |

### Tests
- Added/Modified: X tests
- Status: All passing / X failures

### Remaining Issues (if any)
- Issue that couldn't be fixed

### Commit
`[hash]` Commit message (or "Not committed")

### Next Steps
- Recommendation for follow-up work
```

**WHY THIS MATTERS**: The log provides:
1. Context for future AI sessions about what's been done
2. Patterns that worked (reusable for similar components)
3. Track record of migration progress
4. Quick reference for class mappings

## Overview

This command orchestrates a complete component improvement cycle:

```
┌─────────────────┐
│  1. VERIFY      │ ─── Run /verify-component
└────────┬────────┘
         │
         ▼
    ┌─────────┐
    │ Issues? │
    └────┬────┘
         │
    Yes  │  No
    ▼    │   ▼
┌────────┴───────┐    ┌─────────────┐
│   2. FIX       │    │   DONE!     │
│ Run /fix-comp  │    │  All clear  │
└────────┬───────┘    └─────────────┘
         │
         ▼
┌─────────────────┐
│  3. RE-VERIFY   │
└────────┬────────┘
         │
         ▼
    ┌─────────┐
    │ Issues? │──── Yes ──► Loop (max N times)
    └────┬────┘
         │ No
         ▼
┌─────────────────┐
│  4. UX REVIEW   │ ─── Delegate to frontend-ui-ux-engineer
└────────┬────────┘
         │
         ▼
    ┌─────────┐
    │ Issues? │──── Yes ──► Loop (max N times)
    └────┬────┘
         │ No
         ▼
┌─────────────────┐
│  5. COMPLETE    │
└─────────────────┘
```

## Workflow

### Phase 1: Initial Verification

Run comprehensive verification:

```
/verify-component [ComponentName]
```

Capture:
- DaisyUI compliance status
- Visual issues
- JS functionality status
- Test coverage
- UX score

### Phase 2: Fix Loop

For each iteration (max N):

1. **Analyze Issues** - Prioritize by severity:
   - Critical: Broken functionality, dead classes
   - High: Missing DaisyUI patterns, JS bugs
   - Medium: Missing tests, preview issues
   - Low: Polish, minor UX improvements

2. **Apply Fixes** - Use `/fix-component` patterns:
   - Map Bulma → Tailwind classes
   - Add missing DaisyUI classes
   - Fix Stimulus controllers
   - Generate missing tests
   - Update preview examples

3. **Verify Fixes** - Quick verification:
   - Run `lsp_diagnostics`
   - Run component tests
   - Check Lookbook renders

4. **Check Exit Conditions**:
   - All critical/high issues resolved → Continue to UX review
   - Issues remain → Loop again (if under max iterations)
   - Max iterations reached → Report remaining issues

### Phase 3: UX Review Loop

After functional issues are resolved:

1. **Delegate to frontend-ui-ux-engineer**:

```
## TASK
Final UX review of [ComponentName] after functional fixes.

## CONTEXT
- Component: Bali::[ComponentName]::Component
- Lookbook URL: http://localhost:3001/lookbook/inspect/bali/[name]/default
- Functional issues have been fixed
- This is iteration X of UX review

## EXPECTED OUTCOME
1. Visual consistency score (1-10)
2. Remaining visual issues (if any)
3. Specific CSS fixes needed
4. PASS/FAIL verdict

## MUST DO
- Open Lookbook and check ALL preview variants
- Test hover, focus, active states
- Check responsive behavior
- Verify accessibility (contrast, focus visibility)

## MUST NOT DO
- Do not break functional code
- Do not add unnecessary complexity

## REQUIRED TOOLS
- skill_mcp (Playwright) for browser automation

## PLAYWRIGHT CALL FORMAT (CRITICAL)
When using skill_mcp for Playwright, arguments MUST be a JSON string:

CORRECT:
skill_mcp(mcp_name="playwright", tool_name="browser_navigate", arguments='{"url": "http://localhost:3001/lookbook/inspect/bali/[component]/default"}')
skill_mcp(mcp_name="playwright", tool_name="browser_snapshot", arguments='{}')

WRONG (will cause parse error):
skill_mcp(mcp_name="playwright", tool_name="browser_navigate", arguments={"url": "..."})
```

2. **Apply UX Fixes** (if any):
   - Delegate visual changes to frontend-ui-ux-engineer
   - Or apply simple Tailwind class adjustments

3. **Re-verify UX**:
   - Score must be ≥ 7/10 to pass
   - Or no critical visual issues

### Phase 4: Completion

When all checks pass:

1. **Run Final Verification**:
   ```bash
   bundle exec rspec spec/components/bali/[name]/
   ```

2. **Generate Cycle Report**

3. **Optional Auto-Commit** (if `--auto-commit`):
   ```bash
   git add app/components/bali/[name]/ spec/components/bali/[name]/
   git commit -m "Fix [ComponentName] - complete Tailwind/DaisyUI migration

   - Map Bulma classes to Tailwind equivalents
   - Add proper DaisyUI semantic classes
   - Update preview examples
   - Add/update component tests
   - UX review passed (score: X/10)"
   ```

## Exit Conditions

| Condition | Action |
|-----------|--------|
| All issues resolved, UX score ≥ 7 | **SUCCESS** - Complete |
| Max iterations reached | **PARTIAL** - Report remaining issues |
| Critical issue cannot be fixed | **BLOCKED** - Escalate to user |
| Tests fail after fix | **ROLLBACK** - Revert last change, try different approach |

## Cycle Report Format

```markdown
# Component Cycle Report: [ComponentName]

## Summary
| Metric | Value |
|--------|-------|
| Status | SUCCESS / PARTIAL / BLOCKED |
| Iterations | X of N |
| Start Time | [timestamp] |
| End Time | [timestamp] |
| Duration | Xm Ys |

## Iteration Log

### Iteration 1
**Issues Found**: 5
- [Critical] Dead Bulma classes in preview
- [High] Missing SIZES constant
- [Medium] No tests
- [Medium] Preview uses wrong API
- [Low] Box styling missing

**Fixes Applied**:
- Added SIZES/OFFSETS constants to Column component
- Updated preview to use size: param
- Generated component_spec.rb with 8 test cases

**Verification**: 3 issues remain

---

### Iteration 2
**Issues Found**: 2
- [Medium] Preview box class unstyled
- [Low] Missing hover state on items

**Fixes Applied**:
- Replaced `box` with `bg-base-200 p-4 rounded-lg`
- Added `hover:bg-base-300` to interactive elements

**Verification**: All functional issues resolved

---

### UX Review
**Score**: 8/10
**Verdict**: PASS

**Positive**:
- Clean DaisyUI implementation
- Proper responsive behavior
- Good contrast and readability

**Minor Notes**:
- Consider adding transition for smoother hover

---

## Final State

### Files Changed
| File | Status |
|------|--------|
| app/components/bali/columns/column/component.rb | Modified |
| app/components/bali/columns/preview.rb | Modified |
| spec/components/bali/columns/component_spec.rb | Created |

### Tests
- Total: 8
- Passing: 8
- Coverage: 100%

### Verification
- [x] LSP diagnostics clean
- [x] All tests passing
- [x] Lookbook renders correctly
- [x] UX score ≥ 7/10

## Commit (if --auto-commit)
```
[commit hash] Fix Columns - complete Tailwind/DaisyUI migration
```
```

## Example Execution

```
User: /component-cycle Columns --max-iterations:3

AI: Starting component improvement cycle for Bali::Columns::Component...

═══════════════════════════════════════════════════════════════
                     ITERATION 1 OF 3
═══════════════════════════════════════════════════════════════

## Phase 1: Verification

Running /verify-component Columns...

### Issues Found (5)
| # | Severity | Issue |
|---|----------|-------|
| 1 | Critical | Dead Bulma classes: is-half, is-narrow, is-offset-* |
| 2 | High | No size/offset params in Column component |
| 3 | Medium | No tests exist |
| 4 | Medium | Preview uses Bulma API |
| 5 | Low | `box` class unstyled |

## Phase 2: Applying Fixes

### Fix 1: Add size/offset mappings to Column component
[Shows code changes]

### Fix 2: Update preview to use new API
[Shows code changes]

### Fix 3: Generate component tests
[Shows new test file]

## Phase 3: Re-verification

Running quick verification...

- LSP Diagnostics: ✓ Clean
- Tests: ✓ 8/8 passing
- Lookbook: ✓ Renders

### Remaining Issues (1)
| # | Severity | Issue |
|---|----------|-------|
| 1 | Low | `box` class still unstyled in preview content |

═══════════════════════════════════════════════════════════════
                     ITERATION 2 OF 3
═══════════════════════════════════════════════════════════════

## Phase 2: Applying Fix

### Fix: Replace `box` with Tailwind classes
```ruby
# Before
c.tag.div(class: 'box') { ... }

# After  
c.tag.div(class: 'bg-base-200 p-4 rounded-lg') { ... }
```

## Phase 3: Re-verification

- LSP Diagnostics: ✓ Clean
- Tests: ✓ 8/8 passing
- Lookbook: ✓ Renders correctly

### Issues: 0 remaining

═══════════════════════════════════════════════════════════════
                     UX REVIEW PHASE
═══════════════════════════════════════════════════════════════

Delegating to frontend-ui-ux-engineer...

### UX Assessment

**Score: 8/10** ✓ PASS

**Observations**:
- Clean grid layout with proper spacing
- Columns resize correctly with size params
- Good visual hierarchy

**Minor Suggestions** (non-blocking):
- Add subtle transition on hover states

═══════════════════════════════════════════════════════════════
                     CYCLE COMPLETE
═══════════════════════════════════════════════════════════════

## Summary
| Metric | Value |
|--------|-------|
| Status | ✅ SUCCESS |
| Iterations | 2 of 3 |
| Issues Fixed | 5 |
| Final UX Score | 8/10 |
| Tests | 8/8 passing |

## Files Changed
- app/components/bali/columns/column/component.rb (modified)
- app/components/bali/columns/preview.rb (modified)
- spec/components/bali/columns/component_spec.rb (created)

Ready to commit? Use --auto-commit or run:
git add app/components/bali/columns/ spec/components/bali/columns/
git commit -m "Fix Columns - complete Tailwind/DaisyUI migration"
```

## Troubleshooting

### Cycle gets stuck
If the same issue keeps appearing:
1. Check if the fix is actually being applied
2. Try a different fix approach
3. Escalate to user for guidance

### UX review keeps failing
If UX score stays below 7:
1. Focus on critical visual issues only
2. Accept "good enough" for non-critical items
3. Create follow-up task for polish

### Tests fail after fix
1. Rollback the change
2. Analyze why tests fail
3. Fix tests or fix approach
4. Never delete tests to pass

### Max iterations reached
1. Report partial completion
2. List remaining issues
3. Let user decide next steps
