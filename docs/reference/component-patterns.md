# Bali ViewComponent Patterns

The standard patterns for creating and maintaining Bali ViewComponents, taken from the
code that ships — every class name, keyword and command here exists in this repo. When
this document and a component disagree, the component wins; fix the document.

## Component Structure

```
app/components/bali/[name]/
├── component.rb           # Ruby class (required)
├── component.html.erb     # Template (or a `call` method on the class)
├── index.css              # Styles (optional; plain CSS, no SCSS — see "CSS" below)
├── index.js               # Co-located Stimulus controller (only if it needs one)
├── preview.rb             # Lookbook preview (required)
├── previews/              # ERB templates for preview scenarios that need markup
│   └── [scenario].html.erb
└── [subcomponent]/        # Nested components (if needed)
    ├── component.rb
    └── component.html.erb

test/bali/components/[name]_test.rb   # Minitest (required — the suite is NOT RSpec)
cypress/e2e/[name]*.cy.js             # Cypress, when the component has JS behaviour
```

## The Class

Every component inherits from `Bali::ApplicationViewComponent`
(`app/components/bali/application_view_component.rb`), which brings:

- **`HtmlElementHelper`** — `prepend_class_name`, `prepend_controller`,
  `prepend_values`, `prepend_data_attribute`, `prepend_action`, `hyphenize_keys`.
  These are how `**options` merges with the component's own attributes.
- **i18n**: `t('.key')` inside `Bali::Rate::Component` resolves to
  `bali_view.rate.key`. All gem strings live under the `bali_view.*` root in
  `config/locales/bali_view.{en,es}.yml`.

```ruby
# frozen_string_literal: true

module Bali
  module Example
    class Component < ApplicationViewComponent
      BASE_CLASSES = "example-component flex items-center gap-2"

      # @param variant [Symbol] colour, from the shared taxonomy
      # @param size [Symbol] xs/sm/md/lg/xl
      def initialize(variant: nil, size: nil, **options)
        @variant_class = Bali::ButtonTaxonomy.variant!(self.class, variant)
        @size_class = Bali::ButtonTaxonomy.size!(self.class, size)
        @options = prepend_class_name(options, BASE_CLASSES)
      end
    end
  end
end
```

### Constants are written in full

`render Bali::Card::Component.new`, never a bare `render Component.new` relying on
nesting — and inside a `preview.rb`, sibling constants are ALWAYS fully qualified
(`Bali::Icon::LucideMapping`, never `LucideMapping`). The short form works on a cold
server and 500s after a reload (#843); `test/requests/icon_previews_test.rb` fails the
build if the pattern comes back.

## Variants, styles and sizes: the shared taxonomy

Button-shaped components (`Button`, `Link` in button dress, `DeleteLink`) share ONE
table — `Bali::ButtonTaxonomy` (`app/components/bali/button_taxonomy.rb`) — split along
daisyUI 5's three axes:

- **`variant:`** — the colour: `:neutral :primary :secondary :accent :info :success
  :warning :error`, plus `:ghost` / `:link`
- **`style:`** — the fill: `:outline`, `:soft`
- **`size:`** — the scale: `:xs :sm :md :lg :xl` (`:md` is the default and emits no class)

They compose: `variant: :error, style: :outline, size: :sm`. An unknown value
**raises** with a message listing the accepted ones — never resolve unknown input to
"no class", which is how `variant: :danger` once survived two majors painting an
uncoloured button.

There are **no aliases**. `danger`, `small`, `regular`, `medium`, `large` were the
v1/v2 (Bulma-era) vocabulary and are gone; components that met them recently
(`Tag`, `Alert`) raise on the legacy spelling with a message naming the new one.

### Tailwind sees only literal strings

Tailwind emits a class it finds verbatim in a scanned file. `"btn-#{variant}"` is
invisible to the scanner — which is why every map is written out longhand, in the
component (or taxonomy) file, and why that duplication is deliberate.

## Options passthrough

Every component takes `**options` and merges — never overwrites — with its own
attributes:

```ruby
def initialize(**options)
  @options = prepend_class_name(options, BASE_CLASSES)   # host class composes
  @options = prepend_controller(@options, "example")     # host data-controller composes
  @options = prepend_values(@options, "example", { open: false })
end
```

The component's own invariants go **before** the splat where the host must not
override them, and derived defaults go where the host may (see the worked example on
`DataTable#bulk_actions`, `app/components/bali/data_table/component.rb`).

## Slots

```ruby
renders_one :header, Header::Component            # slot backed by a sub-component
renders_many :actions, Action::Component          # generates with_action (singular!)
renders_one :title, ->(text, **options) do        # slot backed by a lambda
  tag.h2(text, **prepend_class_name(options, "card-title"))
end
```

Two gotchas, both load-bearing:

- **`renders_many :actions` is consumed as `with_action`**, one call per item. The
  plural `with_actions` writer exists but takes a collection — passing it a block
  silently renders nothing.
- **A block that itself calls `render` comes back empty under `capture`.** Render to a
  local first (`pill = render(...)` then interpolate) — see the worked comment in
  `app/components/bali/topbar/icon_action/component.rb`.
- A slot's lambda runs when the slot is **read**, and reading it (ViewComponent's
  `Slotable`) already evaluates the block once — do not also call the block yourself
  (see `DataTable#bulk_actions` for the double-render trap).

