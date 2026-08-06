# Engines: host integration for Bali's controllers

Bali is a Rails engine with `isolate_namespace`. Besides components, it ships real
controllers — today `Bali::SavedViewsController` (saved views storage) and
`Bali::BlockEditorUploadsController` (editor uploads), with more arriving as the
documents engine grows. This guide explains why your app's authentication does not
reach those controllers on its own, and the one supported way to teach it to them:
`Bali.engine_controller_concerns`.

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
| `Bali.block_editor_commentables` | what may carry comment threads | `{}` — everything 404s |
| `Bali.block_editor_comments_user` | who authors a comment | `->(controller) { controller.try(:current_user)&.id&.to_s }` |
| `Bali.block_editor_comments_authorize` | reaching the comments at all | user id present, else 403 |

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

## Block Editor comments (#706)

The engine ships the storage behind the editor's inline comments: three tables, three
controllers, and the nine endpoints `RESTThreadStore` calls. Adopting it is a
migration, three lines of configuration, and one keyword in the view.

### 1. Install the tables

```bash
bin/rails bali:install:migrations
bin/rails db:migrate
```

That copies `CreateBaliBlockEditorComments`, which creates
`bali_block_editor_threads`, `bali_block_editor_comments` and
`bali_block_editor_reactions`.

### 2. Configure the three lambdas

```ruby
# config/initializers/bali.rb
Bali.config do |config|
  # What may carry comment threads. The KEY is what lands in `commentable_type`,
  # i.e. `Document.polymorphic_name`. The value is the model — as a String, a class,
  # or a lambda that receives the id and returns the record (or nil).
  config.block_editor_commentables = { "Document" => "Document" }

  # Who is writing. Returns a STRING id; the editor resolves the display name on the
  # client from `comments[:users]` / `comments[:users_url]`.
  config.block_editor_comments_user = ->(controller) { controller.current_user&.id&.to_s }

  # Whether this request may reach the comments of this record at all.
  config.block_editor_comments_authorize = lambda do |_controller, user_id, commentable|
    user_id.present? && commentable.readable_by?(user_id)
  end
end
```

Prefer the **String** form over the class in the whitelist: an initializer that holds
the class object holds the copy Zeitwerk discards on the next reload, and comments
start 404ing in development after the first edit.

The default whitelist is `{}`, so mounting the engine grants nothing. Both the missing
type and the missing record answer `404` — telling them apart would turn the whitelist
into a directory of what you store.

### 3. Point the editor at it

```erb
<%= render Bali::BlockEditor::Component.new(
  initial_content: @document.content,
  comments: { url: :auto, commentable: @document,
              user: { id: current_user.id.to_s, username: current_user.name },
              users_url: users_path }
) %>
```

`url: :auto` resolves `bali.block_editor_threads_path(commentable_type:,
commentable_id:)` for that record. The commentable travels in the base URL's query
string and `RESTThreadStore._buildUrl` keeps it on all nine endpoints, so nothing else
has to carry it. Passing `:auto` without a `commentable:` raises — an editor pointed at
an unscoped thread list is not a thing this engine offers.

You can still pass an explicit `url:` and implement the contract yourself; `:auto` is
only a shortcut to the engine's own endpoints.

### What the engine decides, and what it leaves to you

Permissions replay BlockNote's client-side `DefaultThreadStoreAuth` on the server,
because that matrix is what the UI already promises — and the client-side copy stops
nothing:

| Action | Who |
|---|---|
| list threads, open a thread, add a comment, resolve/unresolve, react | anyone the authorize lambda admits |
| edit or delete a comment | its author, and nobody else (`403`) |
| delete a thread | the author of its **first** comment (`403` for anyone else) |

Deleting a comment is soft: the body becomes `null`, `deleted_at` is stamped, and the
editor renders a tombstone. Deleting the last live comment of a thread takes the thread
with it.

Two things the engine deliberately does **not** do:

- **No user directory endpoint.** Who exists and what they are called is the host's
  business — `comments[:users]` and `comments[:users_url]` already cover it, and it is
  the same doctrine as the injected audience elsewhere in the engine.
- **No trust in `X-User-Id`.** `RESTThreadStore` sends that header, and the engine
  ignores it. Identity comes from `Bali.block_editor_comments_user` and nowhere else.

### Migrating an app that already had its own tables

Apps that ran the reference implementation before this shipped
(`block_editor_threads` / `block_editor_comments` / `block_editor_reactions` with the
same columns — this is the case for gobierno-corporativo) do not need to copy any data.
Every column keeps the name it had, so a rename is enough:

```ruby
class MoveBlockEditorCommentsIntoBali < ActiveRecord::Migration[8.0]
  def change
    rename_table :block_editor_threads,   :bali_block_editor_threads
    rename_table :block_editor_comments,  :bali_block_editor_comments
    rename_table :block_editor_reactions, :bali_block_editor_reactions
  end
end
```

Then delete the app's own `BlockEditorThread` / `BlockEditorComment` /
`BlockEditorReaction` models, its threads/comments/reactions controllers and their
routes, and replace the view's `comments: { url: ... }` with `url: :auto, commentable:`.

Three details the rename does not cover:

- **`commentable` is `null: false` in the engine.** If your `commentable_type` /
  `commentable_id` were nullable — the reference implementation left them so — backfill
  the orphans (or delete them; a thread that belongs to nothing was never reachable
  from a document) and add the `NOT NULL` in the same migration.
- **A hand-named index keeps its old name.** `rename_table` renames indexes Rails named
  itself, not one you named explicitly, so the reactions uniqueness index stays
  `idx_reactions_comment_user_emoji` instead of `idx_bali_reactions_comment_user_emoji`.
  Cosmetic — it constrains the same three columns — but a schema diff will show it.
- **Do not reach for `self.table_name`** on the engine's models to keep the old names.
  It would leave every other host carrying a knob nobody else needs, and the next engine
  migration would target a table name that no longer matches.

## Testing with an injected concern

In the engine's own suite, `test/requests/engine_controller_concerns_test.rb` shows the
pattern: assign the array in `setup`, run `Rails.application.reloader.prepare!` to
trigger the include (tests don't reload code, so `to_prepare` won't fire on its own),
and restore the original array in `teardown`. Remember Ruby cannot un-include a module —
neutralize the concern's state instead of expecting it to disappear.
