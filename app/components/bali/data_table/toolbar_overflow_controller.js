import { Controller } from '@hotwired/stimulus'

// Where focus can land when the control that held it changes place. The non-negative
// `[tabindex]` covers the dropdown trigger, which is a div with `role="button"`.
const FOCUSABLE = 'a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])'

/**
 * Toolbar Overflow Controller
 *
 * Moves the DataTable toolbar's secondary controls into a "⋯" menu when the row stops
 * fitting, and brings them back when there is room again. It MOVES, it does not duplicate: two
 * copies of the column selector would be two controllers driving the same table, and two copies
 * of the saved views would duplicate the ids of their rename forms — the bug in #669.
 *
 * All the state lives in the DOM (targets + data attributes). The controller disconnects and
 * reconnects on every Turbo navigation, every cache restore and every turbo-stream that
 * replaces the container; an in-memory map of "where each control used to live" would be lost
 * on the reconnect and would leave them trapped inside the ⋯.
 *
 * WHAT can collapse is declared by the priority (`threshold`, see OVERFLOW_PRIORITIES in the
 * component); HOW MUCH collapses is decided by MEASURING the row. The breakpoint is only still
 * the mobile floor: the width the toolbar has is not set by the viewport but by the host's
 * layout —a sidebar eats 300px of it— and with the cut fixed at `sm` the row got squeezed
 * without collapsing anything, leaving the search painted on top of grouping and columns.
 *
 *   <div data-controller="toolbar-overflow">
 *     <div data-toolbar-overflow-target="group" data-toolbar-overflow-group="left">
 *       <div data-toolbar-overflow-target="item"
 *            data-toolbar-overflow-group="left"
 *            data-toolbar-overflow-priority="70">…</div>
 *     </div>
 *     <div data-toolbar-overflow-target="separator"
 *          data-toolbar-overflow-separates="left memory">…</div>
 *     <div data-toolbar-overflow-target="group" data-toolbar-overflow-group="memory">…</div>
 *     <div data-toolbar-overflow-target="overflow">
 *       …<div data-toolbar-overflow-target="menu"></div>
 *     </div>
 *   </div>
 */
export default class extends Controller {
  static targets = ['group', 'item', 'menu', 'overflow', 'separator']

  static values = {
    breakpoint: { type: Number, default: 640 }, // Tailwind `sm`
    threshold: { type: Number, default: 50 }
  }

  connect () {
    this.mediaQuery = window.matchMedia(`(max-width: ${this.breakpointValue - 1}px)`)
    this.mediaQuery.addEventListener('change', this.handleBreakpointChange)
    document.addEventListener('turbo:before-cache', this.handleBeforeCache)

    // The ITEMS are observed as well as the row. The row's box is set by its parent and does
    // not change when its content grows: measured, putting a 300px child inside it produces
    // ZERO callbacks. What grows is the control — SlimSelect replaces its `<select>` with a
    // wider widget, flatpickr mounts its own, a font finishes loading— and that does change the
    // box of the item containing it. Without this the ⋯ valve was only evaluated on mount, when
    // none of those widgets exists yet.
    this.observer = new window.ResizeObserver(this.handleResize)
    this.observer.observe(this.element)
    this.itemTargets.forEach(item => this.observer.observe(item))

    // The initial layout can already arrive narrow: listening for the crossing is not enough.
    this.apply(this.mediaQuery.matches)
    this.recordMeasurements()
    this.reveal()
  }

  /**
   * The collapsible controls arrive with their space reserved and unpainted, and this
   * uncovers them once the row is already in its final shape. See RESERVED_CLASSES in the
   * component.
   *
   * It goes here and not behind a "it has settled" heuristic because the cause of the flicker
   * is not that the row grows: it is that the server sends the row UNcollapsed and nobody can
   * collapse it until this controller exists. Measured on /admin/studios, the page paints at
   * 260ms and `connect()` does not run until 1189ms, when the bundle finishes executing. By
   * the end of the `apply()` above the row is already the final one, so there is nothing to
   * wait for.
   *
   * A later `apply()` —the one a widget that widens on mount fires— happens with the controls
   * already visible, which is the correct thing: by then moving one into the ⋯ is a response
   * to something that changed, not a wrong initial state.
   */
  reveal () {
    this.element.removeAttribute('data-toolbar-overflow-settling')
  }

  disconnect () {
    this.mediaQuery.removeEventListener('change', this.handleBreakpointChange)
    document.removeEventListener('turbo:before-cache', this.handleBeforeCache)
    this.observer?.disconnect()
    if (this.frame) window.cancelAnimationFrame(this.frame)
  }

  handleBreakpointChange = (event) => this.apply(event.matches)

