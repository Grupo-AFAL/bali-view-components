# Review Cycle

Automated review→fix→review loop for Bali ViewComponents until code quality standards are met.

## Usage

```
/review-cycle $ARGUMENTS
```

Where `$ARGUMENTS` is:
- Component name (e.g., `Button`, `Modal`, `Dropdown`)
- `--max-iterations:N` - Maximum fix attempts (default: 5)
- `--min-score:N` - Minimum score to pass (default: 9)
- `--no-push` - Skip pushing to remote after commit
- `--code-only` - Skip visual verification (for parallel batch processing)

## Modes

### Full Mode (default)
Includes visual verification with Playwright:
- Opens Lookbook in browser
- Takes screenshots of component
- Checks for console errors
- Validates visual appearance

### Code-Only Mode (`--code-only`)
Skips visual verification for faster parallel processing:
- Runs Rubocop and RSpec only
- DHH code review
- No browser/Playwright needed
- Safe for parallel execution

Use code-only mode when:
- Running batch reviews in parallel
- Visual verification will be done later
- You only care about code quality

## Overview

This command orchestrates a complete code quality improvement cycle:

```
┌─────────────────┐
│  1. REVIEW      │ ─── Run /review (Rubocop, RSpec, DHH reviewer)
└────────┬────────┘     Returns score 1-10
         │
         ▼
    ┌───────────┐
    │ Score ≥ 9 │
    └─────┬─────┘
          │
    No    │  Yes
    ▼     │   │
┌─────────┴───────┐    │
│   2. FIX        │    │
│ Apply fixes     │    │
└─────────┬───────┘    │
          │            │
          ▼            │
┌─────────────────┐    │
│  3. RE-REVIEW   │    │
└─────────┬───────┘    │
          │            │
          ▼            │
    ┌───────────┐      │
    │ Score ≥ 9 │──No──► Loop (max N times)
    └─────┬─────┘
          │ Yes
          ▼
┌─────────────────┐
│  4. DOCS CHECK  │ ─── Review if documentation needs updates
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│  5. COMMIT      │ ─── Commit changes with detailed message
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│  6. PUSH        │ ─── Push to remote (unless --no-push)
└─────────────────┘
```

## Workflow

### Phase 1: Initial Review

Run comprehensive code review:

1. **Automated Checks**:
   ```bash
   bundle exec rubocop app/components/bali/[name]/
   bundle exec rspec spec/bali/components/[name]_spec.rb
   ```

2. **DHH Review** - Invoke `dhh-code-reviewer` agent to analyze:
   - Component class design
   - API quality and expressiveness
   - Template cleanliness
   - DaisyUI usage patterns
   - Test coverage

3. **Capture Issues** with severity:
   - **Critical**: Broken functionality, security issues, failing tests
   - **High**: Poor API design, missing constants, Rubocop errors
   - **Medium**: Missing tests, preview issues, code style
   - **Low**: Minor suggestions, polish

### Phase 2: Fix Loop

For each iteration (max N):

1. **Prioritize Issues** - Fix in order:
   - Critical issues first (must fix)
   - High issues second (should fix)
   - Medium issues if time permits
   - Low issues only if explicitly requested

2. **Apply Fixes** by category:

   | Issue Type | Fix Approach |
   |------------|--------------|
   | Rubocop offense | Run `rubocop -a` or manual fix |
   | Failing tests | Fix code (never delete tests) |
   | Missing constants | Add frozen VARIANTS/SIZES hashes |
   | Poor API | Refactor initialize params |
   | Missing `class_names` | Replace string concatenation |
   | Missing tests | Generate test cases |
   | Template logic | Move to helper methods |
   | Raw HTML | Replace with Bali components |

3. **Verify Fixes**:
   ```bash
   bundle exec rubocop app/components/bali/[name]/
   bundle exec rspec spec/bali/components/[name]_spec.rb
   ```

4. **Check Exit Conditions**:
   - All critical/high issues resolved → SUCCESS
   - Issues remain but under max iterations → Loop again
   - Max iterations reached → Report remaining issues

### Phase 3: Update Migration Status

**CRITICAL**: After each review cycle completes, update `MIGRATION_STATUS.md`:

1. **Update the Quality column** in the Component Verification Matrix:
   ```markdown
   | ComponentName |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Notes |
   ```

2. **Update the Quality Score Summary** section with new counts

3. **Add to Change Log** at the bottom:
   ```markdown
   | 2026-01-17 | ComponentName | Quality review: 9/10 | AI |
   ```

### Phase 4: Documentation Review

When score reaches ≥ 9, review documentation needs:

1. **Check if API changed**:
   - New params added? → Update component docs
   - Params removed/renamed? → Update CHANGELOG.md
   - New slots added? → Update preview notes

