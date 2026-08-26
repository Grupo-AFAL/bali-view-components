# The widget size ladder: progressive disclosure across four canvases

**Date:** 2026-08-26
**Branch:** `feat/widgets-and-widget-grid` (or a follow-on branch off it)
**Depends on:** `docs/superpowers/specs/2026-08-25-widgets-and-widget-grid-design.md`

## The problem

The shipped card changes *what it shows* as it grows. Apple's widget families change *how much
context they give the same fact*. Those are different products.

Today, `ROWS = { small: 0, medium: 3, large: 7, wide: 3 }` drives everything, and `count`
appears in exactly two places in the template: the small-size stat (`component.html.erb:131`)
and interpolated into the "View all 6" header link (`:151`). So the headline number exists at
`small` and nowhere else — at `medium` it is replaced by a three-row list.

That is **substitution**. The target is **disclosure**: the fact stays and earns context.

Concretely, three ladders have to be expressible, and only the second is today:

1. **number → number + trend → number + trend + breakdown** — the most common by far, and
   currently impossible: `Result` carries no delta, direction or comparison period.
2. **item → list of items** — works today, and is the only thing that works.
3. **ring → ring + history** — impossible: the library has no radial primitive at all
   (`Bali::Progress` is linear; nothing uses daisyUI's `radial-progress`).

## The window

The feature is unreleased (`CHANGELOG.md`, `## [Unreleased]`) and enjoykitchen cannot adopt it
until its 2.9 → 3.x upgrade. `Result`'s shape, the `SIZES` vocabulary and `wide`'s geometry can
change with **no deprecation cycle**. That window closes at the next release, which is why this
is worth doing now rather than as a v4 migration.

## Decisions taken before planning

| Question | Decision |
|---|---|
| What becomes the extra-large? | **Retarget `wide` from 4×1 to 4×2 two-column.** No fifth size. |
| How is the chart region rendered? | **`Bali::Chart` at every size**, configured axis-less below `large`. |
| Scope | **All three patterns**, including the missing gauge primitive. |

On the chart decision: `Bali::Chart`'s controller already does `await import('chart.js')`
(`chart/index.js:52`), so the library is fetched once and shared. The marginal cost of a tile is
a `Chart` instance plus a canvas, not a bundle — much cheaper than it first looks. Task 7 still
carries a mitigation, because twelve live instances with their own resize observers is real.

## The region model

The card stops being a size-switch over one body and becomes **three optional regions that fill
in as the canvas grows**:

- **`headline`** — the fact. Value, label, and optionally a trend.
- **`context`** — how the fact is moving. A chart, or a gauge.
- **`detail`** — the breakdown. The existing row list.

| Size | Grid | Regions | Notes |
|---|---|---|---|
| `small` | 1×1 | headline | Whole tile is one link. Nothing inside is focusable. |
| `medium` | 2×1 | headline · context | Context is axis-less — a sparkline, per the <2×2 rule. |
| `large` | 2×2 | headline / context / detail | Context gets axes. Detail below. |
| `wide` | 4×2 | [headline · context] │ [detail] | Two columns; detail column takes more rows. |

### Regions degrade, which is what keeps existing widgets working

A widget that supplies only `count` and `items` — every widget written against today's contract
— renders with the context region **omitted** and detail expanded to fill it. Nothing a host has
already written breaks; richer widgets simply fill more of the canvas. This is the property that
makes the whole change additive rather than a migration, and it must be asserted in tests, not
assumed.

## Task 1 — Value objects and `Result`

New siblings in `app/lib/bali/widget/`:

```ruby
# The comparison, not the conclusion. `direction` is the raw movement; whether that
# movement is GOOD is `positive_when`, because "up" is not universally good — overdue
# tasks up 12% and revenue up 12% must not be the same colour.
Trend = Data.define(:delta, :direction, :period, :positive_when) do
  def initialize(delta:, direction: nil, period: nil, positive_when: :up)
    super(delta:, direction: direction || (delta.to_f.negative? ? :down : :up), period:, positive_when:)
  end

  def good? = direction == positive_when
  def flat? = delta.to_f.zero?
end

# What the context region charts. `type` is a Bali::Chart type, defaulting to a line
# because the sparkline case is the common one.
Series = Data.define(:labels, :values, :type) do
  def initialize(values:, labels: [], type: :line) = super
end

# The ring. `max` rather than a percentage so the card can render "7 / 10" as well as 70%.
Gauge = Data.define(:value, :max, :label) do
  def initialize(value:, max: 100, label: nil) = super
end
```

`Result` gains three fields and one override:

```ruby
Result = Data.define(:count, :items, :view_all_path, :payload, :failed,
                     :display_value, :trend, :series, :gauge)
```

`display_value` exists for the 4–6 character constraint: `count` may be `1_234_567`, which
overflows a 215px tile at `text-4xl`. It defaults to `Bali::Widget.abbreviate(count)` and a
widget overrides it for `"72%"` or `"$1.2k"`.

```ruby
def Bali::Widget.abbreviate(number)  # 1_234 -> "1.2k", 1_234_567 -> "1.2M"
```

**Tests:** `Trend#good?` under both `positive_when` values; `direction` inferred from a negative
delta; `abbreviate` at each threshold boundary and for nil; `Result` defaults leaving all four
new fields nil so today's widgets are unchanged.

## Task 2 — `Bali::Gauge::Component`

The library has no ring. daisyUI 5 ships `radial-progress`, which is CSS-only — no canvas, no JS,
no per-instance cost — so the ring pattern costs far less than the chart one.

A real component rather than raw daisyUI markup inside the card, per the composition rule in
`.claude/CLAUDE.md`: a ring is useful well beyond widgets.

```ruby
render Bali::Gauge::Component.new(value: 7, max: 10, label: "shifts", size: :md, color: :primary)
```

Accessibility is the part to get right: `role="progressbar"` with `aria-valuenow`,
`aria-valuemin`, `aria-valuemax` and an `aria-label`. daisyUI's own example emits none of these.

**Tests:** the ARIA quartet; `value > max` clamping; zero and nil; the percentage maths.
**Preview:** `@param value`, `@param max`, `@param color`, `@param size`.

## Task 3 — `REGIONS` replaces `ROWS`

```ruby
# What each canvas has room for. Replaces ROWS, which could only answer "how many rows"
# and so could only express one of the three ladders.
REGIONS = {
  small:  { headline: :hero, context: nil,        detail: 0 },
  medium: { headline: :inline, context: :spark,   detail: 0 },
  large:  { headline: :header, context: :full,    detail: 7 },
  wide:   { headline: :header, context: :full,    detail: 6 }
}.freeze
```

`ROWS` is deleted; `rows` reads `REGIONS[size][:detail]`. `summary?` becomes
`headline_style == :hero`.

Predicates the template asks instead of branching on size directly: `hero_headline?`,
`context?` (region wants one **and** the result supplies `series` or `gauge`), `detail?`,
`two_column?`.

**Tests:** each size selects the right region set; `context?` false when the widget supplies
neither series nor gauge — the degradation property above.

## Task 4 — Retarget `wide` to 4×2

`widget_grid/index.css`: `[data-size="wide"]` gains `grid-row: span 2 / span 2`. At the `md`
breakpoint it keeps `span 2` columns like the others, with two rows.

`CELLS` in `widget/component.rb` currently draws `wide` as `[0, 1, 2, 3]` — the top row of the
4×2 lattice. It becomes `[0, 1, 2, 3, 4, 5, 6, 7]`, the whole lattice, which is what the size now
means. `large` (`[0, 1, 4, 5]`) is unchanged and stays distinguishable.

Locale: `bali_view.widgets.edit.sizes.wide` reads "Wide" / "Ancho". It now means full-width **and**
double-height. Rename the string's content to "Extra large" / "Extra grande", keeping the key —
the key is the persisted `size` value and renaming it would orphan every stored row.

**Tests:** the lattice glyph for `wide` fills all eight cells; a stored `"wide"` still resolves.

## Task 5 — Template rebuild

The template becomes four layouts over the three regions, in this precedence:

1. **`failed?`** — unchanged, and still first. The reasoning in the existing comment holds
   exactly: a failed widget has `count: 0`, and a confident grey "0" is this dashboard's word for
   *all clear*.
2. **`hero_headline?`** (small) — the stat, whole tile linked. **Nothing inside may be
   focusable**, which is the one-tap-target constraint. A trend renders here as text, never a
   link. This also preserves today's documented behaviour that a custom-bodied widget dropped to
   small still renders as a stat.
3. **regions** — headline, then context if present, then detail; two-column at `wide`.

The `body` slot keeps working and now replaces the **detail** region only, so a host that fills
it still gets the headline and context it did not have to write.

## Task 6 — Trend rendering

An arrow glyph, the delta, and the period label: `↑ 12%` with `vs last week` beneath or beside,
depending on region style.

Colour comes from `Trend#good?`, never from `direction` — `text-success` when good,
`text-error` when not, `text-base-content/60` when flat. A widget of overdue counts declares
`positive_when: :down` and a rising number then reads red, which is the entire point of carrying
the field.

The arrow is decorative (`aria-hidden`); the accessible text is the delta plus the period, so a
screen reader hears "up 12 percent, vs last week" rather than "up arrow 12%".

New i18n under `bali_view.widgets.trend.*`: `up`, `down`, `flat`, and `since` — en and es.

## Task 7 — Chart integration, size-aware

One private method builds `Bali::Chart::Component` options from the region style:

- `:spark` (medium) — `scales: { x: { display: false }, y: { display: false } }`,
  `plugins: { legend: { display: false }, tooltip: { enabled: false } }`,
  `elements: { point: { radius: 0 } }`. This is your "<2×2 loses its axes" rule, expressed as
  Chart.js config.
- `:full` (large, wide) — axes and tooltips on, legend still off; a legend inside a 16rem tile
  costs more than it explains.

**Mitigation for the instance cost, inside the chosen approach:** the card renders the chart
region only when the widget actually supplies a `series`, so a dashboard of list widgets creates
zero Chart instances. Twelve *charted* tiles remain twelve instances — acceptable, and the
dynamic import means one library fetch. If it does become a problem in practice, the next lever
is gating `chart#connect` on an `IntersectionObserver`, which is a change inside
`chart/index.js` and benefits every chart in the library, not just widgets.

## Task 8 — Previews

`widget/preview.rb` gains `@param pattern select [list, metric, gauge]` alongside the existing
size and state toggles, so all three ladders are visible in Lookbook at every size. The grid
preview's `SPECIMENS` gains one widget per pattern.

## Task 9 — Tests

**Minitest** — the region matrix is the point: each of the three patterns at each of the four
sizes, twelve assertions of what renders and what does not. Plus: a today-shaped widget
(`count` + `items` only) renders at every size with the context region absent; the small size
contains no focusable element; trend colour follows `good?` and not `direction`.

**Cypress** — resize one card through all four sizes and assert the regions appear and
disappear, which is the ladder itself and the one thing a component test cannot see. Runs
headless; Chrome is wedged on this machine and hangs the suite.

## Task 10 — Documentation

- `docs/guides/components.md` — the ladder table, the three patterns, and the `positive_when`
  rule, which is the one thing a host will otherwise get wrong.
- `docs/guides/engine-models.md` — `Result`'s new fields in the widget-contract section.
- `docs/superpowers/specs/2026-08-25-widgets-and-widget-grid-design.md` — the "Body precedence"
  section describes `ROWS` and a four-step precedence that this replaces. Update it rather than
  leaving the spec describing deleted code, which is exactly the drift the `lock_rows` reconcile
  had to fix.
- `CHANGELOG.md` — folded into the existing unreleased Widget entry, since none of this ever
  shipped separately.

## Risks

- **`Result` grows to nine fields.** Three are a group (`trend`, `series`, `gauge`) and could be
  one `context:` field holding whichever object applies. Nine positional fields on a `Data` is
  the smell to watch; if Task 1 feels crowded when written, collapse them before Task 3 depends
  on the shape.
- **`wide` changing height is invisible to a stored row.** An owner who chose `wide` under the
  old geometry gets a tile twice as tall on next load. Correct — it is the same size name with a
  better layout — but worth one line in the CHANGELOG rather than letting someone discover it.
- **Twelve Chart instances** is the accepted cost of the chosen approach, bounded by rendering
  the region only when a series exists, with the `IntersectionObserver` lever held in reserve.
