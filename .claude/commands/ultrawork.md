# Ultrawork: Autonomous Component Migration

Autonomously migrate multiple Bali components from Bulma to DaisyUI without intervention.

## Usage

```
/ultrawork $ARGUMENTS
```

Where `$ARGUMENTS` is:
- `--all` - Migrate all pending components
- `--batch N` - Migrate components in batch N (1-8)
- `--component name` - Migrate a single specific component
- `--resume` - Resume from last state (reads MIGRATION_STATE.json)
- `--infrastructure` - Run infrastructure setup only (Phase 1-2)
- `--dry-run` - Plan only, don't execute
- `--stop-on-failure` - Stop if any component fails (default: continue)
- `--skip-visual` - Skip visual verification (faster, less safe)

## State Tracking

Progress is tracked in `docs/migration/MIGRATION_STATE.json`. This allows:
- Resuming after interruption
- Tracking which components are done/pending/failed
- Logging errors for review

## Prerequisites Check

Before ANY component migration, verify:
1. `docs/migration/MIGRATION_STATE.json` exists and `infrastructure_complete: true`
2. If infrastructure not complete, run `--infrastructure` first
3. On `tailwind-migration` branch
4. Working directory clean (no uncommitted changes)
5. Lookbook server running at http://localhost:3001/lookbook

## Infrastructure Phase (Run First!)

If `infrastructure_complete` is false, execute these steps:

### Step 1: Update Gemfile
Remove: `bulma-rails`, `dartsass-rails`, `sprockets-rails`
Add: `propshaft` (if not present)
Keep: `tailwindcss-rails`, `importmap-rails`

### Step 2: Update spec/dummy configuration
- Update `config/application.rb` (remove scss from lookbook extensions)
- Update `Procfile.dev` (remove sass watcher)
- Update Tailwind config to scan Bali components

### Step 3: Update Engine
- Simplify `lib/bali/engine.rb` (remove Sprockets hooks)
- Create `config/importmap.rb` in gem root

### Step 4: Verify Infrastructure
```bash
cd spec/dummy
bundle install
bin/rails tailwindcss:build
bin/rails assets:precompile
```

### Step 5: Mark Complete
Update MIGRATION_STATE.json: `infrastructure_complete: true`

## Verification Strategy (CRITICAL)

### What Gets Verified

| Layer | Tool | What It Checks |
|-------|------|----------------|
| **Ruby Logic** | RSpec | Component initializes, methods work |
| **HTML Structure** | RSpec | Correct elements, classes present |
| **CSS Classes** | RSpec | DaisyUI classes applied correctly |
| **Stimulus JS** | Cypress | Controllers connect, actions fire |
| **Visual Rendering** | Playwright | Component looks correct in browser |
| **Lookbook Preview** | Playwright | Preview page loads without error |

### Verification Pipeline

For EACH component, run this full pipeline:

```
┌─────────────────────────────────────────────────────────────┐
│  1. RSpec Tests (Ruby + HTML structure)                     │
│     bundle exec rspec spec/components/bali/[name]/          │
│     └─ FAIL? → Revert, skip component                       │
├─────────────────────────────────────────────────────────────┤
│  2. Rubocop (Code style)                                    │
│     bundle exec rubocop app/components/bali/[name]/         │
│     └─ FAIL? → Auto-fix, continue                           │
├─────────────────────────────────────────────────────────────┤
│  3. Cypress Tests (JS behavior) - if component has JS       │
│     yarn run cy:run --spec cypress/e2e/[name].cy.js         │
│     └─ FAIL? → Revert, skip component                       │
├─────────────────────────────────────────────────────────────┤
│  4. Visual Verification (Playwright)                        │
│     - Start Lookbook server if not running                  │
│     - Navigate to component preview                         │
│     - Screenshot each variant                               │
│     - Check for console errors                              │
│     - Check component renders (not blank/broken)            │
│     └─ FAIL? → Log warning, flag for manual review          │
├─────────────────────────────────────────────────────────────┤
│  5. All Pass → Commit                                       │
│  6. Any Critical Fail → Revert, log, continue               │
└─────────────────────────────────────────────────────────────┘
```

## Autonomous Mode Rules

When running in ultrawork mode:

1. **No confirmations** - Proceed automatically
2. **Git commits per component** - Each component gets its own commit
3. **Branch per component** - Create `tailwind-migration/[name]` branches
4. **Full verification before commit** - RSpec + Cypress + Visual
5. **Skip on failure** - Log failure, continue to next component
6. **Summary at end** - Report all successes/failures with evidence

## Migration Phases

### Phase 1: Core (No dependencies)
1. `Icon`
2. `Link`
3. `Loader`
4. `BooleanIcon`
5. `Clipboard`
6. `Timeago`

