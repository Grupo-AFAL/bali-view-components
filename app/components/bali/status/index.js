import { Controller } from '@hotwired/stimulus'

// Gap between the trigger and the panel, and the minimum breathing room the panel
// keeps from the viewport edges.
const PANEL_MARGIN = 8

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

  // A `fixed` element is positioned against the viewport ONLY while no ancestor
  // carries a transform, filter or perspective; one that does becomes the
  // containing block, and viewport coordinates then mean something else entirely.
  // Bali's own Drawer animates with `transform: translateX(...)`, so a pill inside
  // one used to get a `left` of ~1000px measured from the drawer's edge and threw
  // the panel off screen. Rather than special-case the drawer, probe for the
  // offset: park the panel at (0,0) and read back where it actually landed — 0,0
  // under the viewport, anything else under a transformed ancestor — then express
  // the position we want in that coordinate space. The horizontal clamp keeps the
  // panel on screen in both cases.
  reposition () {
    const panel = this.panelTarget
    const trigger = this.triggerTarget.getBoundingClientRect()

    panel.style.position = 'fixed'
    panel.style.minWidth = `${trigger.width}px`

    panel.style.left = '0px'
    panel.style.top = '0px'
    const origin = panel.getBoundingClientRect()

    const panelWidth = panel.offsetWidth
    const clampedLeft = Math.min(trigger.left, window.innerWidth - panelWidth - PANEL_MARGIN)
    const desiredLeft = Math.max(PANEL_MARGIN, clampedLeft)

    // Open downward, or upward if there isn't room below.
    const panelHeight = panel.offsetHeight
    const belowSpace = window.innerHeight - trigger.bottom
    const desiredTop = belowSpace < panelHeight && trigger.top > belowSpace
      ? trigger.top - panelHeight - PANEL_MARGIN
      : trigger.bottom + PANEL_MARGIN

    panel.style.left = `${desiredLeft - origin.left}px`
    panel.style.top = `${desiredTop - origin.top}px`
    panel.style.bottom = 'auto'
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
