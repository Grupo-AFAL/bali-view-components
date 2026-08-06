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

## Testing with an injected concern

In the engine's own suite, `test/requests/engine_controller_concerns_test.rb` shows the
pattern: assign the array in `setup`, run `Rails.application.reloader.prepare!` to
trigger the include (tests don't reload code, so `to_prepare` won't fire on its own),
and restore the original array in `teardown`. Remember Ruby cannot un-include a module —
neutralize the concern's state instead of expecting it to disappear.
