# FormBuilder Guide

Bali extends Rails' `ActionView::Helpers::FormBuilder` with DaisyUI-styled form inputs, automatic label/error handling, and Stimulus controller integration.

## Quick Start

```erb
<%= form_with model: @user, builder: Bali::FormBuilder do |f| %>
  <%= f.text_group :name %>
  <%= f.email_group :email %>
  <%= f.password_group :password %>
  <%= f.submit_field "Create Account", variant: :primary %>
<% end %>
```

## Configuration

### Set as Default FormBuilder

```ruby
# config/initializers/bali.rb
ActionView::Base.default_form_builder = Bali::FormBuilder
```

Or use per-form:

```erb
<%= form_with model: @user, builder: Bali::FormBuilder do |f| %>
  <%# ... %>
<% end %>
```

---

## Field Patterns

Every field type is a pair, and the two names are the type plus a suffix:

| Pattern | Method | Description |
|---------|--------|-------------|
| **Group** | `<type>_group` | The control inside a fieldset, with its caption, help text and error message |
| **Field** | `<type>_field` | The bare control, plus its help and error messages |

```erb
<%# With wrapper (label, errors, help text) %>
<%= f.text_group :name %>

<%# Just the input %>
<%= f.text_field :name %>
```

There is no third pattern and no exception to guess at: `select_group` /
`select_field`, `text_group` / `text_field`, `boolean_group` / `boolean_field`,
`text_area_group` / `text_area_field`. Before v3 the wrapper was spelled
`*_field_group` for twenty-three helpers and `*_group` for nine, and the bare
half was `*_field` for some types and the bare type name for others — see
[Migrating from v2 to v3](migration-v2-to-v3.md#the-formbuilder-gets-one-family-of-names)
for the full mapping and the deprecation window.

Rails' own names still work where Bali overrides a Rails helper: `f.text_area`,
`f.rich_text_area` and `f.time_zone_select` render exactly what
`f.text_area_field`, `f.rich_text_area_field` and `f.time_zone_select_field`
render. They are **not** deprecated — Rails and the gems built on it call those
names, and the override is what keeps them producing Bali's markup rather than
falling through to an unstyled control.

### Call shape

**Everything after the field name is a keyword.** The only positional arguments
are the attribute and, where a field type needs one, its data — the choices for
a select, the priority zones for a time zone select:

```erb
<%= f.text_group :name, label: "Full name", help: "As it appears on your ID" %>
<%= f.select_group :status, statuses, include_blank: "Any", label: "Status" %>
<%= f.boolean_group :indie, checked_value: "yes", unchecked_value: "no" %>
```

Attributes that belong on the element itself, rather than options that configure
the field, go in `html:`:

```erb
<%= f.select_group :tags, tags, label: "Tags", html: { multiple: true, class: "w-64" } %>
```

The families that take an `html:` hash are the three select families
(`select_*`, `slim_select_*`, `time_zone_select_*`) and `radio_*`. Every other
field type has a single hash, so there is nothing to choose between.

---

## Text Input Fields

### text_group / text_field

Standard text input with DaisyUI styling.

```erb
<%= f.text_group :name %>
<%= f.text_group :name, placeholder: "Enter your name" %>
<%= f.text_group :name, help: "Your display name" %>
```

**Options:**
- `placeholder` - Placeholder text
- `help` - Help text displayed below input
- `addon_left` - Content to prepend (e.g., "$" for currency)
- `addon_right` - Content to append (e.g., ".com")

### email_group / email_field

```erb
<%= f.email_group :email %>
<%= f.email_group :email, placeholder: "user@example.com" %>
```

### password_group / password_field

```erb
<%= f.password_group :password %>
<%= f.password_group :password_confirmation, label: "Confirm Password" %>
```

### url_group / url_field

```erb
<%= f.url_group :website %>
<%= f.url_group :website, addon_left: "https://" %>
```

### search_group

```erb
<%= f.search_group :query, placeholder: "Search..." %>
```

> **No `search_field`.** Rails already defines one, and unlike `text_area` or
> `time_zone_select` — where Bali's override renders the same control the
> canonical name does — taking this name over would add a submit-button addon
> and a default placeholder to call sites that never asked for either. The bare
> control for a search box is `text_field`; `search_group` is that plus the
> addon and the fieldset.

---

## Number Fields

### number_group / number_field

```erb
<%= f.number_group :quantity %>
<%= f.number_group :quantity, min: 0, max: 100, step: 1 %>
```

### step_number_group / step_number_field

Number input with increment/decrement buttons.

```erb
<%= f.step_number_group :quantity %>
<%= f.step_number_group :quantity, min: 0, max: 10, step: 1 %>
```

**Options:**
- `min` - Minimum value
- `max` - Maximum value
- `step` - Step increment (default: 1)
- `button_class` - Custom class for +/- buttons
- `disabled` - Disable the entire control

### currency_group

Currency input with symbol prefix.

```erb
<%= f.currency_group :price %>
<%= f.currency_group :price, symbol: "€" %>
<%= f.currency_group :price, symbol: "MXN $" %>
```

**Options:**
- `symbol` - Currency symbol (default: "$")

### percentage_group

```erb
<%= f.percentage_group :discount %>
<%= f.percentage_group :tax_rate, symbol: "‰" %>
```

**Options:**
- `symbol` - Symbol appended after the input (default: "%")

### Both are localized, and both need the model side

`currency_group` and `percentage_group` share one implementation
(`numeric_group`) and render a `type="text"` input, because a `type="number"`
input rejects the thousands delimiter as it is typed.

The `pattern` validating that text is **built from the active locale** — Rails'
`number.format.delimiter` and `number.format.separator`. In English it accepts
`1,234.56`; in a locale shipping Spanish number formats it accepts `1.234,56`
and rejects the English shape. There is nothing to configure: if the app has
`rails-i18n` (or defines `number.format` itself) this follows it, and if it does
not, every locale falls back to Rails' English defaults and behaves as before.

`inputmode="decimal"` is set so a phone opens the numeric keypad. `step` is
deliberately **not** set: it is inert on a `type="text"` input, and passing one
only misleads the next person to read the markup.

The browser validates a string. Turning it back into a number is the model's
job, and `Bali::Concerns::NumericAttributesWithCommas` does it against the same
locale:

```ruby
class Product < ApplicationRecord
  include Bali::Concerns::NumericAttributesWithCommas

  currency_attribute :price
  percentage_attribute :discount
end
```

Without the concern the parameter arrives as the string the user typed, and
Rails' own cast reads `"1.234,56"` as `1.234`.

### range_group / range_field

Slider input with optional tick marks.

```erb
<%= f.range_group :volume, min: 0, max: 100, color: :primary %>
<%= f.range_group :price, min: 0, max: 1000, step: 100, show_ticks: true, prefix: "$" %>
<%= f.range_group :rating, min: 1, max: 5, tick_labels: %w[Bad Poor OK Good Great] %>
```

**Options:**
- `min` - Minimum value (default: 0)
- `max` - Maximum value (default: 100)
- `step` - Step increment (default: 1)
- `size` - `:xs`, `:sm`, `:md`, `:lg`, `:xl`
- `color` - `:primary`, `:secondary`, `:accent`, `:success`, `:warning`, `:info`, `:error`
- `show_ticks` - Show tick marks below slider
- `ticks` - Number of tick marks
- `tick_labels` - Custom labels array
- `prefix` - Prefix for auto-generated labels (e.g., "$")
- `suffix` - Suffix for auto-generated labels (e.g., "%")

---

## Text Areas

### text_area_group / text_area

```erb
<%= f.text_area_group :description %>
<%= f.text_area_group :description, rows: 5 %>
```

### rich_text_area_group / rich_text_area

Trix editor with file upload support.

```erb
<%= f.rich_text_area_group :content %>
<%= f.rich_text_area_group :content, attachments: { max_size: 5 } %>
<%= f.rich_text_area_group :content, attachments: { max_size: 10, error_message: "Files must be under 10MB" } %>
```

**Options:**
- `attachments[:max_size]` - Max attachment size in MB (default: 1)
- `attachments[:error_message]` - Custom error message

---

## Select Fields

### select_group / select_field

Native HTML select with DaisyUI styling.

```erb
<%= f.select_group :status, User.statuses.keys.map { |s| [s.humanize, s] } %>
<%= f.select_group :country, Country.all.map { |c| [c.name, c.id] }, include_blank: "Select country" %>
```

**Caption keys work from either hash.** `label:`, `help:` and the other keys the
*group* owns are read from the field's own options and from `html:` alike, the
former winning on a conflict — so there is nothing to get wrong:

```erb
<%= f.select_group :status, statuses, label: "Status", help: "Visible to admins only" %>
```

Before v3 the three select families read those keys from the **second positional
hash** only, so a `help:` written next to `label:` — where every single-hash
field type reads it — reached the wrapper and never reached the paragraph. It
disappeared with no error and no warning.

**Non-model forms** (`form_with url:` without a model): pass `input_name:` /
`input_id:` to namespace the rendered `<select>` under a param key. Also
supported by `slim_select_group`. An explicit `name:`/`id:` in `html:` still
wins.

```erb
<%= f.select_group :approver_id, approvers, input_name: "thing[approver_id]" %>
<%# => <select name="thing[approver_id]" ...> — works with params.require(:thing) %>
```

### slim_select_group / slim_select_field

Enhanced select with search, multi-select, and AJAX support.

```erb
<%# Basic usage %>
<%= f.slim_select_group :category, Category.all.map { |c| [c.name, c.id] } %>

<%# Multi-select %>
<%= f.slim_select_group :tags, Tag.all.map { |t| [t.name, t.id] }, html: { multiple: true } %>

<%# With search %>
<%= f.slim_select_group :user, [], show_search: true, ajax_url: search_users_path, ajax_param_name: 'q' %>

<%# Allow creating new items %>
<%= f.slim_select_group :category, categories, add_items: true %>
```

**Options:**
- `show_search` - Enable search input (default: true)
- `add_items` - Allow adding new items (default: false)
- `close_on_select` - Close dropdown on selection (default: true)
- `allow_deselect_option` - Allow deselecting (default: false)
- `select_all` - Show select all/deselect all buttons (default: false)
- `hide_selected` - Hide selected items from dropdown (default: false)
- `search_highlight` - Highlight search matches (default: false)
- `placeholder` - Placeholder text

**AJAX Options:**
- `ajax_url` - URL to fetch options
- `ajax_param_name` - Query parameter name (default: "q")
- `ajax_value_name` - Value field in response
- `ajax_text_name` - Text field in response

### time_zone_select_group

```erb
<%= f.time_zone_select_group :time_zone %>
<%= f.time_zone_select_group :time_zone, ActiveSupport::TimeZone.us_zones %>
```

---

## Date and Time Fields

### date_group / date_field

Flatpickr-powered date picker.

```erb
<%= f.date_group :birth_date %>
<%= f.date_group :start_date, min_date: Date.today %>
<%= f.date_group :deadline, max_date: 1.year.from_now %>
```

### datetime_group / datetime_field

Date and time picker.

```erb
<%= f.datetime_group :starts_at %>
<%= f.datetime_group :appointment, time_24hr: true %>
```

### time_group / time_field

Time-only picker.

```erb
<%= f.time_group :opening_time %>
<%= f.time_group :closing_time, time_24hr: true %>
```

### month_group / month_field

Month/year picker.

```erb
<%= f.month_group :billing_month %>
```

### Typing into date/time fields

By default, date/datetime/time fields are **typeable** — users can pick a value
from the calendar/time popup or type it directly into the input. The visible
input uses a **numeric display format** (`d/m/Y`, e.g. `31/12/2026`), and Bali
auto-fills a `placeholder:` hint (`dd/mm/yyyy`) so users know what to type:

```erb
<%= f.date_group :birth_date %>
```

**Typed text is parsed against the visible input's format** (flatpickr's
`altFormat`) when the field loses focus; anything that doesn't match is silently
cleared. Pass an explicit `alt_format:` to change that format — the auto-filled
placeholder follows it:

