import { Controller } from '@hotwired/stimulus'
import zIndexFor from '../../../assets/javascripts/bali/utils/z-index.js'
import { topLayerHost } from '../../../assets/javascripts/bali/utils/top-layer.js'
import { optionalPeer } from '../../../assets/javascripts/bali/utils/optional-peer.js'

// tippy's own `preventOverflow` padding, so both modes stop the same distance from the edge.
const VIEWPORT_PADDING = 5

export class DropdownController extends Controller {
  static targets = ['trigger', 'menu']
  static values = {
    closeOnClick: { type: Boolean, default: true },
    // Portal the menu out of any ancestor whose `overflow` would clip it. The menu is
    // MOVED into the popper, not copied: the element the server rendered is the element
    // the reader operates, so ids, Stimulus targets, `data-turbo-confirm` and every
    // listener already on it survive the trip. `this.menu` is captured at connect, before
    // the move, because a Stimulus target lookup is scoped to the controller element and
    // stops finding it the moment tippy moves the menu into its popper.
    popover: { type: Boolean, default: false },
    placement: { type: String, default: 'bottom-start' }
  }

  connect () {
    this.menu = this.hasMenuTarget ? this.menuTarget : null

    if (this.closeOnClickValue) {
      document.addEventListener('click', this.handleOutsideClick)
    }
    this.listenOn(this.element)
    if (this.popoverValue) {
      this.setupPopover()
    } else if (this.opensOnClick) {
      this.close()
      this.element.addEventListener('mousedown', this.holdTriggerFocus)
      this.element.addEventListener('click', this.handleTriggerClick, true)
    }
  }

  disconnect () {
    if (this.closeOnClickValue) {
      document.removeEventListener('click', this.handleOutsideClick)
    }
    this.stopListeningOn(this.element)
    if (this.menu) this.stopListeningOn(this.menu)
    this.element.removeEventListener('mousedown', this.holdTriggerFocus)
    this.element.removeEventListener('click', this.handleTriggerClick, true)

    // destroy() leaves the menu inside the popper it is about to throw away, so put it
    // back where the server rendered it. Without this, a Turbo Frame re-render that
    // disconnects and reconnects the controller comes back with no panel at all.
    if (this.tippy) {
      const menu = this.menu
      this.tippy.destroy()
      if (menu && !this.element.contains(menu)) {
        menu.classList.add('dropdown-content')
        this.element.appendChild(menu)
      }
      this.tippy = null
    }
  }

  async setupPopover () {
    if (!this.menu || !this.hasTriggerTarget) return

    const tippyModule = await import('tippy.js').catch(optionalPeer('tippy.js'))
    if (!tippyModule) return
    const { default: tippy } = tippyModule

    // The menu leaves `this.element` from here on, so the handlers bound on the wrapper
    // never see its events. Bound on the menu as well, they do.
    this.listenOn(this.menu)

    // `.dropdown-content` is what kept the panel closed until this line — see
    // Component#content_classes. Inside the popper it would position the panel against
    // the wrong box and hide it outright, since daisyUI's open rules are all descendants
    // of `.dropdown`, which the panel has just stopped being.
    this.menu.classList.remove('dropdown-content')

    // `manual` and `hideOnClick: false` on purpose: tippy is a positioner here, not the
    // thing that decides when the menu is open. Its own `click` trigger has toggle rules of
    // its own that disagree with the controller's — measured, a second click on the trigger
    // left the popper up — and every path in and out of the open state (Enter, Space, the
    // arrows, Escape, a click outside) already runs through `open()` / `close()`, which is
    // also what keeps the two modes behaving alike.
    this.tippy = tippy(this.triggerTarget, {
      content: this.menu,
      // Inside a Modal or Drawer, everything outside the `<dialog>` is inert: hung off
      // `<body>` there, the menu opened under the panel with 0 of its 3 items reachable
      // (#1269). Asked on every show, not once at connect: a dropdown in a panel rendered
      // closed connects before its dialog is modal.
      appendTo: (reference) => topLayerHost(reference) ?? document.body,
      trigger: 'manual',
      hideOnClick: false,
      interactive: true,
      arrow: false,
      offset: [0, 4],
      placement: this.placementValue,
      zIndex: zIndexFor('dropdown'),
      // tippy's box defaults to `role="tooltip"`, and a menu inside a tooltip is not a
      // thing: read back from Chromium's accessibility tree, the panel came out as
      // `tooltip > menu "Dropdown menu"`. The box is chrome; the roles belong to the list
      // the server rendered. It needs no other aria told to it — tippy leaves
      // `aria-expanded` alone because the trigger already carries one, and skips
      // `aria-describedby` because an interactive popper is not a description.
      role: 'presentation',
      // The popper box stays unstyled: the panel carries its own background, radius,
      // shadow and padding in both modes, so there is one look to maintain, not two.
      onShow: this.onPopoverShow,
      onHide: this.onPopoverHide
    })

    this.element.addEventListener('mousedown', this.holdTriggerFocus)
    this.element.addEventListener('click', this.handleTriggerClick, true)
  }

