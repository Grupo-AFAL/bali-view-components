# FormBuilder Guide

Bali extends Rails' `ActionView::Helpers::FormBuilder` with DaisyUI-styled form inputs, automatic label/error handling, and Stimulus controller integration.

## Quick Start

```erb
<%= form_with model: @user, builder: Bali::FormBuilder do |f| %>
  <%= f.text_field_group :name %>
  <%= f.email_field_group :email %>
  <%= f.password_field_group :password %>
  <%= f.submit "Create Account", variant: :primary %>
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

Most Bali form helpers follow two patterns:

| Pattern | Method | Description |
|---------|--------|-------------|
| **Group** | `*_field_group` | Wraps input with label, help text, and error messages |
| **Field** | `*_field` | Just the input element with DaisyUI styling |

```erb
<%# With wrapper (label, errors, help text) %>
<%= f.text_field_group :name %>

<%# Just the input %>
<%= f.text_field :name %>
```

---

## Text Input Fields

### text_field_group / text_field

Standard text input with DaisyUI styling.

```erb
<%= f.text_field_group :name %>
<%= f.text_field_group :name, placeholder: "Enter your name" %>
<%= f.text_field_group :name, help: "Your display name" %>
```

**Options:**
- `placeholder` - Placeholder text
- `help` - Help text displayed below input
- `addon_left` - Content to prepend (e.g., "$" for currency)
- `addon_right` - Content to append (e.g., ".com")

### email_field_group / email_field

```erb
<%= f.email_field_group :email %>
<%= f.email_field_group :email, placeholder: "user@example.com" %>
```

### password_field_group / password_field

```erb
<%= f.password_field_group :password %>
<%= f.password_field_group :password_confirmation, label: "Confirm Password" %>
```

### url_field_group / url_field

```erb
<%= f.url_field_group :website %>
<%= f.url_field_group :website, addon_left: "https://" %>
```

### search_field_group / search_field

```erb
<%= f.search_field_group :query, placeholder: "Search..." %>
```

---

## Number Fields

### number_field_group / number_field

```erb
<%= f.number_field_group :quantity %>
<%= f.number_field_group :quantity, min: 0, max: 100, step: 1 %>
```

### step_number_field_group / step_number_field

Number input with increment/decrement buttons.

```erb
<%= f.step_number_field_group :quantity %>
<%= f.step_number_field_group :quantity, min: 0, max: 10, step: 1 %>
```

**Options:**
- `min` - Minimum value
- `max` - Maximum value
- `step` - Step increment (default: 1)
- `button_class` - Custom class for +/- buttons
- `disabled` - Disable the entire control

### currency_field_group

Currency input with symbol prefix.

```erb
<%= f.currency_field_group :price %>
<%= f.currency_field_group :price, symbol: "€" %>
<%= f.currency_field_group :price, symbol: "MXN $" %>
```

**Options:**
- `symbol` - Currency symbol (default: "$")
- `step` - Decimal precision (default: "0.01")

### percentage_field_group

```erb
<%= f.percentage_field_group :discount %>
<%= f.percentage_field_group :tax_rate, addon_right: "%" %>
```

### range_field_group / range_field

Slider input with optional tick marks.

```erb
<%= f.range_field_group :volume, min: 0, max: 100, color: :primary %>
<%= f.range_field_group :price, min: 0, max: 1000, step: 100, show_ticks: true, prefix: "$" %>
<%= f.range_field_group :rating, min: 1, max: 5, tick_labels: %w[Bad Poor OK Good Great] %>
```

**Options:**
- `min` - Minimum value (default: 0)
- `max` - Maximum value (default: 100)
- `step` - Step increment (default: 1)
- `size` - `:xs`, `:sm`, `:md`, `:lg`
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

### slim_select_group / slim_select_field

Enhanced select with search, multi-select, and AJAX support.

```erb
<%# Basic usage %>
<%= f.slim_select_group :category, Category.all.map { |c| [c.name, c.id] } %>

<%# Multi-select %>
<%= f.slim_select_group :tags, Tag.all.map { |t| [t.name, t.id] }, {}, { multiple: true } %>

<%# With search %>
<%= f.slim_select_group :user, [], { show_search: true, ajax_url: search_users_path, ajax_param_name: 'q' } %>

<%# Allow creating new items %>
<%= f.slim_select_group :category, categories, { add_items: true } %>
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

### date_field_group / date_field

Flatpickr-powered date picker.

```erb
<%= f.date_field_group :birth_date %>
<%= f.date_field_group :start_date, min_date: Date.today %>
<%= f.date_field_group :deadline, max_date: 1.year.from_now %>
```

### datetime_field_group / datetime_field

Date and time picker.

```erb
<%= f.datetime_field_group :starts_at %>
<%= f.datetime_field_group :appointment, time_24hr: true %>
```

### time_field_group / time_field

Time-only picker.

```erb
<%= f.time_field_group :opening_time %>
<%= f.time_field_group :closing_time, time_24hr: true %>
```

### month_field_group / month_field

Month/year picker.

```erb
<%= f.month_field_group :billing_month %>
```

---

## Boolean Fields

### boolean_field_group / boolean_field

Checkbox input.

```erb
<%= f.boolean_field_group :terms_accepted %>
<%= f.boolean_field_group :active, color: :primary, size: :lg %>
```

**Options:**
- `size` - `:xs`, `:sm`, `:md`, `:lg`
- `color` - `:primary`, `:secondary`, `:accent`, `:success`, `:warning`, `:info`, `:error`
- `label` - Custom label text

### switch_field_group / switch_field

