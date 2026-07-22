# Component Usage Guide

This guide covers how to use Bali ViewComponents in your Rails views.

## Basic Rendering

All Bali components use Rails' ViewComponent library. Render them using the standard `render` helper:

```erb
<%= render Bali::Button::Component.new(name: 'Click Me') %>
```

## Component Naming Convention

Components follow this naming pattern:

```ruby
Bali::[Name]::Component
```

Examples:
- `Bali::Button::Component`
- `Bali::Card::Component`
- `Bali::Modal::Component`

---

## Common Parameters

Most components share these standard parameters:

| Parameter | Type | Description |
|-----------|------|-------------|
| `variant` | Symbol | Style variant (`:primary`, `:secondary`, etc.) |
| `size` | Symbol | Size modifier (`:xs`, `:sm`, `:md`, `:lg`, `:xl`) |
| `class` | String | Additional CSS classes |
| `data` | Hash | Data attributes for Stimulus |
| `**options` | Hash | Any additional HTML attributes |

---

## Variants and Sizes

### Standard Variants

DaisyUI semantic colors available on most components:

| Variant | Use Case |
|---------|----------|
| `:primary` | Main actions, emphasis |
| `:secondary` | Secondary actions |
| `:accent` | Highlights, special elements |
| `:success` | Positive feedback, confirmations |
| `:warning` | Cautions, attention needed |
| `:error` | Errors, destructive actions |
| `:info` | Informational |
| `:neutral` | Subdued, neutral |
| `:ghost` | Minimal styling |

### Standard Sizes

| Size | Description |
|------|-------------|
| `:xs` | Extra small |
| `:sm` | Small |
| `:md` | Medium (usually default) |
| `:lg` | Large |
| `:xl` | Extra large |

---

## Components with Slots

Many components use ViewComponent slots for flexible content composition.

### Understanding Slots

Slots allow you to inject content into specific areas of a component:

```erb
<%= render Bali::Card::Component.new do |card| %>
  <% card.with_header { "Card Title" } %>
  <% card.with_actions do %>
    <%= render Bali::Button::Component.new(name: 'Save') %>
  <% end %>

  <%# Default content goes in the body %>
  <p>This is the card content.</p>
<% end %>
```

### Slot Types

| Syntax | Description |
|--------|-------------|
| `renders_one :name` | Single slot (0 or 1 instance) |
| `renders_many :name` | Multiple slots (0 or more instances) |

### Common Slot Patterns

**Single content slot:**
```erb
<%= render Bali::Card::Component.new do |c| %>
  <% c.with_title("My Title") %>
  Card body content here
<% end %>
```

**Multiple slots:**
```erb
<%= render Bali::Tabs::Component.new do |tabs| %>
  <% tabs.with_tab(label: "Tab 1") { "Content 1" } %>
  <% tabs.with_tab(label: "Tab 2") { "Content 2" } %>
  <% tabs.with_tab(label: "Tab 3") { "Content 3" } %>
<% end %>
```

**Slots with parameters:**
```erb
<%= render Bali::Card::Component.new do |c| %>
  <% c.with_image(src: "/image.jpg", alt: "Description") %>
  <% c.with_actions do %>
    <%= render Bali::Button::Component.new(name: 'Action', variant: :primary) %>
  <% end %>
<% end %>
```

---

## Component Categories

### Layout Components

#### AppLayout

Top-level page shell. Renders `<body>` directly with optional banner, navbar,
sidebar, topbar, and main body slots. Designed for admin shells but the
slots are independent so non-shell layouts work too.

```erb
<%= render Bali::AppLayout::Component.new(fixed_sidebar: true) do |layout| %>
  <% layout.with_sidebar do %>
    <%= render 'layouts/admin_sidebar' %>  <%# typically a Bali::SideMenu %>
  <% end %>
  <% layout.with_topbar do %>
    <%= render 'layouts/admin_topbar' %>   <%# typically a Bali::Topbar %>
  <% end %>
  <% layout.with_body do %>
    <%= yield %>
  <% end %>
<% end %>
```

**Options:**
- `fixed_sidebar` - Sidebar uses `position: fixed`; content gets left padding (default: false)
- `viewport_locked` - Body locks to 100vh; only inner `<main>` scrolls (Linear/Notion app-shell pattern). Defaults to `fixed_sidebar` value — pass explicitly to decouple
- `body_container` - `:wide` (default), `:contained`, `:narrow`, `:full`
- `flash` - Pass `flash` for built-in toast notifications
- `modal` / `drawer` - Render shared modal/drawer slots (default: true)

**Decoupled scroll model**:
| `fixed_sidebar` | `viewport_locked` | Behavior |
|-----------------|-------------------|----------|
| `true` | `true` (default) | Full app shell — sidebar + topbar pinned, only body scrolls |
| `true` | `false` | Fixed sidebar but page scrolls (long forms) |
| `false` | `true` | Topbar pinned, no sidebar |
| `false` | `false` | Marketing-style page scroll |

#### Topbar

Top-of-content bar that sits inside the AppLayout's `with_topbar` slot. 56px
tall to align horizontally with the SideMenu's brand row. Slots: brand,
search, actions (many), user_menu.

```erb
<%= render Bali::Topbar::Component.new do |topbar| %>
  <% topbar.with_search do %>
    <%= render Bali::Command::Component.new do |cmd| %>
      <% cmd.with_trigger do %>
        <button type="button" class="...">Search… <kbd>⌘K</kbd></button>
      <% end %>
      <% cmd.with_group(name: "Pages") do |g| %>
        <% g.with_item(title: "Dashboard", icon: 'layout-dashboard', href: '/') %>
      <% end %>
    <% end %>
  <% end %>

  <% topbar.with_action do %>
    <button class="btn btn-ghost btn-sm btn-square" aria-label="Notifications">
      <%= render Bali::Icon::Component.new('bell', class: 'size-5') %>
    </button>
  <% end %>

  <% topbar.with_user_menu do %>
    <%= render Bali::Dropdown::Component.new do |d| %>
      <%# avatar + dropdown items %>
    <% end %>
  <% end %>
<% end %>
```

**Options:**
- `mobile_trigger_id` - ID of the sidebar's mobile checkbox (renders the `lg:hidden` hamburger). Defaults to `Bali::SideMenu::Component::MOBILE_TRIGGER_ID`. Pass `nil` for layouts without a sidebar

#### Card

Content container with optional header, image, and actions.

```erb
<%= render Bali::Card::Component.new(style: :bordered, shadow: true) do |c| %>
  <% c.with_image(src: "/photo.jpg") %>
  <% c.with_title("Card Title") %>
  <p>Card description text.</p>
  <% c.with_actions do %>
    <%= render Bali::Button::Component.new(name: 'Details', variant: :primary) %>
  <% end %>
<% end %>
```

**Options:**
- `style` - `:default`, `:bordered`, `:dash`
- `size` - `:xs`, `:sm`, `:md`, `:lg`, `:xl`
- `side` - Horizontal layout (image on side)
- `image_full` - Image overlays entire card
- `shadow` - Enable shadow (default: true)

#### Modal

Dialog overlay for focused interactions.

```erb
<%= render Bali::Modal::Component.new(title: "Confirm Action") do |modal| %>
  <% modal.with_trigger do %>
    <%= render Bali::Button::Component.new(name: 'Open Modal') %>
  <% end %>

  <p>Are you sure you want to proceed?</p>

  <% modal.with_actions do %>
    <%= render Bali::Button::Component.new(name: 'Cancel', variant: :ghost, data: { action: 'modal#close' }) %>
    <%= render Bali::Button::Component.new(name: 'Confirm', variant: :primary) %>
  <% end %>
<% end %>
```

#### Drawer

Slide-in panel from edge of screen.

```erb
<%= render Bali::Drawer::Component.new(title: "Settings", position: :right) do |drawer| %>
  <% drawer.with_trigger { "Open Settings" } %>
  <%# Drawer content %>
  <p>Drawer panel content here.</p>
<% end %>
```

**Turbo Stream form submits** (Modal and Drawer): forms submitted with the
`modal#submit`/`drawer#submit` action and `data-turbo="true"` accept
`text/vnd.turbo-stream.html` responses — the streams are applied to the page
and the modal/drawer closes on success (an error stream keeps it open so the
form can re-render inside). Redirect and HTML responses behave as before.

```erb
<%# In the drawer content %>
<%= form_with model: @tag, data: { turbo: true } do |f| %>
  ...
  <%= render Bali::Button::Component.new(name: 'Save', data: { action: 'drawer#submit' }) %>
<% end %>
```

```ruby
# Controller — partial update instead of full-page redirect
respond_to do |format|
  format.turbo_stream do
    render turbo_stream: [
      turbo_stream.replace('systems-card', partial: 'systems_card'),
      turbo_stream.append('toast-notifications', partial: 'toast')
    ]
  end
end
```

#### Columns

Responsive column layout that stacks on mobile and sits side-by-side on `md+`; pass `cols:` to switch to CSS Grid auto-flow mode (no `with_column` wrappers needed).

```erb
<%= render Bali::Columns::Component.new(gap: :lg) do |c| %>
  <% c.with_column(size: :one_third) do %>
    Sidebar content
  <% end %>
  <% c.with_column do %>
    Main content fills remaining space
  <% end %>
<% end %>
```

