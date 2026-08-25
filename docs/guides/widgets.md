# Widgets and the dashboard grid

A user-arrangeable bento dashboard: which widgets an owner sees, in what order, at what
size. Bali ships the presentation half of this — the widget contract, the card, the grid,
the Stimulus controllers, the CSS, the previews. **It ships no store and no table.**
Persistence is always the host's, the same way a widget's own visibility rule is: `Bali`
gives you the shape, you supply the object that remembers anything.

This guide covers the three engine pieces briefly, then documents the store contract in
full — because once you're past "which component do I render", the contract is the whole
of what you're implementing.

## The three pieces

`Bali::Widget::Base` is the contract a widget class implements. **Your own store** reads
and writes one owner's arrangement — see [The store contract](#the-store-contract) below.
`Bali::WidgetGrid::Component` renders it.

```ruby
class LowStockItems < Bali::Widget::Base
  # Bali::Widget::Base deliberately carries almost no surface — it does NOT give you
  # route helpers. A widget that links its rows anywhere needs them itself.
  include Rails.application.routes.url_helpers

  sized :medium

  def visible? = context.has_any_role?(:inventory_manager)

  def call = list_from(low_stock.order(:name), view_all_path: items_path)

  private

  def row(item)
    Bali::Widget::Row.new(title: item.name,
                          subtitle: subtitle("#{item.stock} left", item.outlet_name),
                          href: item_path(item))
  end
end
```

`sized` is validated at class-definition time — an unknown size is a boot failure, not a
`KeyError` the first time someone opens the dashboard. `visible?` is a HOOK, never a rule
Bali owns: roles, tenancy and feature flags are things only your app can see, and it
defaults to `true`. `call` returns a `Bali::Widget::Result`; the private `list_from`
builds one from an ordered scope, capping the preview at `PREVIEW_ROWS` (8 rows) while
`count` still reflects the whole scope — which is what lets `#call` stay ignorant of the
size the card renders at. `context` is whatever your app needs to gate on (a Pundit
context, a user, nothing at all) — Bali never reads it itself.

## The widget's copy is yours, in your own locale scope

A widget's `title`, `short_title`, `description` and `empty` come from **your** app's locale
files, under a plain `widgets.<key>.*` scope — deliberately NOT under `bali_view.*`, which is
where Bali keeps its own chrome (the Edit/Done labels, the size names, "Couldn't load"). Bali
ships that chrome in `en` and `es`; the widget's own words are host content and it has none.

The `key` is derived from the class name, so `LowStockItems` reads `widgets.low_stock_items.*`:

```yaml
en:
  widgets:
    low_stock_items:
      title: "Low stock items"
      short_title: "Low stock"        # optional; falls back to title
      description: "Ingredients running low"
      empty: "Nothing running low"
```

Without these you get `translation missing` on the card, so add them when you add the widget.
Point `Bali::Widget::Base.i18n_scope` elsewhere if `widgets` collides with something you
already use, or override the four class methods directly — which is what the Lookbook previews
in this engine do, since they have no locale file of their own.

## Gating: building the `offering:`

A store never decides who can see what. It is handed the already-authorized set and can
only subset, reorder and resize it — a stale or tampered widget key finds nothing in that
set and is inert.

```ruby
def offering
  Bali::Widget.authorized_for(WIDGETS.map { |klass| klass.new(pundit_user) })
end
```

`Bali::Widget.authorized_for` just selects on `#visible?`. It costs only whatever your
`visible?` bodies cost — never a widget query, since visibility and loading are
deliberately kept separate.

## Rendering

```erb
<%= render Bali::WidgetGrid::Component.new(
      url: widget_layout_path, add_path: edit_user_widgets_path) do |grid| %>
  <% grid.with_heading { tag.h2("Today", class: "text-lg font-semibold") } %>
  <% layout.widgets.each do |widget| %>
    <% grid.with_widget(widget) %>
  <% end %>
<% end %>
```

`with_heading` replaces only the leading text next to the Edit/Done controls — the
controls themselves are structural and always render, deliberately, so a heading override
can never delete the dashboard's one entry point into edit mode.

A widget that isn't a list fills the card's `body` slot instead of falling through to the
default row list:

