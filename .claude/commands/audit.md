# Audit Bali Component Library

Comprehensive audit of the Bali ViewComponent library status.

## Usage

```
/audit $ARGUMENTS
```

Where `$ARGUMENTS` is:
- (none) - Full library audit
- `--migration` - Migration status only
- `--coverage` - Test coverage only
- `--a11y` - Accessibility status only
- `--json` - Output as JSON for tooling
- `--quick` - Skip detailed analysis

## Workflow

### Step 1: Discover All Components

```bash
# Find all component directories
ls -d app/components/bali/*/

# Count components
find app/components/bali -name "component.rb" -type f | wc -l
```

For each component, gather:
- Component path
- Has preview.rb
- Has spec file
- Has SCSS file
- Has Stimulus controller

### Step 2: Migration Status Analysis

Check each component for:

1. **Bulma Classes** (indicates NOT migrated):
   ```ruby
   # Grep for Bulma patterns
   grep -l "is-primary\|is-success\|is-danger\|is-warning\|is-info" component.rb
   grep -l "is-small\|is-medium\|is-large" component.rb
   grep -l "columns\|column" component.html.erb
   ```

2. **DaisyUI Classes** (indicates migrated):
   ```ruby
   # Grep for DaisyUI patterns
   grep -l "btn-primary\|btn-success\|btn-error" component.rb
   grep -l "badge-\|alert-\|card-body" component.rb
   ```

3. **Classification**:
   - **Migrated**: Only DaisyUI classes, no Bulma
   - **Partial**: Mix of Bulma and DaisyUI
   - **Pending**: Only Bulma classes
   - **Not Applicable**: No CSS framework classes (e.g., utility components)

### Step 3: Test Coverage Analysis

For each component:

```bash
# Check if spec exists
test -f spec/bali/components/{name}_spec.rb

# Count test examples
grep -c "it \|context \|describe " spec/bali/components/{name}_spec.rb
```

Categories:
- **Full Coverage**: Spec exists with >5 examples
- **Basic Coverage**: Spec exists with 1-5 examples
- **No Coverage**: No spec file

### Step 4: Accessibility Analysis

For each component, check:

1. **ARIA Attributes**:
   ```bash
   grep -l "aria-\|role=" component.html.erb
   ```

2. **Focus Management**:
   ```bash
   grep -l "tabindex\|focus" component.rb component.html.erb
   ```

3. **Screen Reader Support**:
   ```bash
   grep -l "sr-only\|aria-label\|aria-describedby" component.html.erb
   ```

Categories:
- **A11y Compliant**: Has required ARIA for component type
- **Needs Review**: Missing some ARIA patterns
- **No A11y**: No accessibility considerations

### Step 5: Generate Report

```markdown
# Bali ViewComponent Library Audit
Generated: [timestamp]

## Summary

| Metric | Count | Percentage |
|--------|-------|------------|
| Total Components | X | 100% |
| Fully Migrated | X | X% |
| Partially Migrated | X | X% |
| Pending Migration | X | X% |
| With Tests | X | X% |
| A11y Compliant | X | X% |

## Migration Status

### Migrated (X components)
| Component | Tests | A11y | Notes |
|-----------|-------|------|-------|
| Button | 12 examples | Yes | |
| Badge | 8 examples | Yes | |

### Partially Migrated (X components)
| Component | Bulma Classes | DaisyUI Classes | Blocking Issue |
|-----------|--------------|-----------------|----------------|
| Modal | is-active | modal-box | Needs backdrop migration |

### Pending Migration (X components)
| Component | Complexity | Dependencies | Priority |
|-----------|------------|--------------|----------|
| Form | High | Multiple sub-components | High |
| DataTable | High | Table, Pagination | Medium |

## Test Coverage

### No Test Coverage (X components)
| Component | Reason | Suggested Tests |
|-----------|--------|-----------------|
| GanttChart | Complex | Visual regression |
| RichTextEditor | External lib | Integration |

## Accessibility Status

### Needs A11y Review (X components)
| Component | Missing | Required For |
|-----------|---------|--------------|
| Dropdown | aria-expanded | Keyboard users |
| Modal | focus trap | Screen readers |

## Recommendations

### Immediate Actions
1. [Highest priority item]
2. [Second priority]

### Migration Order (Recommended)
1. [Component] - [reason]
2. [Component] - [reason]

### Technical Debt
- [Issue description]
```

## Report Details

### Migration Status Indicators

| Status | Icon | Criteria |
|--------|------|----------|
| Migrated | :white_check_mark: | 0 Bulma classes, DaisyUI classes present |
| Partial | :construction: | Mix of Bulma and DaisyUI |
| Pending | :hourglass: | Only Bulma classes |
| N/A | :grey_question: | No CSS framework usage |

### Component Complexity Rating

| Rating | Criteria |
|--------|----------|
| Low | Single file, no slots, no JS |
| Medium | Has slots OR has JS controller |
| High | Has slots AND JS controller AND sub-components |

### Priority Calculation

