# Dark mode: validated themes and a switch in the user menu — Design

Date: 2026-10-01
Status: Approved (brainstorming) — 2026-10-01

## Purpose

The group's apps have no dark mode. Bali already ships `afal-dark`, but as a draft nobody has
validated or turned on, and Costa Norte has no dark theme in Bali: the costa-norte app defines a
`costa-norte-dark` of its own only to paint its sidebar dark.

This design delivers two validated dark themes — one for AFAL, one for Costa Norte — and a way
for each person to choose light or dark from the user menu, with no app changing until it opts
in.

## Decisions (from the brainstorming session)

| Question | Decision |
|---|---|
| How a person reaches dark mode | A switch; it lives in the user menu (`Bali::Topbar::UserMenu`), not in the Topbar |
| Where the choice is remembered | A browser cookie, which the server reads to paint the page already dark |
| What someone who has not chosen sees | Light. The switch has two positions: light and dark |
| Where the dark Costa Norte comes from | The `costa-norte-dark` the app already uses on its sidebar, completed into a whole theme |

## 1. The themes

**`afal-dark`** exists in `app/assets/stylesheets/bali/themes/afal-dark.css`. It is validated in
full (section 4) and the tokens that fail are adjusted. After the visual approval its header stops
saying "DRAFT / EXPERIMENTAL".

**`costa-norte-dark`** is new, in `app/assets/stylesheets/bali/themes/costa-norte-dark.css`. It
starts from the values costa-norte has today in `app/assets/tailwind/application.css` (dark teal
surfaces, gold primary, light text) **without changing them**, so the app can delete its block on
upgrading and its sidebar looks the same. It is completed with what a whole theme needs and
validated like `afal-dark`.

Both are published through the same `package.json` `exports` that already serves
`css/themes/*.css`, so an app imports them with
`@import "bali-view-components/css/themes/<theme>.css";`.

## 2. Adoption in an app

Three changes per app, which the CHANGELOG names:

1. **Configuration.** In `config/initializers/bali.rb`:
   `Bali.themes = { light: "afal", dark: "afal-dark" }` (costa-norte: `costa-norte` /
   `costa-norte-dark`). Without this line nothing changes: there is no switch and the helper
   answers the light theme.
2. **Layout.** `<html data-theme="afal">` becomes `<html data-theme="<%= bali_theme %>">`.
   `bali_theme` (a Bali helper exposed to the host's views, like `react_island_meta_tags`) reads
   the cookie and answers the configured light or dark theme. The server decides: the page
   arrives already dark, with no flash.
3. **Tailwind's `dark:` variant.** The app's `@custom-variant dark (...)` line adds its dark
   theme, so `dark:` classes fire under it too.

**The cookie** is called `bali_theme` and holds `light` or `dark`, with `path=/`, one year and
`SameSite=Lax`. It is not `HttpOnly`: the switch's JS writes it. Name and values are a contract
between Ruby (which reads it) and JS (which writes it): the same pattern on both sides, each
naming the other, with a test on each side. Any other value reads as light.

**Known limit:** the choice is per app and per device; each app lives on its own domain and a
cookie does not cross it. A fleet-wide preference would need storing it on the account
(Pasaporte), outside this design.

## 3. The switch

- **Where:** an item of `Bali::Topbar::UserMenu`, between the app's items and "Sign out". It is
  only rendered when `Bali.themes` declares a `dark:` theme.
- **How it looks:** "Dark mode" with a moon icon and a visual switch on the right showing the
  state. The label does not change with the state.
- **Accessibility:** a `<button role="menuitemcheckbox" aria-checked="true|false">`. The dropdown
  controller walks the `menuitem*` roles with the arrow keys, not only `menuitem`, so the item
  joins the keyboard support #1244 left.
- **What it does:** a Stimulus controller flips `<html data-theme>` to the other theme of the
  pair, writes the cookie and updates `aria-checked`, without reloading. The menu stays open (a
  click inside the menu does not close it), so the person sees the change and can undo it.
- **The theme names** travel from Ruby to the controller as Stimulus values, from
  `Bali.themes`; they are not written in the JS.
- **Copy:** `bali_view.topbar.user_menu.dark_mode` — "Dark mode" / "Modo oscuro".
- **Out of scope:** a standalone switch outside the user menu. identity, the only app without
  `UserMenu`, migrates its topbar in Grupo-AFAL/identity#350.

## 4. Validation

- **Contrast sweep** of every Lookbook preview under `afal-dark` and `costa-norte-dark`, with
  real painting (`paintedContrast`, which composites alpha, opacity and translucent grounds):
  text at 4.5:1. What fails because of the theme is fixed in the theme; what is a component's
  own recipe goes to a separate issue.
- **Permanent guards:** a single theme list in `cypress/support/`, shared by the contrast guards
  and adding `costa-norte-dark` (settles the duplicated-list part of #1252).
  `test/bali/themes_test.rb` requires the new file and its completeness.
- **ThemeSampler:** a `costa-norte-dark` page next to the `afal-dark` one; screenshots of both
  for the visual approval.
- **Switch tests:** Minitest (the helper by cookie and configuration; the item only with `dark:`
  configured; its markup) and Cypress (the click flips the theme and writes the cookie; a reload
  stays dark; `aria-checked`; keyboard). Each with its negative control.

## 5. Rollout

1. Bali publishes the themes and the switch; no app changes until it configures them.
2. The CHANGELOG carries the steps of section 2.
3. It is turned on first in an AFAL pilot app and in costa-norte, and tried in real use before
   it is extended.
