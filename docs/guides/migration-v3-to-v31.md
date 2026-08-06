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

A `Bali::Card` (and `Bali::StatCard`) constructed with `href:` renders its root element as
an `<a>` instead of wrapping a link inside a `<div>`.

*Lands with the #729 PR; details land with it.*

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
