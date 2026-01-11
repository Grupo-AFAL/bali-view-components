# Bali ViewComponents Development Guide

This file provides guidance to AI coding agents working with the Bali ViewComponents library.

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

All 40+ components are currently **Pending** migration. Track progress in README.md.

### Class Mapping Reference

| Bulma Class | DaisyUI Class | Notes |
|-------------|---------------|-------|
| `button` | `btn` | Base button |
| `is-primary` | `btn-primary` | Primary variant |
| `is-success` | `btn-success` | Success variant |
| `is-danger` | `btn-error` | Note: danger → error |
| `is-warning` | `btn-warning` | Warning variant |
| `is-info` | `btn-info` | Info variant |
| `is-outlined` | `btn-outline` | Outline variant |
| `is-small` | `btn-sm` | Small size |
| `is-medium` | `btn-md` | Medium size |
| `is-large` | `btn-lg` | Large size |
| `is-loading` | `loading loading-spinner` | Loading state |
| `card` | `card bg-base-100` | Card container |
| `card-header` | N/A (use card-title in card-body) | Structural change |
| `card-content` | `card-body` | Card content area |
| `card-footer` | `card-actions` | Card actions area |
| `modal` | `modal` | Modal container |
| `modal-card` | `modal-box` | Modal content box |
| `modal-card-head` | N/A (use elements in modal-box) | Structural change |
| `modal-card-body` | Content in modal-box | Direct content |
| `modal-card-foot` | `modal-action` | Modal actions |
| `notification` | `alert` | Notification/alert |
| `is-success` (notification) | `alert-success` | Success alert |
| `is-danger` (notification) | `alert-error` | Error alert |
| `navbar` | `navbar` | Same |
| `tabs` | `tabs tabs-boxed` | Tabbed interface |
| `tag` | `badge` | Tag/badge |
| `dropdown` | `dropdown` | Same |
| `table` | `table` | Same |
| `is-striped` | `table-zebra` | Striped rows |
| `input` | `input input-bordered` | Text input |
| `select` | `select select-bordered` | Select input |
| `textarea` | `textarea textarea-bordered` | Textarea |
| `field` | `form-control` | Form field wrapper |
| `label` | `label` | Same |
| `help` | `label-text-alt` | Helper text |
| `is-danger` (help) | `text-error` | Error text |
| `columns` | `grid grid-cols-*` or `flex` | Layout |
| `column` | Grid/flex children | Layout |
| `is-half` | `w-1/2` or `col-span-6` | Half width |
| `is-one-third` | `w-1/3` or `col-span-4` | Third width |
| `has-text-centered` | `text-center` | Text alignment |
| `is-hidden-mobile` | `hidden md:block` | Responsive hiding |
| `level` | `flex justify-between items-center` | Level layout |
| `hero` | Custom with Tailwind | Hero section |
| `progress` | `progress` | Progress bar |

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
        render Bali::Button::Component.new(
          variant: variant.to_sym,
          size: size.to_sym,
          loading: loading,
          disabled: disabled
        ) { "Button" }
      end

      def all_variants
        render_with_template
      end
    end
  end
end
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
