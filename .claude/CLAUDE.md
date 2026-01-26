# Bali ViewComponents Development Guide

This file provides guidance to AI coding agents working with the Bali ViewComponents library.

## AFAL Design System Reference

**CRITICAL**: When building or modifying components, reference the AFAL handbook design system to ensure alignment with the purchased DaisyUI templates (Nexus and Scalo).

| Resource | Location | Purpose |
|----------|----------|---------|
| **Design System Catalog** | `handbook/design-system/DESIGN-SYSTEM.md` | Complete component inventory |
| **daisyUI 5 Reference** | `handbook/design-system/nexus-html@3.2.0/.clinerules/daisyui.md` | Official daisyUI class reference |
| **Admin Patterns** | `handbook/design-system/nexus-html@3.2.0/src/partials/` | Dashboard, tables, forms |
| **Marketing Patterns** | `handbook/design-system/scalo-html@3.1.0/src/partials/` | Landing pages, pricing |
| **Local Reference** | `docs/reference/afal-design-system.md` | Bali ↔ Design system alignment |

### Quick Pattern Lookup

| Building... | Check Template |
|-------------|----------------|
| Stats/metric cards | `nexus/partials/blocks/stats/` |
| Data tables | `nexus/partials/interactions/datatables/` |
| AI prompt inputs | `nexus/partials/blocks/prompt-bar/` |
| Pricing sections | `scalo/partials/*/pricing.html` |
| Hero sections | `scalo/partials/*/hero.html` |
| Testimonials | `scalo/partials/*/testimonials.html` |

## Shared Documentation

Reference documentation is maintained in `docs/` for use by both Claude Code and OpenCode:

| Document | Purpose |
|----------|---------|
| `docs/reference/afal-design-system.md` | AFAL design system alignment guide |
| `docs/reference/daisyui-mapping.md` | Bulma → DaisyUI class mappings (single source of truth) |
| `docs/reference/component-patterns.md` | Standard ViewComponent patterns |
| `docs/reference/stimulus-patterns.md` | Stimulus controller patterns |
| `docs/guides/accessibility.md` | WCAG 2.1 accessibility standards |

## Available Commands

### Migration Workflow
| Command | Description |
|---------|-------------|
| `/migrate-component [name]` | Migrate component from Bulma to DaisyUI |
| `/component-cycle [name]` | Full verify→fix→review loop |
| `/fix-component [name]` | Fix issues in a component |
| `/verify-component [name]` | Visual and functional verification |

### Quality & Review
| Command | Description |
|---------|-------------|
| `/review [name]` | Code review against DHH standards |
| `/review-cycle [name]` | Autonomous review→fix loop until score ≥ 9, then commit & push |
| `/review-all` | Batch review multiple components in parallel |
| `/a11y [name]` | Accessibility audit (WCAG 2.1) |
| `/audit` | Full library status audit |
| `/test [name]` | Run component tests |

### Batch Processing (Shell Script)
```bash
# Review all components (code-only, parallel)
./scripts/batch-review.sh

# Review specific components
./scripts/batch-review.sh Button Modal Card

# With visual verification (slower, needs port coordination)
./scripts/batch-review.sh --with-visual --parallel 4

# Dry run to see what would happen
./scripts/batch-review.sh --dry-run
```

### Documentation & Release
| Command | Description |
|---------|-------------|
| `/docs [name]` | Generate API documentation |
| `/release [patch\|minor\|major]` | Release new gem version |
| `/deprecate [name]` | Mark component/param deprecated |

### Development
| Command | Description |
|---------|-------------|
| `/component [name]` | Create new component |
| `/pr` | Create pull request |

## Project Overview

**Bali** is AFAL's open-source ViewComponent library providing 40+ reusable UI components for Rails applications.

| Aspect | Details |
|--------|---------|
| **Type** | Ruby gem (Rails engine) |
| **Components** | 40+ ViewComponents |
| **Current CSS** | Bulma (SCSS) |
| **Target CSS** | Tailwind + DaisyUI |
| **JavaScript** | Stimulus controllers |
| **Testing** | RSpec + Cypress |
| **Preview** | Lookbook |

## Project Structure