```erb
<% grid.with_widget(widget) do |card| %>
  <% card.with_body { render Compliance::TodayPanel::Component.new(widget.payload) } %>
<% end %>
```

`add_path:` is optional. When given, a dashed "+" tile appears in edit mode — and, when
the grid has no widgets at all, it becomes the empty state's own call to action, so a host
that configured `add_path:` still has a way to add its first widget.

## The write path

Bali ships **no controller, no routes and no store** — who may see which widget is your
rule, so the write goes through whatever store you built the offering with. Every
gesture — drag, arrow-key move, resize, remove — PATCHes the **whole** arrangement to
`url:`, not a diff:

```
widgets[][key]=low_stock_items&widgets[][size]=medium&widgets[][key]=cost_spikes&widgets[][size]=
```

```ruby
class WidgetLayoutsController < ApplicationController
  def update
    layout.arrange(permitted_layout)
    head :no_content
  end

  private

  def layout
    DashboardWidget.store_for(current_user, context: @tenant.id.to_s,
                              dashboard_key: "today", offering: offering)
  end

  # THE BOUNDARY. A submitted key becomes a widget only by looking it up in the
  # already-authorized offering — an unauthorized or retired key finds nothing
  # and is silently dropped. That is the design's entire security property.
  def permitted_layout
    return [] if params[:widgets].blank?

    by_key = offering.index_by(&:key)
    params.expect(widgets: [%i[key size]]).filter_map do |item|
      widget = by_key[item[:key].to_s]
      { widget: widget, size: item[:size] } if widget
    end
  end
end
```

The `params[:widgets].blank?` guard runs **before** `params.expect`, deliberately:
`expect` raises `ActionController::ParameterMissing` on both an omitted `widgets` key and
an empty `widgets: []` — and an empty submission is not an error here, it is the reset
gesture below.

