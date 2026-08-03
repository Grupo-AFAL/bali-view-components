import { Controller } from '@hotwired/stimulus'

const OPEN_CLASS = 'is-active'
const COLLAPSED_CLASS = 'is-collapsed'
const COLLAPSE_STORAGE_KEY = 'bali_sideMenuCollapsed'
const OVERLAY_QUERY = '(max-width: 1023.98px)'

// The module switcher is a native `<details>` — see the note in component.html.erb for
// why, which is iOS Safari and not preference. It comes with its own toggling and with
// nothing else: `<details>` closes when its `<summary>` is pressed again and on no other
// event, so the panel stayed open over the rest of the page.
const SWITCHER = '.menu-switcher > details'

const FOCUSABLE = [
  'a[href]',
  'button:not([disabled])',
  'input:not([disabled])',
  'select:not([disabled])',
  'textarea:not([disabled])',
  'summary',
  '[tabindex]:not([tabindex="-1"])'
].join(',')

/**
 * Opening and collapsing used to be hidden checkboxes toggled by `<label>`
 * elements — unreachable by keyboard. Both states are now classes this
 * controller owns:
 *
 *   is-active     mobile drawer is open   (paired with the scrim)
 *   is-collapsed  desktop icon-only rail  (persisted in localStorage)
 *
 * Triggers live outside the sidebar (topbar, navbar, layout chrome), so they
 * talk to it over window events rather than a DOM relationship:
 *
 *   in   bali:side-menu:toggle | :open | :close   detail { menuId, trigger }
 *   out  bali:side-menu:state                     detail { menuId, open }
 *
 * A `menuId` that is absent or matching addresses this menu, which keeps the
 * detail-less `bali:side-menu:toggle` that NavbarController still dispatches
 * working.
 */
export class SideMenuController extends Controller {
  static values = {
    collapsible: Boolean,
    fixed: Boolean
  }

  connect () {
    this.lastTrigger = null
    this.overlayQuery = window.matchMedia(OVERLAY_QUERY)
    this.restoreCollapseState()

    this.onGlobalToggle = event => this.forThisMenu(event) && this.toggle(event)
    this.onGlobalOpen = event => this.forThisMenu(event) && this.open(event)
    this.onGlobalClose = event => this.forThisMenu(event) && this.close()
    this.onDocumentKeydown = event => this.handleKeydown(event)
    this.onDocumentPointerdown = event => this.closeSwitcherOnOutsideClick(event)
    // Crossing the breakpoint turns a drawer into permanent chrome and back,
    // which flips whether the panel should be reachable at all.
    this.onOverlayChange = () => this.syncInert()

    window.addEventListener('bali:side-menu:toggle', this.onGlobalToggle)
    window.addEventListener('bali:side-menu:open', this.onGlobalOpen)
    window.addEventListener('bali:side-menu:close', this.onGlobalClose)
    document.addEventListener('keydown', this.onDocumentKeydown)
    document.addEventListener('pointerdown', this.onDocumentPointerdown)
    this.overlayQuery.addEventListener('change', this.onOverlayChange)

    this.syncInert()
  }

  disconnect () {
    window.removeEventListener('bali:side-menu:toggle', this.onGlobalToggle)
    window.removeEventListener('bali:side-menu:open', this.onGlobalOpen)
    window.removeEventListener('bali:side-menu:close', this.onGlobalClose)
    document.removeEventListener('keydown', this.onDocumentKeydown)
    document.removeEventListener('pointerdown', this.onDocumentPointerdown)
    this.overlayQuery.removeEventListener('change', this.onOverlayChange)
  }

  // ── Module switcher ────────────────────────────────────────────────────

  get switcher () {
    return this.element.querySelector(SWITCHER)
  }

  // `pointerdown` and not `click`: a press that starts inside the open panel and drifts
  // a pixel out before release retargets the click to whatever is underneath, and a
  // click-bound handler would read that as "outside" and close the panel out from under
  // the item the reader was pressing. The press is where the intent is.
  //
  // Pressing the summary itself is left alone in both directions, and it does not need a
  // special case: while it is open the press is inside the `<details>`, and while it is
  // closed there is nothing to close. The native toggle then runs as the click's default
  // action, after this listener.
  closeSwitcherOnOutsideClick (event) {
    const switcher = this.switcher

    if (!switcher?.open) return
    if (switcher.contains(event.target)) return

    switcher.open = false
  }

  // Escape closes the innermost thing that is open — the switcher before the drawer it
  // sits in — which is the precedence every other popup in the package already follows.
  // Focus goes back to the summary rather than being dropped on <body>.
  closeSwitcherOnEscape () {
    const switcher = this.switcher

    if (!switcher?.open) return false

    switcher.open = false
    switcher.querySelector('summary')?.focus()

    return true
  }

