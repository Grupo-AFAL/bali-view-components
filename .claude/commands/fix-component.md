# Fix Component

Implement fixes for a Bali ViewComponent based on verification findings.

## Usage

```
/fix-component $ARGUMENTS
```

Where `$ARGUMENTS` is:
- Component name (e.g., `Columns`, `Modal`)
- `--issue:[type]` - Focus on specific issue type (classes, tests, preview, js)
- `--dry-run` - Show proposed changes without applying

## Prerequisites

- Run `/verify-component [name]` first to identify issues
- Lookbook should be running for visual verification after fixes

## Workflow

### Step 1: Load Verification Context

1. Read component files:
   - `app/components/bali/[name]/component.rb`
   - `app/components/bali/[name]/component.html.erb`
   - `app/components/bali/[name]/preview.rb`
   - `test/bali/components/[name]_test.rb` (if exists)

2. Identify issues from previous verification or re-run quick check

### Step 2: Classify Issues

| Issue Type | Priority | Fix Approach |
|------------|----------|--------------|
| Missing DaisyUI classes | High | Add correct DaisyUI classes |
| Broken JS functionality | High | Fix Stimulus controller |
| Missing tests | Medium | Generate test file |
| Preview uses wrong API | Medium | Update preview examples |
| Accessibility issues | Medium | Add ARIA attributes, focus states |
| Design inconsistencies | Low | Delegate to frontend-ui-ux-engineer |

### Step 3: Apply Fixes by Category

#### 3A: Fix Missing DaisyUI Classes

Check component against DaisyUI reference and add missing semantic classes:

```ruby
# Before (missing DaisyUI)
def dropdown_classes
  class_names('my-dropdown', @options[:class])
end

# After (with DaisyUI)
def dropdown_classes
  class_names(
    'dropdown',                    # DaisyUI base
    'dropdown-end' => @align_end,  # DaisyUI modifier
    @options[:class]
  )
end
```

#### 3C: Fix/Generate Tests

If tests are missing or incomplete, generate them:

```ruby
# test/bali/components/[name]_test.rb
# frozen_string_literal: true

require "test_helper"

class Bali[Name]ComponentTest < ComponentTestCase
  # === Rendering ===

  def test_renders_successfully
    render_inline(Bali::[Name]::Component.new)
    assert_selector("[expected-selector]")
  end

  # === Sizes ===

  Bali::[Name]::Component::SIZES.each do |size, css_class|
    define_method("test_renders_#{size}_size") do
      render_inline(Bali::[Name]::Component.new(size: size))
      assert_selector(".#{css_class.split.first}")
    end
  end

  # === Slots ===

  def test_renders_slot_content
    render_inline(Bali::[Name]::Component.new) do |c|
      c.with_[slot_name] { "Slot content" }
    end
    assert_text("Slot content")
  end

  # === Options passthrough ===

  def test_accepts_custom_classes
    render_inline(Bali::[Name]::Component.new(class: "custom-class"))
    assert_selector(".custom-class")
  end

  def test_accepts_data_attributes
    render_inline(Bali::[Name]::Component.new(data: { testid: "my-component" }))
    assert_selector('[data-testid="my-component"]')
  end
end
```

#### 3D: Fix Preview Examples

Update preview to use correct API:

```ruby
# Before (incorrect API)
c.with_column(class: 'is-half') { ... }

# After (correct param-based API)
c.with_column(size: :half) { ... }

# Or if keeping class passthrough
c.with_column(class: 'w-1/2') { ... }
```

#### 3E: Fix JavaScript/Stimulus Issues

1. Check controller is registered
2. Verify data-controller attribute in template
3. Test all actions work
4. Check for console errors

### Step 4: Verify Fixes

After applying fixes:

1. Run `lsp_diagnostics` on changed files
2. Run component tests: `bin/rails test test/bali/components/[name]_test.rb`
3. Visual check in Lookbook

### Step 5: Delegate Visual Polish (if needed)

If design issues remain after functional fixes, delegate to `frontend-ui-ux-engineer`:

```
## TASK
Polish the visual design of [ComponentName] after functional fixes.

## CONTEXT
- Component: Bali::[ComponentName]::Component  
- Functional issues have been fixed
- Need visual polish and DaisyUI consistency check

## MUST DO
- Verify component looks correct in Lookbook
- Check spacing, colors, typography
- Ensure hover/focus states work
- Test responsive behavior

## MUST NOT DO
- Do not break functional fixes already applied
- Do not remove existing Tailwind classes without replacement
```

### Step 6: Generate Fix Report

```markdown
# Fix Report: [ComponentName]

## Changes Applied

### Files Modified
| File | Changes |
|------|---------|
| component.rb | Added SIZES constant, size param, DaisyUI classes |
| preview.rb | Updated examples to use new API |
| [name]_test.rb | Created with X test cases |

### Tests
- Added: X new test cases
- Passing: X/X

## Verification Status
- [ ] LSP diagnostics clean
- [ ] Tests passing  
- [ ] Visual check in Lookbook

## Next Steps
- Run `/verify-component [name]` to confirm all issues resolved
```

## Example Execution

```
User: /fix-component Columns

AI: Fixing Bali::Columns::Component based on verification findings...

## Issues Identified
1. Missing size/offset params in Column component
2. No tests exist
3. Preview uses incorrect API

## Applying Fixes

### 1. Updating Column::Component

Adding size and offset mappings:

```ruby
# app/components/bali/columns/column/component.rb
SIZES = {
  half: 'w-1/2',
  third: 'w-1/3',
  two_thirds: 'w-2/3',
  quarter: 'w-1/4',
  narrow: 'w-auto'
}.freeze

OFFSETS = {
  quarter: 'ml-[25%]',
  third: 'ml-[33.33%]',
  half: 'ml-[50%]'
}.freeze

def initialize(size: nil, offset: nil, **options)
  @size = size&.to_sym
  @offset = offset&.to_sym
  @options = prepend_class_name(options, column_classes)
end

def column_classes
  class_names(
    'column min-w-0',
    size_class,
    OFFSETS[@offset]
  )
end

private

def size_class
  @size ? "#{SIZES[@size]} flex-none" : 'flex-1'
end
```

### 2. Updating Preview

[Shows updated preview.rb]

### 3. Generating Tests

[Shows new [name]_test.rb]

### 4. Running Verification

```bash
bin/rails test test/bali/components/columns_test.rb
```
✓ 77 runs, 117 assertions, 0 failures, 0 errors, 0 skips

## Fix Report

All issues addressed. Run `/verify-component Columns` to confirm.
```
