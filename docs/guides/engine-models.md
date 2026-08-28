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

`Bali::Widget::Base` is the contract a widget class implements. `Bali::DashboardWidget::Store`
reads and writes one owner's arrangement. `Bali::WidgetGrid::Component` renders it.

### The pattern is the type

A widget does not declare what shape it is; it **inherits** it. There are four bases, one per
shape, and picking one is what supplies both the declarations you may use and the methods you
owe:

| Base | The card shows | You implement | You declare |
|---|---|---|---|
| `Bali::Widget::ValueBase` | one figure | `value` | `formatted_value` if the number is not the display |
| `Bali::Widget::ListBase` | how many, and which | — | `list`, `row_title`, `row_subtitle`, `row_href` |
| `Bali::Widget::TrendBase` | a figure and how it moved | `current`, `previous` | `positive_when`, `period_label`, `series_labels`, `series_values` |
| `Bali::Widget::ProgressBase` | a ring toward a goal | `value`, `max` | `goal_label`, `series_labels`, `series_values` |

This is single inheritance on purpose: **a widget is exactly one of these.** A class that could
claim two shapes could claim them inconsistently, and the card would have to ask which one it
meant. It never asks — `Base` answers every question with a null (`items` is `[]`, `trend` is
`nil`, `goal` is `nil`), each pattern overrides the ones it actually has, and the card reads
one uniform interface at every size.

It also means a subclass that forgets an abstract method fails loudly rather than rendering
half a thing: `TrendBase#current` raises `NotImplementedError` until you write it.

```ruby
class LowStockItems < Bali::Widget::ListBase
  default_size :medium

  list { Item.low_stock.order(:name) }

  row_title    :name
  row_subtitle :outlet_name
  row_href     { |item| item_path(item) }

  view_all_path { items_path }
end
```

**`list` is the primitive.** `count` and the preview rows both fall out of one declaration, so
a list widget states its collection once.

**Order the scope yourself**, in the scope — there is no `order_by:` keyword, because there is
one obvious place to write it and it is the place you would write it anyway. Bali applies
`limit` *after* your block returns, so ordering written inside the scope is always applied
first. An unordered scope pages the preview off whatever the database happened to return, which
is a different bug in every database. `limit:` defaults to `PREVIEW_ROWS` (8), which covers
every built-in size; raise it only if you have also raised `Component.regions` past eight.

**`list` takes a block and nothing else**, and that is deliberate rather than terse. A class
body runs once at boot, so a relation written there closes over the moment the process started:
`where(due_date: Date.current..)` would keep that day's window and the tile would show the wrong
week until a redeploy. The reloader re-runs the class body on every request, so the bug cannot
reproduce in development — it is silent, and only in production.

The block is re-read on every render and runs against the widget, so it also reaches `context`
and private helpers. A scope frozen into the class body could never be tenant- or user-scoped,
which is most widgets in a real app:

```ruby
list { Task.for_tenant(context.tenant).due_after(Date.current).order(:due_date) }
```

**The row declarations are symbols sent to the record**, which is the ergonomic point of them:
`row_title :name` says everything `->(r) { r.name }` would. `row_href` takes a block, because a
path is built from a helper rather than read off the record, and `row_subtitle` accepts either
— a symbol for one attribute, a block when it composes two.

A **string is the value itself**, not a third spelling of "send this to the record": a symbol
references, a string is. `row_subtitle "In stock"` labels every row the same way, and reads the
same as the `title "Low stock items"` a few lines above it.

**Blocks run against the widget, so take the record as an argument — don't reach for it
bare.** `size`, `count`, `items`, `title`, `key`, `description` and `subtitle` are all widget
methods, and several are ordinary column names too: inside `row_subtitle { … }`, a bare `size`
is the widget's size, not the record's. Always name the parameter:

```ruby
row_subtitle { |studio| subtitle(studio.country, studio.size&.humanize) }
```

A trend widget implements the two figures and lets the base compute the delta between them:

```ruby
class StudioFoundings < Bali::Widget::TrendBase
  default_size :medium

  period_label  "vs previous decade"
  series_labels { decades.keys.map(&:to_s) }
  series_values { decades.values }

  view_all_path { admin_studios_path }

  def current  = decades.values.last
  def previous = decades.values[-2]

  private

  # Declaration blocks run against the widget, so private helpers and memoisation
  # work exactly as they do in a method — which is how `series` and `trend` share
  # one query.
  def decades = @decades ||= Studio.group(…).count.sort.to_h
end
```

`previous` returning **`nil` means the trend is absent, not zero** — a widget's first week has
nothing to compare against, and the card drops the indicator rather than drawing a flat 0%.
Every trend widget used to hand-roll `(((latest - previous) / previous.to_f) * 100).round`;
it is written once in the base now, and `current`/`previous` is a contract you cannot
half-implement.

**`positive_when` is a declaration because getting it wrong makes the card lie.** "Up" is not
universally good — overdue tasks up 12% and revenue up 12% are opposite news, and the direction
alone cannot tell them apart. The card colours from whether the movement was *good*, so a widget
counting something bad declares `positive_when :down` and a rising number then reads red.

The simplest pattern is one figure:

```ruby
class ProductionBudget < Bali::Widget::ValueBase
  default_size :small

  view_all_path { admin_movies_path }

  def value = Movie.budgeted.sum(:budget).to_i
  def formatted_value = "$#{Bali::Widget.abbreviate(value)}"
end
```

### The sizes you offer are a promise about the data you have

`medium` and `large` put a context region beside or above the headline. `ValueBase` therefore
offers `small` alone, and that is the class's point rather than a limitation of it: a bare
figure at `large` is a title, a number and most of a 2×2 cell of whitespace. Say `supports`
yourself to override it.

`supports` is **declared, never inferred from the data.** Inferring "this widget has no series,
so hide `large`" would mean loading every widget just to render a picker — collapsing the
`visible?`/data split that lets the picker list the authorized set without a single query. It
would also make the offered sizes vary with the data: a widget whose series is empty this week
would silently stop offering a size the user had already chosen. Apple declares
`supportedFamilies` for the same two reasons.

Both `default_size` and `supports` are validated at class-definition time, and `supports`
additionally rejects a default the user could not choose — a typo is a boot failure, not a
`KeyError` the first time someone opens the dashboard.

### What every widget gets from `Base`

`view_all_path` is on `Base` rather than on `ListBase`, because a figure, a trend and a ring
all link somewhere just as a list does. Route helpers are not available to a widget by default:
put `include Rails.application.routes.url_helpers` in a concern your widgets share, the way
`spec/dummy/app/widgets/widget_routes.rb` does. (A shared `ApplicationWidget` superclass is not
an option here — the superclass slot belongs to the pattern.)

`visible?` is a HOOK, never a rule Bali owns: roles, tenancy and feature flags are things only
your app can see, and it defaults to `true`. It must not touch the database — that split is what
lets the picker list the offering without loading anything. `context` is whatever your app needs
to gate on (a Pundit context, a user, nothing at all); Bali never reads it itself.

The preview is capped at `PREVIEW_ROWS` (8 rows) while `count` reflects the whole scope, which
is what lets a widget stay ignorant of the size its card renders at.

**One widget's failure must not take the page with it.** Every data read a pattern makes is
wrapped, so a raising widget renders a degraded "Couldn't load" tile instead of a 500 — and
memoises the failure, so the card's several questions do not re-run the broken query. In
development and test the safety net is off (`Bali::Widget.raise_load_errors?`), because a widget
bug there is a bug rather than a permanently apologetic tile.

### The four ladders

The card shows the same fact at every size and adds context as the canvas grows. It never
changes subject.

| Pattern | small → medium → large |
|---|---|
| **Value** | figure *(the only size it offers)* |
| **List** | count → count + 3 rows → count + 7 rows |
| **Trend** | figure + trend → + sparkline → + axed chart |
| **Progress** | ring → ring + sparkline → ring + axed chart |

A `small` card is a different card, not a narrower one: it drops everything but the headline
and the whole tile becomes one link, because a tile that size supports exactly one tap target.

```bash
bin/rails g bali:widget StudioFoundings --pattern trend --size medium
```

