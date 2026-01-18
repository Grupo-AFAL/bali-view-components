# Bali ViewComponent Patterns

This document defines the standard patterns for creating and maintaining Bali ViewComponents.

## Component Structure

Every component follows this file structure:

```
app/components/bali/[name]/
├── component.rb           # Ruby class (required)
├── component.html.erb     # Template (required)
├── component.scss         # Styles (optional, minimize usage)
├── preview.rb             # Lookbook preview (required)
└── [subcomponent]/        # Nested components (if needed)
    ├── component.rb
    └── component.html.erb

spec/bali/components/[name]_spec.rb  # RSpec tests (required)
```

---

## Component Class Patterns

### Standard Constants

```ruby
module Bali
  module Button
    class Component < ApplicationComponent
      # Variants map to DaisyUI modifier classes
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

      # Sizes map to DaisyUI size classes
      SIZES = {
        xs: "btn-xs",
        sm: "btn-sm",
        md: "btn-md",
        lg: "btn-lg",
        xl: "btn-xl"
      }.freeze

      # For backward compatibility with Bulma naming
      SIZE_ALIASES = {
        small: :sm,
        medium: :md,
        large: :lg
      }.freeze

      VARIANT_ALIASES = {
        danger: :error  # Bulma used "danger", DaisyUI uses "error"
      }.freeze
    end
  end
end
```

### Standard Initializer Pattern

```ruby
def initialize(
  variant: :primary,      # Default to most common variant
  size: :md,              # Default to medium size
  loading: false,         # Boolean states default to false
  disabled: false,
  **options               # Always accept options hash for HTML attributes
)
  @variant = resolve_variant(variant)
  @size = resolve_size(size)
  @loading = loading
  @disabled = disabled
  @options = options
end

private

# Handle backward compatibility aliases
def resolve_variant(variant)
  VARIANT_ALIASES.fetch(variant, variant)
end

def resolve_size(size)
  SIZE_ALIASES.fetch(size, size)
end
```

### Class Generation Pattern

```ruby
private

def component_classes
  class_names(
    "btn",                           # Base DaisyUI class
    VARIANTS[@variant],              # Variant modifier
    SIZES[@size],                    # Size modifier
    @loading && "loading",           # Conditional state
    @disabled && "btn-disabled",     # Conditional state
    @options[:class]                 # User-provided classes
  )
end

def component_attributes
  @options.except(:class).merge(
    disabled: @disabled || nil,
    "aria-busy": @loading || nil
  ).compact
end
```

---

## Template Patterns

### Basic Template

```erb
<%# Always use computed classes method %>
<button class="<%= component_classes %>" <%= tag.attributes(component_attributes) %>>
  <%= content %>
</button>
```

### Template with Loading State

```erb
<button class="<%= component_classes %>" <%= tag.attributes(component_attributes) %>>
  <% if @loading %>
    <span class="loading loading-spinner loading-sm"></span>
  <% end %>
  <%= content %>
</button>
```

### Template with Slots

```erb
<div class="<%= card_classes %>" <%= tag.attributes(card_attributes) %>>
  <% if image? %>
    <figure><%= image %></figure>
  <% end %>
  
  <div class="card-body">
    <% if header? %>
      <h2 class="card-title"><%= header %></h2>
    <% end %>
    
    <%= body? ? body : content %>
    
    <% if actions? %>
      <div class="card-actions justify-end">
        <%= actions %>
      </div>
    <% end %>
  </div>
</div>
```

---

## Slot Patterns

### Simple Slot

```ruby
renders_one :header
renders_one :footer
```

### Slot with Lambda (Custom Rendering)

```ruby
renders_one :image, ->(src:, alt: "", **options) do
  tag.figure do
    image_tag(src, alt: alt, class: "w-full", **options)
  end
end
```

### Multiple Slots

```ruby
renders_many :items, ->(href: nil, **options, &block) do
  if href
    link_to(href, class: "menu-item", **options, &block)
  else
    tag.button(class: "menu-item", **options, &block)
  end
end
```

### Slot with Component

```ruby
renders_many :tabs, Bali::Tabs::Tab::Component
```

---

## Preview Patterns

### Standard Preview

```ruby
module Bali
  module Button
    class Preview < Lookbook::Preview
      # @!group Playground
      
      # Interactive playground with all options
      # @param variant select [primary, secondary, accent, success, warning, error, info, ghost, link, outline]
      # @param size select [xs, sm, md, lg, xl]
      # @param loading toggle
      # @param disabled toggle
      # @param text text
      def playground(variant: :primary, size: :md, loading: false, disabled: false, text: "Button")
        render Component.new(
          variant: variant.to_sym,
          size: size.to_sym,
          loading: loading,
          disabled: disabled
        ) { text }
      end
      
      # @!endgroup
      
      # @!group Variants
      
      # @label All Variants
      def all_variants
        render_with_template
      end
      
      # @!endgroup
      
      # @!group Sizes
      
      # @label All Sizes
      def all_sizes
        render_with_template
      end
      
      # @!endgroup
      
      # @!group States
      
      def loading_state
        render Component.new(loading: true) { "Loading..." }
      end
      
      def disabled_state
        render Component.new(disabled: true) { "Disabled" }
      end
      
      # @!endgroup
    end
  end
end
```

