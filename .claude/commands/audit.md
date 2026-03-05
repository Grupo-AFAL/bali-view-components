# Audit Bali Component Library

Comprehensive audit of the Bali ViewComponent library status.

## Usage

```
/audit $ARGUMENTS
```

Where `$ARGUMENTS` is:
- (none) - Full library audit
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

### Step 2: DaisyUI Compliance Check

Check each component for proper DaisyUI class usage:

1. **DaisyUI Classes**:
   ```ruby
   # Grep for DaisyUI patterns
   grep -l "btn-primary\|btn-success\|btn-error" component.rb
   grep -l "badge-\|alert-\|card-body" component.rb
   ```

2. **Classification**:
   - **Compliant**: Uses proper DaisyUI classes
   - **Needs Review**: Missing or incorrect DaisyUI patterns
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
| DaisyUI Compliant | X | X% |
| Needs Review | X | X% |
| With Tests | X | X% |
| A11y Compliant | X | X% |

## Component Status

### Compliant (X components)
| Component | Tests | A11y | Notes |
|-----------|-------|------|-------|
| Button | 12 examples | Yes | |
| Badge | 8 examples | Yes | |

### Needs Review (X components)
| Component | Issue | Priority |
|-----------|-------|----------|
| Form | Complex sub-components | High |
| DataTable | Table, Pagination dependencies | Medium |

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

### Improvement Order (Recommended)
1. [Component] - [reason]
2. [Component] - [reason]

### Technical Debt
- [Issue description]
```

## Report Details

### DaisyUI Compliance Indicators

| Status | Icon | Criteria |
|--------|------|----------|
| Compliant | :white_check_mark: | Proper DaisyUI classes present |
| Needs Review | :construction: | Missing or incorrect DaisyUI patterns |
| N/A | :grey_question: | No CSS framework usage |

### Component Complexity Rating

| Rating | Criteria |
|--------|----------|
| Low | Single file, no slots, no JS |
| Medium | Has slots OR has JS controller |
| High | Has slots AND JS controller AND sub-components |

### Priority Calculation

```
Priority Score = (Usage Frequency * 3) + (Complexity * -1) + (Has Tests * 2)
```

- Usage Frequency: Based on grep across consumer apps (if available)
- Complexity: Low=1, Medium=2, High=3
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
| DaisyUI Compliant | 45 | 75% |
| Needs Review | 3 | 5% |
| With Tests | 48 | 80% |
| A11y Compliant | 25 | 42% |

## Component Status

### Compliant (45 components)

| Component | Tests | A11y | Notes |
|-----------|-------|------|-------|
| ActionsDropdown | 3 | Yes | |
| Avatar | 5 | Yes | |
| Badge | 8 | Yes | |
| BooleanIcon | 3 | N/A | |
| Breadcrumb | 4 | Yes | |
| Button | 12 | Yes | |
| Columns | 15 | N/A | |
| Icon | 6 | Yes | |
| Link | 4 | Yes | |
| Loader | 3 | Yes | |
| Notification | 5 | Yes | |
| Progress | 4 | Yes | |
| Tabs | 8 | Yes | |
| Tooltip | 5 | Yes | |
| DeleteLink | 3 | Yes | |

### Needs Review (3 components)

| Component | Issue | Priority |
|-----------|-------|----------|
| GanttChart | Complex custom component | Low |
| LocationsMap | External library integration | Low |
| RichTextEditor | External library integration | Medium |

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
1. Add missing tests for high-use components - ~1 day
2. Run /a11y audit on components - ~1 day
3. Review components flagged as "Needs Review" - ~1 day

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
    "compliant": 45,
    "needs_review": 3,
    "with_tests": 48,
    "a11y_compliant": 25
  },
  "components": [
    {
      "name": "Button",
      "path": "app/components/bali/button",
      "daisyui_status": "compliant",
      "has_preview": true,
      "has_spec": true,
      "test_count": 12,
      "has_scss": true,
      "has_stimulus": false,
      "a11y_status": "compliant",
      "daisyui_classes": ["btn", "btn-primary", "btn-sm"]
    }
  ]
}
```

## Integration with Other Commands

After audit, suggested follow-ups:

```bash
# Run accessibility audit on components
/a11y Button Card Modal

# Generate missing tests
/test --generate GanttChart

# Full quality cycle on components needing review
/component-cycle Card
```