Three behaviours are not obvious and matter — see [Five behaviours to get right](#five-behaviours-to-get-right)
for the full list with the reasoning behind each:

- **There is no way to store "an empty dashboard".** No visible rows means "never chose", so
  a well-behaved `#widgets` falls back to the whole offering. That is what gives a new user a
  populated dashboard and what makes "restore defaults" work — but it also means a picker in
  which the user unticks *everything* shows them MORE widgets, not none. Say so in your
  picker's copy; the gesture reads the other way round. The dummy app's picker
  (`spec/dummy/app/views/dashboard_widgets/picker.html.erb`) does exactly that.
- **An empty sequence means reset.** Removing the last widget submits nothing; `arrange([])`
  should delete every row, and no rows means "never chose" — the next read restores every
  authorized widget, in catalog order.
- **The grid reloads after an empty sequence.** A `204` returns no markup, which would
  leave an empty grid on screen over a full dashboard already sitting in the database,
  wrong until the next navigation — so the grid's own JavaScript does a full reload
  specifically for this one case.

## The store contract

Bali ships this contract and nothing that implements it. A store is a plain object — not
necessarily an ActiveRecord model — scoped to one owner, one context and one dashboard,
built however you like (`DashboardWidget.store_for(...)`, `Store.new(...)`, a service
object, anything with these seven methods):

| Method | Returns |
|---|---|
| `#widgets` | the offering, subset, reordered and resized by what is stored. No **visible** stored row means "never chose" — the whole offering, in catalog order |
| `#stored_keys` | every stored key, including rows for widgets the owner cannot currently see |
| `#visible_keys` | stored keys ∩ offering keys, in stored order |
| `#customized?` | `visible_keys.any?` — whether there is anything visible to reset |
| `#choose(widgets)` | membership only: survivors keep their stored order, newly chosen widgets append. Re-supplies each survivor's stored size internally, because `arrange` (below) is a full reconcile — without that, every `choose` would silently reset every already-sized card back to its default |
| `#arrange(layout)` | reconciles to exactly `layout`, an ordered `[{ widget:, size: }, …]` where position is the array index — delete-then-insert, **not** an upsert, and an omitted `size` means "no opinion" (the widget renders at the size it was drawn around) |
| `#reset` | drops every row — what "restore defaults" and an emptied grid both mean |

Rows never grant visibility, and a row for a widget the owner can no longer see survives
rather than being deleted — so a temporarily revoked role, or a feature flag flipped off
and back on, does not silently erase someone's arrangement.

### Five behaviours to get right

The seven method signatures above are easy to copy. These five are not obvious from the
signatures, and a store that gets any of them wrong ships a subtle bug:

1. **`#widgets` can only ever return members of `offering`.** This is the security
   invariant. A key for a widget whose role the owner lost, whose feature flag went off,
   that was retired from the catalog, or that was hand-edited into the table — all four
   collapse to the same `nil` from one lookup (`offering.index_by(&:key)`). Implement this
   by mapping over the offering, never by checking a stored key against a permitted list:
   the point is that an unauthorized widget structurally *cannot* come back, not that a
   filter happens to catch it.

2. **No VISIBLE rows means "never chose" — fall back to the whole offering.** A dashboard
   holding only rows for widgets the owner can no longer see must render the full offering,
   not an empty grid; otherwise a temporarily revoked role empties someone's dashboard
   instead of just hiding one card. The corollary is the one that surprises people: **there
   is no way to store "an empty dashboard".** A picker where the user unticks every widget
   restores defaults — showing them MORE widgets, not none. Say so in the picker's copy,
   because the gesture reads the other way.

3. **`choose` is membership; `arrange` is a full reconcile.** `choose` takes "here is what
   should be present" and must preserve stored order for survivors, append newcomers after
   them, and collapse a key submitted twice into one row (or let the unique index reject the
   write). `arrange` takes "here is the whole layout, in order" and reconciles to exactly
   that — it is not additive.

4. **`choose` must re-supply stored sizes.** Because `arrange` deletes and re-inserts,
   `choose` implemented as "look up widgets, call arrange" without first reading each
   survivor's current `size` and passing it back in silently resets every card's size the
   moment its checkbox is re-ticked. This was a real bug caught in review — ticking a box
   should never resize anything.

5. **`stored_keys` and `visible_keys` are different, and `customized?` must use the
   second.** `stored_keys` answers "has this owner ever chosen anything"; `visible_keys`
   answers "is there anything on their dashboard right now". An owner whose only stored row
   points at a widget they can no longer see has customized nothing they can see — offering
   them "restore defaults" in that state is offering it to someone already looking at
   defaults.

### Reference implementation

`spec/dummy/app/models/dashboard_widget/store.rb` is a complete, worked implementation of
this contract, backed by the row model at `spec/dummy/app/models/dashboard_widget.rb` and
the migration at `spec/dummy/db/migrate/20260825130000_create_dashboard_widgets.rb`. Its
comments walk through the reasoning behind each of the five behaviours above in the
context of real code, and `test/dummy_dashboard_widget_store_test.rb` exercises all of
them. Copying it — table, model, store — is a reasonable way to adopt this feature; nothing
about it is engine-specific.

```ruby
DashboardWidget.store_for(
  current_user,
  context: @tenant.id.to_s,   # the scoping string; "" for a single-tenant app
  dashboard_key: "today",     # which dashboard, for a host with more than one
  offering: offering
)
```

Two different things are both called "context" here, and they are not the same one.
The scoping string above is unrelated to `Bali::Widget::Base#context`, the actor object a
widget's `visible?` gates against. A store never sees the actor object; `Base` never sees
the scoping string.

### Locking has real limits

A store's writes typically lock their scope's rows before writing (`SELECT ... FOR UPDATE`
inside a transaction, as the reference implementation does), but that buys less than the
name suggests:

- **It cannot lock rows that don't exist yet.** On a first-ever write for an owner there is
  nothing to lock, so two concurrent requests proceed completely unserialized.
- **It does not prevent a lost update even when rows already exist.** Each request
  computes its target state from its own snapshot; the later commit wins wholesale, and
  because `arrange` deletes before it inserts, the loser's row is simply gone — no
  exception, no conflict, just silence.
- **On SQLite it is a no-op.** `.lock` emits no `FOR UPDATE` on that adapter, so the
  locking described above is real only on PostgreSQL.

In practice this bounds the exposure to one owner racing themselves (two tabs, a retried
request), and the grid's own JavaScript already serializes its writes client-side (a
250ms debounce plus a promise queue). A host that needs a stronger guarantee should reach
for an advisory lock keyed on the scope (`pg_advisory_xact_lock`), which serializes
writers even with zero rows present.
