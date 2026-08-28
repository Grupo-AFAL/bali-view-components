# The pattern is the type

**Date:** 2026-08-27
**Branch:** `feat/widgets-and-widget-grid`
**Supersedes:** `docs/superpowers/specs/2026-08-27-widget-declaration-dsl.md`

A widget does not describe its shape; it **inherits** it. There are five bases, one per shape,
and a widget picks exactly one.

```ruby
class LowStockItems < Bali::Widget::ListBase
  default_size :medium

  order_by     :name
  row do |r|
    r.title :name
    r.subtitle :outlet_name
    r.href { |item| item_path(item) }
  end

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

## The five

| Base | Shows | Declares |
|---|---|---|
| `ValueBase` | one figure | `value`, `display_value` |
| `ListBase` | how many, and which | `list`, `row` |
| `TrendBase` | a figure and how it moved | `trend`, `series` |
| `ProgressBase` | a ring toward a goal | `goal`, `series` |
| `CheckBase` | does it pass? | `check` |

**Nothing is an abstract method any more.** A widget's data is declared, not defined — `t.current
{ … }` rather than `def current`. The readers survive (`#current`, `#value`, `#max`) because
`g.label { "of #{max}" }` has to be able to read one, but they resolve the declaration rather
than being overridden. The only methods a host writes are private helpers two declarations share.

`Base` holds what they share: `default_size`, `supports`, `view_all_path`, the copy macros,
`visible?`, `key`, and the failure net.

## `CheckBase` is ternary, and its name carries the polarity

Added after the other four, which makes it the first test of whether the shape generalises. It
did: one builder, one value object's worth of state, the same `dup`-on-inherit and merge-per-field
rules, and the card branch it needs is the one `goal?` already established — a check replaces the
number rather than decorating it.

**Ternary, not boolean.** `nil` is "not checked yet", drawn muted and reporting `count` 0, so a
pending check cannot claim a pass. `false` reports `count` 1, because a failing check is not an
empty one — `count.positive?` drives the card's muted treatment, and a red tick is an answer.

**No `positive_when`, unlike `TrendBase`,** and the asymmetry is principled rather than an
oversight. A trend's number carries no polarity of its own: 12% up is neutral until you say what
it measures, so the widget must declare which direction is good. A check's *name* states it —
"Backups healthy", "Certificate valid". Requiring positive phrasing puts the decision where the
reader already looks, and adding a declaration would duplicate what the name says.

It renders through `Bali::BooleanIcon`, which already owned the ternary reasoning, the
success/error/muted palette and the screen-reader labels that keep colour from being the only
signal. Composing it was the point: the pattern places a component, it does not restate one.

**It caught a latent bug in the builder idiom.** Every other builder writes
`@field = block || value`, which collapses a declared `c.value false` into "not declared" — fatal
for the one pattern whose answer is falsy. `CheckBuilder` uses a sentinel instead. The other four
are unaffected (no one declares `r.title false`), but the idiom is now known to be conditional on
the field's values being truthy.

## `Charted` is a module, not a fifth base

`series` is declared and read identically by `TrendBase` and `ProgressBase` — it was written out
twice, verbatim — so it lives in `Bali::Widget::Charted`, which both include. The per-pattern
difference is one class attribute: `:line` against `:bar`.

`Base → ChartedBase → {TrendBase, ProgressBase}` would also work and would keep single
inheritance. It is a module instead for two reasons:

**`*Base` is host-facing vocabulary.** `--pattern trend` scaffolds `TrendBase`; the guide's table
lists exactly four. A fifth `*Base` reads as a fifth pattern to inherit from, and nothing
inherits from this one — it is a capability two patterns have, not a kind of widget.

**A middle class fixes a taxonomy; a mixin does not.** Putting "charted" in the chain commits to
it being a level, and it is not obviously one: a list widget with a sparkline beside its count is
a plausible thing to want, and that is `include Charted` on `ListBase` — one line, where a middle
class would need a re-parenting `ListBase` cannot have.

Ruby draws the same line: `Comparable` and `Enumerable` are capabilities; inheritance is
taxonomy. The name follows those rather than `Chartable`, because a widget including it *has* a
chart rather than merely being able to have one.

**`s.type` takes `:line` or `:bar` and nothing else**, validated at class-definition time. Those
two survive the size ladder — both have axes for the sparkline to strip below `large`, and both
read at a 2×1. Chart.js's axis-less types do not, and a widget wanting one wants the `body` slot.

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
`list`/`row` to `TrendBase` and `ProgressBase`, plus a row budget in `REGIONS`
for a card that is showing both.

## The card decides what to load, and validates while doing it

`Base#failed?` is a plain reader. The loading happens in `Bali::Widget::Component#before_render`,
which reads `count` always and `items` only where rows will render — a hero tile shows none, so
it never pays for them.

It has to happen there, because the card branches on failure *first*, before it has asked the
widget for anything, and a lazily-read widget has not failed yet at that moment. Leaving
`failed?` to probe for itself worked but had to be explained in three files; deciding what a
canvas needs read is the card's job, and `REGIONS` is where that is already written down.

**Every required declaration is validated from `count`**, which `before_render` reads at every
size. That placement is load-bearing rather than incidental. Guarding only `#trend` and `#goal`
left `:small` unprotected: the hero branch decides on `failed?` at the very top and never looks
again, so a guard reached later fired *after* the card had committed to looking healthy — a
widget missing `t.current` printed a confident grey `0` at its own default size while apologising
correctly at the other two. That is precisely what the degraded tile exists to prevent.

A widget whose `count` survives and whose series does not is caught a second time by the detail
region, which keeps itself rendered (`detail?` includes `failed?`) so the apology has somewhere
to go.

The wrapper memoises the failure as well as catching it: the card asks several questions, and a
rescue that did not remember would re-run the broken query once per question. It names
`NotImplementedError` explicitly, because that descends from `ScriptError` rather than
`StandardError` — and a forgotten declaration is the most likely way to author a broken widget.

**Successes are memoised too**, by the patterns, with `defined?` rather than `||=`. `nil` is a
documented answer here — no previous period, no series — and `||=` cannot hold it, so the
declaration block would re-run on every read. The card asks `series` six to eight times per tile.

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
base names (`value`, `list`, `trend`, `progress`, `check`) rather than a second set of words for
classes that already have names. It scaffolds that pattern's required declarations with a
raising placeholder, the optional ones commented out, and the reasoning in comments — including
the three forms every row field takes, which is the one table a host most needs and which
otherwise lived only in the gem. It refuses a `--size` the pattern does not offer.

## What did not change

`visible?`, `key`, the i18n scope, `PREVIEW_ROWS`, `Widget.abbreviate`, `Widget.join` (was
`Widget.subtitle`), the `Trend`/`Series`/`Goal`/`Row` value objects (moved onto the patterns that
own them, `Series` onto `Charted`), the card's regions and layouts, the grid, the store, and the
size picker.
