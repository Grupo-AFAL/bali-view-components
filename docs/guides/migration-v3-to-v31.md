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

A `Bali::Card` (and `Bali::StatCard`) constructed with `href:` renders its root element as
an `<a>` instead of wrapping a link inside a `<div>`.

*Lands with the #729 PR; details land with it.*

## Five shadowed icons change their drawing (#902)

Five icon names that Bali's legacy SVGs were shadowing resolve to their Lucide drawing
instead: the name keeps working, the glyph changes. The full before/after table lands here
— and also in [the v2 → v3 guide](migration-v2-to-v3.md), because it affects anyone
migrating from v1/v2 as well.

*Lands with the #902 PR; details land with it.*
