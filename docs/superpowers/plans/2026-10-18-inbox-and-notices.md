# Inbox and notices Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One topbar icon, one lazy popover and one full page with «Te toca» and «Avisos», shipped
as a Bali engine feature and adopted by afal-apps.

**Architecture:** «Te toca» is computed per person from host-registered providers and has no
table. «Avisos» are `Bali::Notice` rows with an email delivery log and an hourly digest. A
per-person cached badge feeds the icon. The host includes two controller concerns: one in its
`ApplicationController` for the badge, and one in its own `InboxesController` for the pages,
whose engine views it can override.

**Tech Stack:** Rails 8.1 engine, ViewComponent 4, Stimulus, tippy.js (the optional peer `Bali::Dropdown` already uses), Turbo Frames and Streams (turbo-rails), ActiveJob, ActionMailer, Minitest, Cypress.

**Spec:** `docs/superpowers/specs/2026-10-18-inbox-and-notices-design.md`.

## Global Constraints

- Everything in the repo is in English, including identifiers, comments and test names. UI copy is
  Spanish only in `config/locales/bali_view.es.yml`.
- Comments carry only a measurement, an invisible constraint, or why the obvious thing is wrong.
- The engine tables have no foreign keys. One migration, `create_bali_notices`, installed with
  `bali:install:migrations:notices`.