```erb
<%= f.date_group :birth_date, alt_format: 'F j, Y' %>  <%# "December 31, 2026" %>
<%= f.time_group :start_at, alt_format: 'H:i' %>       <%# 24-hour time %>
```

For a verbose format like `'F j, Y'` (a localized month name, which has no
compact literal hint), the placeholder falls back to an i18n sample string
(e.g. "e.g., December 31, 2026"). A caller-supplied `placeholder:` always takes
precedence over the derived hint.

**Opt out with `allow_input: false`** to keep a field read-only — users must
pick a value from the popup and cannot type. The visible input renders with
flatpickr's `readonly` attribute and no placeholder hint:

```erb
<%= f.date_group :birth_date, allow_input: false %>
```

---

## Boolean Fields

### boolean_group / boolean_field

Checkbox input.

```erb
<%= f.boolean_group :terms_accepted %>
<%= f.boolean_group :active, color: :primary, size: :lg %>
<%= f.boolean_group :indie, text: "This is an indie film" %>
```

**Options:**
- `size` - `:xs`, `:sm`, `:md`, `:lg`, `:xl`
- `color` - `:primary`, `:secondary`, `:accent`, `:success`, `:warning`, `:info`, `:error`
- `text` - The caption **beside the checkbox** (default: the translated attribute name).
  `false` renders none.
