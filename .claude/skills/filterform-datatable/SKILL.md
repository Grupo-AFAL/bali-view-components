---
name: filterform-datatable
description: Use when building filtered/searchable index views with Bali::FilterForm, Bali::DataTable, or Bali::Filters — covers search_fields quick search, the FilterForm DSL, its methods/parameters, and DataTable filters-panel auto-configuration.
---

# FilterForm + DataTable + Filters Integration

The `Bali::FilterForm`, `Bali::DataTable`, and `Bali::Filters` components work together to provide a complete data filtering solution with minimal configuration.

## The canonical index

This is the composition to copy. It is rendered live as `bali/index_page/complete` in
Lookbook — the only place where all seven control families are on at once. `/admin/movies`
in the dummy app is the same composition against real controllers, routes and Turbo Streams,
saved views included; the only family it leaves out is host toolbar buttons.

```ruby
# Controller
@filter_form = Bali::FilterForm.new(
  Movie.all,
  params,
  search_fields: %i[name genre studio_name], # quick search across these columns
  storage_id: 'admin_movies',                # THE listing identity (see below)
  context: current_user.id,                  # scopes persisted filters to this user
  group_by_attributes: %i[genre status],     # enables the "Group by" control
  saved_views_store: :default,               # enables the "Views" dropdown
  saved_views_owner: current_user
)
@pagy, @movies = pagy(@filter_form.result.includes(:studio))
```

