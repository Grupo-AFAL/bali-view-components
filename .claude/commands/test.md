# Run Component Tests

Run RSpec tests for Bali ViewComponents.

## Usage

```
/test $ARGUMENTS
```

Where `$ARGUMENTS` is:
- Component name (e.g., `Button`, `Card`)
- File path (e.g., `spec/components/bali/button/component_spec.rb`)
- `--all` - Run all component tests
- `--coverage` - Show coverage report
- `--generate` - Generate missing tests

## Workflow

### Step 1: Identify Test Files

Based on argument:

1. **Component name**: Run `spec/components/bali/[name]/`
2. **File path**: Run that specific file
3. **--all**: Run `spec/components/`

### Step 2: Run Tests

```bash
# Single component
bundle exec rspec spec/components/bali/button/ --format documentation

# All components
bundle exec rspec spec/components/ --format progress

# With coverage
COVERAGE=true bundle exec rspec spec/components/
```

### Step 3: Analyze Results

For failures:
- Show the failing test
- Show the error message
- Suggest fix based on error type

### Step 4: Generate Missing Tests (if --generate)

For components without tests, generate:

```ruby
# spec/components/bali/[name]/component_spec.rb
RSpec.describe Bali::[Name]::Component, type: :component do
  it "renders successfully" do
    render_inline(described_class.new)
    expect(page).to have_css("[expected-selector]")
  end

  describe "variants" do
    Bali::[Name]::Component::VARIANTS.each_key do |variant|
      it "renders #{variant} variant" do
        render_inline(described_class.new(variant: variant))
        expect(page).to have_css(".#{expected_class}")
      end
    end
  end

  describe "sizes" do
    Bali::[Name]::Component::SIZES.each_key do |size|
      it "renders #{size} size" do
        render_inline(described_class.new(size: size))
        expect(page).to have_css(".#{expected_class}")
      end
    end
  end
end
```

## Test Patterns for DaisyUI Components

### Basic Rendering

```ruby
it "renders with base DaisyUI class" do
  render_inline(described_class.new) { "Content" }
  expect(page).to have_css(".btn")  # or .card, .modal, etc.
end
```

### Variant Testing

```ruby
describe "variants" do
  it "applies primary variant" do
    render_inline(described_class.new(variant: :primary)) { "Primary" }
    expect(page).to have_css(".btn.btn-primary")
  end

  it "applies error variant" do
    render_inline(described_class.new(variant: :error)) { "Error" }
    expect(page).to have_css(".btn.btn-error")
  end
end
```

### Size Testing

```ruby
describe "sizes" do
  %i[xs sm md lg].each do |size|
    it "applies #{size} size" do
      render_inline(described_class.new(size: size)) { "Button" }
      expect(page).to have_css(".btn.btn-#{size}")
    end
  end
end
```

### State Testing

```ruby
describe "states" do
  it "shows loading state" do
    render_inline(described_class.new(loading: true)) { "Loading" }
    expect(page).to have_css(".loading")
  end

  it "shows disabled state" do
    render_inline(described_class.new(disabled: true)) { "Disabled" }
    expect(page).to have_css(".btn-disabled")
    expect(page).to have_css("[disabled]")
  end
end
```

### Slot Testing

```ruby
describe "slots" do
  it "renders header slot" do
    render_inline(described_class.new) do |c|
      c.with_header { "Header Content" }
    end
    expect(page).to have_css(".card-title", text: "Header Content")
  end

  it "renders actions slot" do
    render_inline(described_class.new) do |c|
      c.with_actions { "<button>Action</button>".html_safe }
    end
    expect(page).to have_css(".card-actions button", text: "Action")
  end
end
```

### Options Passthrough

```ruby
describe "options passthrough" do
  it "adds custom classes" do
    render_inline(described_class.new(class: "custom-class")) { "Content" }
    expect(page).to have_css(".btn.custom-class")
  end

  it "adds data attributes" do
    render_inline(described_class.new(data: { controller: "test" })) { "Content" }
    expect(page).to have_css("[data-controller='test']")
  end
end
```

## Example Execution

```
User: /test Button

AI: Running tests for Bali::Button::Component...

```bash
bundle exec rspec spec/components/bali/button/ --format documentation
```

Bali::Button::Component
  renders with base DaisyUI class
  variants
    applies primary variant
    applies secondary variant
    applies success variant
    applies error variant
    applies ghost variant
  sizes
    applies xs size
    applies sm size
    applies md size
    applies lg size
  states
    shows loading state
    shows disabled state
  options passthrough
    adds custom classes
    adds data attributes

Finished in 0.45 seconds
12 examples, 0 failures

✓ All tests passing
```

```
User: /test Card --generate

AI: Analyzing Bali::Card::Component...

Component has:
- Variants: default, compact, bordered, side
- Sizes: N/A
- Slots: header, body, footer, image
- Options: shadow (boolean)

Generating spec/components/bali/card/component_spec.rb...

[Shows generated test file]

Running generated tests...
12 examples, 0 failures

✓ Tests generated and passing
```
