# Run Component Tests

Run the Minitest suite for Bali ViewComponents.

## Usage

```
/test $ARGUMENTS
```

Where `$ARGUMENTS` is:
- Component name (e.g., `Button`, `Card`)
- File path (e.g., `test/bali/components/button_test.rb`)
- `--all` - Run all component tests
- `--coverage` - Run the whole suite with a coverage report
- `--generate` - Generate missing tests

## Workflow

### Step 1: Identify Test Files

Based on argument:

1. **Component name**: `test/bali/components/[name]_test.rb`. A few components keep
   their tests in a subdirectory (`data_table/`, `filters/`, `form/`, `icon/`,
   `pagination/`, …), so locate the file instead of assuming the path:
   ```bash
   find test/bali/components -name "[name]_test.rb"
   ```
2. **File path**: Run that specific file
3. **--all**: Run `test/bali/components/`

### Step 2: Run Tests

```bash
# Single component
bin/rails test test/bali/components/button_test.rb

# A directory, recursively
bin/rails test test/bali/components/

# The whole suite
bin/rails test

# With coverage
COVERAGE=1 bin/rails test
```

Minitest has no `--format` flag. Narrow a run with a file, a `file:line`, or `-n`
and a test-name pattern:

```bash
bin/rails test test/bali/components/button_test.rb -n /variant/
bin/rails test test/bali/components/button_test.rb:6
```

`COVERAGE=1` starts SimpleCov from `spec/dummy/config/boot.rb` (before Bundler, so
coverage tracks the files loaded during boot) and the config enforces
`minimum_coverage line: 80`. Only the whole suite clears that bar: a single component
file measures around 14% and the run exits non-zero on the coverage gate alone, with
every test passing. `COVERAGE` also disables parallelization, so the run is slower.

### Step 3: Analyze Results

For failures:
- Show the failing test
- Show the error message
- Suggest fix based on error type

### Step 4: Generate Missing Tests (if --generate)

For components without tests, generate:

```ruby
# test/bali/components/[name]_test.rb
# frozen_string_literal: true

require "test_helper"

class Bali[Name]ComponentTest < ComponentTestCase
  def test_renders_successfully
    render_inline(Bali::[Name]::Component.new)
    assert_selector("[expected-selector]")
  end

  Bali::[Name]::Component::VARIANTS.each do |variant, css_class|
    define_method("test_variants_renders_#{variant}_variant") do
      render_inline(Bali::[Name]::Component.new(variant: variant))
      assert_selector(".#{css_class}")
    end
  end

  Bali::[Name]::Component::SIZES.each do |size, css_class|
    define_method("test_sizes_renders_#{size}_size") do
      render_inline(Bali::[Name]::Component.new(size: size))
      assert_selector(".#{css_class}")
    end
  end
end
```

`ComponentTestCase` (defined in `test/test_helper.rb`) is a `ViewComponent::TestCase`
with `Capybara::Minitest::Assertions` mixed in — that is where `render_inline`,
`assert_selector` and `assert_button` come from. Tests name the component class in
full; there is no RSpec-style `described_class`.

## Test Patterns for DaisyUI Components

### Basic Rendering

```ruby
def test_basic_rendering_renders_with_base_daisyui_class
  render_inline(Bali::Button::Component.new) { "Content" }
  assert_selector("button.btn") # or .card, .modal, etc.
end
```

### Variant Testing

```ruby
def test_variants_applies_primary_variant
  render_inline(Bali::Button::Component.new(variant: :primary)) { "Primary" }
  assert_selector("button.btn.btn-primary")
end

def test_variants_applies_error_variant
  render_inline(Bali::Button::Component.new(variant: :error)) { "Error" }
  assert_selector("button.btn.btn-error")
end
```

A whole family is usually covered by a loop that defines one case per value, so a new
value in the component's constant is a new test case for free:

```ruby
%i[primary secondary accent info success warning error ghost link neutral].each do |variant|
  define_method("test_variants_renders_#{variant}_variant") do
    render_inline(Bali::Button::Component.new(variant: variant)) { "Button" }
    assert_selector("button.btn.btn-#{variant}")
  end
end
```

### Size Testing

```ruby
def test_sizes_supports_all_daisyui_sizes
  %i[xs sm md lg xl].each do |size|
    render_inline(Bali::Tag::Component.new(text: "Tag", size: size))
    assert_selector("div.badge.badge-#{size}")
  end
end
```

### State Testing

```ruby
def test_states_shows_loading_state
  render_inline(Bali::Button::Component.new(loading: true)) { "Loading" }
  assert_selector(".loading")
end

def test_states_shows_disabled_state
  render_inline(Bali::Button::Component.new(disabled: true)) { "Disabled" }
  assert_selector("button.btn-disabled")
  assert_selector("[disabled]")
end
```

### Slot Testing

```ruby
def test_slots_renders_header_slot
  render_inline(Bali::Card::Component.new) do |c|
    c.with_header { "Header Content" }
  end
  assert_selector(".card-title", text: "Header Content")
end

def test_slots_renders_actions_slot
  render_inline(Bali::Card::Component.new) do |c|
    c.with_actions { "<button>Action</button>".html_safe }
  end
  assert_selector(".card-actions button", text: "Action")
end
```

### Options Passthrough

```ruby
def test_options_passthrough_accepts_custom_classes
  render_inline(Bali::Alert::Component.new(class: "custom-class")) { "Content" }
  assert_selector("div.alert.custom-class")
end

def test_options_passthrough_accepts_data_attributes
  render_inline(Bali::Alert::Component.new(data: { testid: "my-alert" })) { "Content" }
  assert_selector('div.alert[data-testid="my-alert"]')
end
```

### Asserting an Absence

`assert_no_selector` is the Capybara-on-Minitest spelling — there is no `not_to`:

```ruby
def test_no_icon_by_default
  render_inline(Bali::Alert::Component.new) { "Content" }
  assert_no_selector("div.alert > span.icon-component")
end
```

## Example Execution

```
User: /test Button

AI: Running tests for Bali::Button::Component...

```bash
bin/rails test test/bali/components/button_test.rb
```

Run options: --seed 38921

# Running:

..............................................

Finished in 0.147148s, 312.6112 runs/s, 468.9167 assertions/s.
46 runs, 69 assertions, 0 failures, 0 errors, 0 skips

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

Generating test/bali/components/card_test.rb...

[Shows generated test file]

Running generated tests...
12 runs, 24 assertions, 0 failures, 0 errors, 0 skips

✓ Tests generated and passing
```

## Browser Tests

Minitest does not exercise the Stimulus controllers. Those are Cypress, rendered
through the Lookbook previews, and need the dummy server up on port 3001:

```bash
cd spec/dummy && bin/dev   # in another terminal
yarn run cy:run            # headless
yarn run cy:open           # interactive
```
