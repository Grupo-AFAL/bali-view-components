# Migrating from Bali v3.0 to v3.1

This guide is for hosts on **v3.0.x** upgrading to **v3.1**. If you are coming from v2 (or
v1), read [Migrating from Bali v2 to v3](migration-v2-to-v3.md) first — everything there
still applies, and this guide only covers what changes *after* it.

v3.1 is an additive release with one deliberate exception: **five announced changes of
markup or behaviour, admitted as a block**. The policy behind them: the universe of hosts
on v3 is closed, pinned and measured — every blast radius below was quantified against real
host code before the change was approved, and each change ships with an explicit CHANGELOG
entry. The alternative (deferring all five to v4) was considered and rejected once, for all
five together, so no individual PR relitigates it.

The five sections below are placeholders on purpose. This document is the vehicle; each PR
brings its own section — what breaks, what replaces it, and the measurement that sized it.
Until a section says otherwise, the v3.0 behaviour it describes is still what ships.

## Residual daisyUI 4 classes outside the FormBuilder (#903)

v3.0 moved the library to daisyUI 5, but a handful of daisyUI 4 class names survived
outside the FormBuilder. v3.1 removes them.

*Lands with the #903 PR; details land with it.*

## `ActionsDropdown` POST items become `button_to` (#641)

**What changes.** A `Dropdown` / `ActionsDropdown` item with `method: :post`, `:patch` or
`:put` used to render `<a data-turbo-method="...">`. It now renders a real `button_to` —
`<form class="contents" method="post"><button type="submit">` (with the `_method` override
for `:patch`/`:put`) — the exact shape the `:delete` item has had since #829, form out of
the box tree and the button as the menu item.

**Why.** `<a data-turbo-method>` degrades to a GET *navigation* when Turbo is not running,
and a control that mutates state is a button, not a link — assistive tech announces the
two differently, and Space activates only the button. The `:delete` item already paid for
the `button_to` pattern; this closes the inconsistency between two items of the same menu.

**What to do.** For behaviour, nothing: the click submits the same request. Update
anything that *selects* those items as anchors — CSS on `.menu a`, Capybara `click_link`,
Cypress `get('a[data-turbo-method]')` — to target the button (`form.contents > button` is
the stable shape). `data:` passed to `with_item` still lands on the button, so
`data: { turbo_confirm: }` keeps working; form-level attributes go through `form: {}`.

**Blast radius, measured** (grep over every consuming app, six-line window after each
`with_item`): 6 call sites total. One in afal-apps — the "Activar" item of
`prodigia/credentials/index.html.erb`, on v3.0.0 today, which changes markup on the bump
to v3.1 and keeps its behaviour (Turbo submits the same POST). Five in enjoykitchen's
flamingOS, all the same "archive" action, and that host is locked to a v2-era revision —
they change whenever it takes the v2→v3 migration. Zero in the dummy and zero anywhere
else: the apps the issue was opened for hand-rolled their menus precisely because v2's
`with_item` rejected non-GET/DELETE verbs.

Plain `Bali::Link::Component.new(method: :post)` outside a dropdown is untouched: it keeps
emitting `data-turbo-method`.

## Tabs: `options` reach the `<a>` (#722)

**What changes.** In navigation mode — every tab has an `href:`, the component renders a
`<nav>` of links — the `**options` passed to `with_tab` now land on the `<a>` element
itself. In v3.0 they were merged into the attributes of a panel `<div>` that navigation
mode never renders, so they silently vanished. `class` composes with the tab classes
(`tab`, `tab-active`) instead of replacing them.

Panel mode is untouched: without `href:`, the tab's `**options` keep going to its
`role="tabpanel"` div, hidden-until-active as always.

**Who is affected.** Only a call site that passes extra options to an `href:` tab *and*
depends on them being ignored — measured across the pinned hosts, no such call site
exists; what does exist is the opposite (gc needs `data:` attributes on its tab links and
had no way to get them there). If you migrate hand-rolled tab markup, this is what makes
`data-bali-test`, tracking attributes, or an extra utility class on a tab link possible:

```erb
<%= render Bali::Tabs::Component.new(label: "Inbox scopes") do |tabs| %>
  <% tabs.with_tab(title: "Mine", href: inbox_path(scope: :mine),
                   data: { bali_test: "inbox-mine" }) %>
<% end %>
```