## Previews

```ruby
module Bali
  module Example
    # @label Example
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # @param size select [xs, sm, md, lg, xl]
      def default(size: :md)
        render Bali::Example::Component.new(size: size.to_sym)
      end

      # Scenarios that need surrounding markup render a template:
      def composed
        render_with_template(template: "bali/example/previews/composed")
      end
    end
  end
end
```

- Base class is **`ApplicationViewComponentPreview`** — never `Lookbook::Preview`
  (unavailable in consuming apps) nor `ViewComponent::Preview` (inconsistent here).
- Previews are ERB without test coverage of their own: when a component's API
  changes, its previews and `docs/guides/components.md` change in the same commit,
  and a request test that renders the previews over HTTP
  (`test/requests/topbar_previews_test.rb` is the model) turns a broken preview into
  a red build.
- The full annotation reference (params, `@!group` URL collapsing, preview-context
  limits) lives in the `lookbook-previews` skill.

## Tests

The suite is **Minitest**. Component tests live in `test/bali/components/` and use
`ComponentTestCase` (`test/test_helper.rb`: `ViewComponent::TestCase` +
`Capybara::Minitest::Assertions`):

```ruby
# frozen_string_literal: true

require "test_helper"

class BaliExampleComponentTest < ComponentTestCase
  def test_renders_with_base_class
    render_inline(Bali::Example::Component.new) { "Content" }

    assert_selector(".example-component", text: "Content")
  end

  def test_an_unknown_size_raises_naming_the_accepted_values
    error = assert_raises(ArgumentError) do
      render_inline(Bali::Example::Component.new(size: :tiny))
    end
    assert_match(/size/, error.message)
  end

  def test_host_options_pass_through
    render_inline(Bali::Example::Component.new(class: "custom", data: { testid: "x" }))

    assert_selector(".example-component.custom[data-testid='x']")
  end
end
```

Assertions are Capybara's (`assert_selector`, `assert_no_selector`, `assert_text`,
`assert_button`); add `visible: :all` for hidden inputs. Test the contract that can
break a host: the raise on bad input, the options passthrough, the aria state — not a
re-enumeration of every CSS class.

Anything with JS behaviour also gets a Cypress spec driving the **Lookbook preview
URL** (`/lookbook/preview/bali/[name]/[scenario]`); Minitest passing is not evidence
that the browser behaviour works.

## CSS

Component styles are plain `.css` (no SCSS) in the component's `index.css`, almost
always inside `@layer components`. Which of the three layer positions a rule belongs
in — and why unlayered files exist — is specified in `.claude/CLAUDE.md` ("Which CSS
layer a rule belongs in"); read it before adding any rule. Rebuild with
`bundle exec rails app:tailwindcss:build`.

## Accessibility

The load-bearing rules, enforced across the library:

- **Button vs Link is semantics, not looks**: an action is a `<button>`, navigation is
  an `<a href>`. An `<a>` without `href` (or with `href="#"`) is the anti-pattern the
  Dropdown solves with `with_item(tag: :button)`.
- **Icon-only controls take `aria_label:`** — that exact keyword, on every component
  that has one (`ViewSwitch`, `SideMenu`, `Chart`, `Topbar::IconAction`,
  `search_fields`). It is required where the control has no other name.
- Toggles carry `aria-pressed`/`aria-expanded` and the JS keeps them in sync with the
  visual state; state that only lives in `btn-primary` vs `btn-outline` is invisible
  to a screen reader.
- Dynamic outcomes (a drop, an async result) reach screen readers through a
  `role="status"` live region — `Bali::Kanban` is the worked example.

Full standards: `docs/guides/accessibility.md`.

## Anti-patterns

| Don't | Do |
|---|---|
| `class Component < ApplicationComponent` | `< ApplicationViewComponent` |
| `class Preview < Lookbook::Preview` | `< ApplicationViewComponentPreview` |
| Alias maps for legacy vocabulary (`danger:`, `small:`) | raise on the legacy spelling, naming the replacement |
| Resolve unknown variants to `nil`/no class | `Bali::ButtonTaxonomy.variant!` raises |
| `"btn-#{variant}"` | longhand class maps (Tailwind scans literals) |
| Inline styles | Tailwind/daisyUI classes |
| RSpec / `.scss` in examples or new files | Minitest / plain `.css` |
| Logic chains in ERB | a private method returning `class_names(...)` |
| Swallow unknown host options (`def initialize(x:)` only) | `**options` + `prepend_*` helpers |