scaffolds exactly that pattern's abstract methods and declarations with the reasoning in
comments, which is the shortest way to learn what one needs.

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

`Bali::DashboardWidget::Store` never decides who can see what. It is handed the
already-authorized set and can only subset, reorder and resize it — a stale or tampered
widget key finds nothing in that set and is inert.

```ruby
def offering
  Bali::Widget.authorized_for(WIDGETS.map { |klass| klass.new(pundit_user) })
end
```

`Bali::Widget.authorized_for` just selects on `#visible?`. It costs only whatever your
`visible?` bodies cost — never a widget query, since visibility and loading are
deliberately kept separate.

### Constructing a `Store`

```ruby
layout = Bali::DashboardWidget::Store.new(
  owner: current_user,
  context: @tenant.id.to_s,   # the scoping string; "" for a single-tenant app
  dashboard_key: "today",     # which dashboard, for a host with more than one
  offering: offering
)
```

There is no `DashboardWidget.store_for` shortcut, unlike `Bali::SavedView.store_for`.
`Store.new` takes four keywords and a shortcut that forwarded all four unchanged
bought a saved line and a second name for one thing.

Two different things are both called "context" here, and they are not the same one.
`Store.new(context:)` is a scoping STRING — a tenant id — and it is unrelated to
`Bali::Widget::Base#context`, the actor object a widget's `visible?` gates against.
`Store` never sees the actor object; `Base` never sees the scoping string.

`Bali::DashboardWidget::Store` is the DEFAULT implementation, not a requirement. A host
that already persists dashboards elsewhere — an existing table, its own model — can
implement the same contract (`widgets`, `stored_keys`, `visible_keys`, `customized?`,
`choose`, `arrange`, `reset`) and pass that object wherever a `Store` is expected instead;
such a host never runs `bali:install:migrations:dashboard_widgets`. See the class comment
on `Bali::DashboardWidget::Store` for the contract in full.

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

**There is currently no way to render a plain, non-editable grid.** `url:` is a required
keyword and the Edit/Done controls always render — deliberately, so a heading override
can never delete the dashboard's only entry point into edit mode (see above). One
consequence of that guarantee is that `Bali::WidgetGrid::Component` cannot express a
read-only bento: an admin viewing someone else's dashboard, an embedded summary, a
read-only export. A host that needs one today has to compose its own layout directly out
of `Bali::Widget::Component` cards. This is a current limitation, not a contract Bali is
promising to keep.

### The write path

Bali ships **no controller and no routes** — who may see which widget is your rule, so the
write goes through the same `Store` you built the offering with. Every gesture — drag,
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
    Bali::DashboardWidget::Store.new(owner: current_user, context: @tenant.id.to_s,
                                     dashboard_key: "today", offering: offering)
  end

  # THE BOUNDARY. `Bali::Widget::Layout` does the lookup; you supply the
  # offering. A submitted key becomes a widget only by being found in the
  # already-authorized set — an unauthorized, retired or hand-edited key finds
  # nothing and is dropped rather than rejected, so a role revoked between
  # render and submit degrades quietly.
  def permitted_layout = Bali::Widget::Layout.from(params, offering: offering)
end
```

The `params[:widgets].blank?` guard runs **before** `params.expect`, deliberately:
`expect` raises `ActionController::ParameterMissing` on both an omitted `widgets` key and
an empty `widgets: []` — and an empty submission is not an error here, it is the reset
gesture below.

Two behaviours are not obvious and matter:

- **There is no way to store "an empty dashboard".** No visible rows means "never chose", so
  `#widgets` falls back to the whole offering. That is what gives a new user a populated
  dashboard and what makes "restore defaults" work — but it also means a picker in which the
  user unticks *everything* shows them MORE widgets, not none. Say so in your picker's copy;
  the gesture reads the other way round. The dummy app's picker
  (`spec/dummy/app/views/dashboard_widgets/picker.html.erb`) does exactly that.

- **An empty sequence means reset.** Removing the last widget submits nothing;
  `Store#arrange([])` deletes every row, and no rows means "never chose" — the next read
  restores every authorized widget, in catalog order.
