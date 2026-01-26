# Stimulus Controller Patterns for Bali

This document defines patterns for Stimulus controllers used in Bali ViewComponents.

## Controller Structure

```
app/assets/javascripts/bali/controllers/
├── [component]_controller.js     # Component-specific controller
├── shared/                        # Shared utilities
│   └── focus_trap.js
└── index.js                       # Registration
```

---

## Standard Controller Pattern

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // 1. Declare targets (DOM elements to reference)
  static targets = ["menu", "trigger", "content"]

  // 2. Declare values (reactive state)
  static values = {
    open: { type: Boolean, default: false },
    position: { type: String, default: "bottom" }
  }

  // 3. Declare classes (CSS classes to toggle)
  static classes = ["active", "hidden"]

  // 4. Lifecycle callbacks
  connect() {
    // Called when controller is connected to DOM
    this.boundClickOutside = this.clickOutside.bind(this)
  }

  disconnect() {
    // Called when controller is disconnected from DOM
    document.removeEventListener("click", this.boundClickOutside)
  }

  // 5. Actions (event handlers)
  toggle() {
    this.openValue = !this.openValue
  }

  open() {
    this.openValue = true
  }

  close() {
    this.openValue = false
  }

  // 6. Value change callbacks
  openValueChanged(value, previousValue) {
    if (value) {
      this.show()
      document.addEventListener("click", this.boundClickOutside)
    } else {
      this.hide()
      document.removeEventListener("click", this.boundClickOutside)
    }
  }

  // 7. Private methods
  show() {
    if (this.hasContentTarget) {
      this.contentTarget.classList.remove(this.hiddenClass)
    }
  }

  hide() {
    if (this.hasContentTarget) {
      this.contentTarget.classList.add(this.hiddenClass)
    }
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}
```

---

## Common Patterns

### Modal Controller

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]
  static values = { open: Boolean }

  connect() {
    // Handle ESC key
    this.boundKeydown = this.keydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
  }

  open() {
    this.dialogTarget.showModal()
    this.openValue = true
    this.trapFocus()
  }

  close() {
    this.dialogTarget.close()
    this.openValue = false
    this.releaseFocus()
  }

  // Close on backdrop click
  backdropClick(event) {
    const rect = this.dialogTarget.getBoundingClientRect()
    const isInDialog = (
      rect.top <= event.clientY &&
      event.clientY <= rect.top + rect.height &&
      rect.left <= event.clientX &&
      event.clientX <= rect.left + rect.width
    )
    if (!isInDialog) {
      this.close()
    }
  }

  keydown(event) {
    if (event.key === "Escape" && this.openValue) {
      this.close()
    }
  }

  trapFocus() {
    this.previousActiveElement = document.activeElement
    const focusable = this.dialogTarget.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )
    if (focusable.length) focusable[0].focus()
  }

  releaseFocus() {
    if (this.previousActiveElement) {
      this.previousActiveElement.focus()
    }
  }
}
```

