import { Controller } from '@hotwired/stimulus'

/**
 * Toolbar Overflow Controller
 *
 * Mueve los controles secundarios de la toolbar del DataTable a un menú "⋯" cuando el
 * viewport baja del breakpoint, y los devuelve al subir. MUEVE, no duplica: dos copias del
 * selector de columnas serían dos controladores manejando la misma tabla, y dos copias de
 * las vistas guardadas duplicarían los ids de sus forms de renombrar — el bug de #669.
 *
 * Todo el estado vive en el DOM (targets + data attributes). El controlador se desconecta y
 * reconecta con cada navegación Turbo, cada restauración de caché y cada turbo-stream que
 * reemplaza el contenedor; un mapa en memoria con "dónde vivía cada control" se perdería en
 * el reconnect y los dejaría atrapados dentro del ⋯.
 *
 * Umbral fijo, no medición: se colapsa lo que declare una prioridad por debajo de
 * `threshold` (ver OVERFLOW_PRIORITIES en el componente).
 *
 *   <div data-controller="toolbar-overflow">
 *     <div data-toolbar-overflow-target="group" data-toolbar-overflow-group="left">
 *       <div data-toolbar-overflow-target="item"
 *            data-toolbar-overflow-group="left"
 *            data-toolbar-overflow-priority="70">…</div>
 *     </div>
 *     <div data-toolbar-overflow-target="overflow">
 *       …<div data-toolbar-overflow-target="menu"></div>
 *     </div>
 *   </div>
 */
export default class extends Controller {
  static targets = ['group', 'item', 'menu', 'overflow']

  static values = {
    breakpoint: { type: Number, default: 640 }, // Tailwind `sm`
    threshold: { type: Number, default: 50 }
  }

  connect () {
    this.mediaQuery = window.matchMedia(`(max-width: ${this.breakpointValue - 1}px)`)
    this.mediaQuery.addEventListener('change', this.handleBreakpointChange)
    document.addEventListener('turbo:before-cache', this.handleBeforeCache)

    // El layout inicial puede llegar ya angosto: no alcanza con escuchar el cruce.
    this.apply(this.mediaQuery.matches)
  }

  disconnect () {
    this.mediaQuery.removeEventListener('change', this.handleBreakpointChange)
    document.removeEventListener('turbo:before-cache', this.handleBeforeCache)
  }

  handleBreakpointChange = (event) => this.apply(event.matches)

  // El snapshot que Turbo cachea tiene que ser SIEMPRE el layout expandido. Cacheado
  // colapsado, volver atrás en un viewport ancho restaura la toolbar plegada hasta que
  // connect() la repara: un parpadeo con la toolbar vacía.
  handleBeforeCache = () => this.apply(false)

  apply (narrow) {
    const focused = this.focusedControl()

    this.closeOpenDropdowns()
    if (narrow) {
      this.collapse()
    } else {
      this.expand()
    }
    this.syncOverflowVisibility()
    this.restoreFocus(focused)
  }

  collapse () {
    if (!this.hasMenuTarget) return

    this.collapsibleItems()
      .filter(item => !this.menuTarget.contains(item))
      .forEach(item => this.menuTarget.appendChild(item))
  }

  expand () {
    if (this.hasMenuTarget) {
      this.itemTargets
        .filter(item => this.menuTarget.contains(item))
        .forEach(item => this.homeGroupFor(item)?.appendChild(item))
    }

    // Reordenar por prioridad es lo que hace innecesario recordar la posición original.
    this.groupTargets.forEach(group => this.sortByPriority(group))
  }

  // Ordenados de mayor a menor para que adentro del ⋯ el orden de lectura sea el mismo que
  // el de la toolbar.
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
   * Cerrar antes de mover. Los dropdowns de columnas, export y vistas guardadas abren por
   * :focus-within de daisyUI: mover el nodo lo saca del documento y el foco salta al body
   * en medio del movimiento. Los que usan el DropdownController guardan su estado en la
   * clase `dropdown-open`, que SOBREVIVE al movimiento — quedarían abiertos dentro del ⋯.
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
   * Cruzar el breakpoint (un zoom al 400%, rotar el teléfono) no puede costarle al usuario
   * de teclado su posición: `closeOpenDropdowns` hace blur y `collapse`/`expand` mueven el
   * nodo enfocado, así que sin esto el foco cae al <body> sin anillo ni anuncio.
   */
  focusedControl () {
    const active = document.activeElement
    if (!active || !this.itemTargets.some(item => item.contains(active))) return null

    return active
  }

  restoreFocus (element) {
    if (!element || !element.isConnected) return

    // Quedó dentro del ⋯ cerrado (no renderizado): el destino equivalente es su trigger,
    // que es por donde el usuario llega ahora a ese control.
    if (element.offsetParent === null) {
      this.overflowTrigger()?.focus({ preventScroll: true })
      return
    }

    element.focus({ preventScroll: true })
  }

  overflowTrigger () {
    if (!this.hasOverflowTarget) return null

    return this.overflowTarget.querySelector('[data-dropdown-target="trigger"]')
  }

  // Sin nada adentro, el ⋯ abriría un menú vacío. `sm:hidden` ya lo tapa arriba del
  // breakpoint; esto cubre al host que solo declaró controles no colapsables.
  syncOverflowVisibility () {
    if (!this.hasOverflowTarget || !this.hasMenuTarget) return

    this.overflowTarget.classList.toggle('hidden', this.menuTarget.children.length === 0)
  }
}
