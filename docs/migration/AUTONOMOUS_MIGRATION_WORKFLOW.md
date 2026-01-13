# Autonomous Component Migration Workflow

This document defines the workflow for Claude to autonomously migrate all Bali components from Bulma to DaisyUI without human intervention.

## Invocation

```
/ultrawork
```

Or ask Claude: "Run the autonomous component migration"

## Prerequisites (Must be completed before autonomous run)

Before running autonomous migration, ensure:

- [ ] Lookbook server is running at `http://localhost:3001/lookbook`
- [ ] All dependencies installed (`bundle install`)
- [ ] On `tailwind-migration` branch
- [ ] No uncommitted changes (`git status` clean)

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    AUTONOMOUS MIGRATION LOOP                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. Load migration state from progress file                      │
│  2. Get next pending component                                   │
│  3. Create migrate/[component] branch                            │
│  4. Read component files (rb, erb, scss)                         │
│  5. Apply Bulma → DaisyUI transformation rules                   │
│  6. Update component.rb with DaisyUI classes                     │
│  7. Update component.html.erb                                    │
│  8. Convert/remove SCSS file                                     │
│  9. Update RSpec tests                                           │
│  10. Run verification:                                           │
│      - RSpec tests                                               │
│      - Rubocop                                                   │
│      - Visual check (Playwright if available)                    │
│  11. If PASS: commit, merge to tailwind-migration, mark done     │
│      If FAIL: log error, skip component, continue                │
│  12. Repeat until all components processed                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Migration State File

Location: `docs/migration/MIGRATION_STATE.json`

```json
{
  "started_at": "2025-01-12T00:00:00Z",
  "last_updated": "2025-01-12T00:00:00Z",
  "infrastructure_complete": false,
  "components": {
    "icon": { "status": "pending", "migrated_at": null, "error": null },
    "link": { "status": "pending", "migrated_at": null, "error": null },
    "button": { "status": "completed", "migrated_at": "2025-01-12T01:00:00Z", "error": null },
    "card": { "status": "failed", "migrated_at": null, "error": "RSpec failed: expected .card-body" }
  },
  "stats": {
    "total": 55,
    "completed": 1,
    "failed": 1,
    "pending": 53,
    "skipped": 0
  }
}
```

## Component Migration Order

Components are migrated in dependency order to minimize breakage:

### Batch 1: Foundation (No dependencies)
1. icon
2. link
3. tag
4. loader
5. progress
6. label_value

### Batch 2: Basic Containers
7. card
8. modal
9. drawer
10. dropdown
11. tabs
12. tooltip
13. hover_card
14. notification
15. message
16. reveal

### Batch 3: Interactive
17. avatar
18. clipboard
19. actions_dropdown
20. bulk_actions

### Batch 4: Data Display
21. table
22. list
23. sortable_list
24. tree_view
25. properties_table

### Batch 5: Forms
26. filters
27. search_input
28. image_field
29. rate
30. recurrent_event_rule_form

### Batch 6: Layout
31. navbar
32. side_menu
33. page_header
34. level
35. info_level

### Batch 7: Visualization
36. chart
37. carousel
38. image_grid
39. heatmap
40. timeline
41. stepper
42. calendar
43. locations_map

### Batch 8: Complex (May require manual review)
44. gantt_chart (+ sub-components)
45. rich_text_editor (+ sub-components)

## Transformation Rules

### Class Mapping (Bulma → DaisyUI)

```ruby
CLASS_MAPPINGS = {
  # Buttons
  'button' => 'btn',
  'is-primary' => 'btn-primary',
  'is-secondary' => 'btn-secondary',
  'is-success' => 'btn-success',
  'is-danger' => 'btn-error',
  'is-warning' => 'btn-warning',
  'is-info' => 'btn-info',
  'is-link' => 'btn-link',
  'is-ghost' => 'btn-ghost',
  'is-outlined' => 'btn-outline',
  'is-small' => 'btn-sm',
  'is-medium' => 'btn-md',
  'is-large' => 'btn-lg',
  'is-loading' => 'loading loading-spinner',

  # Cards
  'card-content' => 'card-body',
  'card-header-title' => 'card-title',
  'card-footer' => 'card-actions',

  # Modals
  'modal-background' => 'modal-backdrop',
  'modal-content' => 'modal-box',
  'modal-close' => 'btn btn-sm btn-circle btn-ghost absolute right-2 top-2',

  # Notifications/Alerts
  'notification' => 'alert',
  'is-danger' => 'alert-error',
  'is-success' => 'alert-success',
  'is-warning' => 'alert-warning',
  'is-info' => 'alert-info',

  # Tables
  'table' => 'table',
  'is-striped' => 'table-zebra',
  'is-hoverable' => 'hover',
  'is-fullwidth' => 'w-full',

  # Forms
  'input' => 'input input-bordered',
  'textarea' => 'textarea textarea-bordered',
  'select' => 'select select-bordered',
  'checkbox' => 'checkbox',
  'radio' => 'radio',
  'label' => 'label',
  'help' => 'label-text-alt',
  'is-danger' => 'input-error',

  # Layout
  'columns' => 'grid grid-cols-12 gap-4',
  'column' => 'col-span-12',
  'is-1' => 'col-span-1',
  'is-2' => 'col-span-2',
  'is-3' => 'col-span-3',
  'is-4' => 'col-span-4',
  'is-5' => 'col-span-5',
  'is-6' => 'col-span-6',
  'is-7' => 'col-span-7',
  'is-8' => 'col-span-8',
  'is-9' => 'col-span-9',
  'is-10' => 'col-span-10',
  'is-11' => 'col-span-11',
  'is-12' => 'col-span-12',

  # Navbar
  'navbar-brand' => 'navbar-start',
  'navbar-menu' => 'navbar-center',
  'navbar-end' => 'navbar-end',
  'navbar-item' => 'btn btn-ghost',
  'navbar-burger' => 'btn btn-ghost lg:hidden',

  # Dropdown
  'dropdown-trigger' => 'dropdown',
  'dropdown-menu' => 'dropdown-content',
  'dropdown-item' => 'menu-item',

  # Tags
  'tag' => 'badge',
  'tags' => 'flex gap-1',
  'is-rounded' => 'badge-outline rounded-full',

  # Progress
  'progress' => 'progress',

  # Tabs
  'tabs' => 'tabs',
  'is-active' => 'tab-active',

  # Typography
  'title' => 'text-2xl font-bold',
  'subtitle' => 'text-lg text-base-content/70',
  'is-1' => 'text-5xl',
  'is-2' => 'text-4xl',
  'is-3' => 'text-3xl',
  'is-4' => 'text-2xl',
  'is-5' => 'text-xl',
  'is-6' => 'text-lg',

  # Misc
  'box' => 'card bg-base-100 shadow-xl p-6',
  'content' => 'prose',
  'icon' => 'inline-flex items-center',
  'is-hidden' => 'hidden',
  'is-invisible' => 'invisible',
  'has-text-centered' => 'text-center',
  'has-text-left' => 'text-left',
  'has-text-right' => 'text-right',
  'is-pulled-left' => 'float-left',
  'is-pulled-right' => 'float-right',
  'is-clearfix' => 'clearfix',
  'is-flex' => 'flex',
  'is-block' => 'block',
  'is-inline' => 'inline',
  'is-inline-block' => 'inline-block',
}.freeze
```