  /**
   * Two measurements decide whether to recompute, not one: what the row HAS and what the row
   * NEEDS. With only the available width, a control that widens AFTER the first layout
   * —SlimSelect replacing its `<select>`, flatpickr mounting its input, a font that finishes
   * loading— fires nothing, and the row overflows without the ⋯ finding out. Measured on
   * `/studios` at 2008px: `max-content` asked for 2078 and the menu had 0 items, with the
   * filter row wrapped onto three lines.
   *
   * Both are read inside the rAF, not in the observer callback: `requiredWidth()` writes
   * `style.width` to measure, and doing that inside the callback is asking the observer to
   * re-enter because of the change we just caused — the loop Chrome reports as
   * "ResizeObserver loop". For the same reason the comparison is stored AFTER applying:
   * collapsing lowers the `max-content`, so recording the previous value guaranteed a second
   * pass.
   */
  handleResize = () => {
    if (this.frame) return

    this.frame = window.requestAnimationFrame(() => {
      this.frame = null
      if (this.measurementsUnchanged()) return

      this.apply(this.mediaQuery.matches)
      this.recordMeasurements()
    })
  }

  measurementsUnchanged () {
    return Math.round(this.availableWidth()) === this.lastWidth &&
      Math.round(this.requiredWidth()) === this.lastRequired
  }

  recordMeasurements () {
    this.lastWidth = Math.round(this.availableWidth())
    this.lastRequired = Math.round(this.requiredWidth())
  }

  // The snapshot Turbo caches has to ALWAYS be the expanded layout. Cached collapsed, going
  // back in a wide viewport restores the folded toolbar until connect() repairs it: a flicker
  // with an empty toolbar.
  handleBeforeCache = () => {
    this.closeOpenDropdowns()
    this.expand()
    this.sync()
  }

  apply (narrow) {
    const focused = this.focusedControl()

    this.closeOpenDropdowns()
    // Always start from the whole row: collapsing is incremental and without expanding first,
    // widening would never give anything back.
    this.expand()
    this.sync()

    if (narrow) {
      this.collapseAll()
    } else {
      this.collapseUntilItFits()
    }

    this.sync()
    this.restoreFocus(focused)
  }

  sync () {
    this.syncGroupVisibility()
    this.syncSeparators()
    this.syncOverflowVisibility()
  }

  // Below the breakpoint nothing is measured: nothing fits on a phone and the result has to be
  // the same every time, not depend on how much a translated label takes up.
  collapseAll () {
    if (!this.hasMenuTarget) return

    this.collapsibleItems()
      .filter(item => !this.menuTarget.contains(item))
      .forEach(item => this.menuTarget.appendChild(item))
  }

  /**
   * Items are sacrificed from lowest to highest priority and only until the row fits: the ⋯
   * stops being a mobile mode and becomes the valve for any width. Each move re-syncs before
   * measuring again because the ⋯ itself takes up room and a group left empty hides, giving
   * back its `gap`.
   */
  collapseUntilItFits () {
    if (!this.hasMenuTarget) return

    for (const item of this.collapsibleItems().reverse()) {
      if (!this.overflowing()) return

      this.menuTarget.appendChild(item)
      this.sync()
    }
  }

  /**
   * What the row NEEDS against what it HAS. `scrollWidth` is no use as a signal: what does
   * not fit lives inside the single elastic item, which shrinks to 0 and leaves its content
   * painted over its neighbours WITHOUT producing scroll — measured `scrollWidth === clientWidth`
   * with three overlapping controls. With `max-content` each item contributes its natural
   * width, which is the real question.
   */
  overflowing () {
    const available = this.availableWidth()
    if (available === 0) return false

    return this.requiredWidth() > available + 0.5
  }

  availableWidth () {
    return this.element.getBoundingClientRect().width
  }

  requiredWidth () {
    const inline = this.element.style.width
    this.element.style.width = 'max-content'
    const required = this.element.getBoundingClientRect().width
    this.element.style.width = inline

    return required
  }

  expand () {
    if (this.hasMenuTarget) {
      this.itemTargets
        .filter(item => this.menuTarget.contains(item))
        .forEach(item => this.homeGroupFor(item)?.appendChild(item))
    }

    // Reordering by priority is what makes remembering the original position unnecessary.
    this.groupTargets.forEach(group => this.sortByPriority(group))
  }

  // Sorted from highest to lowest so that inside the ⋯ the reading order is the same as the
  // toolbar's. It holds because the priorities descend following the row (see
  // OVERFLOW_PRIORITIES); renumbering them without looking at the layout breaks this
  // correspondence without anything failing.
  collapsibleItems () {
    return this.itemTargets
      .filter(item => this.priorityOf(item) < this.thresholdValue)
      .sort((a, b) => this.priorityOf(b) - this.priorityOf(a))
  }

  sortByPriority (group) {
    Array.from(group.children)
      .sort((a, b) => this.priorityOf(b) - this.priorityOf(a))
      .forEach(item => group.appendChild(item))
  }

