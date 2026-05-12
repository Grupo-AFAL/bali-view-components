import { Controller } from '@hotwired/stimulus'

// Side-menu flyout: keyboard + touch support for the collapsed-state
// popup that appears on hover for expandable items with children.
//
// Hover/focus open is handled by DaisyUI's dropdown-hover (CSS).
// This controller adds the keyboard niceties on top:
//
//   ArrowRight / Enter on trigger → focus first child link (opens panel)
//   Escape on trigger or panel    → close panel and refocus trigger
//   ArrowDown / ArrowUp in panel  → move focus between links
//   ArrowLeft in panel            → return focus to trigger
//
// Touch (pointer: coarse): first tap on a parent <a> trigger opens the
// panel without navigating; the user reaches the parent's own page via
// the parent-name link inside the panel. Subsequent taps (panel already
// open) navigate as normal.
export class SideMenuFlyoutController extends Controller {
  static targets = ['trigger', 'panel']

  connect () {
    // Anchor the panel to the trigger. DaisyUI's CSS Anchor Positioning
    // doesn't reliably point a `position: fixed` panel at the right
    // place when the sidebar overflow-scrolls, so we set top/left
    // ourselves before each open and on scroll/resize so a long sidebar
    // scrolling under an open panel doesn't leave the panel detached.
    this.boundUpdatePosition = this.updatePosition.bind(this)
    this.scrollParent = this.element.closest('.sidebar-menu') ?? window
    this.element.addEventListener('mouseenter', this.boundUpdatePosition)
    this.element.addEventListener('focusin', this.boundUpdatePosition)
    this.scrollParent.addEventListener('scroll', this.boundUpdatePosition, { passive: true })
    window.addEventListener('resize', this.boundUpdatePosition, { passive: true })
    this.updatePosition()

    if (this.coarsePointer) {
      this.boundPointerDown = this.onPointerDown.bind(this)
      this.boundClick = this.onClick.bind(this)
      this.triggerTarget.addEventListener('pointerdown', this.boundPointerDown)
      this.triggerTarget.addEventListener('click', this.boundClick)
    }
  }

  disconnect () {
    this.element.removeEventListener('mouseenter', this.boundUpdatePosition)
    this.element.removeEventListener('focusin', this.boundUpdatePosition)
    this.scrollParent?.removeEventListener('scroll', this.boundUpdatePosition)
    window.removeEventListener('resize', this.boundUpdatePosition)

    if (this.boundPointerDown) {
      this.triggerTarget.removeEventListener('pointerdown', this.boundPointerDown)
      this.triggerTarget.removeEventListener('click', this.boundClick)
    }
  }

  // Pin the panel's top to the trigger's top and its left to the
  // trigger's right edge — zero gap to traverse.
  updatePosition () {
    const rect = this.triggerTarget.getBoundingClientRect()
    this.panelTarget.style.top = `${rect.top}px`
    this.panelTarget.style.left = `${rect.right}px`
  }

  // Captured once at connect; hybrid devices that switch input modes
  // mid-session keep their initial mode. Acceptable trade-off — the
  // alternative is a media-query listener that re-binds handlers on
  // each change, which adds churn for a rare scenario.
  get coarsePointer () {
    return window.matchMedia('(pointer: coarse)').matches
  }

  // Capture whether the flyout was already open BEFORE this tap so we
  // can tell a first-tap (open) apart from a re-tap (navigate).
  onPointerDown () {
    this.openBeforeTap = this.element.matches(':focus-within')
  }

  // First tap on a coarse pointer: intercept navigation so the user
  // sees the children. Focus has already moved to the trigger, so
  // :focus-within keeps the panel open.
  onClick (event) {
    if (!this.openBeforeTap) event.preventDefault()
  }

  triggerKeydown (event) {
    if (event.key === 'ArrowRight' || event.key === 'Enter') {
      const first = this.panelLinks[0]
      if (!first) return
      event.preventDefault()
      first.focus()
    } else if (event.key === 'Escape') {
      this.close()
    }
  }

  panelKeydown (event) {
    switch (event.key) {
      case 'Escape':
        event.preventDefault()
        this.close()
        break
      case 'ArrowDown':
        event.preventDefault()
        this.moveFocus(event.target, 1)
        break
      case 'ArrowUp':
        event.preventDefault()
        this.moveFocus(event.target, -1)
        break
      case 'ArrowLeft':
        event.preventDefault()
        this.triggerTarget.focus()
        break
    }
  }

  // Explicit close. DaisyUI's dropdown-hover keeps the panel open while
  // the cursor sits on the trigger OR while focus is inside it; a CSS
  // `is-suppressed` class wins against both. Cleared on the next
  // mouseleave or focusout so future hovers/focus reopen normally.
  close () {
    this.element.classList.add('is-suppressed')
    this.triggerTarget.focus()
    const clear = () => {
      this.element.classList.remove('is-suppressed')
      this.element.removeEventListener('mouseleave', clear)
      this.element.removeEventListener('focusout', clear)
    }
    this.element.addEventListener('mouseleave', clear, { once: true })
    this.element.addEventListener('focusout', clear, { once: true })
  }

  get panelLinks () {
    return Array.from(this.panelTarget.querySelectorAll('a'))
  }

  moveFocus (current, direction) {
    const links = this.panelLinks
    const idx = links.indexOf(current)
    if (idx === -1) return
    const next = links[(idx + direction + links.length) % links.length]
    next.focus()
  }
}
