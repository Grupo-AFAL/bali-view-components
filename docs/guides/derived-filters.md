# Filtering on derived attributes

`Bali::FilterForm`, the `Filters` popover and `SimpleFilters` assume every condition is
Ransack: each filter compiles to a `q[...]` parameter and resolves to SQL. That assumption
is what keeps a filtered page honest — the database filters, then `pagy` counts and slices
what is left, so the rows you see and the summary that announces them always agree.

The assumption seems to break the first time you need to filter by an attribute that does
not exist as a column: a health traffic light computed in Ruby from several associations,
a status derived by a calculator object, a name that should match regardless of accents.
None of those are Ransack paths, so none of them can be a `filter_attribute` — at first
sight.

This guide is the pattern for those cases: **make the value visible to SQL and declare a
`ransacker`**. The attribute then joins the popover as a first-class citizen — operators,
AND/OR groups, quick search, persistence, saved views — with no new Bali API and no
special-casing in the controller. It is the pattern that resolved the real-world case that
motivated issue [#642](https://github.com/Grupo-AFAL/bali-view-components/issues/642), and
the reason that issue is closed pointing here.

## The anti-pattern: filtering in Ruby after the fact

The tempting shortcut is to smuggle the derived filter around Ransack — a top-level param
the controller intercepts and applies in Ruby:

```ruby
# DON'T
@filter_form = ProjectsFilterForm.new(policy_scope(Project), params, storage_id: 'projects')
@pagy, @projects = pagy(@filter_form.result)
@projects = @projects.select { |p| p.health == params[:health] } if params[:health]
```

This is wrong twice. Filtering **after** `pagy` only filters the current page — matching
rows on other pages are never shown, and `@pagy.count` and the DataTable summary keep
announcing the unfiltered totals ("Showing 3 of 250 projects", where 250 is a lie).
Moving the `select` **before** `pagy` fixes the count but materializes the entire table
into an Array on every request, and quietly downgrades `pagy` to array mode.

And it costs you the UI: a filter Ransack cannot see cannot live in the popover, so it
ends up as a stray control outside the toolbar — one page, two places to filter, and a
second widget whose state the filter persistence and saved views know nothing about.

## The pattern

Three steps:

1. **Make the value readable by SQL.** Either the derivation is already expressible as a
   SQL expression over existing columns, or you cache the Ruby-computed value in a column
   and keep it fresh (a job, a callback, a touch point on read).
2. **Declare a `ransacker`** on the model with the Arel for that expression.
3. **Allowlist and declare it**: add the name to `ransackable_attributes` and declare it
   in the FilterForm like any other attribute.

### Worked example: a cached column

The case that motivated this guide. A project's health is derived in Ruby by a calculator
over stages, deliverables, tasks and defects — nothing SQL can compute. The app caches the
last computed value in an `auto_health` column (refreshed by a daily job and whenever a
project page is opened) and allows a manual override in `health_override`:

```ruby
class Project < ApplicationRecord
  # `#health` is "manual override, else derived". The derivation is pure Ruby, so the
  # only thing SQL can read is its latest computed value, cached in `auto_health`.
  ransacker :health do
    Arel::Nodes::NamedFunction.new(
      'COALESCE', [arel_table[:health_override], arel_table[:auto_health]]
    )
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name status pm_id health]
  end
end
```

```ruby
class ProjectsFilterForm < Bali::FilterForm
  filter_attribute :health, type: :select,
                   label: -> { I18n.t('filters.health') },
                   options: -> { Project::HEALTHS.map { |h| [I18n.t("healths.#{h}"), h] } }