  // daisyUI's CSS dropdown opens from `:focus-within`, so Tab alone unfolded the menu and the
  // Enter meant to open it closed it (#1231). A click dropdown rests in daisyUI's own
  // `dropdown-close`, which outranks `:focus-within`, and only `open()` takes it out. The
  // hover one keeps focus as its keyboard way in; popover mode never opened on focus.
  //
  // Hover is read off `dropdown-hover` (Component#dropdown_classes) and not off a value: it
  // is the class daisyUI's hover rules read, so the controller and the CSS cannot disagree.
  get opensOnClick () {
    return !this.popoverValue && !this.element.classList.contains('dropdown-hover')
  }

  // Bound on the wrapper rather than on the trigger, because a press and a release do not
  // always land on the same element: the wrapper is the only other thing under the pointer
  // and it is an ancestor, so a click that starts on the trigger and ends a pixel outside
  // it still arrives. Measured in Cypress, where focusing on `mousedown` scrolls the page
  // enough that `mouseup` and `click` retarget from the trigger to the wrapper and a
  // trigger-bound listener never fires at all. In the CSS mode the menu is inside the
  // wrapper, so its clicks — a nested dropdown's included — are let through.
  //
  // Bound in the capture phase so the menu is open before any action on the trigger runs:
  // with `:focus-within` it already was, from the `mousedown`, and the rich text editor's
  // link panel focuses its input from a click action on its trigger.
  //
  // Clicking an open trigger lands here too, on the wrapper: daisyUI gives that trigger
  // `pointer-events: none`.
  handleTriggerClick = (event) => {
    if (this.menu?.contains(event.target)) return

    event.preventDefault()
    this.toggle()
  }

  // The wrapper takes no focus, so that press on an open trigger blurred it: `handleFocusOut`
  // closed the menu and the click that followed opened it again.
  holdTriggerFocus = (event) => {
    if (event.target === this.element) event.preventDefault()
  }

  listenOn (node) {
    node.addEventListener('keydown', this.handleKeydown)
    node.addEventListener('focusin', this.handleFocusIn)
    node.addEventListener('focusout', this.handleFocusOut)
  }

  stopListeningOn (node) {
    node.removeEventListener('keydown', this.handleKeydown)
    node.removeEventListener('focusin', this.handleFocusIn)
    node.removeEventListener('focusout', this.handleFocusOut)
  }

  onPopoverShow = () => {
    this.element.classList.add('dropdown-open')
    this.syncExpanded()
  }

  onPopoverHide = () => {
    this.element.classList.remove('dropdown-open')
    this.syncExpanded()
  }

  /**
   * In the hover dropdown focus is still an open signal — daisyUI unfolds it from
   * `:focus-within` — so `aria-expanded` is synced to it, or the screen reader announces
   * "collapsed" with the menu in plain sight (WCAG 4.1.2). A click dropdown only opens
   * through `open()`, and in popover mode `onPopoverShow`/`onPopoverHide` are in charge.
   */
  handleFocusIn = (event) => {
    if (this.popoverValue) return

    // Focus arriving from outside is the reader coming back. A hover menu loses its
    // explicit-close mark, or an outside click would leave it shut for the rest of the page's
    // life; a closed click menu gets it back, in case a Turbo morph rewrote `class` and
    // `:focus-within` is about to open it again. Focus arriving from INSIDE is Escape handing
    // the trigger its focus back, and that changes nothing.
    if (!this.owns(event.relatedTarget)) {
      this.element.classList.toggle('dropdown-close', this.opensOnClick && !this.isOpen)
    }
    this.syncExpanded()
  }