```erb
<%= render Bali::IndexPage::Component.new(title: 'Movies', breadcrumbs: [...]) do |page| %>
  <% page.with_action do %>
    <%= render Bali::Link::Component.new(name: 'New Movie', href: new_movie_path,
                                         variant: :primary, icon_name: 'plus') %>
  <% end %>

  <%# Export lives in the page's ⋯, not in the toolbar: it acts ON the page. The links
      carry the active slice (filters, search, sort, grouping), which is why the item
      reads "Export filtered". The host still has to answer the format — a respond_to
      that only declares html gives a 406 on ?format=csv. %>
  <% page.with_export(url: movies_path) %>

  <%# The DataTable goes in BARE — no Bali::Card around it %>
  <% page.with_body do %>
    <%= render Bali::DataTable::Component.new(
          filter_form: @filter_form, url: movies_path, pagy: @pagy,
          display_mode: params[:view]
        ) do |dt| %>
      <% dt.with_filters_panel(search: { placeholder: 'Search movies...' }) %>

      <%# "Group by" renders itself when the FilterForm declares group_by_attributes AND the
          current display mode applies grouping (default: only :table). In cards the control
          hides, the grouping is suspended and en su lugar queda un cartel que lo dice, pero
          el param sigue en la URL. Si la PRIMERA vista declarada no fuera la tabla, el form
          también necesita el modo: `Bali::FilterForm.new(..., display_mode: params[:view] || :grid)` %>

      <% dt.with_view_switch do |switch| %>
        <% switch.with_view(name: 'Table', icon: 'list', value: :table) %>
        <% switch.with_view(name: 'Cards', icon: 'grid', value: :grid) %>
      <% end %>

      <% dt.with_saved_views %>

      <%# Column 0 is the selection checkbox the Table renders %>
      <% if dt.display_mode == :table %>
        <% dt.with_column_selector do |cs| %>
          <% cs.with_column(index: 1, label: 'Name') %>
          <% cs.with_column(index: 2, label: 'Genre') %>
        <% end %>
      <% end %>

      <% dt.with_bulk_actions do |bulk| %>
        <% bulk.with_action(label: 'Mark as done',
                            href: bulk_actions_movies_path(bulk_action: 'mark_done'),
                            variant: :success) %>
      <% end %>

      <%# ONE content band: declaring two raises DuplicateContent %>
      <% if dt.display_mode == :grid %>
        <% dt.with_grid do %>
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <% @movies.each do |movie| %>
              <%= render Bali::Card::Component.new(style: :bordered) do |card| %>
                <% card.with_title(movie.name) %>
              <% end %>
            <% end %>
          </div>
        <% end %>
      <% else %>
        <% dt.with_table do %>
          <%# `group_counts:` + `group:` son lo que HACE VISIBLE la agrupación: sin los dos, el
              control ofrece agrupaciones cuyo único efecto es reordenar las filas sin ninguna
              banda que lo explique. `group_by_applied` (no `group_by`) es nil cuando la
              agrupación está apagada O suspendida. %>
          <%= render Bali::Table::Component.new(form: @filter_form, selectable: true,
                                                group_counts: @filter_form.group_counts) do |t| %>
            <% t.with_header(name: 'Name', sort: :name) %>
            <% applied = @filter_form.group_by_applied %>
            <% @movies.each do |movie| %>
              <% t.with_row(record_id: movie.id, select_label: movie.name,
                            group: applied && movie.public_send(applied)) do %>
                <td><%= movie.name %></td>
              <% end %>
            <% end %>
          <% end %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

Rules this composition encodes — get these wrong and the page still renders, just wrong:

- **The surface belongs to the content slot, never to the page.** Never wrap a DataTable in
  `Bali::Card`. `with_table` brings its own card + `overflow-x-auto`, `with_grid` brings
  none (the cards *are* the surface), and `with_content(surface: false)` is the escape
  hatch for content with its own chrome (a Gantt, a map). The toolbar and the footer stay
  bare on purpose, in every display mode.
- **One listing, one name.** `storage_id` is the identity: the container id, the column
  selector's target and its localStorage key, the filter-persistence key and the saved
  views scope. There is no `table_id:` and `Bali::Table` needs no `id:`.
- **Read `dt.display_mode`, not the param you passed.** It is the value validated against
  the declared views, so an unknown `?view=` falls back to the first one instead of
  rendering an empty listing. Declare the switch before reading it.
- **Turbo Streams target the RESOLVED identity:**
  `turbo_stream.replace Bali::DataTable::ListingIdentity.for(@filter_form)`. It is
  `storage_id` sanitized into a valid CSS identifier, so the raw value is only the same
  string when it is already a slug (`'admin/movies'` renders as `admin-movies`). Turbo
  resolves the target with `getElementById`: a miss replaces nothing and reports nothing.
  Render the DataTable from a **shared partial** so the HTML and the stream cannot diverge —
  the stream replaces the node that carries the selection controller.
- **Every selectable row needs `select_label:`** (`t.with_row(record_id:, select_label:)`).
  Without it all the checkboxes are called "Select row" and a screen reader's form-controls
  rotor lists N identical entries.
- **`selectable: true` shifts every column by one.** A column selector's 0-based indexes
  must start at 1.
- **Below `sm` the secondary controls move into a `⋯` menu.** Anything in a collapsible
  slot needs an idempotent `connect()` and no `data-turbo-permanent`.

## FilterForm DSL

For reusable filter forms, use the class-level DSL:

```ruby
class MoviesFilterForm < Bali::FilterForm
  # Quick search across multiple columns
  search_fields :name, :genre, :studio_name

  # Filterable attributes for advanced filters UI
  filter_attribute :name, type: :text
  filter_attribute :genre, type: :select, options: [['Action', 'action'], ...]
  filter_attribute :status, type: :select, label: 'Movie Status'
  filter_attribute :created_at, type: :date
  filter_attribute :indie, type: :boolean

  # Standard Ransack attributes
  attribute :name_cont
  attribute :genre_eq
end
```

**Every field here is a Ransack path, and a wrong one fails silently.** An association is
reached by its Ransack name (`studio_name` for `belongs_to :studio`), never by a Ruby
`alias_method` — Ransack does not see those. Because `search_fields` compiles into ONE
combined predicate (`name_or_genre_or_studio_name_cont`), a single unreachable field makes
Ransack drop the whole condition without raising: the search returns 200 and every row. The
same rule applies to `with_header(sort:)` on the table. Assert on the result SET, not the
status code.

**An attribute derived in Ruby (no column) is NOT a reason to bypass Ransack.** Declare a
`ransacker` over a SQL expression or a cached column and it becomes a normal
`filter_attribute` — the full pattern, the pagination anti-pattern it avoids, and the two
real-world worked examples are in `docs/guides/derived-filters.md`.

A `filter_attribute type: :select` over a Rails enum can use the enum LABELS as its option
values (`Movie.statuses.keys`) — Bali translates label to value before the params reach
Ransack, which otherwise casts with the raw column type and turns `"done"` into `0`. Only the
four operators the select UI offers are translated (`eq`, `not_eq`, `in`, `not_in`); a value
that is neither a label nor a raw code matches nothing rather than silently becoming the FIRST
member, so the option values must be the exact `Movie.statuses.keys` strings — `"Done"` is not
`"done"`.

**Warning — association enums are NOT translated.** `filter_attribute :studio_status` (any
Ransack association path) skips the translation, so a select built on its labels returns the
OPPOSITE records, silently. Declare those options with the raw values
(`Studio.statuses.map { |label, value| [label.humanize, value] }`) until this is covered.

### Pills that filter on click (`auto_submit:`)

`auto_submit: true` makes a SimpleFilters filter submit the row as soon as it changes, with no
trip through the Filter button:

```ruby
filter_attribute :status, type: :select, simple: true, advanced: false,
  options: [['Draft', 'draft'], ['Published', 'published']],
  input: :radio_group, auto_submit: true
