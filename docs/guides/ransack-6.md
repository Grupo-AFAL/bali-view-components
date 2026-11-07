# Accepting ransack 6 in an app

Bali takes `ransack >= 5.0.3, < 7.0` (#1530). **Upgrading Bali changes nothing while the app stays
on ransack 5**: Bali reads and writes the same `q` keys it always did. This page is what an app
does *before* it lets Dependabot or `bundle update` move it to ransack 6 — an app that declares
`gem "ransack"` without a ceiling gets that proposal as soon as Bali allows it.

## What ransack 6 changes

- **`cont`, `start` and `end` (and their `not_` forms) become case-sensitive on PostgreSQL**
  (activerecord-hackery/ransack#1715). Up to 5.x they ran as `ILIKE` there. ransack 6 adds
  `i_start` and `i_end` beside the `i_cont` 5.x already had.
- **A model searched with groupings (`q[g]`) must answer `ransackable_associations`**, even when
  the search touches no association: ransack 6 raises `Ransack needs <Model> associations
  explicitly allowlisted as searchable`. The Filters panel always sends its conditions as
  groupings, so filtering from the panel is a 500 on such a model.

## What Bali does under ransack 6

One switch, `Bali::RansackParamName.case_insensitive_text?`, decided from the installed gem:

- The quick search submits `q[<fields>_i_cont]` instead of `q[<fields>_cont]`.
- The panel's "contains", "does not contain", "starts with" and "ends with" write `i_cont`,
  `not_i_cont`, `i_start` and `i_end`, including a new condition and a reset row.
- What was written before keeps reading: a URL, a saved view, the filter cache or a link that
  carries `name_cont` applies as `name_i_cont`, and the panel paints it as "contains". The
  quick search is read under every name of `Bali::RansackParamName.predicates(fields)`, which
  `FilterForm#search_param_names` returns.
- A Ransack scope the model allowlists under the box's `_cont` name (`ransackable_scopes`
  returning `"reported_serial_cont"`) keeps that name: Ransack calls a scope only for its exact key.
- `filter_attribute operators:` and `default_operator:` take either spelling.
- `Bali::RansackParamName.predicate(fields)` is the box's name under either ransack.

## Before accepting ransack 6

1. **`ransackable_associations` on every model a panel filters.** The simplest way covers them
   all; a model that declares its own keeps it:

   ```ruby
   class ApplicationRecord < ActiveRecord::Base
     def self.ransackable_associations(_auth_object = nil) = []
   end
   ```

   The models that allowlist attributes and not associations:
   `git grep -L ransackable_associations -- $(git grep -l "def self.ransackable_attributes" app/models)`.

2. **What reads the search box's param by hand** — `params.dig(:q, :name_cont)`,
   `params[:q][:name_or_email_cont]`, `search: { value: params.dig(...) }` — reads
   `Bali::RansackParamName.predicate(fields)` instead. Under ransack 6 the box submits `_i_cont`:
   a hand read of `_cont` comes back empty, so the box loses its text, or the search does
   nothing when the controller filters with that value itself.
   `git grep -n -E "_cont\b" app/views app/controllers app/helpers`.

3. **What acts on the search by its name** — a guard that drops it from the raw `q` before the
   form is built, a link or chip that removes it — covers every name the form reads it from.
   They depend only on the search's fields, so a guard has them before any form exists:

   ```ruby
   q = params.fetch(:q, {})
   Bali::RansackParamName.predicates(UsersFilterForm.defined_search_fields).each { |name| q.delete(name) }
   ```

   Where the form exists, `form.search_param_names` is the same list. `search_field_name` alone
   misses a bookmark that still carries `_cont`, which Bali reads and applies.
   `git grep -n -e search_field_name -e RansackParamName app`.

4. **Code that handles the panel's conditions by key.**
   - What evaluates the panel's operators by name (`"cont"`, `"not_cont"`, `"start"`, `"end"`)
     accepts the `i_` ones, or a condition from the panel reaches it unknown.
   - What rewrites `q[g]` after `super` — `ransack_params`, `extract_groupings`, `@groupings` —
     receives the text conditions already under the `i_` key (`name_i_cont`), whether they came
     from the URL, a saved view or the filter cache, so a lookup of `name_cont` there no longer
     finds it.

   `git grep -n -E "\"(not_)?cont\"|\"start\"|\"end\"|groupings|\[:g\]" app/forms app/models`.

5. **`_cont`, `_start` and `_end` written by hand** — a flat `attribute :name_cont`, a simple filter
   with `predicate: :cont`, a link with `q: { name_cont: ... }`, a `ransack(...)` call in a
   service or an API — become case-sensitive on PostgreSQL under ransack 6. Move the ones a
   person types into to `_i_cont`, `_i_start`, `_i_end`. A Ransack scope named `<field>_cont`
   that is not the quick search's exact name is not renamed by Bali.
   `git grep -n -E "_(cont|start|end)\b" app`.

6. **Run the app's suite with ransack 6**: tests that assert a `_cont` box name or a
   `q[g][0][name_cont]` field change with the version.