### Preview Template (all_variants.html.erb)

```erb
<div class="flex flex-wrap gap-4">
  <% Bali::Button::Component::VARIANTS.each_key do |variant| %>
    <%= render Bali::Button::Component.new(variant: variant) { variant.to_s.titleize } %>
  <% end %>
</div>
```

---

## Test Patterns

### Standard Test Structure

```ruby
RSpec.describe Bali::Button::Component, type: :component do
  # Basic rendering
  it "renders with base class" do
    render_inline(described_class.new) { "Click" }
    expect(page).to have_css("button.btn", text: "Click")
  end

  # Test all variants dynamically
  describe "variants" do
    described_class::VARIANTS.each do |variant, css_class|
      it "renders #{variant} variant with #{css_class}" do
        render_inline(described_class.new(variant: variant)) { variant.to_s }
        expect(page).to have_css("button.btn.#{css_class}")
      end
    end
  end

  # Test all sizes dynamically
  describe "sizes" do
    described_class::SIZES.each do |size, css_class|
      it "renders #{size} size with #{css_class}" do
        render_inline(described_class.new(size: size)) { size.to_s }
        expect(page).to have_css("button.btn.#{css_class}")
      end
    end
  end

  # Test boolean states
  describe "loading state" do
    it "adds loading class when true" do
      render_inline(described_class.new(loading: true)) { "Loading" }
      expect(page).to have_css("button.loading")
      expect(page).to have_css("[aria-busy='true']")
    end

    it "does not add loading class when false" do
      render_inline(described_class.new(loading: false)) { "Not Loading" }
      expect(page).not_to have_css("button.loading")
    end
  end

  describe "disabled state" do
    it "adds disabled class and attribute" do
      render_inline(described_class.new(disabled: true)) { "Disabled" }
      expect(page).to have_css("button.btn-disabled[disabled]")
    end
  end

  # Test options passthrough
  describe "options passthrough" do
    it "merges custom classes" do
      render_inline(described_class.new(class: "custom-class")) { "Custom" }
      expect(page).to have_css("button.btn.custom-class")
    end

    it "passes data attributes" do
      render_inline(described_class.new(data: { testid: "my-button" })) { "Data" }
      expect(page).to have_css("[data-testid='my-button']")
    end

    it "passes aria attributes" do
      render_inline(described_class.new("aria-label": "Submit form")) { "Submit" }
      expect(page).to have_css("[aria-label='Submit form']")
    end
  end

  # Test backward compatibility aliases
  describe "backward compatibility" do
    it "accepts :danger as alias for :error" do
      render_inline(described_class.new(variant: :danger)) { "Danger" }
      expect(page).to have_css("button.btn.btn-error")
    end

    it "accepts :small as alias for :sm" do
      render_inline(described_class.new(size: :small)) { "Small" }
      expect(page).to have_css("button.btn.btn-sm")
    end
  end
end
```

### Testing Slots

```ruby
describe "slots" do
  it "renders header slot" do
    render_inline(described_class.new) do |c|
      c.with_header { "Card Title" }
      "Card content"
    end
    
    expect(page).to have_css(".card-title", text: "Card Title")
    expect(page).to have_css(".card-body", text: "Card content")
  end

  it "renders multiple item slots" do
    render_inline(described_class.new) do |c|
      c.with_item { "Item 1" }
      c.with_item { "Item 2" }
    end
    
    expect(page).to have_css("li", count: 2)
  end
end
```

---

## Accessibility Patterns

### Required Attributes

```ruby
def component_attributes
  @options.except(:class).merge(
    role: role_attribute,
    "aria-label": aria_label,
    "aria-expanded": aria_expanded,
    "aria-controls": aria_controls,
    "aria-busy": @loading || nil,
    "aria-disabled": @disabled || nil
  ).compact
end
```

### Focus Management

```erb
<%# Ensure focusable elements %>
<button class="<%= classes %>" tabindex="0">
  <%= content %>
</button>

<%# Skip link for keyboard users %>
<a href="#main-content" class="sr-only focus:not-sr-only">
  Skip to main content
</a>
```

### Screen Reader Support

```erb
<%# Visually hidden but readable %>
<span class="sr-only">Close dialog</span>

<%# Live regions for dynamic content %>
<div aria-live="polite" aria-atomic="true">
  <%= flash_message %>
</div>
```

---

## Stimulus Integration Patterns

### Component with Controller

```ruby
def stimulus_controller
  "dropdown"
end

def stimulus_data
  {
    controller: stimulus_controller,
    "#{stimulus_controller}-open-value": @open
  }
end
```

```erb
<div <%= tag.attributes(stimulus_data) %>>
  <button data-action="click->dropdown#toggle">
    <%= trigger %>
  </button>
  <div data-dropdown-target="menu">
    <%= content %>
  </div>
</div>
```

