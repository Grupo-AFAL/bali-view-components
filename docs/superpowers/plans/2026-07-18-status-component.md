# Bali::Status::Component Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a colorful, SmartSuite-style `Bali::Status::Component` — a solid vibrant status pill that, when editable, opens a portaled panel of colored option rows and auto-submits the selected value via a Turbo form.

**Architecture:** A presentational, domain-agnostic ViewComponent. Consumers pass `options: [{value:, label:, color:}]` + `selected:`. Colors come from a fixed Ruby `PALETTE` (or a hex escape) painted as **inline `style`** — no Tailwind `bg-*` classes, so no safelist and identical across DaisyUI themes. Editing is plain HTML form semantics: each option is a `<button type="submit" name=param value=…>` inside a `form_with`; the server responds with a Turbo Stream that replaces the wrapper. A small `status` Stimulus controller only handles open/close, viewport positioning (`position: fixed` so the panel escapes DataTable `overflow` clipping), keyboard, and the clear action.

**Tech Stack:** Ruby (ViewComponent, `Bali::ApplicationViewComponent`), ERB, Stimulus (vanilla JS, no new npm dep), CSS (component `index.css`), Minitest (`ComponentTestCase`), Cypress (Lookbook preview URLs), Lookbook previews, i18n (`bali.es.yml` / `bali.en.yml`).

## Global Constraints

- Component base class: `Bali::ApplicationViewComponent` (gives `class_names`, `prepend_*` helpers, `PathHelper`).
- Colors render as inline `style="background-color:…; color:…"`. NEVER emit dynamic Tailwind `bg-*`/`text-*` classes (Tailwind v4 safelist + unlayered-CSS gotcha).
- `index.css` carries only shape/layout/positioning — no color utilities, no `@apply bg-*`.
- Palette hex + foreground pairs are fixed for AA-ish contrast; hex escape uses `Bali::Utils::ColorCalculator#contrasting_text_color`.
- Preview files inherit from `ApplicationViewComponentPreview` (NOT `Lookbook::Preview`).
- Stimulus controllers registered in `app/frontend/bali/components/index.js` (import + export + `application.register`) and re-exported from `app/frontend/bali/index.js`.
- Component CSS imported via a line in `app/assets/stylesheets/bali/components.css`; after editing CSS run `bundle exec rails tailwindcss:build`.
- Cypress `baseUrl` = `http://localhost:3001/lookbook/preview`; specs `cy.visit('/bali/status/<preview_method>')`.
- Run Ruby tests with `bundle exec rails test`; a single file with `bundle exec rails test test/bali/components/status_test.rb`.
- Editable ⇔ `form.present? && !readonly`. No `form:` OR `readonly: true` → static, read-only pill (no controller, no panel, no buttons).
- The consumer owns the Turbo target id — they pass `id:` (e.g. `id: dom_id(record, :status)`) which passes through to the root element. The component does NOT know about any model/`dom_id`.

---

### Task 1: Component (Ruby) + display-only rendering + i18n placeholder

**Files:**
- Create: `app/components/bali/status/component.rb`
- Create: `app/components/bali/status/component.html.erb`
- Modify: `config/locales/bali.es.yml` (add `bali.status.no_status`)
- Modify: `config/locales/bali.en.yml` (add `bali.status.no_status`)
- Test: `test/bali/components/status_test.rb`

**Interfaces:**
- Produces (used by Tasks 2, 4, 5, 6):
  - `Bali::Status::Component.new(selected: nil, options: [], form: nil, readonly: false, clearable: false, size: :sm, placeholder: nil, **options)`
  - `options` element shape: `{ value: String, label: String, color: Symbol|String }`.
  - Private predicates/helpers used by the template: `editable?`, `selected?`, `selected_option`, `selected_label`, `resolve_color(color) => { bg:, fg: }`, `pill_style(color) => String`, `size_class`, `container_attributes`.
  - Palette symbols: `:slate :gray :red :orange :amber :yellow :green :teal :blue :indigo :violet :pink`.
  - CSS class hooks emitted (consumed by Task 4 CSS + Task 6 Cypress): root `.status-component`; pill `.status-pill` (+ `.status-pill--static` when read-only); size `.status--xs/.status--sm/.status--md`; label `.status-pill__label`.

- [ ] **Step 1: Write the failing test**

Create `test/bali/components/status_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class BaliStatusComponentTest < ComponentTestCase
  OPTIONS = [
    { value: "pending", label: "Pendiente", color: :slate },
    { value: "validated", label: "Validada", color: :green }
  ].freeze

  def test_display_only_renders_static_pill_with_selected_label
    render_inline(Bali::Status::Component.new(selected: "validated", options: OPTIONS))
    assert_selector("span.status-component .status-pill.status-pill--static", text: "Validada")
  end

  def test_display_only_does_not_render_a_form_or_buttons
    render_inline(Bali::Status::Component.new(selected: "validated", options: OPTIONS))
    assert_no_selector("form")
    assert_no_selector("button")
  end

  def test_named_color_is_applied_as_inline_background_style
    render_inline(Bali::Status::Component.new(selected: "green", options: [{ value: "green", label: "G", color: :green }]))
    assert_selector('.status-pill[style*="background-color: #16a34a"]')
    assert_selector('.status-pill[style*="color: #fff"]')
  end

  def test_hex_color_is_applied_with_contrasting_text
    render_inline(Bali::Status::Component.new(selected: "x", options: [{ value: "x", label: "X", color: "#ff0000" }]))
    assert_selector('.status-pill[style*="background-color: #ff0000"]')
    assert_selector('.status-pill[style*="color:"]')
  end

  def test_nil_selected_renders_placeholder_none_state
    render_inline(Bali::Status::Component.new(selected: nil, options: OPTIONS))
    assert_selector(".status-pill.status-pill--none", text: "Sin estado")
  end

  def test_custom_placeholder_overrides_default
    render_inline(Bali::Status::Component.new(selected: nil, options: OPTIONS, placeholder: "Elegir"))
    assert_selector(".status-pill.status-pill--none", text: "Elegir")
  end

  def test_size_class_is_applied
    render_inline(Bali::Status::Component.new(selected: "validated", options: OPTIONS, size: :md))
    assert_selector(".status-pill.status--md")
  end

  def test_id_passthrough_lands_on_root_element
    render_inline(Bali::Status::Component.new(selected: "validated", options: OPTIONS, id: "test_case_1_status"))
    assert_selector("span#test_case_1_status.status-component")
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rails test test/bali/components/status_test.rb`
Expected: FAIL — `uninitialized constant Bali::Status` (component not defined).

