# Engines: host integration for Bali's controllers

Bali is a Rails engine with `isolate_namespace`. Besides components, it ships real
controllers — today `Bali::SavedViewsController` (saved views storage) and
`Bali::BlockEditorUploadsController` (editor uploads), with more arriving as the
documents engine grows. This guide explains why your app's authentication does not
reach those controllers on its own, and the one supported way to teach it to them:
`Bali.engine_controller_concerns`.

For the **tables** the engine ships and how one of your models opts into them, see
[Engine models](engine-models.md).

## Why your `ApplicationController` hooks don't apply

`Bali::ApplicationController` inherits from `ActionController::Base`, **not** from your
app's `ApplicationController`:

```ruby
module Bali
  class ApplicationController < ActionController::Base
  end
end
```

That is what `isolate_namespace` engines do, and it is deliberate — the engine cannot
know what your base controller requires. The consequences, all of them by design:

- Your `before_action`s (authentication, tenant scoping, locale) never run for engine
  requests.
- `current_user`, `Current.user`, session helpers — none of them exist inside an engine
  controller. `controller.try(:current_user)` returns `nil`.
- Your rescue handlers and layout don't apply either.

Before this extension point existed, every host worked around it with the same
monkey-patch: re-open the engine controller from a `config.to_prepare` initializer and
`include` the auth concern by hand, once per controller, once per app. With the engine
growing more controllers, that multiplies — hence `Bali.engine_controller_concerns`.

## The real gate: the `Bali.*_authorize` lambdas

Injecting a concern is about **identity** (teaching the engine who the user is), not
about **access**. Access is decided by the engine's own configurable lambdas, which run
inside each controller and respond `403 Forbidden` on their own:

| Config | Guards | Default |
|---|---|---|
| `Bali.saved_views_owner` | who owns a saved view | `->(controller) { controller.try(:current_user) }` |
| `Bali.saved_views_authorize` | saved views mutations | owner present, else 403 |
| `Bali.block_editor_upload_authorize` | editor uploads | unset — uploads allowed; configure it |
| `Bali.entity_references_authorize` | entity reference search and resolution | **denies** — mounting the engine publishes nothing until you open it |
| `Bali.content_versionables` | which models expose a history at all | `{}` — every `record_type` is a 404 |
| `Bali.content_versions_authorize` | reading and restoring versions | falsy — 403 |

New engine controllers follow the same doctrine: a whitelist plus an authorize lambda
is the defense, and it works even for a request that carries no session at all. The
injected concern only makes the defaults useful — `try(:current_user)` starts returning
someone.

## `Bali.engine_controller_concerns`

An array of modules. Every module is included into `Bali::ApplicationController` — and
therefore into every engine controller at once — during `to_prepare`, so it survives
code reloads in development and runs before eager loading in production. The include is
idempotent: a module already in the ancestors is skipped, so a plain module's
`included` hook fires once per loaded class, not once per reload.

```ruby
# config/initializers/bali.rb
Bali.engine_controller_concerns = [MySessionConcern]
```

Timing: the assignment just stores the array. The include happens on the next
`to_prepare` pass — at boot that is *after* initializers run, so don't expect the
module in `Bali::ApplicationController.ancestors` from inside the initializer itself.

### Keep the concern passive

**Never inject a concern whose `before_action`s stay active.** An `authenticate_user!`
that redirects to login would shadow the engine's own `403`s — the browser lands on
your sign-in page instead of surfacing the real answer, and some auth concerns render
views the engine does not have in its view path (a `500`). Teach identity, then disable
the concern's own gate, and let the engine's lambdas decide.

### The bali-auth recipe

