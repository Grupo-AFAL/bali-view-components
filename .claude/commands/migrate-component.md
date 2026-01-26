# Migrate Component from Bulma to DaisyUI

Migrate a Bali ViewComponent from Bulma CSS to Tailwind + DaisyUI.

## Usage

```
/migrate-component $ARGUMENTS
```

Where `$ARGUMENTS` is:
- Component name (e.g., `Button`, `Card`, `Modal`)
- `--dry-run` - Show changes without applying
- `--branch` - Auto-create feature branch (default: true)

## Branching Strategy

All migration work follows this structure:

```
main
  └── tailwind-migration (base branch)
        ├── tailwind-migration/infrastructure
        ├── tailwind-migration/button
        ├── tailwind-migration/card
        └── tailwind-migration/[component-name]
```

## Workflow

### Step 1: Create Feature Branch

```bash
# Ensure we're on the base migration branch
git checkout tailwind-migration
git pull origin tailwind-migration 2>/dev/null || true

# Create component-specific branch
git checkout -b tailwind-migration/[component-name]
```

### Step 2: Analyze Current Component

Read and understand:
1. `app/components/bali/[name]/component.rb` - Ruby class
2. `app/components/bali/[name]/component.html.erb` - Template
3. `app/components/bali/[name]/component.scss` - Styles (if exists)
4. `app/components/bali/[name]/preview.rb` - Lookbook preview
5. `spec/components/bali/[name]/component_spec.rb` - Tests

Document:
- Current Bulma classes used
- Variants and sizes
- Slots defined
- Stimulus controllers used
- Custom CSS

### Step 3: Map Bulma to DaisyUI

Use this reference:

| Bulma | DaisyUI | Notes |
|-------|---------|-------|
| `button` | `btn` | Base class |
| `is-primary` | `btn-primary` | |
| `is-success` | `btn-success` | |
| `is-danger` | `btn-error` | danger → error |
| `is-warning` | `btn-warning` | |
| `is-info` | `btn-info` | |
| `is-outlined` | `btn-outline` | |
| `is-small` | `btn-sm` | |
| `is-medium` | `btn-md` | |
| `is-large` | `btn-lg` | |
| `is-loading` | `loading loading-spinner` | |
| `card` | `card bg-base-100` | Add bg |
| `card-header` | (use card-title in card-body) | Restructure |
| `card-content` | `card-body` | |
| `card-footer` | `card-actions` | |
| `modal` | `modal` | Same |
| `modal-card` | `modal-box` | |
| `modal-card-head` | (elements in modal-box) | Restructure |
| `modal-card-body` | (content in modal-box) | Direct |
| `modal-card-foot` | `modal-action` | |
| `notification` | `alert` | |
| `is-success` (notif) | `alert-success` | |
| `is-danger` (notif) | `alert-error` | |
| `navbar` | `navbar` | Same |
| `tabs` | `tabs tabs-boxed` | |
| `tag` | `badge` | |
| `table` | `table` | Same |
| `is-striped` | `table-zebra` | |
| `input` | `input input-bordered` | |
| `select` | `select select-bordered` | |
| `field` | `form-control` | |
| `help` | `label-text-alt` | |
| `help is-danger` | `label-text-alt text-error` | |

### Step 4: Update Ruby Component

Transform variant/size mappings:

**Before:**
```ruby
VARIANTS = {
  primary: "is-primary",
  success: "is-success",
  danger: "is-danger"
}.freeze

SIZES = {
  small: "is-small",
  medium: "is-medium",
  large: "is-large"
}.freeze

def component_classes
  ["button", VARIANTS[@variant], SIZES[@size]].compact.join(" ")
end
```

**After:**
```ruby
VARIANTS = {
  primary: "btn-primary",
  secondary: "btn-secondary",
  success: "btn-success",
  error: "btn-error",      # Note: danger → error
  warning: "btn-warning",
  info: "btn-info",
  ghost: "btn-ghost",
  link: "btn-link",
  outline: "btn-outline"
}.freeze

SIZES = {
  xs: "btn-xs",
  sm: "btn-sm",
  md: "btn-md",
  lg: "btn-lg"
}.freeze

def component_classes
  class_names(
    "btn",
    VARIANTS[@variant],
    SIZES[@size],
    @loading && "loading loading-spinner",
    @disabled && "btn-disabled",
    @options[:class]
  )
end
```

### Step 5: Update ERB Template

Apply new DaisyUI class structure. Example for card:

**Before (Bulma):**
```erb
<div class="card">
  <header class="card-header">
    <p class="card-header-title"><%= title %></p>
  </header>
  <div class="card-content">
    <%= content %>
  </div>
  <footer class="card-footer">
    <%= footer %>
  </footer>
</div>
```

**After (DaisyUI):**
```erb
<div class="<%= card_classes %>">
  <div class="card-body">
    <% if title.present? %>
      <h2 class="card-title"><%= title %></h2>
    <% end %>
    <%= content %>
    <% if footer.present? %>
      <div class="card-actions justify-end">
        <%= footer %>
      </div>
    <% end %>
  </div>
</div>
```

### Step 6: Handle SCSS Migration

For component-specific SCSS:

1. **Remove Bulma overrides** - No longer needed
2. **Convert custom styles to Tailwind** - Use `@apply` or inline
3. **Keep minimal SCSS** - Only for complex animations/states

