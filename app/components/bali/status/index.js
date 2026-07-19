import { Controller } from '@hotwired/stimulus'

// Drives the editable status pill: opens/closes the options panel, positions it
// with position:fixed (so it escapes DataTable overflow clipping), and wires
// keyboard + outside-click. Selecting an option submits the form natively; the
// app's Turbo Stream then replaces this element, so no "close after select" is
// needed here.
export class StatusController extends Controller {
  static targets = ['trigger', 'panel']

  connect () {
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
    this.handleKeydown = this.handleKeydown.bind(this)
    this.reposition = this.reposition.bind(this)
  }

  disconnect () {
    this.close()
  }

  toggle (event) {
    event?.preventDefault()
    this.isOpen ? this.close() : this.open()
  }

  open () {
    if (this.isOpen) return
    this.isOpen = true
    this.panelTarget.hidden = false
    this.panelTarget.classList.add('status-panel--open')
    this.triggerTarget.setAttribute('aria-expanded', 'true')
    this.reposition()

    document.addEventListener('click', this.handleOutsideClick)
    document.addEventListener('keydown', this.handleKeydown)
    window.addEventListener('resize', this.reposition)
    window.addEventListener('scroll', this.reposition, true)

    this.currentOption?.focus()
  }

  close () {
    if (!this.isOpen) return
    this.isOpen = false
    if (this.hasPanelTarget) {
      this.panelTarget.hidden = true
      this.panelTarget.classList.remove('status-panel--open')
    }
    this.triggerTarget?.setAttribute('aria-expanded', 'false')

    document.removeEventListener('click', this.handleOutsideClick)
    document.removeEventListener('keydown', this.handleKeydown)
    window.removeEventListener('resize', this.reposition)
    window.removeEventListener('scroll', this.reposition, true)
  }

  // Lets the native submit run; nothing else to do here.
  clear () {}

  reposition () {
    const rect = this.triggerTarget.getBoundingClientRect()
    const panel = this.panelTarget
    panel.style.position = 'fixed'
    panel.style.minWidth = `${rect.width}px`
    panel.style.left = `${rect.left}px`

    // Open downward, or upward if there isn't room below.
    const belowSpace = window.innerHeight - rect.bottom
    const panelHeight = panel.offsetHeight
    if (belowSpace < panelHeight && rect.top > belowSpace) {
      panel.style.top = 'auto'
      panel.style.bottom = `${window.innerHeight - rect.top + 4}px`
    } else {
      panel.style.bottom = 'auto'
      panel.style.top = `${rect.bottom + 4}px`
    }
  }

  handleOutsideClick (event) {
    if (!this.element.contains(event.target) && !this.panelTarget.contains(event.target)) {
      this.close()
    }
  }

  handleKeydown (event) {
    switch (event.key) {
      case 'Escape':
        event.preventDefault()
        this.close()
        this.triggerTarget.focus()
        break
      case 'ArrowDown':
        event.preventDefault()
        this.focusRelative(1)
        break
      case 'ArrowUp':
        event.preventDefault()
        this.focusRelative(-1)
        break
    }
  }

  focusRelative (delta) {
    const items = this.optionItems
    if (items.length === 0) return
    const index = items.indexOf(document.activeElement)
    const next = (index + delta + items.length) % items.length
    items[next].focus()
  }

  get optionItems () {
    return Array.from(this.panelTarget.querySelectorAll('[role="option"]'))
  }

  get currentOption () {
    return this.panelTarget.querySelector('[aria-selected="true"]') || this.optionItems[0]
  }
}
