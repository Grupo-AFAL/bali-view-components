# Engine models: the tables Bali ships

Bali is mostly view components, but a few features need somewhere to *put* things. For
those, the engine ships the model layer itself — a table, an Active Record model, and a
concern or plain object your own models opt into — instead of asking every app to
reinvent the same schema.

This page is the adoption guide for all of them. For how your authentication reaches the
engine's **controllers**, see [Engines](engines.md); this page is about the **models**.

## The shape they all share

Every engine model follows the same four steps, so learning one teaches you the rest:

1. **Install the migrations.** They ship with the gem and are copied into your app:

   ```bash
   bin/rails bali:install:migrations
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
