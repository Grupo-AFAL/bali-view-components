# DaisyUI Expert Skill

This skill provides guidance for migrating Bali ViewComponents from Bulma CSS to DaisyUI.

## DaisyUI Version
- DaisyUI 5.x with Tailwind CSS (via tailwindcss-rails gem)
- Reference: https://daisyui.com/llms.txt

## Usage Rules

1. Style elements by adding DaisyUI class names: component class + part classes + modifier classes
2. Customize with Tailwind CSS utilities when DaisyUI doesn't provide the option (e.g., `btn px-10`)
3. Use `!` suffix on Tailwind classes to override DaisyUI styles if needed (e.g., `btn bg-red-500!`) - use sparingly
4. For responsive layouts with `flex`/`grid`, use Tailwind responsive prefixes
5. Only use existing DaisyUI class names or Tailwind CSS utilities
6. Avoid custom CSS - prefer DaisyUI + Tailwind utilities
7. Don't add `bg-base-100 text-base-content` to body unless necessary
8. Use `data-theme="light"` on `<html>` to force light theme

## Color System

### Semantic Colors (use these instead of Tailwind colors)
| Color | Purpose |
|-------|---------|
| `primary` | Main brand color |
| `secondary` | Secondary brand color |
| `accent` | Accent brand color |
| `neutral` | Non-saturated UI parts |
| `base-100/200/300` | Surface colors (light to dark) |
| `info` | Informative messages |
| `success` | Success/safe messages |
| `warning` | Warning/caution messages |
| `error` | Error/danger messages |

### Color Rules
- Use DaisyUI colors so they adapt to themes automatically
- No need for `dark:` prefix with DaisyUI colors
- Avoid Tailwind colors like `text-gray-800` - they don't adapt to themes
- Use `*-content` colors for text on corresponding backgrounds

## Bulma to DaisyUI Class Mapping

### Buttons
| Bulma | DaisyUI |
|-------|---------|
| `button` | `btn` |
| `is-primary` | `btn-primary` |
| `is-secondary` | `btn-secondary` |
| `is-success` | `btn-success` |
| `is-danger` | `btn-error` |
| `is-warning` | `btn-warning` |
| `is-info` | `btn-info` |
| `is-link` | `btn-primary` |
| `is-light` | `btn-ghost` |
| `is-dark` | `btn-neutral` |
| `is-outlined` | `btn-outline` |
| `is-loading` | (use loading component) |
| `is-small` | `btn-sm` |
| `is-medium` | `btn-md` |
| `is-large` | `btn-lg` |

### Tags/Badges
| Bulma | DaisyUI |
|-------|---------|
| `tag` | `badge` |
| `is-primary` | `badge-primary` |
| `is-success` | `badge-success` |
| `is-danger` | `badge-error` |
| `is-warning` | `badge-warning` |
| `is-info` | `badge-info` |
| `is-light` | `badge-ghost` or `badge-outline` |
| `is-dark` | `badge-neutral` |
| `is-small` | `badge-sm` |
| `is-medium` | `badge-md` |
| `is-large` | `badge-lg` |

### Notifications/Alerts
| Bulma | DaisyUI |
|-------|---------|
| `notification` | `alert` |
| `is-primary` | `alert-info` |
| `is-success` | `alert-success` |
| `is-danger` | `alert-error` |
| `is-warning` | `alert-warning` |
| `is-info` | `alert-info` |

### Modals
| Bulma | DaisyUI |
|-------|---------|
| `modal` | `modal` |
| `modal-background` | `modal-backdrop` |
| `modal-content` | `modal-box` |
| `modal-close` | `btn btn-sm btn-circle btn-ghost` |
| `is-active` | `modal-open` (on modal) |

### Tabs
| Bulma | DaisyUI |
|-------|---------|
| `tabs` | `tabs` |
| `is-boxed` | `tabs-box` |
| `is-toggle` | `tabs-lift` |
| `is-active` | (on the tab item, not a class) |

### Dropdowns
| Bulma | DaisyUI |
|-------|---------|
| `dropdown` | `dropdown` |
| `dropdown-trigger` | (use button/summary) |
| `dropdown-menu` | `dropdown-content` |
| `dropdown-content` | `menu` inside dropdown-content |
| `is-active` | `dropdown-open` |
| `is-hoverable` | `dropdown-hover` |
| `is-right` | `dropdown-end` |
| `is-up` | `dropdown-top` |

### Cards
| Bulma | DaisyUI |
|-------|---------|
| `card` | `card` |
| `card-header` | (use card-body with title) |
| `card-header-title` | `card-title` |
| `card-content` | `card-body` |
| `card-footer` | `card-actions` |
| `card-image` | `figure` inside card |

### Progress
| Bulma | DaisyUI |
|-------|---------|
| `progress` | `progress` |
| `is-primary` | `progress-primary` |
| `is-success` | `progress-success` |
| `is-danger` | `progress-error` |
| `is-warning` | `progress-warning` |
| `is-info` | `progress-info` |

### Tables
| Bulma | DaisyUI |
|-------|---------|
| `table` | `table` |
| `is-striped` | `table-zebra` |
| `is-hoverable` | (rows have hover by default) |
| `is-fullwidth` | `w-full` |

