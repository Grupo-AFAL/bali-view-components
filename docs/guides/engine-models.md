# Engine models: the tables Bali ships

Bali is mostly view components, but a few features need somewhere to *put* things. For
those, the engine ships the model layer itself — a table, an Active Record model, and a
concern or plain object your own models opt into — instead of asking every app to
reinvent the same schema.

This page is the adoption guide for all of them. For how your authentication reaches the
engine's **controllers**, see [Engines](engines.md); this page is about the **models**.

## The shape they all share

Every engine model follows the same four steps, so learning one teaches you the rest:

1. **Install the migration**, naming the feature you want:

   ```bash
   bin/rails bali:install:migrations:saved_views
   bin/rails db:migrate
   ```

2. **Opt a model in**, usually by including a concern. Nothing is global: a table with no
   model pointing at it simply stays empty.

3. **Configure the lambdas**, if the feature has an HTTP surface. The engine's controllers
   do not inherit your `ApplicationController`, so access is decided by configuration
   rather than by your `before_action`s. Every one of them denies by default.

4. **Everything is polymorphic.** Owners, records, users and authors are all polymorphic
   associations, because the engine cannot know whether your user is a `User`, a `Member`
   or an `Employee`. That is also why no engine table has a foreign key constraint
   pointing into your schema.

### Installing one feature at a time