- `label` - A `<legend>` **over the group**. No default: omit it and no legend is rendered.

### switch_group / switch_field

Toggle switch (styled checkbox).

```erb
<%= f.switch_group :notifications %>
<%= f.switch_field :dark_mode, color: :accent, size: :lg %>
```

**Options:**
- `size` - `:xs`, `:sm`, `:md`, `:lg`, `:xl`
- `color` - `:primary`, `:secondary`, `:accent`, `:success`, `:warning`, `:info`, `:error`
- `text` - The caption **beside the toggle** (default: the translated attribute name)
- `label` - A `<legend>` **over the group**, with no default
- `label_options` - HTML attributes for the `<label>` wrapping the control

### `text:` vs `label:` in these two families

They are two different captions, and until v3 a single `label:` fed both — so
`boolean_group :indie` rendered "Indie" as the legend *and* "Indie" beside
the box, and a screen reader read the field out as "Indie Indie".

- **`text:`** is the caption inside the `<label>` that wraps the control. This is
  where a checkbox's accessible name comes from, so it is the one with a default.
- **`label:`** is the `<legend>` naming the whole fieldset. It renders only when
  you ask for one — that is, when the group caption says something the inline
  text does not.

```erb
<%# One caption, which is what you want almost always %>
<%= f.boolean_group :indie, text: "This is an indie film" %>

<%# Two, when the group needs a heading of its own %>
<%= f.boolean_group :indie, label: "Distribution", text: "This is an indie film" %>
```