```
bali/
├── app/
│   ├── components/bali/       # ViewComponents (Ruby + ERB)
│   ├── assets/
│   │   ├── javascripts/       # Stimulus controllers
│   │   └── stylesheets/       # SCSS (Bulma-based)
│   └── helpers/
├── lib/
│   └── bali_view_components/  # Gem configuration
├── spec/
│   ├── components/            # RSpec component tests
│   └── dummy/                 # Dummy Rails app for testing
└── cypress/                   # JavaScript/integration tests
```

## Development Commands

```bash
# Run RSpec tests
bundle exec rspec

# Run specific component test
bundle exec rspec spec/components/bali/button_spec.rb

# Start Lookbook preview server
cd spec/dummy && bin/dev
# Open http://localhost:3001/lookbook

# Run Cypress tests (requires server running)
yarn run cy:run   # Headless
yarn run cy:open  # Interactive
```

## Current Migration: Bulma → Tailwind + DaisyUI

We are migrating all components from Bulma CSS to Tailwind + DaisyUI. This is a major initiative.

### CRITICAL: Per-Component Migration Workflow (NON-NEGOTIABLE)

**DO NOT BATCH COMPONENTS. Process ONE component through the FULL pipeline before starting the next.**

#### Step-by-Step Cycle (BLOCKING - must complete each step)

```
1. CREATE BRANCH
   git checkout tailwind-migration
   git checkout -b migrate/[component-name]

2. EDIT COMPONENT FILES
   - component.rb (update class mappings)
   - component.html.erb (update classes)
   - component.scss (remove Bulma, keep custom)
   - preview.rb (update for new variants)

3. UPDATE TESTS
   - Update spec expectations for new DaisyUI classes
   - DO NOT delete tests to make them pass

4. RUN RSPEC (BLOCKING)
   bundle exec rspec spec/bali/components/[name]_spec.rb
   └─ FAIL? → Fix code, re-run. Do NOT proceed until green.

5. RUN RUBOCOP
   bundle exec rubocop app/components/bali/[name]/ --autocorrect-all

6. VISUAL VERIFICATION WITH PLAYWRIGHT (BLOCKING - DO NOT SKIP)
   Use Playwright MCP to:
   a) Navigate to http://localhost:3001/lookbook/inspect/bali/[name]/default
   b) Wait for page load
   c) Take screenshot: browser_take_screenshot
   d) Check console errors: browser_console_messages
   e) Navigate to each variant and screenshot
   
   └─ Console errors? → Fix before proceeding
   └─ Component not rendering? → Fix before proceeding

7. COMMIT WITH EVIDENCE
   git add app/components/bali/[name]/ spec/bali/components/[name]_spec.rb
   git commit -m "Migrate [Name] component from Bulma to DaisyUI
   
   - [List changes made]
   
   Verification:
   - RSpec: ✓ N examples, 0 failures
   - Rubocop: ✓ 0 offenses
   - Visual: ✓ Lookbook renders correctly"

8. RETURN TO BASE
   git checkout tailwind-migration

9. START NEXT COMPONENT (repeat from step 1)
```

#### Anti-Patterns (BLOCKING VIOLATIONS)

| ❌ DON'T | ✅ DO |
|----------|-------|
| Edit multiple components before verifying | Complete full cycle for ONE component |
| Skip Playwright visual verification | ALWAYS verify in Lookbook with screenshots |
| Commit directly to tailwind-migration | Create `migrate/[name]` branch per component |
| Batch commits across components | One commit per component with evidence |
| Delete failing tests | Fix code to make tests pass |
| Proceed with console errors | Fix errors before committing |

#### Lookbook URLs

- Base: `http://localhost:3001/lookbook`
- Component inspect: `http://localhost:3001/lookbook/inspect/bali/[name]/default`
- Variants: `http://localhost:3001/lookbook/inspect/bali/[name]/[variant]`

### Migration Status

Migration is in progress. Current status:
- **3 Fully Verified**: ActionsDropdown, AdvancedFilters (new), Columns
- **21 Partially Migrated**: Most core components have initial DaisyUI migration
- **34 Pending Verification**: Need visual/functional verification

Track detailed progress in `MIGRATION_STATUS.md` and `README.md`.

### Class Mapping Reference

