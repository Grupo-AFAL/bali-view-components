# Custom Themes

Bali ships optional DaisyUI themes that you can import alongside the default `light` and `dark` themes.

## Available Themes

| Theme | File | Description |
|-------|------|-------------|
| `afal` | `css/themes/afal.css` | Grupo AFAL brand - light variant with blue/violet/amber palette |
| `afal-dark` | `css/themes/afal-dark.css` | **Draft / experimental** - dark variant derived from `afal`, pending visual approval |
| `costa-norte` | `css/themes/costa-norte.css` | Costa Norte brand - light variant with teal/gold palette |

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
afal-apps, identity and opina used to carry byte-identically in their own CSS. If your app
still has a local copy, delete it **in the same commit** that adds the import — while both
exist, whichever appears later in the compiled CSS wins, silently.

```css
@import "bali-view-components/css/themes/afal.css";
@import "bali-view-components/css/themes/afal-dark.css"; /* optional, draft */
```

```html
<html data-theme="afal">
```

Listing `afal` in your `@plugin "daisyui" { themes: ... }` block is **not** what makes the
theme work — daisyUI does not know these names, and listing an unknown name registers
nothing. The theming comes entirely from the unlayered `[data-theme="afal"]` block, which
wins over daisyUI's own themes by layer order. You can drop `afal` and `afal-dark` from the
plugin's `themes:` list when you adopt the imports.

### `afal-dark` (draft) and the `dark:` variant

`afal-dark` is an experimental first design — no app activates it yet, and its tokens may
change before it is announced as stable. Preview it in Lookbook under
*Theme Sampler → Afal Dark*.

If your app defines a `@custom-variant dark` so `dark:` utilities follow the theme (all
AFAL hosts do), `dark:` will **not** fire under `afal-dark` unless you extend the variant:

```css
@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *, [data-theme=afal-dark], [data-theme=afal-dark] *));
```

Without this, components styled with `dark:` utilities keep their light-theme styling even
though the daisyUI palette around them has gone dark.

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
colours are brand, so the gem ships the mechanism, not a palette.

A chrome theme does not need the full token list above. The sidebar only reads the
base surfaces and its accent, so the working recipe (measured in costa-norte, which
ran this pattern in production first) is a `dark` `color-scheme` plus the base
palette, `primary`, and `neutral` — around 18 declarations:

```css
[data-theme="acme-chrome"] {
  color-scheme: dark;

  --color-base-100: oklch(0.27 0.03 240); /* the rail */
  --color-base-200: oklch(0.31 0.03 240); /* flyout panels, hover */
  --color-base-300: oklch(0.36 0.03 240); /* borders, active */
  --color-base-content: oklch(0.93 0.01 240);

  --color-primary: oklch(0.75 0.12 80);   /* the accent that marks the active item */
  --color-primary-content: oklch(0.2 0.03 240);
  --color-neutral: oklch(0.22 0.03 240);
  --color-neutral-content: oklch(0.93 0.01 240);
  /* info/success/warning/error only if your sidebar renders badges with them */
}
```

Two things the component already handles so the theme does not have to:

- **Flyout panels keep their edges on a dark surface.** daisyUI's soft shadow is
  invisible on dark and a `base-100` panel matches the rail it opens from, so a
  themed sidebar renders its dropdown panels one step lighter, with a real border
  and a stronger shadow. That fix ships in the component's own CSS, scoped to
  `.side-menu-component[data-theme]`.
- **The `dark_chrome` Lookbook preview** renders the sidebar with daisyUI's stock
  `dark` theme next to light content — use it to sanity-check your own chrome theme
  by passing its name in the preview's theme param.
