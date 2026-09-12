# Accessibility Guide for Bali ViewComponents

This guide defines accessibility (a11y) standards and patterns for all Bali ViewComponents.

## Target Compliance

- **WCAG 2.1 Level AA** - Minimum requirement for all components
- **WCAG 2.1 Level AAA** - Aspirational for enhanced components

---

## Core Principles

### 1. Perceivable

Users must be able to perceive all content.

**Requirements:**
- Text alternatives for images (`alt` attributes)
- Captions for multimedia
- Color contrast ratios (4.5:1 for text, 3:1 for large text)
- Don't rely on color alone to convey information

### 2. Operable

Users must be able to operate all interactive elements.

**Requirements:**
- All functionality available via keyboard
- No keyboard traps
- Skip navigation links
- Sufficient time for interactions
- No seizure-inducing flashing content

### 3. Understandable

Users must be able to understand content and interface.

**Requirements:**
- Clear, consistent navigation
- Predictable behavior
- Error identification and suggestions
- Labels and instructions for inputs

### 4. Robust

Content must work with assistive technologies.

**Requirements:**
- Valid HTML markup
- Proper ARIA usage
- Name, role, value programmatically determinable

---

## Component Requirements

### Interactive Elements

All buttons, links, and controls must have:

| Requirement | Implementation |
|-------------|----------------|
| Keyboard accessible | `tabindex="0"` or native focusable element |
| Focus visible | `:focus-visible` styles (DaisyUI provides this) |
| Role announced | Native element or `role` attribute |
| Name announced | Visible text, `aria-label`, or `aria-labelledby` |
| State announced | `aria-expanded`, `aria-selected`, `aria-pressed` |

### Buttons

```erb
<%# GOOD - Native button with visible text %>
<button class="btn btn-primary">
  Save Changes
</button>

<%# GOOD - Icon button with aria-label %>
<button class="btn btn-circle" aria-label="Close dialog">
  <svg>...</svg>
</button>

<%# BAD - No accessible name %>
<button class="btn btn-circle">
  <svg>...</svg>
</button>

<%# BAD - div as button %>
<div class="btn" onclick="...">Click me</div>
```

### Links

```erb
<%# GOOD - Descriptive link text %>
<a href="/reports">View quarterly reports</a>

<%# BAD - Non-descriptive %>
<a href="/reports">Click here</a>

<%# GOOD - Link that opens new window %>
<a href="..." target="_blank" rel="noopener">
  External site
  <span class="sr-only">(opens in new tab)</span>
</a>
```

### Forms

The FormBuilder produces all of this — the associated label, the described-by wiring for
help and error text, the `aria-invalid` on error — so the accessible form is the default
one:

```erb
<%# GOOD - the FormBuilder wires label, help and error for you %>
<%= f.email_group :email, help: "We'll never share your email" %>
<%= f.password_group :password, error: "Password must be at least 8 characters" %>
```

Writing the markup by hand, this is what it has to amount to (daisyUI 5's `fieldset`
vocabulary — `form-control`/`label-text`/`input-bordered` were daisyUI 4 and no longer
exist):

```erb
<%# GOOD - associated label, described-by help (what email_group renders) %>
<fieldset class="fieldset">
  <label class="fieldset-legend" for="email">Email</label>
  <input type="email" id="email" class="input" aria-describedby="email-hint">
  <p class="fieldset-label" id="email-hint">We'll never share your email</p>
</fieldset>

<%# GOOD - error state %>
<fieldset class="fieldset">
  <label class="fieldset-legend" for="password">Password</label>
  <input type="password" id="password" class="input input-error"
         aria-invalid="true" aria-describedby="password-error">
  <p class="fieldset-label text-error" id="password-error">
    Password must be at least 8 characters
  </p>
</fieldset>

<%# BAD - no label association %>
<fieldset class="fieldset">
  <span>Email</span>
  <input type="email" class="input">
</fieldset>
```

### Images

```erb
<%# Informative image - describe content %>
<img src="chart.png" alt="Sales increased 25% in Q3 2024">

<%# Decorative image - empty alt %>
<img src="decorative-swirl.png" alt="">

<%# Complex image - longer description %>
<figure>
  <img src="org-chart.png" 
       alt="Organization chart showing reporting structure"
       aria-describedby="org-chart-desc">
  <figcaption id="org-chart-desc">
    CEO at top, with three VPs reporting directly...
  </figcaption>
</figure>
```

---

## ARIA Patterns by Component