**Options:**
- `gap` - Space between columns: `:none`, `:px`, `:xs`, `:sm`, `:md`, `:lg`, `:xl`, `:'2xl'` (default: `:md`)
- `cols` - Grid columns 1-12; enables grid auto-flow mode where children render directly (default: `nil`)
- `cols_md` - Grid columns at the `md` breakpoint, 768px+ (default: `nil`)
- `cols_lg` - Grid columns at the `lg` breakpoint, 1024px+ (default: `nil`)
- `cols_xl` - Grid columns at the `xl` breakpoint, 1280px+ (default: `nil`)
- `wrap` - Allow columns to wrap to multiple lines (default: `false`)
- `center` - Center columns horizontally (default: `false`)
- `middle` - Center columns vertically (default: `false`)
- `mobile` - Keep columns horizontal on mobile instead of stacking (default: `false`)

#### Hero

Full-width hero section (DaisyUI `hero`) with title, subtitle, and action slots.

```erb
<%= render Bali::Hero::Component.new(size: :md, color: :primary) do |c| %>
  <% c.with_title('Hello there') %>
  <% c.with_subtitle('Provident cupiditate voluptatem et in.') %>
  <% c.with_actions do %>
    <%= render Bali::Button::Component.new(name: 'Get Started', variant: :secondary) %>
  <% end %>
<% end %>
```

**Options:**
- `size` - Minimum height: `:sm`, `:md`, `:lg` (full screen) (default: `:md`)
- `color` - Background color: `:base`, `:primary`, `:secondary`, `:accent`, `:neutral` (default: `:base`)
- `centered` - Center-align the hero content (default: `true`)

#### Level

Horizontal bar that spreads content between left and right sides, wrapping on small screens; use `with_item` directly when positioning is not needed.

```erb
<%= render Bali::Level::Component.new(align: :center) do |c| %>
  <% c.with_left do |l| %>
    <% l.with_item(text: 'Left Item 1') %>
    <% l.with_item(text: 'Left Item 2') %>
  <% end %>
  <% c.with_right do |r| %>
    <% r.with_item(text: 'Right Item 1') %>
  <% end %>
<% end %>
```

**Options:**
- `align` - Vertical alignment of items: `:start`, `:center`, `:end` (default: `:center`)

#### PageHeader

Page-level header with title, subtitle, optional back button, and right-aligned content (the block).

```erb
<%= render Bali::PageHeader::Component.new(
  title: 'Movies',
  subtitle: 'Manage your catalog',
  back: { href: movies_path }
) do %>
  <%= render Bali::Link::Component.new(name: 'New Movie', href: new_movie_path, type: :primary) %>
<% end %>
```

**Options:**
- `title` - Title text; use the `with_title` slot for a custom tag or classes (default: `nil`)
- `subtitle` - Subtitle text; use the `with_subtitle` slot for a custom tag or classes (default: `nil`)
- `align` - Vertical alignment of left/right content: `:top`, `:center`, `:bottom` (default: `:center`)
- `back` - Back button options hash, requires `href` (e.g. `{ href: path }`) (default: `nil`)
- `responsive` - Apply tighter spacing on small screens (default: `true`)

#### Footer

Responsive site footer (DaisyUI `footer`) with brand, link sections, and bottom copyright slots.

```erb
<%= render Bali::Footer::Component.new(color: :neutral) do |footer| %>
  <% footer.with_brand(name: 'ACME Industries', description: 'Providing reliable tech since 1992.') %>
  <% footer.with_section(title: 'Company') do |section| %>
    <% section.with_link(name: 'About us', href: '/about') %>
    <% section.with_link(name: 'Contact', href: '/contact') %>
  <% end %>
  <% footer.with_bottom do %>
    <p>Copyright 2026 - All rights reserved</p>
  <% end %>
<% end %>
```

**Options:**
- `color` - Background color preset: `:neutral`, `:base`, `:primary`, `:secondary` (default: `:neutral`)
- `center` - Center-align footer content (default: `false`)

---

### Navigation Components

#### SideMenu

Vertical sidebar with brand row, sectioned nav, optional module switcher, and
bottom-pinned items. Used inside `Bali::AppLayout`'s `with_sidebar` slot.

```erb
<%= render Bali::SideMenu::Component.new(current_path: request.path, collapsible: true) do |menu| %>
  <%# Brand slot — accepts icon + text or any custom HTML %>
  <% menu.with_brand do %>
    <%= lucide_icon('clapperboard', size: 24) %>
    <span class="truncate">My App</span>
  <% end %>

  <%# Optional: multiple modules → renders a switcher dropdown above the lists %>
  <% menu.with_menu_switch(title: 'Admin', icon: 'shield', href: admin_root_path) %>
  <% menu.with_menu_switch(title: 'Reports', icon: 'bar-chart-3', href: reports_path) %>

  <% menu.with_list(title: 'Main') do |list| %>
    <% list.with_item(name: 'Dashboard', href: '/', icon: 'layout-dashboard', match: :exact) %>
    <% list.with_item(name: 'Movies', href: movies_path, icon: 'film', match: :crud) %>
  <% end %>

  <% menu.with_bottom_group(name: 'Settings', icon: 'settings') do |group| %>
    <% group.with_item(name: 'Profile', href: '#', icon: 'circle-user') %>
    <% group.with_item(name: 'Sign out', href: '#', icon: 'log-out') %>
  <% end %>
<% end %>
```

**Options:**
- `current_path` (required) - For active-state matching
- `fixed` - Fixed-to-viewport sidebar (default: true)
- `collapsible` - Show desktop collapse toggle and icon-only collapsed state
- `brand` - Simple text brand. For richer brand (logo + text, custom HTML), use the `with_brand` slot instead
- `group_behavior` - `:expandable` (default, DaisyUI collapse) or `:dropdown` (hover dropdown for nested items)

**Brand row aligns** with `Bali::Topbar` (both 56px) so they form one continuous chrome divider when paired in `Bali::AppLayout`.

**Match types** for `with_item`: `:exact`, `:partial`, `:starts_with`, `:crud` (matches `/path` and `/path/123/edit` etc).

#### Command

⌘K-style command palette / launcher. Modal panel with search input, grouped
results, keyboard navigation, and a global ⌘K (Mac) / Ctrl+K (Windows) shortcut.

```erb
<%= render Bali::Command::Component.new(placeholder: 'Search…') do |c| %>
  <% c.with_trigger do %>
    <button type="button" class="...">
      <%= render Bali::Icon::Component.new('search') %>
      <span>Search…</span>
      <kbd class="kbd kbd-xs">⌘K</kbd>
    </button>
  <% end %>

  <% c.with_group(name: 'Pages') do |g| %>
    <% g.with_item(title: 'Dashboard', meta: 'Overview', icon: 'layout-dashboard', href: '/') %>
    <% g.with_item(title: 'Movies', meta: 'Catalog', icon: 'film', href: movies_path) %>
  <% end %>

  <% c.with_group(name: 'Recents', mode: :recent) do |g| %>
    <% g.with_item(title: 'Last viewed doc', icon: 'file-text', href: '/docs/1') %>
  <% end %>

  <% c.with_group(name: 'Actions', mode: :action) do |g| %>
    <% g.with_item(title: 'New movie', meta: 'Create a record', icon: 'plus', href: new_movie_path) %>
  <% end %>
<% end %>
```

**Group modes:**
- `:searchable` (default) - Items only show when the query matches `title + meta`
- `:recent` - Only shown when query is empty (recent activity)
- `:action` - Always shown (used as a fallback when no matches)

**Options:**
- `placeholder` - Search input placeholder
- `density` - `:default` (44px rows) or `:compact` (32px rows)
- `no_results_text` / `no_results_subtitle` - Empty-state copy
- `shortcut_label` - Display label for the shortcut hint (default `⌘K`). Actual binding is hardcoded to ⌘K/Ctrl+K

**Triggers:**
- `with_trigger` slot — any clickable element opens the palette (input-shaped buttons are common)
- Global keyboard: ⌘K (Mac) / Ctrl+K (Windows/Linux)
- Window events: `bali:command:open` / `bali:command:close` / `bali:command:toggle`

**Keyboard:** ↑/↓ to navigate, ⏎ to activate, Esc to close.

#### Breadcrumb

Navigation path indicator.

```erb
<%= render Bali::Breadcrumb::Component.new do |bc| %>
  <% bc.with_item(href: "/") { "Home" } %>
  <% bc.with_item(href: "/products") { "Products" } %>
  <% bc.with_item { "Current Page" } %>  <%# No href = current %>
<% end %>
```

#### Tabs

Tabbed content navigation.

```erb
<%= render Bali::Tabs::Component.new(variant: :boxed) do |tabs| %>
  <% tabs.with_tab(label: "Overview", active: true) do %>
    Overview content...
  <% end %>
  <% tabs.with_tab(label: "Details") do %>
    Details content...
  <% end %>
<% end %>
```

#### Dropdown

Action menu that opens on click/hover.

```erb
<%= render Bali::Dropdown::Component.new do |dd| %>
  <% dd.with_trigger { "Options" } %>
  <% dd.with_item(href: "/edit") { "Edit" } %>
  <% dd.with_item(href: "/delete", class: "text-error") { "Delete" } %>
<% end %>
```

#### Stepper

Step indicator for multi-stage flows. Steps accept an optional `sublabel:`
(event date, actor, status note) rendered as a smaller muted line under the
title, or a free content block for arbitrary markup.

```erb
<%= render Bali::Stepper::Component.new(current: 2) do |s| %>
  <% s.with_step(title: "Proposed", sublabel: "07/01 · Luis Pérez") %>
  <% s.with_step(title: "Approved", sublabel: "07/03 · Ana Gutiérrez") %>
  <% s.with_step(title: "Published") do %>
    <span class="text-xs opacity-60">release #12</span>
  <% end %>
  <% s.with_step(title: "Active") %>
<% end %>
```