```scss
// Before: Bulma overrides
.bali-button {
  &.is-primary {
    background-color: $custom-primary;
  }
}

// After: Minimal or use Tailwind
// Most styling should be in ERB with Tailwind classes
// Only keep truly custom behavior
.bali-button {
  // Custom animations if needed
  &.animate-pulse {
    animation: pulse 2s infinite;
  }
}
```

### Step 7: Update Preview

```ruby
# app/components/bali/button/preview.rb
module Bali
  module Button
    class Preview < Lookbook::Preview
      # @param variant select [primary, secondary, success, warning, error, info, ghost, link, outline]
      # @param size select [xs, sm, md, lg]
      # @param loading toggle
      # @param disabled toggle
      def default(variant: :primary, size: :md, loading: false, disabled: false)
        render Component.new(
          variant: variant.to_sym,
          size: size.to_sym,
          loading: loading,
          disabled: disabled
        ) { "Button Text" }
      end

      # @!group Variants
      def primary
        render Component.new(variant: :primary) { "Primary" }
      end

      def secondary
        render Component.new(variant: :secondary) { "Secondary" }
      end
      # @!endgroup

      # @!group Sizes
      def all_sizes
        render_with_template
      end
      # @!endgroup
    end
  end
end
```

### Step 8: Update Tests

```ruby
# spec/components/bali/button/component_spec.rb
RSpec.describe Bali::Button::Component, type: :component do
  it "renders with DaisyUI btn class" do
    render_inline(described_class.new) { "Click" }
    expect(page).to have_css("button.btn")
  end

  it "applies primary variant" do
    render_inline(described_class.new(variant: :primary)) { "Primary" }
    expect(page).to have_css("button.btn.btn-primary")
  end

  it "applies size classes" do
    render_inline(described_class.new(size: :lg)) { "Large" }
    expect(page).to have_css("button.btn.btn-lg")
  end

  it "shows loading state" do
    render_inline(described_class.new(loading: true)) { "Loading" }
    expect(page).to have_css("button.loading")
  end

  it "applies disabled state" do
    render_inline(described_class.new(disabled: true)) { "Disabled" }
    expect(page).to have_css("button.btn-disabled")
  end
end
```

### Step 9: Verify

```bash
# Run component-specific tests
bundle exec rspec spec/components/bali/[name]/

# Run all tests to check for regressions
bundle exec rspec

# Start Lookbook and verify visually
cd spec/dummy && bin/dev
# Open http://localhost:3001/lookbook
```

### Step 10: Update README Status

Edit README.md to mark component as migrated:

```markdown
| Button | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | Migrated to DaisyUI |
```

### Step 11: Commit and Create PR

```bash
git add .
git commit -m "Migrate [ComponentName] from Bulma to DaisyUI

- Update variant/size mappings to DaisyUI classes
- Restructure template for DaisyUI patterns
- Update tests for new class names
- Update Lookbook preview
- Remove Bulma-specific SCSS"

# Push and create PR against tailwind-migration base branch
git push -u origin tailwind-migration/[component-name]
gh pr create --base tailwind-migration --title "Migrate [ComponentName] to DaisyUI" --body "..."
```

## Migration Order (Recommended)

Start with foundational components, then build up:

### Phase 1: Core (No dependencies)
1. `Icon` - Used everywhere
2. `Link` - Basic navigation
3. `Loader` - Loading states
4. `BooleanIcon` - Simple display

### Phase 2: Buttons & Forms
5. `Button` - Primary action
6. `Dropdown` - Menu patterns
7. `SearchInput` - Form element
8. `Filters` - Form patterns

### Phase 3: Layout
9. `Card` - Container pattern
10. `Modal` - Dialog pattern
11. `Drawer` - Slide-out panel
12. `Tabs` - Navigation pattern
13. `NavBar` - Top navigation
14. `SideMenu` - Side navigation

### Phase 4: Data Display
15. `Table` - Basic table
16. `DataTable` - Advanced table
17. `PropertiesTable` - Key-value display
18. `List` - List display
19. `Timeline` - Chronological
20. `TreeView` - Hierarchical

### Phase 5: Feedback
21. `Notification` - Alerts/toasts
22. `Progress` - Progress bars
23. `Tooltip` - Hover info
24. `Hovercard` - Rich hover

### Phase 6: Specialized
25+ Remaining components

## Example Execution

```
User: /migrate-component Button

AI: Starting migration of Button component to DaisyUI...

## Pre-Migration Analysis

**Current Implementation:**
- File: app/components/bali/button/component.rb
- Variants: primary, success, danger, warning, info, link, outline
- Sizes: small, medium, large
- Features: loading state, disabled state
- Bulma classes: button, is-primary, is-small, is-loading, etc.

## Creating Branch

```bash
git checkout tailwind-migration
git checkout -b tailwind-migration/button
```

## Migrating Files

### 1. component.rb
[Shows diff of changes]

### 2. component.html.erb
[Shows diff of changes]

### 3. component_spec.rb
[Shows test updates]

### 4. preview.rb
[Shows preview updates]

## Running Tests

```bash
bundle exec rspec spec/components/bali/button/
```

✓ 12 examples, 0 failures

## Summary

- Migrated Button component to DaisyUI
- Updated 4 files
- All tests passing

Next: Run `cd spec/dummy && bin/dev` to verify in Lookbook

Ready to commit? [y/n]
```