### Modal

`Bali::Modal` and `Bali::Drawer` render a native `<dialog>` and open it with
`showModal()`. Do the same in your own markup, and do **not** write `role="dialog"`
or `aria-modal="true"` on it: both are implicit on the element, and `aria-modal`
written by hand is a claim the markup cannot keep — a `<dialog>` that no script has
opened with `showModal()` is not modal, whatever the attribute says.

```erb
<dialog class="modal"
        aria-labelledby="modal-title"
        aria-describedby="modal-desc">
  <div class="modal-box">
    <h3 id="modal-title" class="font-bold text-lg">Confirm Action</h3>
    <p id="modal-desc" class="py-4">Are you sure you want to proceed?</p>
    <div class="modal-action">
      <button class="btn">Cancel</button>
      <button class="btn btn-primary">Confirm</button>
    </div>
  </div>
</dialog>
```

**Stimulus Requirements:**
- Focus trap within modal
- Return focus to trigger on close
- Close on Escape key
- Close on backdrop click (optional)

### Dropdown Menu

```erb
<div class="dropdown" data-controller="dropdown">
  <button class="btn" 
          aria-haspopup="true"
          aria-expanded="false"
          aria-controls="dropdown-menu"
          data-action="click->dropdown#toggle">
    Options
  </button>
  <ul id="dropdown-menu"
      class="dropdown-content menu"
      role="menu"
      aria-label="Options menu">
    <li role="none">
      <a href="#" role="menuitem">Edit</a>
    </li>
    <li role="none">
      <a href="#" role="menuitem">Delete</a>
    </li>
  </ul>
</div>
```

**Keyboard Requirements:**
- Enter/Space: Open menu
- Escape: Close menu
- Arrow Down: Move to next item
- Arrow Up: Move to previous item
- Home: Move to first item
- End: Move to last item

### Tabs

```erb
<div class="tabs" role="tablist" aria-label="Content sections">
  <button class="tab tab-active"
          role="tab"
          aria-selected="true"
          aria-controls="panel-1"
          id="tab-1"
          tabindex="0">
    Tab 1
  </button>
  <button class="tab"
          role="tab"
          aria-selected="false"
          aria-controls="panel-2"
          id="tab-2"
          tabindex="-1">
    Tab 2
  </button>
</div>

<div id="panel-1"
     role="tabpanel"
     aria-labelledby="tab-1"
     tabindex="0">
  Content for tab 1
</div>

<div id="panel-2"
     role="tabpanel"
     aria-labelledby="tab-2"
     hidden>
  Content for tab 2
</div>
```

**Keyboard Requirements:**
- Arrow Left/Right: Move between tabs
- Home: First tab
- End: Last tab
- Enter/Space: Activate tab (if not automatic)

### Alert/Notification

```erb
<%# Static alert %>
<div class="alert alert-warning" role="alert">
  <span>Warning: Your session will expire in 5 minutes</span>
</div>

<%# Dynamic notification (toast) %>
<div class="toast" 
     role="status"
     aria-live="polite"
     aria-atomic="true">
  <div class="alert alert-success">
    <span>Changes saved successfully</span>
  </div>
</div>

<%# Error notification %>
<div class="alert alert-error"
     role="alert"
     aria-live="assertive">
  <span>Error: Unable to save changes</span>
</div>
```

### Progress

```erb
<%# Determinate progress %>
<progress class="progress progress-primary"
          value="70"
          max="100"
          aria-label="Upload progress"
          aria-valuenow="70"
          aria-valuemin="0"
          aria-valuemax="100">
  70%
</progress>

<%# Indeterminate progress %>
<progress class="progress"
          aria-label="Loading"
          aria-busy="true">
</progress>

<%# Loading spinner %>
<span class="loading loading-spinner"
      role="status"
      aria-label="Loading">
  <span class="sr-only">Loading...</span>
</span>
```

### Tooltip

```erb
<div class="tooltip" data-tip="More information about this feature">
  <button class="btn"
          aria-describedby="tooltip-1">
    Help
  </button>
</div>

<%# For complex tooltips, use aria-describedby %>
<button aria-describedby="tooltip-content">
  Advanced
</button>
<div id="tooltip-content" role="tooltip" class="hidden">
  This feature allows you to configure...
</div>
```

### Table