**Options:**
- `current` - Zero-based index of the active step
- `orientation` - `:horizontal` (default) or `:vertical`
- `color` - DaisyUI step color for completed/active steps

#### Pagination

Pagination controls (DaisyUI `join` buttons) built from a Pagy object; renders nothing when there is only one page.

```erb
<%= render Bali::Pagination::Component.new(pagy: @pagy, size: :sm, variant: :outline) %>
```

**Options:**
- `pagy` - The Pagy pagination object (required)
- `size` - Button size: `:xs`, `:sm`, `:md`, `:lg` (default: `:md`)
- `variant` - Button variant: `:default`, `:outline`, `:ghost` (default: `:default`)
- `url` - Base URL for pagination links (default: `nil`, uses the request path)

#### PaginationFooter

Footer row combining a "Showing X-Y of Z items" summary with `Pagination` controls; renders nothing without a Pagy object.

```erb
<%= render Bali::PaginationFooter::Component.new(pagy: @pagy, item_name: 'movies') %>
```

**Options:**
- `pagy` - Pagy object for pagination (required)
- `item_name` - Name for items in the summary text (default: `nil`, falls back to "items")
- `show_summary` - Whether to show the summary text (default: `true`)
- `show_pagination` - Whether to show pagination controls (default: `true`)

---

### Data Display Components

#### Table

Data table with optional sorting and pagination.

```erb
<%= render Bali::Table::Component.new(zebra: true) do |table| %>
  <% table.with_header(name: "Name", sort: :name) %>
  <% table.with_header(name: "Email") %>
  <% table.with_header(name: "Status") %>

  <% @users.each do |user| %>
    <% table.with_row do |row| %>
      <% row.with_cell { user.name } %>
      <% row.with_cell { user.email } %>
      <% row.with_cell { render Bali::Tag::Component.new(text: user.status, color: status_color(user)) } %>
    <% end %>
  <% end %>
<% end %>
```

**Row grouping** — pass `group:` to `with_row` to render a group-header row
whenever the value changes between consecutive rows. The header spans every
column (including the bulk-actions column when present) and shows the group
value plus the count of rows in that run (e.g. `Norte (12)`).

```erb
<%= render Bali::Table::Component.new do |table| %>
  <% table.with_header(name: "Leader") %>
  <% table.with_header(name: "Role") %>

  <%# leaders must already be ordered by area %>
  <% @leaders.each do |leader| %>
    <% table.with_row(group: leader.area_name) do %>
      <td><%= leader.name %></td>
      <td><%= leader.role %></td>
    <% end %>
  <% end %>
<% end %>
```

Caveats:

- **Ordering is the caller's responsibility.** The component never re-sorts;
  it only compares each row's `group:` against the previous row. The same value
  reappearing later starts a *new* group header. Sort server-side by the group
  field so equal values are adjacent. When you drive grouping through
  `Bali::FilterForm#group_by` (see **Query-aware grouping** below) this is
  handled for you, and user column sorts remain compatible as a *secondary*
  sort.
- **Pagination splits groups.** With Pagy a group that spans a page boundary
  restarts on the next page, because each page only sees its own slice of rows.
  Pass `group_counts:` (below) so the header still shows the group's *global*
  total plus a "showing N" hint on the split page.
- **Zebra striping shifts.** `table-zebra` stripes by `:nth-child`, so injected
  header rows offset the alternating background of the data rows. This is
  cosmetic and expected.
- **Group headers are not sticky.** They scroll with the table body even when
  `sticky_headers: true` (which only pins the `<thead>`), so the two never
  overlap.
- Rows given `group: nil` (or with no `group:` while other rows have one) are
  collected under a localized "Ungrouped" header (i18n
  `bali.table.ungrouped`). When **no** row has a `group:`, the table renders
  exactly as it does without the feature — no header rows.

**Query-aware grouping (FilterForm + DataTable)** — driving grouping through
`Bali::FilterForm` upgrades the page-local behavior above: groups are ordered by
the query, counts are global, and the "Agrupar por" control persists the choice
in the URL.

Declare groupable attributes on the form (DSL or constructor):

```ruby
class MoviesFilterForm < Bali::FilterForm
  group_by_attribute :genre, label: "Género"
  group_by_attribute :status
end

# or, without subclassing:
Bali::FilterForm.new(Movie.all, params, group_by_attributes: [:genre, :status])
```

`group_by` is a **whitelisted top-level param** (not a `q[...]` predicate). The
raw value only takes effect when it matches a declared attribute — anything else
is ignored, so it can never reach `.group()`/`.order()` (Ransack does not
authorize `.group`). When active, the form:

- orders the query by the group field **first**, keeping any user column sort as
  the **secondary** sort — so column sorting and grouping now coexist
  (sort-within-groups); and
- exposes `group_counts`, the **global** per-group totals over the full filtered
  (unpaginated) result.

Wire it into the view — `DataTable` auto-renders the "Agrupar por" control
whenever the form declares group_by attributes, and the `Table` shows global
counts when you pass `group_counts:`:

```erb
<%= render Bali::DataTable::Component.new(url: request.path, filter_form: @filter_form, pagy: @pagy) do |c| %>
  <% c.with_simple_filters %>          <%# control renders itself beside the filters %>
  <% c.with_table do %>
    <%= render Bali::Table::Component.new(form: @filter_form, group_counts: @filter_form.group_counts) do |t| %>
      <%= t.with_header(name: "Name", sort: :name) %>
      <%= t.with_header(name: "Genre", sort: :genre) %>
      <% @movies.each do |movie| %>
        <%= t.with_row(group: @filter_form.group_by && movie.public_send(@filter_form.group_by)) do %>
          <td><%= movie.name %></td>
          <td><%= movie.genre %></td>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

A split group then reads e.g. `Norte (30) — showing 25` (i18n
`bali.table.group_partial`). The count lookup is tolerant of string-vs-symbol
keys and falls back to the page-local count on a miss.

Constraints:

- **Do not `.reorder` the relation after `result`** when grouping — it drops the
  group-first ordering and rows stop cohering into groups. Let the form own the
  order.
- **`group_by` is not persisted** in the FilterForm filters cache. It lives only
  in the URL (the "Agrupar por" links carry it, and the filter forms round-trip
  it as a hidden field), so it resets when the URL does.

#### Avatar

User avatar display.

```erb
<%= render Bali::Avatar::Component.new(
  src: user.avatar_url,
  alt: user.name,
  size: :md,
  shape: :circle
) %>
```

#### Tag (Badge)

Labels and status indicators.

```erb
<%= render Bali::Tag::Component.new(text: "New", color: :primary) %>
<%= render Bali::Tag::Component.new(text: "Pending", color: :warning, outline: true) %>
```

#### Status

Colorful, SmartSuite-style status pill with optional inline editing. Presentational and domain-agnostic — colors come from a fixed palette or a hex string, rendered as inline styles so it looks the same across DaisyUI themes with no Tailwind safelist.

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

**Options:**
- `selected` - Currently selected value, matched against each option's `value:` (default: nil)
- `options` - Array of `{ value:, label:, color: }`; `color:` is a palette symbol (`:slate :gray :red :orange :amber :yellow :green :teal :blue :indigo :violet :pink`) or a hex string (default: `[]`)
- `form` - `{ url:, method:, param: }`; when present (and `readonly:` is false) the pill becomes clickable and opens a portaled panel of colored option rows that submits via Turbo on selection (default: nil)
- `readonly` - Forces the read-only pill even when `form:` is given, e.g. permission-gated call sites (default: false)
- `clearable` - Adds a clear (X) button and a "no status" row to the panel; only applies when editable (default: false)
- `size` - `:xs`, `:sm`, `:md` (default: `:sm`)
- `placeholder` - Text shown when nothing is selected (default: i18n `bali.status.no_status`, "No status")
- `**html_options` - Additional HTML attributes for the wrapper `span`; the consumer owns the Turbo target id via `id:` passthrough

The consuming controller responds with a Turbo Stream replacing the element identified by the `id:` you pass.

#### Progress

Progress bar indicator.

```erb
<%= render Bali::Progress::Component.new(value: 75, max: 100, color: :primary) %>
```

#### ImageGrid

Responsive image gallery with optional lightbox and empty state.

```erb
<%= render Bali::ImageGrid::Component.new(columns: 4, expandable: true) do |grid| %>
  <% grid.with_empty_state do %>
    <p class="text-sm text-base-content/60"><%= t('bali.image_grid.empty_state.title') %></p>
    <%= render Bali::Link::Component.new(name: t('bali.image_grid.empty_state.add_image'),
          href: new_image_path, type: :primary) %>
  <% end %>
  <% @images.each do |image| %>
    <% grid.with_image(full_src: image.full_url) { image_tag image.thumb_url } %>
  <% end %>