**See `docs/reference/daisyui-mapping.md` for the complete mapping reference.**

Key mappings (quick reference):

| Bulma | DaisyUI | Notes |
|-------|---------|-------|
| `is-danger` | `*-error` | DaisyUI uses "error" not "danger" |
| `is-small/medium/large` | `*-sm/md/lg` | Use abbreviated sizes |
| `columns` | `grid grid-cols-12` | Use CSS Grid, not Flexbox |
| `card-content` | `card-body` | Different naming |
| `notification` | `alert` | Different naming |

### Migration Workflow

When migrating a component:

1. **Read current implementation** - Understand Bulma classes used
2. **Map to DaisyUI** - Use the table above
3. **Update Ruby class** - Change variant/class mappings
4. **Update ERB template** - Apply new classes
5. **Update SCSS** - Remove/migrate custom styles
6. **Update preview** - Ensure Lookbook preview works
7. **Run tests** - `bundle exec rspec spec/components/bali/[component]_spec.rb`
8. **Visual verification** - Check in Lookbook

### Migration Example

**Before (Bulma):**

```ruby
# app/components/bali/button/component.rb
VARIANTS = {
  primary: "is-primary",
  success: "is-success",
  danger: "is-danger",
  warning: "is-warning",
  info: "is-info",
  link: "is-link",
  outline: "is-outlined"
}.freeze

SIZES = {
  small: "is-small",
  medium: "is-medium",
  large: "is-large"
}.freeze

def button_classes
  ["button", VARIANTS[@variant], SIZES[@size], @loading ? "is-loading" : nil].compact.join(" ")
end
```

**After (DaisyUI):**

```ruby
# app/components/bali/button/component.rb
VARIANTS = {
  primary: "btn-primary",
  secondary: "btn-secondary",
  accent: "btn-accent",
  success: "btn-success",
  warning: "btn-warning",
  error: "btn-error",
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

def button_classes
  [
    "btn",
    VARIANTS[@variant],
    SIZES[@size],
    @loading ? "loading loading-spinner" : nil,
    @disabled ? "btn-disabled" : nil
  ].compact.join(" ")
end
```

## Component Patterns

### Standard Component Structure

```
app/components/bali/
└── button/
    ├── component.rb           # Ruby class
    ├── component.html.erb     # Template
    ├── component.scss         # Styles (migrating away)
    └── preview.rb             # Lookbook preview
```

### Component Class Template (DaisyUI)

```ruby
# app/components/bali/example/component.rb
module Bali
  module Example
    class Component < ApplicationComponent
      VARIANTS = {
        default: "",
        primary: "example-primary"
      }.freeze

      def initialize(variant: :default, **options)
        @variant = variant
        @options = options
      end

      private

      def component_classes
        class_names(
          "example-base",
          VARIANTS[@variant],
          @options[:class]
        )
      end
    end
  end
end
```

### Slot Usage

```ruby
# Component with slots
module Bali
  module Card
    class Component < ApplicationComponent
      renders_one :header
      renders_one :body
      renders_one :footer
      renders_many :actions

      def initialize(variant: :default, shadow: true, **options)
        @variant = variant
        @shadow = shadow
        @options = options
      end
    end
  end
end
```

```erb
<%# Template with slots %>
<div class="<%= card_classes %>">
  <% if header? %>
    <div class="card-title px-6 pt-6"><%= header %></div>
  <% end %>
  
  <div class="card-body">
    <%= body.present? ? body : content %>
  </div>
  
  <% if footer? || actions? %>
    <div class="card-actions justify-end px-6 pb-6">
      <%= footer %>
      <% actions.each do |action| %>
        <%= action %>
      <% end %>
    </div>
  <% end %>
</div>
```

## Testing

### RSpec Component Test

```ruby
# spec/components/bali/button/component_spec.rb
RSpec.describe Bali::Button::Component, type: :component do
  it "renders a button with default classes" do
    render_inline(described_class.new) { "Click me" }
    
    expect(page).to have_css("button.btn")
    expect(page).to have_text("Click me")
  end

  it "applies primary variant" do
    render_inline(described_class.new(variant: :primary)) { "Save" }
    
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
end
```

### Lookbook Preview

**Use Lookbook params to reduce the number of preview methods.** Instead of creating separate methods for each variant, use `@param` annotations to make previews interactive.

