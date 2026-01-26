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

```erb
<%# GOOD - Associated label %>
<div class="form-control">
  <label class="label" for="email">
    <span class="label-text">Email</span>
  </label>
  <input type="email" id="email" class="input input-bordered"
         aria-describedby="email-hint email-error">
  <label class="label" id="email-hint">
    <span class="label-text-alt">We'll never share your email</span>
  </label>
</div>

<%# GOOD - Error state %>
<div class="form-control">
  <label class="label" for="password">
    <span class="label-text">Password</span>
  </label>
  <input type="password" id="password" 
         class="input input-bordered input-error"
         aria-invalid="true"
         aria-describedby="password-error">
  <label class="label" id="password-error">
    <span class="label-text-alt text-error">
      Password must be at least 8 characters
    </span>
  </label>
</div>

<%# BAD - No label association %>
<div class="form-control">
  <span class="label-text">Email</span>
  <input type="email" class="input">
</div>
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

```erb
<dialog class="modal" 
        role="dialog"
        aria-modal="true"
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
# spec/support/accessibility_helpers.rb
RSpec.configure do |config|
  config.include AccessibilityHelpers, type: :component
end

module AccessibilityHelpers
  def expect_accessible(page)
    # Check for basic accessibility issues
    expect(page).not_to have_css("img:not([alt])")
    expect(page).not_to have_css("input:not([id])")
    expect(page).not_to have_css("label:not([for])")
  end
end
```

### Manual Testing

| Test | Method |
|------|--------|
| Keyboard navigation | Tab through all interactive elements |
| Screen reader | Test with VoiceOver (Mac) or NVDA (Windows) |
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

<%# FIX %>
<dialog class="modal" 
        role="dialog" 
        aria-modal="true"
        aria-labelledby="modal-title">
  <div class="modal-box">
    <h3 id="modal-title">Dialog Title</h3>
    ...
  </div>
</dialog>
```