  handleFocusOut = (event) => {
    // Focus can jump BETWEEN children (from the trigger to an item): that is not closing.
    if (event.relatedTarget && this.owns(event.relatedTarget)) return

    if (this.tippy || this.opensOnClick) {
      this.close()
      return
    }

    // Focus has genuinely left a hover dropdown (or a popover one whose tippy never loaded,
    // which is the CSS dropdown). Drop both marks: `dropdown-close` so that coming back with
    // Tab opens it again, and the `dropdown-open` that Enter or an arrow may have set.
    this.element.classList.remove('dropdown-close', 'dropdown-open')
    this.syncExpanded()
  }

  // `aria-expanded` mirrors daisyUI's own open condition rather than being told what to
  // say, because in the CSS mode daisyUI is the one opening the menu and it does it from
  // four different selectors. Anything that sets the attribute by hand goes stale the first
  // time the menu opens down a path that did not run the setter — which is the WCAG 4.1.2
  // bug this component has already been fixed for twice.
  get isOpen () {
    // `dropdown-open` and not `tippy.state.isVisible`: tippy runs `onShow` BEFORE it flips
    // that flag, so reading it from inside the callback reports the state the menu is
    // leaving. Measured: the popper on screen with `aria-expanded="false"` beside it.
    //
    // A click dropdown is open when `dropdown-open` says so, and only then: a Turbo morph
    // that rewrites `class` takes `dropdown-close` away too, and reading its absence as
    // "open" made the first click after it close a menu nobody could see.
    if (this.tippy || this.opensOnClick) return this.element.classList.contains('dropdown-open')

    const el = this.element
    if (el.classList.contains('dropdown-close')) return false
    if (el.classList.contains('dropdown-open')) return true
    if (el.classList.contains('dropdown-hover') && el.matches(':hover')) return true

    return el.matches(':focus-within')
  }

  syncExpanded () {
    if (!this.hasTriggerTarget) return

    this.triggerTarget.setAttribute('aria-expanded', String(this.isOpen))
  }

  // Everything this dropdown is made of, whichever mode it is in. In popover mode the menu
  // hangs off `<body>`, or off the dialog around the dropdown, rather than off the wrapper,
  // so `this.element.contains` on its own answers "not mine" about this dropdown's own panel.
  owns (node) {
    if (!node) return false

    return this.element.contains(node) || Boolean(this.menu && this.menu.contains(node))
  }

  // Only a dropdown that is actually open gets closed: in a hover dropdown `close()` leaves
  // `dropdown-close` behind, which outranks `:hover`, so closing one nobody had opened would
  // stop the pointer from opening it.
  handleOutsideClick = (event) => {
    if (this.owns(event.target)) return
    if (!this.isOpen) return

    this.close()
  }

  handleKeydown = (event) => {
    // keydown BUBBLES and a dropdown can contain others (the ⋯ of the DataTable toolbar):
    // without this guard the same key was processed by both controllers, so a single arrow
    // skipped two items and an Escape inside the inner dropdown closed the whole container.
    if (this.fromNestedDropdown(event.target)) return

    const isOpen = this.isOpen

    switch (event.key) {
      case 'Escape':
        if (isOpen) {
          event.preventDefault()
          this.close()
          // `?.` cannot guard a Stimulus target: the getter throws rather than returning
          // undefined. This file already asks `hasTriggerTarget` at setupPopover and
          // syncExpanded — Escape has to ask too, or a dropdown rendered without a trigger
          // slot throws on Escape instead of just closing.
          if (this.hasTriggerTarget) this.triggerTarget.focus()
        }
        break
      case 'ArrowDown':
        // Inside a field the arrows belong to the field: they move the caret or selection.
        if (this.fromFormControl(event.target)) break
        event.preventDefault()
        // Unconditionally, even when the menu is already on screen: a hover menu that
        // `:hover` or `:focus-within` opened has no `dropdown-open` on the wrapper, and that
        // class is how the rest of the package tells an explicitly-opened dropdown from one
        // merely shown — `toolbar_overflow_controller` closes exactly those before folding a
        // control into the ⋯.
        this.open()
        this.focusNextItem()
        break
      case 'ArrowUp':
        if (this.fromFormControl(event.target)) break
        event.preventDefault()
        this.open()
        this.focusPreviousItem()
        break
      case 'Enter':
      case ' ':
        // Opens and steps in, like ArrowDown — the menu button of the WAI-ARIA APG. A toggle
        // here closed whatever `:focus-within` had opened under the very key meant to open it.
        if (this.triggerFocused) {
          event.preventDefault()
          this.open()
          this.focusNextItem()
        }
        break
      case 'Tab':
        // The popper hangs at the end of `<body>`: Tab from its last item left the document
        // and Shift+Tab from its first went to the end of the page. From the trigger, the
        // browser's own Tab carries on in the trigger's place.
        if (this.tippy && this.menu.contains(event.target)) {
          this.close()
          this.triggerTarget.focus()
        }
        break
    }
  }