The caption stays a `<legend>` rather than becoming a `<label for>` the way the
other field groups' captions did: the control is already inside a `<label>`, and
a second `<label for>` pointing at it does not replace that name, it concatenates
with it.

### radio_group / radio_field

```erb
<%= f.radio_group :status, [["Active", "active"], ["Inactive", "inactive"]] %>
<%= f.radio_group :status, statuses, label: "Status", html: { orientation: :horizontal, color: :primary } %>
```

`html:` carries what each `<input type="radio">` gets, which for this family
includes the daisyUI variants `size:` and `color:` and the list's
`orientation:` (`:vertical`, the default, or `:horizontal`).

### radio_buttons_group / radio_buttons_field

A segmented toggle over grouped radio values.

```erb
<%= f.radio_buttons_group :plan, values, keep_selection: true,
                          togglers: { class: "mb-4" }, radios: { class: "gap-2" } %>
```

`togglers:` and `radios:` are the attributes for the two halves of the control —
the button row and the radio lists it switches between.

---

## File Fields

### file_group / file_field

```erb
<%= f.file_group :avatar %>
<%= f.file_group :documents, multiple: true %>
```

### direct_upload_group

Active Storage direct upload support.

```erb
<%= f.direct_upload_group :avatar %>
```

---

## Submit Buttons

These follow the same `<type>_group` / `<type>_field` split as every field:
`submit_group` renders the button inside the actions row, `submit_field` renders
the button alone. `f.submit` is Rails' name for the bare button and keeps
working, exactly like `f.text_area`.