### Phase 2: Buttons & Inputs
7. `Button` (if exists as standalone)
8. `Dropdown`
9. `SearchInput`
10. `Filters`

### Phase 3: Layout Containers
11. `Card`
12. `Modal`
13. `Drawer`
14. `Tabs`
15. `Columns`
16. `Level`
17. `Hero`

### Phase 4: Navigation
18. `NavBar`
19. `SideMenu`
20. `Breadcrumb`
21. `Stepper`

### Phase 5: Data Display
22. `Table`
23. `DataTable`
24. `PropertiesTable`
25. `LabelValue`
26. `List`
27. `Timeline`
28. `TreeView`
29. `Calendar`
30. `GanttChart`
31. `Heatmap`
32. `Chart`

### Phase 6: Feedback & Specialized
33. `Notification`
34. `Progress`
35. `Tooltip`
36. `Hovercard`
37. `Avatar`
38. `Carousel`
39. `ImageGrid`
40. `InfoLevel`
41. `PageHeader`
42. `Rate`
43. `Reveal`
44. `SortableList`
45. `DeleteLink`
46. `RichTextEditor`

## Workflow Per Component

For each component, execute this sequence:

### 1. Setup Branch
```bash
git checkout tailwind-migration
git pull origin tailwind-migration 2>/dev/null || true
git checkout -b tailwind-migration/[component-name-lowercase]
```

### 2. Analyze Component
- Read `app/components/bali/[name]/component.rb`
- Read `app/components/bali/[name]/component.html.erb`
- Read `app/components/bali/[name]/component.scss` (if exists)
- Read `spec/components/bali/[name]/component_spec.rb`
- Check if `cypress/e2e/[name].cy.js` exists
- Identify all Bulma classes used

### 3. Transform Component

#### Ruby Class (`component.rb`)
- Replace Bulma class mappings with DaisyUI equivalents
- Update VARIANTS constant
- Update SIZES constant (if applicable)
- Ensure `class_names` helper is used
- Ensure `**options` passthrough exists

#### Template (`component.html.erb`)
- Replace Bulma classes with DaisyUI classes
- Restructure markup if needed (e.g., card-header → card-title in card-body)
- Update data attributes for Stimulus if needed

#### Styles (`component.scss`)
- Remove Bulma overrides
- Keep only custom animations/behaviors
- Delete file if empty after cleanup

#### Preview (`preview.rb`)
- Update variant options
- Update size options
- Add any new DaisyUI-specific options

#### Tests (`component_spec.rb`)
- Update class expectations from Bulma to DaisyUI
- Add tests for new variants if added
- Ensure all existing functionality is tested

### 4. Verification Pipeline

#### Step 4a: RSpec Tests (REQUIRED - blocks commit)
```bash
bundle exec rspec spec/components/bali/[name]/ --format documentation
```
- Must pass 100%
- If fails: REVERT and skip component

#### Step 4b: Rubocop (REQUIRED - auto-fix)
```bash
bundle exec rubocop app/components/bali/[name]/ --autocorrect-all
```
- Auto-fixes applied
- Only blocks if unfixable errors

#### Step 4c: Cypress Tests (REQUIRED if exists - blocks commit)
```bash
# Check if component has Cypress tests
if [ -f "cypress/e2e/[name].cy.js" ]; then
  # Ensure server is running
  curl -s http://localhost:3001/lookbook > /dev/null || {
    echo "Starting Lookbook server..."
    cd spec/dummy && bin/rails server -p 3001 -d
    sleep 5
  }
  
  yarn run cy:run --spec "cypress/e2e/[name].cy.js"
fi
```
- Must pass 100%
- If fails: REVERT and skip component

#### Step 4d: Visual Verification (WARNING only - doesn't block)

Use Playwright to verify component renders correctly:

```
VISUAL VERIFICATION CHECKLIST:
1. Start Lookbook server (if not running)
2. Navigate to: http://localhost:3001/lookbook/inspect/bali/[name]/default
3. Wait for page load
4. Check for JavaScript console errors
5. Check component is visible (not blank)
6. Screenshot the component
7. Navigate to each variant preview
8. Screenshot each variant
9. Compare screenshots to expected (if baseline exists)
```

**Playwright Script Pattern:**
```javascript
// For each component variant:
await page.goto(`http://localhost:3001/lookbook/inspect/bali/${name}/${variant}`);
await page.waitForLoadState('networkidle');

// Check for errors
const errors = [];
page.on('console', msg => {
  if (msg.type() === 'error') errors.push(msg.text());
});

// Check component renders
const preview = page.locator('.lookbook-preview iframe');
await expect(preview).toBeVisible();