2. **Review files to potentially update**:
   - `app/components/bali/[name]/preview.rb` - Lookbook notes
   - `CHANGELOG.md` - If breaking changes or new features
   - `docs/reference/component-patterns.md` - If new pattern established

3. **Update documentation** if needed:
   ```ruby
   # In preview.rb - Add/update notes for consumers
   # @label Default
   # [Document any non-obvious behavior, dependencies, or usage examples]
   def default
     # ...
   end
   ```

### Phase 5: Commit and Push

After documentation review:

1. **Stage all changed files**:
   ```bash
   git add app/components/bali/[name]/ spec/bali/components/[name]/
   # Also add any updated docs
   git add CHANGELOG.md docs/ # if modified
   ```

2. **Create detailed commit**:
   ```bash
   git commit -m "Refactor [ComponentName] for code quality

   Changes:
   - [List specific improvements made]
   - [List any API changes]

   Review cycle: X iterations
   Final score: X/10

   Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
   ```

3. **Push to remote** (unless `--no-push`):
   ```bash
   git push origin HEAD
   ```

4. **Generate Cycle Report** (see format below)

## Exit Conditions

| Condition | Action |
|-----------|--------|
| Score ≥ 9, tests pass | **SUCCESS** - Proceed to docs, commit, push |
| Max iterations, score 7-8 | **PARTIAL** - Commit with notes on remaining issues |
| Max iterations, score < 7 | **BLOCKED** - Escalate to user |
| Tests keep failing after fixes | **BLOCKED** - Escalate to user |
| Rubocop can't auto-fix | **BLOCKED** - Escalate to user |

### Hard Gate: Score Requirement

**Score < 9 = Keep iterating. Score < 7 at max iterations = BLOCKED.**

The score reflects overall code quality:
- **9-10**: Excellent - Rails-worthy, follows all conventions
- **7-8**: Good - Minor improvements possible but acceptable
- **5-6**: Needs work - Several issues to address
- **< 5**: Poor - Significant refactoring needed

## Issue Categories and Fixes

### Rubocop Offenses

```bash
# Auto-fix what's possible
bundle exec rubocop app/components/bali/[name]/ -a

# For remaining issues, fix manually based on offense type
```

### Missing Frozen Constants

```ruby
# Before
def variant_class
  case @variant
  when :primary then "btn-primary"
  when :secondary then "btn-secondary"
  end
end

# After
VARIANTS = {
  primary: "btn-primary",
  secondary: "btn-secondary"
}.freeze

def variant_class
  VARIANTS[@variant]
end
```

### String Concatenation → class_names

```ruby
# Before
def button_classes
  classes = ["btn"]
  classes << VARIANTS[@variant] if @variant
  classes << SIZES[@size] if @size
  classes.join(" ")
end

# After
def button_classes
  class_names(
    "btn",
    VARIANTS[@variant],
    SIZES[@size]
  )
end
```

### Template Logic → Helper Methods

```erb
<%# Before %>
<div class="<%= @loading ? 'loading' : '' %> <%= @disabled ? 'disabled' : '' %>">

<%# After - move to component.rb %>
<div class="<%= state_classes %>">
```

```ruby
# In component.rb
private

def state_classes
  class_names(
    "loading" => @loading,
    "disabled" => @disabled
  )
end
```

### Missing Tests

Generate tests for uncovered functionality:

```ruby
RSpec.describe Bali::[Name]::Component, type: :component do
  describe "variants" do
    described_class::VARIANTS.each_key do |variant|
      it "renders #{variant} variant" do
        render_inline(described_class.new(variant: variant))
        expect(page).to have_css(".#{described_class::VARIANTS[variant]}")
      end
    end
  end

  describe "options passthrough" do
    it "accepts custom classes" do
      render_inline(described_class.new(class: "custom"))
      expect(page).to have_css(".custom")
    end

    it "accepts data attributes" do
      render_inline(described_class.new(data: { testid: "test" }))
      expect(page).to have_css('[data-testid="test"]')
    end
  end
end
```

## Cycle Report Format

```markdown
# Review Cycle Report: [ComponentName]

## Summary
| Metric | Value |
|--------|-------|
| Status | SUCCESS / PARTIAL / BLOCKED |
| Final Score | X/10 |
| Iterations | X of N |
| Issues Fixed | X |
| Tests | X passing |

## Iteration Log

### Iteration 1
**Score**: 6/10

**Review Findings**:
- [Critical] 2 Rubocop offenses
- [High] Missing VARIANTS constant
- [Medium] No tests for edge cases

**Fixes Applied**:
- Ran rubocop -a (fixed 2 offenses)
- Added VARIANTS constant with freeze
- Generated 4 new test cases

---

### Iteration 2
**Score**: 8/10

**Review Findings**:
- [Medium] Template has inline conditional

**Fixes Applied**:
- Moved conditional to `state_classes` helper

---

### Iteration 3
**Score**: 9/10 ✓

All checks passing. Proceeding to documentation review.

---

## Documentation Review

### Changes Assessed
- API: No breaking changes
- New features: None
- Documentation updates: None needed

### Files Reviewed
- [x] preview.rb - Notes are current
- [x] CHANGELOG.md - No update needed

---

## Final State

### Automated Checks
- Rubocop: ✓ 0 offenses
- RSpec: ✓ 12 examples, 0 failures

### Code Quality Score: 9/10
- Constants: ✓ VARIANTS, SIZES frozen
- class_names: ✓ Used throughout
- Template: ✓ Minimal logic
- Tests: ✓ Full coverage

### Files Changed
| File | Changes |
|------|---------|
| component.rb | Added constants, refactored methods |
| component_spec.rb | Added 4 test cases |

### Git
- Commit: `abc1234` Refactor Button component for code quality
- Pushed: ✓ origin/tailwind-migration
```