Toggle switch (styled checkbox).

```erb
<%= f.switch_field_group :notifications %>
<%= f.switch_field :dark_mode, color: :accent, size: :lg %>
```

**Options:**
- `size` - `:xs`, `:sm`, `:md`, `:lg`
- `color` - `:primary`, `:secondary`, `:accent`, `:success`, `:warning`, `:info`, `:error`
- `label` - Custom label text
- `label_options` - HTML attributes for label element

### radio_field_group

```erb
<%= f.radio_field_group :status, [["Active", "active"], ["Inactive", "inactive"]] %>
```

---

## File Fields

### file_field_group / file_field

```erb
<%= f.file_field_group :avatar %>
<%= f.file_field_group :documents, multiple: true %>
```

### direct_upload_field_group

Active Storage direct upload support.

```erb
<%= f.direct_upload_field_group :avatar %>
```

---

## Submit Buttons

### submit

Styled submit button.

```erb
<%= f.submit "Save" %>
<%= f.submit "Save", variant: :primary %>
<%= f.submit "Create", variant: :success, size: :lg %>
```

**Options:**
- `variant` - `:primary`, `:secondary`, `:accent`, `:success`, `:warning`, `:error`, `:ghost`
- `size` - `:xs`, `:sm`, `:md`, `:lg`
- `modal` - Add modal submit action
- `drawer` - Add drawer submit action

### submit_actions

Submit with cancel button.

```erb
<%= f.submit_actions "Save", cancel_path: users_path %>
<%= f.submit_actions "Save", cancel_path: :back %>
<%= f.submit_actions "Save", modal: true %>  <%# Cancel closes modal %>
<%= f.submit_actions "Save", drawer: true %> <%# Cancel closes drawer %>
```

**Options:**
- `cancel_path` - Path for cancel link
- `cancel_options` - HTML options for cancel link (including `:label`)
- `modal` - Integrate with modal controller
- `drawer` - Integrate with drawer controller
- `field_class` - Wrapper class (default: flexbox with gap)

---

## Special Fields

### dynamic_fields

Add/remove fields dynamically.

```erb
<%= f.dynamic_fields :line_items do |builder| %>
  <%= builder.text_field_group :description %>
  <%= builder.number_field_group :quantity %>
  <%= builder.currency_field_group :price %>
<% end %>
```

### coordinates_polygon_field_group

Map-based polygon selection.

```erb
<%= f.coordinates_polygon_field_group :coverage_area %>
```

### recurrent_event_rule_field

Recurring event schedule builder.

```erb
<%= f.recurrent_event_rule_field :schedule %>
```

### lexxy_editor_group

Rich text editor powered by [Lexxy](https://github.com/basecamp/lexxy) (Basecamp's Lexical-based editor). Replaces `rich_text_area_group`.

```erb
<%= f.lexxy_editor_group :body, placeholder: "Write something..." %>
```

With mentions:

```erb
<%= f.lexxy_editor_group :body do |editor| %>
  <% editor.with_prompt(trigger: "@", name: "mention", src: "/people") %>
<% end %>
```

Options: `placeholder`, `toolbar`, `attachments`, `markdown`, `multi_line`, `rich_text`, `required`, `disabled`, `autofocus`, `preset`.

See the full [Lexxy Editor Guide](./lexxy-editor.md) for details.

---

## Common Options

These options work across most field types:

| Option | Description |
|--------|-------------|
| `label` | Custom label text (default: humanized attribute name) |
| `help` | Help text displayed below input |
| `placeholder` | Input placeholder |
| `disabled` | Disable the input |
| `readonly` | Make input read-only |
| `class` | Additional CSS classes |
| `data` | Data attributes hash |

---

## Error Handling

Bali FormBuilder automatically displays validation errors:

```erb
<%# Errors are shown automatically when present %>
<%= f.text_field_group :email %>
```

The input gets `input-error` class and error messages appear below.

### Manual Error Display

```erb
<% if @user.errors[:email].any? %>
  <p class="text-error text-sm"><%= @user.errors[:email].join(", ") %></p>
<% end %>
```

---

## Addons (Prefix/Suffix)

Add content before or after inputs:

```erb
<%# Currency prefix %>
<%= f.text_field_group :price, addon_left: "$" %>

<%# URL suffix %>
<%= f.text_field_group :subdomain, addon_right: ".myapp.com" %>

<%# Icon addon %>
<%= f.text_field_group :search, addon_left: render(Bali::Icon::Component.new("search")) %>
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
| `submit` (with modal) | `modal` | Form submission handling |

---

## Full Example

```erb
<%= form_with model: @product, builder: Bali::FormBuilder, class: "space-y-4" do |f| %>
  <div class="grid grid-cols-2 gap-4">
    <%= f.text_field_group :name %>
    <%= f.text_field_group :sku, help: "Stock keeping unit" %>
  </div>

  <%= f.lexxy_editor_group :description, placeholder: "Product description..." %>

  <div class="grid grid-cols-3 gap-4">
    <%= f.currency_field_group :price %>
    <%= f.number_field_group :quantity, min: 0 %>
    <%= f.percentage_field_group :discount %>
  </div>

  <%= f.slim_select_group :category_id, Category.all.map { |c| [c.name, c.id] } %>

  <%= f.slim_select_group :tag_ids, Tag.all.map { |t| [t.name, t.id] },
      { select_all: true }, { multiple: true } %>

  <%= f.switch_field :active, color: :success %>
  <%= f.boolean_field_group :featured %>

  <%= f.submit_actions "Save Product", cancel_path: products_path, variant: :primary %>
<% end %>
```