// Screenshot
await page.screenshot({ path: `screenshots/${name}/${variant}.png` });

// Report errors
if (errors.length > 0) {
  console.warn(`⚠ Console errors in ${name}/${variant}:`, errors);
}
```

**Visual Check Criteria:**
- [ ] Page loads without timeout
- [ ] No JavaScript console errors
- [ ] Component iframe is visible
- [ ] Component is not blank/empty
- [ ] No broken image icons
- [ ] No unstyled "flash of unstyled content"

**If visual check fails:**
- Log warning with screenshot path
- Flag component for manual review
- DO NOT revert (RSpec/Cypress already passed)
- Continue to commit (visual issues may be acceptable)

### 5. Commit (only if RSpec + Cypress pass)
```bash
git add app/components/bali/[name]/ spec/components/bali/[name]/
git commit -m "Migrate [ComponentName] from Bulma to DaisyUI

- Update variant/size mappings to DaisyUI classes
- Restructure template for DaisyUI patterns
- Update tests for new class names
- Update Lookbook preview

Verification:
- RSpec: ✓ [N] examples, 0 failures
- Cypress: ✓ [N] tests passed (or N/A if no JS tests)
- Visual: ✓ Lookbook renders (or ⚠ flagged for review)"
```

### 6. Return to Base
```bash
git checkout tailwind-migration
```

### 7. Log Result
Record success, partial success (visual warning), or failure.

## Server Management

Before starting verification, ensure Lookbook is running:

```bash
# Check if server is running
if ! curl -s http://localhost:3001/lookbook > /dev/null 2>&1; then
  echo "Starting Lookbook server for visual verification..."
  cd spec/dummy
  bundle exec rails server -p 3001 -d -e test
  sleep 10  # Wait for server startup
fi
```

After all components done:
```bash
# Kill the server
pkill -f "rails server.*3001" || true
```

## Class Mapping Reference (Quick)

| Bulma | DaisyUI |
|-------|---------|
| `button` | `btn` |
| `is-primary` | `btn-primary` |
| `is-danger` | `btn-error` |
| `is-small/medium/large` | `btn-sm/md/lg` |
| `card` | `card bg-base-100` |
| `card-header` | (use card-title in card-body) |
| `card-content` | `card-body` |
| `card-footer` | `card-actions` |
| `modal` | `modal` |
| `modal-card` | `modal-box` |
| `notification` | `alert` |
| `tag` | `badge` |
| `table is-striped` | `table table-zebra` |
| `input` | `input input-bordered` |
| `tabs` | `tabs tabs-boxed` |

## Execution Example

```
User: /ultrawork --phase 1

AI: Starting autonomous migration of Phase 1 components...

## Pre-flight
- Checking Lookbook server... not running
- Starting server on port 3001... done
- Loading Playwright for visual verification... ready

## Phase 1: Core Components

### 1/6: Icon
- Branch: tailwind-migration/icon
- Analyzing... found 3 Bulma classes
- Transforming component.rb... done
- Transforming component.html.erb... done
- Verification:
  - RSpec: ✓ 8 examples, 0 failures
  - Rubocop: ✓ no offenses
  - Cypress: ⊘ no JS tests for this component
  - Visual: ✓ renders correctly, 0 console errors
- Committed: abc1234

### 2/6: Link
- Branch: tailwind-migration/link
- Analyzing... found 5 Bulma classes
- Transforming... done
- Verification:
  - RSpec: ✓ 12 examples, 0 failures
  - Rubocop: ✓ no offenses
  - Cypress: ⊘ no JS tests
  - Visual: ✓ renders correctly
- Committed: def5678

### 3/6: Loader
- Branch: tailwind-migration/loader
- Analyzing... found 2 Bulma classes
- Transforming... done
- Verification:
  - RSpec: ✓ 4 examples, 0 failures
  - Rubocop: ✓ no offenses
  - Cypress: ⊘ no JS tests
  - Visual: ⚠ spinner animation different (flagged)
- Committed with warning: ghi9012

### 4/6: BooleanIcon
...

---

## Summary

| Component | RSpec | Cypress | Visual | Status | Commit |
|-----------|-------|---------|--------|--------|--------|
| Icon | ✓ | ⊘ | ✓ | ✓ Migrated | abc1234 |
| Link | ✓ | ⊘ | ✓ | ✓ Migrated | def5678 |
| Loader | ✓ | ⊘ | ⚠ | ⚠ Review | ghi9012 |
| BooleanIcon | ✓ | ⊘ | ✓ | ✓ Migrated | jkl3456 |
| Clipboard | ✓ | ✓ | ✓ | ✓ Migrated | mno7890 |
| Timeago | ⊘ | ⊘ | ⊘ | ⊘ Skipped | - |