- The model is `Bali::Notice` (`Bali::Notification` is a deprecated component's module until 4.0).
- Configuration lives in `lib/bali.rb` as `mattr_accessor`s, each documented like the
  `archivals_*` block. Provider classes are registered by name (String) and constantized on use.
- No new gem dependency. pagy stays out: page with `next_url:` on `Bali::SplitView::List`.
- Compose existing Bali components (Tabs, SplitView, Tag, Link, Button, EmptyState, Icon).
  `IconAction`'s `BUTTON_CLASSES` and `COUNT_CLASSES` are reused, not copied.
- Every new test is red for the right reason first, with a negative control on the line it covers
  (`docs/reference/testing-traps.md`).
- Browser checks run in `afal` and `afal-dark` at 1280 and 375. Cypress runs against
  `http://localhost:3001/lookbook/preview` with `cd test/dummy && bin/dev` up.
- Bali's release is `v3.19.0`. Its PR body opens with `Closes #1512`. afal-apps gets one PR, which
  Federico merges.

## Review Focus

1. **A logged-out page, and the bali-auth engine screens.** `inbox_badge` is nil or undefined
   there. The icon renders nothing and nothing raises. Pinned in Tasks 6 and 7.
2. **A notice whose `action_url` is absolute or protocol-relative** (`https://evil`, `//evil`).
   `open_notice` must not redirect off-site. Pinned in Task 8.
3. **A forged or stale gid in `/inbox/items/:kind/:gid`:** another model's gid, a record that
   was deleted, or an unknown kind. All of them get the same «ya no está» body and never a 500.
   Pinned in Tasks 4 and 8.
4. **Turbo hover prefetch of the open links.** Without `data-turbo-prefetch="false"`, hovering a
   row would mark it read. Pinned in Task 8.
5. **A recipient with no email address.** The host mailer raises, the delivery ends `failed` with
   the reason after its attempts, and the notice itself survives. Pinned in Task 2.

---

### Task 1: Notices — table, model, kinds, `Bali::Notifiable`

**Files:**
- Create: `db/migrate/20261018120000_create_bali_notices.rb`. It creates `bali_notices` and `bali_notice_deliveries`, with the columns and indexes of spec §2.
- Create: `app/models/bali/notice.rb`, `app/models/bali/notice_delivery.rb`, `app/models/bali/notifiable.rb`.
- Modify: `lib/bali.rb`. Add `notice_kinds` (default `{}`), `notices_mailer` (default `nil`), `notices_parent_mailer` (default `"ApplicationMailer"`) and `notices_deliver_if` (default `->(_notice) { true }`), each documented.
- Modify: `test/dummy/db/schema.rb`, by running `cd test/dummy && bin/rails db:migrate`. Never use `db:prepare` (memory: it clobbers `schema.rb`).
- Modify: `test/dummy/config/initializers/bali.rb`. Register the dummy's kinds.
- Test: `test/bali/models/notice_test.rb`, `test/bali/models/notifiable_test.rb`.

**Interfaces:**
- Produces:
  - `Bali::Notice::Kind = Data.define(:name, :email, :queue, :announces)`.
  - `Bali::Notice.kinds → Hash{String => Kind}`. It is built from `Bali.notice_kinds` and raises `ArgumentError` on an `email:` other than nil, `:immediate` or `:digest`.
  - `Bali::Notice.kind(name) → Kind | nil`.
  - `Bali::Notice.announcing_kinds → Array<String>`.
  - Scopes: `unread`, `recent` (`created_at DESC, id DESC`), `listed` (kinds that announce nothing), `addressed_to(recipient)`.
  - `#mark_read!`, `#unread?`.
  - `Bali::Notice.mark_all_read!(recipient) → Integer`.
  - `has_one :delivery`.
  - `Bali::NoticeDelivery`: `STATUSES = %w[pending sending delivered failed skipped]`, `MODES = %w[immediate digest]`, `belongs_to :notice`, scopes `pending`, `digest`.
  - `Bali::Notifiable#notify(recipient:, kind:, message:, actor: nil, action_url: nil, idempotency_key: nil) → Bali::Notice | nil`.
  - The callbacks are hooks for later tasks:
    - `after_create :record_delivery` writes the delivery row in the same transaction, when `kind(…).email` is set and `Bali.notices_deliver_if.call(self)` is truthy;
    - `after_create_commit :announce` calls `Bali::NoticeDeliveryJob` (Task 2) and `Bali::Inbox::Badge.refresh(recipient)` (Task 6), each guarded with `defined?` until its task lands. Task 6 removes the guards.

- [ ] **Step 1: Write the failing tests** in `notice_test.rb`:
  - `test "a notice of an unregistered kind is invalid"`;
  - `test "listed leaves out the kinds that announce"`;
  - `test "an immediate kind writes a pending immediate delivery in the notice's transaction"`: assert `notice.delivery.mode == "immediate"` and `status == "pending"`, and that a raise after `create!` inside the transaction leaves zero deliveries;
  - `test "a digest kind writes a pending digest delivery"`;
  - `test "notices_deliver_if false writes no delivery"`;
  - `test "mark_all_read! reads every unread notice of that recipient only"`.

  And in `notifiable_test.rb`:
  - `test "notify with a blank recipient creates nothing"`;
  - `test "notify with a used idempotency_key returns the existing notice"`: the same id, `Bali::Notice.count` unchanged;
  - `test "destroying the notifiable destroys its notices and their deliveries"`.

  The tests use `Movie` as notifiable and `User` as recipient, through `Movie.include(Bali::Notifiable)` in the dummy model.
- [ ] **Step 2: Run** `bin/rails test test/bali/models/notice_test.rb test/bali/models/notifiable_test.rb`. Expected: errors on the missing constants, then the assertions.
- [ ] **Step 3: Write the migration and the models.** `notify` rescues `ActiveRecord::RecordNotUnique` only when `idempotency_key` is present, and returns `Bali::Notice.find_by!(idempotency_key:)`.
- [ ] **Step 4: Migrate the dummy.** Run `cd test/dummy && bin/rails db:migrate && RAILS_ENV=test bin/rails db:schema:load`, then run the two files and `test/dummy_schema_test.rb`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(notices): tabla bali_notices, Bali::Notice y Bali::Notifiable (#1512)`.

### Task 2: Immediate delivery job

**Files:**
- Create: `app/jobs/bali/application_job.rb` (`< ActiveJob::Base`), `app/jobs/bali/notice_delivery_job.rb`.
- Create: `test/dummy/app/mailers/notice_mailer.rb`, with `notify(notice)` plus text and HTML templates. Set `Bali.notices_mailer = "NoticeMailer"` in the dummy.
- Test: `test/bali/jobs/notice_delivery_job_test.rb`.

**Interfaces:**
- Consumes: `Bali::NoticeDelivery` (Task 1).
- Produces: `Bali::NoticeDeliveryJob.perform_later(delivery)`. It is enqueued on `kind.queue || :default`, `retry_on StandardError, wait: :polynomially_longer, attempts: 5`. On the final failure it marks the row `failed`, with `failure_reason` = `"#{error.class}: #{error.message}".truncate(255)`, and does not re-raise.

- [ ] **Step 1: Write the failing tests:**
  - `test "delivers once and stamps delivered_at"`;
  - `test "a delivered row is not sent again"`;
  - `test "each failure counts an attempt and the fifth leaves it failed with the reason"`: drive it with `perform_enqueued_jobs` and a mailer that raises;
  - `test "a recipient with no email ends failed and the notice survives"`;
  - `test "an immediate kind with queue: :low is enqueued on low"`.
- [ ] **Step 2: Run** `bin/rails test test/bali/jobs/notice_delivery_job_test.rb`. Expected: FAIL.
- [ ] **Step 3: Implement the job.** `Bali.notices_mailer.constantize.notify(notice).deliver_now`. Wire `Bali::Notice#announce` to enqueue it for `immediate` deliveries.
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(notices): entrega inmediata con bitácora y reintentos (#1512)`.

### Task 3: The hourly digest

**Files:**
- Create: `app/jobs/bali/notice_digest_job.rb`.
- Create: `app/mailers/bali/notice_digest_mailer.rb`. It is `class NoticeDigestMailer < Bali.notices_parent_mailer.constantize`.
- Create: `app/views/bali/notice_digest_mailer/digest.html.erb` and `digest.text.erb`.
- Modify: `config/locales/bali_view.en.yml` and `bali_view.es.yml`, under `bali_view.notices.digest`.
- Create: `test/dummy/test/mailers/previews/bali/notice_digest_mailer_preview.rb`, or the dummy's preview path if it has one configured.
- Test: `test/bali/jobs/notice_digest_job_test.rb`, `test/bali/mailers/notice_digest_mailer_test.rb`.

**Interfaces:**
- Produces:
  - `Bali::NoticeDigestJob#perform`, with no arguments. It reclaims `sending` rows older than `STALE_AFTER = 1.hour`.
  - `Bali::NoticeDelivery.claim_digest! → Array<Integer>`: in one transaction, `pending.digest.order(:id).lock("FOR UPDATE SKIP LOCKED").pluck(:id)`, then `update_all(status: "sending")` on those ids. On Postgres a concurrent run skips the rows already claimed. On SQLite, the dummy's adapter, the lock clause is dropped by Arel and writes serialize, so the claim is still exclusive.
  - `Bali::NoticeDigestMailer.digest(recipient, notices)`.
  - `Bali::NoticeDigestMailer::GROUP_MIN = 3`.
  - The mailer reads `main_app.inbox_url(tab: "notices")` and `main_app.root_url`, so the host's routes must name `inbox` (the guide says so).
- Copy (es): spec §4 verbatim. The subject is `"%{count} avisos nuevos en %{app}"`, with `app` defaulting to `Rails.application.class.module_parent_name`. The window line uses `l(…, format: "%A %-d de %B")` with days and months in lower case.

- [ ] **Step 1: Write the failing tests:**
  - `test "two runs claim disjoint rows"`: call `claim_digest!` twice and assert the second gets `[]`;
  - `test "a notice read before the run is skipped and a recipient left with nothing gets no email"`;
  - `test "groups by recipient, one email each"`;
  - `test "a row stuck in sending for over an hour returns to pending"`;
  - `test "a failed send puts the rows back to pending with one more attempt, failed at the fifth"`.

  And in the mailer test:
  - `test "kinds with three or more get their own block and the rest share Otros avisos"`;
  - `test "rows link to the notice's absolute action_url, never an engine path"`: assert no `/inbox/notices/` in the body;
  - `test "lists the first three of a kind and the remainder as y N más en tu bandeja"`.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement** the job, the claim, the mailer and the templates. The HTML follows the «Correo agrupado» board, with inline styles because it is email.
- [ ] **Step 4: Run them.** Expected: PASS. Then open `/rails/mailers` in the dummy to check the preview renders.
- [ ] **Step 5: Commit** `feat(notices): correo agrupado por hora (#1512)`.

### Task 4: Te toca — Provider, Item, Query

**Files:**
- Create: `app/models/bali/inbox/provider.rb`, `app/models/bali/inbox/item.rb`, `app/models/bali/inbox/query.rb`.
- Modify: `lib/bali.rb`. Add `inbox_providers` (default `{}`).
- Create: `test/dummy/app/inbox/` with two providers:
  - `TaskInboxProvider`: kind `:task`, the dummy's `Task.where.not(status: :done)` with `due_date`;
  - `DocumentInboxProvider`: kind `:acknowledgment`, published `Document`s the demo user has not acknowledged.

  Register them under `demo:` and `docs:` in the dummy initializer.
- Test: `test/bali/models/inbox/query_test.rb`.

**Interfaces:**
- Produces:
  - `Bali::Inbox::Provider` (module). Hosts implement `kind`, `pending_for(user)` and `build_item(record, user:)`. Defaults: `icon → "inbox"`, `pending_count_for(user) → pending_for(user).size`, `build_items(records, user:)`, and the helper `item(record, **fields) → Item`.
  - `Bali::Inbox::Item = Data.define(:kind, :record, :title, :subtitle, :href, :due_at, :requested_by, :module_key)`, with optional fields defaulting to nil. Methods:
    - `#gid → record.to_gid_param`;
    - `#band(now = Time.current) → :overdue | :this_week | :later`;
    - `#overdue?`.
  - `Bali::Inbox.providers → Array<[module_key Symbol, provider]>`. It constantizes `Bali.inbox_providers`, and raises `ArgumentError` naming both modules on a duplicate kind, or on an `announces:` (`Bali::Notice.announcing_kinds`) whose kind no provider has.
  - `Bali::Inbox::Query.new(user)` with:
    - `#count`, `#counts_by_kind → Hash{Symbol => Integer}`, `#modules → Array<Symbol>`;
    - `#items(module_key: nil, kind: nil) → Array<Item>`, sorted;
    - `#capped?`;
    - `#find(kind, gid) → Item | nil`.

    `FETCH_CAP = 100`. `BANDS = %i[overdue this_week later]`. `due_at` is compared as a Time; a `Date` is treated at end of day.

- [ ] **Step 1: Write the failing tests:**
  - `test "count sums pending_count_for across providers"`;
  - `test "items sort overdue, this week, later; undated last; then title"`;
  - `test "items(kind:) and items(module_key:) filter"`;
  - `test "a provider over FETCH_CAP is capped and capped? says so"`;
  - `test "find returns the item for a pending record"`;
  - `test "find returns nil for a gid of another model, a resolved record, a deleted record and an unknown kind"`;
  - `test "a duplicate kind raises naming both modules"`;
  - `test "announces naming a kind no provider has raises"`.
- [ ] **Step 2: Run** `bin/rails test test/bali/models/inbox/query_test.rb`. Expected: FAIL.
- [ ] **Step 3: Implement.** `find` parses with `GlobalID.parse(GlobalID::Locator…)`, refuses when `gid.model_name` is not the class of the provider's records (it asks `pending_for(user)`: `klass` on a relation, `first&.class` otherwise), and then uses `pending_for(user).where(id: gid.model_id).first`, or `detect` on an Array. It never calls `GlobalID::Locator.locate`.
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(inbox): providers, Item y Query de lo que te toca (#1512)`.

### Task 5: Folding — the «Nuevo» marks

**Files:**
- Modify: `app/models/bali/inbox/query.rb`.
- Test: `test/bali/models/inbox/folding_test.rb`.

**Interfaces:**
- Produces:
  - `Bali::Inbox::Query#fresh_keys(items) → Set<[String, Integer]>`, the `(notifiable_type, notifiable_id)` pairs of unread announcing notices for this user and these items. It is one query.
  - `#mark_seen!(item) → Integer`, which marks those notices read.

- [ ] **Step 1: Write the failing tests:**
  - `test "fresh_keys marks an item whose record has an unread announcing notice of the same recipient"`;
  - `test "another recipient's notice or a read one does not mark it"`;
  - `test "fresh_keys is one query"` (`assert_queries_count(1)`);
  - `test "mark_seen! reads the announcing notices of that item only"`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** with `Bali::Notice.unread.addressed_to(user).where(kind: Bali::Notice.announcing_kinds).where(notifiable_type:, notifiable_id:)` over the items' records, grouped by type.
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(inbox): aviso fundido en su pendiente con la marca Nuevo (#1512)`.

### Task 6: The badge and `InboxBadge`

**Files:**
- Create: `app/models/bali/inbox/badge.rb`, `lib/bali/concerns/controllers/inbox_badge.rb` (required from `lib/bali.rb`).
- Modify: `app/models/bali/notice.rb`. `announce` calls `Badge.refresh`, and `mark_all_read!` and `mark_read!` call `Badge.expire`.
- Modify: `test/dummy/app/controllers/application_controller.rb`. Include the concern.
- Test: `test/bali/models/inbox/badge_test.rb`, `test/bali/concerns/controllers/inbox_badge_test.rb`.

**Interfaces:**
- Produces:
  - `Bali::Inbox::Badge = Data.define(:pending, :unread)`.
  - `.for(owner) → Badge`: a `Rails.cache.fetch` of `"bali/inbox/badge/#{owner.to_gid_param}"`, `expires_in: TTL` (`TTL = 1.minute`).
  - `.compute(owner)`, `.write(owner, badge)`, `.expire(owner)`.
  - `.refresh(owner)`: expires, then `Turbo::StreamsChannel.broadcast_replace_to([owner, :bali_inbox], target: SIGNAL_ID, html: …)`, with `SIGNAL_ID = "bali-inbox-signal"`. The html is a fresh signal element carrying no count. turbo-rails is a development dependency of Bali, not a runtime one, so the broadcast is skipped unless `defined?(Turbo::StreamsChannel)`.
  - `#unread?`, `#empty?`.
  - `Bali::Concerns::Controllers::InboxBadge`:
    - `helper_method :inbox_badge` (`nil` without `inbox_owner`);
    - private `inbox_owner` (default `try(:current_user)`);
    - `after_action :expire_inbox_badge, unless: -> { request.get? || request.head? }`.

- [ ] **Step 1: Write the failing tests:**
  - `test "a warm cache issues no provider or notice query"`: call `Badge.for` twice under `assert_queries_count(0)` on the second, with `MemoryStore` set for the test;
  - `test "a new notice expires the recipient's badge and broadcasts the signal"` (`assert_broadcasts`);
  - `test "mark_all_read! expires it"`;
  - `test "unread counts listed kinds only"`.

  And in the concern test, which goes through a dummy request:
  - `test "a POST by the owner expires the badge"`;
  - `test "a GET does not"`;
  - `test "inbox_badge is nil without an owner"`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Use `MemoryStore` in the tests (`Rails.cache = ActiveSupport::Cache::MemoryStore.new` in `setup`, restored in `teardown`).
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(inbox): contador en caché por persona, refrescado por avisos y acciones propias (#1512)`.

### Task 7: `Bali::Topbar::Inbox` and its controller

**Files:**
- Create: `app/components/bali/topbar/inbox/component.rb` and `component.html.erb`, `app/components/bali/topbar/inbox/badge/component.rb` (the badge frame's content, also used by the `badge` action), `app/components/bali/topbar/inbox/index.js` and `index.css` (`@layer components`).
- Modify:
  - `app/frontend/bali/components/index.js`: register `'topbar-inbox': TopbarInboxController`;
  - the controller manifest: `yarn check:manifest` must pass;
  - `app/assets/stylesheets/bali/components.css`, if each component sheet is imported there.
- Create: `app/components/bali/topbar/inbox/preview.rb` and previews `default`, `states`, `dark`, with `@label`s. The popover points at a fixture route in the dummy that renders the engine's popover partial.
- Modify: `app/components/bali/topbar/preview.rb`. `six_actions` uses the new icon in place of the inbox and bell pair.
- Modify: `config/locales/bali_view.{en,es}.yml`, under `bali_view.inbox` (labels from spec §7).
- Test: `test/bali/components/topbar_inbox_test.rb`, `cypress/e2e/topbar-inbox.cy.js`, `test/requests/topbar_inbox_previews_test.rb`.

**Interfaces:**
- Consumes: `Bali::Inbox::Badge`.
- Produces:
  - `Bali::Topbar::Inbox::Component.new(badge:, popover_url:, href:, stream: nil, **options)`. `render?` is false when `badge` is nil.
  - The DOM ids: `BADGE_FRAME_ID = "bali-inbox-badge"`, `POPOVER_FRAME_ID = "bali-inbox-popover"`, `PANEL_ID = "bali-inbox-panel"`. Each is a Ruby constant, and the JS reads it from `data-` values, never hard-coded twice.
  - The accessible name comes from the link's content: a `sr-only` span inside the badge frame. The four i18n states are `bali_view.inbox.icon.{empty,pending,unread,pending_and_unread}`.
  - The Stimulus `topbar-inbox` controller:
    - targets `trigger`, `panel`, `frame`, `badge`, `signal`;
    - values `popoverUrl`, `badgeUrl`;
    - `toggle(event)` ignores modified clicks and non-primary buttons;
    - `open()` builds tippy on first use (`appendTo: topLayerHost ?? document.body`, `placement: 'bottom-end'`, `trigger: 'manual'`, `interactive: true`, `zIndex: zIndexFor('dropdown')`, `role: 'presentation'`, `maxWidth: 'none'`). It sets the frame's `src` the first time and calls `reload()` after, then focuses the panel;
    - `close()` returns focus to the trigger;
    - Escape and an outside click close it;
    - `signalTargetConnected()` reloads the badge frame from `badgeUrl`.
- Visuals: counter A from spec §7. The number goes in `IconAction::COUNT_CLASSES` with `Tag` color `:error` size `:xs` and the cap of 99. The dot is `absolute bottom-1 right-1 size-2 rounded-full bg-primary border-2 border-base-100`, set in `index.css`.

- [ ] **Step 1: Write the failing component tests:**
  - `test "no badge renders nothing"`;
  - `test "pending only draws the count and names it"`: the name is «Bandeja: 6 pendientes» in es;
  - `test "unread only draws the primary dot"`;
  - `test "both draw both"`;
  - `test "100 pending reads 99+"`;
  - `test "it is a link to href with aria-haspopup dialog and aria-expanded false"`;
  - `test "stream: renders turbo_stream_from for [owner, :bali_inbox]"`.
- [ ] **Step 2: Run** `bin/rails test test/bali/components/topbar_inbox_test.rb`. Expected: FAIL.
- [ ] **Step 3: Implement** the component, its badge subcomponent, the CSS and the previews.
- [ ] **Step 4: Run.** Expected: PASS. Then run `bundle exec rails app:tailwindcss:build`.
- [ ] **Step 5: Write the Cypress spec** `cypress/e2e/topbar-inbox.cy.js`. Steps 5 and 6 run once Task 8 has landed, because the previews' `popover_url` is the dummy's `/inbox/popover`:
  - `it('sends no popover request before the first click')`, using `cy.intercept` with a counter;
  - `it('opens on click, loads the frame, moves focus inside')`;
  - `it('Escape closes and returns focus to the icon')`;
  - `it('a click outside closes it')`;
  - `it('a second open reloads the frame')`;
  - `it('a cmd-click navigates instead of opening')`: assert the `href` and that no tippy box was created.
- [ ] **Step 6: Implement** `index.js` until the spec passes (`yarn run cy:run --spec cypress/e2e/topbar-inbox.cy.js`). Then run `yarn standard`.
- [ ] **Step 7: Commit** `feat(topbar): Bali::Topbar::Inbox, un solo ícono con popover lazy (#1512)`.

### Task 8: `Bali::Concerns::Controllers::Inbox` — the pages

**Files:**
- Create: `lib/bali/concerns/controllers/inbox.rb`.
- Create the engine views:
  - `app/views/bali/inbox/show.html.erb`;
  - `app/views/bali/inbox/_pending.html.erb` and `_notices.html.erb` (the tabs);
  - `app/views/bali/inbox/_item_detail.html.erb` (the generic detail);
  - `app/views/bali/inbox/_gone.html.erb`;
  - `app/views/bali/inbox/popover.html.erb`, `_popover_pending.html.erb` and `_popover_notices.html.erb`;
  - `app/views/bali/inbox/badge.html.erb`;
  - `app/views/bali/inbox/read_all.turbo_stream.erb`.
- Modify: `config/locales/bali_view.{en,es}.yml`, with the page, popover and gone copy from spec §7–§8.
- Create: `test/dummy/app/controllers/inboxes_controller.rb`. Modify: `test/dummy/config/routes.rb` (spec §8 routes) and `test/dummy/app/views/layouts/_admin_topbar.html.erb` (the bell becomes `Bali::Topbar::Inbox`). Modify: `test/dummy/db/seeds.rb` (notices for `User.demo`, including one announcing).
- Test: `test/requests/inbox_test.rb`.

**Interfaces:**
- Consumes: Tasks 4–7.
- Produces:
  - Actions `show item popover badge open_item open_notice read_all`.
  - `_prefixes` is `super + %w[bali/inbox]`.
  - The per-kind detail is looked up as the partial `inbox/items/_<kind>` (`lookup_context.exists?("inbox/items/#{kind}", [], true)`); otherwise the generic one renders.
  - `PER_PAGE = 20` for both tabs; `POPOVER_LIMIT = 10`.
  - `open_notice` redirects only when `action_url.start_with?("/") && !action_url.start_with?("//")`; otherwise it goes to `url_for(action: :show, tab: "notices")`. Someone else's notice is `ActiveRecord::RecordNotFound` (404).
  - Every open link carries `data: { turbo_prefetch: "false" }`. The popover frame has `target="_top"`.

- [ ] **Step 1: Write the failing request tests:**
  - `test "show renders Te toca with bands, pills and counts"`;
  - `test "show tab=notices lists listed notices newest first, 20 per page"`;
  - `test "item renders the detail and marks its folded notices read"`;
  - `test "a host partial inbox/items/_<kind> replaces the generic detail"`, with a dummy partial for `:task`;
  - `test "the gone body is identical for a resolved item, a gid of another model, an unknown kind and a deleted record"`: compare `response.body` after stripping the CSRF meta;
  - `test "open_item marks read and 303s to href; a stale one shows gone"`;
  - `test "open_notice 303s to a relative action_url"`;
  - `test "open_notice refuses https:// and // and goes to the notices tab"`;
  - `test "open_notice for someone else's notice is 404"`;
  - `test "read_all reads every unread notice of the owner and answers a turbo stream from the popover"`;
  - `test "popover renders at most 10 items and the Nuevo pill on a folded item"`;
  - `test "the popover's tab=notices leaves out announcing kinds"`;
  - `test "open links carry data-turbo-prefetch=false"`;
  - `test "an app/views/inboxes/show.html.erb in the host wins"`, using a second dummy controller with its own template.
- [ ] **Step 2: Run** `bin/rails test test/requests/inbox_test.rb`. Expected: FAIL.
- [ ] **Step 3: Implement** the concern, the views and the dummy wiring.
  - The page uses `Bali::Tabs` with `href:` tabs and `Bali::SplitView` with `with_group` per band and `next_url:` for paging.
  - The popover uses `Bali::Tabs` with panels, and the Avisos panel has `src:`.
  - The gone detail uses `Bali::EmptyState`.
- [ ] **Step 4: Run.** Expected: PASS. Then run `bin/rails test` (the full suite) and `yarn run cy:run --spec "cypress/e2e/topbar-inbox.cy.js,cypress/e2e/split-view*.cy.js"`.
- [ ] **Step 5: Commit** `feat(inbox): concern de la página, popover, detalle y «ya no está» (#1512)`.

### Task 9: Documentation, CHANGELOG, browser, review, release

**Files:**
- Modify: `docs/guides/engine-models.md`. Add a section «Inbox and notices (`bali_notices`)», covering:
  - install;
  - kinds;
  - `notify`;
  - providers;
  - folding and its risk;
  - the two concerns and the routes;
  - the topbar;
  - the digest schedule (`config/recurring.yml`);
  - «Porting from afal-apps».
- Modify: `docs/guides/engines.md`. Add the `Bali.inbox_providers`, `Bali.notice_kinds` and `Bali.notices_*` entries.
- Modify: `docs/guides/components.md`. Add `Topbar::Inbox`.
- Modify: `CHANGELOG.md`. Add `[Unreleased]` → «Added», in Spanish: what changed, who it affects, what to do.
- Modify, at release: `lib/bali/version.rb` and `package.json` to `3.19.0`, and CHANGELOG `[v3.19.0] - <date>`.

- [ ] **Step 1: Write the docs.** Run every example as written in the dummy, and check every claim against the code.
- [ ] **Step 2: Browser.** Run `cd test/dummy && bin/dev`, then use Playwright on `/admin`:
  - the icon in each counter state;
  - the popover open, loading, empty, and on «Avisos»;
  - the page on both tabs;
  - «ya no está»;
  - the digest preview.

  Each one in `afal` and `afal-dark`, at 1280 and 375, with screenshots kept in the scratchpad.
- [ ] **Step 3: Review.** Run `dhh-code-reviewer` on a worktree with `branch.diff` in a file (memory: the reviewer has no shell). Open the prompt with the scope (read-only, this worktree, this diff), and give it steps 1–6 of «Resolving an issue». Apply what holds, and re-review until it is rails-worthy.
- [ ] **Step 4: Open the PR** (body `Closes #1512`, review summary). Check CI's check-runs, merge by REST, then release `v3.19.0`: a version bump PR or the bump in this PR, with the tag and GitHub Release on the merge commit (memory: release by tag and GitHub Release only).

### Task 10: afal-apps — the bump, the data and Avisos

Work in a worktree of afal-apps on `origin/main`, using its own Postgres (memory: «Suites de las apps host en la Beelink»).

**Files:**
- Modify: `Gemfile`/`Gemfile.lock` (bali `v3.19.0`), `package.json`/`yarn.lock` if the JS package is pinned there.
- Create: the installed `db/migrate/*_create_bali_notices.bali.rb` and `db/migrate/*_copy_notifications_into_bali_notices.rb` (deploy 1 of spec §10: same ids, sequence moved to `max + 1_000_000`).
- Create: `config/initializers/bali_inbox.rb`, with `Bali.notice_kinds` for the 29 kinds, `Bali.notices_mailer = "NotificationMailer"` and `Bali.notices_deliver_if = ->(_n) { !SmartsuiteImport.importing? }`.
- Modify: the 17 `include Notifiable` models (to `Bali::Notifiable`), and every reader the spec lists in §10.
- Modify: `app/models/notification.rb`, reduced to the bare class for queued jobs.
- Modify: `app/mailers/notification_mailer.rb`.
- Delete: `app/models/concerns/notifiable.rb`.
- Test: its notification tests adapted, plus `test/migrations/copy_notifications_into_bali_notices_test.rb`.

- [ ] **Step 1:** Run the existing notification and mailer tests. They are red on the missing `Bali::Notice` once the models switch over.
- [ ] **Step 2:** Bump Bali, install the migration, write the copy migration and its test: ids, read state and polymorphic types; a row written after the copy is still copyable; the sequence lands past the gap.
- [ ] **Step 3:** Switch the models and readers. Run `git grep -n "Notification\b" -- app lib config` until only the bare class and the mailer remain.
- [ ] **Step 4:** Run the full suite. Commit `feat: avisos sobre el engine de Bali (#1512)`.

### Task 11: afal-apps — Te toca, the page and the topbar

**Files:**
- Modify: `app/models/td_flow/inbox.rb`. It is split into one file per provider under `app/models/td_flow/inbox/`, each `include Bali::Inbox::Provider`, returning records, with the `tdflow.access/manage/executive` early-out.
- Create: `app/models/td_flow/inbox/interviews_provider.rb`.
- Create: `app/controllers/inboxes_controller.rb` (`include Bali::Concerns::Controllers::Inbox`). Modify `ApplicationController`: include `InboxBadge` and remove `Current.unread_notifications_count`.
- Modify: `config/routes.rb`. Add the spec §8 routes, plus the redirects `/notifications → /inbox?tab=notices` and `/td_flow/inbox → /inbox?module=td_flow`.
- Modify: `app/views/layouts/_topbar.html.erb`. Replace the bell with `Bali::Topbar::Inbox` under the same condition, using `main_app.` URLs and `try(:inbox_badge)`.
- Modify: `app/views/td_flow/shared/_inbox_widget.html.erb`, which reads `Bali::Inbox::Query` filtered to `td_flow`.
- Delete:
  - `NotificationsController`, `Notifications::ReadsController`, `Notifications::ReadAllsController` and their views;
  - `notifications/_bell`;
  - `TDFlow::InboxesController` and its views, and `TDFlow::InboxPolicy` once nothing reads it;
  - `TARGET_STATE_KINDS`, `target_resolved?` and the «Mis pendientes» filter;
  - `Current.unread_notifications_count`.
- Modify: `config/locales/es.yml`, adding `bali_view.inbox.kinds.*`, `bali_view.inbox.modules.td_flow` and `bali_view.notices.digest.kinds.scholarship_request_submitted`.
- Test: `test/models/td_flow/inbox/interviews_provider_test.rb`, the provider tests adapted, `test/integration/inbox_test.rb`.

- [ ] **Step 1: Write the interview provider's tests.** They cover spec §10's matrix:
  - leader;
  - co-leader;
  - mapped participant;
  - an invitation sent again;
  - an interview started before invitations existed;
  - a closed interview;
  - a paused initiative;
  - someone without a TDFlow role sees it.

  Add `test "count agrees with pending_for"` for each of the six providers, and one folding test per announcing kind.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** the providers, the registration, the controller, the routes, the topbar, the widget and the deletions.
- [ ] **Step 4:** Run the full suite and `bin/rubocop`.
- [ ] **Step 5: Browser**, on afal-apps' development database (memory: «afal-apps en la Beelink»):
  - a TD user and a user with no TDFlow role who has an interview;
  - the icon, popover, page, «ya no está» and redirects;
  - `afal` and `afal-dark` at 1280 and 375.

  Then measure the query count and time of a page with a warm and with a cold badge, against `main`.
- [ ] **Step 6: Review.** Run DHH review on the worktree and apply what holds. Then push and open the PR (body `Closes`-free: `Part of Grupo-AFAL/bali-view-components#1512`), with the review summary and the measurement. Do not merge.
