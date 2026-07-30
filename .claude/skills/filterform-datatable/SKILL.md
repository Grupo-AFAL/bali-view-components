---
name: filterform-datatable
description: Use when building filtered/searchable index views with Bali::FilterForm, Bali::DataTable, or Bali::Filters — covers search_fields quick search, the FilterForm DSL, its methods/parameters, and DataTable filters-panel auto-configuration.
---

# FilterForm + DataTable + Filters Integration

The `Bali::FilterForm`, `Bali::DataTable`, and `Bali::Filters` components work together to provide a complete data filtering solution with minimal configuration.

## The canonical index

This is the composition to copy. It is rendered live as `bali/index_page/complete` in
Lookbook, and as `/admin/movies` in the dummy app.

```ruby
# Controller
@filter_form = Bali::FilterForm.new(
  Movie.all,
  params,
  search_fields: %i[name genre tenant_name], # quick search across these columns
  storage_id: 'admin_movies',                # THE listing identity (see below)
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

  <%# The DataTable goes in BARE — no Bali::Card around it %>
  <% page.with_body do %>
    <%= render Bali::DataTable::Component.new(
          filter_form: @filter_form, url: movies_path, pagy: @pagy,
          display_mode: params[:view]
        ) do |dt| %>
      <% dt.with_filters_panel(search: { placeholder: 'Search movies...' }) %>

      <%# "Group by" renders itself when the FilterForm declares group_by_attributes %>

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

      <% dt.with_export(formats: %i[csv excel pdf], url: movies_path) %>

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
          <%= render Bali::Table::Component.new(form: @filter_form, selectable: true) do |t| %>
            <% t.with_header(name: 'Name', sort: :name) %>
            <% @movies.each do |movie| %>
              <% t.with_row(record_id: movie.id) do %>
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
- **Turbo Streams target the same identity:** `turbo_stream.replace @filter_form.storage_id`.
  Render the DataTable from a **shared partial** so the HTML and the stream cannot diverge —
  the stream replaces the node that carries the selection controller.
- **`selectable: true` shifts every column by one.** A column selector's 0-based indexes
  must start at 1.
- **Below `sm` the secondary controls move into a `⋯` menu.** Anything in a collapsible
  slot needs an idempotent `connect()` and no `data-turbo-permanent`.

## FilterForm DSL

For reusable filter forms, use the class-level DSL:

```ruby
class MoviesFilterForm < Bali::FilterForm
  # Quick search across multiple columns
  search_fields :name, :genre, :tenant_name

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

## FilterForm Architecture

FilterForm is organized into focused concerns for maintainability:

| Concern | File | Responsibility |
|---------|------|----------------|
| `SearchConfiguration` | `lib/bali/filter_form/search_configuration.rb` | Search DSL and methods |
| `FilterGroupParser` | `lib/bali/filter_form/filter_group_parser.rb` | Ransack grouping parsing |

## FilterForm Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `search_fields` | `Array<Symbol>` | Configured search field names |
| `search_enabled?` | `Boolean` | True if search is configured |
| `search_value` | `String` | Current search value from params |
| `search_field_name` | `String` | Ransack field name (e.g., `name_or_genre_cont`) |
| `search_config` | `Hash` | Full config for Filters component |
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
| `saved_views_store` | `Symbol, Object` | `nil` | `:default` for the engine store, or any object answering `list/find/save/delete`; enables the "Views" dropdown |
| `saved_views_owner` | `Object` | `nil` | Owner the saved views are scoped to (typically `current_user`) |
| `context` | `String` | `nil` | Context for cache key namespacing |
| `search_fields` | `Array<Symbol>` | `nil` | Fields for quick text search |
| `search_placeholder` | `String` | `nil` | Placeholder text for search input |
| `persist_enabled` | `Boolean` | `false` | Whether to restore persisted filters |
| `clear_filters` | `Boolean` | `false` | Clear all persisted filters (via params) |
| `clear_search` | `Boolean` | `false` | Clear only persisted search (via params) |

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
