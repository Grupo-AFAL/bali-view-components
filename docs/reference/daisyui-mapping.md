# DaisyUI Migration Reference

This document is the **single source of truth** for Bulma to DaisyUI class mappings in the Bali ViewComponent library.

> **Version**: DaisyUI 5.x with Tailwind CSS (via tailwindcss-rails gem)
> **Reference**: https://daisyui.com/llms.txt

## Usage Rules

1. Style elements by adding DaisyUI class names: component class + part classes + modifier classes
2. Customize with Tailwind CSS utilities when DaisyUI doesn't provide the option (e.g., `btn px-10`)
3. Use `!` suffix on Tailwind classes to override DaisyUI styles if needed (e.g., `btn bg-red-500!`) - use sparingly
4. For responsive layouts with `flex`/`grid`, use Tailwind responsive prefixes
5. Only use existing DaisyUI class names or Tailwind CSS utilities
6. Avoid custom CSS - prefer DaisyUI + Tailwind utilities
7. Don't add `bg-base-100 text-base-content` to body unless necessary
8. Use `data-theme="light"` on `<html>` to force light theme

---

## Color System

### Semantic Colors (use these instead of Tailwind colors)

| Color | Purpose | Usage |
|-------|---------|-------|
| `primary` | Main brand color | `btn-primary`, `text-primary`, `bg-primary` |
| `secondary` | Secondary brand color | `btn-secondary`, `text-secondary` |
| `accent` | Accent brand color | `btn-accent`, `badge-accent` |
| `neutral` | Non-saturated UI parts | `btn-neutral`, `bg-neutral` |
| `base-100/200/300` | Surface colors (light to dark) | `bg-base-100`, `bg-base-200` |
| `info` | Informative messages | `alert-info`, `btn-info` |
| `success` | Success/safe messages | `alert-success`, `btn-success` |
| `warning` | Warning/caution messages | `alert-warning`, `btn-warning` |
| `error` | Error/danger messages | `alert-error`, `btn-error` |

### Color Rules

- Use DaisyUI colors so they adapt to themes automatically
- No need for `dark:` prefix with DaisyUI colors
- Avoid Tailwind colors like `text-gray-800` - they don't adapt to themes
- Use `*-content` colors for text on corresponding backgrounds (e.g., `primary-content` on `bg-primary`)

---

## Class Mappings by Component Type

### Buttons

| Bulma | DaisyUI | Notes |
|-------|---------|-------|
| `button` | `btn` | Base class |
| `is-primary` | `btn-primary` | |
| `is-secondary` | `btn-secondary` | |
| `is-success` | `btn-success` | |
| `is-danger` | `btn-error` | **danger → error** |
| `is-warning` | `btn-warning` | |
| `is-info` | `btn-info` | |
| `is-link` | `btn-link` | Or `btn-primary` |
| `is-light` | `btn-ghost` | |
| `is-dark` | `btn-neutral` | |
| `is-outlined` | `btn-outline` | |
| `is-loading` | `loading loading-spinner` | Separate element |
| `is-small` | `btn-sm` | |
| `is-medium` | `btn-md` | |
| `is-large` | `btn-lg` | |

**DaisyUI Button Extras:**
- Sizes: `btn-xs`, `btn-sm`, `btn-md`, `btn-lg`, `btn-xl`
- Styles: `btn-outline`, `btn-dash`, `btn-soft`, `btn-ghost`, `btn-link`
- Shapes: `btn-wide`, `btn-block`, `btn-square`, `btn-circle`

### Tags/Badges

| Bulma | DaisyUI | Notes |
|-------|---------|-------|
| `tag` | `badge` | Base class |
| `is-primary` | `badge-primary` | |
| `is-success` | `badge-success` | |
| `is-danger` | `badge-error` | **danger → error** |
| `is-warning` | `badge-warning` | |
| `is-info` | `badge-info` | |
| `is-light` | `badge-ghost` | Or `badge-outline` |
| `is-dark` | `badge-neutral` | |
| `is-small` | `badge-sm` | |
| `is-medium` | `badge-md` | |
| `is-large` | `badge-lg` | |

**DaisyUI Badge Extras:**
- Sizes: `badge-xs`, `badge-sm`, `badge-md`, `badge-lg`, `badge-xl`
- Styles: `badge-outline`, `badge-dash`, `badge-soft`, `badge-ghost`

### Notifications/Alerts

| Bulma | DaisyUI | Notes |
|-------|---------|-------|
| `notification` | `alert` | Base class |
| `is-primary` | `alert-info` | |
| `is-success` | `alert-success` | |
| `is-danger` | `alert-error` | **danger → error** |
| `is-warning` | `alert-warning` | |
| `is-info` | `alert-info` | |

**DaisyUI Alert Extras:**
- Styles: `alert-outline`, `alert-dash`, `alert-soft`
- Add `role="alert"` for accessibility

