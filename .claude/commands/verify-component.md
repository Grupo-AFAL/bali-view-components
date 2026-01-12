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

### Step 5: UX/Design Review (Delegate to frontend-ui-ux-engineer)

**MANDATORY** (unless `--quick` flag is used)

Delegate to `frontend-ui-ux-engineer` agent with this prompt structure:

```
## TASK
Review the visual design and UX of the [ComponentName] component for DaisyUI compliance and design quality.

## CONTEXT
- Component: Bali::[ComponentName]::Component
- Lookbook URL: http://localhost:3001/lookbook/inspect/bali/[component_name]/default
- Framework: DaisyUI (Tailwind CSS)
- Screenshots attached: [list of screenshot paths]

## EXPECTED OUTCOME
Provide a detailed UX assessment covering:
1. Visual consistency with DaisyUI design system
2. Color usage and contrast (accessibility)
3. Spacing and alignment
4. Interactive states (hover, focus, active, disabled)
5. Responsive behavior
6. Animation/transition smoothness
7. Overall design quality score (1-10)

## MUST DO
- Open Lookbook in browser and inspect ALL preview variants
- Check each variant against DaisyUI reference (https://daisyui.com/components/[component])
- Test on different viewport sizes
- Verify focus states for accessibility
- Note any visual inconsistencies

## MUST NOT DO
- Do not modify any code
- Do not skip any variant
- Do not approve components with obvious visual bugs

## REQUIRED TOOLS
- skill_mcp (Playwright) for browser automation

## PLAYWRIGHT CALL FORMAT (CRITICAL)
When using skill_mcp for Playwright, arguments MUST be a JSON string:

CORRECT:
skill_mcp(mcp_name="playwright", tool_name="browser_navigate", arguments='{"url": "http://localhost:3001/lookbook/inspect/bali/[component]/default"}')
skill_mcp(mcp_name="playwright", tool_name="browser_snapshot", arguments='{}')
skill_mcp(mcp_name="playwright", tool_name="browser_click", arguments='{"ref": "E123"}')

WRONG (will cause parse error):
skill_mcp(mcp_name="playwright", tool_name="browser_navigate", arguments={"url": "..."})
```

### Step 6: Generate Verification Report

```markdown
# Component Verification Report: [ComponentName]

## Summary
- Component: Bali::[ComponentName]::Component
- Verified: [timestamp]
- Status: [PASS/FAIL/NEEDS_REVIEW]

## DaisyUI Compliance

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

## UX Review (by frontend-ui-ux-engineer)

### Design Quality Score: X/10

### Positive Observations
- [Observation 1]
- [Observation 2]

### Issues Found
- [Issue 1]
- [Issue 2]

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
