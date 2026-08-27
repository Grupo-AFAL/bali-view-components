# The widget declaration DSL

**Date:** 2026-08-27
**Branch:** `feat/widgets-and-widget-grid`
**Supersedes:** the `#call`-only contract in
`docs/superpowers/specs/2026-08-25-widgets-and-widget-grid-design.md`
**Superseded by:** `docs/superpowers/specs/2026-08-27-widget-pattern-bases.md`, which makes the
pattern a superclass rather than a combination of macros. Kept for the reasoning it records
about why the `Result` builders had almost no callers; the DSL described below is no longer
the shipped design.

A host's widget class declares what it *has*; Bali builds the `Result`. `#call` remains
for anything the declarations cannot express.

```ruby
class LowStockItems < ApplicationWidget
  sized :medium

  scope    { Item.low_stock.order(:name) }
  row      { |item| { title: item.name, href: item_path(item) } }
  view_all { items_path }
end
```

## Why

The previous contract was one method returning a nine-field value object, with three
builders (`with_trend`, `with_series`, `with_goal`) as sugar. Measured against the ten
widgets in `spec/dummy/app/widgets/`, that sugar had **almost no callers** — `with_goal`
none, `with_trend` none, `with_series` one. The documented ladder was not the ladder any
widget walked.

The reason was specific: the builders constructed their value object unconditionally, so a
widget whose trend is conditional could not use them. Two of two trend widgets in the
showcase return `nil` when there is no prior period, and both therefore hand-built a
`Result`.

The DSL makes that case the natural one — **a block returning `nil` means the rung is
absent** — and removes the duplication the builders never addressed: a list widget stated
its collection twice, once for `count` and once for `items`.

## The declarations

| Macro | Fills | Notes |
|---|---|---|
| `scope` | `count` and `items` | The primitive. Must arrive **ordered**. |
| `row` | each `Bali::Widget::Row` | Returns a Hash; Bali builds the `Row`. |
| `count` | `count` | Only when the headline is not `scope.count` — a sum, an average. |
| `headline` | `display_value` | Only when the number is not the display: `"$2.1B"`. |
| `series` · `trend` · `goal` | same-named fields | Hash of the value object's attributes, or `nil`. |
| `view_all` | `view_all_path` | Not `links_to` — one character from `link_to`. |

Every block is `instance_exec`'d on the widget at `#result` time. Private helpers,
memoisation, `context` and route helpers work exactly as they do inside `#call`, which is
how two rungs share one query:

```ruby
series { { labels: decades.keys, values: decades.values } }
trend  { … decades … }

private

def decades = @decades ||= Studio.group(…).count.sort.to_h
```

**Nothing runs during `visible?`.** The split that lets `Bali::Widget.authorized_for` list
the offering without touching the database is unchanged.

## Row shape: a Hash, not a constructor

`row` returns a Hash and `Definition` calls `Row.new(**hash)`. This was challenged as losing
`Row`'s typed-key protection; it does not. `Row` is a `Data`, so an unknown key raises
`ArgumentError: unknown keyword: :subtile` at the point of construction — the same failure
the explicit constructor gives, and still not a silently blank cell.

## The size promise

**The sizes a widget offers are a promise about the data it has.** `medium` and `large` put
a context region beside or above the headline; a widget with neither `scope` nor `series`
fills that with nothing, and the user who picks the size gets a number in an empty box.

So a declared widget supporting anything above `small` must declare `scope` or `series`:

```
ArgumentError: ProductionBudget supports [:medium] but declares neither `scope` nor
`series` — those sizes put a context region beside the headline and this widget has
nothing to fill it with. Add data, or `supports :small`.
```

This is checked **lazily**, on the first `#result`, not at class-definition time: a class
body is read top to bottom and `supports` may legitimately precede the data macros.
`Widget.raise_load_errors?` is true in development, so it surfaces on the first render.

It cannot check a `#call` widget — a method body is not something Bali can see inside.

Note what it caught: `ProductionBudget` was hand-declared `supports :small, :medium` after
eyeballing the card. The rule rejects `:medium`, and it is right to — a bare figure in a 2×1
is the same complaint as a bare figure in a 2×2, with less of it.

## Declare or define, never both

A widget that declares and also defines `#call` would be two descriptions of one thing, free
to disagree. The second one raises, in either order — `method_added` catches a `#call`
defined after declarations, and `declare` catches a declaration added after `#call`.

`UnavailableFeed` (returns `Result.failed`) uses `#call`, and is the reason the escape hatch
exists.

## How a developer knows what to write

The generator, not a `pattern` macro in the class body — a declaration restating what the
macros below already say is a second source of truth free to drift.

```bash
bin/rails g bali:widget StudioFoundings --size medium --pattern metric
```

`--pattern` is one of `list`, `metric`, `goal`, `stat`, and scaffolds exactly that ladder's
rungs with the reasoning in comments. `--pattern stat` also writes `supports :small`, and
refuses a larger `--size` rather than leaving the widget's own boot check to reject it.

## What did not change

`sized`, `supports`, `visible?`, `key`, the i18n scope, `PREVIEW_ROWS`, every value object,
and `Result`'s fields. The card, the grid and the store are untouched.

## Costs, accepted knowingly

- **No partial override.** With `#call` a subclass uses `super`. Declarations are inherited
  and overridden **wholesale** — a child re-declaring `row` replaces the parent's block.
- **Eight reserved class-level names**: `scope`, `row`, `count`, `headline`, `series`,
  `trend`, `goal`, `view_all`.
- **The size check is lazy**, so a widget nobody has rendered has not been checked.