### Modals

| Bulma | DaisyUI | Notes |
|-------|---------|-------|
| `modal` | `modal` | Use `<dialog>` element |
| `modal-background` | `modal-backdrop` | |
| `modal-content` | `modal-box` | |
| `modal-close` | `btn btn-sm btn-circle btn-ghost` | |
| `is-active` | `modal-open` | Or use `dialog.showModal()` |

**DaisyUI Modal Structure:**
```html
<dialog class="modal">
  <div class="modal-box">
    <h3 class="text-lg font-bold">Title</h3>
    <p>Content</p>
    <div class="modal-action">
      <form method="dialog">
        <button class="btn">Close</button>
      </form>
    </div>
  </div>
  <form method="dialog" class="modal-backdrop">
    <button>close</button>
  </form>
</dialog>
```

### Tabs

| Bulma | DaisyUI | Notes |
|-------|---------|-------|
| `tabs` | `tabs` | Add `role="tablist"` |
| `is-boxed` | `tabs-box` | |
| `is-toggle` | `tabs-lift` | |
| `is-active` | `tab-active` | On the tab item |

**DaisyUI Tab Extras:**
- Styles: `tabs-box`, `tabs-bordered`, `tabs-lift`
- Sizes: `tabs-xs`, `tabs-sm`, `tabs-md`, `tabs-lg`

### Dropdowns

| Bulma | DaisyUI | Notes |
|-------|---------|-------|
| `dropdown` | `dropdown` | Use `<details>` element |
| `dropdown-trigger` | `<summary>` | |
| `dropdown-menu` | `dropdown-content` | |
| `dropdown-content` | `menu` inside dropdown-content | |
| `is-active` | `dropdown-open` | Or use `<details open>` |
| `is-hoverable` | `dropdown-hover` | |
| `is-right` | `dropdown-end` | |
| `is-up` | `dropdown-top` | |

**DaisyUI Dropdown Structure:**
```html
<details class="dropdown">
  <summary class="btn m-1">Click</summary>
  <ul class="dropdown-content menu bg-base-100 rounded-box z-1 w-52 p-2 shadow-sm">
    <li><a>Item 1</a></li>
    <li><a>Item 2</a></li>
  </ul>
</details>
```

### Cards

| Bulma | DaisyUI | Notes |
|-------|---------|-------|
| `card` | `card bg-base-100` | Add background |
| `card-header` | (use card-body with title) | Structural change |
| `card-header-title` | `card-title` | Inside card-body |
| `card-content` | `card-body` | |
| `card-footer` | `card-actions` | |
| `card-image` | `<figure>` inside card | |

**DaisyUI Card Extras:**
- Variants: `card-bordered`, `card-compact`, `card-side`
- Shadow: Use Tailwind `shadow-sm`, `shadow-md`, `shadow-xl`

### Progress

| Bulma | DaisyUI | Notes |
|-------|---------|-------|
| `progress` | `progress` | |
| `is-primary` | `progress-primary` | |
| `is-success` | `progress-success` | |
| `is-danger` | `progress-error` | **danger → error** |
| `is-warning` | `progress-warning` | |
| `is-info` | `progress-info` | |

### Tables

| Bulma | DaisyUI | Notes |
|-------|---------|-------|
| `table` | `table` | |
| `is-striped` | `table-zebra` | |
| `is-hoverable` | (default hover) | Rows hover by default |
| `is-fullwidth` | `w-full` | Tailwind utility |

**DaisyUI Table Extras:**
- Sizes: `table-xs`, `table-sm`, `table-md`, `table-lg`
- `table-pin-rows` - Pin header rows
- `table-pin-cols` - Pin first column

### Forms

| Bulma | DaisyUI | Notes |
|-------|---------|-------|
| `input` | `input` | Add `input-bordered` for border |
| `textarea` | `textarea` | Add `textarea-bordered` |
| `select` | `select` | Add `select-bordered` |
| `checkbox` | `checkbox` | |
| `radio` | `radio` | |
| `is-primary` | `input-primary` | Same for select, textarea |
| `is-danger` | `input-error` | **danger → error** |
| `is-small` | `input-sm` | |
| `is-large` | `input-lg` | |
| `field` | `form-control` | |
| `label` | `label` | |
| `help` | `label-text-alt` | |
| `help is-danger` | `label-text-alt text-error` | |

### Layout

| Bulma | DaisyUI/Tailwind | Notes |
|-------|------------------|-------|
| `columns` | `grid grid-cols-12 gap-4` | Use CSS Grid |
| `column` | `col-span-*` | |
| `is-half` | `col-span-6` | |
| `is-one-third` | `col-span-4` | |
| `is-two-thirds` | `col-span-8` | |
| `is-one-quarter` | `col-span-3` | |
| `is-three-quarters` | `col-span-9` | |
| `is-narrow` | `col-span-2` | |
| `is-offset-one-quarter` | `col-start-4` | |
| `is-offset-one-third` | `col-start-5` | |
| `is-offset-half` | `col-start-7` | |
| `container` | `container mx-auto` | |
| `section` | `py-12` | Or similar padding |
| `box` | `bg-base-200 p-4 rounded-lg` | |
| `level` | `flex items-center justify-between` | |
| `is-multiline` | (grid wraps automatically) | |