The features on this page are unrelated to each other, and an app usually adopts one of
them. Rails' plain `bali:install:migrations` does not know that: it copies **every**
migration an engine ships, so asking for saved views also hands you content versions,
entity references, acknowledgments, block editor comments and dashboard widgets — five
tables you never asked for, permanently in the `db/schema.rb` every one of your PRs
reviews (#1079).

So name the feature. One task per table, listed by `bin/rails -T bali`:

```bash
bin/rails bali:install:migrations:saved_views
bin/rails bali:install:migrations:content_versions
bin/rails bali:install:migrations:entity_references
bin/rails bali:install:migrations:acknowledgments
bin/rails bali:install:migrations:block_editor_comments
bin/rails bali:install:migrations:dashboard_widgets
```

Each copies exactly one migration, through the same copier the umbrella task uses: it
renumbers to the moment of the copy, keeps the `.bali.rb` suffix, and leaves a migration
you already installed alone. Run one now and the next one months later — that is the
point.

`bali:install:migrations` still copies all six, for an app that really does want
everything. It now prints the per-feature list before it starts.

---

## Saved views (`bali_saved_views`)

The default storage behind the DataTable's "Views" dropdown: a named combination of
filters, belonging to an owner and to one listing.

```ruby
# The FilterForm resolves the engine's store for you
Bali::FilterForm.new(
  ...,
  saved_views_store: :default,
  saved_views_owner: current_user
)
```

Or use the store directly, which is what `:default` builds:

```ruby
store = Bali::SavedView.store_for(current_user, "movies_index")
store.list
store.save(name: "Finished", payload: { "attributes" => { "status_eq" => "done" } })
```

`owner` is polymorphic on purpose: the phase-2 idea of team or role views changes the
owner, not the schema. `storage_id` is the same key the FilterForm already uses to persist
filters, so a view belongs to exactly one listing.

**Configuration** (`config/initializers/bali.rb`):

| Config | Purpose | Default |
|---|---|---|
| `Bali.saved_views_owner` | Resolves the owner from the request | `->(controller) { controller.try(:current_user) }` |
| `Bali.saved_views_authorize` | Gates `Bali::SavedViewsController` | Owner present, else 403 |

The payload is sliced to the keys the FilterForm declares, so the UI cannot smuggle extra
data into the column. Someone else's view answers 404 rather than 403 — a 403 would
confirm it exists.

---

## Acknowledgments (`bali_acknowledgments`)

A signature book: *this person confirmed they read this*. Both halves are polymorphic, so
one table serves documents signed by `User`s, agreements signed by `Member`s, and whatever
comes next.

```ruby
class Document < ApplicationRecord
  include Bali::Acknowledgeable
end

@document.acknowledge(user: current_user)   # => Bali::Acknowledgment
@document.acknowledged_by?(current_user)    # => true
@document.acknowledgments                   # the signatures themselves
```

There is no macro to configure. The only thing the concern asks your model is
`version_label`, and it asks with `try`, so a model without versions works unchanged:

```ruby
class Document < ApplicationRecord
  include Bali::Acknowledgeable

  # Whatever you show people: "1.0", "Rev. C", "2026-Q2".
  attribute :version_label, :string, default: "1.0"
end
```

### What re-confirming does

`acknowledge` is **idempotent for the same version**: confirming twice returns the
signature that already existed, untouched. That is what makes the record usable as
evidence — the original `acknowledged_at` is when that person signed.

When `version_label` has **changed**, the person is signing a different text, so it is a
new act: the label *and* the date are both updated on the same row. There is never a
second row per person and record — the unique index on
`[acknowledgeable_type, acknowledgeable_id, user_type, user_id]` makes sure of it.

> **Note for anyone porting from gobierno-corporativo:** its `acknowledge` keeps the
> original `acknowledged_at` across a re-confirmation and only moves `version_number`. That
> leaves a row asserting someone signed v2.0 at a time when v2.0 did not exist yet. With
> only two columns the coherent reading is "`acknowledged_at` is when they signed
> `version_label`", so Bali moves them together.

### `content_version_id`

The column is there, nullable, **without a foreign key**, so that installing the signature
book never forces you to install the [content versions](#content-versions) table. When
both are present the concern fills it in with the record's newest version; when they are
not, it stays `nil`. You can always name it yourself:

```ruby
@document.acknowledge(user: current_user, content_version_id: some_version.id)
```

### The controller stays in your app

The engine deliberately ships **no** acknowledgments controller. The valuable part of one
is the `turbo_stream` response, and that renders a partial *of yours* — an engine
controller cannot do that without knowing your views. The whole thing is about twenty
lines:

```ruby
# app/controllers/acknowledgments_controller.rb
class AcknowledgmentsController < ApplicationController
  before_action :set_acknowledgeable

  def create
    authorize @acknowledgeable, :acknowledge?   # your authorization, your rules

    @acknowledgeable.acknowledge(user: current_user)

    respond_to do |format|
      format.turbo_stream                       # renders your own partial
      format.html { redirect_back fallback_location: @acknowledgeable }
    end
  end

  private

  # Whitelist, never `constantize` — the type arrives from the request.
  ACKNOWLEDGEABLE = { "document" => Document, "agreement" => Agreement }.freeze

  def set_acknowledgeable
    key = request.path_parameters.keys.find { |k| k.to_s.end_with?("_id") && k != :id }
    klass = ACKNOWLEDGEABLE[key.to_s.delete_suffix("_id")]
    raise ActiveRecord::RecordNotFound unless klass

    @acknowledgeable = klass.find(params[key])
  end
end
```

```ruby
# config/routes.rb
resources :documents do
  resources :acknowledgments, only: %i[index create]
end
```

Route it under each acknowledgeable resource and the nested `*_id` param tells the
controller what is being signed. Keep the whitelist: `params[:type].constantize` would let
a request name any class in your app.

### Read coverage

`Bali::ReadCoverage` answers "how much of the audience has signed?". The audience is
**injected** — the engine has no opinion about where it comes from, because that is the
part every app does differently (a department, a role, an explicit reader list):

```ruby
coverage = Bali::ReadCoverage.new(@document, audience: @document.readers, threshold: 80)

coverage.total_count          # => 4
coverage.confirmed_count      # => 3
coverage.pending_count        # => 1
coverage.confirmed_users      # => [#<User ...>, ...]
coverage.pending_users        # => [#<User ...>]
coverage.coverage_percentage  # => 75.0
coverage.below_threshold?     # => true
```

`audience` is any collection of user records — an Array or a Relation. All the objects
need is an `id` and a class, which is how they are matched against the polymorphic pair on
each signature. The signatures are read in a single query no matter how big the audience
is, and it does not group by department or area: that is your domain, not Bali's.

`threshold` defaults to `80`, the only value in production use today, but it is a
per-application policy, not a shared constant.

**An empty audience has no coverage, not zero coverage.** `coverage_percentage` returns
`nil` — `0/0` is not `0`, and reporting 0% would paint a dashboard red over records nobody
has to read, while reporting 100% would claim a coverage nobody confirmed. `nil` forces
whoever renders it to decide what goes there ("—", "No audience"), which is the honest
answer. `below_threshold?` still returns a boolean, and it is `false`: with nobody required
to read, nothing is outstanding. (gobierno-corporativo returns `0` and `true` here; this is
a deliberate change.)

### Porting the table from gobierno-corporativo

Its `acknowledgments` table is close but not identical:

| gobierno-corporativo | Bali | What to do |
|---|---|---|
| `user_id` bigint, `belongs_to :user` | `user` polymorphic | Backfill `user_type = 'User'` |
| `version_number` string | `version_label` | Rename; the name was colliding with the integer `version_number` of content versions |
| `document_version_id` | `content_version_id` | Only meaningful once content versions are installed |
| `ALLOWED_ACKNOWLEDGEABLE_TYPES` on the model | no whitelist on the model | The type never arrives from a request; whitelist it in *your* controller instead |

---

## Content versions

Shipped (#707): `Bali::ContentVersion` plus the `Bali::ContentVersionable` concern, with
the `create_bali_content_versions` migration. It backs DocumentEditor's version history
(preview and restore) — include the concern in the model whose content is versioned and
point the editor's `versions_url:`/`restore_version_url:` at the engine's endpoints (or
pass `record:` and let `:auto` resolve them).

## Comments and threads

Shipped (#706): `Bali::BlockEditorThread`, `Bali::BlockEditorComment` and
`Bali::BlockEditorReaction`, with the `create_bali_block_editor_comments` migration. They
back BlockEditor's comments sidebar — enable it with `comments:` in the editor's
`config:`.

## Entity references

Shipped (#708): `Bali::EntityReference` plus the `Bali::EntityReferenceable` concern,
with the `create_bali_entity_references` migration. It records which entities a document
mentions, so back-references ("mentioned in…") can be listed from either side.

---

## Dashboard widgets (`bali_dashboard_widgets`)

A user-arrangeable bento dashboard: which widgets an owner sees, in what order, at what
size.

```bash
bin/rails bali:install:migrations:dashboard_widgets
bin/rails db:migrate
```

### The three pieces

`Bali::Widget::Base` is the contract a widget class implements. `Bali::Widget::Layout`
reads and writes one owner's arrangement. `Bali::WidgetGrid::Component` renders it.

```ruby
class LowStockItems < Bali::Widget::Base
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

### The widget's copy is yours, in your own locale scope

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

### Gating: building the `offering:`

`Bali::Widget::Layout` never decides who can see what. It is handed the already-authorized
set and can only subset, reorder and resize it — a stale or tampered widget key finds
nothing in that set and is inert.

```ruby
def offering
  Bali::Widget.authorized_for(WIDGETS.map { |klass| klass.new(pundit_user) })
end
```

`Bali::Widget.authorized_for` just selects on `#visible?`. It costs only whatever your
`visible?` bodies cost — never a widget query, since visibility and loading are
deliberately kept separate.

### Constructing a `Layout`

```ruby
layout = Bali::Widget::Layout.new(
  owner: current_user,
  context: @tenant.id.to_s,   # the scoping string; "" for a single-tenant app
  dashboard_key: "today",     # which dashboard, for a host with more than one
  offering: offering
)
```

Two different things are both called "context" here, and they are not the same one.
`Layout.new(context:)` is a scoping STRING — a tenant id — and it is unrelated to
`Bali::Widget::Base#context`, the actor object a widget's `visible?` gates against.
`Layout` never sees the actor object; `Base` never sees the scoping string.

### Rendering

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

### The write path

Bali ships **no controller and no routes** — who may see which widget is your rule, so the
write goes through the same `Layout` you built the offering with. Every gesture — drag,
arrow-key move, resize, remove — PATCHes the **whole** arrangement to `url:`, not a diff:

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
    Bali::Widget::Layout.new(owner: current_user, context: @tenant.id.to_s,
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

Two behaviours are not obvious and matter:

- **An empty sequence means reset.** Removing the last widget submits nothing;
  `Layout#arrange([])` deletes every row, and no rows means "never chose" — the next read
  restores every authorized widget, in catalog order.
- **The grid reloads after an empty sequence.** A `204` returns no markup, which would
  leave an empty grid on screen over a full dashboard already sitting in the database,
  wrong until the next navigation — so the grid's own JavaScript does a full reload
  specifically for this one case.

### `Bali::Widget::Layout` methods

| Method | Returns |
|---|---|
| `#widgets` | the offering, subset, reordered and resized by what is stored. No **visible** stored row means "never chose" — the whole offering, in catalog order |
| `#stored_keys` | every stored key, including rows for widgets the owner cannot currently see |
| `#visible_keys` | stored keys ∩ offering keys, in stored order |
| `#customized?` | `visible_keys.any?` — whether there is anything visible to reset |
| `#choose(widgets)` | membership only: survivors keep their stored order, newly chosen widgets append. Re-supplies each survivor's stored size internally, because `arrange` (below) is a full reconcile — without that, every `choose` would silently reset every already-sized card back to its default |
| `#arrange(layout)` | reconciles to exactly `layout`, an ordered `[{ widget:, size: }, …]` where position is the array index — `delete_all` then `insert_all`, **not** an upsert, and an omitted `size` means "no opinion" (the widget renders at the size it was drawn around) |
| `#reset` | drops every row — what "restore defaults" and an emptied grid both mean |

Rows never grant visibility, and a row for a widget the owner can no longer see survives
rather than being deleted — so a temporarily revoked role, or a feature flag flipped off
and back on, does not silently erase someone's arrangement.

### Locking has real limits

`choose` and `arrange` lock their scope's rows before writing (`SELECT ... FOR UPDATE`
inside a transaction), but that buys less than the name suggests:

- **It cannot lock rows that don't exist yet.** On a first-ever write for an owner there is
  nothing to lock, so two concurrent requests proceed completely unserialized.
- **It does not prevent a lost update even when rows already exist.** Each request
  computes its target state from its own snapshot; the later commit wins wholesale, and
  because `arrange` deletes before it inserts, the loser's row is simply gone — no
  exception, no conflict, just silence.
- **On SQLite it is a no-op.** `.lock` emits no `FOR UPDATE` on that adapter, so the
  locking described above is real only on PostgreSQL.

In practice this bounds the exposure to one owner racing themselves — two tabs, a retried
request — and the grid's own JavaScript already serializes its writes client-side (a
250ms debounce plus a promise queue). A host that needs a stronger guarantee should reach
for an advisory lock keyed on the scope (`pg_advisory_xact_lock`), which serializes
writers even with zero rows present. Bali does not ship one: it is PostgreSQL-only, and
the engine runs on whatever database the host has.