### Dropdown Controller

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  static values = {
    open: { type: Boolean, default: false },
    closeOnSelect: { type: Boolean, default: true }
  }
  static classes = ["hidden"]

  connect() {
    this.boundClickOutside = this.clickOutside.bind(this)
    this.boundKeydown = this.keydown.bind(this)
  }

  disconnect() {
    this.removeListeners()
  }

  toggle() {
    this.openValue = !this.openValue
  }

  open() {
    this.openValue = true
  }

  close() {
    this.openValue = false
  }

  select(event) {
    if (this.closeOnSelectValue) {
      this.close()
    }
    // Dispatch custom event for parent components
    this.dispatch("select", { detail: { target: event.target } })
  }

  openValueChanged(isOpen) {
    if (isOpen) {
      this.showMenu()
      this.addListeners()
    } else {
      this.hideMenu()
      this.removeListeners()
    }
  }

  showMenu() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.remove(this.hiddenClass || "hidden")
      this.menuTarget.setAttribute("aria-expanded", "true")
    }
  }

  hideMenu() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add(this.hiddenClass || "hidden")
      this.menuTarget.setAttribute("aria-expanded", "false")
    }
  }

  addListeners() {
    document.addEventListener("click", this.boundClickOutside)
    document.addEventListener("keydown", this.boundKeydown)
  }

  removeListeners() {
    document.removeEventListener("click", this.boundClickOutside)
    document.removeEventListener("keydown", this.boundKeydown)
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  keydown(event) {
    switch (event.key) {
      case "Escape":
        this.close()
        break
      case "ArrowDown":
        event.preventDefault()
        this.focusNextItem()
        break
      case "ArrowUp":
        event.preventDefault()
        this.focusPreviousItem()
        break
    }
  }

  focusNextItem() {
    const items = this.menuTarget.querySelectorAll("[role='menuitem']")
    const current = document.activeElement
    const index = Array.from(items).indexOf(current)
    const next = items[index + 1] || items[0]
    next?.focus()
  }

  focusPreviousItem() {
    const items = this.menuTarget.querySelectorAll("[role='menuitem']")
    const current = document.activeElement
    const index = Array.from(items).indexOf(current)
    const prev = items[index - 1] || items[items.length - 1]
    prev?.focus()
  }
}
```

### Tabs Controller

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = {
    index: { type: Number, default: 0 },
    updateUrl: { type: Boolean, default: false }
  }

  connect() {
    this.showTab(this.indexValue)
  }

  select(event) {
    const tab = event.currentTarget
    const index = this.tabTargets.indexOf(tab)
    this.indexValue = index
  }

  indexValueChanged(index) {
    this.showTab(index)
    if (this.updateUrlValue) {
      this.updateUrlHash(index)
    }
    this.dispatch("change", { detail: { index } })
  }

  showTab(index) {
    this.tabTargets.forEach((tab, i) => {
      const isActive = i === index
      tab.classList.toggle("tab-active", isActive)
      tab.setAttribute("aria-selected", isActive)
      tab.setAttribute("tabindex", isActive ? "0" : "-1")
    })

    this.panelTargets.forEach((panel, i) => {
      const isActive = i === index
      panel.classList.toggle("hidden", !isActive)
      panel.setAttribute("aria-hidden", !isActive)
    })
  }

  // Keyboard navigation
  keydown(event) {
    switch (event.key) {
      case "ArrowLeft":
        this.selectPrevious()
        break
      case "ArrowRight":
        this.selectNext()
        break
      case "Home":
        this.indexValue = 0
        break
      case "End":
        this.indexValue = this.tabTargets.length - 1
        break
    }
  }

  selectNext() {
    this.indexValue = (this.indexValue + 1) % this.tabTargets.length
    this.tabTargets[this.indexValue].focus()
  }

  selectPrevious() {
    this.indexValue = (this.indexValue - 1 + this.tabTargets.length) % this.tabTargets.length
    this.tabTargets[this.indexValue].focus()
  }

  updateUrlHash(index) {
    const tab = this.tabTargets[index]
    const id = tab.dataset.tabId
    if (id) {
      history.replaceState(null, null, `#${id}`)
    }
  }
}
```

### Clipboard Controller

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "feedback"]
  static values = {
    successMessage: { type: String, default: "Copied!" },
    successDuration: { type: Number, default: 2000 }
  }

  async copy() {
    try {
      const text = this.sourceTarget.value || this.sourceTarget.textContent
      await navigator.clipboard.writeText(text)
      this.showSuccess()
      this.dispatch("copy", { detail: { text } })
    } catch (error) {
      this.showError()
      console.error("Failed to copy:", error)
    }
  }

  showSuccess() {
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.textContent = this.successMessageValue
      this.feedbackTarget.classList.remove("hidden")
      
      setTimeout(() => {
        this.feedbackTarget.classList.add("hidden")
      }, this.successDurationValue)
    }
  }

  showError() {
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.textContent = "Failed to copy"
      this.feedbackTarget.classList.add("text-error")
    }
  }
}
```

---

## Event Communication

### Dispatching Custom Events

```javascript
// Controller emitting event
this.dispatch("select", {
  detail: { value: selectedValue },
  prefix: "dropdown"  // Results in "dropdown:select"
})

// In HTML
<div data-action="dropdown:select->parent#handleSelect">
```

### Listening to Events