### Visibility

| Bulma | DaisyUI/Tailwind | Notes |
|-------|------------------|-------|
| `is-hidden` | `hidden` | |
| `is-invisible` | `invisible` | |
| `is-hidden-mobile` | `hidden sm:block` | |
| `is-hidden-desktop` | `sm:hidden` | |

### Text

| Bulma | DaisyUI/Tailwind | Notes |
|-------|------------------|-------|
| `has-text-centered` | `text-center` | |
| `has-text-left` | `text-left` | |
| `has-text-right` | `text-right` | |
| `has-text-weight-bold` | `font-bold` | |
| `has-text-primary` | `text-primary` | |
| `has-text-success` | `text-success` | |
| `has-text-danger` | `text-error` | **danger → error** |
| `has-text-warning` | `text-warning` | |
| `has-text-info` | `text-info` | |

---

## DaisyUI Component Quick Reference

### Loading States

```html
<span class="loading loading-spinner loading-{size}"></span>
```
Types: `loading-spinner`, `loading-dots`, `loading-ring`, `loading-ball`, `loading-bars`, `loading-infinity`
Sizes: `loading-xs`, `loading-sm`, `loading-md`, `loading-lg`, `loading-xl`

### Tooltip

```html
<div class="tooltip tooltip-{position}" data-tip="Tooltip text">
  <button class="btn">Hover me</button>
</div>
```
Positions: `tooltip-top`, `tooltip-bottom`, `tooltip-left`, `tooltip-right`
Colors: `tooltip-primary`, `tooltip-secondary`, `tooltip-accent`, `tooltip-info`, `tooltip-success`, `tooltip-warning`, `tooltip-error`

### Avatar

```html
<div class="avatar">
  <div class="w-24 rounded-full">
    <img src="..." />
  </div>
</div>
```
Modifiers: `online`, `offline`, `placeholder`, `rounded`, `rounded-full`

### Steps/Stepper

```html
<ul class="steps">
  <li class="step step-primary">Step 1</li>
  <li class="step step-primary">Step 2</li>
  <li class="step">Step 3</li>
</ul>
```

### Timeline

```html
<ul class="timeline">
  <li>
    <div class="timeline-start">Date</div>
    <div class="timeline-middle">
      <svg>...</svg>
    </div>
    <div class="timeline-end">Content</div>
    <hr/>
  </li>
</ul>
```

### Drawer

```html
<div class="drawer">
  <input id="my-drawer" type="checkbox" class="drawer-toggle" />
  <div class="drawer-content">
    <label for="my-drawer" class="btn btn-primary drawer-button">Open</label>
  </div>
  <div class="drawer-side">
    <label for="my-drawer" class="drawer-overlay"></label>
    <ul class="menu bg-base-200 text-base-content min-h-full w-80 p-4">
      <li><a>Item 1</a></li>
    </ul>
  </div>
</div>
```

---

## Migration Checklist

When migrating a Bali component:

1. [ ] Read the current component.rb to understand the options/variants
2. [ ] Map Bulma classes to DaisyUI equivalents using tables above
3. [ ] Check DaisyUI docs for additional modifiers/features
4. [ ] Update component.rb to generate DaisyUI classes
5. [ ] Update component.html.erb template
6. [ ] Minimize custom SCSS (prefer Tailwind utilities)
7. [ ] Update tests to expect new class names
8. [ ] Update preview.rb with new parameter values
9. [ ] Verify in Lookbook visually
10. [ ] Run tests: `bundle exec rspec spec/bali/components/{component}_spec.rb`

---

## Key Learnings from Migrations

### Flex vs Grid for Columns

**Problem**: Flex + gap + percentage widths causes overflow
```html
<!-- BAD: Columns wrap unexpectedly -->
<div class="flex flex-wrap gap-4">
  <div class="w-1/2">...</div>
  <div class="w-1/2">...</div>
</div>
```

**Solution**: Use CSS Grid
```html
<!-- GOOD: Grid handles gaps correctly -->
<div class="grid grid-cols-12 gap-4">
  <div class="col-span-6">...</div>
  <div class="col-span-6">...</div>
</div>
```

### Danger vs Error

DaisyUI uses `error` instead of `danger`:
- `is-danger` → `btn-error`, `alert-error`, `text-error`
- Keep aliases in Ruby for backward compatibility

### Box Class

Bulma's `box` has no DaisyUI equivalent. Replace with:
```html
<div class="bg-base-200 p-4 rounded-lg shadow">...</div>
```