**Also new in the same PR (additive).** `with_tab` gains `count:` (a badge after the
title; `nil` renders nothing, `0` renders) and `turbo_action:` — in navigation mode every
link now emits `data-turbo-action="advance"` by default. On full-page visits that is a
no-op (advance is Turbo's default); inside a `turbo_frame` it promotes the visit to the
URL. If a tab must not touch the URL, pass `turbo_action: false`.

## Card root becomes an `<a>` when given `href:` (#729)

**What changes.** `Bali::Card` gains `href:`. When present, the card's root element renders
as `<a class="card">` instead of `<div class="card">`, with a hover affordance
(`transition-shadow hover:shadow-md`). `Bali::StatCard` gains the same `href:` and
propagates it to its inner Card, and `DashboardPage#with_stat` gains `href:` so a stat in
the grid drills down to its listing. Without `href:` nothing changes: the root stays a
`<div>` and the markup is byte-identical to v3.0.

```erb
<%# v3.0 — the wrapper pattern (still works, but stop writing it) %>
<%= link_to dashboard_orders_path do %>
  <%= render Bali::StatCard::Component.new(title: 'Open Orders', value: '87', icon: 'shopping-cart') %>
<% end %>

<%# v3.1 %>
<%= render Bali::StatCard::Component.new(
  title: 'Open Orders', value: '87', icon: 'shopping-cart',
  href: dashboard_orders_path
) %>
```

**Who is affected.** The change only activates at call sites that pass `href:`, so nothing
breaks on upgrade day. What the announcement covers is the *adoption*:

- **Host test selectors.** A spec that asserts `div.card` (or wraps the card in `link_to`
  and asserts `a > div.card`) breaks the moment that call site adopts `href:` — the
  wrapper `<a>` is gone and the card root itself is the `<a>`. Measured against the pinned
  hosts, the wrapper pattern exists in costa-norte's dashboard
  (`app/views/dashboard/show.html.erb`); that is the call site this exists for.
- **`DashboardPage::Stat` grows from five members to six.** The v3 migration guide
  promised "Stat still exists with the same five members"; `href` is the sixth. Keyword
  construction (`Stat.new(label:, value:, icon:, change:, color:)`) keeps working —
  `Data.define` fills the missing member only through `with_stat`, which is the only
  constructor Bali itself calls — but *positional* construction of the Data class outside
  Bali (`Stat.new("Users", "1,234", "users", nil, :primary)`) now raises `ArgumentError:
  missing keyword`. No pinned host constructs the Data directly.

**One rule the browser enforces, not Bali.** An `<a>` must not contain interactive
content: with `href:`, the card's body, actions, and StatCard's `footer` must not contain
links or buttons — browsers recover from `<a><a></a></a>` by splitting the outer link,
and the card stops being one target. If a card needs its own inner actions, keep the card
a `<div>` and link the parts instead (the deliberately rejected alternative was a
stretched-link pseudo-element — complexity without a consumer).

## Five shadowed icons change their drawing (#902)

**What changes.** `Bali::Icon` consults the legacy name map (`LucideMapping`) *before*
trying a name as a Lucide icon, so a map key that is itself a current Lucide name and
points at a different glyph made the honest drawing of that name unreachable — you read
lucide.dev, wrote the name, and Bali silently drew something else. Five such entries are
removed. The names keep resolving; what they draw changes:

| Name | Drew until v3.0 | Draws in v3.1 | Want the old drawing? |
|---|---|---|---|
| `trash` | `trash-2` — bin with two inner vertical lines | Lucide `trash` — plain bin | write `trash-2` |
| `cog` | `settings` — gear with a single toothed outline | Lucide `cog` — double cog wheel | write `settings` |
| `expand` | `maximize` — four corner brackets | Lucide `expand` — diagonal out-pointing arrows | write `maximize` |
| `indent` | `indent-increase` | Lucide `indent` — same shape, legacy encoding | write `indent-increase` |
| `outdent` | `indent-decrease` | Lucide `outdent` — same shape, legacy encoding | write `indent-decrease` |

**Who is affected.** Measured across every host in the org (124 one-line call sites of all
shadowed names): the pinned v3 hosts have **zero** call sites of these five — the visible
delta lands on v1/v2 hosts the day they migrate, which is why the same table also sits in
[the v2 → v3 guide](migration-v2-to-v3.md). `indent`/`outdent` have zero call sites
anywhere and draw the same shape anyway; `trash` is the only name with real surface, and
its delta is the two lines inside the bin. `Bali::DeleteLink`'s default icon is unchanged
visually — it now spells its default `trash-2` internally.

**What deliberately does not change.** `check-circle => circle-check` and `edit => pencil`
stay mapped, documented as exceptions in `lucide_mapping.rb`: their "honest" spellings are
deprecated Lucide aliases — `check-circle` ships as a legacy glyph (the check overflowing
the circle), and `edit`'s real rename is `square-pen`, so dropping either entry would make
drawings worse, not truer. `plus-circle => circle-plus` also stays: it draws the same
thing and only protects against the alias file disappearing. The 60 identity entries
(`"check" => "check"`, …) were removed too — a no-op, since the direct-Lucide step
resolves those names identically.

The shadowing test (`test/bali/components/icon/lucide_mapping_test.rb`) freezes the three
surviving entries and pins the five removed names to the direct-Lucide step, so the set
can only shrink from here.

---

## Adoption notes (additive — not part of the five)

Everything below is opt-in housekeeping: nothing renders differently until you act.

### Adopt the gem-shipped AFAL theme (#718)

v3.1 publishes the AFAL brand theme in the gem — `css/themes/afal.css`, plus a **draft**
`afal-dark` — so the `[data-theme="afal"]` block your app carries by hand can finally be
deleted.

**Every app, in the SAME commit** (while both copies exist, whichever comes later in the
compiled CSS silently wins):

1. Add the import to your Tailwind entry point:

   ```css
   @import "bali-view-components/css/themes/afal.css";
   ```

2. Delete your local copy:
   - **gobierno-corporativo, afal-apps, identity, opina**: delete the
     `[data-theme="afal"]` block from `app/assets/tailwind/application.css`. The gem file
     is byte-identical to it, so nothing changes visually.
   - **centinela-web**: delete `app/assets/tailwind/themes/afal.css` (and its import).
     **Expect a visible delta** — centinela's copy came from an independent OKLCH
     conversion of the same hex values, so its secondary (a darker, differently-hued
     violet), accent, neutral and the five status pairs all shift to the canonical
     values. Screenshot before/after in the adoption PR.

3. Optionally clean the phantom declaration: `afal --default, afal-dark` inside
   `@plugin "daisyui" { themes: ... }` never registered anything (daisyUI does not know
   those names — the unlayered `[data-theme]` block does all the work). Keep or drop it;
   dropping it removes the implication that daisyUI defines these themes.

`afal-dark` remains **draft/experimental**: no app activates it today, and its tokens may
change before it is announced as stable. If you want to try it, see
[Custom Themes](custom-themes.md) — including the `@custom-variant dark` extension needed
for `dark:` utilities to fire under it.

While migrating, also fix your `@source` glob if it scans only `{rb,erb}`: Bali writes
some classes from JavaScript (the drawer submit spinner among them), so the canonical glob
is `node_modules/bali-view-components/app/**/*.{rb,erb,js}` — see
[Installation](installation.md).

### The Gantt gained `mode: :interactive` (#719)

`Bali::Gantt` shipped in v3.1 in three steps, and this is the last of them: the component
now renders the React Flow island as well as the static board. **Nothing changes for
existing call sites** — `mode:` still defaults to `:static`, and every option it took
before means the same thing.

What is new is that `mode: :interactive` no longer raises. It renders the static board
*inside* the island's mount element and React replaces it on connect, so an interactive
Gantt is also a working one before the bundle lands and with JavaScript off. `fallback:
:skeleton` swaps that board for a neutral placeholder if you would rather not pay for
rendering it twice.

Going interactive is additive work — the island needs a bundler entry, the loader and the
meta tags, and the host implements the mutation endpoints the island posts to.
[../api/gantt.md](../api/gantt.md) is the whole circuit, including the broadcast contract
and why echo suppression is the host's job.

If you upgraded from v2, note that `bali-view-components/gantt` resolves again in v3.1 —
see the warning in [migration-v2-to-v3.md](migration-v2-to-v3.md#the-gantt-chart-is-gone).
