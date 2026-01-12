---
description: DaisyUI expertise for Bali ViewComponent styling
---

# DaisyUI Expert Skill

This skill provides quick reference for DaisyUI styling in Bali ViewComponents.

## Full Reference

See `docs/reference/daisyui-mapping.md` for the complete mapping reference.

## Quick Reference

### DaisyUI Version
- DaisyUI 5.x with Tailwind CSS
- Reference: https://daisyui.com/llms.txt

### Usage Rules

1. Use DaisyUI component classes + modifier classes
2. Customize with Tailwind utilities when needed
3. Use semantic colors (`primary`, `error`) not Tailwind colors (`red-500`)
4. Avoid custom CSS - prefer DaisyUI + Tailwind

### Most Common Mappings

| Bulma | DaisyUI |
|-------|---------|
| `button` | `btn` |
| `is-primary` | `btn-primary` |
| `is-danger` | `btn-error` |
| `is-small` | `btn-sm` |
| `is-large` | `btn-lg` |
| `tag` | `badge` |
| `notification` | `alert` |
| `card-content` | `card-body` |
| `card-footer` | `card-actions` |
| `modal-card` | `modal-box` |
| `columns` | `grid grid-cols-12` |
| `is-half` | `col-span-6` |

### Semantic Colors

| Color | Usage |
|-------|-------|
| `primary` | Main brand actions |
| `secondary` | Secondary actions |
| `accent` | Highlighted elements |
| `neutral` | Neutral UI |
| `info` | Informational |
| `success` | Positive/safe |
| `warning` | Caution |
| `error` | Danger/destructive |

### Key Differences from Bulma

1. **danger -> error**: DaisyUI uses `error` not `danger`
2. **Sizes**: Use `xs`, `sm`, `md`, `lg`, `xl` not `small`, `medium`, `large`
3. **Layout**: Use CSS Grid (`grid-cols-12`) not Flexbox for columns
4. **Box**: No equivalent - use `bg-base-200 p-4 rounded-lg`

## Full Documentation

For complete mappings and patterns, see:
- `docs/reference/daisyui-mapping.md`
- `docs/reference/component-patterns.md`