end
```

Nothing else changes. To Bali — and to Ransack — `health` is now indistinguishable from a
column: the popover offers it with the `:select` operators, it participates in AND/OR
groups, `applied_tags` and the active-filters badge count it, persistence restores it, and
sorting by it works if you also expose it to `with_header(sort:)`.

Two consequences of caching to accept (and to state in a comment next to the ransacker,
so the next reader filters with open eyes):

- **Staleness.** The filter sees the value as of the last computation, not the live
  derivation. Bound the window explicitly — how often does the refresh job run, which
  reads re-compute?
- **Never-computed rows.** A row whose cache column is still `NULL` matches no value of
  the filter until the first computation lands. Decide whether that is acceptable or the
  cache needs a backfill.

### Worked example: a query-time expression

When the derivation is expressible directly in SQL, no cache is needed — the ransacker
computes at query time. Accent-insensitive matching ("gonzalez" must find "González"):

```ruby
class User < ApplicationRecord
  # unaccent() normalizes the column in SQL; I18n.transliterate mirrors that exact
  # mapping onto what the user typed, so the fold works in both directions.
  ACCENT_FOLD = ->(v) { I18n.transliterate(v.to_s) }

  ransacker :name, formatter: ACCENT_FOLD do |parent|
    Arel::Nodes::NamedFunction.new('unaccent', [parent.table[:name]])
  end
end
```

Because the ransacker is named like the column, it **shadows** it for all of Ransack on
this model: `search_fields :name` quick search, `filter_attribute :name` in the popover,
and any future sort on the column all go through it (sorting accent-insensitively, which
is usually what you want in Spanish). Notes for this specific expression: `unaccent` needs
the PostgreSQL extension (`enable_extension 'unaccent'` in a migration), and the function
is `STABLE`, not `IMMUTABLE` — if the table grows enough to need an expression index, the
index needs an `IMMUTABLE` wrapper function.

The same shape covers any derivation over existing columns — a `CASE`, arithmetic, a date
comparison:

```ruby
ransacker :overdue, type: :boolean do
  Arel::Nodes::Grouping.new(
    Arel.sql('due_on < CURRENT_DATE AND completed_at IS NULL')
  )
end
```

## Why filter in SQL at all?

This is the reason the pattern above is the documented answer, rather than Bali growing a
`filter_attribute ..., ransack: false` escape hatch that emits a custom top-level param
(what #642 originally proposed):

- **Pagination stays truthful.** SQL filters before `pagy` counts. Every Ruby-side
  alternative either lies in the summary or materializes the table — and an official API
  for non-Ransack filters would invite exactly that trap.
- **The popover is semantically Ransack.** Its groups compile to `q[g][N][...]` and the
  OR between conditions resolves in SQL. A top-level param cannot participate in an OR
  resolved by the database; offering it inside the popover would promise semantics no
  host controller can honor.
- **The whole surface comes for free.** Operators, badge count, applied tags,
  persistence, saved views — all of it already works for anything Ransack can see. A
  second species of filter would need each of those re-implemented, including its own
  key in the persistence payload.

## When the value truly cannot reach SQL

A ransacker needs the value to be either derivable from columns or cacheable in one. If
you hit a derived attribute that is neither — it depends on per-request external state, or
on a per-user context no column can hold — then this pattern does not apply, and that case
is the condition for reopening
[#642](https://github.com/Grupo-AFAL/bali-view-components/issues/642) (a custom top-level
param unified into the Filters UI).

Until then, the escape hatch is host-side and honest about its costs: intercept your
top-level param in the controller and apply it **before counting and paginating** (via
`pagy_array` over the Ruby-filtered list, accepting the full materialization), re-emit the
foreign `q[...]` params as hidden fields so your control and the popover do not destroy
each other's state on submit, and accept that the control lives outside the toolbar.
Before settling for that, look hard at the cached-column variant — a value only Ruby can
compute can almost always be computed *at write time* and cached.

## See also

- [Components guide — Filters](components.md) and the `filterform-datatable` skill for
  the FilterForm DSL itself.
- The enum-label translation and association-path warnings in the skill apply to
  ransacker-backed selects too: a ransacker is reached by its name exactly like a column.