  homeGroupFor (item) {
    return this.groupTargets.find(
      group => group.dataset.toolbarOverflowGroup === item.dataset.toolbarOverflowGroup
    )
  }

  priorityOf (element) {
    return parseInt(element.dataset.toolbarOverflowPriority, 10) || 0
  }

  /**
   * Close before moving. The columns, export and saved views dropdowns open through daisyUI's
   * :focus-within: moving the node takes it out of the document and focus jumps to the body in
   * the middle of the move. The ones using the DropdownController keep their state in the
   * `dropdown-open` class, which SURVIVES the move — they would stay open inside the ⋯.
   */
  closeOpenDropdowns () {
    const active = document.activeElement
    if (active && this.itemTargets.some(item => item.contains(active))) active.blur()

    this.element.querySelectorAll('.dropdown-open').forEach(dropdown => {
      const controller = this.application.getControllerForElementAndIdentifier(dropdown, 'dropdown')
      if (controller) {
        controller.close()
      } else {
        dropdown.classList.remove('dropdown-open')
      }
    })
  }

  /**
   * Crossing the breakpoint (a 400% zoom, rotating the phone) cannot cost the keyboard user
   * their position: `closeOpenDropdowns` blurs and `collapse`/`expand` move the focused node,
   * so without this focus falls to the <body> with no ring and no announcement.
   *
   * The ⋯ counts as a control and is NOT an `item`: narrow, it is the only way to reach what
   * is collapsed, and on widening it hides. Without counting it here, crossing upwards
   * —coming back from the 400% zoom— dropped focus onto the <body>, which is exactly the loss
   * this method exists to prevent, only in the other direction.
   */
  focusedControl () {
    const active = document.activeElement
    if (!active) return null
    if (this.itemTargets.some(item => item.contains(active))) return active
    if (this.hasOverflowTarget && this.overflowTarget.contains(active)) return this.overflowTarget

    return null
  }

  restoreFocus (element) {
    if (!element || !element.isConnected) return

    // Focus was on the ⋯. If it is still on screen it goes back to its trigger; if it hid
    // because there is nothing left to collapse, the equivalent destination is the
    // highest-priority control that has just come back to the row — the first thing the menu
    // offered.
    if (element === this.overflowTarget) {
      const home = this.isRendered(element) ? this.overflowTrigger() : this.collapsibleItems()[0]
      this.focusableWithin(home)?.focus({ preventScroll: true })
      return
    }

    // It stayed inside the closed (not rendered) ⋯: the equivalent destination is its trigger,
    // which is how the user reaches that control now.
    if (!this.isRendered(element)) {
      this.overflowTrigger()?.focus({ preventScroll: true })
      return
    }

    element.focus({ preventScroll: true })
  }

  isRendered (element) {
    return element.offsetParent !== null
  }

  // The `item`s are WRAPPERS, not controls: focusing them does nothing. Focus goes to the
  // first focusable element they have inside.
  focusableWithin (element) {
    if (!element) return null

    return element.matches(FOCUSABLE) ? element : element.querySelector(FOCUSABLE)
  }

  overflowTrigger () {
    if (!this.hasOverflowTarget) return null

    return this.overflowTarget.querySelector('[data-dropdown-target="trigger"]')
  }

  /**
   * An empty group is still a flex item: it takes the row's `gap` on both sides and eats
   * width from the search exactly in the viewport where there is least to spare.
   */
  syncGroupVisibility () {
    this.groupTargets.forEach(group => {
      group.classList.toggle('hidden', group.children.length === 0)
    })
  }

  /**
   * The little bar is an ASSERTION about its neighbours ("here ends what the view contains
   * and begins how it is remembered"). When the overflow takes one of the two sides away the
   * assertion stops being true and it is left marking a border against nothing. It is NOT a
   * control: it is not an `item`, so `collapsibleItems` cannot move it into the ⋯ — it only
   * hides and comes back.
   */
  syncSeparators () {
    this.separatorTargets.forEach(separator => {
      separator.classList.toggle('hidden', !this.separatorFlanked(separator))
    })
  }

  // The groups are looked up BY NAME and not by adjacency in the DOM: inserting any node
  // between the little bar and a group used to break the decision silently.
  separatorFlanked (separator) {
    return (separator.dataset.toolbarOverflowSeparates || '')
      .split(' ')
      .filter(name => name)
      .every(name => this.groupNamed(name)?.children.length > 0)
  }

  groupNamed (name) {
    return this.groupTargets.find(group => group.dataset.toolbarOverflowGroup === name)
  }

  // With nothing inside, the ⋯ would open an empty menu. It is the ONLY visibility rule for
  // the menu since collapsing became a measurement: the markup no longer hides it by
  // breakpoint.
  syncOverflowVisibility () {
    if (!this.hasOverflowTarget || !this.hasMenuTarget) return

    this.overflowTarget.classList.toggle('hidden', this.menuTarget.children.length === 0)
  }
}
