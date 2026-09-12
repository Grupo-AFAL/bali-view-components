# Widget design notes

Decisions behind `Bali::Widget` that are **not** about the ten lines beneath them —
the ones a reader needs when they are about to undo one, not when they are reading
the method. Source comments point here rather than restating these.

Gotchas that *are* about the line beneath them stay in the source: the `dup` in
`Base.declares`, `defined?`-versus-`||=` on a legitimately-nil read, the
`blank?`-before-`expect` guard, `to_h`'s indifferent access.

## `default_size` and `supports` are validated on read, not on write

The pair used to be checked inside `supports`, which made the two macros
**order-dependent**. `ValueBase` ships `supports :small`, so a widget widening it
writes:

```ruby
default_size :medium
supports :small, :medium
```

and the eager check rejected it — the default is not yet among the supported sizes
at the moment `default_size` runs, and `supports` had already inherited `[:small]`.
Ruby reads a class body top to bottom; a macro that cares which order two of them
appear in is a trap, and the trap fired on a class that is perfectly valid once both
lines have run.

Validation moved to the `default_size` reader, so order stops mattering.
`Bali::Widget.check_catalog!` — run by the `dashboard_widgets` macro, after every
class body — restores the boot-time failure for anything actually on a dashboard.
`supports :small, :medium, default: :medium` does both in one line for hosts who
prefer it.

## `list` takes a block, never a relation

A class body is evaluated once at boot, so a relation passed by value freezes
whatever it closed over. `where(due_date: Date.current..)` becomes *the day the
process started*, and the tile shows the wrong week until a redeploy.

The reloader re-runs class bodies in development, so the bug cannot reproduce there
and is silent in production — the worst shape an API hazard can have. This widget
set shipped it twice before the block form was made mandatory.

The block also runs against the widget, so it reaches `context`: a frozen scope
could never be tenant- or user-scoped, which is most widgets in a real host.

Ordering goes **inside** the scope rather than in a keyword of its own. `limit` is
applied after the block returns, so a scope that orders itself is always ordered
before it is paged.

## `Charted` is a module, not a `ChartedBase`

`Base → ChartedBase → {TrendBase, ProgressBase}` would work and would keep single
inheritance. It was rejected because `*Base` is host-facing vocabulary and **the
pattern is the type**: a sixth `*Base` reads as a sixth pattern to inherit from,
and nothing inherits from this one.

A middle class also fixes a taxonomy that is not obviously right. A list widget
with a sparkline beside its count is a plausible thing to want — that is
`include Charted` on `ListBase`, one line. With a middle class it is a
re-parenting, and `ListBase` cannot have two parents.

## `adopt` is idempotent, not locked

Two locks were tried and both were wrong. See the "There is no locking" section of
`docs/guides/engine-models.md`, which records what each one failed to buy and names
the primitive that would actually work.