### Forms
| Bulma | DaisyUI |
|-------|---------|
| `input` | `input` |
| `textarea` | `textarea` |
| `select` | `select` |
| `checkbox` | `checkbox` |
| `radio` | `radio` |
| `is-primary` | `input-primary` / `select-primary` / etc. |
| `is-danger` | `input-error` / `select-error` / etc. |
| `is-small` | `input-sm` / `select-sm` / etc. |
| `is-large` | `input-lg` / `select-lg` / etc. |

### Layout
| Bulma | DaisyUI/Tailwind |
|-------|------------------|
| `columns` | `flex` or `grid` |
| `column` | `flex-1` or grid children |
| `is-one-third` | `w-1/3` or `basis-1/3` |
| `is-half` | `w-1/2` or `basis-1/2` |
| `container` | `container mx-auto` |
| `section` | `py-12` or similar |
| `box` | `card` with `card-body` |
| `level` | `flex items-center justify-between` |
| `is-mobile` | (use responsive prefixes) |

### Visibility
| Bulma | DaisyUI/Tailwind |
|-------|------------------|
| `is-hidden` | `hidden` |
| `is-invisible` | `invisible` |
| `is-hidden-mobile` | `hidden sm:block` |
| `is-hidden-desktop` | `sm:hidden` |

### Text
| Bulma | DaisyUI/Tailwind |
|-------|------------------|
| `has-text-centered` | `text-center` |
| `has-text-left` | `text-left` |
| `has-text-right` | `text-right` |
| `has-text-weight-bold` | `font-bold` |
| `has-text-primary` | `text-primary` |
| `has-text-success` | `text-success` |
| `has-text-danger` | `text-error` |
| `has-text-warning` | `text-warning` |
| `has-text-info` | `text-info` |

## DaisyUI Component Quick Reference

### Badge
```html
<span class="badge badge-{color} badge-{size}">Text</span>
```
Colors: `primary`, `secondary`, `accent`, `neutral`, `info`, `success`, `warning`, `error`
Styles: `badge-outline`, `badge-dash`, `badge-soft`, `badge-ghost`
Sizes: `badge-xs`, `badge-sm`, `badge-md`, `badge-lg`, `badge-xl`

### Button
```html
<button class="btn btn-{color} btn-{size}">Button</button>
```
Colors: `primary`, `secondary`, `accent`, `neutral`, `info`, `success`, `warning`, `error`
Styles: `btn-outline`, `btn-dash`, `btn-soft`, `btn-ghost`, `btn-link`
Sizes: `btn-xs`, `btn-sm`, `btn-md`, `btn-lg`, `btn-xl`
Modifiers: `btn-wide`, `btn-block`, `btn-square`, `btn-circle`

### Alert
```html
<div role="alert" class="alert alert-{color}">
  <span>Message</span>
</div>
```
Colors: `alert-info`, `alert-success`, `alert-warning`, `alert-error`
Styles: `alert-outline`, `alert-dash`, `alert-soft`

### Modal
```html
<dialog id="my_modal" class="modal">
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

### Dropdown
```html
<details class="dropdown">
  <summary class="btn m-1">Click</summary>
  <ul class="dropdown-content menu bg-base-100 rounded-box z-1 w-52 p-2 shadow-sm">
    <li><a>Item 1</a></li>
    <li><a>Item 2</a></li>
  </ul>
</details>
```

### Tabs
```html
<div role="tablist" class="tabs tabs-box">
  <a role="tab" class="tab">Tab 1</a>
  <a role="tab" class="tab tab-active">Tab 2</a>
  <a role="tab" class="tab">Tab 3</a>
</div>
```

### Card
```html
<div class="card bg-base-100 shadow-sm">
  <figure><img src="..." alt="..." /></figure>
  <div class="card-body">
    <h2 class="card-title">Title</h2>
    <p>Description</p>
    <div class="card-actions justify-end">
      <button class="btn btn-primary">Action</button>
    </div>
  </div>
</div>
```

### Loading
```html
<span class="loading loading-spinner loading-{size}"></span>
```
Types: `loading-spinner`, `loading-dots`, `loading-ring`, `loading-ball`, `loading-bars`, `loading-infinity`
Sizes: `loading-xs`, `loading-sm`, `loading-md`, `loading-lg`, `loading-xl`

### Tooltip
```html
<div class="tooltip" data-tip="Tooltip text">
  <button class="btn">Hover me</button>
</div>
```
Positions: `tooltip-top`, `tooltip-bottom`, `tooltip-left`, `tooltip-right`
Colors: `tooltip-primary`, `tooltip-secondary`, `tooltip-accent`, `tooltip-info`, `tooltip-success`, `tooltip-warning`, `tooltip-error`

## Migration Checklist

When migrating a Bali component:

1. [ ] Read the current component.rb to understand the options/variants
2. [ ] Map Bulma classes to DaisyUI equivalents using tables above
3. [ ] Update component.rb to generate DaisyUI classes
4. [ ] Update component SCSS if needed (minimize custom CSS)
5. [ ] Update tests to expect new class names
6. [ ] Verify in Lookbook visually
7. [ ] Run tests: `bundle exec rspec spec/bali/components/{component}_spec.rb`