  get triggerFocused () {
    return this.hasTriggerTarget && document.activeElement === this.triggerTarget
  }

  // Was the event born in a dropdown NESTED inside this one? Then it belongs to the inner
  // one. Hand-written markup with no `.dropdown` around it still works: `closest` returns
  // null.
  fromNestedDropdown (target) {
    const nearest = target?.closest?.('.dropdown')

    return Boolean(nearest) && nearest !== this.element && this.owns(nearest)
  }

  // A field that IS a menuitem is walked like any other item, by the same `[role^="menuitem"]`
  // as `getMenuItems`: the DataTable column selector's checkboxes
  // (`column_selector/component.html.erb`).
  fromFormControl (target) {
    return Boolean(target?.closest?.('input:not([role^="menuitem"]), textarea, select'))
  }

  toggle () {
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open () {
    if (this.tippy) {
      this.tippy.show()
      return
    }

    this.element.classList.remove('dropdown-close')
    this.element.classList.add('dropdown-open')
    this.keepInViewport()
    this.syncExpanded()
  }

  // daisyUI anchors the panel to one edge of the trigger and never looks at the screen: the
  // page ⋯, `align: :end`, wraps to the left of a 390px phone and opened at x = −104 (#1231).
  // Popover mode has Popper for that; this is the same nudge. Read from the centre and the
  // layout width because the opening `scale` (.95 around the top centre) is still running.
  //
  // Only for menus that open above or below: one opening sideways (`dropdown-left`/`-right`,
  // the classes daisyUI positions it by) would be pushed over its own trigger.
  keepInViewport () {
    if (!this.menu) return

    this.menu.style.transform = ''
    if (!this.menu.offsetWidth) return
    if (this.element.matches('.dropdown-left, .dropdown-right')) return

    const { left, right } = this.menu.getBoundingClientRect()
    const centre = (left + right) / 2
    const half = this.menu.offsetWidth / 2
    const spillLeft = VIEWPORT_PADDING - (centre - half)
    const spillRight = centre + half - (document.documentElement.clientWidth - VIEWPORT_PADDING)
    const shift = spillLeft > 0 ? spillLeft : -Math.max(spillRight, 0)

    if (shift) this.menu.style.transform = `translateX(${shift}px)`
  }

  // `dropdown-close` is daisyUI's own escape hatch and the only thing that makes Escape
  // stick: every one of its open rules is written `.dropdown:not(.dropdown-close)…`,
  // `:focus-within` included. Without it, closing and then handing focus back to the
  // trigger — which is what Escape is supposed to do — re-opened the menu on the same
  // frame, so Escape looked like it did nothing at all. Measured before the fix: after
  // Escape, `aria-expanded="true"` with the menu still on screen.
  //
  // The old `close()` blurred instead, which does close it, at the price of dropping the
  // reader's place on the page entirely.
  close () {
    if (this.tippy) {
      this.tippy.hide()
      return
    }

    this.element.classList.remove('dropdown-open')
    this.element.classList.add('dropdown-close')
    this.syncExpanded()
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
    if (!this.menu) return []

    return Array.from(this.menu.querySelectorAll('[role^="menuitem"]'))
  }
}
