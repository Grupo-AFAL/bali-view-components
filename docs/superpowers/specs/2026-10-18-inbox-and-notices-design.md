# Inbox and notices: one tray and one icon for every app — Design

Date: 2026-10-18
Status: Design approved in brainstorming — 2026-10-18; written spec pending review
Issue: #1512
Canvas: https://claude.ai/artifact/BgyR6ZerRQ7Yea1eZ6Sg9i (private) — the boards named below
Pilot: afal-apps. gobierno-corporativo (GC) adopts in a later round.

## Purpose

Every app grew its own pair: an inbox of what you have to do and a bell of what happened. The two
overlap — an approval assigned to you is an item in the inbox and an unread notice in the bell —
so people check two icons and find the same thing twice. Each copy also has gaps of its own:
afal-apps' inbox lives inside TDFlow behind `tdflow.access`, so the person invited to a discovery
interview, who often has no TDFlow role, never sees the invitation there. That is the case that
opened #1512.

The engine gives every app one icon in the topbar, one popover that opens over the current page,
and one full page. Each has two tabs: «Te toca», what is waiting on you, read live from the
models; and «Avisos», what happened, stored when it happened. A notice about something that is
also waiting on you folds into that item instead of appearing twice.

## Decisions

Federico's, from the brainstorming session on 2026-10-18:

| Question | Decision |
|---|---|
| Scope | Inbox and notices together, in one delivery |
| Topbar | One icon replaces the inbox and the bell |
| Opening it | A large popover over the current page, loaded when it opens; from there, the full page |
| A notifications page | None of its own: the full page has an «Avisos» tab |
| Counter | Option A: a number for what is waiting on you, plus a dot when there are unread notices |
| A notice and an item about the same record | They fold into the item, which carries a «Nuevo» mark while the notice is unread |
| Email | A delivery log: pending, delivered or failed, with its attempts |
| Grouped email | In v1. Each kind declares `email: :digest`, and an hourly job groups by recipient. This is the pattern of GC's `GlossaryTerm::ApprovalDigest`. The reminder for items waiting several days comes when GC adopts |
| Counter freshness | Up to one minute stale; the person's own actions and new notices refresh it at once |
| Controller | A concern the host includes in its own controller, with engine views the host can override (the dashboard widgets pattern) |
| Pilot | afal-apps, with a new interview provider. GC is not in this round |
| Where it lives | This repo. The inbox has no table. Notices get a new polymorphic table, migrated from afal-apps' `notifications` in two deploys. A notice's text is stored when it is created |
| A folded notice once its item is resolved | It does not come back into the «Avisos» history |
| Grouped email in the pilot | Only `scholarship_request_submitted` |

Defaults he accepted without changing them:
- GC's provider contract, with explicit registration;
- the item key is kind + GlobalID;
- a generic detail, with a host partial per kind that replaces it;
- a «ya no está en tus pendientes» detail that does not say whether the item was resolved or was never yours;
- no team view in v1;
- GC's `inline_actions` is not carried over.

## Premises of #1512 that did not hold

Measured against `origin/main` of both apps on 2026-10-18:

- GC's «ya resuelto» page is unreachable. Only `inbox/items/_row` links to it, and no view renders
  that partial. The «ya no está» detail here is new, not a port.
- GC has no inbox widget.
- GC's `idempotency_key` is written by five workflow hooks, not one.
- GC runs three notice systems:
  - the bell;
  - an email engine for Órganos de Gobierno only (`notification_deliveries`);
  - loose mailers.

  The delivery log in this spec is therefore new for the bell. The Órganos de Gobierno engine,
  and the open-agreements and MDM digests, stay in GC.
- afal-apps has 29 notice kinds (17, plus 12 from Becas), not 17.
- The person invited to an interview may have no TDFlow role, so only an inbox that spans the
  whole app fixes the triggering case.

## 1. Two halves, and the one rule between them

- **Te toca (the inbox)** has no table. The host registers providers. Each one answers, for one
  person, what is waiting on them, from the live state of its own models. An item leaves the
  inbox when the thing is resolved; nothing marks it done.
- **Avisos (notices)** are rows in `bali_notices`. Each is written when something happens, with
  its text, and is either read or unread.
- The inbox never reads `bali_notices` to decide what is pending, and a notice never decides
  whether something is still pending. The one point of contact is folding (section 5), and
  folding only decides where an unread notice is *shown*.

## 2. Data

One migration, `create_bali_notices`, holds both tables. It is installed with
`bin/rails bali:install:migrations:notices`; the task name derives from the file name
(`lib/bali/engine_migrations.rb`). Like every engine table, neither table has a foreign key.

### `bali_notices`