- **The grid reloads after an empty sequence.** A `204` returns no markup, which would
  leave an empty grid on screen over a full dashboard already sitting in the database,
  wrong until the next navigation — so the grid's own JavaScript does a full reload
  specifically for this one case.

### `Bali::DashboardWidget::Store` methods

| Method | Returns |
|---|---|
| `#widgets` | the offering, subset, reordered and resized by what is stored. No **visible** stored row means "never chose" — the whole offering, in catalog order |
| `#stored_keys` | every stored key, including rows for widgets the owner cannot currently see |
| `#visible_keys` | stored keys ∩ offering keys, in stored order |
| `#customized?` | `visible_keys.any?` — whether there is anything visible to reset |
| `#choose(widgets)` | membership only: survivors keep their stored order, newly chosen widgets append. Re-supplies each survivor's stored size internally, because `arrange` (below) is a full reconcile — without that, every `choose` would silently reset every already-sized card back to its default |
| `#arrange(layout)` | reconciles to exactly `layout`, an ordered `[{ widget:, size: }, …]` where position is the array index — `delete_all` then `insert_all`, **not** an upsert, and an omitted `size` means "no opinion" (the widget renders at the size it was drawn around). A repeated widget key is deduped, keeping the first occurrence, before the insert — `choose`'s own union already guarantees uniqueness, but `arrange` is the lower-level primitive a host's controller can reach directly from params, and `insert_all`'s `ON CONFLICT DO NOTHING` would otherwise silently drop everything after the first without raising |
| `#reset` | drops every row — what "restore defaults" and an emptied grid both mean |

`arrange` rebuilds every row, but `created_at` is not rebuilt with them: it reads the
existing timestamps before deleting and carries each surviving widget's forward, so "when did
you first add this widget?" stays answerable across any number of drags. A widget that was
absent is dated now; one removed and later re-added is dated from its return, because absence
of a row means "off". `updated_at` is always the moment of the write.

Rows never grant visibility, and a row for a widget the owner can no longer see survives
rather than being deleted — so a temporarily revoked role, or a feature flag flipped off
and back on, does not silently erase someone's arrangement.

### Bring your own store

`Bali::DashboardWidget::Store` is the **default** implementation of the contract above, not
a requirement of it — the same seam `Bali::SavedView::Store` offers for saved views. A host
that already persists dashboards elsewhere (an existing table, its own model) can write a
plain object with the same seven methods (`widgets`, `stored_keys`, `visible_keys`,
`customized?`, `choose`, `arrange`, `reset`) and pass it anywhere this guide passes a
`Store` — the grid, the controller, the picker all just call methods on whatever they were
handed. That host never installs `bali_dashboard_widgets` and never runs
`bali:install:migrations:dashboard_widgets`; nothing in Bali requires the table to exist.

### There is no locking, and that turned out fine

`choose` and `arrange` do not lock their scope's rows before writing — an earlier version
did (`SELECT ... FOR UPDATE` inside the transaction), but it bought nothing a plain
`delete_all` doesn't already buy: it cannot lock rows that don't exist yet, so a
first-ever write is unserialized with or without it; it does not prevent a lost update
even when rows already exist, because each request computes its target state from its
own snapshot and the later commit wins wholesale regardless; and on SQLite — what the
dummy app runs — `.lock` emits no `FOR UPDATE` at all, so the guarantee was real only on
PostgreSQL to begin with. It was two extra `SELECT`s per write for a promise the code's
own comments already conceded it couldn't keep, so it was removed rather than kept as
reassurance.

What actually happens on a race: two concurrent writes for the same owner both delete
what's there and insert their own layout; the later commit wins wholesale, no exception,
no conflict, just silence. In practice this bounds the exposure to one owner racing
themselves — two tabs, a retried request — and the grid's own JavaScript already
serializes its writes client-side (a 250ms debounce plus a promise queue). A host that
needs a stronger guarantee should reach for an advisory lock keyed on the scope
(`pg_advisory_xact_lock`), which serializes writers even with zero rows present. Bali
does not ship one: it is PostgreSQL-only, and the engine runs on whatever database the
host has.