```ruby
# app/components/bali/button/preview.rb
module Bali
  module Button
    class Preview < Lookbook::Preview
      # @param variant select { choices: [primary, secondary, success, warning, error] }
      # @param size select { choices: [xs, sm, md, lg] }
      # @param loading toggle
      # @param disabled toggle
      def default(variant: :primary, size: :md, loading: false, disabled: false)
        render Bali::Button::Component.new(
          name: 'Button',
          variant: variant.to_sym,
          size: size.to_sym,
          loading: loading,
          disabled: disabled
        )
      end
    end
  end
end
```

#### Param Types

| Type | Syntax | Example |
|------|--------|---------|
| Select dropdown | `@param name select { choices: [a, b, c] }` | `@param size select { choices: [sm, md, lg] }` |
| Toggle (boolean) | `@param name toggle` | `@param loading toggle` |
| Text input | `@param name text` | `@param label text` |
| Number input | `@param name number` | `@param count number` |

#### When to Create Separate Preview Methods

Only create separate preview methods when:
- The preview requires significantly different template markup
- You need to demonstrate a specific integration (e.g., "with_sorting" needs real DB data)
- The combination of params would be confusing in a single preview

**❌ DON'T** create: `small_button`, `medium_button`, `large_button`, `primary_button`, etc.
**✅ DO** use: One `default` method with `@param size` and `@param variant`

### Lookbook Notes

Comments (not tags) above preview methods are rendered as Markdown in the Notes panel. **Be critical** - only include notes that help developers use the component correctly.

#### When to Add Notes

**✅ DO add notes for:**
- Required dependencies (JS libraries, backend setup)
- Non-obvious behavior or gotchas
- Accessibility requirements
- Code examples showing usage

**❌ DON'T add notes for:**
- Implementation details consumers don't need
- Obvious information clear from the preview
- Internal development notes

```ruby
# @label With Sorting
# Sorting requires a `Bali::FilterForm` instance:
# ```ruby
# filter_form = Bali::FilterForm.new(Movie.all, params)
# ```
# Add `sort: :column_name` to `with_header` to make columns sortable.
def with_sorting(q: {})
  # ...
end
```

### Lookbook Preview Best Practices

**URLs in Previews**: Use hardcoded paths like `/lookbook` for navigation URLs. Do NOT use `helpers.request.path` - it causes "undefined method" errors in preview context.

```ruby
# ❌ BAD - causes undefined method error
c.with_header(route_path: helpers.request.path)

# ✅ GOOD - hardcoded path works reliably
c.with_header(route_path: '/lookbook')
```

**Form URLs in Templates**: In ERB templates (not previews), use `request.path` for form actions:

```erb
<%# In template files - this works because templates have request context %>
<%= render MyComponent.new(url: request.path) %>
```

**Why this matters**: Lookbook previews run in a different context than normal Rails requests. The `helpers` proxy doesn't have access to `request` in all preview scenarios. Using hardcoded paths ensures previews always render.

**Avoid `safe_join` in Preview Blocks**: Using `safe_join` inside component blocks in previews often prints raw HTML instead of rendering it. Use `render_with_template` with an ERB file instead.

```ruby
# ❌ BAD - safe_join in blocks prints raw HTML
def with_slots
  render MyComponent.new do |c|
    c.with_footer do
      safe_join([
        render(Bali::Button::Component.new(name: 'Cancel')),
        render(Bali::Button::Component.new(name: 'Save'))
      ])
    end
  end
end

# ✅ GOOD - use render_with_template with ERB file
def with_slots
  render_with_template(locals: { active: true })
end
```

Template file at `previews/with_slots.html.erb`:
```erb
<%%= render MyComponent.new do |c| %>
  <%% c.with_footer do %>
    <%%= render Bali::Button::Component.new(name: 'Cancel') %>
    <%%= render Bali::Button::Component.new(name: 'Save') %>
  <%% end %>
<%% end %>
```

**Wrapper HTML for Interactive Components**: When previewing dropdowns, tooltips, or popovers, use `render_with_template` to add centering/padding so menus have space to expand. Do NOT use `tag.div` blocks in preview methods - they cause "no implicit conversion of Symbol into Integer" errors.

```ruby
# ❌ BAD - tag.div blocks fail in preview methods
def default
  tag.div(class: 'flex justify-center p-8') do
    render Dropdown::Component.new { ... }
  end