```javascript
// Controller listening to child events
handleSelect(event) {
  const { value } = event.detail
  console.log("Selected:", value)
}
```

### Cross-Controller Communication

```javascript
// Via custom events (preferred)
document.dispatchEvent(new CustomEvent("bali:modal:open", {
  detail: { id: "confirm-dialog" }
}))

// Via Stimulus outlets (for direct connections)
static outlets = ["modal"]

openModal() {
  this.modalOutlet.open()
}
```

---

## Accessibility Patterns

### Focus Management

```javascript
// Trap focus in modal
trapFocus(container) {
  const focusable = container.querySelectorAll(
    'a[href], button:not([disabled]), textarea:not([disabled]), ' +
    'input:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])'
  )
  
  const first = focusable[0]
  const last = focusable[focusable.length - 1]

  container.addEventListener("keydown", (e) => {
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

### ARIA Updates

```javascript
// Update ARIA attributes reactively
openValueChanged(isOpen) {
  this.triggerTarget.setAttribute("aria-expanded", isOpen)
  this.menuTarget.setAttribute("aria-hidden", !isOpen)
}
```

### Screen Reader Announcements

```javascript
announce(message) {
  const announcer = document.getElementById("sr-announcer") ||
    this.createAnnouncer()
  
  announcer.textContent = message
}

createAnnouncer() {
  const el = document.createElement("div")
  el.id = "sr-announcer"
  el.setAttribute("aria-live", "polite")
  el.setAttribute("aria-atomic", "true")
  el.classList.add("sr-only")
  document.body.appendChild(el)
  return el
}
```

---

## Testing Patterns

### Cypress Tests

```javascript
// cypress/e2e/dropdown.cy.js
describe("Dropdown Controller", () => {
  beforeEach(() => {
    cy.visit("/lookbook/inspect/bali/dropdown/default")
  })

  it("opens on click", () => {
    cy.get("[data-controller='dropdown']").within(() => {
      cy.get("[data-dropdown-target='menu']").should("have.class", "hidden")
      cy.get("button").click()
      cy.get("[data-dropdown-target='menu']").should("not.have.class", "hidden")
    })
  })

  it("closes on outside click", () => {
    cy.get("button").click()
    cy.get("[data-dropdown-target='menu']").should("not.have.class", "hidden")
    cy.get("body").click(0, 0)
    cy.get("[data-dropdown-target='menu']").should("have.class", "hidden")
  })

  it("closes on Escape key", () => {
    cy.get("button").click()
    cy.get("body").type("{esc}")
    cy.get("[data-dropdown-target='menu']").should("have.class", "hidden")
  })

  it("supports keyboard navigation", () => {
    cy.get("button").click()
    cy.get("body").type("{downArrow}")
    cy.focused().should("have.attr", "role", "menuitem")
  })
})
```

---

## Debug Mode

Enable debugging for development:

```javascript
// In browser console
window.baliDispatchDebugEnabled = true
```

```javascript
// In controller
dispatch(name, detail) {
  if (window.baliDispatchDebugEnabled) {
    console.log(`[Bali] ${this.identifier}:${name}`, detail)
  }
  super.dispatch(name, detail)
}
```

---

## Anti-Patterns

### Don't: Kitchen Sink Controllers

```javascript
// BAD - Too many responsibilities
export default class extends Controller {
  static targets = ["modal", "dropdown", "tabs", "form", "toast", ...]
  // 500 lines of mixed concerns
}

// GOOD - Single responsibility
export default class extends Controller {
  static targets = ["dialog"]
  // Only modal-related logic
}
```

### Don't: Direct DOM Manipulation Outside Controller

```javascript
// BAD
document.querySelector(".modal").classList.add("open")

// GOOD - Use targets and Stimulus patterns
this.modalTarget.classList.add("open")
```

### Don't: Ignore Cleanup

```javascript
// BAD - Memory leak
connect() {
  document.addEventListener("click", this.handleClick)
}

// GOOD - Clean up listeners
connect() {
  this.boundHandleClick = this.handleClick.bind(this)
  document.addEventListener("click", this.boundHandleClick)
}

disconnect() {
  document.removeEventListener("click", this.boundHandleClick)
}
```
