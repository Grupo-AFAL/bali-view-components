# Bali Component Migration Log

This file tracks all component migrations from Bulma to Tailwind/DaisyUI.
AI agents should READ this at the start of each `/component-cycle` and APPEND after completion.

---

## Columns - 2026-01-11 21:30

**Status**: SUCCESS
**Iterations**: 2 of 3
**UX Score**: 8/10

### Issues Found
- [Critical] Dead Bulma classes: `is-half`, `is-narrow`, `is-offset-*`, `is-multiline`
- [Critical] Flex + gap + percentage widths caused overflow/wrapping
- [High] No `size:` or `offset:` params in Column component
- [Medium] No tests existed
- [Medium] Preview used Bulma API
- [Low] `box` class unstyled

### Fixes Applied
- Switched container from flexbox to CSS Grid (`grid grid-cols-12 gap-4`)
- Added `SIZES` constant with col-span classes
- Added `OFFSETS` constant with col-start classes
- Added `size:` param (`:half`, `:third`, `:quarter`, `:narrow`, `:full`, etc.)
- Added `offset:` param (`:quarter`, `:third`, `:half`)
- Rewrote preview.rb with new API and DaisyUI styling
- Expanded tests from 1 to 15

### Files Modified
- `app/components/bali/columns/component.rb` - Container grid classes
- `app/components/bali/columns/column/component.rb` - SIZES, OFFSETS, params
- `app/components/bali/columns/preview.rb` - Complete rewrite
- `spec/bali/components/columns_spec.rb` - 15 tests

### Class Mappings
| Old (Bulma) | New (Tailwind Grid) |
|-------------|---------------------|
| `is-half` | `col-span-6` |
| `is-one-third` | `col-span-4` |
| `is-two-thirds` | `col-span-8` |
| `is-one-quarter` | `col-span-3` |
| `is-three-quarters` | `col-span-9` |
| `is-narrow` | `col-span-2` |
| `is-full` | `col-span-12` |
| `is-offset-one-quarter` | `col-start-4` |
| `is-offset-one-third` | `col-start-5` |
| `is-offset-half` | `col-start-7` |
| `is-multiline` | N/A (grid wraps automatically) |
| `box` | `bg-base-200 p-4 rounded-lg` |
| Container `flex flex-wrap` | `grid grid-cols-12` |

### Key Learnings
1. **Flex + gap + percentage widths = broken**: When using `gap-4` with `w-1/2`, columns exceed 100% and wrap. CSS Grid handles this correctly.
2. **CSS Grid is better for column layouts**: Use `grid-cols-12` for 12-column grid, `col-span-*` for widths, `col-start-*` for offsets.
3. **Default column behavior changed**: Without explicit size, columns now get `col-span-6` (half width) instead of `flex-1` (equal distribution).

### Tests
- Added: 15 tests (was 1)
- Status: All passing

### Remaining Issues
- None

### Commit
`2cdf695` Fix Columns component and add verification tooling

### Next Steps
- Verify other partially-migrated components using same patterns
- Components using similar column/grid layouts may need same flex→grid fix

---

## ActionsDropdown - 2026-01-11 21:33

**Status**: SUCCESS (Already Complete)
**Iterations**: 1 of 3
**UX Score**: 9/10

### Issues Found
- None - component was already fully migrated

### Verification Results
- ✅ No Bulma classes found in component
- ✅ DaisyUI classes correctly implemented:
  - Trigger: `btn btn-ghost btn-sm btn-circle`
  - Content: `menu bg-base-100 rounded-box shadow-lg min-w-40`
  - List: `menu p-2`
  - Items: `menu-item`
- ✅ Dropdown opens on click (via HoverCard Stimulus controller)
- ✅ Shows Edit, Export, Delete menu items
- ✅ Delete uses proper form with turbo-confirm
- ✅ 3 tests passing
- ✅ No LSP diagnostics

### Files Reviewed (No Changes Needed)
- `app/components/bali/actions_dropdown/component.rb`
- `app/components/bali/actions_dropdown/component.html.erb`
- `app/components/bali/actions_dropdown/preview.rb`
- `app/components/bali/actions_dropdown/index.scss`
- `spec/bali/components/actions_dropdown_spec.rb`

### Class Mappings
| Old (Bulma) | New (DaisyUI) |
|-------------|---------------|
| N/A | Already uses `btn btn-ghost btn-circle` |
| N/A | Already uses `menu`, `menu-item` |

### Tests
- Existing: 3 tests
- Status: All passing

### Remaining Issues
- None

### Commit
Not needed - already migrated in commit a89f03a

### Next Steps
- Continue verifying other partially-migrated components