```erb
<div class="overflow-x-auto" tabindex="0" role="region" aria-label="User data">
  <table class="table">
    <caption class="sr-only">List of registered users</caption>
    <thead>
      <tr>
        <th scope="col">Name</th>
        <th scope="col">Email</th>
        <th scope="col">Role</th>
        <th scope="col">
          <span class="sr-only">Actions</span>
        </th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>John Doe</td>
        <td>john@example.com</td>
        <td>Admin</td>
        <td>
          <button class="btn btn-ghost btn-sm" aria-label="Edit John Doe">
            Edit
          </button>
        </td>
      </tr>
    </tbody>
  </table>
</div>
```

### Tabs vs navigation

Sharing a look is not sharing a role. `Bali::Tabs` renders two different widgets and picks
between them by whether the triggers have an `href:`:

| Triggers | Renders | Why |
|---|---|---|
| No `href:` — each tab owns a panel | `role="tablist"` / `role="tab"` / `role="tabpanel"` | The ARIA tabs pattern: a click swaps a panel without leaving the page |
| `href:` on **every** tab | `<nav aria-label>` + `aria-current="page"` | The click leaves the page. There is no panel, so `role="tab"` would promise an `aria-controls` target that does not exist |

Mixing them raises `ArgumentError`. A tablist where half the children are links leaving the
page is a widget ARIA does not describe.

Name the `<nav>` whenever a page holds more than one: `Tabs::Component.new(label: '…')`.

### Label / value pairs

A `<label>` with no `for=` and no control inside it labels nothing — the text and the value
next to it end up as two unrelated nodes in the accessibility tree. Use the pairing the
markup actually means:

```erb
<%# One pair that stands on its own, or pairs placed individually in a grid %>
<%= render Bali::LabelValue::Component.new(label: 'Name', value: 'Juan Perez') %>
<%# → <dl><dt>Name</dt><dd>Juan Perez</dd></dl> %>

<%# A set read top to bottom: one table, one announcement of how many rows %>
<%= render Bali::PropertiesTable::Component.new do |t| %>
  <% t.with_property(label: 'Name', value: 'Juan Perez') %>
  <% t.with_property(label: 'Email', value: 'juan@example.com') %>
<% end %>
```

### Icon-only state

An icon is not a name. Lucide ships its SVGs `aria-hidden`, so an icon on its own is an
anonymous node — a table cell holding one announces as empty, and colour ends up being the
only thing separating two states, which fails WCAG 1.4.1 as well.

```erb
<%# Bali::BooleanIcon does this for you: icon + sr-only name %>
<%= render Bali::BooleanIcon::Component.new(value: movie.indie) %>

<%# The hand-rolled equivalent %>
<span class="text-success">
  <%= render Bali::Icon::Component.new('check-circle', 'aria-hidden': true) %>
  <span class="sr-only">Yes</span>
</span>
```

Keep three states three states. `nil` is missing data, not `false`: announcing "No" for a
column nobody filled in asserts something the record does not say.

### Charts and other canvas

A canvas is opaque to assistive tech — everything drawn into it is pixels, and the fallback
content inside the tag is only surfaced when canvas itself is unsupported.

```erb
<%= render Bali::Chart::Component.new(data: @sales, title: 'Weekly sales') do |c| %>
  <% c.with_data_table do %>
    <%# a real <table>, visually hidden next to the canvas %>
  <% end %>
<% end %>
```

- `role="img"` plus a name is the floor. An unnamed `role="img"` is announced as nothing,
  so a generic name beats none.
- A name is not a number. The `data_table` slot is the only way a screen reader user reads
  a value off the chart.
- The same table is the chart's no-JS fallback: with scripting off the canvas never draws,
  so `@media (scripting: none)` reveals the table and collapses the empty canvas box
  instead of leaving a container-height hole.

The same reasoning drives `Bali::Heatmap`: axis labels are `<th scope="col">` and
`<th scope="row">` so both axes reach the cell as headers, and each cell carries its value
as `sr-only` text, because a coloured cell with no text is an empty cell.

### Drag and drop

A drop moves the DOM and nothing else: focus stays where it was and no text changes, so
nothing is announced. A live region is the only channel the outcome can travel through.

```erb
<%# Bali::Kanban ships this: a role="status" region plus a translated template %>
<div class="sr-only" role="status" aria-live="polite" aria-atomic="true"
     data-kanban-target="liveRegion"></div>
```

Two things that are easy to get wrong:

- **The region has to be in the DOM before the text arrives.** Inserting the region and its
  text together is not a change to a live region; it is a new element, and most screen
  readers say nothing.