- [ ] **Step 3: Write the component class**

Create `app/components/bali/status/component.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module Status
    class Component < ApplicationViewComponent
      include Utils::ColorCalculator

      CONTROLLER = "status"

      # Fixed, vibrant status palette. Rendered as inline styles (never Tailwind
      # bg-* classes) so statuses look identical across DaisyUI themes and need
      # no safelist. `fg` values are picked for AA-ish contrast on `bg`.
      PALETTE = {
        slate:  { bg: "#64748b", fg: "#fff" },
        gray:   { bg: "#d1d5db", fg: "#1f2937" },
        red:    { bg: "#dc2626", fg: "#fff" },
        orange: { bg: "#ea580c", fg: "#fff" },
        amber:  { bg: "#f59e0b", fg: "#1f2937" },
        yellow: { bg: "#eab308", fg: "#1f2937" },
        green:  { bg: "#16a34a", fg: "#fff" },
        teal:   { bg: "#0d9488", fg: "#fff" },
        blue:   { bg: "#2563eb", fg: "#fff" },
        indigo: { bg: "#4f46e5", fg: "#fff" },
        violet: { bg: "#6d28d9", fg: "#fff" },
        pink:   { bg: "#db2777", fg: "#fff" }
      }.freeze

      SIZES = { xs: "status--xs", sm: "status--sm", md: "status--md" }.freeze

      DEFAULT_COLOR = :slate

      def initialize(selected: nil, options: [], form: nil, readonly: false,
                     clearable: false, size: :sm, placeholder: nil, **html_options)
        @selected = selected.presence&.to_s
        @options = options
        @form = form
        @readonly = readonly
        @clearable = clearable
        @size = size&.to_sym
        @placeholder = placeholder
        @html_options = html_options
      end

      private

      attr_reader :options, :form, :clearable, :html_options

      def editable?
        form.present? && !@readonly
      end

      def clearable?
        editable? && clearable
      end

      def selected?
        @selected.present?
      end

      def selected_option
        @selected_option ||= options.find { |o| o[:value].to_s == @selected }
      end

      def selected_label
        return placeholder unless selected?

        selected_option&.dig(:label) || @selected
      end

      def placeholder
        @placeholder.presence || t("bali.status.no_status")
      end

      def param
        form[:param]
      end

      def form_method
        form.fetch(:method, :patch)
      end

      # Resolves a palette symbol or a hex string to { bg:, fg: } for inline styling.
      def resolve_color(color)
        return PALETTE.fetch(DEFAULT_COLOR) if color.blank?

        if color.is_a?(Symbol) || PALETTE.key?(color.to_s.to_sym)
          PALETTE.fetch(color.to_sym, PALETTE.fetch(DEFAULT_COLOR))
        else
          { bg: color, fg: contrasting_text_color(color) }
        end
      end

      def pill_style(color)
        c = resolve_color(color)
        "background-color: #{c[:bg]}; color: #{c[:fg]};"
      end

      def selected_style
        return if @selected.blank?

        pill_style(selected_option&.dig(:color))
      end

      def size_class
        SIZES.fetch(@size, SIZES[:sm])
      end

      def pill_classes(extra = nil)
        class_names("status-pill", size_class, extra, "status-pill--none" => !selected?)
      end

      def container_classes
        class_names("status-component", "inline-block", html_options[:class])
      end

      def container_attributes
        attrs = html_options.except(:class, :data)
        attrs[:class] = container_classes
        data = html_options.fetch(:data, {})
        attrs[:data] = editable? ? { controller: CONTROLLER }.merge(data) : data
        attrs[:data] = nil if attrs[:data].empty?
        attrs.compact
      end
    end
  end
end
```

- [ ] **Step 4: Write the display-only template**

Create `app/components/bali/status/component.html.erb` (the editable branch is added in Task 2; for now only the read-only branch exists):

```erb
<%= tag.span(**container_attributes) do %>
  <% if editable? %>
    <%# filled in Task 2 %>
  <% else %>
    <span class="<%= pill_classes("status-pill--static") %>"<%= " style=\"#{selected_style}\"".html_safe if selected_style %>>
      <span class="status-pill__label"><%= selected_label %></span>
    </span>
  <% end %>
<% end %>
```

- [ ] **Step 5: Add the i18n placeholder key**

In `config/locales/bali.es.yml`, add under the `es: bali:` map (alphabetical near other component keys):

```yaml
    status:
      no_status: "Sin estado"
```

In `config/locales/bali.en.yml`, add under the `en: bali:` map:

```yaml
    status:
      no_status: "No status"
```

- [ ] **Step 6: Run test to verify it passes**

Run: `bundle exec rails test test/bali/components/status_test.rb`
Expected: PASS (8 assertions/tests green).

- [ ] **Step 7: Commit**

