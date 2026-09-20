# Create New Bali Component

Generate a new ViewComponent following Bali patterns with DaisyUI styling.

## Usage

```
/component $ARGUMENTS
```

Where `$ARGUMENTS` is:
- Component name (e.g., `Tooltip`, `Accordion`)
- `--slots` - Include slot definitions
- `--stimulus` - Include Stimulus controller
- `--preview` - Generate Lookbook preview (default: true)
- `--test` - Generate Minitest test (default: true)

## Workflow

### Step 1: Determine Component Type

| Type | Characteristics | Example |
|------|-----------------|---------|
| **Simple** | No slots, minimal logic | `Badge`, `Loader` |
| **Composite** | Has slots for content areas | `Card`, `Modal` |
| **Interactive** | Needs Stimulus controller | `Dropdown`, `Tabs` |

### Step 2: Generate Files

```
app/components/bali/[name]/
├── component.rb           # Ruby class
├── component.html.erb     # Template
├── index.css              # Styles (optional; plain CSS — this repo has no SCSS)
├── index.js               # Co-located Stimulus controller (if --stimulus)
└── preview.rb             # Lookbook preview

test/bali/components/
└── [name]_test.rb         # Minitest tests
```

A component's controller is **co-located** in its own directory as `index.js` — 47
components do it that way. `app/assets/javascripts/bali/controllers/` holds the 25
controllers that are not tied to one component, and they are dash-named
(`slim-select-controller.js`), never `snake_case`.

The full layout, with the nested-component and preview-template cases, is in
`docs/reference/component-patterns.md`. When that document and this one disagree,
that one wins.

### Step 3: Apply Bali Patterns

## Component Templates

### Simple Component (DaisyUI)

```ruby
# app/components/bali/badge/component.rb
module Bali
  module Badge
    class Component < ApplicationViewComponent
      VARIANTS = {
        primary: "badge-primary",
        secondary: "badge-secondary",
        accent: "badge-accent",
        success: "badge-success",
        warning: "badge-warning",
        error: "badge-error",
        info: "badge-info",
        ghost: "badge-ghost"
      }.freeze

      SIZES = {
        xs: "badge-xs",
        sm: "badge-sm",
        md: "badge-md",
        lg: "badge-lg"
      }.freeze

      def initialize(variant: :primary, size: :md, outline: false, **options)
        @variant = variant
        @size = size
        @outline = outline
        @options = options
      end

      private

      def badge_classes
        class_names(
          "badge",
          VARIANTS[@variant],
          SIZES[@size],
          @outline && "badge-outline",
          @options[:class]
        )
      end

      def badge_attributes
        @options.except(:class)
      end
    end
  end
end
```

```erb
<%# app/components/bali/badge/component.html.erb %>
<span class="<%= badge_classes %>" <%= tag.attributes(badge_attributes) %>>
  <%= content %>
</span>
```

### Composite Component (with Slots)

```ruby
# app/components/bali/card/component.rb
module Bali
  module Card
    class Component < ApplicationViewComponent
      renders_one :header
      renders_one :image, ->(src:, alt: "", **options) do
        tag.figure do
          image_tag(src, alt: alt, class: "w-full", **options)
        end
      end
      renders_one :body
      renders_one :actions
      renders_many :badges

      VARIANTS = {
        default: "",
        compact: "card-compact",
        bordered: "card-bordered",
        side: "card-side"
      }.freeze

      def initialize(variant: :default, shadow: true, **options)
        @variant = variant
        @shadow = shadow
        @options = options
      end

      private

      def card_classes
        class_names(
          "card bg-base-100",
          VARIANTS[@variant],
          shadow_class,
          @options[:class]
        )
      end

      def shadow_class
        return "" unless @shadow
        @shadow == true ? "shadow-xl" : "shadow-#{@shadow}"
      end

      def card_attributes
        @options.except(:class)
      end
    end
  end
end
```

```erb
<%# app/components/bali/card/component.html.erb %>
<div class="<%= card_classes %>" <%= tag.attributes(card_attributes) %>>
  <%= image if image? %>
  
  <div class="card-body">
    <% if header? || badges? %>
      <h2 class="card-title">
        <%= header %>
        <% badges.each do |badge| %>
          <%= badge %>
        <% end %>
      </h2>
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

### Interactive Component (with Stimulus)

```ruby
# app/components/bali/dropdown/component.rb
module Bali
  module Dropdown
    class Component < ApplicationViewComponent
      renders_one :trigger
      renders_many :items, ->(href: nil, **options, &block) do
        if href
          link_to(href, class: "dropdown-item", **options, &block)
        else
          tag.button(class: "dropdown-item", **options, &block)
        end
      end

      POSITIONS = {
        bottom: "dropdown-bottom",
        top: "dropdown-top",
        left: "dropdown-left",
        right: "dropdown-right"
      }.freeze

      ALIGNS = {
        start: "dropdown-start",
        end: "dropdown-end"
      }.freeze

      def initialize(position: :bottom, align: :start, hover: false, **options)
        @position = position
        @align = align
        @hover = hover
        @options = options
      end

      private

      def dropdown_classes
        class_names(
          "dropdown",
          POSITIONS[@position],
          ALIGNS[@align],
          @hover && "dropdown-hover",
          @options[:class]
        )
      end
    end
  end
end
```

```erb
<%# app/components/bali/dropdown/component.html.erb %>
<div class="<%= dropdown_classes %>" 
     data-controller="dropdown"
     <%= tag.attributes(@options.except(:class)) %>>
  <div tabindex="0" role="button" class="btn m-1" data-action="click->dropdown#toggle">
    <%= trigger %>
  </div>
  <ul tabindex="0" 
      class="dropdown-content menu bg-base-100 rounded-box z-10 w-52 p-2 shadow"
      data-dropdown-target="menu">
    <% items.each do |item| %>
      <li><%= item %></li>
    <% end %>
  </ul>
