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

Dropdown items that trigger a non-GET request (POST/PATCH/DELETE) stop being links with
`data-turbo-method` and become real `button_to` forms.

*Lands with the #641 PR; details land with it.*

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

Five icon names that Bali's legacy SVGs were shadowing resolve to their Lucide drawing
instead: the name keeps working, the glyph changes. The full before/after table lands here
— and also in [the v2 → v3 guide](migration-v2-to-v3.md), because it affects anyone
migrating from v1/v2 as well.

*Lands with the #902 PR; details land with it.*