<% end %>
```

The `empty_state` slot renders inside a dashed-border centered box instead of
the grid when there are no images; it is ignored when images are present.
i18n keys `bali.image_grid.empty_state.{title,add_image}` ship in en/es.

#### BooleanIcon

Displays a boolean value as a colored icon — a green check for true, a red cross for false (nil is treated as false). Useful in table cells and lists.

```erb
<%= render Bali::BooleanIcon::Component.new(value: movie.indie?) %>
```

**Options:**
- `value` - Boolean value to display; nil is coerced to false (required)
- `**options` - Additional HTML attributes for the wrapper div

#### Chart

Renders a Chart.js chart (bar, line, pie, doughnut, polarArea) with theme-aware colors, optionally wrapped in a DaisyUI card.

```erb
<%= render Bali::Chart::Component.new(
  data: {
    labels: %w[Mon Tue Wed Thu Fri],
    datasets: [
      { label: 'Sales', data: [120, 190, 300, 250, 420] },
      { label: 'Returns', data: [20, 30, 25, 35, 40] }
    ]
  },
  type: :bar,
  title: 'Weekly Sales Report',
  legend: true,
  card_style: :default
) %>
```

**Options:**
- `type` - Chart type or array of types for mixed charts: `:bar`, `:line`, `:pie`, `:doughnut`, `:polarArea` (default: `:bar`)
- `data` - Simple hash `{ "Mon" => 10 }` or multi-series `{ labels: [...], datasets: [...] }` (default: `{}`)
- `title` - Chart title shown in the card header (default: nil)
- `legend` - Show the legend (default: false)
- `display_percent` - Display values as percentages (default: false)
- `order` - Dataset draw order, one entry per dataset (default: `[]`)
- `y_axis_ids` - Y-axis IDs per dataset for multi-axis charts (default: `[]`)
- `options` - Custom Chart.js options, deep-merged over defaults (default: `{}`)
- `card_style` - Card wrapper: `:default`, `:bordered`, `:compact`, `:none` (default: `:none`)
- `height` - Height preset: `:sm`, `:md`, `:lg`, `:xl` (default: `:md`)
- `use_theme_colors` - Use DaisyUI theme colors for series, grid, and tooltips (default: true)

#### DataTable

Complete data table wrapper with filters, quick search, summary, and pagination. Integrates with `Bali::FilterForm` — when a `filter_form` is given, `with_filters_panel` auto-configures attributes, filter groups, and search.

```erb
<%= render Bali::DataTable::Component.new(filter_form: @filter_form, url: movies_path, pagy: @pagy) do |dt| %>
  <% dt.with_filters_panel(search: { placeholder: 'Search movies...' }) %>
  <% dt.with_table do %>
    <%= render Bali::Table::Component.new(form: @filter_form) do |t| %>
      <% t.with_header(name: 'Name', sort: :name) %>
      ...
    <% end %>
  <% end %>
<% end %>
```

**Options:**
- `url` - Base URL for filtering/sorting links (required)
- `filter_form` - `Bali::FilterForm` instance for Ransack integration (default: nil)
- `pagy` - Pagy object for pagination (default: nil)
- `show_summary` - Show record summary (default: true when pagy present)
- `summary_position` - `:top` or `:bottom` (default: `:bottom`)
- `item_name` - Item name used in the summary text (default: i18n)
- `table_class` - CSS class for the table wrapper (default: `"overflow-x-auto"`)
- `display_mode` - `:table` or `:grid` (default: `:table`)

Slots: `with_filters_panel`, `with_simple_filters`, `with_table`, `with_grid`, `with_summary`, `with_toolbar_button`, `with_column_selector`, `with_export`, `with_actions_panel`, `with_custom_pagy_nav`.

#### GanttChart

Interactive Gantt chart with nested tasks, dependencies, milestones, drag/resize editing, and day/week/month zoom levels.

```erb
<%= render Bali::GanttChart::Component.new(tasks: [
  { id: 1, name: 'Task 1', start_date: Date.current, end_date: Date.current + 16.days, update_url: '/tasks/1' },
  { id: 2, name: 'Task 1.1', start_date: Date.current, end_date: Date.current + 10.days, parent_id: 1, update_url: '/tasks/2' }
], zoom: :day) do |c| %>
  <% c.with_view_mode_button(label: 'Day', zoom: :day, active: true) %>
  <% c.with_view_mode_button(label: 'Week', zoom: :week, active: false) %>
  <% c.with_footer { 'This is a footer' } %>
<% end %>
```

**Options:**
- `tasks` - Array of task hashes (`id`, `name`, `start_date`, `end_date`, `update_url`, plus optional `parent_id`, `dependent_on_id`, `progress`, `milestone`, `critical`, `href`, `actions`) (default: `[]`)
- `row_height` - Row height in pixels (default: 35)
- `col_width` - Column width in pixels (default: 25 for day zoom, 100 for week/month)
- `zoom` - `:day`, `:week`, or `:month` (default: `:day`)
- `readonly` - Disable drag/resize editing (default: false)
- `offset` - Initial horizontal scroll offset in pixels (default: scrolls near today)
- `resource_name` - Resource name sent with update requests (default: nil)
- `list_param_name` - Param name used when reordering tasks (default: `"list_id"`)
- `start_date` - Chart start date string; computed from tasks when nil (default: nil)
- `colors` - Hash with `:default` and `:completed` task bar colors (via `**options`)

Slots: `with_view_mode_button`, `with_footer`, `with_list_footer`.

#### Heatmap

Grid visualization that shows magnitude as color intensity across two dimensions, e.g. activity by day and hour.

```erb
<%= render Bali::Heatmap::Component.new(
  data: {
    Mon: { 9 => 5, 10 => 8, 11 => 3 },
    Tue: { 9 => 3, 10 => 6, 11 => 9 }
  },
  color: :primary
) do |c| %>
  <% c.with_x_axis_title('Days') %>
  <% c.with_y_axis_title('Hours') %>
  <% c.with_hovercard_title('Clicks by hour of day') %>
  <% c.with_legend_title('Clicks') %>
<% end %>
```

**Options:**
- `data` - Hash of `{ x_label => { y_label => value } }` (required)
- `color` - DaisyUI preset (`:primary`, `:secondary`, `:accent`, `:success`, `:info`, `:warning`, `:error`) or hex string (default: `:primary`)
- `cell_size` - Cell size in pixels (default: 28)
- `responsive` - Stretch to fill container width (default: true)

Slots: `with_x_axis_title`, `with_y_axis_title`, `with_legend_title`, `with_hovercard_title`.

#### Icon

Renders an icon by name, resolving Lucide icons first (1,600+ available), then kept brand/regional icons, then legacy Bali icons.

```erb
<%= render Bali::Icon::Component.new('check', size: :large) %>
<%= render Bali::Icon::Component.new('alert', class: 'text-error') %>
```

**Options:**
- `name` - Icon name: Bali name, Lucide name, or kept brand/regional icon (required, positional)
- `tag_name` - Wrapper HTML tag (default: `:span`)
- `size` - `:small`, `:medium`, `:large`, or an integer in pixels (default: nil, renders at 16px)
- `**options` - Additional HTML attributes (e.g. `class`)

#### InfoLevel

Horizontal row of heading/title stat items, useful for profile counts or summary metrics.

```erb
<%= render Bali::InfoLevel::Component.new(align: :center) do |c| %>
  <% c.with_item do |i| %>
    <% i.with_heading('Posts') %>
    <% i.with_title('128') %>
  <% end %>
  <% c.with_item do |i| %>
    <% i.with_heading('Followers') %>
    <% i.with_title('12.3K') %>
  <% end %>
<% end %>
```

**Options:**
- `align` - Item alignment: `:start`, `:center`, `:end`, `:between` (default: `:center`)
- `**options` - Additional HTML attributes

Slots: `with_item` (each item takes `with_heading` and `with_title`, as text or block).

#### LabelValue

Displays a small bold label above its value — a common pattern on show pages.

```erb
<%= render Bali::LabelValue::Component.new(label: 'Name', value: 'Juan Perez') %>

<%# Block content is used when value: is nil %>
<%= render Bali::LabelValue::Component.new(label: 'URL') do %>
  <a href="#" class="link link-primary">Download link</a>
<% end %>
```

**Options:**
- `label` - Label text shown above the value (required)
- `value` - Value to display; when nil, block content is rendered instead (default: nil)
- `**options` - Additional HTML attributes

#### List

Vertical list of rows (DaisyUI `list`) where each item has a title, subtitle, optional actions, and extra content.

```erb
<%= render Bali::List::Component.new do |c| %>
  <% c.with_item do |i| %>
    <% i.with_title('First item') %>
    <% i.with_subtitle('Description of the first item') %>
    <% i.with_action do %>
      <%= render Bali::Button::Component.new(name: 'Delete', variant: :error, size: :sm, icon: 'trash') %>
    <% end %>
  <% end %>
<% end %>
```

**Options:**
- `borderless` - Remove the outer border and rounded box (default: false)
- `relaxed_spacing` - Add extra vertical padding to rows (default: false)
- `**options` - Additional HTML attributes

Slots: `with_item` (each item takes `with_title`, `with_subtitle`, and repeatable `with_action`; extra block content renders in the middle column).

#### LocationsMap

Interactive Google Map with location markers, optional info views, clustering, and linked location cards. Requires the `GOOGLE_MAPS_KEY` environment variable to be set with a Google Maps JavaScript API key.

```erb
<%= render Bali::LocationsMap::Component.new(zoom: 12, clustered: false) do |c| %>
  <% c.with_location(latitude: 32.5253, longitude: -117.0166) %>
  <% c.with_location(latitude: 32.5284, longitude: -117.0197, color: 'green') %>
  <% c.with_location(latitude: 32.5162, longitude: -117.0129) do |location| %>
    <% location.with_info_view { tag.p('This is an info view') } %>
  <% end %>
  <% c.with_card(latitude: 32.5253, longitude: -117.0166) { tag.p('Card 1') } %>