```

It is **opt-in per filter and off by default**, so no existing row changes behaviour, and the
button stays for the filters that did not opt in. The row mounts `submit-on-change` only when
at least one filter asked for it, and only that filter's controls get the action.

Only `:toggle_group` and `:radio_group` accept it (`AUTO_SUBMIT_INPUTS` in
`lib/bali/filter_form.rb` — it lives on the singleton class next to `SIMPLE_INPUTS`, so it is
not reachable as `Bali::FilterForm::AUTO_SUBMIT_INPUTS`).
Anything else **raises at class-definition time**: one click is the whole interaction on a
pill, whereas a date or number range would submit between the two halves of its value. The
instance-level `simple_filters:` hashes take the same key and are filtered by the component
instead of raising, since they never go through the DSL's validation.

There is no phantom submit on load: `submit-on-change` drops change events fired in the frame
it connects in (see `docs/guides/controllers.md`).

### Date range presets ("This month" instead of two dates)

`presets:` turns an `input: :date_range` simple filter into a period select whose "Custom…"
option reveals the picker. It takes `true` for every token, or an array to pick and order
them:

```ruby
filter_attribute :created_at, type: :date, input: :date_range, simple: true,
                 presets: %i[today this_week this_month], blank: 'Any date'

# or, from an instance-level simple_filters: hash
{ attribute: :created_at, type: :date_range, label: 'Created', presets: true }
```

The tokens are `today`, `this_week`, `this_month`, `last_7_days`, `last_30_days`
(`Bali::DateRangePresets::TOKENS`); the trailing two include today. An unknown one raises at
declaration time.

**The token itself is what travels.** `q[created_at]=this_month` goes in the same param an
explicit range would, and `Bali::Types::DateRangeValue` resolves it to a real range only when
the query runs. That is the whole reason to prefer it over filling in two dates: a saved view
or a persisted filter holding `this_month` still means this month next month, while one
holding `2026-08-01..2026-08-31` means August forever.

It also means the period is the SERVER's — `Time.zone`, the same zone the rest of the date
filtering already speaks. A visitor in another zone sees the boundaries their listing is
actually filtered by, which is the honest answer; computing them in the browser would make
the two disagree.

Presets are `date_range`-only, by design: "this week" is not a value a single `date` filter
can hold, so declaring them on one raises rather than rendering a control that cannot work.
The widget is the shared `time-period-field` Stimulus controller — the same one
`f.time_period_group` builds — so a period select behaves the same wherever it appears.

## FilterForm Architecture

FilterForm is organized into focused concerns for maintainability:

| Concern | File | Responsibility |
|---------|------|----------------|
| `SearchConfiguration` | `lib/bali/filter_form/search_configuration.rb` | Search DSL and methods |
| `FilterGroupParser` | `lib/bali/filter_form/filter_group_parser.rb` | Ransack grouping parsing |
| `EnumCasting` | `lib/bali/filter_form/enum_casting.rb` | Enum label → value translation before Ransack |

## FilterForm Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `search_fields` | `Array<Symbol>` | Configured search field names |
| `search_enabled?` | `Boolean` | True if search is configured |
| `search_value` | `String` | Current search value from params |
| `search_field_name` | `String` | Ransack field name (e.g., `name_or_genre_cont`) |
| `search_config` | `Hash` | The `search:` hash BOTH filter surfaces take (`fields`, `value`, `placeholder`, `icon`) |
| `available_attributes` | `Array<Hash>` | Filter attributes from DSL |
| `filter_groups` | `Array<Hash>` | Parsed filter groups from params |
| `combinator` | `String` | Top-level combinator ('and' or 'or') |
| `active_filter_details` | `Array<Hash>` | Detailed info about active filters |

## FilterForm Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `scope` | `ActiveRecord::Relation` | Required | Base scope to filter |
| `params` | `Hash` | `{}` | Request params containing `q[...]` |
| `storage_id` | `String` | `nil` | **The listing identity.** Filter-persistence cache key, DataTable container id, column-selector target (`#<id> table`) and localStorage key (`bali:columns:<id>`), and the saved-views scope. Without it a DataTable falls back to a random hex and column persistence turns itself off |
| `group_by_attributes` | `Array<Symbol>` | `nil` | Groupable attributes; enables the "Group by" control |
| `group_by_modes` | `Array<Symbol>` | `[:table]` | Display modes that APPLY grouping. Outside them the control hides and the grouping is suspended — but the param survives, so switching back finds it as it was left. Paint rows with `group_by_applied`, never `group_by` |
| `view_param` | `Symbol` | `:view` | URL param carrying the display mode. Must be the SAME one the DataTable gets, or the DataTable raises `ArgumentError` at build time |
| `display_mode` | `Symbol` | `nil` | The mode the listing RENDERS, for when the URL cannot say it. Only needed when the first declared view is not a grouping mode: without `?view=` the form would assume grouping applies and sort the cards by group. Pass what the DataTable gets (`params[:view] \|\| :grid`) |
| `saved_views_store` | `Symbol, Object` | `nil` | `:default` for the engine store, or any object answering `list/find/save/delete`; enables the "Views" dropdown |
| `saved_views_owner` | `Object` | `nil` | Owner the saved views are scoped to (typically `current_user`) |
| `context` | `String` | `nil` | Namespaces the persistence cache key. **Omitting it makes the persisted state process-global** — see below |
| `search_fields` | `Array<Symbol>` | `nil` | Fields for quick text search |
| `search_placeholder` | `String` | `nil` | Placeholder text for search input |
| `persist_enabled` | `Boolean` | `false` | Whether to restore persisted filters. **Needs a real `Rails.cache`** — see below |
| `clear_filters` | `Boolean` | `false` | Clear all persisted filters (via params) |
| `clear_search` | `Boolean` | `false` | Clear only persisted search (via params) |