### submit_field

Styled submit button, on its own.

```erb
<%= f.submit_field "Save" %>
<%= f.submit_field "Save", variant: :primary %>
<%= f.submit_field "Create", variant: :success, size: :lg %>
<%= f.submit "Save" %>  <%# Rails' name for the same thing %>
```

**Options** (validated through `Bali::ButtonTaxonomy`, the same table as `Button`,
`Link` and `DeleteLink` — an unknown value raises naming the replacement):
- `variant` - the colour: `:neutral`, `:primary`, `:secondary`, `:accent`, `:info`, `:success`, `:warning`, `:error`, `:ghost`, `:link`
- `style` - the fill: `:outline`, `:soft`
- `size` - `:xs`, `:sm`, `:md`, `:lg`, `:xl`
- `modal` - Add modal submit action
- `drawer` - Add drawer submit action

### submit_group

The actions row: submit with the cancel control beside it. Spelled
`submit_actions` in v2, which still works for one cycle and warns.

```erb
<%= f.submit_group "Save", cancel_path: users_path %>
<%= f.submit_group "Save", cancel_path: :back %>
<%= f.submit_group "Save", modal: true %>  <%# Cancel closes modal %>
<%= f.submit_group "Save", drawer: true %> <%# Cancel closes drawer %>
```

**Options:**
- `cancel_path` - Path for cancel link
- `cancel_options` - HTML options for cancel link (including `:label`). Cancel renders
  `btn-ghost`: a form has one primary action, and Cancel is the way out of it rather than a
  second thing to do. Pass `class:` here to override.
- `modal` - Integrate with modal controller
- `drawer` - Integrate with drawer controller
- `field_class` - Wrapper class (default: flexbox with gap)

---

## Special Fields

### dynamic_fields_group

Add and remove nested records without a round trip.

The header — a caption plus an "add" button — is rendered for you, and each row
comes from a `_<singular>_fields` partial that the helper renders per associated
record and once more into a `<template>` for the add button to clone.

```erb
<%# app/views/invoices/_form.html.erb %>
<%= f.dynamic_fields_group :line_items, button_text: "Add line item" %>

<%# app/views/invoices/_line_item_fields.html.erb %>
<div class="line_item-fields">
  <%= f.text_group :description %>
  <%= f.number_group :quantity %>
  <%= f.currency_group :price %>
  <%= f.link_to_remove_fields "Remove" %>
</div>
```

Pass a block to replace the whole header:

```erb
<%= f.dynamic_fields_group :line_items do %>
  <h3>Line items</h3>
  <%= f.link_to_add_fields "Add line item", :line_items %>
<% end %>
```

