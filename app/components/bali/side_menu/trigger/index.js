import { Controller } from '@hotwired/stimulus'

/**
 * A sidebar trigger is never a sibling of the sidebar it opens — it lives in
 * the topbar, the navbar or the layout chrome. It talks to it over the window
 * events SideMenuController listens for, and mirrors back the state event so
 * `aria-expanded` says what the sidebar is actually doing.
 *
 * The scrim uses the same controller with only the `close` action, so there is
 * one place that knows the event names.
 */
export class SideMenuTriggerController extends Controller {
  static values = {
    menuId: String
  }

  connect () {
    this.onState = event => {
      if (event.detail?.menuId !== this.menuIdValue) return
      if (!this.element.hasAttribute('aria-expanded')) return

      this.element.setAttribute('aria-expanded', String(event.detail.open))
    }

    window.addEventListener('bali:side-menu:state', this.onState)
  }

  disconnect () {
    window.removeEventListener('bali:side-menu:state', this.onState)
  }

  toggle (event) {
    event.preventDefault()
    this.dispatchToMenu('toggle')
  }

  open (event) {
    event.preventDefault()
    this.dispatchToMenu('open')
  }

  close (event) {
    event.preventDefault()
    this.dispatchToMenu('close')
  }

  // `trigger` travels with the event so the sidebar can hand focus back to
  // this exact button when it closes.
  dispatchToMenu (action) {
    window.dispatchEvent(
      new CustomEvent(`bali:side-menu:${action}`, {
        detail: { menuId: this.menuIdValue, trigger: this.element }
      })
    )
  }
}
