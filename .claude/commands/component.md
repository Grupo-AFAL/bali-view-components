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
- `--test` - Generate RSpec test (default: true)

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
├── component.scss         # Styles (minimal, prefer Tailwind)
└── preview.rb             # Lookbook preview

spec/components/bali/[name]/
└── component_spec.rb      # RSpec tests

app/assets/javascripts/bali/controllers/
└── [name]_controller.js   # Stimulus controller (if --stimulus)
```

### Step 3: Apply Bali Patterns

## Component Templates

### Simple Component (DaisyUI)

```ruby
# app/components/bali/badge/component.rb
module Bali
  module Badge
    class Component < ApplicationComponent
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
    class Component < ApplicationComponent
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
    class Component < ApplicationComponent
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
// app/assets/javascripts/bali/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
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

```ruby
# app/components/bali/badge/preview.rb
module Bali
  module Badge
    class Preview < Lookbook::Preview
      # @!group Playground
      
      # @param variant select [primary, secondary, accent, success, warning, error, info, ghost]
      # @param size select [xs, sm, md, lg]
      # @param outline toggle
      # @param text text
      def playground(variant: :primary, size: :md, outline: false, text: "Badge")
        render Component.new(
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

## RSpec Test Template

```ruby
# spec/components/bali/badge/component_spec.rb
RSpec.describe Bali::Badge::Component, type: :component do
  it "renders with base badge class" do
    render_inline(described_class.new) { "Badge" }
    expect(page).to have_css("span.badge", text: "Badge")
  end

  describe "variants" do
    described_class::VARIANTS.each do |variant, css_class|
      it "renders #{variant} variant" do
        render_inline(described_class.new(variant: variant)) { variant.to_s }
        expect(page).to have_css("span.badge.#{css_class}")
      end
    end
  end

  describe "sizes" do
    described_class::SIZES.each do |size, css_class|
      it "renders #{size} size" do
        render_inline(described_class.new(size: size)) { size.to_s }
        expect(page).to have_css("span.badge.#{css_class}")
      end
    end
  end

  describe "outline" do
    it "applies outline class when true" do
      render_inline(described_class.new(outline: true)) { "Outline" }
      expect(page).to have_css("span.badge.badge-outline")
    end

    it "does not apply outline class when false" do
      render_inline(described_class.new(outline: false)) { "Solid" }
      expect(page).not_to have_css("span.badge-outline")
    end
  end

  describe "options passthrough" do
    it "applies custom classes" do
      render_inline(described_class.new(class: "custom")) { "Custom" }
      expect(page).to have_css("span.badge.custom")
    end

    it "applies data attributes" do
      render_inline(described_class.new(data: { testid: "badge" })) { "Data" }
      expect(page).to have_css("[data-testid='badge']")
    end
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

### 4. spec/components/bali/tooltip/component_spec.rb
[RSpec tests for all variants and positions]

### 5. app/assets/javascripts/bali/controllers/tooltip_controller.js
[Stimulus controller for dynamic tooltips]

## Running Tests

```bash
bundle exec rspec spec/components/bali/tooltip/
```

✓ 10 examples, 0 failures

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