```bash
git add app/components/bali/status/component.rb \
        app/components/bali/status/component.html.erb \
        config/locales/bali.es.yml config/locales/bali.en.yml \
        test/bali/components/status_test.rb
git commit -m "feat(status): display-only colorful status pill

Presentational component: fixed vibrant PALETTE + hex escape rendered as
inline styles (theme- and safelist-agnostic). Read-only pill + none-state
placeholder (i18n bali.status.no_status). Editable mode added next.

Confidence: high
Scope-risk: narrow"
```

---

### Task 2: Editable mode — form, options panel, clearable

**Files:**
- Modify: `app/components/bali/status/component.html.erb` (fill the `editable?` branch; rewrite BOTH branches to build inline `style` via Rails `tag.*` helpers so the value is HTML-escaped — resolves the Task 1 review's Important finding)
- Modify: `app/components/bali/status/component.rb` (add `default:` fallback to the `placeholder` translation — resolves a Task 1 Minor finding)
- Test: `test/bali/components/status_test.rb` (add editable cases + a style-escaping regression test + an unmatched-`selected` test)

**Security note (Task 1 review carryover):** the inline `style` must NEVER be assembled via `"style=\"#{...}\"".html_safe` string interpolation — that bypasses Rails attribute escaping and lets a `"` in a color value break out of the attribute. Always pass `style:` as a kwarg to a `tag.*` helper (as `Bali::Tag::Component` does), which escapes the value.

**Interfaces:**
- Consumes (from Task 1): `editable?`, `clearable?`, `selected?`, `selected_option`, `selected_label`, `selected_style`, `pill_classes`, `pill_style`, `param`, `form_method`, `options`, `form`.
- Produces (consumed by Task 3 JS + Task 6 Cypress): DOM contract —
  - trigger: `<button type="button" class="status-pill status-pill__label" data-status-target="trigger" data-action="status#toggle" aria-haspopup="listbox" aria-expanded="false">`
  - clear: `<button type="submit" name=param value="" class="status-pill__clear" data-action="status#clear">`
  - panel: `<div class="status-panel" data-status-target="panel" role="listbox" hidden>`
  - option: `<button type="submit" name=param value=<v> role="option" class="status-option" aria-selected=…>` styled with `pill_style`; none-row: `.status-option--none`.

- [ ] **Step 1: Write the failing tests (append to the test file)**

Add these methods inside `class BaliStatusComponentTest`:

```ruby
  FORM = { url: "/things/1/status", method: :patch, param: "thing[status]" }.freeze

  def test_editable_renders_a_form_posting_to_the_given_url_and_method
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM))
    assert_selector("form[action='/things/1/status']")
    assert_selector("input[name='_method'][value='patch']", visible: false)
  end

  def test_editable_renders_a_toggle_trigger_wired_to_the_status_controller
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM))
    assert_selector("span.status-component[data-controller='status']")
    assert_selector("button[type='button'][data-status-target='trigger'][data-action='status#toggle'][aria-haspopup='listbox']")
  end

  def test_editable_renders_one_submit_button_per_option_with_name_and_value
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM))
    assert_selector("div.status-panel[role='listbox'] button[type='submit'][role='option']", count: 2)
    assert_selector("button.status-option[name='thing[status]'][value='pending']", text: "Pendiente")
    assert_selector("button.status-option[name='thing[status]'][value='validated']", text: "Validada")
  end

  def test_editable_marks_the_current_option_as_selected
    render_inline(Bali::Status::Component.new(selected: "validated", options: OPTIONS, form: FORM))
    assert_selector("button.status-option[value='validated'][aria-selected='true']")
    assert_selector("button.status-option[value='pending'][aria-selected='false']")
  end

  def test_option_rows_carry_their_own_inline_color
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM))
    assert_selector('button.status-option[value="validated"][style*="background-color: #16a34a"]')
  end

  def test_readonly_with_form_renders_static_pill_and_no_form
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM, readonly: true))
    assert_selector(".status-pill.status-pill--static")
    assert_no_selector("form")
    assert_no_selector("[data-controller='status']")
  end

  def test_clearable_renders_a_clear_submit_and_a_none_row_when_a_value_is_selected
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM, clearable: true))
    assert_selector("button.status-pill__clear[type='submit'][name='thing[status]'][value='']")
    assert_selector("button.status-option--none[type='submit'][value='']")
  end

  def test_clearable_hides_the_clear_x_when_nothing_is_selected
    render_inline(Bali::Status::Component.new(selected: nil, options: OPTIONS, form: FORM, clearable: true))
    assert_no_selector("button.status-pill__clear")
  end

  def test_color_value_cannot_break_out_of_the_style_attribute
    render_inline(Bali::Status::Component.new(
      selected: "x",
      options: [{ value: "x", label: "X", color: 'red" onmouseover="alert(1)' }],
      form: { url: "/t", method: :patch, param: "t[s]" }
    ))
    # If the color value broke out of the style attribute, an onmouseover
    # attribute would exist. tag.* escaping keeps the quote inside style.
    assert_no_selector("[onmouseover]")
  end

  def test_selected_value_absent_from_options_falls_back_to_raw_label_and_default_color
    render_inline(Bali::Status::Component.new(selected: "ghost", options: OPTIONS))
    assert_selector('.status-pill.status-pill--static[style*="background-color: #64748b"]', text: "ghost")
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rails test test/bali/components/status_test.rb`
Expected: FAIL — the editable branch is empty, so no `form`/trigger/options selectors match.

- [ ] **Step 3: Fill the editable branch of the template (using escaped `tag.*` helpers)**

Replace the whole `app/components/bali/status/component.html.erb` with the following. Note: every inline `style` is passed as a `tag.*` kwarg (auto-escaped) — do NOT hand-roll `style="…".html_safe`. The literal character inside the clear button is a multiplication sign `×` (U+00D7), not a lowercase x.

```erb
<%= tag.span(**container_attributes) do %>
  <% if editable? %>
    <%= form_with url: form[:url], method: form_method, data: { turbo: true } do %>
      <%= tag.div(class: pill_classes, style: selected_style) do %>
        <button type="button"
                class="status-pill__label"
                data-status-target="trigger"
                data-action="status#toggle"
                aria-haspopup="listbox"
                aria-expanded="false">
          <span><%= selected_label %></span>
          <span class="status-pill__caret" aria-hidden="true"></span>
        </button>
        <% if clearable? && selected? %>
          <%= tag.button("×",
                type: "submit",
                class: "status-pill__clear",
                name: param,
                value: "",
                aria: { label: placeholder },
                data: { action: "status#clear" }) %>
        <% end %>
      <% end %>

      <%= tag.div(class: "status-panel", role: "listbox", hidden: true,
                  data: { status_target: "panel" }) do %>
        <% options.each do |option| %>
          <%= tag.button(option[:label],
                type: "submit",
                class: "status-option",
                role: "option",
                name: param,
                value: option[:value],
                aria: { selected: option[:value].to_s == @selected },
                style: pill_style(option[:color])) %>
        <% end %>
        <% if clearable? %>
          <%= tag.button(placeholder,
                type: "submit",
                class: "status-option status-option--none",
                role: "option",
                name: param,
                value: "") %>
        <% end %>
      <% end %>
    <% end %>
  <% else %>
    <%= tag.span(class: pill_classes("status-pill--static"), style: selected_style) do %>
      <span class="status-pill__label"><%= selected_label %></span>
    <% end %>
  <% end %>
<% end %>
```

Notes for the implementer:
- `tag.div(..., style: nil)` and `tag.span(..., style: nil)` omit the attribute entirely when `selected_style` is `nil` — no empty `style=""`.
- `aria: { selected: bool }` renders `aria-selected="true"|"false"`; `hidden: true` renders the boolean `hidden` attribute; `data: { status_target: "panel" }` renders `data-status-target="panel"`.
- The clear button and none-row use `placeholder` (which is the i18n `no_status` string) for their accessible label / text.

- [ ] **Step 3b: Harden the placeholder translation fallback**

In `app/components/bali/status/component.rb`, update the `placeholder` method to pass a `default:` so a consuming app without Bali's locale files loaded degrades gracefully instead of rendering "translation missing":

```ruby
      def placeholder
        @placeholder.presence || t("bali.status.no_status", default: "No status")
      end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bundle exec rails test test/bali/components/status_test.rb`
Expected: PASS (all Task 1 + Task 2 tests green).

- [ ] **Step 5: Commit**

```bash
git add app/components/bali/status/component.html.erb \
        app/components/bali/status/component.rb \
        test/bali/components/status_test.rb
git commit -m "feat(status): editable mode with colored options panel

form_with + one <button type=submit name=param value> per option (plain
form semantics, Turbo Stream on the app side). readonly forces the static
pill; clearable adds an X (form-nested submit) and a 'no status' row.
Inline styles are emitted via escaped tag.* helpers (not html_safe string
interpolation) so a quote in a color value cannot break out of the style
attribute; placeholder translation gains a default: fallback.

Constraint: options must submit without JS -> native submit buttons inside the form
Constraint: color values must not be able to break out of the style attribute -> tag.* escaping
Rejected: hand-rolled style=\"...\".html_safe | bypasses Rails attribute escaping (XSS foot-gun)
Confidence: high
Scope-risk: narrow"
```

---

### Task 3: Stimulus controller (open/close, fixed positioning, keyboard) + registration

**Files:**
- Create: `app/components/bali/status/index.js`
- Modify: `app/frontend/bali/components/index.js` (import + export + register)
- Modify: `app/frontend/bali/index.js` (add `StatusController` to the components re-export list)

**Interfaces:**
- Consumes (from Task 2 DOM): targets `trigger`, `panel`; actions `status#toggle`, `status#clear`.
- Produces (consumed by Task 6 Cypress): opening adds visibility by removing `hidden` and adding `.status-panel--open`; the panel is `position: fixed` (Task 4 CSS) positioned under the trigger; Escape and outside-click close it; `aria-expanded` toggles on the trigger.

- [ ] **Step 1: Write the controller**

Create `app/components/bali/status/index.js`:

```js
import { Controller } from '@hotwired/stimulus'

// Drives the editable status pill: opens/closes the options panel, positions it
// with position:fixed (so it escapes DataTable overflow clipping), and wires
// keyboard + outside-click. Selecting an option submits the form natively; the
// app's Turbo Stream then replaces this element, so no "close after select" is
// needed here.
export class StatusController extends Controller {
  static targets = ['trigger', 'panel']

  connect () {
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
    this.handleKeydown = this.handleKeydown.bind(this)
    this.reposition = this.reposition.bind(this)
  }

  disconnect () {
    this.close()
  }

  toggle (event) {
    event?.preventDefault()
    this.isOpen ? this.close() : this.open()
  }

  open () {
    if (this.isOpen) return
    this.isOpen = true
    this.panelTarget.hidden = false
    this.panelTarget.classList.add('status-panel--open')
    this.triggerTarget.setAttribute('aria-expanded', 'true')
    this.reposition()

    document.addEventListener('click', this.handleOutsideClick)
    document.addEventListener('keydown', this.handleKeydown)
    window.addEventListener('resize', this.reposition)
    window.addEventListener('scroll', this.reposition, true)

    this.currentOption?.focus()
  }

  close () {
    if (!this.isOpen) return
    this.isOpen = false
    if (this.hasPanelTarget) {
      this.panelTarget.hidden = true
      this.panelTarget.classList.remove('status-panel--open')
    }
    this.triggerTarget?.setAttribute('aria-expanded', 'false')

    document.removeEventListener('click', this.handleOutsideClick)
    document.removeEventListener('keydown', this.handleKeydown)
    window.removeEventListener('resize', this.reposition)
    window.removeEventListener('scroll', this.reposition, true)
  }

  // Lets the native submit run; nothing else to do here.
  clear () {}

  reposition () {
    const rect = this.triggerTarget.getBoundingClientRect()
    const panel = this.panelTarget
    panel.style.position = 'fixed'
    panel.style.minWidth = `${rect.width}px`
    panel.style.left = `${rect.left}px`

    // Open downward, or upward if there isn't room below.
    const belowSpace = window.innerHeight - rect.bottom
    const panelHeight = panel.offsetHeight
    if (belowSpace < panelHeight && rect.top > belowSpace) {
      panel.style.top = 'auto'
      panel.style.bottom = `${window.innerHeight - rect.top + 4}px`
    } else {
      panel.style.bottom = 'auto'
      panel.style.top = `${rect.bottom + 4}px`
    }
  }

  handleOutsideClick (event) {
    if (!this.element.contains(event.target) && !this.panelTarget.contains(event.target)) {
      this.close()
    }
  }

  handleKeydown (event) {
    switch (event.key) {
      case 'Escape':
        event.preventDefault()
        this.close()
        this.triggerTarget.focus()
        break
      case 'ArrowDown':
        event.preventDefault()
        this.focusRelative(1)
        break
      case 'ArrowUp':
        event.preventDefault()
        this.focusRelative(-1)
        break
    }
  }

  focusRelative (delta) {
    const items = this.optionItems
    if (items.length === 0) return
    const index = items.indexOf(document.activeElement)
    const next = (index + delta + items.length) % items.length
    items[next].focus()
  }

  get optionItems () {
    return Array.from(this.panelTarget.querySelectorAll('[role="option"]'))
  }

  get currentOption () {
    return this.panelTarget.querySelector('[aria-selected="true"]') || this.optionItems[0]
  }
}
```

- [ ] **Step 2: Register the controller**

In `app/frontend/bali/components/index.js`:

1. Add the static import (near the other component imports, after the `CommandController` import line):

```js
import { StatusController } from '../../../components/bali/status/index'
```

2. Add the re-export (near the "Interactive components" export block):

```js
export { StatusController } from '../../../components/bali/status/index'
```

3. Add the registration inside `registerAll`, in the `// Interactive` group:

```js
  application.register('status', StatusController)
```

In `app/frontend/bali/index.js`, add `StatusController` to the alphabetized list inside the `export { … } from './components/index'` block (e.g. after `SortableListController`):

```js
  StatusController,
```

- [ ] **Step 3: Verify JS lints (no unit runner; lint is the gate)**

Run: `yarn standard app/components/bali/status/index.js`
Expected: no output (passes). If `yarn standard` is unavailable, run `npx standard app/components/bali/status/index.js`.

- [ ] **Step 4: Verify registration wiring is syntactically valid**

Run: `node --check app/frontend/bali/components/index.js && node --check app/frontend/bali/index.js`
Expected: no output (both parse). (Behavioral verification happens in Task 6 Cypress.)

- [ ] **Step 5: Commit**

```bash
git add app/components/bali/status/index.js app/frontend/bali/components/index.js app/frontend/bali/index.js
git commit -m "feat(status): stimulus controller for the editable panel

Open/close, position:fixed panel that escapes DataTable overflow, outside-
click + Escape close, arrow-key option navigation. Selecting an option
submits natively; the app's Turbo Stream replaces the element.

Rejected: portal panel to body via tippy | moving the <form> out of nesting breaks submit; position:fixed escapes overflow without moving DOM
Confidence: medium
Scope-risk: narrow
Not-tested: ancestor with CSS transform establishing a fixed containing block"
```

---

### Task 4: Component CSS (shape, sizes, panel, option rows)

**Files:**
- Create: `app/components/bali/status/index.css`
- Modify: `app/assets/stylesheets/bali/components.css` (add `@import`)

**Interfaces:**
- Consumes (from Tasks 1–2 DOM): `.status-component`, `.status-pill`, `.status-pill--static`, `.status-pill--none`, `.status-pill__label`, `.status-pill__caret`, `.status-pill__clear`, `.status-panel`, `.status-panel--open`, `.status-option`, `.status-option--none`, `.status--xs/.status--sm/.status--md`.
- Produces: visual styling only. No color utilities (colors are inline).

- [ ] **Step 1: Write the CSS**

Create `app/components/bali/status/index.css`:

```css
/* Bali Status component — shape/layout only. Colors are applied inline
   (see Bali::Status::Component#pill_style) and must never be set here. */

.status-component {
  position: relative;
}

.status-pill {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  border-radius: 0.375rem;
  font-weight: 600;
  line-height: 1.2;
  white-space: nowrap;
  max-width: 100%;
}

.status-pill__label {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  background: transparent;
  border: 0;
  color: inherit;
  font: inherit;
  cursor: pointer;
  padding: 0;
  overflow: hidden;
  text-overflow: ellipsis;
}

.status-pill--static .status-pill__label { cursor: default; }

.status-pill__caret {
  width: 0;
  height: 0;
  border-left: 0.25rem solid transparent;
  border-right: 0.25rem solid transparent;
  border-top: 0.3rem solid currentColor;
  opacity: 0.7;
}

.status-pill__clear {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: 0;
  color: inherit;
  cursor: pointer;
  opacity: 0;
  font-size: 1.1em;
  line-height: 1;
  padding: 0 0.15rem;
  transition: opacity 0.1s ease-in-out;
}

.status-pill:hover .status-pill__clear,
.status-pill:focus-within .status-pill__clear { opacity: 0.85; }

/* None / unassigned state */
.status-pill--none {
  background-color: transparent !important;
  color: #6b7280 !important;
  border: 1px dashed #d1d5db;
  font-weight: 500;
}

/* Sizes */
.status--xs { font-size: 0.6875rem; padding: 0.125rem 0.5rem; }
.status--sm { font-size: 0.75rem; padding: 0.25rem 0.625rem; }
.status--md { font-size: 0.875rem; padding: 0.375rem 0.75rem; }

/* Panel (position:fixed set inline by the controller).
   Visibility is class-driven: hidden by default, shown when the controller
   adds `.status-panel--open`. This must NOT rely on the `[hidden]` attribute
   alone — Bali's component CSS is unlayered, so an unconditional
   `display: flex` here would beat the UA `[hidden] { display: none }` rule and
   the panel would never hide (repo's "Tailwind v4 unlayered CSS" gotcha). */
.status-panel {
  z-index: 60;
  display: none;
  flex-direction: column;
  gap: 0.25rem;
  padding: 0.375rem;
  background-color: #fff;
  border-radius: 0.5rem;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.2), 0 8px 10px -6px rgba(0, 0, 0, 0.15);
  max-height: 20rem;
  overflow-y: auto;
}

.status-panel--open { display: flex; }

.status-option {
  display: block;
  width: 100%;
  text-align: center;
  border: 0;
  border-radius: 0.375rem;
  padding: 0.5rem 0.75rem;
  font-weight: 600;
  font-size: 0.8125rem;
  cursor: pointer;
  transition: filter 0.1s ease-in-out;
}

.status-option:hover { filter: brightness(0.95); }
.status-option[aria-selected="true"] { box-shadow: 0 0 0 2px rgba(0, 0, 0, 0.25); }

.status-option--none {
  background-color: transparent !important;
  color: #6b7280 !important;
  border: 1px dashed #d1d5db;
  font-weight: 500;
}
```

- [ ] **Step 2: Register the stylesheet import**

In `app/assets/stylesheets/bali/components.css`, add (near the other interactive component imports, e.g. after the `tooltip/index.css` line):

```css
@import "../../../components/bali/status/index.css";
```

- [ ] **Step 3: Rebuild Tailwind/CSS**

Run: `bundle exec rails tailwindcss:build`
Expected: exits 0; `spec/dummy/app/assets/builds/tailwind.css` regenerated (no errors about the new `@import`).

- [ ] **Step 4: Commit**

```bash
git add app/components/bali/status/index.css app/assets/stylesheets/bali/components.css
git commit -m "feat(status): component stylesheet (shape/panel/options)

Layout-only CSS: pill, caret, clear X, none-state dashed pill, sizes, and
the fixed-position options panel with full-width colored rows (hover via
brightness filter). No color utilities — colors stay inline.

Directive: never add background/text color utilities here; colors are inline per-status
Confidence: high
Scope-risk: narrow"
```

---

### Task 5: Lookbook previews

**Files:**
- Create: `app/components/bali/status/preview.rb`
- Create: `app/components/bali/status/previews/in_table.html.erb`

**Interfaces:**
- Consumes: the full component API. Preview method names become Cypress URLs in Task 6: `editable`, `in_table`.

- [ ] **Step 1: Write the preview class**

Create `app/components/bali/status/preview.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module Status
    class Preview < ApplicationViewComponentPreview
      STATUSES = [
        { value: "pending", label: "Pendiente", color: :slate },
        { value: "in_review", label: "En revisión", color: :blue },
        { value: "in_progress", label: "En proceso", color: :amber },
        { value: "ready", label: "Listo para revisión", color: :orange },
        { value: "done", label: "Completada", color: :green },
        { value: "paused", label: "Pausada", color: :gray },
        { value: "cancelled", label: "Cancelada", color: :red }
      ].freeze

      # Read-only pill (no form).
      # @param selected [Symbol] select [pending, in_review, in_progress, ready, done, paused, cancelled]
      # @param size [Symbol] select [xs, sm, md]
      def default(selected: :in_progress, size: :sm)
        render Status::Component.new(selected: selected, options: STATUSES, size: size)
      end

      # Editable pill: click opens the colored panel; selecting submits the form.
      # @param size [Symbol] select [xs, sm, md]
      # @param clearable toggle
      def editable(size: :sm, clearable: true)
        render Status::Component.new(
          selected: "in_progress",
          options: STATUSES,
          form: { url: "/lookbook", method: :patch, param: "thing[status]" },
          clearable: clearable,
          size: size
        )
      end

      # None / unassigned state.
      def no_status
        render Status::Component.new(selected: nil, options: STATUSES)
      end

      # Hex-color escape hatch (color outside the named palette).
      def custom_color
        render Status::Component.new(
          selected: "brand",
          options: [{ value: "brand", label: "Brand", color: "#7c3aed" }]
        )
      end

      # Full named palette gallery.
      def palette
        render_with_template(locals: {
          swatches: Bali::Status::Component::PALETTE.keys
        })
      end

      # Editable pill inside an overflow-x container (proves the panel is not clipped).
      def in_table
        render_with_template
      end
    end
  end
end
```

- [ ] **Step 2: Write the `in_table` preview template**

Create `app/components/bali/status/previews/in_table.html.erb`:

```erb
<div class="overflow-x-auto border rounded-lg" style="max-width: 32rem;">
  <table class="table">
    <thead>
      <tr><th>Escenario</th><th>Estado</th></tr>
    </thead>
    <tbody>
      <tr>
        <td>B1-01 | Registro</td>
        <td>
          <%= render Bali::Status::Component.new(
                selected: "in_progress",
                options: Bali::Status::Preview::STATUSES,
                form: { url: "/lookbook", method: :patch, param: "thing[status]" },
                clearable: true) %>
        </td>
      </tr>
      <tr>
        <td>B1-01 | Visualización</td>
        <td>
          <%= render Bali::Status::Component.new(
                selected: "done",
                options: Bali::Status::Preview::STATUSES,
                form: { url: "/lookbook", method: :patch, param: "thing[status]" },
                clearable: true) %>
        </td>
      </tr>
    </tbody>
  </table>
</div>
```

- [ ] **Step 3: Write the `palette` preview template**

Create `app/components/bali/status/previews/palette.html.erb`:

```erb
<div class="flex flex-wrap gap-2">
  <% swatches.each do |name| %>
    <%= render Bali::Status::Component.new(
          selected: name.to_s,
          options: [{ value: name.to_s, label: name.to_s.titleize, color: name }]) %>
  <% end %>
</div>
```

- [ ] **Step 4: Verify previews load**

Start the dummy server (background): `cd spec/dummy && bin/dev`
Open `http://localhost:3001/lookbook/preview/bali/status/editable` and `.../bali/status/in_table`.
Expected: no 500; the editable pill renders and clicking it opens the colored panel; in `in_table` the panel overlaps the table without being clipped. Capture a screenshot of `editable` and `in_table` per the repo's Browser Verification rule.

- [ ] **Step 5: Commit**

```bash
git add app/components/bali/status/preview.rb app/components/bali/status/previews/
git commit -m "docs(status): lookbook previews

default (read-only), editable, no_status, custom_color (hex), palette
gallery, and in_table (overflow-x container proving the panel is not
clipped).

Confidence: high
Scope-risk: narrow"
```

---

### Task 6: Cypress end-to-end behavior

**Files:**
- Create: `cypress/e2e/status-controller.cy.js`

**Interfaces:**
- Consumes: preview URLs `/bali/status/editable` and `/bali/status/in_table`; DOM contract from Tasks 2–4.

- [ ] **Step 1: Write the Cypress spec**

Create `cypress/e2e/status-controller.cy.js`:

```js
describe('StatusController', () => {
  context('editable status pill', () => {
    beforeEach(() => {
      cy.visit('/bali/status/editable')
    })

    it('opens the options panel on click', () => {
      cy.get('.status-panel').should('not.be.visible')
      cy.get('[data-status-target="trigger"]').first().click()
      cy.get('.status-panel').first().should('be.visible')
      cy.get('.status-option[role="option"]').should('have.length.greaterThan', 1)
    })

    it('closes on Escape', () => {
      cy.get('[data-status-target="trigger"]').first().click()
      cy.get('.status-panel').first().should('be.visible')
      cy.get('body').type('{esc}')
      cy.get('.status-panel').first().should('not.be.visible')
    })

    it('closes on outside click', () => {
      cy.get('[data-status-target="trigger"]').first().click()
      cy.get('.status-panel').first().should('be.visible')
      cy.get('body').click('bottomRight')
      cy.get('.status-panel').first().should('not.be.visible')
    })

    // NOTE: `form_with method: :patch` renders <form method="post"> plus a
    // hidden _method=patch field, so the wire request is POST (Rack method
    // override), NOT PATCH. Intercept POST — matching the drawer spec. The
    // body carries `_method=patch` and the clicked button's name/value.
    it('submits the form with the chosen value when an option is selected', () => {
      cy.intercept('POST', '/lookbook*', {
        headers: { 'Content-Type': 'text/vnd.turbo-stream.html' },
        body: '<turbo-stream action="append" target="stream-target"><template><p id="stream-result">ok</p></template></turbo-stream>'
      }).as('submit')

      cy.get('[data-status-target="trigger"]').first().click()
      cy.get('.status-option[value="done"]').first().click()

      cy.wait('@submit').its('request.body').should('include', 'thing%5Bstatus%5D=done')
    })

    it('submits an empty value when the clear X is clicked', () => {
      cy.intercept('POST', '/lookbook*', {
        headers: { 'Content-Type': 'text/vnd.turbo-stream.html' },
        body: '<turbo-stream action="append" target="stream-target"><template><p>ok</p></template></turbo-stream>'
      }).as('clear')

      cy.get('.status-pill__clear').first().click({ force: true })
      // thing[status] is the last form param, so its empty value is followed by
      // end-of-body or the next '&' — match either, don't assume a trailing '&'.
      cy.wait('@clear').its('request.body').should('match', /thing%5Bstatus%5D=(&|$)/)
    })
  })

  context('inside an overflow container', () => {
    beforeEach(() => {
      cy.visit('/bali/status/in_table')
    })

    it('renders the panel above the table without clipping', () => {
      cy.get('[data-status-target="trigger"]').first().click()
      cy.get('.status-panel').first().should('be.visible').then(($panel) => {
        // position:fixed panels are laid out against the viewport, not the
        // overflow-x-auto ancestor, so the panel is not clipped.
        expect($panel[0].getBoundingClientRect().height).to.be.greaterThan(0)
      })
    })
  })
})
```

- [ ] **Step 2: Run Cypress against a prebuilt, running dummy server**

`bin/dev`/Foreman is BROKEN in this environment (the tailwind watcher exits and kills the whole process group), so do NOT use it. Instead prebuild the assets and run a plain Rails server:

```bash
# 1. Bundle the dummy app's JS so the new StatusController is registered in the bundle
cd spec/dummy && yarn build
# 2. Build the component CSS (engine-namespaced task name in this repo)
cd /Users/fede/code/afal/bali-view-components && bundle exec rails app:tailwindcss:build
# 3. Start the server on port 3001 in the background; poll until it answers
cd spec/dummy && bin/rails server -p 3001   # (run in background)
# 4. Run the spec (Electron browser — cy:run targets Chrome which may be absent)
cd /Users/fede/code/afal/bali-view-components && yarn run cy:run:electron --spec cypress/e2e/status-controller.cy.js
```

Expected: all specs pass. If a spec fails, read the Cypress output/screenshots to decide whether it's a spec bug (fix the spec) or a real component/JS defect (fix it, rebuild the relevant asset, re-run). Shut the background server down when done.

- [ ] **Step 3: Commit**

```bash
git add cypress/e2e/status-controller.cy.js
git commit -m "test(status): cypress e2e for the editable panel

Open on click, close on Escape/outside-click, option select submits the
form with the chosen value, clear X submits empty, and the panel is not
clipped inside an overflow-x container.

Confidence: high
Scope-risk: narrow"
```

---

### Task 7: CHANGELOG + component catalog docs

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `docs/guides/components.md`

**Interfaces:** none (documentation).

- [ ] **Step 1: Add the CHANGELOG entry**

In `CHANGELOG.md`, add a new `## [Unreleased]` section above the top version heading (`## [v2.12.1] - 2026-07-17`) if one does not already exist, with an `### Added` list item:

```markdown
## [Unreleased]

### Added

- **Status** - new `Bali::Status::Component`, a colorful SmartSuite-style status pill. Presentational and domain-agnostic: pass `options: [{value:, label:, color:}]` + `selected:`. Colors come from a fixed vibrant palette (`:slate :gray :red :orange :amber :yellow :green :teal :blue :indigo :violet :pink`) or a hex escape, rendered as inline styles (theme-independent, no Tailwind safelist). Pass `form: { url:, method:, param: }` to make it editable — click opens a portaled (`position: fixed`, escapes DataTable overflow) panel of colored option rows; selecting a row submits the form natively (respond with a Turbo Stream that replaces the wrapper). `readonly:` forces the read-only pill even when `form:` is given (permission-gated call sites), `clearable:` adds an X + a "no status" row, and `size:` is `:xs/:sm/:md`. The consumer owns the Turbo target id via `id:` passthrough.
```

- [ ] **Step 2: Add a catalog entry to the components guide**

In `docs/guides/components.md`, add a `Status` entry following the existing format used by neighboring components (locate an existing component section such as `Tag` and mirror its heading level and structure). Content:

```markdown
### Status

Colorful, SmartSuite-style status pill with optional inline editing.

```erb
<%# Read-only %>
<%= render Bali::Status::Component.new(
      selected: record.status,
      options: Model.status_options) %>

<%# Editable (auto-submits via Turbo); readonly toggles by permission %>
<%= render Bali::Status::Component.new(
      id: dom_id(record, :status),
      selected: record.status,
      options: Model.status_options,
      form: { url: record_status_path(record), method: :patch, param: "model[status]" },
      readonly: !policy(record).manage?,
      clearable: true) %>
```

`options` elements are `{ value:, label:, color: }` where `color:` is a palette
symbol (`:slate :gray :red :orange :amber :yellow :green :teal :blue :indigo
:violet :pink`) or a hex string. The consuming controller responds with a Turbo
Stream replacing the element identified by the `id:` you pass.
```

(If `docs/guides/components.md` is alphabetized, insert `Status` between the entries that surround it; otherwise append near related data-display components.)

- [ ] **Step 3: Verify docs render / no broken markdown**

Run: `bundle exec rails test test/bali/components/status_test.rb`
Expected: still PASS (sanity that nothing Ruby broke). Visually skim the two edited markdown files for correct fencing.

- [ ] **Step 4: Commit**

```bash
git add CHANGELOG.md docs/guides/components.md
git commit -m "docs(status): changelog + component catalog entry

Confidence: high
Scope-risk: narrow"
```

---

## Self-Review

**Spec coverage:**
- Presentational, domain-agnostic, `options:` + `selected:` API → Task 1/2. ✓
- Single component covering display / editable / permission-gated (`readonly:`) → Task 2. ✓
- `form: {url:, method:, param:}` present ⇒ editable → Task 2. ✓
- Fixed vibrant named palette + hex escape via inline styles → Task 1 (`PALETTE`, `resolve_color`, `pill_style`). ✓
- Solid pill + full-width colored option rows (SmartSuite look) → Task 2 ERB + Task 4 CSS. ✓
- Clearable (X + none row) → Task 2. ✓
- No-status placeholder + i18n → Task 1. ✓
- Portal-out-of-overflow behavior → Task 3 (`position: fixed`) + Task 4 CSS + Task 6 Cypress `in_table`. ✓
- Click-to-open + auto-submit + Escape/outside close + keyboard → Task 3 + Task 6. ✓
- Sidecar file layout, controller registration, tests (Minitest + Cypress), previews → Tasks 1–6. ✓
- CHANGELOG + docs → Task 7. ✓
- Search inside panel: intentionally OUT (YAGNI, per spec). ✓
- afal-apps migration: OUT of this repo's scope (spec migration note). ✓

**Deviation from spec (documented):** the spec described portaling the panel via the same mechanism Tooltip uses (`tippy.js`). Investigation showed Tooltip moves its content to `<body>`; doing that with our `<form>` would pull the option `<button type=submit>`s out of the form and break native submission. The plan instead uses a `position: fixed` panel positioned by the controller, which satisfies the actual requirement ("panel not clipped by DataTable overflow") without moving the form. Trade-off recorded in Task 3's commit and its `Not-tested` note (ancestor with a CSS `transform` establishing a fixed containing block).

**Placeholder scan:** no TBD/TODO/"add error handling"/"similar to Task N" — every code step contains complete code. ✓

**Type/name consistency:** `PALETTE`, `resolve_color`, `pill_style`, `selected_option`, `editable?`, `clearable?`, `param`, `form_method` defined in Task 1 and used consistently in Task 2's ERB. Stimulus targets (`trigger`, `panel`) and actions (`status#toggle`, `status#clear`) match between Task 2 ERB, Task 3 JS, and Task 6 Cypress. CSS class hooks match between Task 2 ERB, Task 4 CSS, and Task 6 Cypress selectors. Preview method names (`editable`, `in_table`) match Task 6 `cy.visit` URLs. ✓