<% end %>
```

**Options:**
- `center_latitude` - Map center latitude (default: 32.5036383, Tijuana)
- `center_longitude` - Map center longitude (default: -117.0308968)
- `zoom` - Initial map zoom level (default: 12)
- `clustered` - Enable marker clustering (default: false)

**Slots:** `with_location` (markers, support `color`, `label`, `icon_url`, and a nested `with_info_view`), `with_card` (cards rendered beside the map that highlight when their marker is clicked).

#### PropertiesTable

Displays key-value pairs in a zebra-striped table — useful for showing object attributes on detail pages.

```erb
<%= render Bali::PropertiesTable::Component.new do |c| %>
  <% c.with_property(label: 'Name', value: 'John Doe') %>
  <% c.with_property(label: 'Email', value: 'john@example.com') %>
  <% c.with_property(label: 'Member Since', value: 'January 2024') %>
<% end %>
```

**Options:**
- `**options` - Additional HTML attributes for the table (e.g. `class`)

**Slots:** `with_property(label:, value:)` — properties also accept block content for rich values like tags or links.

#### Rate

Star rating built on DaisyUI's rating classes, with Rails form integration, auto-submit, and readonly display modes.

```erb
<%# Form input %>
<%= render Bali::Rate::Component.new(form: f, method: :rating, value: 3) %>

<%# Readonly display %>
<%= render Bali::Rate::Component.new(value: 4, readonly: true) %>
```

**Options:**
- `value` - Current rating value (required)
- `form` - Rails form builder for form integration (default: nil)
- `method` - Model attribute name for the input (default: nil)
- `scale` - Range of selectable ratings (default: 1..5)
- `size` - Star size: `:xs`, `:sm`, `:md`, `:lg` (default: :md)
- `color` - Star color: `:warning`, `:primary`, `:secondary`, `:accent`, `:success`, `:error`, `:info` (default: :warning)
- `auto_submit` - Submit the form immediately when a star is clicked (default: false)
- `readonly` - Display-only mode with disabled inputs (default: false)

#### Skeleton

Loading placeholder with preset patterns for common layouts (text, paragraphs, cards, avatars, buttons, modals, lists).

```erb
<%= render Bali::Skeleton::Component.new(variant: :paragraph, lines: 3) %>
<%= render Bali::Skeleton::Component.new(variant: :list, lines: 4) %>
```

**Options:**
- `variant` - Preset pattern: `:text`, `:paragraph`, `:card`, `:avatar`, `:button`, `:modal`, `:list` (default: :text)
- `size` - Line height / avatar size: `:xs`, `:sm`, `:md`, `:lg` (default: :sm)
- `lines` - Number of lines/items for `:paragraph` and `:list` variants (default: 3)

#### StatCard

Metric card showing a title, value, and colored icon — ideal for dashboard KPI rows.

```erb
<%= render Bali::StatCard::Component.new(
  title: 'Total Users',
  value: '1,234',
  icon_name: 'users',
  color: :primary
) do |c| %>
  <% c.with_footer { tag.span('+12% from last month', class: 'text-success') } %>
<% end %>
```

**Options:**
- `title` - Metric label (required)
- `value` - Metric value to display (required)
- `icon_name` - Bali/Lucide icon name (required)
- `color` - Icon accent: `:primary`, `:secondary`, `:accent`, `:success`, `:warning`, `:error`, `:info` (default: :primary)

**Slots:** `with_footer` — optional footer for trends or status text.

#### Tags

Groups multiple Tag components in a wrapping flex container with configurable gap spacing. Renders nothing when no items are given.

```erb
<%= render Bali::Tags::Component.new(gap: :sm) do |c| %>
  <% c.with_item(text: 'Ruby', color: :primary) %>
  <% c.with_item(text: 'Rails', color: :success, style: :outline) %>
  <% c.with_item(text: 'Docs', href: '/docs', color: :info) %>
<% end %>
```

**Options:**
- `gap` - Spacing between tags: `:none`, `:xs`, `:sm`, `:md`, `:lg` (default: :sm)

**Slots:** `with_item(text:, href:, **options)` — each item accepts any `Bali::Tag` option (`color`, `style`, `size`, `rounded`); `href` renders it as a link.

#### Timeago

Displays relative time ("5 minutes ago") using date-fns for localized formatting, with optional auto-refresh.

```erb
<%= render Bali::Timeago::Component.new(article.created_at, add_suffix: true) %>

<%# Live-updating timestamp %>
<%= render Bali::Timeago::Component.new(user.last_seen_at, add_suffix: true, refresh_interval: 30000) %>
```

**Options:**
- `datetime` - The time to display, passed as the first positional argument (required)
- `add_suffix` - Append "ago"/"in" to the output (default: false)
- `refresh_interval` - Auto-refresh interval in milliseconds, `nil` disables (default: nil)
- `include_seconds` - Include seconds for distances under a minute (default: true)

#### Timeline

Vertical timeline for chronological sequences of events, using DaisyUI's timeline with headers, icons, and color variants.

```erb
<%= render Bali::Timeline::Component.new(position: :left) do |c| %>
  <% c.with_tag_header(text: 'Start', color: :primary) %>
  <% c.with_tag_item(heading: 'January 2022', icon: 'check', color: :success) do %>
    <p>Timeline event 1</p>
  <% end %>
  <% c.with_tag_item(heading: 'February 2022') do %>
    <p>Timeline event 2</p>
  <% end %>
  <% c.with_tag_header(text: 'End') %>
<% end %>
```

**Options:**
- `position` - Timeline layout: `:left`, `:center`, `:right` (default: :left)

**Slots:** `with_tag_header(text:, color:)` (badge separators) and `with_tag_item(heading:, icon:, color:)` with block content.

#### TreeView

File/folder-style navigation tree with expandable nested sections. Branches containing the `current_path` expand automatically and the active item is highlighted.

```erb
<%= render Bali::TreeView::Component.new(current_path: request.path) do |c| %>
  <% c.with_item(name: 'Home', path: '/') %>
  <% c.with_item(name: 'Documentation', path: '/docs') do |docs| %>
    <% docs.with_item(name: 'Introduction', path: '/docs/introduction') %>
    <% docs.with_item(name: 'Installation', path: '/docs/installation') %>
  <% end %>
<% end %>
```

**Options:**
- `current_path` - Path of the active item, used for highlighting and auto-expanding branches (default: nil)

**Slots:** `with_item(name:, path:)` — items nest recursively via a block to build sub-trees.

---

### Interactive Components

#### Button

Primary interactive element for actions.

```erb
<%# Basic %>
<%= render Bali::Button::Component.new(name: 'Save', variant: :primary) %>

<%# With icon %>
<%= render Bali::Button::Component.new(name: 'Add', variant: :success, icon_name: 'plus') %>

<%# Loading state %>
<%= render Bali::Button::Component.new(name: 'Processing...', loading: true, disabled: true) %>

<%# Icon slots %>
<%= render Bali::Button::Component.new(name: 'Next', variant: :primary) do |btn| %>
  <% btn.with_icon_right('arrow-right') %>
<% end %>
```

**Options:**
- `name` - Button text
- `variant` - Style variant
- `size` - Size modifier
- `icon_name` - Left icon name
- `type` - `:button`, `:submit`, `:reset`
- `disabled` - Disable button
- `loading` - Show loading spinner

#### Link

Navigation links, optionally styled as buttons.

```erb
<%# Plain link %>
<%= render Bali::Link::Component.new(name: 'View Details', href: item_path(@item)) %>

<%# Link styled as button %>
<%= render Bali::Link::Component.new(
  name: 'Create New',
  href: new_item_path,
  type: :primary  # Button styling
) %>
```

**When to use Button vs Link:**
- Use `Button` for **actions** (submit, click handlers)
- Use `Link` for **navigation** (goes to a URL)

#### Tooltip

Contextual information on hover.

```erb
<%= render Bali::Tooltip::Component.new(content: "More information", position: :top) do %>
  Hover over me
<% end %>
```

#### Kanban

Kanban board built on SortableList with drag-and-drop between columns. Each
column maps to a status value sent to the server on drop. Columns accept an
optional `footer` slot rendered outside the sortable list (never draggable) —
the classic "+ add card" action.

```erb
<%= render Bali::Kanban::Component.new(resource_name: "task", group_name: "board") do |k| %>
  <% k.with_column(title: "To Do", status: "todo", color: :ghost) do |col| %>
    <% col.with_card(update_url: task_path(task)) { render TaskCard.new(task:) } %>
    <% col.with_footer do %>
      <%= link_to "+ Add card", new_task_path(status: :todo) %>
    <% end %>
  <% end %>
<% end %>
```

#### ConfirmDialog

DaisyUI-styled `<dialog>` that replaces Turbo's native `window.confirm` for
every `data-turbo-confirm` (including `DeleteLink` and `ActionsDropdown`
delete items). Auto-installed via `registerAll` — no per-app code needed.

```erb
<%# Any turbo confirm gets the styled dialog automatically %>
<%= button_to "Delete", thing_path(thing), method: :delete,
      data: { turbo_confirm: "Delete this thing?" } %>

<%# Per-trigger customization %>
<%= button_to "Close project", close_project_path(project),
      data: {
        turbo_confirm: "Close this project?",
        bali_confirm_title: "Close project",
        bali_confirm_variant: "warning",
        bali_confirm_accept: "Close it"
      } %>
```

Opt out globally with `window.BALI_DISABLE_CONFIRM_DIALOG = true` before
`registerAll` runs.

#### ActionsDropdown

Dropdown menu for row-level actions with an ellipsis icon trigger. Items with `method: :delete` automatically render a DeleteLink with confirmation.

```erb
<%= render Bali::ActionsDropdown::Component.new(align: :end) do |c| %>
  <% c.with_item(name: 'Edit', icon_name: 'edit', href: edit_movie_path(movie)) %>
  <% c.with_item(name: 'Export', icon_name: 'file-export', href: export_movie_path(movie)) %>
  <% c.with_item(name: 'Delete', icon_name: 'trash', href: movie_path(movie), method: :delete) %>
