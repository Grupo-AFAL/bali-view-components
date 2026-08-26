# Widgets and the widget grid

**Date:** 2026-08-25
**Branch:** `feat/widgets-and-widget-grid`
**Source:** `/Users/miguelfrias/Documents/enjoykitchen` — `app/components/widget/`, `app/services/widgets*`,
`app/javascript/controllers/{widget_grid,edit_mode}_controller.js`, `app/models/user_widget.rb`,
`app/views/today/_widgets.html.erb`

A user-arrangeable bento dashboard: cards in four sizes, drag / arrow-key reorder, resize, remove,
and a persisted layout. Built and shipped in enjoykitchen; this moves the reusable half into Bali so
every AFAL app gets it, and leaves the app-specific half — the nineteen widget classes, the Pundit
gate, the tenant feature flags — where it belongs.

## What moves and what stays

| Layer | Lands in Bali | Stays in the host |
|---|---|---|
| The card (chrome, four sizes, edit affordances, bento CSS) | ✅ all of it | — |
| The grid (SortableList wrapper, edit mode, announcer, "+" tile) | ✅ all of it | — |
| Widget contract (`Base`, `Result`, `Row`, `SIZES`) | ✅ minus authorization | `visible?` bodies |
| Persistence (table, model, read/write object) | ✅ all of it | the controller that routes it |
| The nineteen widget classes, roles, Flipper flags, the picker UI | — | ✅ all of it |

## Architecture

Bali collapses enjoykitchen's `Widget::` / `Widgets::` split — one letter apart, and the source's own
comments apologize for it — into a single `Bali::Widget::` namespace. The engine eager-loads both
`app/components` and `app/lib`, so one namespace spans both roots.

```
app/lib/bali/widget.rb                    Bali::Widget — SIZES, SEPARATOR, .subtitle, .raise_load_errors?
app/lib/bali/widget/base.rb               Bali::Widget::Base
app/lib/bali/widget/result.rb             Bali::Widget::Result
app/lib/bali/widget/row.rb                Bali::Widget::Row
app/models/bali/dashboard_widget/store.rb             Bali::DashboardWidget::Store
app/components/bali/widget/               Bali::Widget::Component — the card
  component.rb  component.html.erb  index.css  preview.rb  previews/
app/components/bali/widget_grid/          Bali::WidgetGrid::Component — the bento
  component.rb  component.html.erb  index.js  preview.rb  previews/
app/models/bali/dashboard_widget.rb       Bali::DashboardWidget — one persisted row
db/migrate/*_create_bali_dashboard_widgets.rb
config/locales/bali_view.{en,es}.yml      bali_view.widgets.* chrome strings appended
```

`app/lib/bali/widget.rb` exists so the namespace is explicit and can hold constants; without it
Zeitwerk would define `Bali::Widget` implicitly and `SIZES` would have nowhere to live.

### Naming decisions

**`bali_dashboard_widgets`, not `bali_user_widgets`.** The owner column is polymorphic; a table named
for `User` while its owner refuses to name one is self-contradicting. It also gives the install task a
name that reads — `bali:install:migrations:dashboard_widgets` — and the feature name is derived from
the migration filename by `Bali::EngineMigrations`, so this is the only place it is chosen.

**`Bali::DashboardWidget::Store`, not `Dashboard`.** In review "Dashboard" read as *the grid*. `Store` names
what the rows actually are — an ordered, sized arrangement — reads correctly against its own methods
(`layout.arrange(…)`) and against the host endpoint enjoykitchen already calls `widget_layouts#update`.

**`index.css` goes in `@layer components`,** imported from `app/assets/stylesheets/bali/components.css`
like every other component sheet. The bento rules only set `grid-column` / `grid-row`; nothing needs to
outrank daisyUI. Being in `components` is what lets a host override a span with `lg:col-span-4` and no
`!` variant.

**`index.js` exports both controllers** — `WidgetGridController` and `EditModeController` — registered
in `app/frontend/bali/components/index.js`, the Kanban pattern. `EditModeController` is generic (it
toggles a class, swaps enter/leave controls, marks a subtree `inert`, remembers the mode in the URL)
but ships co-located rather than in `app/assets/javascripts/bali/controllers/`.