end

# ✅ GOOD - use render_with_template with ERB file
def default
  render_with_template
end
```

Template file at `previews/default.html.erb`:
```erb
<div class="flex justify-center items-center min-h-[250px] p-8">
  <%%= render Bali::Dropdown::Component.new do |c|
    c.with_trigger { 'Click me' }
    c.with_item(href: '#') { 'Item 1' }
  end %>
</div>
```

**Database Access**: Previews can access ActiveRecord models from the dummy app:

```ruby
# preview.rb
def with_real_data
  filter_form = Bali::FilterForm.new(Movie.all, params)
  pagy, records = pagy(filter_form.result, items: 5)

  render_with_template(locals: { records: records, pagy: pagy })
end
```

**Pagination**: Use Pagy (~> 8.0) - configured in `spec/dummy/config/initializers/pagy.rb`:
- Include `Pagy::Backend` in ApplicationController
- Include `Pagy::Frontend` in ApplicationHelper

**Sorting**: Use Ransack's `sort_link` helper with `Bali::FilterForm`:

```erb
<%= render Bali::Table::Component.new(form: filter_form) do |t| %>
  <%= t.with_header(name: 'Name', sort: :name) %>  <%# Sortable %>
  <%= t.with_header(name: 'Status') %>              <%# Not sortable %>
<% end %>
```

## Stimulus Controllers

### Controller Structure

```javascript
// app/assets/javascripts/bali/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]
  static values = { open: Boolean }

  open() {
    this.dialogTarget.showModal()
    this.openValue = true
  }

  close() {
    this.dialogTarget.close()
    this.openValue = false
  }

  // Close on backdrop click
  backdropClick(event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }

  // Close on escape key
  keydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
```

## Pre-Commit Checklist

Before committing changes:

```bash
# 1. Run RSpec tests
bundle exec rspec

# 2. Run Rubocop
bundle exec rubocop -a

# 3. Check Lookbook preview works
cd spec/dummy && bin/dev
# Verify component renders correctly

# 4. Run Cypress tests (if JS changes)
yarn run cy:run
```

## Prohibited Patterns

| DON'T | DO INSTEAD |
|-------|------------|
| Add inline styles | Use Tailwind/DaisyUI classes |
| Create complex Stimulus controllers | Keep controllers focused |
| Mix Bulma and DaisyUI classes | Fully migrate to DaisyUI |
| Skip preview updates | Always update Lookbook preview |
| Skip tests | Always run RSpec after changes |
| Use jQuery | Use vanilla JS or Stimulus |

## Component Composition (CRITICAL)

**ALWAYS use existing Bali components instead of raw HTML with DaisyUI classes.** This ensures consistency, maintainability, and leverages built-in accessibility features.

### Common Composition Mistakes

| ❌ DON'T USE | ✅ USE INSTEAD |
|--------------|----------------|
| `<div class="card">...</div>` | `<%= render Bali::Card::Component.new %>` |
| `<span class="badge">text</span>` | `<%= render Bali::Tag::Component.new(text: 'text') %>` |
| `<button class="btn">...</button>` | `<%= render Bali::Button::Component.new %>` |
| `<a class="link">...</a>` | `<%= render Bali::Link::Component.new %>` |
| `<div class="alert">...</div>` | `<%= render Bali::Notification::Component.new %>` |
| `<table class="table">...</table>` | `<%= render Bali::Table::Component.new %>` |
| `<div class="dropdown">...</div>` | `<%= render Bali::Dropdown::Component.new %>` |
| `<dialog class="modal">...</dialog>` | `<%= render Bali::Modal::Component.new %>` |

### Example: Building a Grid View

```erb
<%# ❌ BAD: Raw HTML %>
<div class="card bg-base-100 shadow">
  <div class="card-body">
    <span class="badge badge-primary">Tag</span>
  </div>
</div>

<%# ✅ GOOD: Using Bali components %>
<%= render Bali::Card::Component.new(style: :bordered) do %>
  <div class="card-body">
    <%= render Bali::Tag::Component.new(text: 'Tag', color: :primary) %>
  </div>