  // ── Mobile drawer ──────────────────────────────────────────────────────

  toggle (event) {
    this.isOpen ? this.close() : this.open(event)
  }

  open (event) {
    if (this.isOpen) return

    this.lastTrigger = event?.detail?.trigger || null
    this.element.classList.add(OPEN_CLASS)
    this.syncInert()
    this.broadcastState()
    this.focusFirstItem()
  }

  close () {
    if (!this.isOpen) return

    this.element.classList.remove(OPEN_CLASS)
    this.broadcastState()

    // Focus goes back where it came from, not to the top of the document.
    // Ordered before `syncInert`: moving focus out of a subtree that is about
    // to become inert is the browser's job to undo otherwise, and it drops it
    // on <body> instead of on the trigger.
    if (this.lastTrigger?.isConnected) this.lastTrigger.focus()
    this.lastTrigger = null

    this.syncInert()
  }

  // What actually takes the closed drawer out of the tab order. The panel is
  // only translated off-screen, so without this every link in it stayed
  // focusable and Tab from the hamburger walked into a menu nobody could see.
  //
  // `inert` and not `visibility: hidden`: hiding it in CSS ties focusability to
  // the animation clock, because the rule that reveals it is a transition. The
  // panel is then still un-focusable in the task that opened it — measured, and
  // it is why the drawer opened with focus parked on the trigger. `inert` is a
  // DOM attribute: it applies the moment it is removed.
  //
  // The server renders it on every fixed sidebar, so the pre-connect drawer is
  // already out of the way; the first `syncInert()` clears it on desktop.
  syncInert () {
    if (!this.fixedValue) return

    this.element.toggleAttribute('inert', this.isOverlay && !this.isOpen)
  }

  get isOpen () {
    return this.element.classList.contains(OPEN_CLASS)
  }

  // True while the sidebar behaves like a modal drawer: pinned to the viewport
  // and narrow enough that it covers the page instead of sitting beside it.
  get isOverlay () {
    return this.fixedValue && this.overlayQuery.matches
  }

  handleKeydown (event) {
    // Ahead of the drawer guard on purpose: el switcher está en el sidebar fijo del
    // desktop tanto como en el drawer, así que su Escape no puede depender de que haya un
    // drawer abierto.
    if (event.key === 'Escape' && this.element.contains(event.target)) {
      if (this.closeSwitcherOnEscape()) {
        event.preventDefault()
        return
      }
    }

    if (!this.isOpen || !this.isOverlay) return

    if (event.key === 'Escape') {
      event.preventDefault()
      this.close()
      return
    }

    if (event.key === 'Tab') this.keepFocusInside(event)
  }

  // The drawer covers the page, so Tab must not walk into the content behind
  // the scrim — there is no way back to the menu and no visible focus ring.
  keepFocusInside (event) {
    const items = this.focusableItems()
    if (items.length === 0) return

    const first = items[0]
    const last = items[items.length - 1]
    const active = document.activeElement

    if (!this.element.contains(active)) {
      event.preventDefault()
      ;(event.shiftKey ? last : first).focus()
    } else if (event.shiftKey && active === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && active === last) {
      event.preventDefault()
      first.focus()
    }
  }

  focusableItems () {
    return Array.from(this.element.querySelectorAll(FOCUSABLE)).filter(
      el => el.offsetParent !== null || el.getClientRects().length > 0
    )
  }

  // Runs in the same task as `open`, which is only safe because `syncInert`
  // already cleared the attribute — see the note there.
  focusFirstItem () {
    if (!this.isOverlay) return

    this.focusableItems()[0]?.focus()
  }

  broadcastState () {
    window.dispatchEvent(
      new CustomEvent('bali:side-menu:state', {
        detail: { menuId: this.element.id, open: this.isOpen }
      })
    )
  }

  forThisMenu (event) {
    const menuId = event?.detail?.menuId
    return !menuId || menuId === this.element.id
  }

  // ── Desktop collapse ───────────────────────────────────────────────────

  toggleCollapse () {
    if (!this.collapsibleValue) return

    const collapsed = this.element.classList.toggle(COLLAPSED_CLASS)
    this.storeCollapseState(collapsed)
  }

  restoreCollapseState () {
    if (!this.collapsibleValue) return

    this.element.classList.toggle(
      COLLAPSED_CLASS,
      this.readCollapseState() === 'true'
    )
  }

  readCollapseState () {
    try {
      return localStorage.getItem(COLLAPSE_STORAGE_KEY)
    } catch {
      return null
    }
  }

  storeCollapseState (collapsed) {
    try {
      localStorage.setItem(COLLAPSE_STORAGE_KEY, collapsed)
    } catch {
      // Private browsing / storage disabled — collapsing still works, it just
      // does not survive a reload.
    }
  }
}
