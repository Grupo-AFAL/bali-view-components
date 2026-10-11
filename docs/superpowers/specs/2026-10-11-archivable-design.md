# Archivable: the document engine's archival, adopted by gobierno-corporativo — Design

Date: 2026-10-11
Status: Design approved in brainstorming — 2026-10-11; written spec pending review
Issue: #721 (Documents engine phase 2), sub-project 1 of 6

## Purpose

gobierno-corporativo (GC) carries its own document lifecycle — publishing, archival, periodic
review, read acknowledgments — coupled to its domain. Phase 2 of the document engine moves the
generic part into Bali so GC adopts it and deletes its copy, and so a second app can use it.
This spec covers the first piece, archival: the smallest, the least coupled, and the pilot of the
adoption pattern every later piece repeats — a polymorphic `bali_*` table, an engine controller
that denies by default, components, and GC copying its rows and deleting its code.

## The programme this belongs to

| # | Sub-project | Consumer |
|---|---|---|
| 1 | **Archivable** (this spec) | GC |
| 2 | Optional Markdown copy of the BlockEditor/DocumentEditor content, for agents | Bali |
| 3 | TDFlow pilot: the requirements document (`TDFlow::Spec`) on DocumentEditor with history, acknowledgments, ReadCoverage and the Markdown copy | afal-apps |
| 4 | Reviewable (periodic review) | GC |
| 5 | Events (a subscribable hook for publish/archive/review) | Bali |
| 6 | Publishable (change log, snapshot, optional polymorphic trigger, approval record) | GC, afal-apps |

Out of the engine for good, as #721 says: the approval workflow, nomenclature, classifications,
pgvector, dashboards.

## Decisions (from the brainstorming session)

| Question | Decision |
|---|---|
| What Bali delivers | The full engine: model, controller with routes, form and notice components |
| Can an archival be undone | Optional per model (`reversible:`); irreversible by default, as GC decided |
| Where the reasons come from | Bali ships GC's five as defaults with es/en labels; a macro changes them per model |
| Where an archival lives | Its own polymorphic table, `bali_archivals`, with the history of archivals and reopenings |

## 1. Data

Table `bali_archivals`, installed with `bin/rails bali:install:migrations:archivals` (the task
name derives from the file name, `lib/bali/engine_migrations.rb`):

| Column | Type | Notes |
|---|---|---|
| `archivable_type`, `archivable_id` | polymorphic, not null | The record archived |
| `archived_by_type`, `archived_by_id` | polymorphic, nullable | Who archived it — same shape as `author` in `bali_content_versions` |
| `reason` | string, nullable | A key from the model's list (`replaced`, `expired`…) |
| `note` | text, nullable | Free text, at most 500 characters |
| `successor_type`, `successor_id` | polymorphic, nullable | The record that replaces it |
| `unarchived_at` | datetime, nullable | Only on reversible models |
| `unarchived_by_type`, `unarchived_by_id` | polymorphic, nullable | Who reopened it |
| `created_at`, `updated_at` | datetime | `created_at` is the archival date |

Indexes: a unique partial index on `(archivable_type, archivable_id) WHERE unarchived_at IS NULL`
— at most one current archival per record, enforced by the database — and an index on
`(successor_type, successor_id)` for "what did this replace".

GC's names change on the way in: its `obsolescence_reason` (the key) becomes `reason`, its `reason`
(the free text) becomes `note`. Today the two read as the same thing.

## 2. The model and the concern

```ruby
class Document < ApplicationRecord
  include Bali::Archivable
  archivable reasons: Bali::Archivable::DEFAULT_REASONS,   # replaced no_longer_applicable superseded expired other
             successor_required_for: %i[replaced],
             reversible: false
end

document.archive!(by: user, reason: :replaced, note: "…", successor: other)
document.unarchive!(by: user)
document.archived?
document.archival        # the current archival, or nil
document.archivals       # every archival, newest first
Document.archived        # EXISTS a current archival
Document.not_archived    # NOT EXISTS a current archival
```

- `archive!` raises `Bali::Archivable::AlreadyArchived` when a current archival exists, and
  `ActiveRecord::RecordInvalid` when the archival is invalid.
- `unarchive!` raises `Bali::Archivable::NotReversible` on a model declared `reversible: false`,
  and `Bali::Archivable::NotArchived` when there is nothing to reopen. It stamps `unarchived_at`
  and `unarchived_by` on the current row; the row stays as history.
- `archivable` with no arguments takes every default.

`Bali::Archival` validates: `reason`, when present, is in the archivable model's list; a successor
is present when `reason` is in `successor_required_for`; the successor is not the record itself;
`note` is at most 500 characters. `reason_label` reads
`activerecord.archival_reasons.<model_i18n_key>.<reason>` and falls back to
`bali_view.archivals.reasons.<reason>`, so a host can relabel per model.

Inverse of the successor: `Bali::Archival.where(successor: record)` gives what `record` replaced.
The concern adds no association for it; GC defines its own `predecessor_documents` through it
(section 5).

The name: four fleet apps already have an `Archivable` of their own (an `archived_at` flag).
`Bali::Archivable` is namespaced, so the two never resolve to each other, but one model cannot
include both — they define the same `archive!`/`archived?`. The guide says so.

## 3. The engine controller

`Bali::ArchivalsController`, built on the `Bali::ContentVersionsController` pattern: the record
travels in the query string (`?record_type=Document&record_id=7`) because the engine does not know
the host's models, and authorization is two default-deny layers.