<% end %>
```

### Before Writing Raw HTML

1. Check the Component Catalog below for an existing component
2. If a component exists, use it even if it requires learning its API
3. Only use raw HTML for truly custom layouts not covered by existing components

### Button vs Link (CRITICAL)

Use the correct component based on **what the element does**, not how it looks:

| Use Case | Component | Renders | Example |
|----------|-----------|---------|---------|
| **Navigation** (goes to URL) | `Bali::Link::Component` | `<a>` | "View Details", "Go Back" |
| **Action** (triggers behavior) | `Bali::Button::Component` | `<button>` | "Submit", "Cancel", "Close Modal" |
| **Link styled as button** | `Bali::Link::Component` with `type:` | `<a class="btn">` | "Create New" (navigates to /new) |

```erb
<%# ✅ CORRECT: Button for actions %>
<%= render Bali::Button::Component.new(name: 'Cancel', variant: :ghost, data: { action: 'modal#close' }) %>
<%= render Bali::Button::Component.new(name: 'Save', variant: :primary, type: :submit) %>

<%# ✅ CORRECT: Link for navigation %>
<%= render Bali::Link::Component.new(name: 'View Users', href: '/users', type: :primary) %>

<%# ❌ WRONG: Link for action (accessibility issue) %>
<%= render Bali::Link::Component.new(name: 'Cancel', href: '#', data: { action: 'modal#close' }) %>
```

**Why this matters:**
- Screen readers announce buttons and links differently
- Keyboard navigation: buttons activate with Space/Enter, links only with Enter
- Links with `href="#"` are an accessibility anti-pattern

## Icons

The Bali icon system uses **Lucide icons** as the primary source, with backwards compatibility for existing icon names.

### Icon Resolution Pipeline

When you use `Bali::Icon::Component.new('icon-name')`, the system resolves icons in this order:

1. **Lucide mapping** - Old Bali names mapped to Lucide equivalents (e.g., `edit` → `pencil`)
2. **Direct Lucide** - Use any [Lucide icon](https://lucide.dev/icons) name directly
3. **Kept icons** - Brand logos, regional icons, custom domain icons
4. **Legacy fallback** - Original Bali SVGs for full backwards compatibility

### Using Icons

```erb
<%# Old Bali names still work (mapped to Lucide) %>
<%= render Bali::Icon::Component.new('edit') %>
<%= render Bali::Icon::Component.new('trash') %>

<%# Or use Lucide names directly (1,600+ icons available) %>
<%= render Bali::Icon::Component.new('activity') %>
<%= render Bali::Icon::Component.new('git-branch') %>