### Filter persistence needs a real cache store — and a `context:`

Persisted filters live in `Rails.cache` (`FilterForm#fetch_stored_filter_state`), keyed by
`"#{form_class};#{context};#{storage_id}"`. **`context:` is what makes that key per-user**:
without it the key is the same for every request the process serves, so one visitor's filters
and quick-search text are restored for the next one. Pass `current_user.id` (or a session
token when the listing is public). Note the state is written whenever filters are submitted,
even with `persist_enabled: false` — so a user who never turned persistence on still writes to
that shared key.

Under `:null_store` every write silently succeeds and every read returns `nil`,
so the feature does nothing and looks like a bug in Bali: apply filters, navigate away, come
back, nothing restored. Rails' generated `development.rb` defaults to `:null_store` unless
`tmp/caching-dev.txt` exists, so this is the normal state of a fresh app, not an exotic one.
Check `Rails.cache.class` before debugging a persistence report.

## DataTable Auto-Configuration

When a `filter_form` is provided to DataTable, `with_filters_panel` auto-populates:

- `available_attributes` from `filter_form.available_attributes`
- `filter_groups` from `filter_form.filter_groups`
- `search` from `filter_form.search_config`

```erb
<%# Minimal - everything auto-configured %>
<% dt.with_filters_panel %>

<%# Override specific options %>
<% dt.with_filters_panel(
  available_attributes: custom_attributes,  # Override attributes
  search: { placeholder: 'Custom...' }      # Merge with auto-config
) %>
```

`with_simple_filters` resolves `search:` the same way, from the same `search_config`.

### The `search:` shape

One hash, both surfaces (`Bali::SearchConfig`). Declare the **columns**; Bali derives the
Ransack param (`fields: %i[name email]` → `q[name_or_email_cont]`, via
`Bali::RansackParamName`). Any other key raises `ArgumentError` — including v2's
`field_name:`, whose message names the replacement.

| Key | Description |
|-----|-------------|
| `fields` | Columns to search. Empty or absent, no box renders |
| `value` | Current value, rendered back into the box |
| `placeholder` | Placeholder text |
| `label` | Accessible name for the input |
| `icon` | Submit-button glyph in `Filters`, leading addon in `SimpleFilters` |
| `width` | Tailwind width classes for the box |