**Options:**
- `label` - Header caption (default: the translated association name)
- `button_text` - Add-button text (default: `bali_view.form_builder.dynamic_fields.add`)
- `button_class` - Add-button classes (default: `btn btn-primary`)
- `partial` - Row partial (default: `_<singular>_fields`)
- `table` - Render the container as a `<tbody>` — see [Table mode](#table-mode)
- `columns` / `table_class` - Table mode only
- `array` - Name the rows `[][key]` — see [Array mode](#array-mode)
- `values` - Rows to render in array mode (default: `object.send(method)`)

`link_to_add_fields` and `link_to_remove_fields` render `<button type="button">`.
The names are historical — they emitted `<a href="#">` until v3 — but nothing
here navigates, so an anchor was announced by screen readers as a link going
nowhere. The `type="button"` matters: these sit inside a `<form>`, where a button
without one submits it.

#### Which mode

| Your rows are… | Mode | Names |
|---|---|---|
| An association with `accepts_nested_attributes_for` | default | `invoice[line_items_attributes][0][price]` |
| The same, but they have to be table rows | `table: true` | same as above |
| A JSON/array attribute — no association, no model per row | `array: true` | `chain[steps][][role]` |

The first two round-trip through `accepts_nested_attributes_for`, so a removed
row that the server already stores is flagged `_destroy` and the record is
deleted on save. Array mode has no records to destroy: the whole array is
replaced by what the form submits.

#### Removing a row

What happens on remove depends on whether the server already knows about the
row, and the marker is the `[id]` hidden field Rails emits only for a persisted
record:

- **Persisted row** — hidden, its visible inputs stripped, and its `_destroy`
  flag set to `true`. It stays in the DOM because the server needs its `id` back
  to know which record to delete.
- **Unsaved row** — removed from the DOM outright. There is nothing to destroy,
  and `_destroy` on a nested hash with no `id` was always a no-op.

Nothing about this needs configuring; it follows from the markup Rails already
emits.

#### Ordinals

Give an element inside the row the `ordinal` target and the controller writes the
row's 1-based number into it after every add, remove and reorder, counting only
the rows still on screen:

```erb
<div class="step-fields">
  <span class="badge" data-dynamic-fields-target="ordinal">1</span>
  …
</div>
```

The target holds the number **alone**. Punctuation around it belongs to the
markup outside the target, so it survives renumbering:

```erb
<span><span data-dynamic-fields-target="ordinal">1</span>.</span>
```

#### Table mode

`table: true` renders the container as the `<tbody>` of a table the helper emits,
so the row partial writes a `<tr>`:

```erb
<%= f.dynamic_fields_group :monetary_lines,
      table: true,
      columns: ["#", "Concept", "Amount", ""],
      table_class: "table table-sm",
      button_text: "Add line" %>
```

```erb
<%# app/views/business_cases/_monetary_line_fields.html.erb %>
<tr class="monetary_line-fields">
  <td><span data-dynamic-fields-target="ordinal">1</span></td>
  <td><%= f.text_field :concept %></td>
  <td><%= f.currency_field :amount %></td>
  <td><%= f.link_to_remove_fields "Remove", class: "btn btn-error btn-sm" %></td>
</tr>
```

`columns:` fills the `<thead>` and is optional — omit it and no `<thead>` is
rendered. `table_class:` defaults to `table`.

The header and its `<template>` render **outside** the `<table>`, which is the
only place they survive. A `<div>` sitting between `<table>` and `<tbody>` is
hoisted out of the table by the HTML parser, and the add button and its template
would go with it. A `<tr>` *inside* the `<template>` is fine: the HTML5 parser
switches to "in table body" for exactly that case, wherever the template sits.

That last point is worth remembering when you write tests. Nokogiri parses HTML4,
where `<template>` is an unknown element and the `<tr>` inside one is dropped, so
a Ruby-level assertion on the parsed document sees an empty template even though
the browser does not. Assert on the rendered string in Minitest and leave the
parsed-DOM half to a system or Cypress test.

#### Array mode

`array: true` is for an attribute that is a plain array of hashes rather than an
association — a JSON column, a serialized attribute, anything with no record per
row. No `fields_for`, no `_destroy`, and no association to reflect on:

```erb
<%= f.dynamic_fields_group :steps,
      array: true,
      partial: "step_fields",
      button_text: "Add step" %>
```

The row partial receives `name_prefix:`, `item:` and `index:` alongside `f`.
`name_prefix` already ends in the empty brackets Rails reads as "next element of
the array", so the partial appends its own key:

```erb
<%# app/views/approval_chains/_step_fields.html.erb %>
<% row_key = index || "new_record" %>
<div class="step-fields">
  <span data-dynamic-fields-target="ordinal"><%= index.to_i + 1 %></span>

  <%= f.text_group :role,
        name: "#{name_prefix}[role]",
        id: "chain_steps_#{row_key}_role",
        control_id: "chain_steps_#{row_key}_role",
        value: item&.dig("role") %>

  <%= f.link_to_remove_fields "Remove", destroy_flag: false %>
</div>
```

Three things about that partial:

- `f` is the **outer** builder. There is no nested record to build a scoped one
  from, so the names come from `name_prefix`, not from `f`. A Bali group takes
  its name through `name:` and its value through `value:`; `input_name:` is a
  different escape hatch that only `select_group` and `slim_select_group`
  understand.
- `control_id:` points the caption's `for` at this row's own control. Without it
  every row's label targets the same id. `new_record` is the placeholder the
  controller swaps for a timestamp when it clones the template, so cloned rows
  get unique ids for free.
- `destroy_flag: false` on the remove button. An array row always leaves the DOM
  on remove, so a `_destroy` key would only add noise to the hash the array
  submits.

Rows come from `object.send(method)` when the object answers to it, or from
`values:` when it does not.

##### Checkboxes do not work in array mode

Rails parses `a[][x]=1&a[][y]=2` by filling one hash until a key repeats, at
which point it starts a new element. A Rails checkbox renders **two** inputs with
the same name — a hidden `0` and the box itself — so a checked box repeats its
key inside the element and splits the array in two, silently, putting the
following fields on the wrong row.

With two rows and one checked box:

```ruby
Rack::Utils.parse_nested_query(
  "c[steps][][role]=Author&c[steps][][active]=0&c[steps][][active]=1" \
  "&c[steps][][role]=Reviewer&c[steps][][active]=0"
)["c"]["steps"]
# => [{"role" => "Author", "active" => "0"},
#     {"active" => "1", "role" => "Reviewer"},
#     {"active" => "0"}]
```

Two rows in, three out, and `active` landed on the wrong one. There is no fix on
the Bali side — it is how the query string is parsed — so **do not put a checkbox
in an array-mode row.** If you need a boolean, either use a `select_group` with
explicit options (one input, one key) or move the collection to a real
association and use the default mode.

The same hazard applies to any control that renders a paired hidden input, which
is why `link_to_remove_fields` takes `destroy_flag: false` here.

### coordinates_polygon_group

Map-based polygon selection.

```erb
<%= f.coordinates_polygon_group :coverage_area %>
```

### recurrent_event_rule_field

Recurring event schedule builder.

```erb
<%= f.recurrent_event_rule_field :schedule %>
```

---

## Common Options

These options work across most field types:

| Option | Description |
|--------|-------------|
| `label` | Custom label text (default: humanized attribute name) |
| `help` | Help text displayed below input |
| `error` | Explicit error message(s) for the field — see [External Errors](#external-errors-error) |
| `placeholder` | Input placeholder |
| `disabled` | Disable the input |
| `readonly` | Make input read-only |
| `class` | Additional CSS classes |
| `data` | Data attributes hash |

### Density (`size:`)

`size:` is the one option with two meanings on a form control, and both work:

- **Symbol** — the daisyUI density variant: `:xs`, `:sm`, `:md`, `:lg`, `:xl`.
  The class joins the control's base classes and no `size` attribute is emitted.
- **Integer** (or String) — the HTML `size` attribute it has always been: width
  in characters on an `<input>`, visible rows on a `<select>`.

```erb
<%= f.text_group :code, size: :sm %>   <%# <input class="input input-sm ..."> %>
<%= f.text_group :code, size: 8 %>     <%# <input size="8" class="input ..."> %>
<%= f.submit_group "Save", size: :sm %> <%# <button class="btn btn-primary btn-sm"> %>
```

A Symbol outside the variant list raises `ArgumentError` instead of leaking
`size="tiny"` into the markup.

Every family takes it, and each one puts the variant on the element it actually
has:

| Family | Class | Notes |
|--------|-------|-------|
| text, email, url, password, number, currency, percentage, numeric, step_number, date, datetime, time, month, search | `input-*` | |
| `select_group`, `time_zone_select_group` | `select-*` | |
| `text_area_group` | `textarea-*` | |
| `range_group` | `range-*` | |
| `boolean_group` | `checkbox-*` | |
| `switch_group` | `toggle-*` | |
| `radio_group` | `radio-*` | in `html:`, like its other input attributes |
| `slim_select_group` | `slim-select-sm` | `:sm` only — the one density the widget has CSS for; the others raise |
| `file_group` | `btn-*` | the native input is hidden, so the density is the CTA button's |
| `submit_group` / `submit_field` | `btn-*` | |

The families whose control is a widget over a hidden field — `rich_text_group`,
`block_editor_group`, `rich_text_area_group`, `coordinates_polygon_group`,
`time_period_group`, `recurrent_event_rule_group`, `direct_upload_group`,
`radio_buttons_group` — ignore the option entirely; there is no daisyUI
component underneath to give a density to.

Captions, help text and error messages take no variant of their own, and need
none: `fieldset-legend` and `fieldset-label` are 12px at every density —
measured on both columns of the **Form / Sizes → Default vs compact** preview.
A validation message is the last thing that should get smaller anyway.

One daisyUI behaviour worth knowing before filing it as a bug: `textarea-sm`
sets the **type size**, not the height. `.textarea` carries `min-height: 5rem`
at every density, so a compact textarea keeps its box and changes its text. Use
`rows:` for the height.

Two spellings the discrimination is worth knowing about:

- `select_group` reads `size:` from either hash (next to `label:` or inside
  `html:`), because Rails copies `:size` out of a select's options onto the
  element and both routes had to be closed.
- `text_area_group` keeps Rails' `size: "20x40"` String, which sets `cols` and
  `rows` — the String half of the rule, doing exactly what it always did.

---

## Error Handling

Bali FormBuilder automatically displays validation errors:

```erb
<%# Errors are shown automatically when present %>
<%= f.text_group :email %>
```

The input gets `input-error` class and error messages appear below.

### External Errors (`error:`)

`error:` carries a message that never lived in `object.errors` — because the
form has no object (`form_with url:`), or because something other than
ActiveModel validated the field. It takes a String, an Array of them, or
nil/false (both render nothing), so the raw return of the validator can be
passed unconditionally:

```erb
<%# A rodauth view: no model, the error comes from rodauth itself %>
<%= form_with url: rodauth.login_path, builder: Bali::FormBuilder do |f| %>
  <%= f.email_group :login, error: rodauth.field_error(rodauth.login_param), required: true %>
  <%= f.password_group :password, error: rodauth.field_error("password") %>
  <%= f.submit_group rodauth.login_button %>
<% end %>
```

The explicit error rides the same plumbing model errors use: the message
paragraph, `aria-invalid` + `aria-describedby`, and the family's `*-error`
class on the control. When the model **also** has errors on the field, the two
join rather than replace — explicit first — mirroring how an error and a help
message both render.

On the two-hash families (`select_*`, `slim_select_*`, `time_zone_select_*`,
`radio_*`) `error:` is a group option: pass it top-level, next to `label:`
(inside `html:` also works).

---

## Addons (Prefix/Suffix)

Add content before or after inputs:

```erb
<%# Currency prefix %>
<%= f.text_group :price, addon_left: "$" %>

<%# URL suffix %>
<%= f.text_group :subdomain, addon_right: ".myapp.com" %>

<%# Icon addon %>
<%= f.text_group :search, addon_left: render(Bali::Icon::Component.new("search")) %>
```

---

## Integration with Stimulus

Many fields automatically integrate with Stimulus controllers:

| Field | Controller | Features |
|-------|------------|----------|
| `slim_select_*` | `slim-select` | Search, multi-select, AJAX |
| `date_field_*` | `datepicker` | Flatpickr integration |
| `datetime_field_*` | `datepicker` | Date + time picking |
| `step_number_field_*` | `step-number-input` | Increment/decrement |
| `rich_text_area_*` | `trix-attachments` | File size limits |
| `submit_field` (with modal) | `modal` | Form submission handling |

---

## Full Example

```erb
<%= form_with model: @product, builder: Bali::FormBuilder, class: "space-y-4" do |f| %>
  <div class="grid grid-cols-2 gap-4">
    <%= f.text_group :name %>
    <%= f.text_group :sku, help: "Stock keeping unit" %>
  </div>

  <%= f.rich_text_area_group :description %>

  <div class="grid grid-cols-3 gap-4">
    <%= f.currency_group :price %>
    <%= f.number_group :quantity, min: 0 %>
    <%= f.percentage_group :discount %>
  </div>

  <%= f.slim_select_group :category_id, Category.all.map { |c| [c.name, c.id] } %>

  <%= f.slim_select_group :tag_ids, Tag.all.map { |t| [t.name, t.id] },
      { select_all: true }, { multiple: true } %>

  <%= f.switch_field :active, color: :success %>
  <%= f.boolean_group :featured %>

  <%= f.submit_group "Save Product", cancel_path: products_path, variant: :primary %>
<% end %>
```
