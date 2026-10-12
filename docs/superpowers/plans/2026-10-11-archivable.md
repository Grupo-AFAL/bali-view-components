# Archivable Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship archival as a Bali engine feature — a polymorphic `bali_archivals` table, the
`Bali::Archivable` concern, a default-deny engine controller and two components — release it as
`v3.14.0`, then have gobierno-corporativo (GC) adopt it, copy its rows and delete its own copy.

**Architecture:** `Bali::Archival` is one row per archival of any host record; the
`Bali::Archivable` concern gives a host model `archive!`/`unarchive!`/`archived?`, a `has_one
:archival` scoped to the current row and EXISTS-based scopes. `Bali::ArchivalsController` mirrors
`Bali::ContentVersionsController`: the record travels in the query string, `Bali.archivables`
(404) and `Bali.archivals_authorize` (403) deny by default. `Bali::ArchivalForm` is the drawer
body the engine serves; `Bali::ArchivalNotice` is rendered by the host on the archived record.
GC adopts in two deploys: deploy 1 copies `document_archivals` into `bali_archivals` and reads
the new table; deploy 2 copies again whatever the outgoing container wrote, then drops the table.

**Tech Stack:** Ruby 4.0.1 and Rails 8.1 (via mise), ViewComponent 4, Minitest + Capybara
(`ComponentTestCase`, `ActionDispatch::IntegrationTest`), Stimulus (`radio-toggle`, existing),
Lookbook, Cypress (Electron under Xvfb), Playwright for screenshots, SQLite in the dummy,
Postgres in GC.

**Spec:** `docs/superpowers/specs/2026-10-11-archivable-design.md` — read it before any task.

## Global Constraints

- **Two deliverables, in order.** Bali PR → release `v3.14.0` → GC PR (deploy 1) → GC PR
  (deploy 2, after deploy 1 is in production). GC pins Bali by tag, so nothing on the GC side
  starts before the tag exists.
- **Inside the spec only.** Nothing from sub-projects 2–6 (Markdown copy, TDFlow pilot,
  Reviewable, Events, Publishable). GC's deactivation change log stays in GC.
- **Table:** `bali_archivals`, columns exactly as spec §1; indexes exactly two: unique partial on
  `(archivable_type, archivable_id) WHERE unarchived_at IS NULL`, and `(successor_type,
  successor_id)`. Installer: `bin/rails bali:install:migrations:archivals`.
- **Default reasons:** `replaced no_longer_applicable superseded expired other`
  (`Bali::Archivable::DEFAULT_REASONS`). Defaults of the macro: those reasons,
  `successor_required_for: []`, `reversible: false`.
- **Note:** at most 500 characters (`Bali::Archival::NOTE_MAX_LENGTH`).
- **Config entries (lib/bali.rb):** `Bali.archivables` (`{}`), `Bali.archivals_authorize`
  (`->(_controller, _record, _action) { false }`), `Bali.archivals_actor`
  (`->(controller) { controller.try(:current_user) }`), `Bali.archival_successors`
  (`->(_controller, _record) { nil }`).
- **Routes:** `GET /archivals/new`, `POST /archivals`, `POST /archivals/unarchive`; success is a
  `303` to `return_to` when it starts with `/` and not `//`, else
  `main_app.polymorphic_path(record)`; invalid is `422`; `unarchive` on an irreversible model is
  `404`.
- **Language:** everything in the repo is English — code, comments, test names, Cypress
  `describe`/`it`, preview copy, this kind of doc. Spanish only in the CHANGELOG, commit messages
  and PR bodies. Sample data (names in fixtures and previews) is content. No new Spanish anywhere;
  `bundle exec rubocop` (`Bali/EnglishOnly`) enforces the Ruby half.
- **Comments** carry only a measurement, a constraint invisible from the line, or why the obvious
  thing is wrong. YARD on public API, `@param`/`@label` in previews, pragmas. The comments shown
  in this plan's code are the full set — do not add narration.
- **Locales:** every new key in `config/locales/bali_view.en.yml` **and**
  `bali_view.es.yml` (`test/bali/i18n_scope_test.rb` compares them).
- **Shell:** the Bash tool runs zsh. Prefix every Ruby/Node command, and every `git commit`/
  `git push` (the hooks run RuboCop, StandardJS and Minitest), with
  `export PATH="$HOME/.local/share/mise/shims:$HOME/.hermes/node/bin:$PATH";`.
- **Servers:** other agents run dummies on 3001+. This plan's dummy runs on **3021** with its own
  pidfile; check `ls -l /proc/<pid>/cwd` before trusting any port; kill only your own PIDs.
- **Negative controls:** remove only the line a test covers, from a backup copy
  (`cp f f.bak` … `cp f.bak f`), never `git checkout -- f`; read the failure — it must be the
  test's own assertion.
- **PR bodies:** Bali opens with `Part of #721` (no closing keyword: #721 tracks six
  sub-projects); GC opens with `Closes #<GC issue>` if Fede names one, else `Part of
  Grupo-AFAL/bali-view-components#721`. Rest in Spanish. Never open a PR or push without the team
  lead's go-ahead.

## Review Focus

1. **Double submit / two people archiving the same record at once.** Expect one archival and a
   redirect for the second request — never a 500 from the unique index. Pinned in Task 3
   (`test_a_concurrent_archival_raises_already_archived`) and Task 6
   (`test_archiving_an_archived_record_redirects_and_keeps_the_first_archival`).
2. **A hostile `return_to`** (`//evil.example`, `https://evil.example`, `javascript:`). Expect the
   record's own page. Pinned in Task 6 (`test_return_to_is_followed_only_when_it_is_a_path_of_this_app`).
3. **A `successor_id` the person was not offered** (outside `Bali.archival_successors`, or any id
   when there are no candidates). Expect it never stored; `422` when the reason needs one. Pinned
   in Task 6 (`test_a_successor_outside_the_candidates_is_never_stored`).
4. **An archival written by GC's outgoing container during deploy 1** (after the copy ran).
   Expect it in `bali_archivals` after deploy 2. Pinned in Task 12
   (`test_running_the_copy_again_adds_only_the_rows_written_since`) and verified on the database
   copy in Task 16.
5. **A GC engine request with no session** (`BaliAuth::EngineAuthentication` is passive, so
   `current_user` is nil). Expect 404, not a 500 from `Pundit.policy_scope!(nil, …)`. Pinned in
   Task 14 (`test_without_a_session_the_engine_answers_not_found`).

---

# Deliverable 1 — Bali (PR, then release v3.14.0)

### Task 1: Preflight — worktree, dependencies, premise

**Files:** none (environment and measurements; findings go into the PR body).

**Interfaces:**
- Consumes: the spec and this plan on branch `docs/721-archivable-spec`.
- Produces: worktree `/home/fede/code/bali-view-components.worktrees/721-archivable` on branch
  `feat/721-archivable`, a green baseline, and a dummy server on 3021 that later tasks use.

- [ ] **Step 1: Create the worktree from the docs branch** (the PR carries spec, plan and code)

```bash
cd /home/fede/code/bali-view-components
git fetch origin
git worktree add --no-track -b feat/721-archivable \
  /home/fede/code/bali-view-components.worktrees/721-archivable docs/721-archivable-spec
```

- [ ] **Step 2: Install, build and load databases** (from the worktree root)

```bash
export PATH="$HOME/.local/share/mise/shims:$HOME/.hermes/node/bin:$PATH"
cd /home/fede/code/bali-view-components.worktrees/721-archivable
bundle install && yarn install && (cd test/dummy && yarn install)
readlink -f test/dummy/node_modules/bali-view-components   # must print this worktree's path
bin/rails db:schema:load && bin/rails db:seed
RAILS_ENV=test bin/rails db:schema:load
bundle exec rails app:tailwindcss:build && yarn build
```

- [ ] **Step 3: Dependency alignment** (repo `.claude/CLAUDE.md`)

```bash
bundle outdated tailwindcss-rails
npm view daisyui version; grep '"daisyui"' test/dummy/package.json package.json
```
If either is behind, bump it in its own first commit (`chore(deps): …`), rebuild CSS, and run the
full suite before Task 2. Otherwise note "already current" for the PR body.

- [ ] **Step 4: Baseline**

Run: `bin/rails test`
Expected: 0 failures, 0 errors (note the run count). Any failure here is pre-existing: record it
and do not attribute it to this branch later.

- [ ] **Step 5: Reproduce the premise** (CLAUDE.md § Resolving an issue, step 1)

```bash
git -C ~/code/gobierno-corporativo fetch origin
git -C ~/code/gobierno-corporativo show origin/main:app/models/concerns/archivable.rb
git -C ~/code/gobierno-corporativo show origin/main:app/models/document/archival.rb
git grep -n -i "archiv" -- app lib config db | grep -v "dummy" | head
```
Expected: GC carries `Archivable` + `Document::Archival` (the premise); Bali has no archival code.
Then check the guide's claim before Task 8 writes it (spec §2, "four fleet apps already have an
`Archivable` of their own"):

```bash
for app in afal-apps gobierno-corporativo identity opina garita costa-norte centinela-web ga-apps; do
  git -C ~/code/$app fetch -q origin 2>/dev/null
  echo "== $app"; git -C ~/code/$app grep -l "module Archivable" origin/main -- app 2>/dev/null
done > <scratchpad>/archivable-fleet.txt; cat <scratchpad>/archivable-fleet.txt
```
(Run it from a `.sh` with bash if zsh mangles the loop.) Keep the real count and app names; Task 8
writes what this measured, not "four".

- [ ] **Step 6: Start the dummy on 3021**

```bash
cd test/dummy && bin/rails server -p 3021 -b 127.0.0.1 -P tmp/pids/server-3021.pid
```
Run it in the background; `touch test/dummy/tmp/restart.txt` restarts it after `lib/` changes.

---

### Task 2: The `bali_archivals` table and its installer

**Files:**
- Create: `db/migrate/20261011120000_create_bali_archivals.rb`
- Modify: `test/dummy/db/schema.rb` (regenerated, not hand-edited)
- Modify: `lib/bali/engine_migrations.rb:7-18,42-46` (counts that rot)
- Modify: `lib/tasks/bali_tasks.rake:5-8` (same)
- Test: `test/bali/engine_migrations_test.rb`

**Interfaces:**
- Consumes: nothing.
- Produces: table `bali_archivals` with `archivable_*`, `archived_by_*`, `reason`, `note`,
  `successor_*`, `unarchived_at`, `unarchived_by_*`, timestamps; index names
  `index_bali_archivals_current` (unique partial) and `index_bali_archivals_on_successor`; the
  rake task `bali:install:migrations:archivals`.

- [ ] **Step 1: Write the failing test** — append to `test/bali/engine_migrations_test.rb`
  (inside the existing class):

```ruby
  # The guide and the spec tell a host to run `bali:install:migrations:archivals`: the feature
  # name comes from the file name, so renaming the migration would break that command silently.
  def test_archivals_installs_under_the_name_the_guide_documents
    assert_includes Bali::EngineMigrations.all.keys, "archivals"
  end
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bin/rails test test/bali/engine_migrations_test.rb -n test_archivals_installs_under_the_name_the_guide_documents`
Expected: FAIL — `Expected [...] to include "archivals".`

- [ ] **Step 3: Write the migration**

`db/migrate/20261011120000_create_bali_archivals.rb`:

```ruby
# frozen_string_literal: true

class CreateBaliArchivals < ActiveRecord::Migration[7.0]
  def change
    create_table :bali_archivals do |t|
      # No index of its own: every lookup by record — `archival`, `archived`, `not_archived` —
      # asks for the current row, which the partial unique index below serves.
      t.references :archivable, polymorphic: true, null: false, index: false
      t.references :archived_by, polymorphic: true, index: false
      t.string :reason
      t.text :note
      t.references :successor, polymorphic: true, index: false
      t.datetime :unarchived_at
      t.references :unarchived_by, polymorphic: true, index: false

      t.timestamps
    end

    # At most one current archival per record, enforced where two concurrent requests cannot
    # both pass it. A reopened row (`unarchived_at` set) stays out of the index as history.
    add_index :bali_archivals, %i[archivable_type archivable_id],
              unique: true, where: "unarchived_at IS NULL", name: "index_bali_archivals_current"
    add_index :bali_archivals, %i[successor_type successor_id],
              name: "index_bali_archivals_on_successor"
  end
end
```

- [ ] **Step 4: Regenerate the dummy schema and load the test database**

```bash
(cd test/dummy && bin/rails db:migrate)
git diff --stat test/dummy/db/schema.rb
git diff test/dummy/db/schema.rb
RAILS_ENV=test bin/rails db:schema:load
```
Expected diff: the `version:` line becomes `2026_10_11_120000` and a `create_table
"bali_archivals"` block with both indexes (`where: "unarchived_at IS NULL"` on the first) appears
in alphabetical position. Anything else in the diff is noise from a stale local database: restore
the file and redo from `bin/rails db:schema:load`. Never `db:prepare` (it clobbers schema.rb).

- [ ] **Step 5: Retire the counts that rot**