| Column | Type | Notes |
|---|---|---|
| `recipient_type`, `recipient_id` | polymorphic, not null | Who it is for |
| `actor_type`, `actor_id` | polymorphic, nullable | Who caused it |
| `notifiable_type`, `notifiable_id` | polymorphic, nullable | What it is about. Folding matches on it. A broadcast such as «Se publicó la convocatoria» may have none |
| `kind` | string, not null | A registered kind (section 4) |
| `message` | text, not null | The sentence shown, written at creation |
| `action_url` | string, nullable | Where opening it leads; a path |
| `read_at` | datetime, nullable | |
| `idempotency_key` | string, nullable | |
| `created_at`, `updated_at` | datetime | |

Indexes:
- `(recipient_type, recipient_id, created_at)` serves the Avisos list.
- `(recipient_type, recipient_id, kind) WHERE read_at IS NULL` serves the counter and the «Nuevo» lookup.
- `(notifiable_type, notifiable_id)`.
- A unique index on `idempotency_key WHERE idempotency_key IS NOT NULL`. Migrated rows carry no key, so migrating needs no dedupe.

The model is `Bali::Notice`, not `Bali::Notification`. Until 4.0, `Bali::Notification` is the
module of the deprecated alert component (`Bali::Notification::Component`), and a class cannot
reopen a module.

### `bali_notice_deliveries`

One row per notice that goes out by email.

| Column | Type | Notes |
|---|---|---|
| `notice_id` | bigint, not null, unique | |
| `mode` | string, not null | `immediate` or `digest` |
| `status` | string, not null | `pending`, `sending` (claimed by a digest run), `delivered`, `failed`, `skipped` (a digest notice already read in the app before its run) |
| `attempts` | integer, default 0 | |
| `delivered_at`, `failed_at` | datetime | |
| `failure_reason` | string | The exception's class and message, truncated |
| `created_at`, `updated_at` | datetime | |

Index `(mode, status, created_at)`, for the digest run.

## 3. Te toca: providers and items

### The contract

GC's contract, with one helper added:

```ruby
class TDFlow::Inbox::SignaturesProvider
  include Bali::Inbox::Provider

  def kind = :signature
  def icon = "signature"            # optional, "inbox" by default

  # A relation or an Array of records: whatever is waiting on `user`, preloaded for build_item.
  def pending_for(user)
    TDFlow::Signature.where(approver: user, decision: "pending").includes(signoff: :initiative)
  end

  # pending_count_for(user) defaults to pending_for(user).size, a COUNT on a relation.
  # A provider that can count more cheaply than it lists overrides it.

  def build_item(signature, user:)
    item signature,
         title: …, subtitle: …, href: new_td_flow_signature_decision_path(signature),
         due_at: signature.due_on, requested_by: signature.signoff.requested_by&.display_name
  end
end
```

- `Bali::Inbox::Provider` includes the host's URL helpers. `item(record, **fields)` builds the
  item with the provider's `kind` and the record already filled in.
- `build_items(records, user:)` maps `build_item` by default. A provider that needs one lookup
  for the whole batch overrides it.
- `Bali::Inbox::Item` is a `Data` with these fields:
  - `kind` and `record`;
  - `title`, required;
  - `subtitle`, `href`, `due_at` and `requested_by` (a name, a String), all optional;
  - `module`, which comes from registration.
- The item's key is `kind` plus `record.to_gid_param`. That key is the URL:
  `/inbox/items/:kind/:gid`.

### Registration

In `lib/bali.rb`, like `Bali.archivables`:

```ruby
# config/initializers/bali.rb
Bali.inbox_providers = {
  td_flow: %w[
    TDFlow::Inbox::ApprovalsProvider TDFlow::Inbox::ExtensionsProvider
    TDFlow::Inbox::SignaturesProvider TDFlow::Inbox::TasksProvider
    TDFlow::Inbox::CorrectiveActionsProvider TDFlow::Inbox::InterviewsProvider
  ]
}
```

- Each key is a module, and the order is the order of the filter pills.
- Providers are named by class name and constantized on use, so a development reload never holds
  a stale class. This is the same reason `Bali.archivables` is keyed by string.
- A kind that appears twice raises on first use.
- Labels come from the host's locale files: `bali_view.inbox.kinds.<kind>` (with `one`/`other`)
  and `bali_view.inbox.modules.<module>`.

### Reading it: `Bali::Inbox::Query`

`Bali::Inbox::Query.new(user)` is public, so GC can later build its team view from it.

- `count` is the sum of `pending_count_for`. `counts_by_kind` gives the same numbers per kind.
- `items(module: nil, kind: nil)` fetches at most `FETCH_CAP = 100` records per provider, builds
  the items, and sorts them. The sort goes by band (below). Inside a band it goes by `due_at`
  ascending, with undated items last and then by title.