With [bali-auth](https://github.com/Grupo-AFAL/bali-auth), the wrapper is five lines:
include the same `Authentication` concern the host already uses (cookie, session token,
impersonation — zero duplication), then `allow_unauthenticated_access` to switch off
its `before_action`s:

```ruby
# config/initializers/bali.rb
module EngineAuthentication
  extend ActiveSupport::Concern

  included do
    include BaliAuth::Authentication
    allow_unauthenticated_access
  end
end

Bali.engine_controller_concerns = [EngineAuthentication]
```

Why `allow_unauthenticated_access` is not optional here: `authenticate_user!` would
redirect to login (shadowing the engine's 403), and `check_role_access` renders a
BaliAuth view the engine's view path does not include (500). The tradeoff — an expired
cookie can still, say, save a personal view until the next host page expires it — is
accepted: the engine's authorize lambdas remain the gate.

A packaged `BaliAuth::EngineAuthentication` concern with exactly this shape is planned
on the bali-auth side (refs #710); once it ships, the initializer collapses to the
single assignment line.

### Hosts without bali-auth

Any way of resolving the user works, as long as it is passive. For a hand-rolled
session:

```ruby
module EngineAuthentication
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
end

Bali.engine_controller_concerns = [EngineAuthentication]
```

(A Devise host usually needs nothing here: Devise registers its helpers on
`ActionController::Base` through `on_load(:action_controller)`, which the engine's
controllers inherit from.)

Or skip the concern entirely and configure the lambdas directly — they receive the
controller, so anything reachable from the request works:

```ruby
Bali.saved_views_owner = ->(controller) {
  User.find_by(id: controller.session[:user_id])
}
```

## Entity references: one declaration per type

The BlockEditor's `#` menu lets an author embed a reference to any record of your app,
and the chip re-resolves its name and URL every time the document loads. Two things make
that work: `Bali::EntityReferencesController` (search and resolution) and
`Bali::EntityReferenceable` (materializing the references embedded in the content into
the `bali_entity_references` table, so you can ask "who mentions this record?" without
scanning JSON).

Both read the same registry. Declaring a type once is what powers search, resolution and
the editor's own display config — before this registry those were three parallel
declarations that drifted.

### 1. Install the table

```bash
bin/rails bali:install:migrations
bin/rails db:migrate
```

### 2. Declare your referenceable types

```ruby
# config/initializers/bali.rb
routes = Rails.application.routes.url_helpers

Bali.entity_reference_types = {
  "Document" => {
    search_scope:  -> { Document.published },
    lookup_scope:  -> { Document.all },
    search_fields: %i[title document_number],
    display_field: :title,
    url:           ->(doc) { routes.document_path(doc) },
    unreachable?:  ->(doc) { doc.nil? || doc.archived? },
    extra_payload: ->(doc) { { entityCode: doc.number } },
    permission_scope: ->(controller, scope) { Pundit.policy_scope!(controller.current_user, scope) },
    display:       { icon: "▧", label: "Document", color: "success" }
  }
}

Bali.entity_references_authorize = ->(controller) { controller.current_user.present? }
```

| Key | Required | What it does |
|---|---|---|
| `search_scope` | yes | What the `#` autocomplete offers. Filter out what an author should not be able to link. |
| `lookup_scope` | yes | What resolution looks in. Deliberately **wider** than `search_scope`: it must include archived and deactivated records, or an existing reference silently loses its name instead of rendering broken. |
| `search_fields` | yes | Columns matched with `LIKE` (already escaped and parameterized). |
| `display_field` | yes | The attribute read for `entityName`. |
| `url` | no | `->(record) { … }` returning the href of the chip. |
| `unreachable?` | no | `->(record) { … }` deciding `broken`. Defaults to "the record is gone". |
| `extra_payload` | no | `->(record) { … }` returning extra keys for the chip. |
| `permission_scope` | no | `->(controller, scope) { scope }` — your own gating, no Pundit coupling. |
| `display` | no | `{icon:, label:, color:}` for the chip. |

The **key is both** the `entityType` that travels to the browser **and** the
`referenceable_type` stored in the table, so it is the model's class name.

`bali_entity_references.referenceable_id` is a bigint, so referenceable models need integer
primary keys. A reference to a record whose id isn't numeric is dropped when the content is
saved rather than stored as a truncated integer.

### 3. Mark the models whose content carries references

```ruby
class Document < ApplicationRecord
  include Bali::EntityReferenceable
  references_entities_in :body # optional; defaults to :content
end
```

Saving re-materializes the references with a **minimal diff**: rows that are still there
keep their ids, so the editor's autosave does not churn the table. `document.entity_references`
walks forward, `record.incoming_references` and `Document.referencing(record)` walk back.

### 4. Point the editor at the engine endpoints

```erb
<%= render Bali::BlockEditor::Component.new(
      references_url: bali.entity_references_path,
      references_resolve_url: bali.resolve_entity_references_path
    ) %>
```

`references_config:` is no longer needed: without it the component serializes the
registry's `display:` entries. Pass it only to make one editor render a type differently
from the rest.

### What the browser receives

Every payload carries exactly these five keys, and they cannot be overridden:

```json
{ "entityType": "Document", "entityId": "42", "entityName": "Onboarding Guide",
  "url": "/documents/42", "broken": false }
```

`extra_payload` adds keys **on top** of them — and those extra keys are yours, not
Bali's: the engine passes them through untouched and never reads them, so their names and
meaning are your contract with your own front end. A key that collides with the five above
is dropped, so an `extra_payload` can never turn a broken reference into a reachable one.

A reference whose record is gone, whose type is not registered, or which falls outside
`permission_scope` resolves to the same shape with `entityName` and `url` null and
`broken: true` — the chip renders broken instead of disappearing from the text, and a
record the viewer may not see never discloses its name.

### Security notes

- The default `entity_references_authorize` **denies**. Until you set it, both endpoints
  answer `403` — mounting the engine does not publish a search over your records.
- `permission_scope` runs on **both** search and resolution.
- Search is capped at 10 results overall and 5 per type, ignores queries shorter than two
  characters, and escapes the query with `sanitize_sql_like`, so `%` matches a literal
  percent sign. Resolution accepts at most 500 refs per request.
- **`reference_text` is the one column outside `permission_scope`.** It stores the name the
  editor had for the entity when the content was saved — client-supplied, never re-checked
  against the record, capped at 255 characters. It exists so a "referenced by" panel can
  list references without resolving every type, but treat it as untrusted user input:
  never mark it `html_safe`, and read the name from the record itself when the viewer's
  permissions matter.
- A record materializes at most 500 references, and references whose id doesn't fit a
  bigint are dropped. Both caps live in the `after_save`, which runs inside the host's own
  `update!` — without them a crafted document makes the record unsaveable.

### Performance

`search_fields` are matched with a leading-wildcard `LIKE`, which no btree index can serve.
At any real table size give those columns a trigram index on PostgreSQL:

```ruby
enable_extension "pg_trgm"
add_index :documents, :title, using: :gin, opclass: :gin_trgm_ops
```

The editor queries once per keystroke, so the number of registered types multiplies every
search. Ordering the registry by how often a type is actually referenced helps: the search
stops as soon as it has ten results.
## Content versions (#707)

`bali_content_versions` is a generic history table: one polymorphic `record`, so a
document, a policy and a note share it without Bali knowing any of those models. It
backs `Bali::ContentVersionsController`, which serves the three endpoints the
`DocumentEditor` history panel calls — list, preview one version, restore one.

Install the table once (it ships with the engine's migrations):

```bash
bin/rails bali:install:migrations
bin/rails db:migrate
```

### Teaching a model to keep history

```ruby
class Document < ApplicationRecord
  include Bali::ContentVersionable
  content_versionable attribute: :content, coalesce_window: 5.minutes
end
```

The macro is optional — including the module already applies those defaults. The
coalescing window is a property of the **model**, not of the app: how long one editing
session lasts depends on what is being edited.

You get:

| Method | What it does |
|---|---|
| `create_version!(author_name:, author: nil, summary: nil, metadata: nil)` | Snapshots the versioned attribute as the next version |
| `create_or_coalesce_version!(...)` | Same, but **updates** the last version instead when the same author saved inside the window |
| `content_at_version(number)` | The content that version holds, or `nil` |
| `restore_content_version!(version, author_name:, author: nil, summary: nil)` | Puts the content back and records a version naming where it came from |
| `content_versions`, `current_content_version_number` | The history itself |

`author` is a polymorphic **optional** association and `author_name` a required string.
A host with no user model passes only the name and loses nothing: the JSON the editor
consumes serves `author_name`. When an author record is present, coalescing compares by
`(author_type, author_id)`, so two people with the same name never collapse into one
version.

> **If you rely on the `author_name` fallback, the history is not tamper-evident.** With no
> author record, coalescing can only compare the displayed name, so two people whose names
> render identically are treated as the same author and their edits collapse into one
> version inside the window — the second person's changes end up recorded under the first
> person's signature. That is fine for a changelog and **not** fine as evidence. If the
> history has to hold up to scrutiny, pass `author:`.

**Schema limitation:** `record_id` and `author_id` are `bigint`, so an app whose primary
keys are UUIDs cannot use this table as shipped. Copy the migration and change the column
types before `db:migrate`; nothing in the model or the controller assumes integers.

**Creating versions stays with the host.** The editor's auto-save PATCHes *your* URL, so
your `update` action is where `create_or_coalesce_version!` belongs. The engine only
reads the history and restores it.

Call either method **after** the record is saved. Both take a row lock so two concurrent
saves cannot claim the same `version_number`, and Rails refuses to lock a record with
unsaved attributes — so versioning mid-edit raises rather than recording a snapshot the
database never held.

```ruby
def update
  if @document.update(document_params)
    @document.create_or_coalesce_version!(author: current_user, author_name: current_user.name)
    # ...
  end
end
```

### Exposing the history over HTTP

Two layers, both default-deny:

```ruby
# config/initializers/bali.rb
Bali.content_versionables = {
  'Document' => ->(controller, id) { controller.current_user.documents.find_by(id: id) }
}

Bali.content_versions_authorize = lambda do |controller, record, action|
  action == 'restore' ? record.editable_by?(controller.current_user) : true
end

Bali.content_versions_author = ->(controller) { [controller.current_user, controller.current_user.name] }
```

`content_versionables` is a whitelist of `record_type` → resolver. It is empty by
default, so **every** `record_type` answers 404 until you name one. Without it,
`record_type` would be a `constantize` over user input — any model in your app readable
over HTTP. Scope inside the resolver: returning only what this user may see makes
someone else's document a 404 rather than a 403 that confirms it exists.

`content_versions_authorize` receives the action (`"index"`, `"show"`, `"restore"`), so
reading and restoring can be gated separately. It returns falsy by default → 403.

`content_versions_author` names who signs the version the **restore** creates.

### Wiring the editor

```erb
<%= render Bali::DocumentEditor::Component.new(
      title: @document.title,
      initial_content: @document.content,
      document_url: document_path(@document),
      versions_url: :auto,
      restore_version_url: :auto,
      record: @document
    ) %>
```

`:auto` resolves to the mounted engine's endpoints. It needs `record:` because those
routes are not nested under yours — the record travels in the query string. Pass no
record and the history panel simply does not render, rather than rendering one whose
every request 404s. Both URLs still accept a plain string, so a host that serves
versions itself keeps working untouched.

### Migrating an existing history table

If you already have your own `document_versions` (or similar), **you do not have to
migrate**. The `versions_url` contract is JSON, and a host can keep serving it. That is
the recommended path for gobierno-corporativo in particular: **do not migrate
`document_versions` yet** — its rows are pinned by sealed-revision references and
change-log foreign keys, which this generic table does not model.

Adopt the engine's table when the history is plain content history. The dummy app's own
`Document` is the worked example: it had exactly this pair of methods (without the row
lock, which was the bug) and now includes the concern instead.
## Testing with an injected concern

In the engine's own suite, `test/requests/engine_controller_concerns_test.rb` shows the
pattern: assign the array in `setup`, run `Rails.application.reloader.prepare!` to
trigger the include (tests don't reload code, so `to_prepare` won't fire on its own),
and restore the original array in `teardown`. Remember Ruby cannot un-include a module —
neutralize the concern's state instead of expecting it to disappear.
