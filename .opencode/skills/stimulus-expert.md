---
description: Expert guidance for Stimulus controllers in Bali ViewComponents
---

# Stimulus Expert Skill

This skill provides guidance for creating and maintaining Stimulus controllers for Bali ViewComponents.

## Reference

See `docs/reference/stimulus-patterns.md` for comprehensive patterns and examples.

## Quick Reference

### Controller Structure

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["element"]
  static values = { 
    open: { type: Boolean, default: false } 
  }
  static classes = ["active", "hidden"]

  connect() {
    // Setup
  }

  disconnect() {
    // Cleanup - ALWAYS remove event listeners
  }

  // Actions
  toggle() {
    this.openValue = !this.openValue
  }

  // Value change callbacks
  openValueChanged(value) {
    // React to state change
  }
}
```

### Common Patterns

#### Click Outside to Close

```javascript
connect() {
  this.boundClickOutside = this.clickOutside.bind(this)
  document.addEventListener("click", this.boundClickOutside)
}

disconnect() {
  document.removeEventListener("click", this.boundClickOutside)
}

clickOutside(event) {
  if (!this.element.contains(event.target)) {
    this.close()
  }
}
```

#### Keyboard Navigation

```javascript
keydown(event) {
  switch (event.key) {
    case "Escape":
      this.close()
      break
    case "ArrowDown":
      event.preventDefault()
      this.focusNext()
      break
    case "ArrowUp":
      event.preventDefault()
      this.focusPrevious()
      break
  }
}
```

#### Focus Trap (for Modals)

```javascript
trapFocus() {
  const focusable = this.element.querySelectorAll(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  )
  const first = focusable[0]
  const last = focusable[focusable.length - 1]

  this.element.addEventListener("keydown", (e) => {
    if (e.key !== "Tab") return
    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault()
      last.focus()
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault()
      first.focus()
    }
  })
  
  first?.focus()
}
```

### Component Templates

#### Dropdown

```erb
<div data-controller="dropdown"
     data-dropdown-open-value="false">
  <button data-action="click->dropdown#toggle"
          aria-haspopup="true"
          aria-expanded="false">
    Menu
  </button>
  <ul data-dropdown-target="menu"
      role="menu"
      class="hidden">
    <li role="menuitem"><a href="#">Item 1</a></li>
  </ul>
</div>
```

#### Modal

```erb
<dialog data-controller="modal"
        data-action="click->modal#backdropClick keydown->modal#keydown"
        class="modal">
  <div class="modal-box" data-modal-target="box">
    <h3 id="modal-title">Title</h3>
    <p>Content</p>
    <div class="modal-action">
      <button data-action="click->modal#close">Close</button>
    </div>
  </div>
</dialog>
```

#### Tabs

```erb
<div data-controller="tabs" data-tabs-index-value="0">
  <div role="tablist">
    <button role="tab" 
            data-action="click->tabs#select"
            data-tabs-target="tab">Tab 1</button>
    <button role="tab" 
            data-action="click->tabs#select"
            data-tabs-target="tab">Tab 2</button>
  </div>
  <div data-tabs-target="panel">Panel 1</div>
  <div data-tabs-target="panel" hidden>Panel 2</div>
</div>
```

## Anti-Patterns

### DON'T: Forget to clean up listeners

```javascript
// BAD - Memory leak
connect() {
  document.addEventListener("click", this.handleClick)
}

// GOOD
connect() {
  this.boundHandleClick = this.handleClick.bind(this)
  document.addEventListener("click", this.boundHandleClick)
}
disconnect() {
  document.removeEventListener("click", this.boundHandleClick)
}
```

### DON'T: Use jQuery

```javascript
// BAD
$(this.element).hide()

// GOOD
this.element.classList.add("hidden")
```

### DON'T: Mix concerns

```javascript
// BAD - Controller does too much
static targets = ["modal", "dropdown", "tabs", "form"]

// GOOD - One controller per concern
// modal_controller.js, dropdown_controller.js, etc.
```

## Testing

See `docs/reference/stimulus-patterns.md` for Cypress testing patterns.

```javascript
// Basic test structure
describe("Dropdown Controller", () => {
  beforeEach(() => {
    cy.visit("/lookbook/inspect/bali/dropdown/default")
  })

  it("toggles on click", () => {
    cy.get("[data-controller='dropdown'] button").click()
    cy.get("[data-dropdown-target='menu']").should("be.visible")
  })
})
```

## Debug Mode

Enable in browser console:

```javascript
window.baliDispatchDebugEnabled = true
```
