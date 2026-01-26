# Verify Component

Comprehensive visual and functional verification for Bali ViewComponents against DaisyUI design system.

## Usage

```
/verify-component $ARGUMENTS
```

Where `$ARGUMENTS` is:
- Component name (e.g., `Dropdown`, `Modal`, `Tabs`)
- `--quick` - Skip UX review, only verify functionality
- `--no-js` - Skip JavaScript functionality tests
- `--screenshots` - Save screenshots of all variants

## Prerequisites

Lookbook must be running at `http://localhost:3001/lookbook`. If not running:

```bash
cd spec/dummy && bin/dev
```

## Workflow

### Step 1: Component Discovery

1. Locate component files:
   - `app/components/bali/[name]/component.rb` - Ruby class
   - `app/components/bali/[name]/component.html.erb` - Template
   - `app/components/bali/[name]/preview.rb` - Lookbook preview

2. Extract component metadata:
   - Variants (from VARIANTS constant or params)
   - Sizes (from SIZES constant or params)
   - States (loading, disabled, active, etc.)
   - Stimulus controllers used
   - Slots defined

3. Map to DaisyUI equivalents (reference: https://daisyui.com/components/)

### Step 2: DaisyUI Compliance Check

Verify the component implements appropriate DaisyUI classes:

#### MANDATORY: Use DaisyUI Blueprint MCP Server

**Before checking compliance manually, you MUST use the DaisyUI Blueprint MCP server** to get authoritative DaisyUI snippets and patterns. This ensures consistency with the official DaisyUI design system.

**Load the MCP tools first:**
```
MCPSearch(query: "select:mcp__daisyui-blueprint__daisyUI-Snippets")
```

**Then fetch the official DaisyUI snippet for the component type:**
```
mcp__daisyui-blueprint__daisyUI-Snippets({
  "component": "[ComponentType]"  // e.g., "button", "card", "modal", "dropdown", etc.
})
```

**Use the returned snippet to verify:**
1. Base class names match (e.g., `btn`, `card`, `modal-box`)
2. Modifier classes follow DaisyUI conventions (e.g., `btn-primary`, `card-bordered`)
3. HTML structure matches recommended patterns
4. Nested elements use correct class relationships

**For complex layouts or when converting designs:**
```
MCPSearch(query: "select:mcp__daisyui-blueprint__Figma-to-daisyUI")
```

This tool can help translate design requirements into proper DaisyUI implementation.

#### Common DaisyUI Patterns to Check

| Component Type | Required Base Class | Common Modifiers |
|---------------|---------------------|------------------|
| Button | `btn` | `btn-primary`, `btn-secondary`, `btn-accent`, `btn-ghost`, `btn-link`, `btn-outline`, `btn-xs/sm/md/lg` |
| Card | `card` | `card-bordered`, `card-compact`, `card-side`, `image-full` |
| Modal | `modal`, `modal-box` | `modal-open`, `modal-bottom`, `modal-middle` |
| Dropdown | `dropdown` | `dropdown-hover`, `dropdown-end`, `dropdown-top`, `dropdown-bottom` |
| Tabs | `tabs` | `tabs-boxed`, `tabs-bordered`, `tabs-lifted`, `tab-active` |
| Alert/Notification | `alert` | `alert-info`, `alert-success`, `alert-warning`, `alert-error` |
| Badge/Tag | `badge` | `badge-primary`, `badge-secondary`, `badge-outline`, `badge-xs/sm/md/lg` |
| Progress | `progress` | `progress-primary`, `progress-secondary`, etc. |
| Table | `table` | `table-zebra`, `table-compact` |
| Menu | `menu` | `menu-horizontal`, `menu-vertical`, `menu-compact` |
| Drawer | `drawer`, `drawer-side` | `drawer-open`, `drawer-end` |
| Tooltip | `tooltip` | `tooltip-primary`, `tooltip-open`, `tooltip-top/bottom/left/right` |
| Avatar | `avatar` | `online`, `offline`, `placeholder` |
| Breadcrumb | `breadcrumbs` | (standard structure) |
| Navbar | `navbar` | `navbar-start`, `navbar-center`, `navbar-end` |
| Steps/Stepper | `steps` | `step`, `step-primary`, `step-info`, etc. |
| Timeline | `timeline` | `timeline-snap-icon`, `timeline-compact` |
| Carousel | `carousel` | `carousel-center`, `carousel-end`, `carousel-vertical` |

### Step 3: Visual Verification via Playwright

Use the Playwright MCP to verify components visually.

**CRITICAL: Playwright MCP Call Format**

When calling Playwright via `skill_mcp`, the `arguments` parameter MUST be a JSON STRING, not an object.

```
# CORRECT - arguments is a JSON string:
skill_mcp(mcp_name="playwright", tool_name="browser_navigate", arguments='{"url": "http://localhost:3001/lookbook"}')

skill_mcp(mcp_name="playwright", tool_name="browser_click", arguments='{"element": "button.btn"}')

skill_mcp(mcp_name="playwright", tool_name="browser_snapshot", arguments='{}')

# WRONG - do NOT pass object literals:
skill_mcp(mcp_name="playwright", tool_name="browser_navigate", arguments={"url": "..."})  # FAILS
```

**Available Playwright Tools:**
- `browser_navigate` - Navigate to URL. Args: `{"url": "..."}`
- `browser_snapshot` - Take accessibility snapshot. Args: `{}`
- `browser_click` - Click element. Args: `{"element": "...", "ref": "..."}` (use ref from snapshot)
- `browser_screenshot` - Take PNG screenshot. Args: `{}`
- `browser_type` - Type text. Args: `{"element": "...", "text": "...", "ref": "..."}`
- `browser_hover` - Hover element. Args: `{"element": "...", "ref": "..."}`

1. **Navigate to Lookbook preview**:
   ```
   URL: http://localhost:3001/lookbook/inspect/bali/[component_name]/[preview_method]
   ```

2. **For each preview method** (variant/state):
   - Take screenshot
   - Extract rendered HTML
   - Verify DaisyUI classes are present
   - Check responsive behavior (if applicable)

3. **Interactive element testing**:
   - Click triggers (buttons, tabs, dropdown triggers)
   - Verify state changes (active states, open/close)
   - Check hover states
   - Test keyboard navigation (if applicable)

### Step 4: JavaScript Functionality Verification

For components with Stimulus controllers:

1. **Identify controller**:
   - Check `stimulus_controller` method in component.rb
   - Or look for `data-controller` in template

2. **Test interactions**:

   | Component | JS Behavior to Test |
   |-----------|---------------------|
   | Dropdown | Click to open/close, close on outside click, close on item click |
   | Modal | Open/close, backdrop click dismiss, ESC key dismiss |
   | Tabs | Tab switching, content visibility toggle, URL hash update |
   | Drawer | Open/close toggle, overlay click dismiss |
   | Carousel | Navigation arrows, bullet navigation, autoplay (if any) |
   | Reveal | Show/hide content toggle |
   | Clipboard | Copy to clipboard, success feedback |
   | Tooltip | Show on hover, hide on leave |
   | Hovercard | Show on hover with delay, hide on leave |

3. **Verify via Playwright**:
   - Click/hover on trigger elements
   - Assert expected state changes
   - Check for JS errors in console

### Step 5: Pixel-Perfect UX Review (MANDATORY - frontend-ui-ux-engineer)

**THIS STEP IS NON-NEGOTIABLE** (unless `--quick` flag is explicitly used)

You MUST spawn the `frontend-ui-ux-engineer` agent for pixel-perfect visual review. This agent is CRITICAL and DEMANDING about visual quality. Do NOT skip this step or try to do the review yourself.

#### Why This Matters
The Calendar component migration revealed that basic visual checks miss critical issues:
- Column widths being unequal
- Navigation elements mispositioned
- Row heights not matching design specs
- Grid layouts breaking due to wrong CSS patterns

#### Pixel-Perfect Checklist (Agent MUST Verify)

| Category | Specific Checks |
|----------|-----------------|
| **Layout Geometry** | Equal column/row widths where expected, proper alignment, no overflow |
| **Navigation** | Prev/next arrows on opposite sides, centered titles, proper spacing |
| **Dimensions** | Cell heights match design (~100px for calendars, proper card heights) |
| **Spacing** | Consistent padding/margins, no cramped areas, proper gaps |
| **Borders** | Visible where expected, correct thickness, proper colors |
| **Backgrounds** | Correct colors applied, proper opacity, hover states |
| **Typography** | Font sizes match, proper weights, correct colors |
| **Today/Active States** | Clearly visible highlighting, proper contrast |

#### Compare Against Bulma Version (When Available)

If the original Bulma version is running on port 3002:
1. Open both versions side-by-side
2. Verify dimensions match or improve upon original
3. Note any intentional design changes vs bugs

#### Spawn Agent with This Prompt:

```
## TASK: PIXEL-PERFECT VISUAL REVIEW

You are reviewing the [ComponentName] component for PIXEL-PERFECT design quality.
Be EXTREMELY CRITICAL. Do NOT approve components with ANY layout issues.

## MANDATORY: USE DAISYUI BLUEPRINT MCP FOR REFERENCE

Before reviewing, you MUST fetch the official DaisyUI snippet to use as the authoritative reference:

1. Load the tool: MCPSearch(query: "select:mcp__daisyui-blueprint__daisyUI-Snippets")
2. Get the snippet: mcp__daisyui-blueprint__daisyUI-Snippets({"component": "[component_type]"})
3. Compare the component implementation against the official DaisyUI pattern

The DaisyUI Blueprint MCP provides the SINGLE SOURCE OF TRUTH for:
- Correct class combinations
- Recommended HTML structure
- Proper modifier usage
- Expected visual appearance

## COMPONENT INFO
- Component: Bali::[ComponentName]::Component
- DaisyUI URL: http://localhost:3001/lookbook/inspect/bali/[component_name]/default
- Bulma URL (if available): http://localhost:3002/lookbook/inspect/bali/[component_name]/default

## PIXEL-PERFECT CHECKLIST (VERIFY EACH ITEM)

### DaisyUI Blueprint Compliance (CHECK FIRST)
- [ ] Fetched official snippet from DaisyUI Blueprint MCP
- [ ] Base classes match DaisyUI recommendation
- [ ] Modifier classes follow DaisyUI naming convention
- [ ] HTML structure aligns with official pattern
- [ ] No deprecated or non-standard class combinations

### Layout Geometry
- [ ] All columns have EQUAL widths (measure if needed)
- [ ] All rows have consistent heights
- [ ] No unexpected overflow or wrapping
- [ ] Grid/flex layouts behave correctly

### Navigation Elements (if applicable)
- [ ] Left arrow/button is on the LEFT side
- [ ] Right arrow/button is on the RIGHT side
- [ ] Title/header is properly CENTERED
- [ ] Spacing between elements is consistent

### Dimensions
- [ ] Cell/card heights are appropriate (not too cramped)
- [ ] Minimum heights are respected
- [ ] Component doesn't collapse unexpectedly

### Visual Polish
- [ ] Borders are visible where expected
- [ ] Background colors applied correctly
- [ ] Hover/focus states work
- [ ] Active/selected states are clearly visible
- [ ] Proper shadows where expected

### Comparison with Original (if Bulma version available)
- [ ] Layout matches or improves upon original
- [ ] No regressions in visual quality
- [ ] Intentional changes documented

## MUST DO
1. Take screenshots of EVERY variant
2. Compare pixel-by-pixel where needed
3. Measure element dimensions if layout looks off
4. Check browser console for errors
5. Test hover/active states interactively

## MUST NOT DO
- Do NOT approve if ANY layout issue exists
- Do NOT skip checking all variants
- Do NOT just "eyeball" - be precise
- Do NOT modify code (report issues only)

## FAILURE CONDITIONS (AUTO-REJECT)
- DaisyUI Blueprint snippet not fetched before review
- Base classes don't match official DaisyUI pattern
- HTML structure deviates from DaisyUI recommendation
- Unequal column widths in grids/tables
- Navigation arrows both on same side
- Rows/cells too short for content
- Missing borders or backgrounds
- Broken hover/active states

## OUTPUT FORMAT
Provide a detailed report with:
1. Screenshot evidence for each issue
2. Specific measurements where applicable
3. Pass/Fail verdict with confidence level
4. List of required fixes (if any)
```

#### After Agent Completes

If the agent reports ANY issues:
1. DO NOT mark component as verified
2. Create fix tasks for each issue
3. Re-run verification after fixes

### Step 6: Generate Verification Report

```markdown
# Component Verification Report: [ComponentName]

## Summary
- Component: Bali::[ComponentName]::Component
- Verified: [timestamp]
- Status: [PASS/FAIL/NEEDS_REVIEW]

## DaisyUI Compliance

### DaisyUI Blueprint MCP Verification
- **Official Snippet Retrieved**: Yes/No
- **Component Type**: [component_type]

| Aspect | Blueprint Reference | Implementation | Match |
|--------|---------------------|----------------|-------|
| Base class | `[class]` | `[class]` | Yes/No |
| Structure | [pattern] | [pattern] | Yes/No |
| Modifiers | [classes] | [classes] | Yes/No |

### Classes Found
| Expected | Found | Status |
|----------|-------|--------|
| `[class]` | Yes/No | Pass/Fail |

### Missing DaisyUI Features
- [ ] [Feature 1]
- [ ] [Feature 2]

## Visual Verification

### Screenshots
| Variant | Screenshot | Status |
|---------|------------|--------|
| default | [path] | Pass/Fail |
| [variant] | [path] | Pass/Fail |

### Visual Issues Found
1. [Issue description]
2. [Issue description]

## JavaScript Functionality

### Controller: [controller_name]

| Interaction | Expected | Actual | Status |
|-------------|----------|--------|--------|
| Click trigger | Opens dropdown | Opens dropdown | Pass |
| Click outside | Closes dropdown | Closes dropdown | Pass |

### JS Errors
- None / [List errors]

## Pixel-Perfect UX Review (by frontend-ui-ux-engineer)

### Design Quality Score: X/10

### Pixel-Perfect Checklist Results

| Check | Status | Notes |
|-------|--------|-------|
| **DaisyUI Blueprint Compliance** | | |
| Official snippet fetched | Pass/Fail | |
| Base classes match | Pass/Fail | [discrepancies] |
| Structure matches | Pass/Fail | |
| Modifiers correct | Pass/Fail | |
| **Layout Geometry** | | |
| Column widths equal | Pass/Fail | [measurement if failed] |
| Navigation positioning | Pass/Fail | |
| Row/cell heights | Pass/Fail | [expected vs actual] |
| **Visual Polish** | | |
| Borders visible | Pass/Fail | |
| Backgrounds correct | Pass/Fail | |
| Hover states | Pass/Fail | |
| Active states | Pass/Fail | |

### Comparison with Bulma Version
- [ ] Matches original layout
- [ ] No visual regressions
- [ ] Improvements noted: [list]

### Issues Found (BLOCKING)
1. [Issue with screenshot evidence]
2. [Issue with measurements]

### Recommendations
1. [Recommendation 1]
2. [Recommendation 2]

## Final Verdict

**Status**: [APPROVED / NEEDS_FIXES / BLOCKED]

### Required Actions
- [ ] [Action 1]
- [ ] [Action 2]
```

## DaisyUI Reference Quick Links

Use these to verify component implementations:

- Buttons: https://daisyui.com/components/button/
- Cards: https://daisyui.com/components/card/
- Modals: https://daisyui.com/components/modal/
- Dropdowns: https://daisyui.com/components/dropdown/
- Tabs: https://daisyui.com/components/tab/
- Alerts: https://daisyui.com/components/alert/
- Badges: https://daisyui.com/components/badge/
- Progress: https://daisyui.com/components/progress/
- Tables: https://daisyui.com/components/table/
- Menus: https://daisyui.com/components/menu/
- Drawers: https://daisyui.com/components/drawer/
- Tooltips: https://daisyui.com/components/tooltip/
- Avatars: https://daisyui.com/components/avatar/
- Breadcrumbs: https://daisyui.com/components/breadcrumbs/
- Navbars: https://daisyui.com/components/navbar/
- Steps: https://daisyui.com/components/steps/
- Timeline: https://daisyui.com/components/timeline/
- Carousel: https://daisyui.com/components/carousel/

## Example Execution

```
User: /verify-component Dropdown

AI: Starting comprehensive verification of Bali::Dropdown::Component...

## Step 1: Component Discovery

**Files found:**
- app/components/bali/dropdown/component.rb
- app/components/bali/dropdown/component.html.erb
- app/components/bali/dropdown/preview.rb
- app/components/bali/dropdown/trigger/component.rb

**Metadata extracted:**
- Alignments: left, right, top, bottom, top_end, bottom_end
- Options: hoverable, close_on_click, wide
- Stimulus controller: dropdown
- Slots: trigger, items

## Step 2: DaisyUI Compliance

Checking against https://daisyui.com/components/dropdown/

| DaisyUI Class | In Component | Status |
|---------------|--------------|--------|
| `dropdown` | Yes | Pass |
| `dropdown-end` | Yes (right align) | Pass |
| `dropdown-top` | Yes | Pass |
| `dropdown-bottom` | Yes | Pass |
| `dropdown-hover` | Yes (hoverable) | Pass |
| `dropdown-content` | Yes | Pass |
| `menu` | Yes | Pass |

**Compliance Score: 100%**

## Step 3: Visual Verification

[Using Playwright to navigate and screenshot]

Screenshots captured:
- /tmp/verify/dropdown_default.png
- /tmp/verify/dropdown_hoverable.png
- /tmp/verify/dropdown_top_aligned.png
- /tmp/verify/dropdown_bottom_end.png
- /tmp/verify/dropdown_wide.png

All variants render correctly with proper DaisyUI styling.

## Step 4: JS Functionality

Testing Stimulus controller: dropdown

| Test | Result |
|------|--------|
| Click trigger opens dropdown | Pass |
| Click outside closes dropdown | Pass |
| Click item closes dropdown (when close_on_click: true) | Pass |
| Click item keeps open (when close_on_click: false) | Pass |
| Hoverable opens on hover | Pass |

No JS console errors detected.

## Step 5: UX Review

[Delegating to frontend-ui-ux-engineer...]

### UX Assessment

**Design Quality Score: 9/10**

**Strengths:**
- Clean DaisyUI implementation
- Smooth open/close transitions
- Good contrast and readability
- Proper z-index stacking

**Minor Issues:**
- Consider adding subtle shadow on focus for accessibility
- Wide variant could use max-width constraint on very large screens

## Final Verdict

**Status: APPROVED**

Component passes all verification checks. Minor UX suggestions noted for future improvement.
```

## Troubleshooting

### Lookbook not running
```bash
cd spec/dummy && bin/dev
```

### Component preview not found
Ensure `preview.rb` exists in the component folder with at least one preview method.

### JS functionality not working
1. Check Stimulus controller is registered
2. Verify data-controller attribute in template
3. Check browser console for errors

### Screenshots failing
Ensure Playwright MCP is configured and browser can access localhost:3001