<% end %>
```

**Options:**
- `align` - Horizontal alignment: `:start`, `:center`, `:end` (default: `:start`)
- `direction` - Menu direction: `:top`, `:bottom`, `:left`, `:right` (default: `nil`)
- `icon` - Trigger icon name (default: `"ellipsis-h"`)
- `width` - Menu width: `:sm`, `:md`, `:lg`, `:xl` (default: `:md`)
- `popover` - Use Tippy.js popover to escape overflow containers like scrollable tables (default: `false`)

Use `with_trigger` to replace the default icon button with a custom trigger element.

#### BulkActions

Selectable item list with a floating action bar that appears when items are selected, showing a counter and bulk action buttons.

```erb
<%= render Bali::BulkActions::Component.new do |c| %>
  <% c.with_action(label: 'Archive', href: bulk_archive_users_path, variant: :info) %>
  <% c.with_action(label: 'Delete', href: bulk_delete_users_path, variant: :error) %>

  <% @users.each do |user| %>
    <% c.with_item(record_id: user.id, class: 'flex items-center gap-3 p-3') do %>
      <input type="checkbox" class="checkbox checkbox-sm">
      <p><%= user.name %></p>
    <% end %>
  <% end %>
<% end %>
```

**Options:**
- `**options` - HTML attributes for the wrapper (e.g. `class`, `data`)

#### Carousel

Image/content carousel powered by Glide.js with optional arrows, bullets, autoplay, and multi-slide layouts.

```erb
<%= render Bali::Carousel::Component.new(slides_per_view: 3, gap: 16, autoplay: :slow) do |c| %>
  <% c.with_arrows %>
  <% c.with_bullets %>

  <% @images.each do |image| %>
    <% c.with_item do %>
      <%= image_tag image, class: 'w-full rounded-lg' %>
    <% end %>
  <% end %>
<% end %>
```

**Options:**
- `slides_per_view` - Number of slides visible at once (default: `1`)
- `start_at` - Index of the initial slide (default: `0`)
- `autoplay` - `:disabled`, `:slow` (5s), `:medium` (3s), `:fast` (1.5s), or milliseconds (default: `:disabled`)
- `gap` - Space between slides in pixels (default: `0`)
- `focus_at` - Which slide to focus: `:center` or an index (default: `:center`)
- `breakpoints` - Hash of responsive settings passed to Glide.js (default: `nil`)
- `peek` - Pixels of adjacent slides to show at the edges (default: `nil`)

#### Clipboard

Copy-to-clipboard button with visual success feedback (shown for 2 seconds after copying).

```erb
<%= render Bali::Clipboard::Component.new do |c| %>
  <% c.with_trigger('Copy') %>
  <% c.with_success_content('Copied!') %>
  <% c.with_source('https://example.com/api/v1/token/abc123xyz') %>
<% end %>
```

**Options:**
- `**options` - HTML attributes for the wrapper; customize feedback duration with `data: { clipboard_success_duration_value: 3000 }`

#### DeleteLink

Delete button that submits a DELETE request and automatically triggers the styled ConfirmDialog (danger variant) before submitting.

```erb
<%= render Bali::DeleteLink::Component.new(model: @movie) %>
<%= render Bali::DeleteLink::Component.new(href: movie_path(@movie), name: 'Remove', size: :sm, icon: true) %>
```

**Options:**
- `model` - Record used to build the URL and the confirmation message (default: `nil`)
- `href` - Explicit URL; either `model` or `href` is required (default: `nil`)
- `name` - Button label (default: translated "Delete")
- `confirm` - Custom confirmation message (default: `nil`, generated from model)
- `size` - `:xs`, `:sm`, `:md`, `:lg` (default: `nil`)
- `disabled` - Disable the button (default: `false`)
- `disabled_hover_url` - URL for a hover card explaining why deletion is disabled (default: `nil`)
- `skip_confirm` - Skip the confirmation dialog (default: `false`)
- `icon` - Show a trash icon (default: `false`)
- `icon_name` - Custom icon name (default: `nil`)
- `authorized` - When `false`, the component does not render (default: `true`)
- `plain` - Render as a plain text link instead of a button (default: `false`)
- `form_class` - Extra classes for the wrapping form (default: `nil`)

#### HoverCard

Popup card that displays content on hover (or click), positioned with Tippy.js. Content can be inline or lazy-loaded from a URL.

```erb
<%= render Bali::HoverCard::Component.new(placement: 'top', hover_url: user_summary_path(@user)) do |c| %>
  <% c.with_trigger do %>
    <button class="btn btn-primary">Hover me!</button>
  <% end %>
<% end %>
```

**Options:**
- `hover_url` - URL to fetch content from asynchronously (default: `nil`)
- `placement` - Tippy.js placement, e.g. `auto`, `top`, `bottom-start`, `right-end` (default: `"auto"`)
- `open_on_click` - Open on click instead of hover (default: `false`)
- `append_to` - Where to append the popup: `'body'`, `'parent'`, or CSS selector (default: `"body"`)
- `z_index` - Z-index for the popup (default: `9999`)
- `content_padding` - Add padding around the content (default: `true`)
- `arrow` - Show an arrow pointing to the trigger (default: `true`)

#### Reveal

Collapsible content section toggled by a trigger with a rotating chevron indicator.

```erb
<%= render Bali::Reveal::Component.new(opened: false) do |c| %>
  <% c.with_trigger do |trigger| %>
    <% trigger.with_title do %>
      <span class="text-lg font-semibold">Click to see contents</span>
    <% end %>
  <% end %>

  <p>This content is hidden until you click the trigger above.</p>
<% end %>
```

**Options:**
- `opened` - Render with the content revealed initially (default: `false`)

#### SortableList

Drag-and-drop sortable list using SortableJS; supports handles, nested lists, and cross-list moves — this component powers the Kanban board. Dropping an item sends a PATCH to that item's `update_url` with its new `position` (and `list_id` for cross-list moves).

```erb
<%= render Bali::SortableList::Component.new(group_name: 'tasks', list_id: list.id) do |s| %>
  <% @tasks.each do |task| %>
    <% s.with_item(update_url: task_path(task)) do %>
      <%= task.name %>
    <% end %>
  <% end %>
<% end %>
```

**Options:**
- `resource_name` - Resource name to namespace params, e.g. `'task'` sends `task[position]` (default: `nil`)
- `position_param_name` - Name of the position param sent to the server (default: `"position"`)
- `list_param_name` - Name of the list param sent to the server (default: `"list_id"`)
- `group_name` - Group name linking multiple lists so items can move between them (default: `nil`)
- `list_id` - Identifier for this list in cross-list moves (default: `nil`)
- `response_kind` - `:html` or `:turbo_stream` (default: `:html`)
- `handle` - CSS selector for the drag handle; without one, whole items are draggable (default: `nil`)
- `disabled` - Disable dragging (default: `false`)
- `animation` - Drag animation duration in milliseconds (default: `150`)

---

### Form Components

#### Filters

Advanced filter controls for data tables with Ransack integration.

```erb
<%= render Bali::Filters::Component.new(
  url: products_path,
  filter_form: @filter_form,
  available_attributes: [
    { key: :name, label: 'Name', type: :text },
    { key: :status, label: 'Status', type: :select, options: Status.options }
  ]
) %>
```

**Features:**
- Multiple filter groups with AND/OR combinators
- Type-specific operators (text, number, date, select, boolean)
- Quick search with clear button (x) for easy clearing
- Filter persistence with bookmark toggle
- Date range "between" operator with Flatpickr

**Modes:**
- `popover: true` (default) - Compact dropdown with search input
- `popover: false` - Inline card layout

**Search Clear Button:**

The search input includes a clear button (x) that appears when text is entered. Clicking it:
- Clears the search input
- Submits `clear_search=1` to clear persisted search
- Preserves other filters

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `url` | String | Required | Form action URL |
| `filter_form` | FilterForm | Required | FilterForm instance |
| `available_attributes` | Array | `[]` | Filterable attributes |
| `popover` | Boolean | `true` | Use popover mode |
| `storage_id` | String | `nil` | Enable persistence |

#### SearchInput

Search field with icon.

```erb
<%= render Bali::SearchInput::Component.new(
  name: 'q',
  placeholder: 'Search...',
  value: params[:q]
) %>
```

#### Calendar

Month, week, or day calendar that displays events grouped by date, with optional navigation header and custom day templates.

```erb
<%= render Bali::Calendar::Component.new(
  start_date: Date.current,
  period: :month,
  events: @events,
  template: 'events/calendar_event'
) do |c| %>
  <% c.with_header(route_path: events_path) %>
  <% c.with_footer { 'Custom footer content' } %>
<% end %>
```

**Options:**
- `template` - Path to an HTML partial rendered for each day's events (default: nil)
- `start_date` - Date or string to center the calendar on (default: `Date.current`)
- `period` - Calendar view, one of `:month`, `:week`, or `:day` (default: `:month`)
- `events` - Array of events; each must respond to `start_attribute` (default: `[]`)
- `start_attribute` - Method called on each event for its start date (default: `:start_time`)
- `end_attribute` - Method called on each event for its end date, enables multi-day events (default: `:end_time`)
- `weekdays_only` - Show only Monday-Friday (default: false)
- `all_week` - DEPRECATED: use `weekdays_only` instead
- `show_date` - Display the day number in each cell (default: true)

**Slots:** `header` (navigation with period switch, accepts `route_path:` and `period_switch:`), `footer`.

#### ImageField

Image preview with an optional file input overlay for uploading/replacing an image, plus a hover clear button.

```erb
<%= form_with(model: @user) do |f| %>
  <%= render Bali::ImageField::Component.new(src: @user.avatar_url, size: :lg) do |c| %>
    <% c.with_input(form: f, method: :avatar) %>
  <% end %>