## The card

```ruby
render Bali::Widget::Component.new(widget)
```

Takes the **widget, not its result**, so `widget.count` stays true and the card derives every widget's
copy from `widget.key`. It does no data access, which is what lets it be tested against plain stubs.

### Two i18n scopes, deliberately split

Bali's own chrome ships in `bali_view.{en,es}.yml` under `bali_view.widgets.*` — `edit.reorder`,
`edit.remove`, `edit.size_of`, `edit.sizes.*`, `edit.add`, `edit.done`, `edit.hint`, `edit.moved`,
`edit.removed`, `edit.resized`, `edit.failed`, `edit.editing_on`, `edit.editing_off`, `load_error`,
`view_all`.

The **widget's** copy (`title`, `short_title`, `description`, `empty`) is host content, read from a
configurable scope defaulting to `widgets.<key>.*`. enjoykitchen's `config/locales/widgets.{es,en}.yml`
keeps working untouched.

### `shape` disappears; `Result` carries a `failed` flag

With the `:verdict` case becoming a slot (below), only two states remain, and a two-state enum is a
predicate:

```ruby
Bali::Widget::Result = Data.define(:count, :items, :view_all_path, :payload, :failed)
Bali::Widget::Row    = Data.define(:title, :subtitle, :href)
```

`payload` stays: it is the channel a widget uses to hand data to its custom body.

### Custom content is a slot, not a shape

`Bali::Widget::Component` declares `renders_one :body`. enjoykitchen's `:verdict` shape existed only to
render `Compliance::TodayPanel::Component` inside a card; naming that in Bali would be naming an app
concept. The grid yields each card, so the one widget that needs custom content fills the slot and
every other card falls through to the list body.

### Body precedence

1. **`failed?`** — the degraded card, at every size. Checked first because a failed widget has
   `count: 0` and the small card renders nothing but its count, so a confident grey "0" would be this
   dashboard's word for *all clear*. A tile that could not load must never be able to say that.
2. **`summary?`** (size `:small`) — the whole tile is a `stat` link. A ~215px card carrying three
   truncated titles is worse than the number those titles summarize.
3. **`body?`** — the slot, if the host filled it.
4. **the list** — `rows`, truncated by `ROWS = { small: 0, medium: 3, large: 7, wide: 3 }`, or
   `empty_message`.

Note that 2-before-3 means a custom-bodied widget dropped to `small` still renders as a stat. That is
the existing behaviour and is kept: a 215px box is not where custom content works.

### Edit chrome

Always rendered, hidden by CSS through `[.editing_&]:` arbitrary-parent variants, never toggled by the
server — so entering edit mode costs no round trip and re-runs no widget queries. No jiggle animation:
a wobbling card of overdue counts reads as a rendering fault, makes text unreadable, and collides with
`prefers-reduced-motion`.

**The size picker is a real radiogroup.** The four sizes are mutually exclusive, which is what
`role="radiogroup"`/`role="radio"` exists for. It shipped first as a `role="group"` +
`aria-pressed` toggle set — a legitimate pattern, and the honest one to use while the keyboard
behaviour was missing, since `role="radio"` without roving tabindex and arrow-key selection
announces semantics assistive tech expects to work and then does not honour. The follow-up
closed that gap rather than the role: the group is now one tab stop carried by the checked
size, all four arrows move within it (wrapping), Home/End jump to the ends, and selection
follows focus — so the card resizes live as you arrow, the same preview the mouse gets, with
`persist`'s debounce collapsing the sweep into one write.

`WidgetGridController#sizeKeydown` decides which button is next and then `click()`s it, so the
keyboard and the mouse both reach the size through `#resize` and cannot drift apart. Selection
is `aria-checked` and nothing else; `applySize` roves the `tabindex` alongside it.

The size picker draws each size as a filled/empty 4×2 lattice. The lattice is the point, not the fill:
four rectangles floating in whitespace have no shared origin, which is why `medium` (2×1) and `large`
(2×2) were indistinguishable at the same width. Selection is expressed by `aria-checked` and nothing
else, so the accessible state and the visible state cannot drift.

