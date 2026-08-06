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

Options passed to a tab item start landing on the `<a>` element itself instead of its
wrapper, alongside the rest of what #722 adds to `Bali::Tabs`.

*Lands with the #722 PR; details land with it.*

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
