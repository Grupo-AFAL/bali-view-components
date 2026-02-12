# Custom Themes

Bali ships optional DaisyUI themes that you can import alongside the default `light` and `dark` themes.

## Available Themes

| Theme | File | Description |
|-------|------|-------------|
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
