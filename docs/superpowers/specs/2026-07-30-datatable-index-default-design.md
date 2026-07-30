# DataTable + IndexPage — the default index — Design

Date: 2026-07-30
Status: Approved (brainstorming)
Target release: v3.0.0 (breaking)

## Purpose

Every listing feature added over the last cycles — saved views (#668/#669), row
grouping (#621/#634), the column selector, export, the `ViewSwitch` segmented
control (#636/#649) — landed as its own isolated preview and its own slot. None
of them were ever composed together, so there is no single place that shows what
a Bali index page is supposed to look like with everything on, and the pieces
have drifted into three partially overlapping implementations.

This spec defines that default: one canonical composition, and the API changes
needed for it to be the *default* rather than something each app assembles
correctly by luck.

### Evidence of the drift

- **No complete IndexPage preview exists.** All three previews in
  `app/components/bali/index_page/previews/` use a fake body; `default.html.erb`
  literally renders `"DataTable would go here."`.
- **`ViewSwitch` is never used with `DataTable`** — not in any preview, not in
  the dummy app.
- **Three overlapping mode/export implementations.**
  `DataTable::ActionsPanel` ships its own table/grid toggle and its own export
  dropdown (`actions_panel/component.html.erb:5-38`), competing with the newer
  declarative `with_export` slot and with `Bali::ViewSwitch`. The legacy toggle
  is built with `Utils::Url#add_query_params`, which duplicates a param that is
  already in the URL — open issue **#653**.
- **The surface (card) belongs to the host, not the component.** Each view
  writes `render Bali::Card { render DataTable }` (e.g.
  `spec/dummy/app/views/admin/movies/index.html.erb:22`), so whether the toolbar
  sits inside a card depends on the page. In grid mode it produces cards nested
  in a card. `toolbar_class:` (v2.17.x) was the escape hatch for exactly this,
  as an option rather than a default.
- **One listing's identity is written four times.** `Bali::Table(id:)`,
  `with_column_selector(table_id:)`, `with_saved_views(table_id:)`, and
  `FilterForm(storage_id:)`. The `#`-prefix normalization is duplicated verbatim
  in `column_selector/component.rb:16` and `saved_views/component.rb:25`; the
  dummy passes `'#movies-table'` while the previews pass `'complete-demo-table'`.
  Column persistence is keyed by `table_id` (`bali:columns:movies-table`,
  `column_selector/component.rb:33`) while the saved-views store is keyed by
  `storage_id` — two identities for the same listing. `movies/index.html.erb`
  and `admin/movies/index.html.erb` are different listings sharing
  `#movies-table`.

### Goals

- One canonical index composition, rendered as a real preview and as a real page
  in the dummy app.
- The correct layout is what you get by default; composing it wrong should
  require effort.
- All seven control families coherent in one toolbar, identical across display
  modes, with a defined mobile behavior.
- One name per listing, used by every feature that persists anything.

### Non-goals (YAGNI)

- No new display modes shipped by Bali. The component never learns what a Gantt
  is; it renders whatever the host puts in the content slot.
- No shared/team saved views (that is phase 2 of B2, a different store
  implementation).
- No measuring/`ResizeObserver` priority+ overflow. A fixed breakpoint is enough
  for v3.0.
- No changes to `Bali::IndexPage`'s own API. It already does its job; only its
  previews and docs change.

## Decisions

| Question | Decision |
|---|---|
| Where the default lives | API change **and** canonical preview |
| Surface | Toolbar bare (no card); content brings its own surface |
| View switch | Generic content slot + `with_view_switch`; Bali stays mode-agnostic |
| Migration | Breaking, in v3.0, with a migration guide |
| Toolbar layout | Single row, grouped by function (left = which data, right = how it is shown) |
| Narrow viewports | Priority overflow into a `⋯` menu, nodes **moved**, never duplicated |
| Bulk actions | Contextual bar replacing the toolbar row while a selection exists |
| Row selection | In scope: `Bali::Table(selectable: true)` |

## Architecture

`DataTable` owns three bands and nothing else:

```
toolbar     bare, no surface, identical in every display mode
content     brings its own surface, decided by the slot
footer      summary + pagination, bare
```

### 1. The surface moves from the host to the component

The content slot decides:

- `with_table` — wraps in a surface and `overflow-x-auto`.
- `with_grid` — no surface (the cards *are* the surface).
- `with_content(surface: true)` — explicit; `true` is the default, so a Gantt
  that brings its own chrome passes `surface: false`.

Hosts delete their `render Bali::Card` wrapper.

### 2. The content generalizes to one slot

`with_table` and `with_grid` survive as sugar over `with_content`, and
`display_mode:` stops selecting between two hardcoded slots. Adding kanban,
calendar or map views to an app requires no change in Bali.

### 3. The view switch joins the toolbar and preserves the query string

`with_view_switch` reuses `Bali::ViewSwitch` and builds each href the way
`DataTable::GroupByControl#build_href` already does: merge
`request.query_parameters`, drop `page`, keep everything else. This is what
makes filters, grouping and the applied saved view survive a mode change — today
they do not, because each mode is a loose page.

`saved_view` **is** preserved on these links. They are navigation, not a filter
submit — the opposite of `Bali::Filters`, where preserving it re-applied the
view's payload over what the user had just typed (that is why it joined
`EXCLUDED_PARAMS` in #669).

Building hrefs this way also closes **#653**: `add_query_params` is no longer on
the path.

### 4. Overflow moves nodes, it does not duplicate them

The current pattern (`hidden md:block` plus a mobile copy of `actions_panel`)
does not scale here. Duplicating the column selector means two Stimulus
controllers driving the same table; duplicating saved views means duplicate ids
in its rename forms — the exact bug fixed in #669.

A `toolbar-overflow` Stimulus controller relocates the secondary controls into a
`⋯` dropdown when crossing the breakpoint, and back when it is crossed the other
way. The breakpoint is Tailwind's `sm` (640px), driven by a `matchMedia`
listener — a fixed threshold, not measurement. Every control exists exactly once
in the DOM. Survival order, highest first:

```
search > filters > view switch (icon only) > saved views > group by > columns > export
```

The column selector goes first because it is useless on a phone, where the table
scrolls horizontally anyway.

## API

```erb
<%= render Bali::DataTable::Component.new(
      url: admin_movies_path, filter_form: @filter_form, pagy: @pagy,
      display_mode: @view,     # :table | :grid | whatever the host defines
      view_param: :view        # URL param name (default :view)
    ) do |dt| %>
  <% dt.with_filters_panel %>
  <% dt.with_view_switch do |vs| %>
    <% vs.with_view(name: 'Tabla',    icon: 'list',     value: :table) %>
    <% vs.with_view(name: 'Tarjetas', icon: 'grid',     value: :grid) %>
    <% vs.with_view(name: 'Gantt',    icon: 'calendar', value: :timeline) %>
  <% end %>
  <% dt.with_saved_views %>
  <% dt.with_column_selector do |cs| %>
    <% cs.with_column(index: 0, label: 'Nombre') %>
  <% end %>
  <% dt.with_export(formats: %i[csv excel pdf]) %>
  <% dt.with_bulk_actions do |ba| %>
    <% ba.with_action(name: 'Marcar hecho', href: mark_done_path, method: :patch) %>
  <% end %>

  <% dt.with_table do %>
    <%= render Bali::Table::Component.new(form: @filter_form, selectable: true) do |t| %>
      ...
    <% end %>
  <% end %>
<% end %>
```

### `with_view_switch`

`value:` instead of `href:`. `DataTable` builds the href (merge query params,
drop `page`, keep `saved_view`) and marks the active view by comparing against
`display_mode`. `href:` remains accepted for a mode that lives on another route.

`view_param:` standardizes on `:view`. The legacy name was
`data_display_mode` — an internal detail leaked into the user's URL.

The host passes `display_mode:` from `params[:view]`, and `DataTable` gates it
against the declared views: an unknown value falls back to the first declared
view instead of rendering an empty content slot. Same whitelist reasoning as
`FilterForm#resolve_group_by` — a raw URL param never reaches behavior
unchecked.

### `with_bulk_actions`

Reuses the existing `BulkActionsController`
(`app/components/bali/bulk_actions/index.js`): selection, `selectedIds`, toggle
by checkbox or double click, and injection of the ids into forms and links
already work and are not rewritten.

`Bali::BulkActions` gains `variant: :toolbar | :floating`. `DataTable` requests
`:toolbar` — the contextual row that replaces the toolbar while a selection
exists (`3 seleccionados · [acciones] · ✕`). The floating bar stays available
for uses outside a DataTable.

### `Bali::Table(selectable: true)`

Renders the checkbox column plus a select-all header, wired to
`BulkActionsController`. Today every app hand-writes that `<td>` (see
`spec/dummy/app/views/admin/movies/index.html.erb:69`).

### Listing identity: `table_id` is removed, not promoted

`table_id:` disappears from `with_column_selector` and `with_saved_views`, and
`Bali::Table` no longer needs an `id:`. The identity already exists and is
`storage_id` — the same name the filter cache and the saved-views store use.

Resolution order:

1. explicit `id:` on `DataTable`
2. `filter_form.storage_id`
3. random hex — **and column persistence turns itself off**, because a key that
   changes on every render can never restore anything. Today that would be a
   silent no-op.

`DataTable` renders its container with the resolved id and the column selector
targets `#<id> table` instead of the table element directly. The localStorage
key becomes `bali:columns:<storage_id>`.

Note: the id `DataTable` generates today (`"data-table-#{@filter_form.id}"`,
where `FilterForm#id` is `scope.cache_key`) contains a slash — `movies/query-abc`
— so it is not usable as a `querySelector` target. The resolved id must be a
clean slug. Nothing queries it today, so this is not a live bug, but it
disqualifies the current value.

### Breaking changes (v3.0)

| Removed | Replacement |
|---|---|
| `with_actions_panel` | `with_bulk_actions` |
| `actions_panel(export_formats:)` | `with_export` |
| `actions_panel(grid_display_mode_enabled:)` | `with_view_switch` |
| param `data_display_mode` | param `view` |
| `with_column_selector(table_id:)` | resolved from `storage_id` |
| `with_saved_views(table_id:)` | resolved from `storage_id` |
| `Bali::Table(id:)` as the selector target | container id |
| `render Bali::Card` around the DataTable in the host | content slot's surface |

Users' stored column preferences reset once, because the localStorage key
changes from `bali:columns:<table_id>` to `bali:columns:<storage_id>`. This goes
in the migration note.

## Deliverables

### Previews

- **New** `index_page/previews/complete.html.erb` — the canonical reference:
  page header, primary action, DataTable with all seven control families,
  selection, pagination.
- `data_table/previews/complete.html.erb` — the same content without the page
  layer, updated to the new API.
- `with_grouping`, `with_saved_views`, `with_grid_mode`, `with_toolbar_buttons`
  survive as single-feature demos, updated.

**Risk to resolve in phase 1, not at the end:** the view switch needs `?view=`
to round-trip inside Lookbook. If Lookbook does not forward arbitrary query
params to the preview iframe, the fallback is to declare
`@param view select [table, grid, timeline]` and have the switch links target
the query string Lookbook does understand.

### Dummy app

`admin/movies` stays the end-to-end reference page — it is what the Cypress
suite and browser verification already target, so migrating it exercises the
removal of the `Card` and of `table_id` against real code.

For the third mode to be honest, the dummy gains a two-column migration
(`production_starts_on` / `production_ends_on` on `movies`). The production
Gantt is already told as a story in `admin/analytics`, today with data invented
in the view.

`admin/projects` is not touched (it is a hand-rolled card grid with no
FilterForm).

Four dummy views reference `table_id` and must migrate together:
`admin/movies/index.html.erb`, `admin/movies/index.turbo_stream.erb`,
`movies/index.html.erb`, `movies/index.turbo_stream.erb`.

### Docs

- `docs/guides/components.md` — DataTable section.
- `.claude/skills/filterform-datatable/SKILL.md` — this is what agents load when
  building an index page; left stale it will keep emitting `render Bali::Card` +
  `table_id:` forever.
- A v2 → v3 migration guide.

### Tests

Minitest:

- toolbar renders with no surface; content surface follows the slot
- id resolution: explicit `id:` > `storage_id` > random hex with persistence off
- view switch hrefs preserve `q` and `saved_view`, drop `page`, mark the active
  mode
- `selectable:` renders the checkbox column and the select-all header

Cypress (behavior only visible in a browser):

- switching display mode keeps filters, applied saved view and grouping
- narrowing the viewport moves controls into `⋯` and back, without duplicating
  them
- selecting rows swaps the toolbar for the contextual bar and restores it on
  clear

Plus the manual browser verification the repo's `CLAUDE.md` requires.

## Sequencing

This is a v3.0 release, not a single PR. The implementation plan should
decompose it into stacked, independently reviewable changes, roughly:

1. **Identity** — resolve the listing id from `storage_id`, drop `table_id:`
   from both slots and the selector target from `Bali::Table`. Self-contained
   and the riskiest to get wrong, so it goes first and alone.
2. **Surface + content slot** — `with_content`, surface ownership, hosts stop
   wrapping in `Card`.
3. **View switch** — `with_view_switch`, href building, removal of the legacy
   `ActionsPanel` toggle and export (closes #653).
4. **Selection + bulk actions** — `Bali::Table(selectable:)`,
   `BulkActions(variant:)`, `with_bulk_actions`, removal of `actions_panel`.
5. **Toolbar overflow** — the `toolbar-overflow` controller.
6. **Previews, dummy migration, docs, migration guide.**

Each step lands with its own tests and CHANGELOG entry; the release note for
v3.0 is assembled at the end.

## Out of scope

- Team/shared saved views (B2 phase 2).
- Measuring priority+ overflow.
- Any new display mode implemented inside Bali.
- `admin/projects` and the Kanban board.
