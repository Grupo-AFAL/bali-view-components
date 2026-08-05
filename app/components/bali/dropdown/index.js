import { Controller } from '@hotwired/stimulus'
import zIndexFor from '../../../assets/javascripts/bali/utils/z-index.js'

export class DropdownController extends Controller {
  static targets = ['trigger', 'menu']
  static values = {
    closeOnClick: { type: Boolean, default: true },
    // Portal the menu out of any ancestor whose `overflow` would clip it. The menu is
    // MOVED into the popper, not copied: the element the server rendered is the element
    // the reader operates, so ids, Stimulus targets, `data-turbo-confirm` and every
    // listener already on it survive the trip. `this.menu` is captured at connect, before
    // the move, because a Stimulus target lookup is scoped to the controller element and
    // stops finding it the moment tippy appends the popper to `<body>`.
    popover: { type: Boolean, default: false },
    placement: { type: String, default: 'bottom-start' }
  }

  connect () {
    this.menu = this.hasMenuTarget ? this.menuTarget : null

    if (this.closeOnClickValue) {
      document.addEventListener('click', this.handleOutsideClick)
    }
    this.listenOn(this.element)
    if (this.popoverValue) this.setupPopover()
  }

  disconnect () {
    if (this.closeOnClickValue) {
      document.removeEventListener('click', this.handleOutsideClick)
    }
    this.stopListeningOn(this.element)
    if (this.menu) this.stopListeningOn(this.menu)
    this.element.removeEventListener('click', this.handleTriggerClick)

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

    const { default: tippy } = await import('tippy.js')

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
      appendTo: () => document.body,
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

    this.element.addEventListener('click', this.handleTriggerClick)
  }

  // Bound on the wrapper rather than on the trigger, because a press and a release do not
  // always land on the same element: the wrapper is the only other thing under the pointer
  // and it is an ancestor, so a click that starts on the trigger and ends a pixel outside
  // it still arrives. Measured in Cypress, where focusing on `mousedown` scrolls the page
  // enough that `mouseup` and `click` retarget from the trigger to the wrapper and a
  // trigger-bound listener never fires at all. In popover mode the menu lives in the
  // popper, so no item click reaches this handler.
  handleTriggerClick = (event) => {
    if (this.fromNestedDropdown(event.target)) return

    event.preventDefault()
    this.toggle()
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
   * `aria-expanded` seguía al TECLADO, no a la pantalla. Quien abre el panel con el mouse
   * nunca pasa por `open()`: daisyUI lo despliega por `:focus-within` al enfocarse el trigger,
   * así que el lector de pantalla anunciaba "contraído" con el menú a la vista (WCAG 4.1.2).
   * El foco es la señal REAL de apertura de daisyUI, así que el atributo se sincroniza con él.
   *
   * En modo popover el foco no es la señal —el panel lo abre y lo cierra tippy—, así que ahí
   * manda `onPopoverShow`/`onPopoverHide` y esto se aparta.
   */
  handleFocusIn = (event) => {
    if (this.popoverValue) return

    // Focus arriving from outside is the reader coming back, and daisyUI's `:focus-within`
    // is about to open the menu — so the explicit-close mark has to go, or an outside click
    // would leave the dropdown shut for the rest of the page's life. Focus arriving from
    // INSIDE is Escape handing the trigger its focus back, and that must not reopen it.
    if (!this.owns(event.relatedTarget)) {
      this.element.classList.remove('dropdown-close')
    }
    this.syncExpanded()
  }

  handleFocusOut = (event) => {
    if (this.popoverValue) return
    // El foco puede saltar ENTRE hijos (del trigger a un item): eso no es cerrar.
    if (event.relatedTarget && this.owns(event.relatedTarget)) return

    // Focus has genuinely left. Drop the explicit-close mark so that coming back with Tab
    // opens the menu again, the way focusing a dropdown that was never closed does.
    this.element.classList.remove('dropdown-close')
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
    if (this.tippy) return this.element.classList.contains('dropdown-open')

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
  // hangs off `<body>` rather than off the wrapper, so `this.element.contains` on its own
  // answers "not mine" about this dropdown's own panel.
  owns (node) {
    if (!node) return false

    return this.element.contains(node) || Boolean(this.menu && this.menu.contains(node))
  }

  // Only a dropdown that is actually open gets closed. `close()` now leaves `dropdown-close`
  // behind, and that class outranks `:focus-within`: closing a menu nobody had opened would
  // mark it shut for good, and the next click on its trigger would do nothing at all.
  handleOutsideClick = (event) => {
    if (this.owns(event.target)) return
    if (!this.isOpen) return

    this.close()
  }

  handleKeydown = (event) => {
    // El keydown BURBUJEA y un dropdown puede contener otros (el ⋯ de la toolbar del
    // DataTable): sin este guard la misma tecla la procesaban los dos controladores, así que
    // una sola flecha saltaba dos items y un Escape dentro del dropdown de adentro cerraba
    // el contenedor entero.
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
        // Dentro de un campo, las flechas son del campo: mueven el cursor o la selección.
        if (this.fromFormControl(event.target)) break
        event.preventDefault()
        // Unconditionally, even when the menu is already on screen: daisyUI may have opened
        // it from `:focus-within` without `dropdown-open` on the wrapper, and that class is
        // how the rest of the package tells an explicitly-opened dropdown from a merely
        // focused one — `toolbar_overflow_controller` closes exactly those before folding a
        // control into the ⋯, and it looked for a class the keyboard had stopped setting.
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
        if (document.activeElement === this.triggerTarget) {
          event.preventDefault()
          this.toggle()
        }
        break
    }
  }

  // ¿El evento nació en un dropdown ANIDADO dentro de éste? Entonces es del de adentro.
  // Markup a mano sin `.dropdown` alrededor sigue funcionando: `closest` devuelve null.
  fromNestedDropdown (target) {
    const nearest = target?.closest?.('.dropdown')

    return Boolean(nearest) && nearest !== this.element && this.owns(nearest)
  }

  fromFormControl (target) {
    return Boolean(target?.closest?.('input, textarea, select'))
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
    this.syncExpanded()
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

    return Array.from(this.menu.querySelectorAll('[role="menuitem"]'))
  }
}