In `lib/bali/engine_migrations.rb`, the header says "Bali ships six" and "five tables it never
asked for", and `#install`'s comment says "identical to installing all six". Rewrite those
phrases without a number: "Bali ships one migration per feature and they are unrelated to each
other — an app that adopts saved views also gets every other feature's table it never asked for
in the `db/schema.rb` every one of its PRs reviews (#1079)." and "…identical to installing them
all." In `lib/tasks/bali_tasks.rake:5`, "copies the five migrations the engine ships" becomes
"copies every migration the engine ships". (The rake file's runtime notice already counts with
`features.size`.)

- [ ] **Step 6: Run the tests**

Run: `bin/rails test test/bali/engine_migrations_test.rb test/dummy_schema_test.rb`
Expected: PASS. `DummySchemaTest` migrates a fresh database and compares the dump with the
committed schema.rb — a red here means Step 4's diff carried noise.

- [ ] **Step 7: Negative control**

`mv db/migrate/20261011120000_create_bali_archivals.rb <scratchpad>/` → the new test fails on its
`assert_includes`; move it back.

- [ ] **Step 8: Commit**

```bash
git add db/migrate/20261011120000_create_bali_archivals.rb test/dummy/db/schema.rb \
  lib/bali/engine_migrations.rb lib/tasks/bali_tasks.rake test/bali/engine_migrations_test.rb
git commit -m "feat(archivable): tabla bali_archivals y su instalador por feature (#721)"
```

---

### Task 3: `Bali::Archival` and the `Bali::Archivable` concern

**Files:**
- Create: `app/models/bali/archival.rb`
- Create: `app/models/bali/archivable.rb`
- Create: `test/support/archivable_declaration.rb`
- Modify: `test/test_helper.rb:16` (require the support file)
- Modify: `test/dummy/app/models/movie.rb` (adopt the concern)
- Modify: `config/locales/bali_view.en.yml`, `config/locales/bali_view.es.yml`
- Test: `test/bali/models/archivable_test.rb`

**Interfaces:**
- Consumes: Task 2's table.
- Produces (later tasks rely on these exact names):
  - `Bali::Archivable::DEFAULT_REASONS` (Array<String>), `AlreadyArchived`, `NotArchived`,
    `NotReversible` (StandardError subclasses).
  - Class macro `archivable(reasons: DEFAULT_REASONS, successor_required_for: [], reversible: false)`.
  - Class attributes (instance readers too): `archival_reasons` (Array<String>),
    `archival_successor_required_for` (Array<String>), `archival_reversible` (Boolean).
  - Class methods `archived`, `not_archived` (relations), `archival_reason_label(reason) -> String`.
  - Associations `archivals` (newest first, `dependent: :destroy`), `archival` (has_one, current).
  - Instance `archived? -> Boolean`, `archive!(by: nil, reason: nil, note: nil, successor: nil) ->
    Bali::Archival`, `unarchive!(by: nil) -> Bali::Archival`.
  - `Bali::Archival::NOTE_MAX_LENGTH = 500`, scope `current`, `#reason_label -> String|nil`,
    `Bali::Archival.name_of(record) -> String`.
  - Locale keys `bali_view.archivals.reasons.<reason>` and
    `activerecord.attributes.bali/archival.{reason,successor_id,note}`.
  - Test helper `ArchivableDeclaration#with_archivable(**declaration) { }` (on `Movie`).
  - Dummy `Movie`: `archivable successor_required_for: %i[replaced], reversible: true`.

- [ ] **Step 1: Write the test support helper**

`test/support/archivable_declaration.rb`:

```ruby
# frozen_string_literal: true

# The dummy's Movie declares itself reversible with `successor_required_for: %i[replaced]`. A test
# that needs another declaration takes it for its block; the dummy's comes back afterwards.
module ArchivableDeclaration
  ATTRIBUTES = %i[archival_reasons archival_successor_required_for archival_reversible].freeze

  def with_archivable(**declaration)
    saved = ATTRIBUTES.to_h { |name| [ name, Movie.public_send(name) ] }
    Movie.archivable(**declaration)
    yield
  ensure
    saved.each { |name, value| Movie.public_send(:"#{name}=", value) }
  end
end
```

In `test/test_helper.rb`, after `require_relative "support/component_test_helpers"`:

```ruby
require_relative "support/archivable_declaration"
```

- [ ] **Step 2: Write the failing tests**

`test/bali/models/archivable_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

# #721 — archiving a host record. The dummy's Movie adopts the concern, so these tests exercise the
# adoption a host is asked for.
class BaliArchivableTest < ActiveSupport::TestCase
  include ArchivableDeclaration

  def setup
    studio = Tenant.create!(name: "Studio")
    @movie = studio.movies.create!(name: "Blade Runner", status: 0)
    @remake = studio.movies.create!(name: "Blade Runner 2049", status: 0)
    @ana = User.create!(name: "Ana")
  end

  def test_archive_records_who_why_and_what_replaces_it
    archival = @movie.archive!(by: @ana, reason: :replaced, note: "Remastered", successor: @remake)

    assert @movie.archived?
    assert_equal archival, @movie.archival
    assert_equal [ @ana, "replaced", "Remastered", @remake ],
                 [ archival.archived_by, archival.reason, archival.note, archival.successor ]
  end

  def test_archiving_twice_raises_already_archived
    @movie.archive!(by: @ana)

    assert_raises(Bali::Archivable::AlreadyArchived) { @movie.archive!(by: @ana) }
    assert_equal 1, @movie.archivals.count
  end

  # Two requests that both read "not archived" before either writes.
  def test_a_concurrent_archival_raises_already_archived
    stale = Movie.find(@movie.id)
    refute stale.archived?
    @movie.archive!(by: @ana)

    assert_raises(Bali::Archivable::AlreadyArchived) { stale.archive!(by: @ana) }
  end

  def test_a_reason_outside_the_models_list_is_invalid
    error = assert_raises(ActiveRecord::RecordInvalid) { @movie.archive!(reason: :misfiled) }

    assert_includes error.record.errors.attribute_names, :reason
    refute @movie.archived?
  end

  def test_a_reason_that_needs_a_successor_is_invalid_without_one
    error = assert_raises(ActiveRecord::RecordInvalid) { @movie.archive!(reason: :replaced) }

    assert_includes error.record.errors.attribute_names, :successor_id
  end

  def test_a_record_cannot_succeed_itself
    error = assert_raises(ActiveRecord::RecordInvalid) do
      @movie.archive!(reason: :replaced, successor: @movie)
    end

    assert_includes error.record.errors.attribute_names, :successor_id
  end

  def test_the_note_is_at_most_500_characters
    error = assert_raises(ActiveRecord::RecordInvalid) { @movie.archive!(note: "a" * 501) }

    assert_includes error.record.errors.attribute_names, :note
    assert_predicate @remake.archive!(note: "a" * 500), :persisted?
  end

  def test_unarchive_on_an_irreversible_model_raises_not_reversible
    @movie.archive!(by: @ana)

    with_archivable(successor_required_for: %i[replaced]) do
      assert_raises(Bali::Archivable::NotReversible) { @movie.unarchive!(by: @ana) }
    end
    assert @movie.reload.archived?
  end

  def test_unarchive_without_a_current_archival_raises_not_archived
    assert_raises(Bali::Archivable::NotArchived) { @movie.unarchive!(by: @ana) }
  end

  def test_reopening_keeps_the_archival_as_history
    first = @movie.archive!(by: @ana, reason: :expired)
    @movie.unarchive!(by: @ana)

    refute @movie.archived?
    assert_equal @ana, first.reload.unarchived_by
    assert_not_nil first.unarchived_at

    travel 1.minute
    second = @movie.archive!(by: @ana, reason: :other)
    assert_equal [ second, first ], @movie.archivals.to_a
  end

  # Reopening is not a new decision: a reason the model retired since must not block it.
  def test_reopening_an_archival_whose_reason_was_retired
    @movie.archive!(by: @ana, reason: :expired)

    with_archivable(reasons: %w[other], reversible: true) do
      assert_nothing_raised { @movie.unarchive!(by: @ana) }
    end
  end

  def test_scopes_split_records_by_their_current_archival
    reopened = @movie.studio.movies.create!(name: "Alien", status: 0)
    @movie.archive!(by: @ana)
    reopened.archive!(by: @ana)
    reopened.unarchive!(by: @ana)

    assert_equal [ @movie.id ], Movie.archived.ids
    assert_equal [ @remake.id, reopened.id ].sort, Movie.not_archived.ids.sort
  end

  def test_scopes_chain_with_other_conditions
    @movie.archive!(by: @ana)

    assert_equal [ @movie.id ], Movie.where(name: "Blade Runner").archived.ids
    assert_empty Movie.where(name: "Blade Runner").not_archived
  end

  def test_the_database_refuses_two_current_archivals
    Bali::Archival.create!(archivable: @movie)

    assert_raises(ActiveRecord::RecordNotUnique) { Bali::Archival.create!(archivable: @movie) }
  end

  def test_reason_label_reads_the_models_own_key_before_balis
    archival = @movie.archive!(reason: :expired)
    assert_equal "Expired", archival.reason_label

    I18n.backend.store_translations(:en, activerecord: { archival_reasons: { movie: { expired: "Out of rights" } } })
    assert_equal "Out of rights", archival.reason_label
  ensure
    I18n.backend.reload!
  end

  def test_the_macro_with_no_arguments_takes_every_default
    with_archivable do
      assert_equal Bali::Archivable::DEFAULT_REASONS, Movie.archival_reasons
      assert_empty Movie.archival_successor_required_for
      refute Movie.archival_reversible
    end
  end

  def test_name_of_prefers_title_then_name
    assert_equal "Blade Runner", Bali::Archival.name_of(@movie)
    assert_equal "Ana", Bali::Archival.name_of(@ana)
  end
end
```

- [ ] **Step 3: Run them to verify they fail**

Run: `bin/rails test test/bali/models/archivable_test.rb`
Expected: every test ERRORs — `undefined method 'archive!' for an instance of Movie`,
`uninitialized constant Bali::Archivable` or `Bali::Archival`. That is the "code does not exist"
failure; each test's own reason is checked by the negative controls of Step 8.

- [ ] **Step 4: Write `Bali::Archival`**

`app/models/bali/archival.rb`:

```ruby
# frozen_string_literal: true

module Bali
  # #721 — one archival of ANY host record. Created through Bali::Archivable#archive!, which knows
  # the archived model's reasons. On a reversible model a reopened row stays, as history.
  class Archival < ApplicationRecord
    NOTE_MAX_LENGTH = 500

    belongs_to :archivable, polymorphic: true
    belongs_to :archived_by, polymorphic: true, optional: true
    belongs_to :successor, polymorphic: true, optional: true
    belongs_to :unarchived_by, polymorphic: true, optional: true

    scope :current, -> { where(unarchived_at: nil) }

    # On create only: they judge the decision to archive. Reopening an archival whose reason the
    # model has retired since must not fail on it.
    validates :reason, inclusion: { in: ->(archival) { archival.archivable.try(:archival_reasons).to_a } },
                       allow_blank: true, on: :create
    validates :successor_id, presence: true, on: :create, if: :successor_required?
    validate :successor_is_another_record, on: :create
    validates :note, length: { maximum: NOTE_MAX_LENGTH }

    # The form lists successors and the notice names the successor and who archived — host
    # records Bali knows nothing about — by the first of `title` and `name` they answer.
    def self.name_of(record)
      record.try(:title).presence || record.try(:name).presence || "##{record.id}"
    end

    def reason_label
      archivable.class.archival_reason_label(reason) if reason.present?
    end

    private

    def successor_required?
      archivable.try(:archival_successor_required_for).to_a.include?(reason)
    end

    def successor_is_another_record
      errors.add(:successor_id, :invalid) if successor.present? && successor == archivable
    end
  end
end
```

Errors land on `:successor_id`, not `:successor`, because the form's control is `successor_id`
and the FormBuilder shows a field's errors by its own method name.

- [ ] **Step 5: Write `Bali::Archivable`**

`app/models/bali/archivable.rb`:

```ruby
# frozen_string_literal: true

module Bali
  # #721 — archiving for a host model:
  #
  #   class Document < ApplicationRecord
  #     include Bali::Archivable
  #     archivable successor_required_for: %i[replaced]
  #   end
  #
  #   document.archive!(by: user, reason: :replaced, successor: other)
  #   Document.not_archived
  #
  # The macro is optional: `include` alone takes the five default reasons, none needing a
  # successor, and makes the model irreversible.
  #
  # One model cannot include this and an `Archivable` of its own: both define `archive!` and
  # `archived?`.
  module Archivable
    extend ActiveSupport::Concern

    DEFAULT_REASONS = %w[replaced no_longer_applicable superseded expired other].freeze

    class AlreadyArchived < StandardError; end
    class NotArchived < StandardError; end
    class NotReversible < StandardError; end

    included do
      class_attribute :archival_reasons, instance_writer: false, default: DEFAULT_REASONS
      class_attribute :archival_successor_required_for, instance_writer: false, default: [].freeze
      class_attribute :archival_reversible, instance_writer: false, default: false

      has_many :archivals, -> { order(created_at: :desc, id: :desc) },
               class_name: "Bali::Archival", as: :archivable, inverse_of: :archivable,
               dependent: :destroy
      has_one :archival, -> { current }, class_name: "Bali::Archival", as: :archivable,
                                         inverse_of: :archivable
    end

    class_methods do
      def archivable(reasons: DEFAULT_REASONS, successor_required_for: [], reversible: false)
        self.archival_reasons = reasons.map(&:to_s).freeze
        self.archival_successor_required_for = successor_required_for.map(&:to_s).freeze
        self.archival_reversible = reversible
      end

      def archived = where(current_archivals.arel.exists)

      def not_archived = where(current_archivals.arel.exists.not)

      # A host relabels a reason for one model under `activerecord.archival_reasons.<model>`.
      def archival_reason_label(reason)
        I18n.t(reason, scope: [ :activerecord, :archival_reasons, model_name.i18n_key ],
                       default: :"bali_view.archivals.reasons.#{reason}")
      end

      private

      def current_archivals
        Bali::Archival.current
                      .where(archivable_type: polymorphic_name)
                      .where(Bali::Archival.arel_table[:archivable_id].eq(arel_table[primary_key]))
      end
    end

    def archived? = archival.present?

    def archive!(by: nil, reason: nil, note: nil, successor: nil)
      raise AlreadyArchived if archived?

      archivals.create!(archived_by: by, reason: reason, note: note, successor: successor)
               .tap { reset_archival }
    rescue ActiveRecord::RecordNotUnique
      raise AlreadyArchived
    end

    def unarchive!(by: nil)
      raise NotReversible unless archival_reversible
      raise NotArchived unless archived?

      archival.tap do |current|
        current.update!(unarchived_at: Time.current, unarchived_by: by)
        reset_archival
      end
    end
  end
end
```

`reset_archival` (Rails ≥ 7.1, generated for singular associations) drops the cached `has_one`
so `archived?` reads the row just written or just reopened.

- [ ] **Step 6: Adopt it in the dummy and add the locale keys**

`test/dummy/app/models/movie.rb`, after `has_many :characters, dependent: :destroy`:

```ruby
  # Reversible so the dummy shows the Reopen half of the notice, which gobierno-corporativo —
  # irreversible, the default — never renders.
  include Bali::Archivable
  archivable successor_required_for: %i[replaced], reversible: true
```

`config/locales/bali_view.en.yml` — a new `activerecord` root as a sibling of `bali_view` under
`en:`, and an `archivals` block inside `bali_view` (place it after `content_versions`):

```yaml
en:
  activerecord:
    attributes:
      bali/archival:
        reason: "Reason"
        successor_id: "Successor"
        note: "Note"
  bali_view:
    # ...existing keys...
    archivals:
      new:
        title: "Archive"
      reasons:
        replaced: "Replaced by another"
        no_longer_applicable: "No longer applicable"
        superseded: "Superseded by a new regulation"
        expired: "Expired"
        other: "Other reason"
```

`config/locales/bali_view.es.yml`, same shape:

```yaml
es:
  activerecord:
    attributes:
      bali/archival:
        reason: "Motivo"
        successor_id: "Sucesor"
        note: "Nota"
  bali_view:
    # ...existing keys...
    archivals:
      new:
        title: "Dar de baja"
      reasons:
        replaced: "Reemplazado por otro"
        no_longer_applicable: "Ya no aplica"
        superseded: "Superado por nueva regulación"
        expired: "Vigencia expirada"
        other: "Otro motivo"
```

(The es reasons are GC's labels, except `replaced`, which GC words "Reemplazado por otro
documento" and keeps as its own override in Task 14.)

- [ ] **Step 7: Run the tests to verify they pass**

Run: `bin/rails test test/bali/models/archivable_test.rb test/bali/i18n_scope_test.rb`
Expected: PASS.

- [ ] **Step 8: Negative controls** — one at a time, each from a backup copy, each failing on the
  named test's own assertion:

| Remove / change | Test that must fail | Expected message |
|---|---|---|
| `rescue ActiveRecord::RecordNotUnique` + its `raise` in `archive!` | `test_a_concurrent_archival_raises_already_archived` | `[Bali::Archivable::AlreadyArchived] exception expected, not ActiveRecord::RecordNotUnique` |
| `raise AlreadyArchived if archived?` | `test_archiving_twice_raises_already_archived` | same shape, `RecordNotUnique` |
| the `validates :reason` line | `test_a_reason_outside_the_models_list_is_invalid` | `ActiveRecord::RecordInvalid expected but nothing was raised` |
| `on: :create` on the reason validation | `test_reopening_an_archival_whose_reason_was_retired` | `assert_nothing_raised` reports `RecordInvalid` |
| the `validates :successor_id` line | `test_a_reason_that_needs_a_successor_is_invalid_without_one` | nothing was raised |
| `validate :successor_is_another_record` | `test_a_record_cannot_succeed_itself` | nothing was raised |
| `validates :note` | `test_the_note_is_at_most_500_characters` | nothing was raised |
| `.not` in `not_archived` | `test_scopes_split_records_by_their_current_archival` | `Expected [..] to be equal to [..]` |
| `-> { current }` on `has_one :archival` | `test_reopening_keeps_the_archival_as_history` | `Expected true to not be truthy` (`refute @movie.archived?`) |
| `raise NotReversible unless archival_reversible` | `test_unarchive_on_an_irreversible_model_raises_not_reversible` | nothing was raised |
| `unique: true` in the migration (then `RAILS_ENV=test bin/rails db:schema:load` after hand-editing schema.rb the same way; restore both and reload after) | `test_the_database_refuses_two_current_archivals` | nothing was raised |

- [ ] **Step 9: Commit**

```bash
git add app/models/bali/archival.rb app/models/bali/archivable.rb test/support/archivable_declaration.rb \
  test/test_helper.rb test/dummy/app/models/movie.rb config/locales/bali_view.en.yml \
  config/locales/bali_view.es.yml test/bali/models/archivable_test.rb
git commit -m "feat(archivable): Bali::Archival y el concern Bali::Archivable (#721)"
```

---

### Task 4: `Bali::ArchivalForm::Component`

**Files:**
- Create: `app/components/bali/archival_form/component.rb`
- Create: `app/components/bali/archival_form/component.html.erb`
- Create: `app/components/bali/archival_form/preview.rb`
- Modify: `config/locales/bali_view.en.yml`, `config/locales/bali_view.es.yml`
- Test: `test/bali/components/archival_form_test.rb`

**Interfaces:**
- Consumes: Task 3's `archival_reasons`, `archival_successor_required_for`,
  `archival_reason_label`, `Bali::Archival.name_of`, `NOTE_MAX_LENGTH`.
- Produces: `Bali::ArchivalForm::Component.new(record:, successors:, url:, return_to: nil,
  archival: nil)` — posts `archival[reason]`, `archival[successor_id]`, `archival[note]` and a
  top-level `return_to`; submit wired to `drawer#submit`. Task 6's view renders it.

`archival:` is the one keyword the spec's signature lacks: the `422` re-render the spec requires
needs the invalid archival, with its errors and the person's choice. Default: a new archival.

- [ ] **Step 1: Write the failing tests**

`test/bali/components/archival_form_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class BaliArchivalFormComponentTest < ComponentTestCase
  def setup
    studio = Tenant.create!(name: "Studio")
    @movie = studio.movies.create!(name: "Blade Runner", status: 0)
    @remake = studio.movies.create!(name: "Blade Runner 2049", status: 0)
  end

  def test_offers_every_reason_with_its_label
    render_form

    Bali::Archivable::DEFAULT_REASONS.each do |reason|
      assert_selector "input[type=radio][name='archival[reason]'][value='#{reason}']"
    end
    assert_selector "label", text: "Replaced by another"
  end

  def test_the_successor_is_revealed_by_radio_toggle_for_the_reasons_that_need_one
    render_form

    assert_selector "form[data-controller='radio-toggle'][data-radio-toggle-disable-hidden-value='true']"
    assert_selector "input[name='archival[reason]'][data-action*='radio-toggle#change']", count: 5
    assert_selector "fieldset[data-radio-toggle-target='element'][data-radio-toggle-value='replaced'] " \
                    "select[name='archival[successor_id]'] option[value='#{@remake.id}']",
                    text: "Blade Runner 2049"
  end

  def test_without_candidates_neither_the_successor_nor_its_reasons_are_offered
    [ nil, Movie.none ].each do |successors|
      render_form(successors: successors)

      assert_no_selector "input[name='archival[reason]'][value='replaced']"
      assert_no_selector "select[name='archival[successor_id]']"
      assert_selector "input[name='archival[reason]']", count: 4
    end
  end

  def test_return_to_travels_with_the_form
    render_form(return_to: "/admin/movies")

    assert_selector "input[type=hidden][name=return_to][value='/admin/movies']", visible: :all
  end

  def test_re_renders_an_invalid_archival_with_its_choice_and_its_error
    archival = Bali::Archival.new(archivable: @movie, reason: "replaced", note: "No successor yet")
    archival.validate
    render_form(archival: archival)

    assert_selector "input[name='archival[reason]'][value='replaced'][checked]"
    assert_selector "form[data-radio-toggle-current-value='replaced']"
    assert_selector "textarea[name='archival[note]'][maxlength='500']", text: "No successor yet"
    assert_selector "#archival_successor_id_error", text: "Successor can't be blank"
  end

  def test_submits_through_the_drawer
    render_form

    assert_selector "button[type=submit][data-action*='drawer#submit']"
  end

  private

  def render_form(successors: Movie.where.not(id: @movie.id), **options)
    render_inline(Bali::ArchivalForm::Component.new(
      record: @movie, successors: successors,
      url: "/bali/archivals?record_type=Movie&record_id=#{@movie.id}", **options
    ))
  end
end
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bin/rails test test/bali/components/archival_form_test.rb`
Expected: ERROR — `uninitialized constant Bali::ArchivalForm`.

- [ ] **Step 3: Write the component**

`app/components/bali/archival_form/component.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module ArchivalForm
    class Component < ApplicationViewComponent
      # @param record [ActiveRecord::Base] the record to archive; includes Bali::Archivable
      # @param successors [ActiveRecord::Relation, nil] the records that may replace it
      # @param url [String] where the form posts
      # @param return_to [String, nil] the path the engine redirects to afterwards
      # @param archival [Bali::Archival, nil] an invalid archival to re-render with its errors
      def initialize(record:, successors:, url:, return_to: nil, archival: nil)
        @record = record
        @successors = successors
        @url = url
        @return_to = return_to
        @archival = archival || Bali::Archival.new(archivable: record)
      end

      private

      attr_reader :url, :return_to, :archival

      def reason_options
        reasons.map { |reason| [ @record.class.archival_reason_label(reason), reason ] }
      end

      # With no candidates, a reason that needs a successor could never be submitted valid.
      def reasons
        return @record.archival_reasons unless @successors.blank?

        @record.archival_reasons - @record.archival_successor_required_for
      end

      def successor_field?
        @successors.present? && @record.archival_successor_required_for.any?
      end

      def successor_reasons = @record.archival_successor_required_for.join(",")

      def successor_options
        @successors.map { |successor| [ Bali::Archival.name_of(successor), successor.id ] }
      end
    end
  end
end
```

`app/components/bali/archival_form/component.html.erb`:

```erb
<%= form_with model: archival, scope: :archival, url: url, method: :post,
              builder: Bali::FormBuilder,
              data: { controller: "radio-toggle",
                      radio_toggle_current_value: archival.reason,
                      radio_toggle_disable_hidden_value: true } do |form| %>
  <%= hidden_field_tag :return_to, return_to if return_to.present? %>

  <%= form.radio_group :reason, reason_options,
        html: { data: { action: "radio-toggle#change" } } %>

  <% if successor_field? %>
    <fieldset data-radio-toggle-target="element" data-radio-toggle-value="<%= successor_reasons %>">
      <%= form.select_group :successor_id, successor_options, include_blank: true %>
    </fieldset>
  <% end %>

  <%= form.text_area_group :note, maxlength: Bali::Archival::NOTE_MAX_LENGTH %>

  <%# The engine serves this form as a drawer body. Rendered on a page, `drawer#submit` finds no
      panel and degrades to a plain submit (#984). %>
  <%= form.submit_group t(".submit"), drawer: true %>
<% end %>
```

Locale keys (both files, inside `bali_view`):

```yaml
    archival_form:
      submit: "Archive"        # es: "Dar de baja"
```

- [ ] **Step 4: Write the preview**

`app/components/bali/archival_form/preview.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module ArchivalForm
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Every reason is offered; "Replaced by another" reveals the successor.
      def default
        render Bali::ArchivalForm::Component.new(
          record: Movie.new(name: "Blade Runner"),
          successors: Movie.order(:name).limit(10),
          url: "/lookbook"
        )
      end

      # @label Without successors
      # The model has no candidates, so the reasons that need one are not offered.
      def without_successors
        render Bali::ArchivalForm::Component.new(
          record: Movie.new(name: "Blade Runner"), successors: nil, url: "/lookbook"
        )
      end
    end
  end
end
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `bin/rails test test/bali/components/archival_form_test.rb test/bali/i18n_scope_test.rb test/bali/i18n_usage_test.rb`
Expected: PASS.

- [ ] **Step 6: Negative controls**

| Remove / change | Test that must fail |
|---|---|
| the `return … unless @successors.blank?` branch (always subtract) | `test_offers_every_reason_with_its_label` (no `replaced` radio) |
| `@successors.present? &&` in `successor_field?` | `test_without_candidates_neither_the_successor_nor_its_reasons_are_offered` |
| `radio_toggle_disable_hidden_value: true` | `test_the_successor_is_revealed_by_radio_toggle_for_the_reasons_that_need_one` |
| the `hidden_field_tag` line | `test_return_to_travels_with_the_form` |
| `archival || ` in `initialize` (always a new archival) | `test_re_renders_an_invalid_archival_with_its_choice_and_its_error` |
| `drawer: true` on `submit_group` | `test_submits_through_the_drawer` |

Each must fail on its `assert_selector`/`assert_no_selector` ("expected to find …"), not on an
error.

- [ ] **Step 7: Commit**

```bash
git add app/components/bali/archival_form config/locales/bali_view.en.yml config/locales/bali_view.es.yml \
  test/bali/components/archival_form_test.rb
git commit -m "feat(archivable): Bali::ArchivalForm, el formulario del drawer (#721)"
```

---

### Task 5: `Bali::ArchivalNotice::Component`

**Files:**
- Create: `app/components/bali/archival_notice/component.rb`
- Create: `app/components/bali/archival_notice/component.html.erb`
- Create: `app/components/bali/archival_notice/preview.rb`
- Modify: `config/locales/bali_view.en.yml`, `config/locales/bali_view.es.yml`
- Test: `test/bali/components/archival_notice_test.rb`
- Test: `test/requests/archival_previews_test.rb` (covers Task 4's preview too)

**Interfaces:**
- Consumes: Task 3's `archival`, `reason_label`, `name_of`.
- Produces: `Bali::ArchivalNotice::Component.new(record:, successor_url: nil, unarchive_url: nil,
  **options)` — root `.archival-notice-component` on a `Bali::Alert` (`color: :warning`); the
  Reopen form posts to `unarchive_url`. Task 7 and GC (Task 14) render it.

`Bali::Notification`, which the spec names, is deprecated (removed in 4.0), warns on every
construction and is a floating toast. The inline alert it was split from is `Bali::Alert`, which
GC already uses for this banner — the notice composes on that.

- [ ] **Step 1: Write the failing tests**

`test/bali/components/archival_notice_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class BaliArchivalNoticeComponentTest < ComponentTestCase
  def setup
    studio = Tenant.create!(name: "Studio")
    @movie = studio.movies.create!(name: "Blade Runner", status: 0)
    @remake = studio.movies.create!(name: "Blade Runner 2049", status: 0)
    @ana = User.create!(name: "Ana")
  end

  def test_renders_nothing_for_a_record_that_is_not_archived
    render_inline(Bali::ArchivalNotice::Component.new(record: @movie))

    assert_no_selector ".archival-notice-component"
  end

  def test_says_when_who_why_and_what_replaces_it
    archive_on_october_third(by: @ana, reason: :replaced, successor: @remake)
    render_inline(Bali::ArchivalNotice::Component.new(record: @movie, successor_url: "/movies/#{@remake.id}"))

    assert_selector ".archival-notice-component.alert.alert-warning",
                    text: "Archived on October 03, 2026 by Ana. Reason: Replaced by another. " \
                          "Replaced by Blade Runner 2049."
    assert_link "Blade Runner 2049", href: "/movies/#{@remake.id}"
  end

  def test_names_the_successor_without_a_link_when_no_url_is_given
    archive_on_october_third(reason: :replaced, successor: @remake)
    render_inline(Bali::ArchivalNotice::Component.new(record: @movie))

    assert_text "Replaced by Blade Runner 2049."
    assert_no_link "Blade Runner 2049"
  end

  def test_leaves_out_what_was_not_recorded
    archive_on_october_third
    render_inline(Bali::ArchivalNotice::Component.new(record: @movie))

    assert_selector ".archival-notice-component", exact_text: "Archived on October 03, 2026."
  end

  def test_reopen_appears_only_with_an_unarchive_url
    @movie.archive!(by: @ana)

    render_inline(Bali::ArchivalNotice::Component.new(record: @movie))
    assert_no_button "Reopen"

    render_inline(Bali::ArchivalNotice::Component.new(record: @movie, unarchive_url: "/bali/archivals/unarchive"))
    assert_selector "form[action='/bali/archivals/unarchive'][method=post] button[type=submit]", text: "Reopen"
  end

  def test_a_reopened_record_shows_no_notice
    @movie.archive!(by: @ana)
    @movie.unarchive!(by: @ana)
    render_inline(Bali::ArchivalNotice::Component.new(record: @movie))

    assert_no_selector ".archival-notice-component"
  end

  def test_reads_as_the_spec_wrote_it_in_spanish
    archive_on_october_third(by: @ana, reason: :replaced, successor: @remake)
    I18n.with_locale(:es) { render_inline(Bali::ArchivalNotice::Component.new(record: @movie)) }

    assert_text "Dado de baja el 03 de Octubre de 2026 por Ana. Motivo: Reemplazado por otro. " \
                "Lo sustituye Blade Runner 2049."
  end

  def test_options_reach_the_alert
    @movie.archive!
    render_inline(Bali::ArchivalNotice::Component.new(record: @movie, class: "mt-4", data: { hook: "" }))

    assert_selector ".archival-notice-component.mt-4[data-hook]"
  end

  private

  def archive_on_october_third(**archival)
    travel_to(Time.zone.local(2026, 10, 3, 9)) { @movie.archive!(**archival) }
  end
end
```

(`03 de Octubre` is the dummy's own `es.date` — `%d de %B de %Y`, capitalised month names.)

- [ ] **Step 2: Run them to verify they fail**

Run: `bin/rails test test/bali/components/archival_notice_test.rb`
Expected: ERROR — `uninitialized constant Bali::ArchivalNotice`.

- [ ] **Step 3: Write the component**

`app/components/bali/archival_notice/component.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module ArchivalNotice
    class Component < ApplicationViewComponent
      BASE_CLASSES = "archival-notice-component"

      # @param record [ActiveRecord::Base] a record that includes Bali::Archivable
      # @param successor_url [String, nil] links the successor's name when given
      # @param unarchive_url [String, nil] shows "Reopen", which posts here. Pass it only when the
      #   model is reversible and the person may reopen.
      def initialize(record:, successor_url: nil, unarchive_url: nil, **options)
        @archival = record.archival
        @successor_url = successor_url
        @unarchive_url = unarchive_url
        @options = prepend_class_name(options, BASE_CLASSES)
      end

      def render? = @archival.present?

      private

      attr_reader :archival, :unarchive_url, :options

      def summary
        safe_join([ archived_sentence, reason_sentence, successor_sentence ].compact, " ")
      end

      def archived_sentence
        date = l(archival.created_at.to_date, format: :long)
        return t(".archived", date: date) if archival.archived_by.nil?

        t(".archived_by", date: date, name: Bali::Archival.name_of(archival.archived_by))
      end

      def reason_sentence
        t(".reason", reason: archival.reason_label) if archival.reason.present?
      end

      def successor_sentence
        successor = archival.successor
        return if successor.nil?

        name = Bali::Archival.name_of(successor)
        name = render(Bali::Link::Component.new(name: name, href: @successor_url)) if @successor_url
        t(".successor_html", successor: name)
      end
    end
  end
end
```

`app/components/bali/archival_notice/component.html.erb`:

```erb
<%= render Bali::Alert::Component.new(color: :warning, icon: "archive", **options) do %>
  <div class="flex flex-wrap items-center gap-x-4 gap-y-2">
    <p><%= summary %></p>
    <% if unarchive_url %>
      <%= form_with url: unarchive_url, method: :post do %>
        <%= render Bali::Button::Component.new(name: t(".reopen"), type: :submit, size: :sm) %>
      <% end %>
    <% end %>
  </div>
<% end %>
```

The Reopen button is Bali's default (filled `base-200`, `base-content` text): an outline or ghost
button would paint `base-content` straight onto the warning fill, which in `afal-dark` is light on
yellow. The successor link has no variant, so it inherits the alert's own text colour.

Locale keys (inside `bali_view`):

```yaml
# en
    archival_notice:
      archived: "Archived on %{date}."
      archived_by: "Archived on %{date} by %{name}."
      reason: "Reason: %{reason}."
      successor_html: "Replaced by %{successor}."
      reopen: "Reopen"
# es
    archival_notice:
      archived: "Dado de baja el %{date}."
      archived_by: "Dado de baja el %{date} por %{name}."
      reason: "Motivo: %{reason}."
      successor_html: "Lo sustituye %{successor}."
      reopen: "Reabrir"
```

- [ ] **Step 4: Write the preview**

`app/components/bali/archival_notice/preview.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module ArchivalNotice
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # @param reason select { choices: [replaced, no_longer_applicable, superseded, expired, other] }
      def default(reason: "replaced")
        movie = archived_movie(reason: reason, by: User.new(name: "Ana García"),
                               successor: Movie.new(name: "Blade Runner 2049"))
        render Bali::ArchivalNotice::Component.new(record: movie, successor_url: "/lookbook")
      end

      # @label Minimal
      # Only the date was recorded: no person, no reason, no successor.
      def minimal
        render Bali::ArchivalNotice::Component.new(record: archived_movie)
      end

      # @label Reopenable
      # A reversible model and a person allowed to reopen: the host passes `unarchive_url:`.
      def reopenable
        movie = archived_movie(reason: "expired", by: User.new(name: "Ana García"))
        render Bali::ArchivalNotice::Component.new(record: movie, unarchive_url: "/lookbook")
      end

      private

      def archived_movie(reason: nil, by: nil, successor: nil)
        Movie.new(name: "Blade Runner").tap do |movie|
          movie.archival = Bali::Archival.new(reason: reason, archived_by: by, successor: successor,
                                              created_at: Time.zone.local(2026, 10, 3, 9))
        end
      end
    end
  end
end
```

- [ ] **Step 5: Write the preview request test**

`test/requests/archival_previews_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

# Component tests render classes, not previews: a preview that 500s stays green everywhere else.
class ArchivalPreviewsTest < ActionDispatch::IntegrationTest
  SCENARIOS = %w[
    archival_form/default archival_form/without_successors
    archival_notice/default archival_notice/minimal archival_notice/reopenable
  ].freeze

  def setup
    Tenant.create!(name: "Studio").movies.create!(name: "Blade Runner 2049", status: 0)
  end

  def test_every_archival_preview_renders
    SCENARIOS.each do |scenario|
      get "/lookbook/preview/bali/#{scenario}"
      assert_response :ok, scenario
    end
  end
end
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `bin/rails test test/bali/components/archival_notice_test.rb test/requests/archival_previews_test.rb test/requests/icon_previews_test.rb test/bali/i18n_scope_test.rb test/bali/i18n_usage_test.rb`
Expected: PASS (`icon_previews_test` guards the fully-qualified constants in `preview.rb`).

- [ ] **Step 7: Negative controls**

| Remove / change | Test that must fail |
|---|---|
| `def render? = @archival.present?` | `test_renders_nothing_for_a_record_that_is_not_archived` |
| the `if @successor_url` on the link line | `test_names_the_successor_without_a_link_when_no_url_is_given` |
| `return t(".archived", …) if archival.archived_by.nil?` | `test_leaves_out_what_was_not_recorded` (errors on `name_of(nil)`: read it — the line under test is the guard, so an error IS the regression here) |
| `if archival.reason.present?` | `test_leaves_out_what_was_not_recorded` (`exact_text` mismatch) |
| `if unarchive_url` in the template | `test_reopen_appears_only_with_an_unarchive_url` |
| `**options` on the Alert | `test_options_reach_the_alert` |

- [ ] **Step 8: Commit**

```bash
git add app/components/bali/archival_notice config/locales/bali_view.en.yml config/locales/bali_view.es.yml \
  test/bali/components/archival_notice_test.rb test/requests/archival_previews_test.rb
git commit -m "feat(archivable): Bali::ArchivalNotice, el aviso del registro dado de baja (#721)"
```

---

### Task 6: `Bali::ArchivalsController`, routes and the four config entries

**Files:**
- Create: `app/controllers/bali/archivals_controller.rb`
- Create: `app/views/bali/archivals/new.html.erb`
- Modify: `lib/bali.rb` (after the `content_versions_author` entry, ~line 365)
- Modify: `config/routes.rb` (add the resource; translate the four existing Spanish comments
  while the file is open — `config/**` is outside RuboCop, so nothing else catches them)
- Modify: `test/dummy/config/initializers/bali.rb` (configure the dummy)
- Test: `test/requests/archivals_test.rb`

**Interfaces:**
- Consumes: Tasks 3–5.
- Produces: routes `bali.new_archival_path`, `bali.archivals_path`,
  `bali.unarchive_archivals_path` (all with `record_type:`, `record_id:`); config
  `Bali.archivables`, `Bali.archivals_authorize`, `Bali.archivals_actor`,
  `Bali.archival_successors`; ivars `@record` and `@archival` after `create` (GC's bali-analytics
  rule reads them, Task 14).

- [ ] **Step 1: Write the failing tests**

`test/requests/archivals_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

# #721 — Bali::ArchivalsController, configured the way a host does it (pattern from
# test/requests/content_versions_test.rb).
class BaliArchivalsRequestTest < ActionDispatch::IntegrationTest
  include ArchivableDeclaration

  CONFIG = %i[archivables archivals_authorize archivals_actor archival_successors].freeze

  def setup
    studio = Tenant.create!(name: "Studio")
    @movie = studio.movies.create!(name: "Blade Runner", status: 0)
    @remake = studio.movies.create!(name: "Blade Runner 2049", status: 0)
    @ana = User.create!(name: "Ana")

    @saved = CONFIG.to_h { |name| [ name, Bali.public_send(name) ] }
    Bali.archivables = { "Movie" => ->(_controller, id) { Movie.find_by(id: id) } }
    Bali.archivals_authorize = ->(_controller, _record, _action) { true }
    ana = @ana
    Bali.archivals_actor = ->(_controller) { ana }
    Bali.archival_successors = ->(_controller, movie) { Movie.where.not(id: movie.id) }
  end

  def teardown
    @saved.each { |name, value| Bali.public_send(:"#{name}=", value) }
  end

  def record_params = { record_type: "Movie", record_id: @movie.id }

  def movie_path = "/movies/#{@movie.id}"

  def test_new_serves_the_form_as_a_drawer_body
    get bali.new_archival_path(record_params.merge(return_to: "/admin/movies"))

    assert_response :success
    assert_select "html", false
    assert_select "h2", "Archive"
    assert_select "form[action=?]", bali.archivals_path(record_params)
    assert_select "input[name=return_to][value=?]", "/admin/movies"
  end

  def test_create_archives_as_the_actor_and_redirects_to_the_record
    post bali.archivals_path(record_params),
         params: { archival: { reason: "replaced", successor_id: @remake.id, note: "Remastered" } }

    assert_response :see_other
    assert_redirected_to movie_path
    archival = @movie.reload.archival
    assert_equal [ @ana, "replaced", @remake, "Remastered" ],
                 [ archival.archived_by, archival.reason, archival.successor, archival.note ]
  end

  def test_an_invalid_archival_re_renders_the_form_with_422_and_keeps_the_choice
    post bali.archivals_path(record_params), params: { archival: { reason: "replaced", note: "Soon" } }

    assert_response :unprocessable_entity
    assert_select "input[name='archival[reason]'][value=replaced][checked]"
    assert_select "#archival_successor_id_error", "Successor can't be blank"
    refute @movie.reload.archived?
  end

  def test_a_successor_outside_the_candidates_is_never_stored
    remake = @remake
    Bali.archival_successors = ->(_controller, movie) { Movie.where.not(id: [ movie.id, remake.id ]) }

    post bali.archivals_path(record_params), params: { archival: { reason: "replaced", successor_id: @remake.id } }

    assert_response :unprocessable_entity
    refute @movie.reload.archived?
  end

  def test_return_to_is_followed_only_when_it_is_a_path_of_this_app
    {
      "/admin/movies?page=2" => "/admin/movies?page=2",
      "//evil.example/movies" => movie_path,
      "https://evil.example/movies" => movie_path,
      "javascript:alert(1)" => movie_path
    }.each do |given, expected|
      post bali.unarchive_archivals_path(record_params), params: { return_to: given }
      assert_redirected_to expected, "return_to=#{given}"
    end
  end

  def test_archiving_an_archived_record_redirects_and_keeps_the_first_archival
    first = @movie.archive!(by: @ana, reason: :expired)

    post bali.archivals_path(record_params), params: { archival: { reason: "other" } }

    assert_redirected_to movie_path
    assert_equal [ first ], @movie.archivals.to_a
  end

  def test_unarchive_reopens_as_the_actor
    @movie.archive!(by: @ana)

    post bali.unarchive_archivals_path(record_params)

    assert_redirected_to movie_path
    refute @movie.reload.archived?
    assert_equal @ana, @movie.archivals.first.unarchived_by
  end

  def test_unarchive_on_an_irreversible_model_is_not_found
    @movie.archive!(by: @ana)

    with_archivable(successor_required_for: %i[replaced]) do
      post bali.unarchive_archivals_path(record_params)
    end

    assert_response :not_found
    assert @movie.reload.archived?
  end

  # Default-deny, layer 1: an empty whitelist is the factory setting.
  def test_a_record_type_outside_the_whitelist_is_not_found
    Bali.archivables = {}

    get bali.new_archival_path(record_params)
    assert_response :not_found
    post bali.archivals_path(record_params)
    assert_response :not_found
    post bali.unarchive_archivals_path(record_params)
    assert_response :not_found
  end

  def test_a_resolver_that_finds_nothing_is_not_found
    get bali.new_archival_path(record_type: "Movie", record_id: 0)

    assert_response :not_found
  end

  def test_a_whitelisted_model_without_the_concern_is_not_found
    studio = Studio.create!(name: "Never archived", country: "USA", status: :active)
    refute_kind_of Bali::Archivable, studio
    Bali.archivables = { "Studio" => ->(_controller, id) { Studio.find_by(id: id) } }

    get bali.new_archival_path(record_type: "Studio", record_id: studio.id)

    assert_response :not_found
  end

  # Default-deny, layer 2: the lambda lib/bali.rb ships, written out because the dummy opens it.
  def test_a_falsy_authorize_forbids_every_action
    Bali.archivals_authorize = ->(_controller, _record, _action) { false }

    get bali.new_archival_path(record_params)
    assert_response :forbidden
    assert_no_difference "Bali::Archival.count" do
      post bali.archivals_path(record_params), params: { archival: { reason: "expired" } }
    end
    assert_response :forbidden
    post bali.unarchive_archivals_path(record_params)
    assert_response :forbidden
  end

  def test_authorize_receives_the_action
    asked = []
    Bali.archivals_authorize = lambda do |_controller, _record, action|
      asked << action
      action == "new"
    end

    get bali.new_archival_path(record_params)
    post bali.archivals_path(record_params)
    post bali.unarchive_archivals_path(record_params)

    assert_equal %w[new create unarchive], asked
    assert_response :forbidden
  end

  # bali-analytics track rules read these two ivars: gobierno-corporativo's
  # `documentos.documento_archivado`. Renaming one switches that event off with no error.
  def test_create_leaves_the_record_and_the_new_archival_where_track_rules_read_them
    post bali.archivals_path(record_params), params: { archival: { reason: "expired" } }

    assert_equal @movie, controller.instance_variable_get(:@record)
    assert_predicate controller.instance_variable_get(:@archival), :previously_new_record?
  end
end
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bin/rails test test/requests/archivals_test.rb`
Expected: ERROR — `NoMethodError: undefined method 'archivables' for module Bali` (in `setup`).

- [ ] **Step 3: Add the config entries to `lib/bali.rb`** (after `content_versions_author`)

```ruby
  # Archivals (#721) — archiving and reopening a host record (`bali_archivals` table, installed
  # with `bin/rails bali:install:migrations:archivals`). Same two default-deny layers as content
  # versions.
  #
  # Whitelist of archivable models `Bali::ArchivalsController` accepts over HTTP: the key is the
  # `record_type` of the query string, the value a callable returning the record or nil. Empty by
  # default, so every `record_type` is a 404. Scope in the resolver: someone else's record is
  # then a 404, not a 403 that confirms it exists. The engine's controllers do not include
  # Pundit, so call it by its module.
  # Example: Bali.archivables = {
  #   "Document" => ->(controller, id) { Pundit.policy_scope!(controller.current_user, Document).find_by(id: id) }
  # }
  mattr_accessor :archivables, default: {}

  # Bali::ArchivalsController authorization: callable (controller, record, action) — truthy
  # allows, falsy answers 403. `action` is "new", "create" or "unarchive". Denies by default.
  # Example: ->(controller, record, _action) { Pundit.policy!(controller.current_user, record).archive? }
  mattr_accessor :archivals_authorize, default: ->(_controller, _record, _action) { false }

  # Who archives or reopens: callable (controller), stored as `archived_by` / `unarchived_by`.
  # Example: ->(controller) { controller.current_member }
  mattr_accessor :archivals_actor, default: ->(controller) { controller.try(:current_user) }

  # The records that may replace this one: callable (controller, record) returning a relation,
  # or nil when there is no successor. With nil (or an empty relation) the form offers neither
  # the successor nor the reasons that require one, so no one can reach an archival that fails
  # on submit.
  # Example: ->(controller, document) { Document.published.where.not(id: document.id) }
  mattr_accessor :archival_successors, default: ->(_controller, _record) { nil }
```

- [ ] **Step 4: Add the routes** — `config/routes.rb`, after the `content_versions` resource:

```ruby
  # #721 — the archived record travels in the query string, as in content versions.
  resources :archivals, only: %i[new create] do
    post :unarchive, on: :collection
  end
```

Translate the file's existing comments to English in the same edit (saved views, entity
references, content versions, block editor comments), keeping what each says.

- [ ] **Step 5: Write the controller**

`app/controllers/bali/archivals_controller.rb`:

```ruby
# frozen_string_literal: true

module Bali
  # #721 — archive and reopen a host record. The record arrives in the query string
  # (`?record_type=Document&record_id=7`) and two default-deny layers stand before every action,
  # as in Bali::ContentVersionsController: `Bali.archivables` (404) and
  # `Bali.archivals_authorize` (403). `@record` and `@archival` are read by hosts' bali-analytics
  # track rules after `create`.
  class ArchivalsController < ApplicationController
    # The form is a drawer body. This controller inherits Bali::ApplicationController, not the
    # host's, so the host's layout — its helpers, its unprefixed routes — cannot render here.
    layout false

    before_action :set_record
    before_action :authorize_archivals!
    before_action :set_successors, only: %i[new create]

    def new
      @archival = Bali::Archival.new(archivable: @record)
    end

    def create
      @archival = @record.archive!(by: actor, **archival_params)
      redirect_to return_path, status: :see_other
    rescue ActiveRecord::RecordInvalid => error
      @archival = error.record
      render :new, status: :unprocessable_entity
    rescue Bali::Archivable::AlreadyArchived
      redirect_to return_path, status: :see_other
    end

    def unarchive
      @record.unarchive!(by: actor)
      redirect_to return_path, status: :see_other
    rescue Bali::Archivable::NotReversible
      head :not_found
    rescue Bali::Archivable::NotArchived
      redirect_to return_path, status: :see_other
    end

    private

    def set_record
      @record = Bali.archivables[params[:record_type].to_s]&.call(self, params[:record_id].to_s)
      head :not_found unless @record.is_a?(Bali::Archivable)
    end

    def authorize_archivals!
      head :forbidden unless Bali.archivals_authorize.call(self, @record, action_name)
    end

    def set_successors
      @successors = Bali.archival_successors.call(self, @record)
    end

    def actor = Bali.archivals_actor.call(self)

    # The successor is looked up among the candidates, never by a type the request names.
    def archival_params
      permitted = params.fetch(:archival, {}).permit(:reason, :note, :successor_id)
      { reason: permitted[:reason].presence, note: permitted[:note].presence,
        successor: @successors&.find_by(id: permitted[:successor_id]) }
    end

    # Rails passes a `//host` location through as protocol-relative, so only a path is followed.
    def return_path
      path = params[:return_to].to_s
      return path if path.start_with?("/") && !path.start_with?("//")

      main_app.polymorphic_path(@record)
    end
  end
end
```

`app/views/bali/archivals/new.html.erb`:

```erb
<%= render Bali::FormPage::Component.new(title: t("bali_view.archivals.new.title"), context: :drawer) do |page| %>
  <% page.with_body do %>
    <%= render Bali::ArchivalForm::Component.new(
          record: @record,
          successors: @successors,
          archival: @archival,
          url: archivals_path(record_type: params[:record_type], record_id: params[:record_id]),
          return_to: params[:return_to]
        ) %>
  <% end %>
<% end %>
```

- [ ] **Step 6: Configure the dummy** — append to `test/dummy/config/initializers/bali.rb`,
  inside `Bali.config do |config|`:

```ruby
  # #721 — archiving movies through the engine's drawer. The defaults deny everything and the
  # engine's controller has no `current_user`; the dummy does not authenticate, so it opens the
  # gate and signs as the demo user.
  config.archivables = { "Movie" => ->(_controller, id) { Movie.find_by(id: id) } }
  config.archivals_authorize = ->(_controller, _record, _action) { true }
  config.archivals_actor = ->(_controller) { User.demo }
  config.archival_successors = ->(_controller, movie) { Movie.where.not(id: movie.id).order(:name) }
```

- [ ] **Step 7: Run the tests to verify they pass**

Run: `bin/rails test test/requests/archivals_test.rb test/requests/content_versions_test.rb test/requests/engine_controller_concerns_test.rb`
Expected: PASS.

- [ ] **Step 8: Negative controls**

| Remove / change | Test that must fail | Read the failure as |
|---|---|---|
| `head :not_found unless …` → `head :not_found if @record.nil?` | `test_a_whitelisted_model_without_the_concern_is_not_found` | errors with `NoMethodError … archival_reasons` from the form — the 500 a host would get; the `is_a?` is what makes it a 404 |
| the body of `authorize_archivals!` | `test_a_falsy_authorize_forbids_every_action` | `Expected response to be a <403>` |
| `rescue Bali::Archivable::NotReversible` | `test_unarchive_on_an_irreversible_model_is_not_found` | the exception surfaces: this rescue IS the 404 |
| `&& !path.start_with?("//")` | `test_return_to_is_followed_only_when_it_is_a_path_of_this_app` | `ActionController::Redirecting::UnsafeRedirectError` — Rails' own guard (`raise_on_open_redirects`) turning it into a 500; the check is what makes it the record's page instead |
| `@successors&.find_by(…)` → `Movie.find_by(id: permitted[:successor_id])` | `test_a_successor_outside_the_candidates_is_never_stored` | `Expected response to be a <422>, but was a <303>` |
| `rescue Bali::Archivable::AlreadyArchived` | `test_archiving_an_archived_record_redirects_and_keeps_the_first_archival` | the exception surfaces |
| `rescue ActiveRecord::RecordInvalid` | `test_an_invalid_archival_re_renders_the_form_with_422_and_keeps_the_choice` | the exception surfaces |
| `layout false` | `test_new_serves_the_form_as_a_drawer_body` | `Expected exactly 0 elements matching "html"` — or an error from the engine layout's `javascript_importmap_tags`; either way, this line is what keeps the layout out |

- [ ] **Step 9: Run RuboCop and commit**

```bash
bundle exec rubocop app/controllers/bali/archivals_controller.rb app/models/bali lib/bali.rb \
  app/components/bali/archival_form app/components/bali/archival_notice test/requests/archivals_test.rb
git add app/controllers/bali/archivals_controller.rb app/views/bali/archivals lib/bali.rb config/routes.rb \
  test/dummy/config/initializers/bali.rb test/requests/archivals_test.rb
git commit -m "feat(archivable): Bali::ArchivalsController con sus dos capas de rechazo por omisión (#721)"
```

---

### Task 7: The dummy's movie page, Cypress, and the browser

**Files:**
- Modify: `test/dummy/app/views/movies/show.html.erb` (trigger + notice)
- Create: `cypress/e2e/archival-drawer.cy.js`
- Create (scratchpad, not committed): `<scratchpad>/archival-shots.mjs`

**Interfaces:**
- Consumes: everything above; the dummy on 3021 (Task 1 Step 6) with seeds (movie 2 is
  "Inception").
- Produces: the end-to-end flow on `/movies/:id` that Cypress and the screenshots exercise.

- [ ] **Step 1: Wire the page** — in `test/dummy/app/views/movies/show.html.erb`, inside the
  header's action `div`, before the Edit link:

```erb
    <% unless @movie.archived? %>
      <%= render Bali::Link::Component.new(
        name: 'Archive',
        href: bali.new_archival_path(record_type: 'Movie', record_id: @movie.id),
        drawer: true,
        variant: :ghost,
        icon: 'archive'
      ) %>
    <% end %>
```

and right after the PageHeader block:

```erb
<%= render Bali::ArchivalNotice::Component.new(
  record: @movie,
  successor_url: (movie_path(@movie.archival.successor) if @movie.archival&.successor),
  unarchive_url: bali.unarchive_archivals_path(record_type: 'Movie', record_id: @movie.id),
  class: 'mt-4'
) %>
```

Update the template's header comment line ("Showcases: …") to add `ArchivalNotice`.

- [ ] **Step 2: Write the Cypress spec**

`cypress/e2e/archival-drawer.cy.js`:

```js
// #721 -- archiving a movie through the engine's drawer, against the real endpoints.
//
// The dummy app lives above the Lookbook preview path `baseUrl` points at, so the origin is
// derived from it: a literal origin ignores CYPRESS_BASE_URL and tests another server.
const appOrigin = new URL(Cypress.config('baseUrl')).origin
const moviePath = '/movies/2'
const unarchiveUrl = `${appOrigin}/bali/archivals/unarchive?record_type=Movie&record_id=2`

// The dummy's Movie is reversible, so a run leaves the movie as it found it. A run that failed
// halfway left it archived: reopening first is a no-op otherwise (the engine redirects).
const reopenIfArchived = () => {
  cy.visit(`${appOrigin}${moviePath}`)
  cy.get('meta[name="csrf-token"]').invoke('attr', 'content').then(token => {
    cy.request({ method: 'POST', url: unarchiveUrl, form: true, body: { authenticity_token: token } })
  })
}

const openDrawer = () => {
  cy.visit(`${appOrigin}${moviePath}`)
  cy.get('a[href*="/bali/archivals/new"]').click()
  return cy.get('#main-drawer form[action*="/bali/archivals"]', { timeout: 10000 })
}

const successorFieldset = '[data-radio-toggle-target="element"]'

describe('Archival drawer', () => {
  beforeEach(reopenIfArchived)

  it('reveals the successor for "Replaced by another", archives, and shows the notice', () => {
    openDrawer().within(() => {
      cy.get(successorFieldset).should('not.be.visible')
      cy.contains('label', 'Replaced by another').click()
      cy.get(successorFieldset).should('be.visible')
      cy.get('select[name="archival[successor_id]"]').select(1)
      cy.get('textarea[name="archival[note]"]').type('Remastered')
      cy.get('button[type="submit"]').click()
    })

    cy.location('pathname').should('eq', moviePath)
    cy.get('.archival-notice-component').should('be.visible')
      .and('contain', 'Reason: Replaced by another.')
      .find('a').should('have.attr', 'href').and('match', /^\/movies\/\d+/)
    cy.get('a[href*="/bali/archivals/new"]').should('not.exist')
  })

  it('keeps the successor hidden for a reason that does not need one, and reopens', () => {
    openDrawer().within(() => {
      cy.contains('label', 'Expired').click()
      cy.get(successorFieldset).should('not.be.visible')
      cy.get('button[type="submit"]').click()
    })

    cy.get('.archival-notice-component').should('be.visible').and('contain', 'Reason: Expired.')
      .and('not.contain', 'Replaced by')
    cy.contains('button', 'Reopen').click()

    cy.location('pathname').should('eq', moviePath)
    cy.get('.archival-notice-component').should('not.exist')
    cy.get('a[href*="/bali/archivals/new"]').should('be.visible')
  })

  it('keeps the drawer open on a 422 and shows why', () => {
    openDrawer().within(() => {
      cy.contains('label', 'Replaced by another').click()
      cy.get('button[type="submit"]').click()
    })

    cy.get('#main-drawer #archival_successor_id_error').should('be.visible')
    cy.location('pathname').should('eq', moviePath)
    cy.get('.archival-notice-component').should('not.exist')
  })
})
```

The third test submits "replaced" with the blank successor: `include_blank` leaves the select
empty, and the browser has no `required` to block it, so the request reaches the server's 422.

- [ ] **Step 3: Run Cypress against 3021**

```bash
export PATH="$HOME/.local/opt/xvfb/usr/bin:$HOME/.local/share/mise/shims:$HOME/.hermes/node/bin:$PATH"
CYPRESS_BASE_URL=http://127.0.0.1:3021/lookbook/preview \
  xvfb-run -a yarn run --silent cypress run --browser electron --spec cypress/e2e/archival-drawer.cy.js
```
Expected: 3 passing. Run it twice in a row — the second run proves the cleanup holds.

- [ ] **Step 4: Negative controls (Cypress)**

- In the ArchivalForm template, remove `controller: "radio-toggle"` from the form's `data` → the
  fieldset is never toggled, and test 1 fails on its first `should('not.be.visible')`. Restore.
- Remove `drawer: true` from `submit_group` → test 3 fails: the plain submit navigates the page
  to the bare 422 body, so `#main-drawer #archival_successor_id_error` is never found. Restore.

- [ ] **Step 5: Screenshots — afal and afal-dark, 1280 and 375**

`<scratchpad>/archival-shots.mjs`:

```js
import { chromium } from '/home/fede/code/gobierno-corporativo/node_modules/playwright/index.mjs'

const base = 'http://127.0.0.1:3021'
const out = process.argv[2]
const setTheme = async (page, theme) => {
  await page.evaluate(t => document.documentElement.setAttribute('data-theme', t), theme)
  await page.waitForTimeout(150)
}

const browser = await chromium.launch()
for (const theme of ['afal', 'afal-dark']) {
  for (const width of [1280, 375]) {
    const page = await browser.newPage({ viewport: { width, height: 900 } })
    await page.goto(`${base}/movies/2`, { waitUntil: 'networkidle' })
    await setTheme(page, theme)
    await page.locator('a[href*="/bali/archivals/new"]').click()
    const form = page.locator('#main-drawer form[action*="/bali/archivals"]')
    await form.waitFor()
    await form.getByLabel('Replaced by another').check()
    await page.screenshot({ path: `${out}/drawer-${theme}-${width}.png` })
    await form.locator('select[name="archival[successor_id]"]').selectOption({ index: 1 })
    await form.locator('button[type="submit"]').click()
    await page.waitForURL('**/movies/2')
    await setTheme(page, theme)
    await page.screenshot({ path: `${out}/notice-${theme}-${width}.png`, fullPage: false })
    await page.getByRole('button', { name: 'Reopen' }).click()
    await page.waitForURL('**/movies/2')
    await page.close()
  }
}
await browser.close()
```

```bash
node <scratchpad>/archival-shots.mjs <scratchpad>/shots
```
Look at all eight: the drawer at 375 fits with no horizontal scroll; the notice wraps its sentence
and keeps Reopen reachable at 375; text, link and Reopen label are readable in `afal-dark`. If
anything looks wrong, measure the contrast with the canvas method of
[[playwright-capturas-beelink]] (paint the background first, then the colour; multiply the
element's `opacity`) against AA 4.5:1 and report the numbers — do not restyle on a guess. Visual
choices (warning colour, button style, wording) go to Fede in the PR as one decision per element,
with these screenshots.

- [ ] **Step 6: Commit**

```bash
git add test/dummy/app/views/movies/show.html.erb cypress/e2e/archival-drawer.cy.js
git commit -m "test(archivable): el drawer de baja en la dummy, con Cypress (#721)"
```

---

### Task 8: Documentation and CHANGELOG

**Files:**
- Modify: `docs/guides/engine-models.md` (install list; new "Archivable" section with its GC
  porting table)
- Modify: `docs/guides/engines.md` (authorize table rows; "Archivals (#721)" section)
- Modify: `CHANGELOG.md` (`[Unreleased]` → `### Added`)

**Interfaces:**
- Consumes: the measured fleet list from Task 1 Step 5; every API name from Tasks 3–6.
- Produces: the adoption guide GC follows in Tasks 11–14.

- [ ] **Step 1: `engine-models.md`**

1. In "Installing one feature at a time", add `bin/rails bali:install:migrations:archivals` to the
   list, and rewrite the count-bearing sentences without numbers: "…also hands you every other
   feature's table — tables you never asked for…" and "`bali:install:migrations` still copies
   every migration…".
2. Add `## Archivable (`bali_archivals`)` after "Entity references", with, in this order:
   - Install (`bin/rails bali:install:migrations:archivals`, `bin/rails db:migrate`).
   - The model, exactly the spec §2 block, and the table of methods (`archive!`, `unarchive!`,
     `archived?`, `archival`, `archivals`, `archived`, `not_archived`) with what each raises.
   - Reasons and labels: the defaults, `activerecord.archival_reasons.<model>.<reason>` before
     `bali_view.archivals.reasons.<reason>`.
   - What replaced this: `Bali::Archival.where(successor: record)` — the concern adds no
     association; the GC example `has_many :predecessor_archivals, class_name: "Bali::Archival",
     as: :successor` + `has_many :predecessor_documents, through: :predecessor_archivals, source:
     :archivable, source_type: "Document"`.
   - The trigger and the notice, as a host writes them:

```erb
<%= render Bali::Link::Component.new(
      name: t('.archive'),
      href: bali.new_archival_path(record_type: 'Document', record_id: @document.id),
      drawer: true) %>

<%= render Bali::ArchivalNotice::Component.new(
      record: @document,
      successor_url: (document_path(@document.archival.successor) if @document.archival&.successor)) %>
```

   - One sentence: the engine's form is a drawer body, served without a layout, because the
     engine's controllers do not inherit your `ApplicationController` and cannot render your
     layout.
   - The name collision: `Bali::Archivable` is namespaced, but one model cannot include it and an
     `Archivable` of its own (both define `archive!`/`archived?`) — name the apps Task 1 Step 5
     found, with that count.
   - `### Porting the table from gobierno-corporativo`:

| gobierno-corporativo | Bali | What to do |
|---|---|---|
| `document_id` | `archivable` polymorphic | `archivable_type = 'Document'` |
| `user_id` (`belongs_to :user`) | `archived_by` polymorphic | `archived_by_type = 'User'` |
| `obsolescence_reason` (the key) | `reason` | Renamed; blank becomes NULL |
| `reason` (the free text) | `note` | Renamed — the two used to read as the same thing |
| `successor_document_id` | `successor` polymorphic | `successor_type = 'Document'` when present |
| `OBSOLESCENCE_REASONS` | `Bali::Archivable::DEFAULT_REASONS` | Same five keys |
| one row per document, forever | `unarchived_at` / `unarchived_by` | Unused while the model is irreversible |

- [ ] **Step 2: `engines.md`**

Add four rows to the table in "The real gate":

```markdown
| `Bali.archivables` | which models can be archived over HTTP | `{}` — every `record_type` is a 404 |
| `Bali.archivals_authorize` | the form, archiving and reopening | falsy — 403 |
| `Bali.archivals_actor` | who archives or reopens | `->(controller) { controller.try(:current_user) }` |
| `Bali.archival_successors` | the records that may replace this one | `nil` — no successor offered |
```

and a `## Archivals (#721)` section after "Content versions (#707)": the initializer with all
four entries (the GC shape from Task 14 Step 3, written generically with `Pundit.policy_scope!`
and `Pundit.policy!` — the engine's controllers do not include Pundit), what `action` takes, why
the resolver returns nil without a session, and a pointer to engine-models.md for the model.

- [ ] **Step 3: Run every guide example as written** (CLAUDE.md step 6): paste the model block
  and the initializer into the dummy temporarily (they must boot and archive a record via
  `bin/rails runner`), then remove them. Check every claim against Tasks 1–7's results.

- [ ] **Step 4: CHANGELOG** — under `## [Unreleased]`, a `### Added` heading above the existing
  `### Fixed`:

```markdown
### Added

- **Archivable: dar de baja un registro del host con el engine (#721, sub-proyecto 1).** Un modelo
  que incluye `Bali::Archivable` gana `archive!`, `unarchive!` (sólo con `reversible: true`),
  `archived?`, `archival`, `archivals` y los scopes `archived`/`not_archived`; los motivos por
  omisión son los cinco de gobierno-corporativo, con etiquetas es/en. El engine sirve el
  formulario en un drawer (`bali.new_archival_path(record_type:, record_id:)`) y
  `Bali::ArchivalNotice` pinta el aviso en el registro dado de baja. Para adoptarlo:
  `bin/rails bali:install:migrations:archivals` y las cuatro entradas `Bali.archiv*` del
  initializer — sin ellas, todo responde 404 o 403. Un modelo no puede incluir a la vez
  `Bali::Archivable` y un `Archivable` propio.
```

- [ ] **Step 5: Commit**

```bash
git add docs/guides/engine-models.md docs/guides/engines.md CHANGELOG.md
git commit -m "docs(archivable): guía de adopción y CHANGELOG (#721)"
```

---

### Task 9: Review gate and the Bali PR

**Files:** none new (fixes from the review land in the files above).

- [ ] **Step 1: Full suites**

```bash
bundle exec rubocop && yarn standard cypress/e2e/archival-drawer.cy.js && bin/rails test
CYPRESS_BASE_URL=http://127.0.0.1:3021/lookbook/preview \
  xvfb-run -a yarn run --silent cypress run --browser electron
```
Expected: RuboCop clean; Minitest 0 failures/0 errors; Cypress all green except the failures
recorded as pre-existing in [[cypress-en-la-beelink]] — confirm any other failure against a clean
tree before attributing it.

- [ ] **Step 2: Host greps** (the reviewer has no shell; run them and hand over the output)

```bash
for app in afal-apps gobierno-corporativo identity opina garita costa-norte centinela-web ga-apps; do
  echo "== $app"
  git -C ~/code/$app grep -n -E "Bali::Archiv|bali_archivals|ArchivalForm|ArchivalNotice|archivals_authorize" origin/main -- app config lib db
done > <scratchpad>/hostgrep.txt
```
Expected: no hits (nothing in the fleet collides with the new constants, table or keys).

- [ ] **Step 3: DHH review** — write the diff, then launch the agent

```bash
{ git log --oneline origin/main..HEAD; git diff --stat origin/main...HEAD; git diff origin/main...HEAD; } \
  > <scratchpad>/branch.diff
```

Launch `dhh-code-reviewer` with a prompt that opens: "Scope: read-only review of the worktree
`/home/fede/code/bali-view-components.worktrees/721-archivable`, diff in
`<scratchpad>/branch.diff`, host greps in `<scratchpad>/hostgrep.txt`. Do not write or edit any
file. If you think the assignment is wrong, say so and stop." Then the criteria: CLAUDE.md
§ Resolving an issue steps 1–6, the comment rule, the spec. Check each finding; apply what holds.
At most two rounds; prose nits do not open a second one.

- [ ] **Step 4: Re-run what the fixes touched**, then the full Minitest suite once more.

- [ ] **Step 5: PR** (only with the team lead's go-ahead) — body in Spanish, opening
  `Part of #721`; sections: what ships, premise measured (Task 1), readers walked (host greps,
  dummy, both locales, light/dark themes), the ambiguities this plan resolved (layout, notice on
  `Bali::Alert`, `archival:` keyword, empty successors = nil), the review summary, the eight
  screenshots and the visual decisions for Fede. End with the attribution line.

---

### Task 10: Release v3.14.0

**Files:** `lib/bali/version.rb`, `package.json`, `Gemfile.lock`, `README.md`,
`docs/guides/installation.md`, `CHANGELOG.md` — per `docs/guides/release-channels.md`
§ Cutting a release.

- [ ] **Step 1:** After the feature PR merges, and only with Fede's go-ahead: a release PR
  `release/v3.14.0` off `main` that bumps the six files (`[Unreleased]` becomes
  `## [v3.14.0] - <date>`, merging repeated `###` headings).
- [ ] **Step 2:** `bin/rails test` (the dependency contract test checks the four install pins).
- [ ] **Step 3:** After that PR merges, tag its `merge_commit_sha` and publish the GitHub
  Release exactly as release-channels.md § Cutting a release step 4 shows.

---

# Deliverable 2 — gobierno-corporativo (deploy 1)

GC rules match Bali's: English code and comments (`Bali/EnglishOnly` runs over the whole repo
with no todo file), Spanish product copy and PR prose, `Closes #NNN` in English. Read GC files on
`origin/main` only; work in a worktree.

### Task 11: GC preflight and the Bali bump

**Files:**
- Modify: `Gemfile:85` (`tag: "v3.14.0"`), `Gemfile.lock`
- Modify: `package.json:42` (`#v3.14.0`), `yarn.lock`
- Create: `db/migrate/<timestamp>_create_bali_archivals.bali.rb` (installed, not written)
- Modify: `db/schema.rb`

**Interfaces:**
- Consumes: the `v3.14.0` tag.
- Produces: worktree `/home/fede/code/gobierno-corporativo.worktrees/bali-archivable` on
  `feat/bali-archivable` with `bali_archivals` in its schema.

- [ ] **Step 1: Worktree with the gitignored files linked** (GC
  `.claude/references/worktree-setup.md`)

```bash
cd /home/fede/code/gobierno-corporativo && git fetch origin
git worktree add --no-track -b feat/bali-archivable \
  /home/fede/code/gobierno-corporativo.worktrees/bali-archivable origin/main
DEST=/home/fede/code/gobierno-corporativo.worktrees/bali-archivable
ln -sf "$PWD/.env.development" "$DEST/.env.development"
for f in "$PWD"/config/*.{p8,pem,key}; do [ -f "$f" ] && ln -sf "$f" "$DEST/config/$(basename "$f")"; done
```

- [ ] **Step 2: Bump Bali, Ruby and JS to the same tag**

Edit `Gemfile` (the `tag:` GC pins on `main` at that moment → `"v3.14.0"`) and `package.json`
(the `#vX.Y.Z` GC pins → `#v3.14.0`), then:

```bash
export PATH="$HOME/.local/share/mise/shims:$HOME/.hermes/node/bin:$PATH"
bundle update bali_view_components --conservative
yarn install
yarn build && bin/rails tailwindcss:build
```
Check `git diff Gemfile.lock yarn.lock`: only the Bali entries move (Yarn 4; if a transitive
duplicates, dedupe per [[dedupe-al-subir-una-transitiva]]).

- [ ] **Step 3: Baseline the suite on the bump alone**

```bash
set -a; . ./.env.development; set +a
DISABLE_SPRING=1 bin/rails test
```
Expected: same result as `origin/main` (record any pre-existing failure).

- [ ] **Step 4: Install the engine migration and migrate**

```bash
bin/rails bali:install:migrations:archivals
bin/rails db:migrate
git diff db/schema.rb
```
Keep only the `create_table "bali_archivals"` block, its two indexes and the `version:` line;
Postgres 18 rewrites `check_constraint` lines on a local migrate — that is noise
(`test/config/schema_check_constraints_test.rb` explains it): put those hunks back as they were.

- [ ] **Step 5: Commit**

```bash
git add Gemfile Gemfile.lock package.json yarn.lock db/migrate/*_create_bali_archivals.bali.rb db/schema.rb
git commit -m "chore(deps): Bali v3.14.0 e instala bali_archivals"
```

---

### Task 12: GC data copy — deploy 1

**Files:**
- Create: `db/migrate/<later-timestamp>_copy_document_archivals_to_bali_archivals.rb`
- Test: `test/models/document/archival_copy_migration_test.rb`

**Interfaces:**
- Consumes: both tables (deploy 1 keeps `document_archivals`).
- Produces: class `CopyDocumentArchivalsToBaliArchivals` with an idempotent `up` (copies only
  documents with no row in `bali_archivals`); Task 16 repeats the same INSERT.

- [ ] **Step 1: Generate the empty migration** (it fixes the timestamp the test requires; it
  sorts after Task 11's installed `create_bali_archivals`)

```bash
bin/rails generate migration CopyDocumentArchivalsToBaliArchivals
```

- [ ] **Step 2: Write the failing test** — `<later-timestamp>` below is the one Step 1 printed.

```ruby
# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/migrate/<later-timestamp>_copy_document_archivals_to_bali_archivals")

# Bali#721 — document archivals move to the engine's table. What has to survive the copy:
# reason, note, successor, author and date.
class Document::ArchivalCopyMigrationTest < ActiveSupport::TestCase
  setup do
    @migration = CopyDocumentArchivalsToBaliArchivals.new
    @migration.verbose = false
  end

  test "reason, note, successor, author and date survive the copy" do
    doc = documents(:politica_gastos)
    insert_document_archival(doc, user: users(:admin), obsolescence_reason: "replaced",
                             reason: "Sustituida por la nueva política", successor: documents(:manual_calidad),
                             at: Time.zone.local(2026, 3, 4, 10))

    @migration.up

    archival = Bali::Archival.find_by!(archivable: doc)
    assert_equal [ users(:admin), "replaced", "Sustituida por la nueva política", documents(:manual_calidad) ],
                 [ archival.archived_by, archival.reason, archival.note, archival.successor ]
    assert_equal Time.zone.local(2026, 3, 4, 10), archival.created_at
    assert_nil archival.unarchived_at
  end

  test "blank strings become NULL and a missing successor stays missing" do
    doc = documents(:politica_gastos)
    insert_document_archival(doc, user: users(:admin), obsolescence_reason: "", reason: "")

    @migration.up

    archival = Bali::Archival.find_by!(archivable: doc)
    assert_nil archival.reason
    assert_nil archival.note
    assert_nil archival.successor_type
  end

  test "running the copy again adds only the rows written since" do
    first = documents(:politica_gastos)
    insert_document_archival(first, user: users(:admin))
    @migration.up

    late = documents(:procedimiento_compras)
    insert_document_archival(late, user: users(:admin))

    assert_difference -> { Bali::Archival.count }, 1 do
      @migration.up
    end
    assert Bali::Archival.exists?(archivable: late)
  end

  private

  def insert_document_archival(document, user:, obsolescence_reason: nil, reason: nil, successor: nil, at: Time.current)
    ActiveRecord::Base.connection.exec_insert(<<~SQL.squish, "archival", [ document.id, user.id, obsolescence_reason, reason, successor&.id, at, at ])
      INSERT INTO document_archivals
        (document_id, user_id, obsolescence_reason, reason, successor_document_id, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
    SQL
  end
end
```

(Fixture names come from `test/fixtures/documents.yml` on `origin/main`; check that
`politica_gastos` and `procedimiento_compras` are not archived there — `archived_doc` is. The
assertions read `Bali::Archival` rows, not `archived?`: until Task 13, `Document#archived?` is
still GC's own and reads `document_archivals`, so it would pass for the wrong reason.)

- [ ] **Step 3: Run it to verify it fails**

Run: `DISABLE_SPRING=1 bin/rails test test/models/document/archival_copy_migration_test.rb`
Expected: the first two tests ERROR with `ActiveRecord::RecordNotFound` from `find_by!` and the
third FAILS on `assert_difference` ("expected change of 1, got 0") — the generated migration's
empty `change` copies nothing.

- [ ] **Step 4: Write the migration** (replace the generated body)

```ruby
# frozen_string_literal: true

# Bali#721. Deploy 1 copies and keeps `document_archivals`: during the switch the outgoing
# container still reads it. Deploy 2 repeats this INSERT for what that container wrote after the
# copy ran, then drops the table — hence the NOT EXISTS.
class CopyDocumentArchivalsToBaliArchivals < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      INSERT INTO bali_archivals
        (archivable_type, archivable_id, archived_by_type, archived_by_id, reason, note,
         successor_type, successor_id, created_at, updated_at)
      SELECT 'Document', a.document_id, 'User', a.user_id,
             NULLIF(a.obsolescence_reason, ''), NULLIF(a.reason, ''),
             CASE WHEN a.successor_document_id IS NOT NULL THEN 'Document' END,
             a.successor_document_id, a.created_at, a.updated_at
      FROM document_archivals a
      WHERE NOT EXISTS (
        SELECT 1 FROM bali_archivals b
        WHERE b.archivable_type = 'Document' AND b.archivable_id = a.document_id
      )
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

(`down` cannot tell copied rows from archivals made after the deploy; deleting them would lose
data a re-run of `up` cannot recover.)

- [ ] **Step 5: Migrate, run the test, negative control**

```bash
bin/rails db:migrate && DISABLE_SPRING=1 bin/rails test test/models/document/archival_copy_migration_test.rb
```
Expected: PASS. Control: remove the `WHERE NOT EXISTS (…)` clause → the third test fails with
`ActiveRecord::RecordNotUnique` from the partial index — that error is the regression (a second
run would abort the deploy), so it counts. Remove the two `NULLIF`s → the second test fails on
`assert_nil archival.reason` ("Expected \"\" to be nil"). Restore.

- [ ] **Step 6: Commit**

```bash
git add db/migrate/*_copy_document_archivals_to_bali_archivals.rb db/schema.rb \
  test/models/document/archival_copy_migration_test.rb
git commit -m "feat(documentos): copia document_archivals a bali_archivals (deploy 1, Bali#721)"
```

---

### Task 13: GC model adoption

**Files:**
- Modify: `app/models/document.rb` (lines 6, 24–27, 109–127, 273–275, 311–313, 378–383)
- Modify: `app/models/document/change_request.rb:430-434`
- Modify: `app/models/document/dashboard_metrics.rb:86-87`
- Modify: `app/models/document/change_log.rb:8-13` (comment that becomes false)
- Modify: `db/seeds/demo.rb:426,1291,2169`
- Delete: `app/models/concerns/archivable.rb`, `app/models/document/archival.rb`
- Delete: `test/models/document/archival_test.rb`, `test/fixtures/document/archivals.yml`
- Create: `test/fixtures/bali/archivals.yml`
- Modify tests: `test/models/document_test.rb`, `test/models/document/referenceable_test.rb:303`,
  `test/controllers/documents_controller_test.rb:135`, `test/support/published_document_helper.rb:64-73`,
  `test/jobs/document/read_reminder_job_test.rb:25`

**Interfaces:**
- Consumes: `Bali::Archivable` (Task 3), the copied rows (Task 12).
- Produces: `Document.archived`/`not_archived`/`active`/`draft` reading `bali_archivals`;
  `Document#replaced_by` → `archival&.successor`; `#predecessor_documents`;
  `#archive_with_change_control(user:, note:, change_request:)`.

- [ ] **Step 1: Move the fixture first** (the model it named is about to go)

`test/fixtures/bali/archivals.yml`:

```yaml
archived_doc_archival:
  archivable: archived_doc (Document)
  archived_by: admin (User)
  reason: replaced
  note: Este procedimiento ha sido reemplazado por uno nuevo
  successor: procedimiento_compras (Document)
  created_at: <%= 6.months.ago.to_fs(:db) %>
  updated_at: <%= 6.months.ago.to_fs(:db) %>
```

Delete `test/fixtures/document/archivals.yml`.

- [ ] **Step 2: Adapt the tests to the new API** (they fail until Step 3)

In `test/models/document_test.rb`:
- "has one archival": `assert_kind_of Bali::Archival, doc.archival`.
- "archive creates an archival record": `doc.archive!(by: users(:admin), note: "Replaced by newer version")`.
- "archive stores the reason" → rename "archive stores the note";
  `doc.archive!(by: users(:admin), note: "Obsoleto")`; `assert_equal "Obsoleto", doc.archival.note`.
- "archive assigns user to archival": `doc.archive!(by: users(:admin))`;
  `assert_equal users(:admin), doc.archival.archived_by`.
- "archive raises AlreadyArchivedError when already archived" → rename "archiving twice raises
  AlreadyArchived"; `assert_raises(Bali::Archivable::AlreadyArchived) { doc.archive!(by: users(:admin)) }`.
- "archive with obsolescence_reason stores reason type" → `doc.archive!(by: users(:admin), reason: :expired)`;
  `assert_equal "expired", doc.archival.reason`.
- "archive with successor document stores reference" → `doc.archive!(by: users(:admin), reason: :replaced, successor: successor)`;
  `assert_equal successor, doc.archival.successor`.
- Add, pinning GC's own declaration (moved from the deleted archival_test):

```ruby
  test "replaced needs a successor" do
    doc = documents(:politica_gastos)

    error = assert_raises(ActiveRecord::RecordInvalid) { doc.archive!(by: users(:admin), reason: :replaced) }
    assert_includes error.record.errors.attribute_names, :successor_id
  end

  test "a document cannot be reopened" do
    doc = documents(:archived_doc)

    assert_raises(Bali::Archivable::NotReversible) { doc.unarchive!(by: users(:admin)) }
  end
```

Elsewhere: `target.create_archival!(user: @user, reason: "obsolete")` (documents_controller_test:135)
and `target.create_archival!(user: users(:admin), reason: "obsolete")` (referenceable_test:303)
become `target.archive!(by: …, note: "obsolete")`; `read_reminder_job_test.rb:25` becomes
`log.document.archive!(by: users(:admin), note: "out of scope")`; in
`published_document_helper.rb`:

```ruby
  def retire_gc_doc_document!(document, at: 1.month.ago)
    archival = document.archive!(by: users(:admin), reason: :superseded,
                                 note: "Retired so the new version could be published.")
    archival.update_columns(created_at: at, updated_at: at)
    document.reload
  end
```

Then: `git grep -n -E "create_archival|Document::Archival|document_archivals\(|obsolescence_reason|successor_document|AlreadyArchivedError|\.archive\(" -- test`
must return nothing but the migration test of Task 12.

- [ ] **Step 3: Adopt the concern in `Document`**

- `include Archivable` → `include Bali::Archivable`, and after the include list:
  `archivable successor_required_for: %i[replaced]`.
- Delete `AlreadyArchivedError = Archivable::AlreadyArchivedError`.
- `active`: the first condition becomes the scope —

```ruby
  scope :active, -> {
    not_archived.where(<<~SQL.squish, Document::ChangeLog::PUBLISHING_TYPES)
      EXISTS (
        SELECT 1 FROM document_change_logs cl
        WHERE cl.document_id = documents.id
          AND cl.change_type IN (?)
          AND cl.revision_number = (
            SELECT MAX(revision_number)
            FROM document_change_logs
            WHERE document_id = documents.id
          )
      )
    SQL
  }
```

- `draft`: `not_archived.where.not(id: active.select(:id))`.
- Predecessors:

```ruby
  # Documents that were replaced by this one
  has_many :predecessor_archivals, class_name: "Bali::Archival", as: :successor, dependent: :nullify
  has_many :predecessor_documents, through: :predecessor_archivals, source: :archivable, source_type: "Document"
```

- `replaced_by`: `archival&.successor`.
- `archive_with_change_control(user: Current.user, note: nil, change_request: nil)` calling
  `archive!(by: user, note: note)`; in `change_request.rb:430-434`, `reason: description` →
  `note: description`.
- `dashboard_metrics.rb:86-87`: `scope.where.missing(:archival)` → `scope.not_archived`;
  `scope.joins(:archival).count` → `scope.archived.count`.
- `change_log.rb:8-13`: the comment says unarchiving was never built because "`Archivable` only
  exposes `archive` and the archiving route is `only: [ :new, :create ]`". Rewrite that clause:
  "`Document` is declared irreversible (`Bali::Archivable`'s default), so `unarchive!` raises and
  the engine's unarchive route answers 404". Keep the rest.
- Seeds: `doc.archive!(by: attrs[:responsible].user, note: "Reemplazado por nueva versión")`;
  `archived_doc.archive!(by: andres, note: "Reemplazado por PROC-COMP-001", successor: doc_objects["PROC-COMP-001"])`;
  `Document.archived.count`.
- Delete `app/models/concerns/archivable.rb`, `app/models/document/archival.rb`,
  `test/models/document/archival_test.rb`.

`includes(:archival)` (documents controller, flows controller, controlled documents) and
`ransackable_associations`' `"archival"` keep working: `archival` is still an association.

- [ ] **Step 4: Run the model, job and helper tests**

```bash
DISABLE_SPRING=1 bin/rails test test/models/document_test.rb test/models/document \
  test/models/governing_body/controlled_document_test.rb test/jobs/document test/models/document_search_test.rb
```
Expected: PASS. Negative control: `include Bali::Archivable` without the macro line → "replaced
needs a successor" fails ("RecordInvalid expected but nothing was raised").

- [ ] **Step 5: Commit**

```bash
git add -A app/models db/seeds test
git commit -m "refactor(documentos): Document adopta Bali::Archivable y borra su copia (Bali#721)"
```

---

### Task 14: GC configuration, UI, analytics

**Files:**
- Modify: `config/initializers/bali.rb` (four entries)
- Modify: `app/views/documents/show.html.erb` (menu item ~124–130, banner ~156–180, sidebar ~306–316)
- Modify: `config/routes.rb:608` (delete the documents archival resource)
- Modify: `app/helpers/navigation_helper.rb:227` (delete `"documents/archivals"`)
- Modify: `config/initializers/bali_analytics.rb:81-88` (port the rule)
- Modify: `config/locales/es.yml` (and `en.yml` where the same keys exist)
- Modify: `app/javascript/controllers/index.js:36-37`
- Delete: `app/controllers/documents/archivals_controller.rb`, `app/views/documents/archivals/`,
  `app/javascript/controllers/toggle_field_controller.js` (its only reader was the deleted form)
- Delete + create: `test/controllers/documents/archivals_controller_test.rb` →
  `test/integration/document_archival_test.rb`
- Modify: `test/controllers/documents_controller_test.rb:591-609`,
  `test/integration/bali_analytics_capture_test.rb`

**Interfaces:**
- Consumes: Bali's routes, config, components and the `@record`/`@archival` ivars (Task 6).
- Produces: GC's archival flow on the engine.

- [ ] **Step 1: Write the failing integration test**

`test/integration/document_archival_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

# Archiving a document through Bali's engine (Bali#721), with GC's four `Bali.archiv*` entries.
class DocumentArchivalTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    sign_in_as @admin
    @doc = documents(:procedimiento_compras)
  end

  def record_params(doc = @doc) = { record_type: "Document", record_id: doc.id }

  test "the drawer offers the five reasons and the published documents as successors" do
    get bali.new_archival_path(record_params)

    assert_response :success
    assert_select "input[name='archival[reason]']", 5
    assert_select "label", "Reemplazado por otro documento"
    assert_select "select[name='archival[successor_id]'] option[value=?]", documents(:manual_calidad).id.to_s
    assert_select "select[name='archival[successor_id]'] option[value=?]", @doc.id.to_s, count: 0
  end

  test "archiving with a successor redirects to the document and records who did it" do
    successor = documents(:manual_calidad)
    post bali.archivals_path(record_params),
         params: { archival: { reason: "replaced", successor_id: successor.id, note: "Reemplazado" } }

    assert_redirected_to document_path(@doc)
    archival = @doc.reload.archival
    assert_equal [ @admin, "replaced", successor, "Reemplazado" ],
                 [ archival.archived_by, archival.reason, archival.successor, archival.note ]
  end

  test "replaced without a successor re-renders with 422" do
    post bali.archivals_path(record_params), params: { archival: { reason: "replaced" } }

    assert_response :unprocessable_entity
    assert_not @doc.reload.archived?
  end

  test "an already archived document keeps its archival" do
    doc = documents(:archived_doc)

    assert_no_difference -> { Bali::Archival.count } do
      post bali.archivals_path(record_params(doc)), params: { archival: { reason: "other" } }
    end
    assert_redirected_to document_path(doc)
  end

  test "a regular user is forbidden" do
    sign_in_as users(:employee)

    post bali.archivals_path(record_params)
    assert_response :forbidden
  end

  test "a document editor can archive" do
    sign_in_as users(:document_editor)

    post bali.archivals_path(record_params), params: { archival: { note: "Editor archive" } }
    assert_redirected_to document_path(@doc)
    assert @doc.reload.archived?
  end

  test "reopening a document is not found" do
    post bali.unarchive_archivals_path(record_params(documents(:archived_doc)))
    assert_response :not_found
  end

  test "without a session the engine answers not found" do
    sign_out
    get bali.new_archival_path(record_params)
    assert_response :not_found
  end
end
```

(Use the suite's own sign-out helper; if there is none, `reset!` drops the session. If the
employee's `policy_scope` already hides `procedimiento_compras`, the regular-user test answers 404
— read which, and assert what the policy actually does.)

Adapt `test/controllers/documents_controller_test.rb:591-609`:

```ruby
  test "show displays the archival notice for archived documents" do
    get document_path(documents(:archived_doc))
    assert_response :success
    assert_select ".archival-notice-component", /Dado de baja el/
  end

  test "show links the successor from the notice" do
    get document_path(documents(:archived_doc))
    assert_select ".archival-notice-component a[href=?]", document_path(documents(:procedimiento_compras))
  end

  test "show does not display the archival notice for active documents" do
    get document_path(@document)
    assert_select ".archival-notice-component", count: 0
  end
```

Add to `test/integration/bali_analytics_capture_test.rb`, as the positive/negative pair its
header asks for:

```ruby
  test "archiving a document through the engine emits documento_archivado with con_sucesor" do
    sign_in_as users(:admin)
    doc = documents(:procedimiento_compras)

    assert_difference -> { BaliAnalytics::Event.where(name: "documentos.documento_archivado").count }, 1 do
      post bali.archivals_path(record_type: "Document", record_id: doc.id),
           params: { archival: { reason: "replaced", successor_id: documents(:manual_calidad).id } }
    end
    event = BaliAnalytics::Event.where(name: "documentos.documento_archivado").order(:id).last
    assert_equal true, event.properties["con_sucesor"]
  end

  test "a rejected archival emits nothing" do
    sign_in_as users(:admin)

    assert_no_difference -> { BaliAnalytics::Event.where(name: "documentos.documento_archivado").count } do
      post bali.archivals_path(record_type: "Document", record_id: documents(:procedimiento_compras).id),
           params: { archival: { reason: "replaced" } }
    end
  end
```

Delete `test/controllers/documents/archivals_controller_test.rb` (its cases live above).

- [ ] **Step 2: Run them to verify they fail**

Run: `DISABLE_SPRING=1 bin/rails test test/integration/document_archival_test.rb test/integration/bali_analytics_capture_test.rb`
Expected: FAIL — 404 on every engine request (`Bali.archivables` is still `{}`).

- [ ] **Step 3: Configure Bali** — append to `config/initializers/bali.rb`:

```ruby
# Bali#721 — archiving documents goes through the engine's drawer. A request with no session
# reaches the engine with a nil `current_user` (BaliAuth::EngineAuthentication only teaches
# identity), and the policy scope cannot take nil: the resolver answers nil, so that is a 404.
Bali.archivables = {
  "Document" => lambda do |controller, id|
    user = controller.current_user
    Pundit.policy_scope!(user, Document).find_by(id: id) if user
  end
}
Bali.archivals_authorize = ->(controller, record, _action) { Pundit.policy!(controller.current_user, record).archive? }
Bali.archivals_actor = ->(controller) { controller.current_user }
Bali.archival_successors = lambda do |controller, document|
  Pundit.policy_scope!(controller.current_user, Document).published.where.not(id: document.id).order(:title)
end
```

- [ ] **Step 4: The view** — `app/views/documents/show.html.erb`:
  - Menu item: `href: bali.new_archival_path(record_type: "Document", record_id: @document.id)`
    and add `drawer: true` (keep `name`, `icon`, `class`, and the `policy(@document).archive? &&
    @document.active?` guard).
  - Replace the whole `<% if @document.archived? %> … Bali::Alert … <% end %>` banner in
    `page.with_subheader` with:

```erb
    <%= render Bali::ArchivalNotice::Component.new(
      record: @document,
      successor_url: (document_path(@document.replaced_by) if @document.replaced_by),
      class: "mb-2"
    ) %>
```

  - Sidebar: `@document.archival.reason` (both occurrences) → `@document.archival.note`.

- [ ] **Step 5: Remove what the engine replaced**
  - `config/routes.rb:608`: delete `resource :archival, only: [ :new, :create ], module: :documents`.
  - `app/helpers/navigation_helper.rb:227`: delete `"documents/archivals" => :documentos,`.
  - Delete the controller, `app/views/documents/archivals/`, `toggle_field_controller.js` and its
    two lines in `app/javascript/controllers/index.js`.
  - `config/locales/es.yml`: delete `documents.archivals` (new/form/create),
    `documents.obsolescence_reasons`, and `documents.show.obsolete_label`, `obsoleted_on`,
    `replaced_by`; add the one label that differs from Bali's:

```yaml
es:
  activerecord:
    archival_reasons:
      document:
        replaced: Reemplazado por otro documento
```

  (merge into GC's existing `activerecord:` root). Repeat the deletions in `en.yml` where those
  keys exist. Then `git grep -n -E "obsolescence_reasons|obsolete_label|obsoleted_on|documents\.archivals|toggle-field" -- app config test`
  must be empty.

- [ ] **Step 6: Port the analytics rule** — `config/initializers/bali_analytics.rb:81-88`:

```ruby
  # `previously_new_record?` and not `archived?`: archiving an archived document redirects
  # without writing, and the archival is present on that path too. What tells today's archival
  # from yesterday's is that the row was just created. `@record` and `@archival` are the ivars
  # Bali::ArchivalsController leaves for track rules.
  c.track "bali/archivals#create",
          event: "documentos.documento_archivado",
          if: -> { @record.is_a?(Document) && @archival&.previously_new_record? },
          properties: -> { { con_sucesor: @archival.successor_id.present? } }
```

(`TrackRuleVerification` raises at boot for a rule naming a controller that no longer exists —
leaving the old rule would stop the app from booting.)

- [ ] **Step 7: Run the tests to verify they pass**

```bash
DISABLE_SPRING=1 bin/rails test test/integration/document_archival_test.rb test/integration/bali_analytics_capture_test.rb \
  test/controllers/documents_controller_test.rb test/models/analytics_track_rules_test.rb \
  test/integration/sidebar_navigation_test.rb
```
Expected: PASS.

- [ ] **Step 8: Negative controls**
  - Drop `if user` from the resolver → "without a session the engine answers not found" fails
    (`Expected response to be a <404>`, the policy scope raises on nil).
  - Replace the rule's condition with `-> { true }` → "a rejected archival emits nothing" fails on
    its `assert_no_difference`. Restore.
  - Remove the `activerecord.archival_reasons.document.replaced` override → "the drawer offers
    the five reasons…" fails on `assert_select "label", "Reemplazado por otro documento"`.

- [ ] **Step 9: Full GC suite, then commit**

```bash
DISABLE_SPRING=1 bin/rails test && bundle exec rubocop
git add -A app config test
git commit -m "feat(documentos): el drawer de baja de Bali reemplaza Documents::ArchivalsController (Bali#721)"
```

---

### Task 15: GC verification — database copy, browser, review, PR (deploy 1)

**Files:** none committed (scripts and outputs in the scratchpad).

- [ ] **Step 1: A database copy.** Production is reachable only from the MacBook: ask Fede for a
  recent `pg_dump -Fc` of production. Restore it into a scratch database on `gc-postgres`
  (5433). If no dump is available, copy the local development database instead and say so in
  the PR.

```bash
set -a; . ./.env.development; set +a
createdb -h localhost -p 5433 gc_archival_check
pg_restore -h localhost -p 5433 -d gc_archival_check --no-owner --no-acl <scratchpad>/gc.dump
```

- [ ] **Step 2: Migrate the copy with this branch**

```bash
DATABASE_URL="postgres://$DATABASE_USERNAME:$DATABASE_PASSWORD@localhost:5433/gc_archival_check" \
  DISABLE_SPRING=1 bin/rails db:migrate
```
(Use the variable names `.env.development` actually defines; `DATABASE_URL` overrides only the
primary database.)

- [ ] **Step 3: Prove nothing was lost** — both tables exist after deploy 1, so one query
  compares them:

```sql
SELECT
  (SELECT count(*) FROM document_archivals) AS old_count,
  (SELECT count(*) FROM bali_archivals WHERE archivable_type = 'Document') AS new_count,
  (SELECT count(*) FROM document_archivals a WHERE NOT EXISTS (
     SELECT 1 FROM bali_archivals b
     WHERE b.archivable_type = 'Document' AND b.archivable_id = a.document_id
       AND b.archived_by_type = 'User' AND b.archived_by_id = a.user_id
       AND b.reason IS NOT DISTINCT FROM NULLIF(a.obsolescence_reason, '')
       AND b.note IS NOT DISTINCT FROM NULLIF(a.reason, '')
       AND b.successor_type IS NOT DISTINCT FROM CASE WHEN a.successor_document_id IS NOT NULL THEN 'Document' END
       AND b.successor_id IS NOT DISTINCT FROM a.successor_document_id
       AND b.created_at = a.created_at AND b.unarchived_at IS NULL)) AS unmatched;
```
Expected: `old_count = new_count`, `unmatched = 0`. And `active` before/after, in one runner
(the old scope's SQL still runs: its table is still there):

```ruby
old = Document.where(<<~SQL.squish, %w[new_document major minor]).order(:id).ids
  NOT EXISTS (SELECT 1 FROM document_archivals a WHERE a.document_id = documents.id)
  AND EXISTS (SELECT 1 FROM document_change_logs cl WHERE cl.document_id = documents.id
    AND cl.change_type IN (?) AND cl.revision_number =
      (SELECT MAX(revision_number) FROM document_change_logs WHERE document_id = documents.id))
SQL
new = Document.active.order(:id).ids
puts({ old: old.size, new: new.size, same: old == new }.inspect)
```
Expected: `same: true`. (`%w[new_document major minor]` is `PUBLISHING_TYPES` on `origin/main`;
re-read it from `Document::ChangeLog` before running.) The three numbers go in the PR body.

- [ ] **Step 4: Browser** — start GC on a free port (`DISABLE_SPRING=1 bin/rails server -p
  <port> -b 127.0.0.1`), log in through the dev picker as a super_admin (users 2 or 10 locally),
  open a published document, "Marcar Obsoleto" → the drawer → «Reemplazado por otro documento» →
  a successor → submit → the notice. Capture with the Task 7 script adapted to GC's URLs, in
  `afal` and `afal-dark`, at 1280 and 375. Delete the scratch database afterwards
  (`dropdb -h localhost -p 5433 gc_archival_check`) and stop only your own server.

- [ ] **Step 5: DHH review** — same shape as Task 9 Step 3 on this worktree's diff, with the
  database-copy numbers and the screenshots attached. At most two rounds.

- [ ] **Step 6: PR** (team lead's go-ahead; deploy 1). Spanish body: what changes for people
  (drawer instead of page, the notice's wording — Bali's es copy, with GC's `replaced` label kept),
  the two-deploy plan and why, the copy's proof, the screenshots, the wording decisions for Fede
  (drawer title and submit read «Dar de baja», not «Marcar como Obsoleto»; overridable in GC's
  locale if he prefers).

---

# Deliverable 3 — gobierno-corporativo (deploy 2)

### Task 16: Drop `document_archivals`

Only after deploy 1 is in production.

**Files:**
- Create: `db/migrate/<timestamp>_drop_document_archivals.rb`
- Delete: `test/models/document/archival_copy_migration_test.rb` (its table is gone from the
  schema; the INSERT it covered runs once more below)
- Modify: `db/schema.rb`

- [ ] **Step 1: Write the migration** — `bin/rails generate migration DropDocumentArchivals`, then
  replace its body:

```ruby
# frozen_string_literal: true

# Bali#721, deploy 2. The INSERT is deploy 1's copy again: it picks up the archivals the outgoing
# container wrote to this table after deploy 1's copy ran.
class DropDocumentArchivals < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      INSERT INTO bali_archivals
        (archivable_type, archivable_id, archived_by_type, archived_by_id, reason, note,
         successor_type, successor_id, created_at, updated_at)
      SELECT 'Document', a.document_id, 'User', a.user_id,
             NULLIF(a.obsolescence_reason, ''), NULLIF(a.reason, ''),
             CASE WHEN a.successor_document_id IS NOT NULL THEN 'Document' END,
             a.successor_document_id, a.created_at, a.updated_at
      FROM document_archivals a
      WHERE NOT EXISTS (
        SELECT 1 FROM bali_archivals b
        WHERE b.archivable_type = 'Document' AND b.archivable_id = a.document_id
      )
    SQL
    drop_table :document_archivals
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

- [ ] **Step 2: Verify on a database copy** (fresh dump taken after deploy 1, as in Task 15
  Step 1). Before migrating, simulate the outgoing container:
  `INSERT INTO document_archivals (document_id, user_id, reason, created_at, updated_at)
  SELECT id, <a user id>, 'late write', now(), now() FROM documents d WHERE NOT EXISTS (SELECT 1 FROM bali_archivals b WHERE b.archivable_type='Document' AND b.archivable_id=d.id) LIMIT 1;`
  Then `bin/rails db:migrate` and check: that document now has a `bali_archivals` row with
  `note = 'late write'` and `Document.archived.exists?(<its id>)` is true; `document_archivals` no
  longer exists; `Bali::Archival.where(archivable_type: "Document").count` is the count taken
  before the INSERT plus one.

- [ ] **Step 3:** `git grep -n "document_archivals" -- app config lib test db/seeds` is empty;
  regenerate `db/schema.rb` (keep only the dropped table and the version line, as in Task 11
  Step 4); full suite; DHH review (one round); PR (Spanish body: what this drops, the late-write
  check from Step 2).

---

## Self-review notes

- **Spec coverage.** §1 → Task 2; §2 → Task 3; §3 → Task 6; §4 → Tasks 4–5 (+ trigger in Tasks 7
  and 8); §5 → Tasks 11–16; §6 → the tests of Tasks 2–7 and 12–14, browser in Tasks 7 and 15,
  DHH in Tasks 9 and 15; §7 → Task 8.
- **Resolved ambiguities** (each also goes in the PR body):
  1. `GET /archivals/new` "for a page or a drawer": the engine serves a drawer body with
     `layout false` — an engine controller cannot render the host layout (no host helpers,
     unprefixed routes), and the engine's own layout calls `javascript_importmap_tags`, which GC
     does not load. A host wanting a page renders `Bali::ArchivalForm` itself.
  2. `ArchivalNotice` composes on `Bali::Alert`, not the deprecated `Bali::Notification` toast.
  3. `ArchivalForm` gains `archival:` — the spec's `422` re-render needs the invalid archival.
  4. An empty successor relation behaves like `nil` (spec: "a model with no candidates").
  5. The spec's resolver example `controller.policy_scope(Document)` does not exist on the
     engine's controller (it does not include Pundit): the plan uses `Pundit.policy_scope!`.
  6. GC's `successor_document` (spec §5) is the archival's column; the Document method is
     `replaced_by`, which keeps its name and reads `archival&.successor`.
  7. `AlreadyArchived` in `create` and `NotArchived` in `unarchive` redirect like a success: the
     page shows the state that already holds.
  8. GC's bali-analytics rule names `Documents::ArchivalsController`; boot verification would fail
     once it is deleted, so Task 14 ports it to `bali/archivals#create`.
  9. Deploy 2 repeats the copy before the drop, for archivals the outgoing container writes during
     deploy 1's switch.