<% end %>
```

**Options:**
- `src` - URL of the current image; falls back to the placeholder when nil (default: nil)
- `placeholder_url` - Image shown when there is no `src` or after clearing (default: `https://placehold.jp/128x128.png`)
- `size` - One of `:xs`, `:sm`, `:md`, `:lg`, `:xl` (default: `:md`)
- `**options` - Additional HTML attributes for the container (e.g. `class`)

**Slots:** `input` (file input, takes `form:` and `method:`), `clear_button` (override the default clear button).

#### RichTextEditor

BlockNote-based rich text editor for editing or displaying HTML content, with a hidden input for form submission.

```erb
<%= render Bali::RichTextEditor::Component.new(
  html_content: @post.body,
  output_input_name: 'post[body]',
  editable: true,
  placeholder: 'Start typing...'
) %>
```

**Options:**
- `html_content` - Initial HTML content to load into the editor (default: nil)
- `output_input_name` - Name of the hidden input that receives the edited HTML (default: nil)
- `editable` - Enable editing; false renders read-only content (default: false)
- `placeholder` - Placeholder text shown when empty (default: "Start typing...")
- `images_url` - Endpoint for image uploads (default: nil)
- `page_hyperlink_options` - Options for internal page hyperlinks (default: `[]`)

Only renders when `Bali.rich_text_editor_enabled` is true.

#### DirectUpload

Uploads files from the browser directly to cloud storage (S3, GCS, Azure) via Active Storage's DirectUpload API, with drag & drop, progress, and client-side validation.

```erb
<%= form_with(model: @document) do |f| %>
  <%= render Bali::DirectUpload::Component.new(
    form: f,
    method: :attachments,
    multiple: true,
    max_files: 5,
    accept: 'application/pdf,image/*'
  ) %>
<% end %>
```

**Options:**
- `form` - Rails form builder object (required)
- `method` - Attachment attribute name, e.g. `:file`, `:images` (required)
- `multiple` - Allow selecting multiple files (default: false)
- `max_files` - Maximum number of files when `multiple: true` (default: 10)
- `max_file_size` - Maximum file size in megabytes (default: 10)
- `accept` - Accepted file types, MIME types or extensions (default: `"*"`)
- `drop_zone` - Show the drag & drop area (default: true)
- `auto_upload` - Upload files immediately on selection (default: true)

Requires Active Storage and CORS configuration on the bucket — see the [DirectUpload setup guide](direct-upload-setup.md). Client-side validation is UX only; always validate on the server.

#### RecurrentEventRuleForm

Form control for building RFC 5545 RRULE strings (e.g. `FREQ=WEEKLY;BYDAY=MO,WE,FR`) with controls for frequency, interval, weekdays, and end conditions.

```erb
<%= form_with(model: @event, builder: Bali::FormBuilder) do |form| %>
  <%= render Bali::RecurrentEventRuleForm::Component.new(
    form: form,
    method: :schedule,
    value: 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR;COUNT=10'
  ) %>
<% end %>
```

Also available through the form builder as `form.recurrent_event_rule_field :schedule` or `form.recurrent_event_rule_field_group :schedule`.

**Options:**
- `form` - The form builder instance (required)
- `method` - The attribute name, e.g. `:schedule` (required)
- `value` - Pre-populate with an existing RRULE string (default: nil)
- `disabled` - Disable all form controls (default: false)
- `skip_end_method` - Hide the "End" section for rules that never end (default: false)
- `frequency_options` - Array of allowed frequencies from `yearly`, `monthly`, `weekly`, `daily`, `hourly` (default: all)

---

### Feedback Components

#### Notification

Alert messages and feedback.

```erb
<%= render Bali::Notification::Component.new(
  type: :success,
  message: "Changes saved successfully!"
) %>

<%= render Bali::Notification::Component.new(type: :error, dismissible: true) do %>
  <strong>Error:</strong> Please fix the following issues.
<% end %>
```

**Types:** `:info`, `:success`, `:warning`, `:error`

#### Loader

Loading indicator.

```erb
<%= render Bali::Loader::Component.new(size: :lg, color: :primary) %>
```

#### FlashNotifications

Renders Rails flash messages as auto-stacking notifications at the bottom-right of the screen.

```erb
<%= render Bali::FlashNotifications::Component.new(
  notice: flash[:notice],
  alert: flash[:alert]
) %>
```

**Options:**
- `notice` - Success message to display (default: `nil`)
- `alert` - Error/warning message to display (default: `nil`)

#### Message

Inline alert box (DaisyUI `alert`) with an optional title or custom header slot.

```erb
<%= render Bali::Message::Component.new(title: 'Heads up', color: :warning, style: :soft) do %>
  Your subscription expires in 3 days.
<% end %>
```

**Options:**
- `title` - Header text shortcut; use the `with_header` slot for custom markup (default: `nil`)
- `size` - Text size: `:small`, `:regular`, `:medium`, `:large` (default: `:regular`)
- `color` - Alert color: `:primary`, `:success`, `:danger`, `:warning`, `:info` (default: `:primary`)
- `style` - Alert style: `:soft`, `:outline`, `:dash` (default: `nil`, solid)

#### EmptyState

Standard empty state: a centered block with an optional icon in a soft circle, a title, an optional description and an optional CTA. Use it anywhere a section has nothing to show yet (grids, panels, tabs, kanban columns) so every blank state looks the same. `Bali::Table` renders its built-in empty state through this component, so tables and standalone sections match.

```erb
<%= render Bali::EmptyState::Component.new(
      icon: 'inbox',
      title: t('.empty_title'),
      description: t('.empty_description')) do |empty_state| %>
  <% empty_state.with_cta do %>
    <%= render Bali::Link::Component.new(
          name: t('.new'), href: new_thing_path,
          icon_name: 'plus', variant: :primary, size: :sm) %>
  <% end %>
<% end %>
```

**Options:**
- `title` - Main message (required)
- `description` - Muted secondary line below the title (default: `nil`)
- `icon` - Icon name rendered inside a soft `bg-base-200` circle (default: `nil`)
- `size` - Vertical padding and icon scale: `:sm` (compact, for cells/panels), `:md`, `:lg` (full page) (default: `:md`)
- `**options` - Additional HTML attributes for the wrapper `div` (e.g. `id:`, extra `class:`)

**Slots:**
- `with_cta` - Optional call-to-action (a `Bali::Link`, button, drawer trigger, etc.) rendered below the text

#### FeedbackWidget

Floating feedback button that opens a drawer with an embedded Opina iframe and polls a badge endpoint for unread count.

```erb
<%= render Bali::FeedbackWidget::Component.new(
  project_slug: 'my-project',
  opina_url: 'https://opina.example.com',
  secret: Rails.application.credentials.opina_secret,
  user_id: current_user.id,
  email: current_user.email
) %>
```

**Options:**
- `project_slug` - The project slug in Opina (required)
- `opina_url` - Base URL of the Opina instance (required)
- `token` - Pre-built JWT token for embed authentication (default: `nil`)
- `secret` - Opina shared secret to generate the token automatically (default: `nil`; either `token` or `secret` is required)
- `user_id` - User ID for token generation, required when using `secret` (default: `nil`)
- `email` - User email for token generation, required when using `secret` (default: `nil`)
- `user_name` - User display name for token generation (default: `nil`)
- `title` - Drawer header title (default: `nil`, falls back to "Feedback")
- `token_expires_in` - Token expiry in seconds (default: `3600`)
- `badge_interval` - Polling interval in ms for the badge count (default: `300000`)

---

### Documents & Editors

#### BlockEditor

Notion-style block editor (BlockNote) with rich text, slash commands, mentions, entity references, comments, and PDF/DOCX export. See the [BlockEditor API](../api/block-editor.md) for the full reference.

```erb
<%= render Bali::BlockEditor::Component.new(
  editable: true,
  placeholder: 'Start writing...',
  input_name: 'document[content]',
  initial_content: @document.content,
  mentions_url: '/users',
  export: true
) %>
```

**Options:**
- `initial_content` - Initial document as BlockNote JSON (Hash/Array or JSON string) (default: nil)
- `input_name` - Hidden input name for form submission (default: nil)
- `format` - Serialization format for the hidden input, `:json` or `:html` (default: :json)
- `editable` - Whether the editor accepts input (default: true)
- `placeholder` - Placeholder text for the empty editor (default: nil)
- `upload_url` - Image upload endpoint; `:auto` resolves the engine's upload route (default: :auto)
- `export` - Enable export; `true` for PDF+DOCX or an array like `[:pdf]` (default: false)
- `comments` - Inline comments config hash (`url:`, `user:`, `users:`) (default: false)

See the component class for the full list (`ai_url`, `mentions`, `references_url`, `multi_column`, `table_of_contents`, `theme`, ...).

#### DocumentEditor

Full-screen document editing overlay wrapping BlockEditor with app bar, table of contents, comments sidebar, version history (preview and restore past versions), auto-save, and Cmd+S manual save.