- **Writing the same string twice is not a change either.** Dropping a card back where it
  came from goes silent unless you clear the region first and set it on the next frame.

Name the drop targets too: `Kanban` gives each column `role="list"` with an `aria-label`
carrying the count, including `"Backlog, 0 cards"` — an empty column that stays quiet is an
unnamed list of nothing.

---

## Color Contrast Requirements

### Minimum Ratios (WCAG AA)

| Text Size | Ratio | Example |
|-----------|-------|---------|
| Normal text (< 18pt) | 4.5:1 | `text-base-content` on `bg-base-100` |
| Large text (>= 18pt or 14pt bold) | 3:1 | Headers |
| UI components & graphics | 3:1 | Buttons, icons, form borders |

### DaisyUI Semantic Colors

DaisyUI themes are designed for accessibility. Use semantic colors:

```erb
<%# GOOD - Semantic colors adapt to themes %>
<p class="text-base-content">Regular text</p>
<p class="text-primary">Primary accent</p>
<p class="text-error">Error message</p>

<%# BAD - Hardcoded colors may not have contrast %>
<p class="text-gray-400">May not have sufficient contrast</p>
```

### Testing Contrast

```ruby
# In component
def text_class_for_background(bg_color)
  case bg_color
  when :primary, :secondary, :accent, :neutral
    "text-#{bg_color}-content"
  when :success, :warning, :error, :info
    "text-#{bg_color}-content"
  else
    "text-base-content"
  end
end
```

---

## Focus Management

### Focus Visibility

DaisyUI provides focus styles. Ensure they're not overridden:

```css
/* DON'T remove focus outlines */
*:focus {
  outline: none; /* BAD */
}

/* DO customize focus styles */
.btn:focus-visible {
  outline: 2px solid currentColor;
  outline-offset: 2px;
}
```

### Focus Order

Ensure logical tab order:

```erb
<%# GOOD - Natural reading order %>
<header>...</header>
<nav>...</nav>
<main>...</main>
<footer>...</footer>

<%# BAD - CSS reorders visually but not focus %>
<main class="order-2">...</main>
<nav class="order-1">...</nav>
```

### Skip Links

`Bali::AppLayout::Component` renders one for you. It is the first focusable element on the
page, it points at the `<main id="main-content" tabindex="-1">` the layout also renders, and it
is off-screen until it takes focus. Pass `skip_link: false` to opt out.

Hand-rolling one outside AppLayout:

```erb
<body>
  <a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:bg-base-100 focus:p-4">
    Skip to main content
  </a>

  <nav>...</nav>

  <main id="main-content" tabindex="-1">
    ...
  </main>
</body>
```

`tabindex="-1"` on the target is not optional: without it the browser scrolls to `<main>` but
leaves focus behind, and the next Tab restarts at the top of the page.

### Sidebar navigation

`Bali::SideMenu::Component` renders a `<nav aria-label>` landmark whose items are a real
`ul`/`li` list, and marks the link pointing at the current page with `aria-current="page"`. An
ancestor of the current page stays visually highlighted but does **not** get `aria-current` —
that belongs to the one link that actually points at the page you are on.

Everything that opens or collapses it is a `<button>`. Do not build your own hamburger: render
`Bali::SideMenu::Trigger::Component`, which carries `aria-controls`, keeps `aria-expanded` in
sync with the sidebar, and gets focus back when the drawer closes.

```erb
<%= render Bali::SideMenu::Trigger::Component.new %>
```

Below the `lg` breakpoint the sidebar is a modal drawer:

- it carries `inert` while closed, so nothing inside it is reachable by Tab;
- opening it moves focus to its first control and keeps Tab inside it;
- Escape closes it and returns focus to the trigger that opened it.

---

## Screen Reader Utilities

### Visually Hidden (sr-only)

```erb
<%# Hidden visually but read by screen readers %>
<span class="sr-only">Additional context for screen readers</span>

<%# Show on focus (for skip links) %>
<a href="#main" class="sr-only focus:not-sr-only">Skip to main</a>
```

### Live Regions

```erb
<%# Polite - waits for pause in speech %>
<div aria-live="polite" aria-atomic="true" id="notifications">
  <%# Dynamic content inserted here %>
</div>

<%# Assertive - interrupts immediately %>
<div aria-live="assertive" id="alerts">
  <%# Critical alerts inserted here %>
</div>
```

---

## Testing Checklist

### Automated Testing

Run these checks on every component:

```ruby
# test/support/accessibility_helpers.rb — the repo's suite is Minitest;
# include this in your ComponentTestCase (Capybara matchers are available
# through ViewComponent::TestHelpers).
module AccessibilityHelpers
  def assert_basic_a11y
    assert_no_selector("img:not([alt])", visible: :all)
    assert_no_selector("input:not([type=hidden]):not([id])", visible: :all)
    assert_no_selector("label:not([for])", visible: :all)
  end
end
```

### Read the accessibility tree, not the markup

An `aria-label` on the wrong element looks perfect in the HTML and never reaches the tree.
Assert against what the browser computed:

- **DevTools** → Elements → Accessibility pane, or the full-page tree at the top of it.
- **Scripted**, over CDP — this is the same tree, and it works headless:

  ```js
  const cdp = await context.newCDPSession(page)
  await cdp.send('Accessibility.enable')
  const { nodes } = await cdp.send('Accessibility.getFullAXTree')
  // each node: { role: {value}, name: {value}, properties: [...], childIds, ignored }
  ```

  `page.accessibility.snapshot()` was removed in Playwright 1.61; `getFullAXTree` replaces it.

Two traps worth knowing before you trust a negative result:

- **CDP does not report `aria-current`.** It is absent from the `AXPropertyName` enum, so a
  link with `aria-current="page"` shows no such property even on a hand-written control
  page. Verify that one in the DOM.
- **A page at rest hides half the work.** A live region is empty until something writes to
  it, and a drop announcement only exists after a real drag. Provoke the state; a snapshot
  of the loaded page will look clean and prove nothing.

### Manual Testing

| Test | Method |
|------|--------|
| Keyboard navigation | Tab through all interactive elements |
| Screen reader | Test with VoiceOver (Mac) or NVDA (Windows) |
| Accessibility tree | Read it, per the section above — not the rendered HTML |
| Zoom | Test at 200% zoom |
| Color blindness | Use simulator (e.g., Chrome DevTools) |
| Motion | Test with `prefers-reduced-motion` |

### Accessibility Audit Checklist

For each component, verify:

- [ ] All interactive elements are keyboard accessible
- [ ] Focus is visible on all interactive elements
- [ ] Focus order is logical
- [ ] ARIA roles are correct
- [ ] ARIA states update dynamically
- [ ] Color contrast meets minimum ratios
- [ ] Text alternatives for images
- [ ] Form inputs have labels
- [ ] Error messages are associated with inputs
- [ ] No content flashes more than 3 times per second

---

## Tools

### Browser Extensions

- **axe DevTools** - Automated accessibility testing
- **WAVE** - Visual accessibility evaluation
- **Lighthouse** - Includes accessibility audit

### Testing in Development

```bash
# Install axe-core for automated checks
yarn add -D axe-core

# In Cypress tests
cy.injectAxe()
cy.checkA11y()
```

### Screen Readers

- **VoiceOver** - Built into macOS (Cmd + F5)
- **NVDA** - Free for Windows
- **JAWS** - Commercial, widely used

---

## Common Issues and Fixes

### Issue: Missing button name

```erb
<%# BAD %>
<button class="btn btn-circle">
  <svg>...</svg>
</button>

<%# FIX %>
<button class="btn btn-circle" aria-label="Close">
  <svg aria-hidden="true">...</svg>
</button>
```

### Issue: Form without labels

```erb
<%# BAD %>
<input type="text" placeholder="Search...">

<%# FIX %>
<label class="sr-only" for="search">Search</label>
<input type="text" id="search" placeholder="Search...">

<%# Or with aria-label %>
<input type="text" aria-label="Search" placeholder="Search...">
```

### Issue: Color-only indication

```erb
<%# BAD - Only color indicates error %>
<input class="input-error">

<%# FIX - Add icon and text %>
<input class="input-error" aria-invalid="true" aria-describedby="error-msg">
<p id="error-msg" class="text-error flex items-center gap-2">
  <svg aria-hidden="true">...</svg>
  This field is required
</p>
```

### Issue: Missing modal attributes

```erb
<%# BAD %>
<div class="modal">
  <div class="modal-box">...</div>
</div>

<%# FIX — a native <dialog>, opened with showModal(). No `role`, no
    `aria-modal`: both are implicit, and the element decides its own modality. %>
<dialog class="modal"
        aria-labelledby="modal-title">
  <div class="modal-box">
    <h3 id="modal-title">Dialog Title</h3>
    ...
  </div>
</dialog>
```