</div>
```

```javascript
// app/components/bali/dropdown/index.js
import { Controller } from '@hotwired/stimulus'

// A NAMED export, and named `<Name>Controller`: registration imports it by name
// (`import { DropdownController } from '../../../components/bali/dropdown/index'`
// in `app/frontend/bali/components/index.js`, which also lists it in the
// `registerControllers` map). A default export never reaches the page.
export class DropdownController extends Controller {
  static targets = ["menu"]
  static values = { open: { type: Boolean, default: false } }

  toggle() {
    this.openValue = !this.openValue
  }

  close() {
    this.openValue = false
  }

  openValueChanged() {
    if (this.openValue) {
      this.menuTarget.classList.remove("hidden")
    } else {
      this.menuTarget.classList.add("hidden")
    }
  }

  // Close when clicking outside
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  connect() {
    document.addEventListener("click", this.clickOutside.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.clickOutside.bind(this))
  }
}
```

## Lookbook Preview Template

Two things this template is strict about, both of which produce a broken preview if
copied loosely:

- **`ApplicationViewComponentPreview`**, never `Lookbook::Preview` — the host apps do
  not have Lookbook, and the class has to load there too. All 132 previews in the repo
  inherit from it.
- **Sibling constants written in full** — `Bali::Badge::Component`, never `Component`.
  `Module.nesting` is captured at parse time, Lookbook keeps the class from boot, and a
  later `reload!` leaves a bare sibling resolving against a module Zeitwerk has already
  discarded (#843). `test/requests/icon_previews_test.rb` fails the build on the bare
  form.

```ruby
# app/components/bali/badge/preview.rb
module Bali
  module Badge
    class Preview < ApplicationViewComponentPreview
      # @!group Playground
      
      # @param variant select [primary, secondary, accent, success, warning, error, info, ghost]
      # @param size select [xs, sm, md, lg]
      # @param outline toggle
      # @param text text
      def playground(variant: :primary, size: :md, outline: false, text: "Badge")
        render Bali::Badge::Component.new(
          variant: variant.to_sym,
          size: size.to_sym,
          outline: outline
        ) { text }
      end
      
      # @!endgroup

      # @!group Variants
      
      def all_variants
        render_with_template
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

## Minitest Test Template

Tests are Minitest, live in `test/`, and subclass `ComponentTestCase` — a
`ViewComponent::TestCase` with `Capybara::Minitest::Assertions` mixed in, defined in
`test/test_helper.rb`. The component class is named in full; there is no
`described_class`. Grouping that RSpec would express with `describe` is carried in the
method name instead (`test_variants_...`, `test_options_passthrough_...`), which is how
`test/bali/components/button_test.rb` and `alert_test.rb` are written.

```ruby
# test/bali/components/badge_test.rb
# frozen_string_literal: true

require "test_helper"

class BaliBadgeComponentTest < ComponentTestCase
  def test_basic_rendering_renders_with_base_badge_class
    render_inline(Bali::Badge::Component.new) { "Badge" }
    assert_selector("span.badge", text: "Badge")
  end

  Bali::Badge::Component::VARIANTS.each do |variant, css_class|
    define_method("test_variants_renders_#{variant}_variant") do
      render_inline(Bali::Badge::Component.new(variant: variant)) { variant.to_s }
      assert_selector("span.badge.#{css_class}")
    end
  end

  Bali::Badge::Component::SIZES.each do |size, css_class|
    define_method("test_sizes_renders_#{size}_size") do
      render_inline(Bali::Badge::Component.new(size: size)) { size.to_s }
      assert_selector("span.badge.#{css_class}")
    end
  end

  def test_outline_applies_outline_class_when_true
    render_inline(Bali::Badge::Component.new(outline: true)) { "Outline" }
    assert_selector("span.badge.badge-outline")
  end

  def test_outline_does_not_apply_outline_class_when_false
    render_inline(Bali::Badge::Component.new(outline: false)) { "Solid" }
    assert_no_selector("span.badge-outline")
  end

  def test_options_passthrough_applies_custom_classes
    render_inline(Bali::Badge::Component.new(class: "custom")) { "Custom" }
    assert_selector("span.badge.custom")
  end

  def test_options_passthrough_applies_data_attributes
    render_inline(Bali::Badge::Component.new(data: { testid: "badge" })) { "Data" }
    assert_selector('span.badge[data-testid="badge"]')
  end
end
```

## Example Execution

```
User: /component Tooltip --stimulus

AI: Creating Bali::Tooltip::Component...

## Generated Files

### 1. app/components/bali/tooltip/component.rb
[Ruby component class with DaisyUI tooltip patterns]

### 2. app/components/bali/tooltip/component.html.erb
[Template using DaisyUI tooltip classes]

### 3. app/components/bali/tooltip/preview.rb
[Lookbook preview with playground and variants]

### 4. test/bali/components/tooltip_test.rb
[Minitest tests for all variants and positions]

### 5. app/components/bali/tooltip/index.js
[Stimulus controller for dynamic tooltips]

## Running Tests

```bash
bin/rails test test/bali/components/tooltip_test.rb
```

✓ 10 runs, 14 assertions, 0 failures, 0 errors, 0 skips

## Usage

```erb
<%= render Bali::Tooltip::Component.new(tip: "Hello!") do %>
  Hover me
<% end %>

<%= render Bali::Tooltip::Component.new(tip: "Top", position: :top) do %>
  Top tooltip
<% end %>
```

## Preview

Start Lookbook and view at: http://localhost:3001/lookbook/inspect/bali/tooltip
```