| Route | Action |
|---|---|
| `GET /archivals/new` | The form, for a page or a drawer |
| `POST /archivals` | `archive!`, then `303` to `return_to` when it is a relative path (starts with `/`, not `//`), else `main_app.polymorphic_path(record)`; an invalid archival re-renders the form with `422` |
| `POST /archivals/unarchive` | `unarchive!`, same redirect; `404` on a model that is not reversible |

Configuration in `lib/bali.rb`, each entry documented like `content_versions_*`:

```ruby
# Whitelist + resolver. Empty by default: every record_type is a 404.
Bali.archivables = {
  "Document" => ->(controller, id) { controller.policy_scope(Document).find_by(id: id) }
}

# truthy allows, falsy is a 403. action: "new", "create" or "unarchive". Denies by default.
Bali.archivals_authorize = ->(_controller, _record, _action) { false }

# Who archives or reopens — becomes archived_by / unarchived_by.
Bali.archivals_actor = ->(controller) { controller.try(:current_user) }

# The successor candidates for this record: a relation, or nil for "no successor".
Bali.archival_successors = ->(_controller, _record) { nil }
```

When `archival_successors` returns `nil`, the form offers neither a successor nor the reasons that
require one — a model with no candidates can never reach a half-valid archival. A model that is
whitelisted but does not include the concern is a `404`, as in content versions.

## 4. The components

**`Bali::ArchivalForm::Component.new(record:, successors:, url:, return_to: nil)`** — the
reasons as a radio group with their I18n labels; the successor select, revealed by the existing
`radio-toggle` controller only for the reasons that require one; the note as a text area; the
submit group. Built with `Bali::FormBuilder`. The engine's `new` renders it; a host can render it
inside its own container.

**`Bali::ArchivalNotice::Component.new(record:, successor_url: nil, unarchive_url: nil)`** — the
notice on an archived record — in the `es` locale, «Dado de baja el {fecha} por {quién}. Motivo:
{etiqueta}. Lo sustituye {enlace}» — composed on `Bali::Notification`. The "Reopen" button appears only when
`unarchive_url:` is given; the host passes it when the model is reversible and the person may
reopen. Renders nothing when the record is not archived.

The trigger stays in the host: a `Bali::Link` to `bali.new_archival_path(record_type:, record_id:)`
opened in a drawer. The guide shows it.

Both components get Lookbook previews.

## 5. How GC adopts it

Order: Bali first (PR and release `v3.12.0`), then GC (bump, adoption, deletion) — GC pins Bali by
tag.

GC deletes:
- `app/models/concerns/archivable.rb` and `app/models/document/archival.rb`;
- `Documents::ArchivalsController`, its views and its route;
- `OBSOLESCENCE_REASONS` (they are Bali's defaults). Its Spanish labels stay as an I18n override
  only where they differ from Bali's.

GC changes, in `Document`:
- `include Bali::Archivable` and `archivable successor_required_for: %i[replaced]` (irreversible);
- the `active` scope's `NOT EXISTS (… document_archivals …)` becomes `not_archived`;
- `predecessor_documents` goes through `Bali::Archival` rows naming the document as successor;
- `successor_document` becomes `archival&.successor`;
- `archive_with_change_control` calls `archive!`. Its deactivation change log stays in GC until
  Publishable (sub-project 6).

GC configures the four `Bali.archiv*` entries in its initializer: its `archive?` policy for
authorization, `current_user` as actor, and `policy_scope(Document).published.where.not(id:)` as
successors — what its controller does today. The archive button becomes a `Bali::Link` to the
engine's drawer, and the archived notice uses `Bali::ArchivalNotice`.

Data, in two deploys so the old container never reads a missing table during the switch:
1. A migration copies `document_archivals` into `bali_archivals` — `obsolescence_reason` → `reason`,
   `reason` → `note`, `user_id` → `archived_by` (User), `successor_document_id` → `successor`
   (Document), `created_at` kept — and the code reads the new table.
2. The next release drops `document_archivals`.

Proof nothing is lost, on a copy of the database: the same number of archivals, the same
successors, and the same documents in `active` before and after.

## 6. Testing

Bali:
- Minitest, model: `archive!`/`unarchive!`; `AlreadyArchived`, `NotReversible`, `NotArchived`;
  each validation (reason outside the list, successor required, successor = self, long note); the
  scopes; the partial unique index refusing two current archivals; history on a reversible model.
- Minitest, controller: one test per default-deny layer (no whitelist → 404, no authorize → 403,
  model without the concern → 404, `unarchive` on an irreversible model → 404); `return_to`
  accepts only a relative path; an invalid archival re-renders with 422.
- Minitest, components: no successors → the reasons that require one are not offered; the notice's
  Reopen button only with `unarchive_url:`; nothing rendered for an unarchived record.
- Cypress: the archival drawer — choosing «replaced» reveals the successor, submitting archives and
  redirects, the notice appears.
- The dummy app: a test model adopts the concern, and its schema loads the engine migration.
- Browser: `afal` and `afal-dark`, at 1280 and 375.

GC: its archival flow tests, adapted; a test of the data migration (reason, note, successor, author
and date survive the copy); the `active` comparison on a database copy; its browser check.

Every new test is red for the right reason before the code exists, with a negative control on the
line it covers, and each PR goes through DHH review until rails-worthy.

## 7. Documentation

- `docs/guides/engine-models.md`: an «Archivable» section, and a row in its GC porting table.
- `docs/guides/engines.md`: the four `Bali.archiv*` entries.
- CHANGELOG under `[Unreleased]`.
