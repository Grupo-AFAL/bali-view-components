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
    this.element.addEventListener('focusin', this.handleFocusIn)
    this.element.addEventListener('focusout', this.handleFocusOut)
  }

  disconnect () {
    if (this.closeOnClickValue) {
      document.removeEventListener('click', this.handleOutsideClick)
    }
    this.element.removeEventListener('keydown', this.handleKeydown)
    this.element.removeEventListener('focusin', this.handleFocusIn)
    this.element.removeEventListener('focusout', this.handleFocusOut)
  }

  /**
   * `aria-expanded` seguía al TECLADO, no a la pantalla. Quien abre el panel con el mouse
   * nunca pasa por `open()`: daisyUI lo despliega por `:focus-within` al enfocarse el trigger,
   * así que el lector de pantalla anunciaba "contraído" con el menú a la vista (WCAG 4.1.2).
   * El foco es la señal REAL de apertura de daisyUI, así que el atributo se sincroniza con él.
   *
   * Solo el atributo: la clase `dropdown-open` la sigue manejando el camino de teclado, que es
   * el que la usa para saber si ya estaba abierto.
   */
  handleFocusIn = () => this.setExpanded(true)

  handleFocusOut = (event) => {
    // El foco puede saltar ENTRE hijos (del trigger a un item): eso no es cerrar.
    if (event.relatedTarget && this.element.contains(event.relatedTarget)) return

    this.setExpanded(false)
  }

  setExpanded (expanded) {
    if (!this.hasTriggerTarget) return

    this.triggerTarget.setAttribute('aria-expanded', String(expanded))
  }

  handleOutsideClick = (event) => {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  handleKeydown = (event) => {
    // El keydown BURBUJEA y un dropdown puede contener otros (el ⋯ de la toolbar del
    // DataTable): sin este guard la misma tecla la procesaban los dos controladores, así que
    // una sola flecha saltaba dos items y un Escape dentro del dropdown de adentro cerraba
    // el contenedor entero.
    if (this.fromNestedDropdown(event.target)) return

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
        // Dentro de un campo, las flechas son del campo: mueven el cursor o la selección.
        if (this.fromFormControl(event.target)) break
        event.preventDefault()
        if (!isOpen) {
          this.open()
        }
        this.focusNextItem()
        break
      case 'ArrowUp':
        if (this.fromFormControl(event.target)) break
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

  // ¿El evento nació en un dropdown ANIDADO dentro de éste? Entonces es del de adentro.
  // Markup a mano sin `.dropdown` alrededor sigue funcionando: `closest` devuelve null.
  fromNestedDropdown (target) {
    const nearest = target?.closest?.('.dropdown')

    return Boolean(nearest) && nearest !== this.element && this.element.contains(nearest)
  }

  fromFormControl (target) {
    return Boolean(target?.closest?.('input, textarea, select'))
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
    this.setExpanded(true)
  }

  close () {
    this.element.classList.remove('dropdown-open')
    this.setExpanded(false)
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