```erb
<%= render Bali::DocumentEditor::Component.new(
  title: @document.title,
  initial_content: @document.content,
  document_url: document_path(@document),
  close_url: document_path(@document),
  versions_url: document_versions_path(@document),
  comments: { url: '/block_editor_comments', user: current_user_json, users: users_json },
  export: true
) do |editor| %>
  <% editor.with_toolbar do %>
    <span class="badge badge-ghost">Draft</span>
  <% end %>
<% end %>
```

**Options:**
- `title` - Document title shown in the app bar (required)
- `initial_content` - Document content as BlockNote JSON (required)
- `document_url` - URL where saves are PATCHed (required)
- `close_url` - URL for the close button (default: document_url)
- `versions_url` - Version history endpoint; enables the versions panel with preview/restore (default: nil)
- `editable` - Read-only when false (default: true)
- `auto_save` - Save automatically while editing (default: true)
- `auto_save_delay` - Auto-save debounce in ms (default: 30000)

See the component class for the full list (`comments`, `export`, `input_name`, `ai_url`, `mentions_url`, `references_url`, ...).

#### DocumentPage

Document-centric page with a three-panel layout: table of contents, read-only BlockEditor content, and a collapsible metadata panel.

```erb
<%= render Bali::DocumentPage::Component.new(
  title: 'Q2 2026 Product Roadmap',
  subtitle: 'Last edited 2 hours ago',
  breadcrumbs: [{ name: 'Documents', href: documents_path }, { name: 'Roadmap' }],
  initial_content: @document.content
) do |page| %>
  <% page.with_title_tag do %>
    <%= render Bali::Tag::Component.new(text: 'Published', color: :success, size: :sm) %>
  <% end %>
  <% page.with_action do %>
    <%= render Bali::Link::Component.new(name: 'Edit', href: edit_document_path(@document), variant: :ghost, icon_name: 'pencil') %>
  <% end %>
  <% page.with_metadata do %>
    <p>Owner: Ana</p>
  <% end %>
<% end %>
```

**Options:**
- `title` - Page title (required)
- `subtitle` - Text under the title (default: nil)
- `breadcrumbs` - Array of `{ name:, href: }` hashes (default: [])
- `back` - Back link, e.g. `{ href: path }` (default: nil)
- `initial_content` - BlockNote JSON; renders the editor and TOC when present (default: nil)
- `toc_open` / `metadata_open` - Initial panel visibility (default: true)

---

### Page Templates

#### DashboardPage

Dashboard layout with page header, stat cards grid, and a body area for charts and cards.

```erb
<%= render Bali::DashboardPage::Component.new(title: 'Dashboard', subtitle: 'Welcome back, Ana') do |page| %>
  <% page.with_action do %>
    <%= render Bali::Button::Component.new(name: 'Export', variant: :ghost, icon_name: 'download') %>
  <% end %>
  <% page.with_stat(label: 'Total Movies', value: '1,234', icon: 'film', color: :primary) %>
  <% page.with_stat(label: 'Revenue', value: '$45.2K', icon: 'dollar-sign', color: :success, change: '+12.5%') %>
  <% page.with_body do %>
    <%= render Bali::Card::Component.new(style: :bordered) { 'Recent activity...' } %>
  <% end %>
<% end %>
```

**Options:**
- `title` - Page title (required)
- `subtitle` - Text under the title (default: nil)
- `breadcrumbs` - Array of `{ name:, href: }` hashes (default: [])
- `stats_columns` - Stat cards per row: 2, 3, or 4 (default: 4)
- `max_width` - Content width: `:lg`, `:xl`, `:"2xl"`, or `:full` (default: :"2xl")

#### IndexPage

Standard listing page with breadcrumbs, title, action buttons, and a body area for tables.

```erb
<%= render Bali::IndexPage::Component.new(
  title: 'Movies',
  subtitle: '24 movies total',
  breadcrumbs: [{ name: 'Dashboard', href: root_path, icon_name: 'home' }, { name: 'Movies' }]
) do |page| %>
  <% page.with_action do %>
    <%= render Bali::Link::Component.new(name: 'New Movie', href: new_movie_path, variant: :primary, icon_name: 'plus') %>
  <% end %>
  <% page.with_body do %>
    <%# DataTable goes here %>
  <% end %>
<% end %>
```

**Options:**
- `title` - Page title (required)
- `subtitle` - Text under the title (default: nil)
- `breadcrumbs` - Array of `{ name:, href: }` hashes (default: [])
- `back` - Back link, e.g. `{ href: path }` (default: nil)

#### ShowPage

Record detail page with breadcrumbs, title with tags, actions, and an optional two-column layout with sidebar.

```erb
<%= render Bali::ShowPage::Component.new(
  title: 'The Matrix',
  subtitle: 'Added 2 days ago',
  breadcrumbs: [{ name: 'Movies', href: movies_path }, { name: 'The Matrix' }],
  back: { href: movies_path }
) do |page| %>
  <% page.with_title_tag do %>
    <%= render Bali::Tag::Component.new(text: 'Released', color: :success, size: :sm) %>
  <% end %>
  <% page.with_action do %>
    <%= render Bali::Link::Component.new(name: 'Edit', href: edit_movie_path(@movie), variant: :ghost, icon_name: 'pencil') %>
  <% end %>
  <% page.with_body do %>
    <%= render Bali::Card::Component.new(style: :bordered) { 'Details...' } %>
  <% end %>
  <% page.with_sidebar do %>
    <%= render Bali::Card::Component.new(style: :bordered) { 'Stats...' } %>
  <% end %>
<% end %>
```

**Options:**
- `title` - Page title (required)
- `subtitle` - Text under the title (default: nil)
- `breadcrumbs` - Array of `{ name:, href: }` hashes (default: [])
- `back` - Back link, e.g. `{ href: path }` (default: nil)

#### FormPage

New/edit page that wraps form content in a centered Card, with an optional sidebar column for help text.

```erb
<%= render Bali::FormPage::Component.new(
  title: 'New Movie',
  breadcrumbs: [{ name: 'Movies', href: movies_path }, { name: 'New' }],
  back: { href: movies_path }
) do |page| %>
  <% page.with_body do %>
    <%= form_with model: @movie do |f| %>
      <%# form fields %>
    <% end %>
  <% end %>
  <% page.with_sidebar do %>
    <p class="text-base-content/60">Tips for filling out this form.</p>
  <% end %>
<% end %>
```

**Options:**
- `title` - Page title (required)
- `subtitle` - Text under the title (default: nil)
- `breadcrumbs` - Array of `{ name:, href: }` hashes (default: [])
- `back` - Back link, e.g. `{ href: path }` (default: nil)
- `max_width` - Form width: `:sm`, `:md`, `:lg`, `:xl`, or `:full` (default: :md)
- `card` - Wrap the body in a Card (default: true)

---

### Utilities

#### ThemeSampler

Lookbook-only preview gallery that renders Bali components (buttons, tags, cards, alerts, form inputs) under a DaisyUI theme to compare color palettes at a glance.

```erb
<%# Not a renderable component — browse it in Lookbook instead: %>
<%# http://localhost:3001/lookbook/preview/bali/theme_sampler/costa_norte %>
```

**Options:**
- None — there is no `Bali::ThemeSampler::Component` class; it exists only as a Lookbook preview (`app/components/bali/theme_sampler/preview.rb`) using a theme-specific layout (e.g. Costa Norte).

---

## Custom CSS Classes

Add custom classes with the `class` option:

```erb
<%= render Bali::Card::Component.new(class: 'my-custom-class hover:shadow-lg') %>
```

Classes are merged with component's default classes.

---

## Data Attributes for Stimulus

Pass data attributes for Stimulus controllers:

```erb
<%= render Bali::Button::Component.new(
  name: 'Toggle',
  data: {
    controller: 'toggle',
    action: 'click->toggle#switch',
    toggle_target: 'button'
  }
) %>
```

---

## Component Composition

Build complex UIs by composing multiple components:

```erb
<%= render Bali::Card::Component.new(style: :bordered) do |card| %>
  <% card.with_header { "User Profile" } %>

  <div class="flex items-center gap-4">
    <%= render Bali::Avatar::Component.new(src: @user.avatar, size: :lg) %>
    <div>
      <h3 class="font-bold"><%= @user.name %></h3>
      <%= render Bali::Tag::Component.new(text: @user.role, color: :info) %>
    </div>
  </div>

  <% card.with_actions do %>
    <%= render Bali::Button::Component.new(name: 'Edit', variant: :ghost) %>
    <%= render Bali::Button::Component.new(name: 'Message', variant: :primary) %>
  <% end %>
<% end %>
```

---

## Lookbook Previews

Browse all components and their variations in Lookbook:

```bash
cd spec/dummy && bin/dev
```

Open [http://localhost:3001/lookbook](http://localhost:3001/lookbook)

Each component has interactive previews showing:
- All variants and sizes
- Slot usage examples
- State variations (loading, disabled, etc.)
- Real-world use cases

---

## Best Practices

### DO

- Use semantic variants (`:success` for confirmations, `:error` for destructive actions)
- Compose components rather than duplicating HTML
- Use slots for complex content
- Pass data attributes for Stimulus integration

### DON'T

- Mix raw HTML with DaisyUI classes when a component exists
- Override component styles with inline styles
- Use `Button` for navigation (use `Link` instead)
- Skip accessibility attributes (components handle most, but add `aria-label` when needed)

---

## Next Steps

- [FormBuilder Guide](form-builder.md) - Enhanced form helpers
- [Component Patterns](../reference/component-patterns.md) - Internal patterns for contributors
- [Accessibility Guide](accessibility.md) - WCAG compliance details