<%# With size %>
<%= render Bali::Icon::Component.new('check', size: :large) %>
```

### Icon Categories

| Category | Source | Examples |
|----------|--------|----------|
| **UI Icons** | Lucide (via mapping) | `edit`, `trash`, `search`, `check`, `times` |
| **Direct Lucide** | Lucide | Any icon from [lucide.dev/icons](https://lucide.dev/icons) |
| **Payment Brands** | Kept SVGs | `visa`, `mastercard`, `american-express`, `paypal`, `oxxo` |
| **Social Brands** | Kept SVGs | `whatsapp`, `facebook`, `youtube`, `twitter`, `linkedin` |
| **Regional** | Kept SVGs | `mexico-flag`, `us-flag` |
| **Custom Domain** | Kept SVGs | `recipe-book`, `diagnose`, `day`, `month`, `week` |

### Key Files

| File | Purpose |
|------|---------|
| `app/components/bali/icon/lucide_mapping.rb` | Maps old Bali names → Lucide names |
| `app/components/bali/icon/kept_icons.rb` | Brand, regional, and custom icons |
| `app/components/bali/icon/component.rb` | Resolution pipeline |

### Common Mappings

| Old Bali Name | Lucide Name | Notes |
|---------------|-------------|-------|
| `edit` | `pencil` | |
| `trash` | `trash-2` | |
| `cog` | `settings` | |
| `times` | `x` | |
| `check-circle` | `circle-check` | |
| `info-circle` | `info` | |
| `alert` | `triangle-alert` | |

**Full mapping:** See `app/components/bali/icon/lucide_mapping.rb`

## File Naming

| Type | Convention | Example |
|------|------------|---------|
| Component | `module/component.rb` | `bali/button/component.rb` |
| Template | `component.html.erb` | `component.html.erb` |
| Styles | `component.scss` | `component.scss` |
| Preview | `preview.rb` | `preview.rb` |
| Test | `component_spec.rb` | `button/component_spec.rb` |
| Controller | `[name]_controller.js` | `modal_controller.js` |

## Resources

- [ViewComponent Docs](https://viewcomponent.org/)
- [DaisyUI Components](https://daisyui.com/components/)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [Lookbook](https://lookbook.build/)
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)

---

## Bali Component Catalog

### Layout Components

| Component | Purpose | DaisyUI Classes | Design System Pattern |
|-----------|---------|-----------------|----------------------|
| `Bali::Card` | Content container | `card bg-base-100 card-border` | `nexus/blocks/stats/` |
| `Bali::Columns` | Grid layout | `grid grid-cols-12 gap-*` | Tailwind grid |
| `Bali::Drawer` | Side panel | `drawer drawer-content drawer-side` | `nexus/layouts/sidebar/` |
| `Bali::Hero` | Hero section | Custom Tailwind | `scalo/*/hero.html` |
| `Bali::Level` | Horizontal layout | `flex items-center justify-between` | Tailwind flex |
| `Bali::Modal` | Dialog/modal | `modal modal-box modal-action` | daisyUI modal |
| `Bali::PageHeader` | Page header | Custom Tailwind | `nexus/layouts/page-title/` |

### Navigation Components

| Component | Purpose | DaisyUI Classes | Design System Pattern |
|-----------|---------|-----------------|----------------------|
| `Bali::Breadcrumb` | Navigation breadcrumb | `breadcrumbs` | daisyUI breadcrumbs |
| `Bali::Dropdown` | Dropdown menu | `dropdown dropdown-content menu` | daisyUI dropdown |
| `Bali::NavBar` | Navigation bar | `navbar navbar-start/center/end` | `nexus/layouts/topbar/` |
| `Bali::SideMenu` | Sidebar menu | `menu` | `nexus/layouts/sidebar/` |
| `Bali::Tabs` | Tab navigation | `tabs tabs-box tab` | daisyUI tabs |
| `Bali::Stepper` | Step indicator | `steps step step-*` | daisyUI steps |

### Data Display Components

| Component | Purpose | DaisyUI Classes | Design System Pattern |
|-----------|---------|-----------------|----------------------|
| `Bali::Avatar` | User avatar | `avatar` | daisyUI avatar |
| `Bali::BooleanIcon` | Boolean indicator | Custom icons | — |
| `Bali::Chart` | Data charts | (ApexCharts) | `nexus/components-apex-charts-*` |
| `Bali::DataTable` | Data table | `table table-zebra` | `nexus/interactions/datatables/` |
| `Bali::GanttChart` | Gantt chart | Custom | — |
| `Bali::Heatmap` | Heatmap display | Custom | — |
| `Bali::Icon` | Icon display | `iconify lucide--*` | Iconify Lucide |
| `Bali::ImageGrid` | Image gallery | Grid layout | — |
| `Bali::InfoLevel` | Info display | Custom | — |
| `Bali::LabelValue` | Label/value pair | Custom Tailwind | — |
| `Bali::List` | List display | `list list-row` | daisyUI list |
| `Bali::Progress` | Progress bar | `progress progress-*` | daisyUI progress |
| `Bali::PropertiesTable` | Property table | `table` | — |
| `Bali::Rate` | Rating display | `rating` | daisyUI rating |
| `Bali::Table` | Basic table | `table` | daisyUI table |
| `Bali::Timeline` | Timeline | `timeline timeline-*` | daisyUI timeline |
| `Bali::TreeView` | Tree structure | Custom | — |

### Interactive Components

| Component | Purpose | DaisyUI Classes | Design System Pattern |
|-----------|---------|-----------------|----------------------|
| `Bali::ActionsDropdown` | Action menu | `dropdown menu` | daisyUI dropdown |
| `Bali::AdvancedFilters` | Complex filter UI | `btn input select dropdown badge join` | Ransack groupings |
| `Bali::BulkActions` | Bulk actions | Custom | — |
| `Bali::Button` | Action button | `btn btn-*` | daisyUI button |
| `Bali::Calendar` | Calendar picker | (Flatpickr) | — |
| `Bali::Carousel` | Image carousel | `carousel carousel-item` | `nexus/interactions/carousel/` |
| `Bali::Clipboard` | Copy to clipboard | Custom + Stimulus | `nexus/interactions/clipboard/` |
| `Bali::DeleteLink` | Delete confirmation | `btn btn-error` | — |
| `Bali::Filters` | Filter controls (DEPRECATED - use AdvancedFilters) | Custom | — |
| `Bali::HoverCard` | Hover popup | Custom | — |
| `Bali::Link` | Styled link | `link link-*` | daisyUI link |
| `Bali::Reveal` | Show/hide content | Custom + Stimulus | — |
| `Bali::SearchInput` | Search field | `input` | `nexus/layouts/search/` |
| `Bali::SortableList` | Drag-drop list | Custom + SortableJS | `nexus/interactions/sortable/` |
| `Bali::Tooltip` | Tooltip | `tooltip tooltip-*` | daisyUI tooltip |

### Feedback Components

| Component | Purpose | DaisyUI Classes | Design System Pattern |
|-----------|---------|-----------------|----------------------|
| `Bali::FlashNotifications` | Flash messages | `alert alert-*` | daisyUI alert |
| `Bali::Loader` | Loading indicator | `loading loading-*` | daisyUI loading |
| `Bali::Message` | Message display | `alert` | daisyUI alert |
| `Bali::Notification` | Notification | `alert alert-*` | daisyUI alert |

### Form Components

| Component | Purpose | DaisyUI Classes | Design System Pattern |
|-----------|---------|-----------------|----------------------|
| `Bali::Form::*` | Form elements | `input select textarea checkbox radio` | daisyUI form elements |
| `Bali::ImageField` | Image upload | Custom | `nexus/interactions/file-upload/` |
| `Bali::RichTextEditor` | Rich text | (Trix) | `nexus/interactions/text-editor/` |

### Utility Components

| Component | Purpose | DaisyUI Classes | Design System Pattern |
|-----------|---------|-----------------|----------------------|
| `Bali::Tag` | Tag/label | `badge badge-*` | daisyUI badge |
| `Bali::Tags` | Tag list | `badge` collection | — |
| `Bali::Timeago` | Relative time | Custom | — |
| `Bali::LocationsMap` | Map display | (Google Maps) | — |

---

## Stimulus Controllers

| Controller | Purpose | Usage |
|------------|---------|-------|
| `AdvancedFilters` | Main filter UI controller | `data-controller="advanced-filters"` |
| `AutoPlay` | Auto-play audio | `data-controller="auto-play"` |
| `AutocompleteAddress` | Google Places autocomplete | `data-controller="autocomplete-address"` |
| `CheckboxToggle` | Toggle visibility with checkbox | `data-controller="checkbox-toggle"` |
| `Datepicker` | Flatpickr date picker | `data-controller="datepicker"` |
| `DynamicFields` | Dynamic form fields | `data-controller="dynamic-fields"` |
| `ElementsOverlap` | Prevent element overlap | `data-controller="elements-overlap"` |
| `FileInput` | File input display | `data-controller="file-input"` |
| `FocusOnConnect` | Auto-focus/scroll | `data-controller="focus-on-connect"` |
| `InputOnChange` | Server notification on change | `data-controller="input-on-change"` |
| `Modal` | Modal control | `data-controller="modal"` |
| `Print` | Print page | `data-controller="print"` |
| `RadioToggle` | Toggle visibility with radio | `data-controller="radio-toggle"` |
| `SlimSelect` | Slim Select dropdown | `data-controller="slim-select"` |
| `StepNumberInput` | Increment/decrement input | `data-controller="step-number-input"` |
| `SubmitButton` | Loading state on submit | `data-controller="submit-button"` |
| `SubmitOnChange` | Auto-submit on change | `data-controller="submit-on-change"` |
| `TrixAttachments` | Trix file attachments | `data-controller="trix-attachments"` |
