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

// The scrolling half of the sidebar, and the one link inside it that points at the page
// you are on. Both are emitted by this component (`component.html.erb` and
// `item/component.rb#aria_current`), which is the whole reason the reveal belongs here:
// a host patching it from outside is reaching into markup the gem owns and can rename.
const MENU_SCROLLER = '.sidebar-menu'
const CURRENT_ITEM = '[aria-current="page"]'

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
    fixed: Boolean,
    revealCurrent: { type: Boolean, default: true }
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
    // Last on purpose: it measures, and everything above it moves things. See the note
    // on the method.
    this.revealCurrentItem()
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
    // `connect` skipped it while this was a closed drawer — see `revealCurrentItem`. This
    // is the first moment the panel is on screen, and it goes after `focusFirstItem`
    // because focusing a link scrolls it into view and would undo the reveal.
    this.revealCurrentItem()
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

  // ── Reveal the current item ────────────────────────────────────────────

  // Every navigation re-renders the sidebar and its scroll goes back to the top, so in a
  // menu taller than the screen the active item lands out of view: you arrive at a page
  // and the menu does not show you where you are.
  //
  // This lives in the component and not in the host because all three things it needs are
  // the component's: `.sidebar-menu` as the scroller, `aria-current="page"` on exactly one
  // link (whose rule — a parent highlights while a child route is open, but only the link
  // for the page you are ON is `current`) is decided in `item/component.rb`, and this very
  // root element. A host patching it from outside also cannot know WHEN to measure:
  // `restoreCollapseState()` reads localStorage and toggles `is-collapsed`, which changes
  // the width of the rail and with it every position — an external controller can only
  // guess at that with `requestAnimationFrame`. In here it is simply the next line.
  revealCurrentItem () {
    if (!this.revealCurrentValue) return
    // A closed drawer is `inert` and translated off screen. Measuring it gives the
    // positions of a panel nobody is looking at, and the scroll would be spent before it
    // is ever seen; `open()` asks again once it is on screen.
    if (this.isOverlay && !this.isOpen) return

    const menu = this.element.querySelector(MENU_SCROLLER)
    const current = menu && this.visibleCurrentItem(menu)
    if (!current) return

    const menuRect = menu.getBoundingClientRect()
    const itemRect = current.getBoundingClientRect()
    const above = itemRect.top - menuRect.top
    const below = itemRect.bottom - menuRect.bottom
    if (above >= 0 && below <= 0) return

    // Moving `scrollTop` by hand rather than `scrollIntoView({ block: 'nearest' })`:
    // `scrollIntoView` also scrolls whatever ancestors it needs to, up to the document,
    // so an INLINE sidebar (`fixed: false`) that sits below the fold would jump the whole
    // page on load. This can only ever move this one container.
    menu.scrollTop += above < 0 ? above : below
  }

  // A simple item renders TWICE — `.side-menu-expanded` and the collapsed icon-only
  // version — and both carry `aria-current="page"`, because both are the link for this
  // page and only CSS decides which one the rail is showing. So a bare `querySelector`
  // has a 50% chance of measuring a `display: none` node whose every rect reads 0. Same
  // check covers a link inside a collapsed group, which has no box either.
  visibleCurrentItem (menu) {
    return Array.from(menu.querySelectorAll(CURRENT_ITEM)).find(
      el => el.getClientRects().length > 0
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
