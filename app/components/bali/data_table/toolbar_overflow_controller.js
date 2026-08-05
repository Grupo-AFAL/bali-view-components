import { Controller } from '@hotwired/stimulus'

// A dónde puede ir a parar el foco cuando el control que lo tenía cambia de lugar. El
// `[tabindex]` no negativo cubre al trigger del dropdown, que es un div con `role="button"`.
const FOCUSABLE = 'a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])'

/**
 * Toolbar Overflow Controller
 *
 * Mueve los controles secundarios de la toolbar del DataTable a un menú "⋯" cuando la fila
 * deja de entrar, y los devuelve cuando vuelve a haber lugar. MUEVE, no duplica: dos copias del
 * selector de columnas serían dos controladores manejando la misma tabla, y dos copias de
 * las vistas guardadas duplicarían los ids de sus forms de renombrar — el bug de #669.
 *
 * Todo el estado vive en el DOM (targets + data attributes). El controlador se desconecta y
 * reconecta con cada navegación Turbo, cada restauración de caché y cada turbo-stream que
 * reemplaza el contenedor; un mapa en memoria con "dónde vivía cada control" se perdería en
 * el reconnect y los dejaría atrapados dentro del ⋯.
 *
 * Qué puede colapsar lo declara la prioridad (`threshold`, ver OVERFLOW_PRIORITIES en el
 * componente); CUÁNTO colapsa lo decide la MEDICIÓN de la fila. El breakpoint solo sigue
 * siendo el piso de móvil: el ancho que la toolbar tiene no lo fija el viewport sino el
 * layout del host —un sidebar le come 300px— y con el corte fijo en `sm` la fila se apretaba
 * sin colapsar nada, dejando la búsqueda pintada encima de agrupar y columnas.
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

    // Se observan los ITEMS además de la fila. El box de la fila lo fija su padre y no cambia
    // cuando su contenido crece: medido, meterle un hijo de 300px produce CERO callbacks. Lo
    // que crece es el control — SlimSelect reemplaza su `<select>` por un widget más ancho,
    // flatpickr monta el suyo, una fuente termina de cargar— y eso sí cambia el box del item
    // que lo contiene. Sin esto la válvula del ⋯ sólo se evaluaba al montar, cuando ninguno de
    // esos widgets existe todavía.
    this.observer = new window.ResizeObserver(this.handleResize)
    this.observer.observe(this.element)
    this.itemTargets.forEach(item => this.observer.observe(item))

    // El layout inicial puede llegar ya angosto: no alcanza con escuchar el cruce.
    this.apply(this.mediaQuery.matches)
    this.recordMeasurements()
    this.reveal()
  }

  /**
   * Los controles colapsables llegan con el lugar reservado y sin dibujarse, y esto los
   * destapa una vez que la fila ya está en su forma final. Ver RESERVED_CLASSES en el
   * componente.
   *
   * Va acá y no detrás de un heurístico de "ya se asentó" porque la causa del parpadeo no
   * es que la fila crezca: es que el servidor manda la fila SIN colapsar y nadie la puede
   * colapsar hasta que este controlador existe. Medido en /admin/studios, la página pinta a
   * los 260ms y `connect()` no corre hasta los 1189ms, cuando termina de ejecutarse el
   * bundle. Al terminar el `apply()` de arriba la fila ya es la definitiva, así que no hay
   * nada que esperar.
   *
   * Un `apply()` posterior —el que dispara un widget que se ensancha al montar— pasa con los
   * controles ya visibles, que es lo correcto: a esa altura mover uno al ⋯ es una respuesta
   * a algo que cambió, no un estado inicial equivocado.
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
   * Dos medidas deciden si hay que recomputar, no una: lo que la fila TIENE y lo que la fila
   * NECESITA. Con sólo el ancho disponible, un control que se ensancha DESPUÉS del primer
   * layout —SlimSelect reemplazando su `<select>`, flatpickr montando su input, una fuente
   * que termina de cargar— no dispara nada, y la fila se desborda sin que el ⋯ se entere.
   * Medido sobre `/studios` a 2008px: `max-content` pedía 2078 y el menú tenía 0 items, con
   * la fila de filtros plegada en tres líneas.
   *
   * Las dos se leen dentro del rAF, no en el callback del observer: `requiredWidth()` escribe
   * `style.width` para medir, y hacerlo dentro del callback es pedirle al observer que vuelva
   * a entrar por el cambio que acabamos de provocar — el bucle que Chrome denuncia como
   * "ResizeObserver loop". Por lo mismo la comparación se guarda DESPUÉS de aplicar: colapsar
   * baja el `max-content`, así que anotar el valor previo garantizaba una segunda pasada.
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

  // El snapshot que Turbo cachea tiene que ser SIEMPRE el layout expandido. Cacheado
  // colapsado, volver atrás en un viewport ancho restaura la toolbar plegada hasta que
  // connect() la repara: un parpadeo con la toolbar vacía.
  handleBeforeCache = () => {
    this.closeOpenDropdowns()
    this.expand()
    this.sync()
  }

  apply (narrow) {
    const focused = this.focusedControl()

    this.closeOpenDropdowns()
    // Siempre se parte de la fila entera: el colapso es incremental y sin volver a expandir
    // primero, ensanchar nunca devolvería nada.
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

  // Bajo el breakpoint no se mide: en un teléfono no entra nada y el resultado tiene que ser
  // el mismo siempre, no depender de cuánto ocupe una etiqueta traducida.
  collapseAll () {
    if (!this.hasMenuTarget) return

    this.collapsibleItems()
      .filter(item => !this.menuTarget.contains(item))
      .forEach(item => this.menuTarget.appendChild(item))
  }

  /**
   * Se sacrifica de menor a mayor prioridad y solo hasta que la fila entra: el ⋯ deja de ser
   * un modo de móvil y pasa a ser la válvula de cualquier ancho. Cada movimiento re-sincroniza
   * antes de volver a medir porque el propio ⋯ ocupa lugar y un grupo que queda vacío se
   * esconde, devolviendo su `gap`.
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
   * Lo que la fila NECESITA contra lo que TIENE. `scrollWidth` no sirve como señal: lo que
   * no entra vive dentro del único item elástico, que se encoge a 0 y deja su contenido
   * pintado por encima de los vecinos SIN generar scroll — medido `scrollWidth === clientWidth`
   * con tres controles superpuestos. Con `max-content` cada item aporta su ancho natural, que
   * es la pregunta real.
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

    // Reordenar por prioridad es lo que hace innecesario recordar la posición original.
    this.groupTargets.forEach(group => this.sortByPriority(group))
  }

  // Ordenados de mayor a menor para que adentro del ⋯ el orden de lectura sea el mismo que
  // el de la toolbar. Se sostiene porque las prioridades bajan siguiendo la fila (ver
  // OVERFLOW_PRIORITIES); renumerarlas sin mirar el layout rompe esta correspondencia sin
  // que falle nada.
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
   *
   * El ⋯ cuenta como control y NO es un `item`: angosto es la única forma de llegar a lo
   * colapsado, y al ensanchar se esconde. Sin contarlo acá, el cruce hacia arriba —volver
   * del zoom al 400%— tiraba el foco al <body>, que es exactamente la pérdida que este
   * método existe para evitar, solo que en el otro sentido.
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

    // El foco estaba en el ⋯. Si sigue en pantalla vuelve a su trigger; si se escondió
    // porque ya no hay nada que colapsar, el destino equivalente es el control de mayor
    // prioridad que acaba de volver a la fila — lo primero que el menú ofrecía.
    if (element === this.overflowTarget) {
      const home = this.isRendered(element) ? this.overflowTrigger() : this.collapsibleItems()[0]
      this.focusableWithin(home)?.focus({ preventScroll: true })
      return
    }

    // Quedó dentro del ⋯ cerrado (no renderizado): el destino equivalente es su trigger,
    // que es por donde el usuario llega ahora a ese control.
    if (!this.isRendered(element)) {
      this.overflowTrigger()?.focus({ preventScroll: true })
      return
    }

    element.focus({ preventScroll: true })
  }

  isRendered (element) {
    return element.offsetParent !== null
  }

  // Los `item` son ENVOLTORIOS, no controles: enfocarlos no hace nada. El foco va al primer
  // elemento enfocable que tengan adentro.
  focusableWithin (element) {
    if (!element) return null

    return element.matches(FOCUSABLE) ? element : element.querySelector(FOCUSABLE)
  }

  overflowTrigger () {
    if (!this.hasOverflowTarget) return null

    return this.overflowTarget.querySelector('[data-dropdown-target="trigger"]')
  }

  /**
   * Un grupo vacío sigue siendo un flex item: se lleva el `gap` de la fila a los dos lados y
   * le come ancho a la búsqueda justo en el viewport donde menos sobra.
   */
  syncGroupVisibility () {
    this.groupTargets.forEach(group => {
      group.classList.toggle('hidden', group.children.length === 0)
    })
  }

  /**
   * La barrita es una AFIRMACIÓN sobre sus vecinos ("acá termina qué contiene la vista y
   * empieza cómo se recuerda"). Cuando el overflow se lleva uno de los dos lados la
   * afirmación deja de ser cierta y queda marcando una frontera contra nada. NO es un
   * control: no es `item`, así que `collapsibleItems` no la puede mover al ⋯ — solo se
   * esconde y vuelve.
   */
  syncSeparators () {
    this.separatorTargets.forEach(separator => {
      separator.classList.toggle('hidden', !this.separatorFlanked(separator))
    })
  }

  // Los grupos se buscan POR NOMBRE y no por adyacencia en el DOM: insertar cualquier nodo
  // entre la barrita y un grupo rompía la decisión en silencio.
  separatorFlanked (separator) {
    return (separator.dataset.toolbarOverflowSeparates || '')
      .split(' ')
      .filter(name => name)
      .every(name => this.groupNamed(name)?.children.length > 0)
  }

  groupNamed (name) {
    return this.groupTargets.find(group => group.dataset.toolbarOverflowGroup === name)
  }

  // Sin nada adentro, el ⋯ abriría un menú vacío. Es la ÚNICA regla de visibilidad del menú
  // desde que el colapso se mide: el markup ya no lo tapa por breakpoint.
  syncOverflowVisibility () {
    if (!this.hasOverflowTarget || !this.hasMenuTarget) return

    this.overflowTarget.classList.toggle('hidden', this.menuTarget.children.length === 0)
  }
}