**Phase 1 Complete**: 4 migrated, 1 needs review, 1 skipped, 0 failed

## Visual Review Needed

### Loader
- Issue: Spinner animation appears different
- Screenshot: screenshots/loader/default.png
- Action: Manual review recommended

## Screenshots Saved
- screenshots/icon/default.png
- screenshots/link/default.png
- screenshots/link/primary.png
- screenshots/loader/default.png (⚠ flagged)
- screenshots/boolean_icon/default.png
- screenshots/clipboard/default.png
```

## Failure Handling

### RSpec/Cypress Failure (Critical - Reverts)

```
### X/N: Modal
- Branch: tailwind-migration/modal
- Analyzing... found 8 Bulma classes
- Transforming... done
- Verification:
  - RSpec: ✗ 2 failures
  
    1) Bali::Modal::Component renders modal-box class
       Expected: have_css(".modal-box")
       Got: have_css(".modal-card")
       
    2) Bali::Modal::Component closes on backdrop click
       ActionView::Template::Error: undefined method `dialog_target`

- ⚠ CRITICAL FAILURE - Reverting changes
- Logging failure for manual review

git checkout -- app/components/bali/modal/
git checkout tailwind-migration
git branch -D tailwind-migration/modal
```

### Visual Failure (Warning - Still Commits)

```
### X/N: Dropdown
- Branch: tailwind-migration/dropdown
- Transforming... done
- Verification:
  - RSpec: ✓ 15 examples, 0 failures
  - Rubocop: ✓ no offenses
  - Cypress: ✓ 3 tests passed
  - Visual: ⚠ Issues detected:
    - Console error: "Uncaught TypeError: Cannot read property 'focus'"
    - Screenshot saved: screenshots/dropdown/default.png
    
- Committed with visual warning: xyz9999
- Flagged for manual visual review
```

## Final Report

At the end of a full run, generate:

```markdown
# Ultrawork Migration Report

**Run Date**: 2026-01-10
**Phase(s)**: 1-6 (All)
**Duration**: 45 minutes

## Verification Summary

| Check | Components Passed | Components Failed |
|-------|-------------------|-------------------|
| RSpec | 43 | 3 |
| Cypress | 28 | 2 (18 N/A) |
| Visual | 38 | 5 (3 N/A) |

## Results by Phase

| Phase | Total | Migrated | Visual Warning | Failed |
|-------|-------|----------|----------------|--------|
| 1: Core | 6 | 5 | 1 | 0 |
| 2: Buttons | 4 | 4 | 0 | 0 |
| 3: Layout | 7 | 5 | 1 | 1 |
| 4: Navigation | 4 | 4 | 0 | 0 |
| 5: Data | 11 | 9 | 1 | 1 |
| 6: Specialized | 14 | 11 | 2 | 1 |
| **Total** | **46** | **38** | **5** | **3** |

## Critical Failures (Require Manual Fix)

### Modal (Phase 3)
- **Failed Check**: RSpec
- **Error**: Stimulus target mismatch
- **File**: app/components/bali/modal/component.html.erb
- **Action**: Manual migration needed

### GanttChart (Phase 5)
- **Failed Check**: Cypress
- **Error**: Timeline drag not working
- **File**: app/assets/javascripts/bali/controllers/gantt_controller.js
- **Action**: Review Stimulus controller

### RichTextEditor (Phase 6)
- **Failed Check**: RSpec
- **Error**: Trix integration conflicts
- **File**: app/components/bali/rich_text_editor/component.rb
- **Action**: Trix + DaisyUI compatibility review

## Visual Warnings (Review Recommended)

### Loader
- **Screenshot**: screenshots/loader/default.png
- **Issue**: Animation timing different from original

### Dropdown  
- **Screenshot**: screenshots/dropdown/default.png
- **Issue**: Console error on focus

### Card
- **Screenshot**: screenshots/card/bordered.png
- **Issue**: Border thickness appears different

### Carousel
- **Screenshot**: screenshots/carousel/default.png
- **Issue**: Arrow icons missing

### Tooltip
- **Screenshot**: screenshots/tooltip/default.png
- **Issue**: Positioning slightly offset

## All Screenshots

Saved to: `./screenshots/[component]/[variant].png`

## Branches Created

[List of all branches]

## Next Steps

1. **Fix 3 critical failures** manually
2. **Review 5 visual warnings** in Lookbook
3. Push all branches: `git push origin tailwind-migration/*`
4. Create PRs or merge locally
```

## Safety Features

1. **Never force push**
2. **Never modify main branch**
3. **Always revert on critical failure**
4. **Full test pipeline before every commit**
5. **Visual evidence (screenshots) saved**
6. **Server auto-managed (start/stop)**
7. **Log everything for review**