### Controller Registration

```javascript
// app/assets/javascripts/bali/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  static values = { open: { type: Boolean, default: false } }

  toggle() {
    this.openValue = !this.openValue
  }

  openValueChanged() {
    this.menuTarget.classList.toggle("hidden", !this.openValue)
  }
}
```

---

## Anti-Patterns (Avoid These)

### Don't: Logic in Templates

```erb
<%# BAD %>
<button class="btn <%= @variant == :primary ? 'btn-primary' : (@variant == :secondary ? 'btn-secondary' : 'btn-ghost') %>">
```

```ruby
# GOOD - Move logic to Ruby
def component_classes
  class_names("btn", VARIANTS[@variant])
end
```

### Don't: Inline Styles

```erb
<%# BAD %>
<div style="background: blue; padding: 10px;">

<%# GOOD %>
<div class="bg-primary p-2.5">
```

### Don't: Skip Options Passthrough

```ruby
# BAD - Can't add custom classes or data attributes
def initialize(variant: :primary)
  @variant = variant
end

# GOOD - Always accept **options
def initialize(variant: :primary, **options)
  @variant = variant
  @options = options
end
```

### Don't: Hardcode Bulma Classes

```ruby
# BAD - Still using Bulma
VARIANTS = {
  primary: "is-primary",
  danger: "is-danger"
}.freeze

# GOOD - DaisyUI classes
VARIANTS = {
  primary: "btn-primary",
  error: "btn-error"  # Note: danger → error
}.freeze
```

---

## Complex Component Patterns

### Responsive Mobile/Desktop Layouts

For components that need different layouts on mobile vs desktop (like navbars with dropdown menus):

```ruby
# Mobile: vertical stacking, hidden by default
# Desktop: horizontal layout, always visible
WRAPPER_CLASSES_MOBILE = %w[
  hidden flex-col gap-4 absolute left-0 top-full
  w-full bg-base-100 shadow-lg p-4 z-40
].join(' ').freeze

WRAPPER_CLASSES_DESKTOP = %w[
  lg:flex lg:flex-1 lg:static lg:flex-row lg:items-center
  lg:gap-4 lg:bg-transparent lg:shadow-none lg:p-0 lg:z-auto
].join(' ').freeze

def wrapper_classes
  class_names(WRAPPER_CLASSES_MOBILE, WRAPPER_CLASSES_DESKTOP)
end
```

### JavaScript Toggle Patterns (Tailwind)

When toggling visibility with Stimulus, use Tailwind's `hidden`/`flex` classes instead of
Bulma's `is-active` pattern:

```javascript
// BAD - Bulma pattern (doesn't work with Tailwind)
toggleMenu() {
  this.menuTarget.classList.toggle('is-active')
}

// GOOD - Tailwind pattern
toggleVisibility(element) {
  const isHidden = element.classList.contains('hidden')
  if (isHidden) {
    element.classList.remove('hidden')
    element.classList.add('flex')
  } else {
    element.classList.add('hidden')
    element.classList.remove('flex')
  }
}
```

### CSS Color Inheritance Fix

When placing components inside colored containers (e.g., dropdowns inside colored navbars),
explicitly set text color to prevent inheritance issues:

```ruby
# BAD - Text color inherited from parent (may be light on light background)
def content_classes
  class_names('dropdown-content', 'menu', 'bg-base-100')
end

# GOOD - Explicit text color ensures proper contrast
def content_classes
  class_names(
    'dropdown-content',
    'menu',
    'bg-base-100',
    'text-base-content'  # Reset text color for this container
  )
end
```

### Dropdown Trigger Variants for Navbars

When using dropdowns inside navbar menus, the DaisyUI menu hover styles can cause issues.
Use `!important` overrides sparingly but intentionally:

```ruby
# The `menu` variant is designed for navbar integration.
# It uses !bg-transparent to override DaisyUI's menu hover styling.
# DO NOT add `btn` classes - they break vertical alignment.
VARIANTS = {
  button: 'btn',
  icon: 'btn btn-ghost btn-circle',
  ghost: 'btn btn-ghost',
  menu: 'flex items-center gap-1 cursor-pointer !bg-transparent hover:!bg-transparent',
  custom: ''
}.freeze
```

### Fullscreen vs Constrained Layout

For layouts that support both edge-to-edge and centered content:

```ruby
# Container width constraint (1152px = max-w-6xl)
def container_classes
  base = 'flex items-center w-full relative px-4'
  if @fullscreen
    # Edge-to-edge: no max-width constraint
    class_names(base, @container_class)
  else
    # Centered: constrained width with auto margins
    class_names(base, 'max-w-6xl mx-auto', @container_class)
  end
end
```

**Important**: Choose a max-width that's visible in your preview environment. Common values:
- `max-w-7xl` = 1280px (too wide for most Lookbook panels)
- `max-w-6xl` = 1152px (good for wide screens)
- `max-w-5xl` = 1024px (visible on most laptops)
- `max-w-4xl` = 896px (visible in Lookbook panels)
