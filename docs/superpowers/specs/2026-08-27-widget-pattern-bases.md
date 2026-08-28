# The pattern is the type

**Date:** 2026-08-27
**Branch:** `feat/widgets-and-widget-grid`
**Supersedes:** `docs/superpowers/specs/2026-08-27-widget-declaration-dsl.md`

A widget does not describe its shape; it **inherits** it. There are four bases, one per shape,
and a widget picks exactly one.

```ruby
class LowStockItems < Bali::Widget::ListBase
  default_size :medium

  order_by     :name
  row_title    :name
  row_subtitle :outlet_name
  row_href     { |item| item_path(item) }

  def scope = Item.low_stock
end
```

## Why this rather than the DSL it replaces

The declaration DSL let a widget say `scope`, `row`, `count`, `headline`, `series`, `trend`,
`goal` and `view_all` in any combination. Two problems followed from that freedom, and neither
was fixable inside it.

**A widget could describe a shape it did not have.** `trend { … }` without a `series`, a `goal`
beside a `count` — combinations that render, badly, and that no macro can reject because each
one is individually legitimate. The card had to branch on what happened to be present.

**Nothing told the author what to write.** The macros were a menu, and a menu does not say
which items make a meal. The generator's `--pattern` flag existed to fill exactly that gap,
which was the tell: the pattern was already the real unit of the design, expressed only in a
generator flag rather than in the code.

Making the pattern a superclass answers both. The class you inherit from supplies the
declarations you may use *and* the methods you owe, so an incomplete widget is a
`NotImplementedError` rather than a card that renders half a thing, and an incoherent one
cannot be spelled at all.

## The four

| Base | Shows | Abstract | Declares |
|---|---|---|---|
| `ValueBase` | one figure | `value` | — |
| `ListBase` | how many, and which | — | `list`, `row_title`, `row_subtitle`, `row_href` |
| `TrendBase` | a figure and how it moved | `current`, `previous` | `positive_when`, `period_label`, `series_labels`, `series_values`, `series_type` |
| `ProgressBase` | a ring toward a goal | `value` (`max` defaults 100) | `goal_label`, `series_labels`, `series_values`, `series_type` |

`Base` holds what they share: `default_size`, `supports`, `view_all_path`, the copy macros,
`visible?`, `key`, and the failure net.

## Base is a null object

The card asks the widget directly — there is no `Result` between them — and `Base` answers
every question with a null: `count` is `0`, `items` is `[]`, `trend`, `series` and `goal` are
`nil`. Each pattern overrides the ones it actually has.

So the card reads **one uniform interface** and never asks what kind of widget it is holding.
`Widget::Component` delegates to a single target, and the template's regions turn on what came
back rather than on a type check.

## Single inheritance, and what it costs

`ProjectProgress` had a row list before this change and does not now: `ProgressBase` is not a
`ListBase`. The original ladder spec described the metric ladder's top rung as a *breakdown*,
which a trend widget can no longer have either.

This is accepted knowingly, but **not for the reason first written here.** The original
argument — that a `rows` mixin would put us back where the DSL was, with the card branching on
what it finds — is false, and the card disproves it: `context?` and `detail?` each decide their
own region with no type checks, so a widget with both a series and items would render through
both unchanged. `REGIONS` even carried a row budget for exactly that case.

The DSL's real defect was free combination on the **headline** axis: `trend` without `series`,
a `goal` beside a `count`, two things competing to be the big number. "Does this widget also
list things" is orthogonal — the detail region is always subordinate, and the null object
already absorbs its absence.

So rows are left out because **no host dashboard has asked for them**, not because they are
incoherent. **A widget that needs both a chart and a list is two widgets**, and the grid exists
to put them side by side. If that stops being true, the change is a `Rows` concern supplying
`list`/`row_*` to `TrendBase` and `ProgressBase`, plus a row budget in `REGIONS`
for a card that is showing both.

## Failure is probed, not reported

`Base#failed?` runs `count` before answering. It has to: the card branches on failure *first*,
before it has asked the widget for anything, and a lazily-read widget has not failed yet at
that moment. A plain `@failed.present?` is false for every widget that is about to raise, and
the card then takes the healthy branch and renders a greyed-out `0` — the tile saying "nothing
here" for a widget that is actually broken, which is the one thing the degraded card exists to
prevent.

`count` is the probe because all four patterns define it and every region of the card already
depends on it, so it costs no query the card was not going to make. A widget whose `count`
survives and whose rows do not is caught a second time by the detail region, which keeps
itself rendered (`detail?` includes `failed?`) so the apology has somewhere to go.

The wrapper memoises the failure as well as catching it: the card asks several questions, and
a rescue that did not remember would re-run the broken query once per question. It names
`NotImplementedError` explicitly, because that descends from `ScriptError` rather than
`StandardError` — and a forgotten abstract method is now the most likely way to author a
broken widget.

## Sizes are declared, never inferred

`ValueBase` sets `supports :small`, which is the class's point rather than a limitation of it.
The others offer all three.

Inferring the set from the data — "no series, so no `large`" — would mean loading every widget
to render a picker, collapsing the `visible?`/data split that lets the picker list the
authorized set without a query. It would also make the offered sizes vary with the data: a
widget whose series is empty this week would silently stop offering a size the user had already
chosen. Apple declares `supportedFamilies` for the same two reasons.

`default_size` and `supports` both validate at class-definition time, and `supports` also
rejects a default the user could not choose.

## Hosts cannot have one `ApplicationWidget`

The superclass slot belongs to the pattern, so shared behaviour moves to a concern. Route
helpers are the case that matters, and `spec/dummy/app/widgets/widget_routes.rb` is the worked
example:

```ruby
module WidgetRoutes
  extend ActiveSupport::Concern
  included do
    include Rails.application.routes.url_helpers
    def default_url_options = {}
  end
end
```

This is a real cost of the design and the one hosts will notice first. It is documented in
`docs/guides/engine-models.md` and in the generated scaffold's comments.

## `list` takes a block, not a relation

`ListBase` declares its collection rather than defining a `#scope` method, which bundles the
three coupled parameters — what to read, how to order it, how many to preview — at one call
site where the old spelling let them drift.

The block is the ONLY accepted form. An earlier draft also took `list scope: <relation>`, and
that draft shipped the bug it enables, twice, in the same demo widget: a class body runs once at
boot, so `where(due_date: Date.current..)` froze the process's start date and the tile showed
the wrong week until a redeploy. The reloader re-runs the class body per request, so it could
not reproduce in development. A hazard that is invisible where you develop and silent where it
bites is not one to document; it is one to make unspellable.

The block is also the only form that works at all for most real widgets: it runs against the
widget, so it can reach `context` and be tenant- or user-scoped. A relation frozen into a class
body cannot.

Ordering goes inside the scope rather than in an `order_by:` keyword. Bali applies `limit` after
the block returns, so order-then-limit still holds by construction, and there is one obvious
place to write the ordering — the place a Rails developer would write it anyway.

## The generator

`--pattern` no longer writes a declaration; it picks the superclass, and its vocabulary is the
base names (`value`, `list`, `trend`, `progress`) rather than a second set of words for classes
that already have names. It scaffolds that pattern's abstract methods raising, with the
reasoning in comments, and refuses a `--size` the pattern does not offer.

## What did not change

`visible?`, `key`, the i18n scope, `PREVIEW_ROWS`, `Widget.abbreviate`, `Widget.subtitle`, the
`Trend`/`Series`/`Goal` value objects (moved onto the patterns that own them), the card, the
grid, the store, and the size picker.