### SCSS Conversion Rules

1. **Pure Bulma variables** → Remove (DaisyUI provides equivalents)
2. **@apply directives** → Keep (already Tailwind)
3. **Custom positioning/sizing** → Convert to Tailwind utilities
4. **Complex animations** → Keep as CSS custom properties
5. **Component-specific layout** → Convert to Tailwind or keep as minimal CSS

### Test Update Rules

1. Replace Bulma class expectations with DaisyUI equivalents
2. Update `have_css('.button')` → `have_css('.btn')`
3. Update `have_css('.is-primary')` → `have_css('.btn-primary')`
4. Keep behavioral tests unchanged

## Verification Steps

For each component, run these checks in order:

### 1. RSpec Tests
```bash
bundle exec rspec spec/components/bali/[component]/ --format progress
```
**Pass criteria**: 0 failures

### 2. Rubocop
```bash
bundle exec rubocop app/components/bali/[component]/ --format simple
```
**Pass criteria**: 0 offenses (warnings OK)

### 3. Visual Verification (if Playwright MCP available)
```
1. Navigate to http://localhost:3001/lookbook/inspect/bali/[component]/default
2. Wait for page load (2 seconds)
3. Check for console errors
4. Take screenshot for record
5. Verify component renders (not empty/error state)
```
**Pass criteria**: No JS errors, component visible

### 4. Build Check
```bash
cd spec/dummy && bin/rails tailwindcss:build
```
**Pass criteria**: Exit code 0

## Error Handling

### Recoverable Errors
- RSpec failures → Attempt fix, retry once
- Rubocop offenses → Auto-correct, retry
- Missing file → Skip component, log warning

### Non-Recoverable Errors
- Git conflicts → Stop, log error, require human intervention
- Build failures → Stop, revert changes, log error
- Multiple RSpec failures → Mark component as "needs_review"

## Commit Message Format

```
Migrate [ComponentName] from Bulma to DaisyUI

Changes:
- Replace Bulma classes with DaisyUI equivalents
- Update component.rb with new class mappings
- Convert SCSS to Tailwind utilities / Remove SCSS
- Update RSpec test expectations

Verification:
- RSpec: ✓ [N] examples, 0 failures
- Rubocop: ✓ [N] files, 0 offenses
- Visual: ✓ Renders in Lookbook

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Progress Reporting

After each component, update the state file and output:

```
═══════════════════════════════════════════════════════════════
MIGRATION PROGRESS: [15/55] components (27%)
═══════════════════════════════════════════════════════════════
✓ Completed: icon, link, tag, loader, progress, label_value,
              card, modal, drawer, dropdown, tabs, tooltip,
              hover_card, notification, message
✗ Failed:    (none)
⏭ Skipped:   (none)
⏳ Remaining: 40 components
═══════════════════════════════════════════════════════════════
Current: reveal
Status: Running RSpec tests...
═══════════════════════════════════════════════════════════════
```

## Stopping Conditions

The autonomous workflow will STOP if:

1. **3 consecutive failures** - Likely a systemic issue
2. **Git conflict detected** - Requires human resolution
3. **Build completely broken** - Tailwind/Rails won't start
4. **All components processed** - Success!

## Resume Capability

If stopped, the workflow can resume by:

1. Reading `MIGRATION_STATE.json`
2. Finding first component with `status: "pending"`
3. Continuing from that point

## Human Intervention Points

The workflow will pause and request human input for:

1. **Gantt Chart** - Complex component, confirm approach
2. **Rich Text Editor** - Many sub-components, confirm approach
3. **Any component with 3+ test failures** - May need architectural decision

## Running the Workflow

### Full Autonomous Run
```
User: /ultrawork
```

### Resume After Stop
```
User: /ultrawork --resume
```

### Single Component (for testing)
```
User: /ultrawork --component=card
```

### Dry Run (no commits)
```
User: /ultrawork --dry-run
```
