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
   - `spec/components/bali/[name]/component_spec.rb` (if exists)

2. Identify issues from previous verification or re-run quick check

### Step 2: Classify Issues

| Issue Type | Priority | Fix Approach |
|------------|----------|--------------|
| Dead Bulma classes | Critical | Map to Tailwind equivalents |
| Missing DaisyUI classes | High | Add correct DaisyUI classes |
| Broken JS functionality | High | Fix Stimulus controller |
| Missing tests | Medium | Generate test file |
| Preview uses wrong API | Medium | Update preview examples |
| Accessibility issues | Medium | Add ARIA attributes, focus states |
| Design inconsistencies | Low | Delegate to frontend-ui-ux-engineer |

### Step 3: Apply Fixes by Category

#### 3A: Fix Bulma → Tailwind Class Mappings

**Common Mappings Reference:**

| Bulma Class | Tailwind/DaisyUI Replacement |
|-------------|------------------------------|
| **Sizing** | |
| `is-half` | `w-1/2 flex-none` or `col-span-6` |
| `is-one-third` | `w-1/3 flex-none` or `col-span-4` |
| `is-two-thirds` | `w-2/3 flex-none` or `col-span-8` |
| `is-one-quarter` | `w-1/4 flex-none` or `col-span-3` |
| `is-three-quarters` | `w-3/4 flex-none` or `col-span-9` |
| `is-narrow` | `w-auto flex-none` |
| `is-full` | `w-full` |
| **Offsets** | |
| `is-offset-one-quarter` | `ml-[25%]` or `col-start-4` |
| `is-offset-one-third` | `ml-[33.33%]` or `col-start-5` |
| `is-offset-half` | `ml-[50%]` or `col-start-7` |
| **Layout** | |
| `is-multiline` | `flex-wrap` (already in flex container) |
| `is-centered` | `justify-center` |
| `is-vcentered` | `items-center` |
| `is-gapless` | `gap-0` |
| **Display** | |
| `is-hidden` | `hidden` |
| `is-invisible` | `invisible` |
| `is-block` | `block` |
| `is-flex` | `flex` |
| **Spacing** | |
| `mb-4` (Bulma) | `mb-4` (same in Tailwind) |
| `p-4` (Bulma) | `p-4` (same in Tailwind) |
| **Colors** | |
| `has-background-primary` | `bg-primary` |
| `has-text-white` | `text-white` |
| **Box/Card** | |
| `box` | `bg-base-100 p-4 rounded-lg shadow` |
| `card` | `card bg-base-100 shadow-xl` |

**Implementation Pattern:**

```ruby
# In component.rb - Add mappings as constants
SIZES = {
  half: 'w-1/2',
  third: 'w-1/3',
  two_thirds: 'w-2/3',
  quarter: 'w-1/4',
  three_quarters: 'w-3/4',
  narrow: 'w-auto',
  full: 'w-full'
}.freeze

def initialize(size: nil, **options)
  @size = size&.to_sym
  @options = options
end

def component_classes
  class_names(
    'base-class',
    size_class,
    @options[:class]
  )
end

private

def size_class
  return 'flex-1' unless @size
  "#{SIZES[@size]} flex-none"
end
```

#### 3B: Fix Missing DaisyUI Classes

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
# spec/components/bali/[name]/component_spec.rb
RSpec.describe Bali::[Name]::Component, type: :component do
  describe 'rendering' do
    it 'renders successfully' do
      render_inline(described_class.new)
      expect(page).to have_css('[expected-selector]')
    end
  end

  describe 'sizes' do
    described_class::SIZES.each_key do |size|
      it "renders #{size} size" do
        render_inline(described_class.new(size: size))
        expect(page).to have_css(".#{described_class::SIZES[size].split.first}")
      end
    end
  end

  describe 'slots' do
    it 'renders slot content' do
      render_inline(described_class.new) do |c|
        c.with_[slot_name] { 'Slot content' }
      end
      expect(page).to have_text('Slot content')
    end
  end

  describe 'options passthrough' do
    it 'accepts custom classes' do
      render_inline(described_class.new(class: 'custom-class'))
      expect(page).to have_css('.custom-class')
    end

    it 'accepts data attributes' do
      render_inline(described_class.new(data: { testid: 'my-component' }))
      expect(page).to have_css('[data-testid="my-component"]')
    end
  end
end
```

#### 3D: Fix Preview Examples

Update preview to use correct Tailwind API:

```ruby
# Before (Bulma classes)
c.with_column(class: 'is-half') { ... }

# After (Tailwind via params)
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
2. Run component tests: `bundle exec rspec spec/components/bali/[name]/`
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
| component.rb | Added SIZES constant, size param, Tailwind mappings |
| preview.rb | Updated examples to use new API |
| component_spec.rb | Created with X test cases |

### Class Mappings Applied
| Old (Bulma) | New (Tailwind) |
|-------------|----------------|
| `is-half` | `w-1/2 flex-none` |
| ... | ... |

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
1. Dead Bulma classes: is-half, is-narrow, is-offset-*, is-multiline
2. Missing size/offset params in Column component
3. No tests exist
4. Preview uses Bulma API

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

[Shows new component_spec.rb]

### 4. Running Verification

```bash
bundle exec rspec spec/components/bali/columns/
```
✓ 8 examples, 0 failures

## Fix Report

All issues addressed. Run `/verify-component Columns` to confirm.
```
