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
