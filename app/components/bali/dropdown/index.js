import { Controller } from '@hotwired/stimulus'

export class DropdownController extends Controller {
  static targets = ['trigger', 'menu']
  static values = {
    closeOnClick: { type: Boolean, default: true }
  }

  connect () {
    if (this.closeOnClickValue) {
      document.addEventListener('click', this.handleOutsideClick)
    }
    this.element.addEventListener('keydown', this.handleKeydown)
  }

  disconnect () {
    if (this.closeOnClickValue) {
      document.removeEventListener('click', this.handleOutsideClick)
    }
    this.element.removeEventListener('keydown', this.handleKeydown)
  }

  handleOutsideClick = (event) => {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  handleKeydown = (event) => {
    const isOpen = this.element.classList.contains('dropdown-open')

    switch (event.key) {
      case 'Escape':
        if (isOpen) {
          event.preventDefault()
          this.close()
          this.triggerTarget?.focus()
        }
        break
      case 'ArrowDown':
        event.preventDefault()
        if (!isOpen) {
          this.open()
        }
        this.focusNextItem()
        break
      case 'ArrowUp':
        event.preventDefault()
        if (!isOpen) {
          this.open()
        }
        this.focusPreviousItem()
        break
      case 'Enter':
      case ' ':
        if (document.activeElement === this.triggerTarget) {
          event.preventDefault()
          this.toggle()
        }
        break
    }
  }

  toggle () {
    if (this.element.classList.contains('dropdown-open')) {
      this.close()
    } else {
      this.open()
    }
  }

  open () {
    this.element.classList.add('dropdown-open')
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute('aria-expanded', 'true')
    }
  }

  close () {
    this.element.classList.remove('dropdown-open')
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute('aria-expanded', 'false')
    }
    this.element.querySelector('[tabindex]')?.blur()
  }

  focusNextItem () {
    const items = this.getMenuItems()
    if (items.length === 0) return

    const currentIndex = items.indexOf(document.activeElement)
    const nextIndex = currentIndex < items.length - 1 ? currentIndex + 1 : 0
    items[nextIndex]?.focus()
  }

  focusPreviousItem () {
    const items = this.getMenuItems()
    if (items.length === 0) return

    const currentIndex = items.indexOf(document.activeElement)
    const prevIndex = currentIndex > 0 ? currentIndex - 1 : items.length - 1
    items[prevIndex]?.focus()
  }

  getMenuItems () {
    if (!this.hasMenuTarget) return []
    return Array.from(this.menuTarget.querySelectorAll('[role="menuitem"]'))
  }
}