- `capped?` says whether any provider hit the cap.
- `find(kind, gid)` returns the item, or `nil` when it is not pending for this user:
  - the gid's model must be that kind's provider's model;
  - the record must be in `pending_for(user)` (`where(id:)` on a relation, `detect` on an Array);
  - the gid is never resolved with `GlobalID::Locator.locate` alone, so a forged gid reaches nothing.

Bands, from the canvas:
- «Vencidos»: `due_at` is in the past.
- «Esta semana»: `due_at` falls within the next 7 days.
- «Después»: everything else, undated items included.

There is no `UNION ALL` batching of counts in v1. GC needs it because it counts on every page. Here
the count is cached (section 6), so it runs at most once a minute per person. If the uncached count
measures slow in the pilot, batching is the next step.

## 4. Avisos: kinds, `notify`, email

### Kinds

```ruby
Bali.notice_kinds = {
  approval_assigned: { email: :immediate, announces: :approval },
  scholarship_request_submitted: { email: :digest },
  scholarship_welcome: { email: :immediate, queue: :low },
  story_assigned: {}
}
```

- `email:` takes one of three values:
  - `nil`, the default: in-app only;
  - `:immediate`: one email when the notice is created;
  - `:digest`: the notice waits for the hourly digest.
- `queue:` is the queue its immediate email goes on. afal-apps sends its Becas broadcasts on `:low`.
- `announces:` is the inbox kind this notice announces (section 5).
- A notice of an unregistered kind is invalid. An `announces:` that names a kind no provider has
  raises on first use.

### `Bali::Notifiable`

```ruby
class TDFlow::Signature < ApplicationRecord
  include Bali::Notifiable
end

signature.notify(recipient: approver, kind: :signature_assigned, message: "…",
                 actor: requester, action_url: path, idempotency_key: nil)
```

- It adds `has_many :notices, class_name: "Bali::Notice", as: :notifiable, dependent: :destroy`.
  A notice deletes its delivery row with it.
- `notify` does nothing when the recipient is blank. This keeps the behaviour and the signature of
  afal-apps' `Notifiable#notify`.
- When the `idempotency_key` was already used, `notify` returns the existing notice instead of
  raising. GC's hooks rescue `RecordNotUnique` by hand today.
- A notice about nothing is created with `Bali::Notice.create!(recipient:, kind:, message:)`.

### When a notice is created

- Its delivery row, when the kind has `email:` and `Bali.notices_deliver_if.call(notice)` is
  truthy, is written in the notice's own transaction. A crash between the two can therefore never
  leave a notice whose email was silently dropped.
- After commit:
  - an `immediate` delivery enqueues `Bali::NoticeDeliveryJob` on the kind's queue;
  - the recipient's counter is expired, and their open pages are told to refresh it (section 6).
- The import guard afal-apps has today (`SmartsuiteImport.importing?`) becomes its
  `Bali.notices_deliver_if`.

### `Bali::NoticeDeliveryJob`

- It calls the host's mailer, `Bali.notices_mailer` (a class name; it is required as soon as any
  kind has `email:`): `notify(notice).deliver_now`.
