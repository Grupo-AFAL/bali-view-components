# Bali::Status::Component — Design

Date: 2026-07-18
Status: Approved (brainstorming)

## Purpose

A colorful "status" component for Bali, modeled on SmartSuite's status field: a
solid, vibrant pill showing the current status, which — when editable — opens a
panel of full-width colored option rows; selecting one auto-submits and updates
the value in place.

The component is **presentational and domain-agnostic**. It knows nothing about
any particular model. Consumers pass an array of options and the current value.
It replaces the current hand-rolled pattern in afal-apps (TD Flow "Pruebas de
calidad" and "Defectos"), where each row renders a plain Rails `<select>` +
`auto-submit` Stimulus controller for editing and an inline `status_color` hash
for the read-only `Bali::Tag` badge.

### Goals
- Visually **colorful** — easy to distinguish statuses at a glance (SmartSuite look).
- Adding new statuses / new status editors in consuming apps is trivial: build an
  options array from the model's status constant + i18n + a color map.
- One component covers three cases: read-only display, editable, and
  "editable-but-not-for-this-user" (permissions), without duplicating call sites.

### Non-goals (YAGNI)
- No in-panel search (dropped; revisit only if a model needs many statuses).
- No new abstraction on the model side (no `Statusable` concern / StatusSet PORO).
  Consumers keep their existing `STATUSES` constant + i18n and add a color map.
- Not a wrapper around `Bali::Tag` — `Status` has its own fixed palette (see below).

## Public API

```erb
<%# Editable %>
<%= render Bali::Status::Component.new(
      selected: test_case.status,
      options: TDFlow::TestCase.status_options,
      form: { url: td_flow_initiative_project_test_case_status_path(initiative, test_case),
              method: :patch,
              param: "td_flow_test_case[status]" },
      clearable: true,
      size: :sm) %>

<%# Editable depending on permissions — pass form always, toggle readonly %>
<%= render Bali::Status::Component.new(
      selected: test_case.status,
      options: TDFlow::TestCase.status_options,
      form: { url: ..._status_path(initiative, test_case), method: :patch,
              param: "td_flow_test_case[status]" },
      readonly: !policy(project).manage?) %>

<%# Read-only (no form) — e.g. header badge, print, non-editable lists %>
<%= render Bali::Status::Component.new(
      selected: test_case.status,
      options: TDFlow::TestCase.status_options) %>
```

### Parameters (keyword-only)

| param | type | default | meaning |
|-------|------|---------|---------|
| `selected:` | String/Symbol/nil | — | current option `value`; `nil`/`""` → "no status" state |
| `options:` | Array<Hash> | `[]` | each `{ value:, label:, color: }` (see below) |
| `form:` | Hash/nil | `nil` | `{ url:, method:, param: }`. Present → editable; absent → display-only |
| `readonly:` | Boolean | `false` | forces display-only even when `form:` is given (permissions) |
| `clearable:` | Boolean | `false` | show an X on the pill + a "no status" row to unset (editable only) |
| `size:` | Symbol | `:sm` | `:xs` / `:sm` / `:md` |
| `placeholder:` | String | i18n default | text shown for the "no status" state |
| `**options` | — | — | passthrough merged onto the root element (`class`, `data`, etc.) |

**Editable ⇔ `form.present? && !readonly`.** Three states from one call site:
- no `form:` → always display-only.
- `form:` + `readonly: false` (default) → interactive pill.
- `form:` + `readonly: true` → same read-only pill (no caret, no panel, not clickable).

### Option shape

```ruby
{ value: "validated", label: "Validada", color: :green }   # named palette color
{ value: "custom",    label: "Custom",   color: "#f2c94c" } # hex escape hatch
```

`color:` is either a symbol from the named palette OR a hex string. Hex uses
`Utils::ColorCalculator#contrasting_text_color` to pick readable foreground.

Consumers build this array however they like. Recommended helper on the model:

```ruby
class TDFlow::TestCase < ApplicationRecord
  STATUSES = %w[pending in_review pre_validated validated failed retest change_requested not_applicable].freeze
  STATUS_COLORS = { "pending" => :slate, "in_review" => :blue, "pre_validated" => :teal,
                    "validated" => :green, "failed" => :red, "retest" => :amber,
                    "change_requested" => :orange, "not_applicable" => :gray }.freeze

  def self.status_options
    STATUSES.map { |s| { value: s, label: I18n.t("td_flow.test_cases.statuses.#{s}"),
                         color: STATUS_COLORS.fetch(s, :slate) } }
  end
end
```

## Visual design

The status palette is **fixed and vibrant**, independent of the DaisyUI theme —
so a status looks the same in any context/theme (this is the point). Colors are a
Ruby constant of `{ bg:, fg: }` pairs and are painted with **inline
`style="background-color: …; color: …"`**, not Tailwind `bg-*` classes. This
avoids the Tailwind v4 safelist requirement, the unlayered-CSS override gotcha,
and theme reinterpretation. `index.css` carries only shape/layout (pill radius,
sizes, panel, hover), which does not conflict with utilities.

### Palette (proposed)

| symbol | typical use | fg |
|--------|-------------|-----|
| `slate` | pending / neutral | light |
| `gray` | paused / muted | dark |
| `red` | error / cancelled | light |
| `orange` | strong review | light |
| `amber` | in progress / warning | dark |
| `yellow` | attention | dark |
| `green` | done / success | light |
| `teal` | active | light |
| `blue` | info | light |
| `indigo` | highlight | light |
| `violet` | highlight | light |
| `pink` | highlight | light |
| _(nil/`""`)_ | **no status** | dotted border, muted |

Exact hex values are finalized during implementation (vibrant, WCAG-AA contrast
against their `fg`). `resolve_color(color)`:
- symbol → `PALETTE.fetch(color, PALETTE[:slate])`
- hex string → `{ bg: hex, fg: contrasting_text_color(hex) }`

### Two presentations of the same color
- **Pill** (trigger + display): solid fill, rounded, centered label; caret only
  when editable; X (clearable) appears on hover/focus.
- **Panel row**: solid full-width bar (SmartSuite look); current option gets a
  check + subtle ring; hover darkens via `filter: brightness(.95)` (works for any
  inline color, theme-agnostic).
- **No status**: pill with dotted light-gray border and placeholder text.

Sizes `:xs/:sm/:md` adjust padding + font-size. `:sm` is the DataTable-row default.

## Behavior (editable)

1. Pill is a `<button type="button">` trigger. Click → open panel.
2. Each option is a `<button type="submit">` **inside the same `<form>`**, with
   `name`/`value` = `param` + option value. Selecting submits the form (Turbo);
   the server responds `turbo_stream`, replacing the fragment; the pill updates.
   **No JS needed to set values or synthesize a submit** — plain form semantics.
3. Clearable: an X on the pill (visible on hover/focus) is another
   `<button type="submit">` sending an empty `param`; plus an optional "no status"
   row at the bottom of the panel.
4. Close: click outside, Escape, or after selecting.

### Portal (escape table overflow)
The panel is anchored to the trigger with Floating UI (the same dependency
`Tooltip` already uses for `append_to`) and mounted on `<body>`, so the
DataTable's `overflow` does not clip it. The `status` Stimulus controller handles:
toggle open/close, Floating UI positioning, keyboard (Escape + arrow keys over
`[role="option"]`), and reposition on scroll/resize.

### Server contract (consumer side — unchanged from today's pattern)
Consuming app keeps the existing nested singular `status` resource controller that
responds with `turbo_stream` replacing `dom_id(record, :status)`. The component
does not dictate the controller; it only renders the form that posts to
`form[:url]` with method `form[:method]`. Existing `auto_submit` / dedicated
status controllers in afal-apps can be migrated to render this component in their
turbo-stream partial.

## File structure (sidecar, Bali convention)

```
app/components/bali/status/
  component.rb            # Bali::Status::Component < ApplicationViewComponent
  component.html.erb      # pill trigger + <form> with option rows
  index.js               # StatusController (open/close, floating-ui, keyboard)
  index.css              # shape/sizes/panel (no Tailwind bg-*)
  preview.rb             # Lookbook previews
  previews/*.html.erb    # template-backed examples if needed
```

Registration:
- `app/frontend/bali/components/index.js`: import + export + `application.register('status', StatusController)`.
- `app/frontend/bali/index.js`: export `StatusController` from the components barrel.

`component.rb` idioms (per repo conventions):
- Subclass `Bali::ApplicationViewComponent`; `include Bali::Utils::ColorCalculator`.
- Keyword `initialize` with `**options` passthrough; `&.to_sym` normalization.
- Frozen `PALETTE` / `SIZES` constants; build classes with `class_names(..., @options[:class])`.
- Use `prepend_controller` / `prepend_action` / `prepend_data_attribute` to wire
  Stimulus without clobbering caller `data`.
- `render?` always true (renders at least the pill).

## Testing

- **Minitest** `test/bali/components/status_test.rb` (extends `ComponentTestCase`,
  `render_inline` + `assert_selector`):
  - display-only (no form) renders pill, no trigger button / no form.
  - editable renders `<form>` with the given url/method and one submit per option.
  - `readonly: true` with `form:` renders display-only (no caret, no panel).
  - `clearable: true` renders the X submit + "no status" row.
  - named color applies expected inline `background-color`; hex color applies hex +
    computed contrasting `color`.
  - `selected: nil` renders the "no status" placeholder.
- **Cypress** `cypress/e2e/status-controller.cy.js` (via Lookbook preview URL):
  open panel, select option → form submits, Escape closes, X clears, panel is not
  clipped by an overflow container.

## Lookbook previews

`preview.rb` variants: display-only, editable, editable-inside-a-table (overflow),
readonly-with-form, clearable, hex-color option, no-status/placeholder, all sizes,
full palette swatch gallery.

## Migration note (afal-apps, out of scope for this repo)

Once shipped, `_test_case_status.html.erb` and `_defect_status.html.erb` collapse
to a single `render Bali::Status::Component.new(...)` for both the editable and
read-only branches, and the inline `status_color` hashes move into
`Model.status_options` (or `TDFlowHelper`). Tracked separately; not part of the
Bali PR.
