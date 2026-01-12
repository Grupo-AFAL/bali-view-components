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

---

## ActionsDropdown - 2026-01-12 00:00 (Re-review)

**Status**: PARTIAL
**Iterations**: 2 of 3
**UX Score**: 6/10 (honest assessment)

### Issues Found
- [High] Delete icon missing - preview used `icon_name:` but DeleteLink expects `icon:` (boolean)
- [Medium] HoverCard caret/arrow positioned awkwardly (doesn't align with trigger)
- [Medium] Shadow too diffuse, looks muddy
- [Low] Generic blue color for Edit/Export icons

### Fixes Applied
- Fixed preview.rb: changed `icon_name: 'trash'` to `icon: true` for Delete item
- Files modified: `app/components/bali/actions_dropdown/preview.rb`

### Key Learnings
1. **DeleteLink vs Link API mismatch**: `Link::Component` accepts `icon_name:` param, but `DeleteLink::Component` only accepts `icon:` (boolean) and hardcodes 'trash' icon
2. **UX reviewer quality**: Gemini model (antigravity-gemini-3-pro-high) couldn't use Playwright MCP correctly (argument format issues). **Switched to Claude Sonnet 4.5** which works properly.
3. **UX reviewer too lenient**: Even with working tools, the reviewer gave 7/10 PASS for a component with obvious visual issues. Need stricter criteria.

### Tests
- Existing: 3 tests
- Status: All passing

### Remaining Issues
- HoverCard arrow positioning (needs HoverCard component fix)
- Shadow styling (needs HoverCard component fix)
- Consider unifying Link/DeleteLink API for `icon_name`

### Commit
Not committed yet

### Next Steps
- Fix HoverCard component arrow/shadow styling
- Consider adding `icon_name:` param to DeleteLink for API consistency
- Update UX review prompts to be more critical

---

## ActionsDropdown - 2026-01-12 00:55 (Full Cycle)

**Status**: PARTIAL (awaiting JS recompile)
**Iterations**: 3 of 3
**UX Score**: 5/10 (strict assessment)

### Issues Found (Initial)
- [High] Delete icon missing - preview used wrong param
- [High] HoverCard arrow positioned awkwardly
- [Medium] Shadow too diffuse
- [Low] Uneven vertical spacing between menu items

### Fixes Applied

1. **Delete icon fix** (preview.rb)
   - Changed `icon_name: 'trash'` to `icon: true`
   - File: `app/components/bali/actions_dropdown/preview.rb`

2. **Arrow option added to HoverCard** (Ruby)
   - Added `arrow:` param (default: true)
   - File: `app/components/bali/hover_card/component.rb`

3. **Arrow option in JS** (needs recompile)
   - Added `arrow` Stimulus value
   - Tippy now respects `arrow: false`
   - File: `app/components/bali/hover_card/index.js`

4. **ActionsDropdown disables arrow**
   - Set `arrow: false` in defaults
   - File: `app/components/bali/actions_dropdown/component.rb`

5. **Created stricter UX reviewer agent**
   - File: `.claude/agents/frontend-ui-ux-engineer.md`
   - Defines scoring criteria, automatic failures
   - Uses Claude Sonnet 4.5

### Files Modified
- `app/components/bali/actions_dropdown/preview.rb`
- `app/components/bali/actions_dropdown/component.rb`
- `app/components/bali/hover_card/component.rb`
- `app/components/bali/hover_card/index.js`
- `.claude/agents/frontend-ui-ux-engineer.md` (created)

### Key Learnings

1. **Gemini can't use skill_mcp**: The Gemini model (antigravity-gemini-3-pro-high) repeatedly failed to format skill_mcp arguments correctly (25+ retries). Claude Sonnet 4.5 works perfectly.

2. **UX reviewers need strict criteria**: Without explicit failure conditions, reviewers are too lenient. The new agent definition includes automatic failure triggers.

3. **HoverCard arrow is hardcoded**: The arrow SVG was embedded in JS with no way to disable. Added `arrow` option to fix this.

4. **DeleteLink API differs from Link**: Link accepts `icon_name:`, DeleteLink accepts `icon:` (boolean). Consider unifying.

### Tests
- Existing: 3 tests (ActionsDropdown)
- Added: 0
- Status: All passing (6/6 with HoverCard tests)

### Remaining Issues (after JS recompile)
- Uneven vertical spacing between menu items
- Shadow could be refined (multi-layer)

### Commit
Not committed - awaiting JS recompile verification

### Next Steps
1. Restart Lookbook server to recompile JS
2. Verify arrow is gone
3. Re-run UX review
4. Fix spacing if still an issue
5. Commit all changes