- It counts attempts. A delivery is marked `delivered` once sent, or `failed` with the reason
  after the last retry, using `retry_on StandardError, wait: :polynomially_longer, attempts: 5`
  (GC's `NotificationDeliveryJob`).
- A delivered row is never sent again.
- The host's mailer keeps every per-kind template it has. afal-apps' `NotificationMailer#notify`
  reads the same attributes from a `Bali::Notice` that it reads from a `Notification` today.

### The digest

`Bali::NoticeDigestJob`, scheduled by the host every hour (Solid Queue's `config/recurring.yml`):

1. It claims the pending digest rows with a single `UPDATE … SET status = 'sending' … RETURNING`,
   so two overlapping runs never take the same row.
2. It marks `skipped` every claimed notice the person has already read in the app, so the email
   only carries what is new to them. A recipient with nothing left gets no email.
3. It groups the rest by recipient and sends one email per recipient through
   `Bali::NoticeDigestMailer`. That mailer inherits from `Bali.notices_parent_mailer` (by default
   `"ApplicationMailer"`), so it carries the host's layout and sender.
4. It marks that recipient's rows `delivered`. On an error the rows go back to `pending` with one
   more attempt, and become `failed` at the fifth.
5. A row left in `sending` for over an hour, because a run was killed mid-send, goes back to
   `pending`. That can send a digest twice, but never loses one.

The content follows the «Correo agrupado» board:
- Subject «{N} avisos nuevos en {app}». The app's name comes from i18n, which the host overrides.
- «{nombre}, tienes {N} avisos nuevos».
- «Del sábado 18 de octubre, de 10:40 a 11:40.»: the span from the first notice to the last, in
  the app's time zone, with days and months in lower case.
- One block per kind that has at least three notices:
  - a heading from `bali_view.notices.digest.kinds.<kind>` with the count;
  - the first three notices, each with its `message` and time;
  - «y {N} más en tu bandeja».

  Kinds with fewer than three share one last block, «Otros avisos · {N}», as on the board.
- The button «Abrir mi bandeja» opens the page's Avisos tab.
- Footer: «Te juntamos estos avisos en un solo correo, una vez por hora y sólo cuando hay algo
  nuevo. Los que no pueden esperar te llegan al momento.»
- Each row links to the notice's `action_url`, made absolute. It never goes through an engine
  endpoint that marks the notice read: mail scanners such as Safe Links fetch every link when the
  message arrives.
- There is an HTML part and a text part.

## 5. Folding

A kind registered with `announces: :signature` says that this notice tells someone a `:signature`
item is now waiting on them, about the notice's own `notifiable`.

- Such notices never appear in «Avisos» and never count toward the dot. Their only trace is the
  «Nuevo» mark. It shows on the item whose `record` is the notice's `notifiable`, for the same
  recipient, while the notice is unread.
- Viewing the item marks those notices read. Viewing means its detail on the page, or following it
  from the popover.
- «Marcar todos como leídos» marks them read too.
- It stays out of «Avisos» after the item is resolved as well, read or not. The Bandeja board
  showed one coming back as «antes era un pendiente»; Federico chose against it on 2026-10-18, so
  «Avisos» never has to compute anyone's pending items.
- If the item stops being pending before the person sees it, the notice stays out of sight. There
  is nothing left to do, which is what «Avisos» would have said anyway. This also covers
  afal-apps' approval notices:
  - they go to everyone with the permission;
  - the provider shows the request only to those that separation of duties allows;
  - for the rest, the notice never shows.
- The email still goes out as its kind says.
- Cost: the «Nuevo» marks are one query over the items being shown. That query matches unread
  notices, of the announcing kinds, whose `(notifiable_type, notifiable_id)` is one of the items'
  records. It runs only in the popover and the page, never in the topbar.
- In afal-apps it retires `TARGET_STATE_KINDS`, `Notification#target_resolved?` and the «Mis
  pendientes» filter.

The risk is a kind declared `announces:` whose provider does not show that record to that
recipient: it hides the notice for good. The guide says to declare it only where the notice and
the provider are about the same record for the same people. afal-apps' pilot tests one case per
announcing kind.

## 6. The counter

`Bali::Inbox::Badge` holds two numbers:
- `pending`: `Query#count`;
- `unread`: unread notices whose kind does not announce.

How it stays fresh:
- It is cached per person in `Rails.cache` for one minute, under
  `bali/inbox/badge/<recipient GlobalID>`.
- These expire it at once:
  - a new notice for that person;
  - a mark-read through the engine;
  - any request by that person that is not a GET or HEAD.

  So resolving something lowers the number on the very next page.
- Someone else's action that adds or removes one of your items without a notice shows within the
  minute.
- Opening the popover computes the live numbers anyway, so it writes them to the cache and the
  icon.

How the host wires it:
- It includes `Bali::Concerns::Controllers::InboxBadge` in its `ApplicationController`.
- The concern adds the `inbox_badge` helper (memoized per request; `nil` when there is no owner,
  and then the icon does not render) and the `after_action`.
- Its seam is `inbox_owner`, which defaults to `current_user`. The inbox controller (section 8)
  inherits it.

Live updates:
- When a notice is created, the engine broadcasts to `[recipient, :bali_inbox]`. The broadcast
  tells the open pages to fetch their badge again from the badge endpoint.
- It carries no count. So a Becas morning that writes thousands of notices writes thousands of
  small cable messages, and computes nothing for people who are not looking.
- The topbar component renders the `turbo_stream_from` when it is given `stream:`.

Cost per page, read from the code on 2026-10-18 (not timed):
- Today:
  - afal-apps runs one indexed `COUNT` on every page (`ApplicationController` →
    `Current.unread_notifications_count`);
  - GC runs a `UNION ALL` of 16 provider counts plus the bell's count.
- With the engine:
  - with a warm cache, a page runs one cache read (one `SELECT` in afal-apps' Solid Cache) and no
    provider or notice query;
  - a cache miss runs every provider's count and one notice `COUNT`, at most once a minute per
    person.

## 7. The topbar icon and the popover

```erb
<% topbar.with_action do %>
  <%= render Bali::Topbar::Inbox::Component.new(
        badge: inbox_badge, popover_url: popover_inbox_path, href: inbox_path,
        stream: current_user) %>
<% end %>
```

The icon follows the «Contador A» board:
- It uses the Lucide icon `inbox`, through the Bali icon pipeline, with `IconAction`'s button classes.
- The pending number is `IconAction`'s count pill: error color, top right, capped at 99+.
- When `unread > 0`, it adds a `primary` dot at the bottom right with a `base-100` ring.
- It shows neither when both numbers are zero.
- Its accessible name is one of «Bandeja», «Bandeja: 6 pendientes», «Bandeja: hay avisos sin
  leer» and «Bandeja: 6 pendientes, hay avisos sin leer» (i18n). The name and the badge update
  together.
- It is a link to `href` with `aria-haspopup="dialog"` and `aria-expanded`. A plain click opens
  the popover instead of navigating; a modified click, or no JS, opens the page.

The popover follows the «Main», «Popover en los dos temas» and «Estados del popover» boards.

Shape and behaviour:
- It is 440 px wide and anchored under the icon's end edge.
- It is appended to `body` and positioned by tippy, as `Bali::Dropdown` is, so no `overflow` on
  the page clips it.
- Below 640 px it takes the viewport's width minus the 16 px gutters.
- It is a dialog: `role="dialog"` with the label «Bandeja». Focus moves into it when it opens;
  Escape or a click outside closes it, and focus returns to the icon.

Loading:
- Its content is a `<turbo-frame>` with `src: popover_url`. It is fetched the first time the
  popover opens.
- While it loads, the board's skeleton shows, with the tabs already carrying the badge's numbers.
- Each later open reloads the frame, and the previous content stays on screen until the new
  content arrives.

Header: «Bandeja», with an expand link to the full page, and two tabs, «Te toca {N}» and «Avisos
{M} sin leer». «Te toca» comes first. «Avisos» loads on its first click as its own frame request,
so opening the popover reads no notice beyond what the counter already knows.

«Te toca»:
- It shows up to 10 items in the bands «Vencidos», «Esta semana» and «Después», each with its count.
- A row has the kind's icon tile, the title, «{kind} · {module}», and the due text («venció hace
  2 días», «vence el viernes»).
- A folded item carries the «Nuevo» pill on the soft primary background.
- Footer: «{N} pendientes» and «Ver toda la bandeja →».
- When it is empty: «No tienes nada pendiente», plus «Ver los {M} avisos sin leer →» when there
  are unread notices.

«Avisos»:
- It lists the latest 10 notices whose kind does not announce. Each unread one carries a dot.
- «Marcar todos como leídos» is a POST. It answers with a Turbo Stream that re-renders the tab
  and the badge.
- Footer: «Ver todos los avisos →».

Links:
- An item row opens `item.href` through the `open_item` action. A notice row goes through
  `open_notice`.
- Both links carry `data-turbo-prefetch="false"`. Turbo 8 prefetches a link on hover, and these
  GETs mark notices read, so without it they would mark them read on hover.

## 8. The full page

The host's side:

```ruby
class InboxesController < ApplicationController
  include Bali::Concerns::Controllers::Inbox
end

# config/routes.rb
resource :inbox, only: :show do
  get :popover
  get :badge
  get "items/:kind/:gid", action: :item, as: :item
  get "items/:kind/:gid/open", action: :open_item, as: :open_item
  get "notices/:id/open", action: :open_notice, as: :open_notice
  post :read_all
end
```

| Action | Verb + path | What it is |
|---|---|---|
| `show` | `GET /inbox` | The page. Takes `tab=notices`, `kind=`, `module=` and `page=` |
| `item` | `GET /inbox/items/:kind/:gid` | The page with that item's detail. It marks the item's folded notices read. When the item is not pending for you, it shows the «ya no está» detail instead |
| `popover` | `GET /inbox/popover` | The popover's frame. `tab=notices` gives the second tab |
| `badge` | `GET /inbox/badge` | The icon's badge, for the live refresh |
| `open_item` | `GET /inbox/items/:kind/:gid/open` | Marks the folded notices read, then `303` to `item.href`. When the item is not pending, it goes to the «ya no está» detail |
| `open_notice` | `GET /inbox/notices/:id/open` | Marks the notice read, then `303` to its `action_url` when that is a relative path (starts with `/`, not `//`), and to the Avisos tab otherwise. Someone else's notice is a `404` |
| `read_all` | `POST /inbox/read_all` | Marks every unread notice of the owner read, folded ones included. `303` back to the page, or a Turbo Stream when it comes from the popover |

Authorization:
- The host's controller runs the host's own authentication `before_action`s and layout. That is
  why this is a concern and not an engine controller.
- The inbox shows only the owner's things. Every provider filters by the person, and every notice
  query filters by recipient, so there is no authorize lambda.

Views:
- The engine's templates sit behind the controller's own through `_prefixes`, as in
  `DashboardWidgets`: `bali/inbox/show`, the popover, the generic item detail, and the «ya no
  está» detail. So `app/views/inboxes/show.html.erb` in the host wins.
- A host partial `inbox/items/_<kind>`, which takes `item` as a local, replaces the generic
  detail for that kind.

The page follows the «Bandeja» board. Header «Bandeja», with the tabs «Te toca» and «Avisos».
The board's census item and its «Terminales» module are sample data. The pilot registers only
`td_flow`, so the module select does not render there.

«Te toca»:
- Filters:
  - kind pills with counts, which come from `counts_by_kind` and ignore the filter;
  - a module select, shown only when there is more than one module.
- The list and detail sit in a `Bali::SplitView`, the layout TDFlow's inbox page uses today. The
  rows match the popover's, 20 per page.
- The generic detail shows the kind tag, the module, the due date, the title, who requested it
  and the subtitle, with «Abrir y resolver» (to `open_item`) and «Copiar liga».
- When a provider hit the fetch cap, the list says so. Items past the cap cannot be reached from
  the page.

«Avisos»:
- The history, newest first, grouped into «Hoy» and «Antes», 20 per page («1–20 de 37»).
- An unread dot on each unread notice, and «Marcar todos como leídos».

«Ya no está», from the «Ya no está en tus pendientes» board:
- Copy: «Esto ya no está en tus pendientes» / «Puede que ya se haya resuelto o que ahora le toque
  a otra persona. No tienes que hacer nada.» / «Volver a lo que te toca».
- A resolved item, someone else's, and a gid that resolves to nothing get the same `200` with the
  same body. The URL tells nothing about records you cannot see.

Pagination works without pagy, which is deliberately not a dependency of this gem.

## 9. Not in v1

- **The team view.** `Bali::Inbox::Query.new(member)` is public, so GC can build «De mi equipo»
  on it.
- **The reminder for items waiting several days.** GC's `deliver_reminders!` comes when GC adopts.
- **`Bali::Pendable` and a «Mis pendientes» dashboard widget.** Neither has a consumer in this
  round. afal-apps' providers are objects, and no app renders an inbox card on a
  `Bali::DashboardPage`. Both come with GC, if it needs them.
- **Batched counts (`UNION ALL`).**
- **GC's `inline_actions`.**
- **Per-person email preferences** (opting out of a kind).

## 10. How afal-apps adopts it (the pilot)

The order:
1. Bali: PR, merge and release. It is the next minor, `v3.19.0`, unless another branch releases first.
2. afal-apps: one PR with the bump, the adoption and the deletions. Federico merges and deploys it.

### Te toca

- The five providers of `TDFlow::Inbox` move to the contract. Each `pending_for` returns records
  and each `build_item` returns an item. Their permission early-outs and preloads stay their own.
  They register under `td_flow`.
- Those five keep the gate TDFlow's inbox page applies today (`TDFlow::InboxPolicy#show?`:
  `tdflow.access`, `tdflow.manage` or `tdflow.executive`) as an early-out in `pending_for`.
  Without it, someone holding a task with no TDFlow role would get an item whose link answers
  `403`. The interview provider has no such gate.
- A new `TDFlow::Inbox::InterviewsProvider`, kind `:interview`, also under `td_flow`:
  - **When it is pending.** The initiative must still take interviews (`taking_interviews?`) and
    the person must still be one of its `interviewees`. Then one of two cases applies:
    - the interview that `interviewees` assigns them exists and is not `closed`. This includes the
      interviews TD started on people's behalf before 16/10/2026, which have no invitation:
      `td_flow_interview_invitations` began with #988, with no backfill;
    - it does not exist yet, and TD has invited them (`TDFlow::InterviewInvitation`). Sending the
      invitation again adds a row, and only the latest one counts.
  - **The item.**
    - Its record is the interview when it exists, and the latest invitation otherwise. Each one is
      the `notifiable` of the `interview_assigned` notices of its era: the dispatcher notified the
      interview until #988, and the invitation after it.
    - Its `href` is `td_flow_initiative_my_interview_path(initiative)`. That page already sends
      someone who has started straight to their conversation.
    - Its title is «Responder la entrevista de «{title}»».
    - It has no due date, unless discovery carries one in the model.
  - **The query.** It does in SQL what `Initiative#interviewees` does in Ruby to pick each
    person's interview: the initial one for the leader, the participant's for everyone else. A
    test pins that the two agree for:
    - the leader;
    - a co-leader;
    - a mapped participant;
    - an invitation sent again;
    - an interview started before invitations existed;
    - a closed interview;
    - a paused initiative.
  - **Who sees it.** Anyone invited, whatever their TDFlow role, as `MyInterviewPolicy` allows.
- `TDFlow::InboxesController`, its views and its route go. The route redirects to
  `/inbox?module=td_flow`.
- `TDFlow::Inbox`, the orchestrator, goes.
- The `_inbox_widget` partial on the TDFlow dashboard and report reads `Bali::Inbox::Query`
  filtered to `td_flow`, and links to the new page.

### Avisos

- The 29 kinds register in `Bali.notice_kinds`:
  - the `EMAIL_KINDS` take `email: :immediate`, and the three `SCHOLARSHIP_BROADCAST_KINDS` add
    `queue: :low`;
  - the rest are in-app only.
- `announces:` pairs, each checked against the record the provider lists:

  | Notice kind | Announces | The record both point at |
  |---|---|---|
  | `approval_assigned` | `:approval` | `TDFlow::ApprovalRequest` |
  | `extension_pending` | `:extension` | `TDFlow::Extension` |
  | `signature_assigned` | `:signature` | `TDFlow::Signature` |
  | `corrective_action_assigned` | `:corrective_action` | `TDFlow::CorrectiveAction` |
  | `interview_assigned` | `:interview` | `TDFlow::Interview` (notices before #988) or the latest `TDFlow::InterviewInvitation` |

- `scholarship_request_submitted` takes `email: :digest`: the training team gets one email an hour
  instead of one per request (Federico, 2026-10-18). Every other email stays as it is today.
- The 17 models that `include Notifiable` switch to `include Bali::Notifiable`.
  `TDFlow::NotificationDispatcher` keeps building messages and choosing recipients, unchanged.
- Every other reader of `Notification` moves to `Bali::Notice`. On `origin/main` (21c81dec0)
  these are:
  - `lib/smartsuite_import.rb`;
  - `Finance::Terminals::CensusNotifier`;
  - three Becas models: `Scholarships::Request::SecondRequestNotice`,
    `Scholarships::Employee::Notices` and `Scholarships::Budget::LowAlert`. Some of them use it to
    avoid sending twice;
  - `Marketing::PopRequest::Submission`;
  - two TDFlow controllers: `portal/proposals/submissions` and `open_questions/assignments`.

  `app/views/pwa/service-worker.js` matches the same search. It is checked, because it most likely
  refers to the browser's `Notification`. The list is re-run with `git grep` when the work starts.
- `NotificationMailer` stays as `Bali.notices_mailer`, with its per-kind templates.
- What goes:
  - `Notification`, `Notifiable`, `TARGET_STATE_KINDS` and `target_resolved?`;
  - the «Mis pendientes» filter;
  - `NotificationsController` and its read controllers;
  - the `notifications/bell` partial;
  - `Current.unread_notifications_count` and its line in `ApplicationController`.

  `/notifications` redirects to `/inbox?tab=notices`.
- In the topbar, `notifications/bell` becomes `Bali::Topbar::Inbox`, under the same
  `current_user && internal_request?` condition.
- That layout also renders bali-auth's engine screens (`/admin/auth/…`). There, two things change:
  - the URLs go through `main_app.`, as the user menu's already do;
  - the `inbox_badge` helper is not defined, because those controllers do not inherit the host's
    `ApplicationController`. The icon must not raise there; it renders nothing.

### The data, in two deploys

This is GC's Archivable pattern. It has to be safe while traffic and the job queues are live: the
deploy cannot assume the queues are drained or that the old container has stopped writing.

1. **First deploy.** A migration copies `notifications` into `bali_notices`, keeping each `id`. It
   maps:
   - `recipient_id` to `recipient` (User);
   - `actor_id` to `actor` (User);
   - `notifiable`, `kind`, `message`, `action_url`, `read_at` and the timestamps as they are.

   The rest of this deploy:
   - It writes no delivery rows, because those emails already went out.
   - It moves the `bali_notices` sequence past the highest copied id plus a gap of 1,000,000. The
     old container keeps inserting into `notifications` from that same highest id, and the gap
     keeps those ids free.
   - The code reads and writes `bali_notices`.
   - It keeps a bare `Notification` class over the old table until the second deploy. Every
     queued email job holds its notification by GlobalID; a Becas morning queues thousands on
     `:low`. Those jobs still find their record, and `NotificationMailer#notify` reads the same
     attributes from either class.
2. **The next release.** It copies the rows the old container wrote during the switch (ids above
   the first copy's highest), keeping their ids, which fall inside the gap. Then it drops
   `notifications` and the bare class.

The proof, on a copy of production:
- the same count per recipient and kind;
- the same unread count per recipient;
- for a sample of users, the new `unread` equals today's bell count minus the folded kinds.

## 11. Testing

### Bali

**The model**
- Kinds are validated.
- `notify` does nothing for a blank recipient.
- A used `idempotency_key` returns the existing notice.
- The delivery row is written in the notice's transaction.
- A falsy `notices_deliver_if` writes no delivery.

**The delivery job**
- A notice is delivered once.
- Retries count attempts.
- The fifth failure leaves the row `failed`, with its reason.
- A delivered row is not sent again.

**The digest**
- Two overlapping runs never send the same notice.
- Notices are grouped by recipient.
- A notice read before the run is `skipped`, and a recipient left with nothing gets no email.
- A kind with fewer than three notices goes into «Otros avisos».
- A row stuck in `sending` returns after an hour.
- The email's links point at `action_url`, never at an engine endpoint.

**The query**
- Aggregation, bands and order.
- The fetch cap and `capped?`.
- `find` refuses a gid of another model and a record that is not pending.
- A duplicate kind raises, and so does an `announces:` that names an unknown kind.

**Folding**
- Announcing notices are left out of Avisos and of `unread`.
- «Nuevo» shows only for the same record and recipient.
- Viewing the item, or opening it, marks the notice read.

**The counter**
- With a warm cache, a page issues no provider or notice query (`assert_queries_count`).
- It expires on a new notice, on a mark-read and on a non-GET request.
- With no owner it is `nil`, and the icon renders nothing.

**The concern**
- Each route works.
- A host template overrides the engine's.
- The «ya no está» body is byte-identical for a resolved item, someone else's, and an unknown gid.
- `open_notice` redirects only to relative paths, and gives `404` for someone else's notice.
- The open links carry `data-turbo-prefetch="false"`.

**The components**
- The counter A states: none, the number only, the dot only, both, and 99+.
- Their accessible names.

**Cypress**
- No popover request goes out before the first click.
- Escape closes the popover and focus returns to the icon; a click outside closes it.
- The Avisos tab loads on its first click.
- «Marcar todos como leídos» updates the badge.

**The dummy app** has a host controller with the concern, two providers, and notices that include
one announcing kind.

**The browser:** `afal` and `afal-dark`, at 1280 and at 375. It covers the popover, the page, «ya
no está», and the digest through an ActionMailer preview.

### afal-apps

- The interview provider's matrix (section 10).
- For each provider, `pending_count_for` agrees with `pending_for` on a sample of users.
- One folding case per announcing kind.
- The data migration: ids, read state and polymorphic types survive. A row written to
  `notifications` after the first copy arrives in the second. A queued email job that holds a
  `Notification` still sends.
- The redirects.
- A browser check on a development database.
- Measured, not estimated:
  - query count and time for a page with a warm cache, against `main`;
  - the same for a cache miss.

### For both

Every new test is first red for the right reason, with a negative control on the line it covers.
Each PR goes through DHH review on a worktree before it opens.

## 12. Documentation

- `docs/guides/engine-models.md`: an «Inbox and notices» section, with its own «Porting from
  afal-apps» table.
- `docs/guides/engines.md`: the `Bali.inbox_providers`, `Bali.notice_kinds` and `Bali.notices_*`
  entries, and the two concerns.
- CHANGELOG, under `[Unreleased]`.

## Left to the builder

- **The popover's JavaScript.** A focused Stimulus controller of its own, or the tippy setup
  `Bali::Dropdown` already has, within the constraints of section 7.
- **The interview provider's SQL**, within the test matrix of section 10.
- **How the engine paginates** its arrays and relations without pagy.
- **The exact i18n keys** beyond the ones named here, and how the digest greets the person.
- **How the badge refresh is wired**: a frame with `src`, or a stream action.
- **The sort's tie-breakers** beyond the ones named in section 3.

## Calls made while writing, not discussed in brainstorming

- **The model is named `Bali::Notice`**, because the other constant is taken (section 2).
- **Folding is declared per kind** (`announces:`). A folded notice never appears in «Avisos» and
  never counts toward the dot (section 5).
- **Viewing is reading.** `item`, `open_item` and `open_notice` are GETs that mark read, with
  Turbo's prefetch turned off on their links (sections 7 and 8).
- **The badge refreshes live** through a broadcast that carries no count (section 6).
- **`Bali::Pendable` and the «Mis pendientes» widget leave v1** (section 9). Both were defaults
  stated in brainstorming, but nothing in this round would use them.
- **TDFlow's inbox page is retired** with a redirect; the TDFlow dashboard's card stays, over the
  new query (section 10).
- **No `UNION ALL` batching** until the pilot measures a slow uncached count (section 3).
- **What counts as an interview pending** now also covers interviews started before invitations
  existed (section 10).
- **The data migration is safe with live traffic:** a sequence gap, and a bare `Notification`
  class kept until the second deploy (section 10).
- **The digest** skips what was already read, and groups small kinds under «Otros avisos»
  (section 4).