## Example Execution

```
User: /review-cycle Button

AI: Starting code quality review cycle for Bali::Button::Component...
Target: Score ≥ 9/10

═══════════════════════════════════════════════════════════════
                     ITERATION 1 OF 5
═══════════════════════════════════════════════════════════════

## Phase 1: Code Review

### Automated Checks

**Rubocop**:
app/components/bali/button/component.rb:15:5: C: Style/StringConcatenation
app/components/bali/button/component.rb:23:3: C: Layout/EmptyLines

**RSpec**:
12 examples, 0 failures

### DHH Review

**Score: 6/10** ⚠️ Below threshold

**High Priority**:
1. String concatenation instead of `class_names` helper (line 15)
2. Variant logic uses case statement instead of constant hash

**Medium Priority**:
1. Missing tests for disabled state
2. Could use `**options` splat for HTML attributes

---

## Phase 2: Applying Fixes

### Fix 1: Replace case with VARIANTS constant
[Shows code change]

### Fix 2: Use class_names helper
[Shows code change]

### Fix 3: Run Rubocop auto-fix
```bash
bundle exec rubocop app/components/bali/button/ -a
```
✓ 2 offenses corrected

---

## Re-review Score: 8/10 ⚠️ Below threshold

═══════════════════════════════════════════════════════════════
                     ITERATION 2 OF 5
═══════════════════════════════════════════════════════════════

### Remaining Issues
- [Medium] Missing tests for disabled state

## Phase 2: Applying Fix

### Fix: Add disabled state tests
[Shows new test cases]

---

## Re-review Score: 9/10 ✓ Threshold met!

═══════════════════════════════════════════════════════════════
                     DOCUMENTATION REVIEW
═══════════════════════════════════════════════════════════════

## Checking Documentation Needs

### API Changes
- No breaking changes
- No new params added
- No params removed

### Files Reviewed
- preview.rb: Notes are current, no update needed
- CHANGELOG.md: No entry needed (internal refactor only)

Documentation: ✓ No updates required

═══════════════════════════════════════════════════════════════
                     COMMIT AND PUSH
═══════════════════════════════════════════════════════════════

## Staging Files
```bash
git add app/components/bali/button/ spec/bali/components/button/
```

## Creating Commit
```bash
git commit -m "Refactor Button component for code quality

Changes:
- Replace case statement with VARIANTS constant
- Use class_names helper throughout
- Add tests for disabled state

Review cycle: 2 iterations
Final score: 9/10

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```
✓ Commit created: abc1234

## Pushing to Remote
```bash
git push origin HEAD
```
✓ Pushed to origin/tailwind-migration

═══════════════════════════════════════════════════════════════
                     CYCLE COMPLETE
═══════════════════════════════════════════════════════════════

## Summary
| Metric | Value |
|--------|-------|
| Status | ✅ SUCCESS |
| Final Score | 9/10 |
| Iterations | 2 of 5 |
| Issues Fixed | 4 |
| Tests | 14 passing |

## Files Changed
- app/components/bali/button/component.rb (refactored)
- spec/bali/components/button_spec.rb (2 tests added)

## Git
- Commit: `abc1234` Refactor Button component for code quality
- Pushed: ✓ origin/tailwind-migration
```

## Troubleshooting

### Same issue keeps appearing
1. Check if fix was actually applied (file saved?)
2. Try different fix approach
3. May need manual intervention - escalate to user

### Rubocop can't auto-fix
Some offenses require manual fixes:
- Complex refactoring (method too long)
- Security-related issues
- Architecture changes

Apply manual fix or mark as accepted deviation.

### Tests fail after fix
1. Read the failure message carefully
2. Fix broke existing behavior? Revert and try different approach
3. Test expectation outdated? Update test (document why)
4. Never delete tests to make them pass

### DHH reviewer disagrees with existing patterns
If the reviewer suggests changes that conflict with project conventions:
1. Check CLAUDE.md for established patterns
2. Project conventions take precedence
3. Note the suggestion but don't apply if it conflicts