```
Priority Score = (Usage Frequency * 3) + (Migration Complexity * -1) + (Has Tests * 2)
```

- Usage Frequency: Based on grep across consumer apps (if available)
- Migration Complexity: Low=1, Medium=2, High=3
- Has Tests: Yes=1, No=0

## Example Output

```
User: /audit

AI: Running comprehensive audit of Bali ViewComponent library...

# Bali ViewComponent Library Audit
Generated: 2026-01-11 21:00:00

## Summary

| Metric | Count | Percentage |
|--------|-------|------------|
| Total Components | 60 | 100% |
| Fully Migrated | 15 | 25% |
| Partially Migrated | 8 | 13% |
| Pending Migration | 37 | 62% |
| With Tests | 48 | 80% |
| A11y Compliant | 25 | 42% |

## Migration Progress

```
[===========                                   ] 25% Migrated
```

## Migration Status

### Migrated (15 components)

| Component | Tests | A11y | Commit |
|-----------|-------|------|--------|
| ActionsDropdown | 3 | Yes | a89f03a |
| Avatar | 5 | Yes | - |
| Badge | 8 | Yes | - |
| BooleanIcon | 3 | N/A | - |
| Breadcrumb | 4 | Yes | - |
| Button | 12 | Yes | - |
| Columns | 15 | N/A | 2cdf695 |
| Icon | 6 | Yes | - |
| Link | 4 | Yes | - |
| Loader | 3 | Yes | - |
| Notification | 5 | Yes | - |
| Progress | 4 | Yes | - |
| Tabs | 8 | Yes | - |
| Tooltip | 5 | Yes | - |
| DeleteLink | 3 | Yes | - |

### Partially Migrated (8 components)

| Component | Issue | Blocking |
|-----------|-------|----------|
| Card | card-footer still using Bulma | Low |
| Dropdown | Some variants use is-active | Medium |
| Modal | Backdrop uses modal-background | Medium |
| Drawer | Uses Bulma columns internally | Low |
| Filters | Form elements need migration | High |
| Hero | Uses section classes | Low |
| Level | Uses level class | Low |
| Navbar | Complex structure | High |

### Pending Migration (37 components)

#### High Priority (frequently used)
- Form (12 sub-components)
- DataTable
- Table
- SearchInput

#### Medium Priority
- Calendar, Carousel, Chart, Clipboard
- Heatmap, HoverCard, ImageGrid, InfoLevel
- LabelValue, List, Message, PageHeader
- PropertiesTable, Rate, Reveal, RichTextEditor
- SideMenu, SortableList, Stepper, Timeline
- TreeView

#### Low Priority (specialized)
- AddToCalendar, Box, DisplayValue
- FieldGroupWrapper, FlashNotifications
- GanttChart, ImageField, LocationsMap
- RecurrentEventRuleForm, TurboNativeApp::SignOut

## Test Coverage

### Missing Tests (12 components)
| Component | Priority |
|-----------|----------|
| GanttChart | Low |
| RichTextEditor | Medium |
| LocationsMap | Low |
| ImageField | Medium |
| ... | ... |

## Accessibility

### Needs A11y Audit (35 components)
Most components need review for:
- ARIA labels on interactive elements
- Keyboard navigation
- Focus management
- Screen reader announcements

### A11y Priority
1. Modal - focus trap missing
2. Dropdown - keyboard nav incomplete
3. Tabs - arrow key navigation
4. Form elements - label associations

## Recommendations

### Immediate Actions
1. Complete partial migrations (8 components) - ~2 days
2. Add missing tests for high-use components - ~1 day
3. Run /a11y audit on migrated components - ~1 day

### Suggested Migration Order
1. **Form** - Blocks many other components
2. **Table/DataTable** - High usage
3. **SearchInput** - Common in all apps
4. **SideMenu/Navbar** - Layout components

### Technical Debt
- 12 components have no test coverage
- 35 components need accessibility review
- SCSS files exist for 45 components (should minimize)

---

Full audit complete. Run `/audit --json` for machine-readable output.
```

## JSON Output Format

When `--json` flag is used:

```json
{
  "generated_at": "2026-01-11T21:00:00Z",
  "summary": {
    "total": 60,
    "migrated": 15,
    "partial": 8,
    "pending": 37,
    "with_tests": 48,
    "a11y_compliant": 25
  },
  "components": [
    {
      "name": "Button",
      "path": "app/components/bali/button",
      "migration_status": "migrated",
      "has_preview": true,
      "has_spec": true,
      "test_count": 12,
      "has_scss": true,
      "has_stimulus": false,
      "a11y_status": "compliant",
      "bulma_classes": [],
      "daisyui_classes": ["btn", "btn-primary", "btn-sm"]
    }
  ]
}
```

## Integration with Other Commands

After audit, suggested follow-ups:

```bash
# Migrate highest priority pending component
/migrate-component Form

# Run accessibility audit on migrated components
/a11y Button Card Modal

# Generate missing tests
/test --generate GanttChart

# Full cycle on partial components
/component-cycle Card
```