The card emits `data-id` (SortableJS's `toArray`), `data-widget-key`, `data-widget-title` and
`data-size`. `data-size` is the **only** thing that changes on resize; `index.css` owns what each size
means per breakpoint, so nothing builds a class name at runtime and Tailwind's "can't see dynamic class
names" constraint never applies.

## The grid

```erb
<%= render Bali::WidgetGrid::Component.new(
      url: tenant_widget_layout_path(@tenant),
      add_path: edit_tenant_user_widgets_path(@tenant)) do |grid| %>
  <% @widgets.each do |widget| %>
    <% grid.with_widget(widget) %>
  <% end %>
<% end %>
```

`renders_many :widgets, Bali::Widget::Component`. Custom content for one widget:

```erb
<% grid.with_widget(widget) do |card| %>
  <% card.with_body { render Compliance::TodayPanel::Component.new(widget.payload) } %>
<% end %>
```

The component owns the whole surface enjoykitchen splits across `today/show` and `today/_widgets`: the
`data-controller="bali-widget-grid edit-mode"` wrapper and its values, a default toolbar (enter/leave
`Bali::Button`s occupying the same slot, and always rendered — `renders_one :heading` overrides
only the leading text, never the controls, so a host cannot delete the sole entry point to
edit mode), the `sr-only` announcer
both controllers write to, the `Bali::SortableList`, the dashed "+" tile when `add_path:` is given, and
`Bali::EmptyState` when there are no widgets.

### Cards are plain children of the SortableList

Not `Bali::SortableList::Item::Component`s: `Item` requires an `update_url:` and carries list-row
styling (`p-2 bg-base-100 border first:rounded-t`) that would fight the bento. SortableJS's default
`draggable: '>*'` handles plain children and `toArray` reads the card's `data-id`.

One consequence, named because it is the least obvious thing here. Bali's `SortableListController` grew
keyboard reordering in #1028, but it only acts on `:scope > .sortable-item` elements that have focus
themselves. Our cards are neither, so **that path is inert here and `WidgetGridController#move` is the
entire keyboard story**: focus lands on the card's `.handle` button and all four arrows move the card,
announcing "*Stock bajo, position 3 of 9*". Not an accidental duplication — `move` handles Left/Right
(meaningless in a list, essential in a 4-column bento) and it announces, which SortableList's path does
not. The two cannot double-fire: SortableList's handler bails unless `event.target` *is* the item.

### Dragging is gated on the handle

The handle is `display:none` outside edit mode, so a card cannot be picked up while you are reading the
dashboard. That is the mechanism — rather than toggling `disabled` — because `SortableListController`
reads `disabledValue` only in `connect`.

### Geometry

`grid-cols-1 md:grid-cols-2 lg:grid-cols-4`, `gap-4`, `lg:auto-rows-[16rem]`. Fixed rows because
`large` meaning "two rows tall" is meaningless while rows size to content. `md:grid-cols-2` exists
because this used to jump 1 → 4 columns at `lg`, so an iPad in portrait got a single column and none of
the size system. Deliberately **not** `grid-flow-dense`, which backfills gaps by pulling later tiles
forward and would silently overrule the order the user chose.

Sizes are 2-D, adapted from iOS: `small` 1×1, `medium` 2×1, `large` 2×2, `wide` 4×1. `large` is
`medium`'s width at double height, which is why it earns more rows rather than wider ones.

### Writes

Every gesture — drop, arrow move, ✕, resize — sends the **same** full snapshot to the same endpoint and
differs only in what it does to the DOM first. Writes are debounced 250ms (arrow keys auto-repeat) and
serialized through one promise queue (two in-flight requests are two complete and different answers to
"what is the arrangement", and nothing about HTTP guarantees the later one commits last). The snapshot
is read when the request is built, not when it is queued. `disconnect` clears the timer, so a Turbo
navigation during the debounce window cannot PATCH a DOM that has already been replaced.

**Two known follow-ups on the controllers**, both from review of Task 7:

- **`EditModeController.push` uses raw `pushState`, and that is now a settled decision rather
  than an open question.** Review flagged it because `modal/index.js` routes through
  `window.Turbo.session.history.push` when Turbo is present. Cypress measured the actual
  behaviour: browser-Back does NOT hard-reload (a `window` marker survives, and our own
  `popstate` handler does the real work), but Turbo does issue a restoration visit — one
  wasted `GET` of a page that never changed.

  Routing through `Turbo.session.history.push` was tried and **does not fix it.** That method
  stamps the history entry correctly; it cannot retroactively cache the DOM. Turbo's snapshot
  cache is keyed by URL and populated only by `view.cacheSnapshot()` during a real visit away
  from a page — and toggling a query param never makes Turbo visit anything. With no cached
  snapshot for the pre-edit URL, `action: "restore"` falls back to the network. Architectural,
  not a missing line.

  Closing it would mean calling `Turbo.session.view.cacheSnapshot()` — private API not exposed
  on `window.Turbo` — from a shared library controller. Not worth a guaranteed future breakage
  to save one `GET` on an infrequent action that already behaves correctly. Accepted as a known
  minor cost; the Cypress spec documents it rather than asserting it away.

  **Note for the library at large:** `modal/index.js`'s use of the same pattern is unverified
  for the same reason. Nothing in `cypress/e2e/` exercises its Back path, and its push-then-
  swap-body flow has the same empty-snapshot-cache problem. Worth checking separately.
- **`remove()` announces the widget but not the new total,** where `move()` announces
  "position X of Y". A screen-reader user removing cards loses the running count. Needs a new
  locale string carrying a count, so it was left out of the initial pass.

Failures are announced, never swallowed: the whole design rests on the DOM being truthful — no draft,
no save button — so the one moment it stops being truthful is the one moment the user must be told.

## The widget contract

```ruby
class LowStockItems < Bali::Widget::Base
  sized :medium

  def visible?
    context.has_any_role?(:inventory_manager)
  end

  def call = list_from(scope, view_all_path: …)
end
```

`Bali::Widget::Base` keeps: `sized` (validated at class-definition time, so a typo is a boot failure
rather than a `KeyError` the first time someone opens the page), `key` derived from the class name,
`PREVIEW_ROWS = 8`, the i18n readers, `with_size`, the memoized `result`, `list_from`, and `subtitle`.

`Base#visible?` returns `true`; hosts override it. `Bali::Widget.authorized_for(widgets)` selects on it.
Bali owns the hook and never the rule — enjoykitchen's role, tenant-admin and Flipper ladder stays in
its own `Widgets::Base` override.

**`result` memoizes the failure too.** `Widget::Component` delegates `count`, `items` and
`view_all_path` separately, so a rescue that returned without assigning would re-run the raising query
three times per card. A raising `#call` degrades to a `failed` card rather than a dropped widget: a tile
that silently disappears reads as "nothing to see", which is the exact lie a failure must not tell.
`Bali::Widget.raise_load_errors?` (true in `Rails.env.local?`) keeps that rescue from being the blanket
kind that hides bugs.

## Persistence

```ruby
create_table :bali_dashboard_widgets do |t|
  t.references :owner, polymorphic: true, null: false, index: false
  t.string  :context,       null: false, default: ""   # tenant id; "" for single-tenant hosts
  t.string  :dashboard_key, null: false
  t.string  :widget_key,    null: false
  t.integer :position,      null: false
  t.string  :size                                       # nullable: "no opinion"
  t.timestamps
end

add_index :bali_dashboard_widgets,
          %i[owner_type owner_id context dashboard_key widget_key],
          unique: true, name: "index_bali_dashboard_widgets_uniqueness"
add_index :bali_dashboard_widgets,
          %i[owner_type owner_id context dashboard_key position],
          name: "index_bali_dashboard_widgets_ordering"
```

`context` is `null: false, default: ""` and **not** nullable: Postgres treats NULLs as distinct in a
unique index, so a nullable column would let a single-tenant host store the same widget twice.

**Two things are called `context` in this design, and they are unrelated.** The column and the
`Store.new(context:)` argument are a **scoping string** — the tenant id, or `""` for a single-tenant
host. `Bali::Widget::Base#context` is the **actor object** a widget's `visible?` gates against
(enjoykitchen's `PunditUserContext`). Nothing passes one where the other is expected — `Store` never
sees the actor and `Base` never sees the scope string — but the names collide in conversation, so a
reader has to know which is meant. Named here rather than renamed because the column name was chosen
deliberately.

`index: false` on the `references` because the unique index below leads with `[owner_type, owner_id]`
and serves every lookup — the same reasoning as `bali_saved_views`.

Installed per-feature: `bin/rails bali:install:migrations:dashboard_widgets`. The umbrella
`bali:install:migrations` still copies everything and prints the per-feature list first.

### `Bali::DashboardWidget`

A row and nothing more. `belongs_to :owner, polymorphic: true`; presence on `dashboard_key`,
`widget_key` and `position`; `widget_key` unique scoped to `%i[owner_type owner_id context
dashboard_key]`; `position` numericality `>= 0`.

No `acts_as_list`: the gem's contract is dense, contiguous positions within a scope, and this table
does not have that.

No `inclusion` validation on `widget_key` or `size`. It would make every legacy row unsaveable the day
a widget is retired, blocking unrelated saves, and it duplicates a read-side filter that must exist
regardless. `size` is a string and not a Rails enum for the same reason plus one more: an integer enum
makes the persisted meaning positional, and `SIZES` is not ordered by area, so inserting a `tall` where
it belongs would silently relabel every stored row.

`scope :ordered, -> { order(:position, :widget_key) }`. The tie-break is load-bearing, not tidy: a row
for a widget the owner cannot currently see keeps its position while visible ones renumber around it,
so two rows *can* share a position, and without a second term Postgres returns them in arbitrary order
— which makes `stored_keys` nondeterministic and `choose`'s "survivors keep their stored order"
guarantee unstable.

### `Bali::DashboardWidget::Store`

```ruby
Bali::DashboardWidget::Store.new(owner:, dashboard_key:, offering:, context: "")
```

| Method | Purpose |
|---|---|
| `#widgets` | the offering, subset + reordered + resized. No **visible** rows means "never chose" → the whole offering |
| `#stored_keys` | every stored key, including rows for widgets the owner cannot currently see |
| `#visible_keys` | stored keys ∩ offering keys, in stored order |
| `#customized?` | `visible_keys.any?` |
| `#choose(widgets)` | membership. Survivors keep stored order; newly chosen append |
| `#arrange(layout)` | full reconcile — `delete_all` + `insert_all` with positions from the array index, in a locked transaction |
| `#reset` | drop all rows — what "restore defaults" and an emptied grid both mean |

**`arrange` is a pure reconcile; `choose` preserves sizes.** `arrange` writes exactly the
layout it is handed (`delete_all` + `insert_all`), so an omitted size comes back as the
widget's default. The grid controller always sends a size for every card, so this only bites
the picker — which has no opinion about sizes and must therefore re-supply the stored ones.
`choose` reads them inside its lock, before `arrange` deletes anything. Getting this wrong
means ticking a checkbox silently resizes every card the owner had already sized.

**`lock_rows` cannot serialise an empty scope, on any adapter.** `FOR UPDATE` locks rows that
exist; on a first-ever `choose` there are none, so two concurrent writers proceed unserialised
and the later commit wins — and since `delete_all` precedes `insert_all`, the loser's row is
gone before the unique index could object. Silent, not an error. Exposure is one owner racing
themselves (two tabs, a retried request), and the controller serialises its own writes
client-side. The fix, if a host needs it, is an advisory lock keyed on the scope
(`pg_advisory_xact_lock`), which serialises writers even with zero rows present. Not shipped
because it is Postgres-only and the engine runs on whatever the host has.

**Timestamps do not survive a rearrange.** `arrange` deletes and re-inserts, so every row gets
a fresh `created_at` on every write. Nothing reads them today, but "when did you first add
this widget?" is permanently unanswerable from this table.

**`lock_rows` is a no-op on SQLite.** `.lock` emits no `FOR UPDATE` on that adapter, verified
against `.to_sql`. The serialization it provides is real on Postgres — the engine's target —
but a host running SQLite gets none of it, and the client-side promise queue is then the only
thing preventing two interleaved writes. Recorded rather than assumed.

`offering:` is **required, with no default**. An empty offer is a valid state but a terrible default:
`arrange` would lose its delete half (`[] - submitted` is `[]`), `choose` would become a no-op, and
`#widgets` would render nothing — three wrong behaviours from one forgotten argument, none raising.

**The invariant.** `choose` and `arrange` take **widgets, not keys**, and `#widgets` maps over
`offering.index_by(&:key)`. A key for a widget whose role was revoked, whose flag went off, that was
deleted from the catalog, or that was hand-edited into the table all collapse to the same `nil` from
one lookup. Safe by construction: there is no permitted-key list to pass and none to forget. The honest
claim is that an unauthorized widget cannot get here *by accident* — not that it cannot get here.

`stored_keys` and `visible_keys` are genuinely different, and conflating them is a real bug: an owner
whose only stored row is for a hidden widget has customized nothing they can see, and telling them
otherwise offers "restore defaults" to someone already looking at defaults.

## What the host writes

```ruby
class WidgetLayoutsController < ApplicationController
  def update
    layout.arrange(permitted_layout)
    head :no_content
  end

  private

  def layout
    Bali::DashboardWidget::Store.new(owner: current_user, context: @tenant.id.to_s,
                             dashboard_key: "today",
                             offering: Widgets.authorized_for(pundit_user))
  end
end
```

Bali ships **no controller and no routes**. Who may see which widget is the host's rule, and a host
that already has `DashboardWidgets` (the concern doing gate → filter → load) keeps it unchanged.

`docs/guides/engine-models.md` documents the PATCH contract — `widgets[][key]`, `widgets[][size]` —
including the two behaviours that are not obvious:

- An **empty sequence means reset**. Removing the last widget sends nothing, no rows means "never
  chose", and the server answers by restoring every authorized widget.
- The grid **reloads after an empty sequence**, because a `204` leaves an empty grid on screen over a
  full dashboard in the database, wrong until the next reload.

## Verification

**Minitest** — the card (each size, the failed card, the body slot, `summary?`, `view_all_link?`), the
grid (widget slots, empty state, "+" tile presence, emitted controller values), `Bali::DashboardWidget::Store`
(`choose` / `arrange` / `reset`, ordering tie-break, an unauthorized key being inert, the "no visible
rows means never chose" fallback), `Bali::Widget::Base` (`sized` validation, `with_size` copying rather
than mutating the class attribute, the memoized failure), and the model.

**Lookbook previews** — `@param size select`, `@param editing toggle`, `@param failed toggle` rather
than a method per size. Previews inherit `ApplicationViewComponentPreview` and name sibling constants
in full (`Bali::Widget::SIZES`, never `SIZES`) per the engine gotcha in `.claude/CLAUDE.md`.

**Cypress** — `cypress/e2e/widget-grid.cy.js` driven through the Lookbook preview URL: drag, arrow
move, resize, remove, the empty-grid reload, and the edit-mode URL round trip including back-button
restore.

### Two costs, named rather than discovered

1. **enjoykitchen's two jsdom controller test files do not come across.** Bali has no JS unit runner,
   only Cypress. Translating `widget_grid_controller.test.js` and `edit_mode_controller.test.js` into
   Cypress specs is the largest single chunk of net-new work in this port.
2. **`scripts/check-controller-manifest.mjs` gates the build** on registered controllers, so both new
   controllers must land in `app/frontend/bali/components/index.js` in the same change.

## Prerequisite for enjoykitchen

enjoykitchen is pinned to `bali_view_components 2.9.2`; Bali is at `v3.1.3`. Commit `09476060` renamed
every public JS event to `bali:<component>:<event>`, so the `sortable-list:onEnd` the current grid
listens for is now `bali:sortable-list:end`. Bali's side of this port is unaffected — it targets v3
semantics — but **enjoykitchen needs the 2.9 → 3.x upgrade before it can adopt any of this**. Out of
scope for this spec; recorded so it is not discovered during the swap.

## Out of scope

- The nineteen `Widgets::*` classes, `Widgets::Routes`, and the `DashboardWidgets` concern.
- The membership picker UI (`user_widgets#edit`, the drawer with a checkbox per authorized widget).
  `Store#choose` is the write half; the UI stays in the host because its list *is* the authorized set.
- Any change to `Bali::SortableList` — including its `disabled`-only-at-connect limitation, which
  handle-gating routes around at no cost.
- The enjoykitchen 2.9 → 3.x upgrade.
