# Custom Themes

Bali ships optional DaisyUI themes that you can import alongside the default `light` and `dark` themes.

## Available Themes

| Theme | File | Description |
|-------|------|-------------|
| `afal` | `css/themes/afal.css` | Grupo AFAL brand - light variant with blue/violet/amber palette |
| `afal-dark` | `css/themes/afal-dark.css` | Dark variant of `afal` |
| `costa-norte` | `css/themes/costa-norte.css` | Costa Norte brand - light variant with teal/gold palette |
| `costa-norte-dark` | `css/themes/costa-norte-dark.css` | Dark variant of `costa-norte`: the dark teal and gold of costa-norte's sidebar |

## Installation

### 1. Import the theme CSS

In your Tailwind CSS entry point (e.g., `application.css`):

```css
@import "tailwindcss";
@plugin "daisyui" {
  themes: light --default, dark;
}

/* Bali themes */
@import "bali-view-components/css/themes/costa-norte.css";
```

### 2. Activate the theme

Set `data-theme` on your `<html>` element:

```html
<html data-theme="costa-norte">
```

Or apply it to a specific section:

```html
<div data-theme="costa-norte">
  <!-- This section uses Costa Norte colors -->
</div>
```

## The AFAL Theme

`afal` is the canonical copy of the `[data-theme="afal"]` block that gobierno-corporativo,
afal-apps, identity and opina used to carry byte-identically in their own CSS, with its primary
and secondary one step darker so white text on them clears AA (the header of `afal.css` has the
measurements). If your app still has a local copy, delete it **in the same commit** that adds
the import — while both exist, whichever appears later in the compiled CSS wins, silently.

```css
@import "bali-view-components/css/themes/afal.css";
@import "bali-view-components/css/themes/afal-dark.css"; /* for dark mode */
```

```html
<html data-theme="afal">
```

Listing `afal` in your `@plugin "daisyui" { themes: ... }` block is **not** what makes the
theme work — daisyUI does not know these names, and listing an unknown name registers
nothing. The theming comes entirely from the unlayered `[data-theme="afal"]` block, which
wins over daisyUI's own themes by layer order. You can drop `afal` and `afal-dark` from the
plugin's `themes:` list when you adopt the imports.

## Dark mode

Each brand has a dark theme: `afal-dark` and `costa-norte-dark`. Nobody sees one until the app
opts in, and then only the people who choose it: the light theme stays the default.

### 1. Declare the pair

In `config/initializers/bali.rb`:

```ruby
Bali.themes = { light: "afal", dark: "afal-dark" }
# costa-norte: { light: "costa-norte", dark: "costa-norte-dark" }
```

Without `dark:` there is no switch, and `bali_theme` always answers the light theme. A key other
than `light:` and `dark:`, or a pair without `light:`, raises when the initializer runs.

### 2. Let the server paint every `<html>`

```erb
<html data-theme="<%= bali_theme %>">
```

In **every** layout. `bali_theme` reads the `bali_theme` cookie and answers the dark theme only
when the person chose it, so a dark page arrives dark instead of flashing light first. Turbo
copies only `lang` and `dir` from the new `<html>` when it navigates, so a layout that still says
`data-theme="afal"` leaves the page in whatever theme the previous one had. Import both theme files.

### 3. The switch

`Bali::Topbar::UserMenu` adds a **Dark mode** item, between your items and sign out, as soon as
`Bali.themes` declares a `dark:` theme. It is a `menuitemcheckbox`: a click (or Enter / Space)
flips `<html data-theme>` in place, writes the cookie for a year and leaves the menu open; charts
repaint with the new theme. The choice is per app and per device — a cookie does not cross the
apps' domains.

### 4. The `dark:` variant

If your app defines a `@custom-variant dark` so `dark:` utilities follow the theme (all AFAL
hosts do), extend it with your dark theme, or `dark:` keeps its light styling under it:

```css
@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *, [data-theme=afal-dark], [data-theme=afal-dark] *));
```

### 5. Fixed colours in your views

A class that names a colour instead of a theme token does not follow the theme: a `bg-white`
card stays white under `afal-dark`, now with light text on it. Before turning dark mode on, swap
them for tokens — `bg-white` for `bg-base-100` (or nothing on a `Bali::Card`, which already
paints it), `text-gray-*` for `text-base-content` at the opacity you need:

```sh
git grep -n -E 'bg-white|bg-gray-|text-gray-' -- app/views app/components
```

`text-neutral` belongs on that list too. On the dark themes `neutral` is a dark fill, as in
daisyUI's own `dark`, and as text it does not read on the page; `text-base-content` is the same
colour on `afal` and `costa-norte`:

```sh
git grep -n -E 'text-neutral([^-]|$)' -- app
```

### 6. No `color-scheme` of your own

Every theme declares its own `color-scheme`. The browser paints scrollbars and native controls
by it, and `text-soft-error`, the Gantt's error pill, the BlockEditor and the FeedbackWidget's
panel read it to choose their light or dark face. An app rule that sets it on the root

```css
:root { color-scheme: light; }
```

has the specificity of `[data-theme="afal-dark"]`, so unlayered and after the theme's `@import`
it wins; daisyUI's own `dark` sits in a layer and loses to it wherever it is written. Under
`afal-dark` the page stays `light`, and `text-soft-error` paints its light-theme ink, 2.49:1 on
the dark `base-100` instead of 10.64. Delete it, and a `[data-theme="dark"] { color-scheme: dark; }`
with it, which daisyUI's `dark` already declares:

```sh
git grep -n 'color-scheme' -- '*.css'
```

Preview both dark themes in Lookbook under *Theme Sampler → Afal Dark* and *Costa Norte Dark*.

## Creating Your Own Theme

Use any Bali theme as a starting point. A theme is a plain CSS file that sets DaisyUI's CSS custom properties under a `[data-theme="your-name"]` selector.

Required variables:

```css
[data-theme="my-theme"] {
  color-scheme: light; /* or dark */

  /* Core palette */
  --color-base-100: oklch(/* ... */);
  --color-base-200: oklch(/* ... */);
  --color-base-300: oklch(/* ... */);
  --color-base-content: oklch(/* ... */);

  --color-primary: oklch(/* ... */);
  --color-primary-content: oklch(/* ... */);
  --color-secondary: oklch(/* ... */);
  --color-secondary-content: oklch(/* ... */);
  --color-accent: oklch(/* ... */);
  --color-accent-content: oklch(/* ... */);
  --color-neutral: oklch(/* ... */);
  --color-neutral-content: oklch(/* ... */);

  /* Status colors */
  --color-info: oklch(/* ... */);
  --color-info-content: oklch(/* ... */);
  --color-success: oklch(/* ... */);
  --color-success-content: oklch(/* ... */);
  --color-warning: oklch(/* ... */);
  --color-warning-content: oklch(/* ... */);
  --color-error: oklch(/* ... */);
  --color-error-content: oklch(/* ... */);

  /* Design tokens */
  --radius-selector: 0.5rem;
  --radius-field: 0.25rem;
  --radius-box: 0.5rem;
  --size-selector: 0.25rem;
  --size-field: 0.25rem;
  --border: 1px;
  --depth: 1;
  --noise: 0;
}
```

All colors must be in OKLCH format. Use the [OKLCH Color Picker](https://oklch.com/) to convert hex values.

### The structural tokens cannot be overridden from `@theme {}`

The eight design tokens at the bottom of the block (`--radius-*`, `--size-*`, `--border`,
`--depth`, `--noise`) are the ones Bali ships fallbacks for in `bali/theme-fallbacks.css`,
in `@layer base` — the same layer daisyUI's own themes use. Tailwind v4's idiomatic
`@theme { --radius-box: 11px }` compiles to `@layer theme`, which comes **before** `base`,
and across layers the later one wins outright — so an `@theme` declaration of these tokens
is silently ignored, no matter how specific. Declare them where the example above does
(a `[data-theme="..."]` block, `@layer base`, or plain unlayered `:root`) — never in
`@theme {}`. The measured table is in the header of `bali/theme-fallbacks.css`.

## A dark sidebar next to a light page (chrome theme)

Every AFAL app that wants the "dark chrome" look — a dark sidebar against a light
content area — used to hand-roll it by scoping a partial theme to the sidebar's DOM.
Since #726 the mechanism is one keyword:

```erb
<%= render Bali::SideMenu::Component.new(current_path: request.path, theme: 'acme-chrome') do |menu| %>
  ...
<% end %>
```

`theme:` emits `data-theme` on the `<nav>`, and daisyUI resolves every colour
variable against the nearest ancestor that carries one — so the sidebar re-skins
itself and nothing outside it changes. The theme's *values* stay in your app: chrome
colours are brand, so the gem ships the mechanism, not a palette. The exception is a
brand whose dark theme the gem already ships: `costa-norte-dark` paints the rail with the
same `base-100`, text and gold as costa-norte's own block, and the component derives the rest
(below), so that app can drop its block.

A chrome theme does not need the full token list above. The sidebar reads the rail,
its ink and its accent, so the working recipe (measured in costa-norte, which ran this
pattern in production first) is a `dark` `color-scheme` plus those, `primary`, and
`neutral` — around 16 declarations:

```css
[data-theme="acme-chrome"] {
  color-scheme: dark;

  --color-base-100: oklch(0.27 0.03 240); /* the rail */
  --color-base-content: oklch(0.93 0.01 240);

  --color-primary: oklch(0.75 0.12 80);   /* the accent that marks the active item */
  --color-primary-content: oklch(0.2 0.03 240);
  --color-neutral: oklch(0.22 0.03 240);
  --color-neutral-content: oklch(0.93 0.01 240);
  /* info/success/warning/error only if your sidebar renders badges with them */
}
```

Two things the component already handles so the theme does not have to:

- **Borders and flyout panels sit above the rail.** A themed rail mixes its own ink
  into `base-100` — 8% for `base-200`, 18% for `base-300` — instead of reading the
  theme's, because daisyUI's `dark` and Bali's dark themes step those two *down* for a
  full page, and inside a rail that put the panel darker than the rail. The panels also
  get a real border and a shadow dark enough to read on a dark surface. All of it ships
  in the component's own CSS, scoped to `.side-menu-component[data-theme]` — so a rail
  given a light theme gets it too, with slightly firmer borders than that theme's own.
- **The `dark_chrome` Lookbook preview** renders the sidebar with daisyUI's stock
  `dark` theme next to light content — use it to sanity-check your own chrome theme
  by passing its name in the preview's theme param.
