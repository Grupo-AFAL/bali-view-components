import { Controller } from '@hotwired/stimulus'
import { toInt } from '../../../assets/javascripts/bali/utils/formatters.js'

const IGNORED_TAG_NAMES = ['select', 'input']
const SELECTED_CLASS = 'selected'

export class BulkActionsController extends Controller {
  static targets = [
    'item',
    'bulkAction',
    'actionsContainer',
    'announcement',
    'selectedCount',
    'selectedLabelOne',
    'selectedLabelOther',
    'selectAll',
    'toolbar',
    'selectAllOffer',
    'selectAllNotice',
    'selectAllFilteredField'
  ]

  static values = {
    selectedIds: { type: Array, default: [] },
    // Estado de runtime, no del servidor: arranca apagado siempre. El N sí viene del
    // servidor, pero en un data attribute del propio nodo de la oferta y no como value,
    // porque dentro de un DataTable el controlador vive en el contenedor de la tabla —
    // un value tendría que emitirse desde dos componentes distintos y podrían discrepar.
    selectAllFiltered: { type: Boolean, default: false }
  }

  connect () {
    // El DOM manda: tras un restore de caché de Turbo las filas vuelven con su clase
    // `selected` puesta pero el valor del controlador arranca vacío. Derivarlo del DOM
    // evita que el contador y las acciones queden desfasados de lo que se ve.
    this.syncSelectedIds()

    this.element.addEventListener('dblclick', this.handleDoubleClick)
  }

  disconnect () {
    this.element.removeEventListener('dblclick', this.handleDoubleClick)
  }

  handleDoubleClick = (event) => {
    if (IGNORED_TAG_NAMES.includes(event.target.tagName.toLowerCase())) return

    const item = event.target.closest('[data-bulk-actions-target="item"]')

    if (item) { this.toggle(item) }
  }

  toggle = (eventOrItem) => {
    const item = eventOrItem.currentTarget || eventOrItem
    if (!item.dataset.recordId) return

    this.setSelected(item, !item.classList.contains(SELECTED_CLASS))
    this.syncSelectedIds()
  }

  // El checkbox de la fila no es el item: sube al `<tr>`, que es quien lleva el record id.
  toggleItem = (event) => {
    const item = event.target.closest('[data-bulk-actions-target="item"]')

    if (item) this.toggle(item)
  }

  toggleAll = (event) => {
    this.selectableItems.forEach(item => this.setSelected(item, event.target.checked))
    this.syncSelectedIds()
  }

  clear = () => {
    // El ✕ vive DENTRO de la barra que él mismo esconde: si no se saca el foco antes, el
    // navegador lo tira al <body> y el usuario de teclado pierde su posición. Se mira
    // ANTES de sincronizar, porque para entonces la barra ya está en display:none.
    const focusWasInBar = this.hasActionsContainerTarget &&
      this.actionsContainerTarget.contains(document.activeElement)

    this.selectableItems.forEach(item => this.setSelected(item, false))
    this.syncSelectedIds()

    if (focusWasInBar) this.focusAfterClear()
  }

  // Destino equivalente al ✕: el seleccionar-todo, que es el control de selección que queda
  // en pie; si la tabla no lo trae, el primer control de la toolbar recién restaurada.
  focusAfterClear = () => {
    if (this.hasSelectAllTarget) {
      this.selectAllTarget.focus({ preventScroll: true })
      return
    }

    if (!this.hasToolbarTarget) return

    this.toolbarTarget
      .querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])')
      ?.focus({ preventScroll: true })
  }

  setSelected = (item, selected) => {
    item.classList.toggle(SELECTED_CLASS, selected)

    const checkbox = item.querySelector('input[type="checkbox"]')
    if (checkbox) checkbox.checked = selected
  }

  // Sale del modo "todos los filtrados" en cuanto la selección deja de cubrir la página
  // entera — patrón Gmail: des-checkear una fila te devuelve a la selección por página en
  // vez de encerrarte en un estado del que solo se sale por el ✕. Por eso los checkboxes
  // NO se deshabilitan durante el modo.
  selectAllFiltered = () => {
    if (this.totalCount <= 0) return

    this.selectAllFilteredValue = true
    this.update()
  }

  // Derivado, nunca incremental: seleccionar-todo y limpiar mueven muchas filas de una
  // y un contador incremental se llenaría de duplicados o de ids fantasma.
  syncSelectedIds = () => {
    this.selectedIdsValue = this.selectableItems
      .filter(item => item.classList.contains(SELECTED_CLASS))
      .map(item => toInt(item.dataset.recordId))

    if (this.selectAllFilteredValue && !this.pageFullySelected) {
      this.selectAllFilteredValue = false
    }

    this.update()
  }

  get selectableItems () {
    return this.itemTargets.filter(item => item.dataset.recordId)
  }

  get pageFullySelected () {
    const total = this.selectableItems.length

    return total > 0 && this.selectedIdsValue.length === total
  }

  // Cuántos registros tiene el resultado filtrado completo. El servidor lo pinta en el nodo
  // de la oferta; sin oferta no hay modo y el modo no puede encenderse.
  get totalCount () {
    if (!this.hasSelectAllOfferTarget) return 0

    return toInt(this.selectAllOfferTarget.dataset.totalCount)
  }

  // Lo que la barra REPRESENTA: N en modo "todos los filtrados", los ids marcados si no.
  get selectionCount () {
    return this.selectAllFilteredValue ? this.totalCount : this.selectedIdsValue.length
  }

  update = () => {
    this.updateBulkActionsSelectedIds()
    this.updateSelectAllFilteredFields()
    this.updateActionsContainer()
    this.updateSelectedCount()
    this.updateSelectAll()
    this.updateSelectAllFilteredBar()
    this.updateToolbar()
    this.announceSelection()
  }

  // En modo "todos los filtrados" los ids se vacían a propósito: el servidor re-deriva el
  // scope de los `q[...]` que viajan en el mismo POST, así que una lista de ids de la página
  // visible solo podría contradecirlo.
  updateBulkActionsSelectedIds = () => {
    const ids = JSON.stringify(this.selectAllFilteredValue ? [] : this.selectedIdsValue)

    this.bulkActionTargets.forEach(action => {
      if (action.tagName.toLowerCase() === 'a') {
        const url = new URL(action.href)
        url.searchParams.set('selected_ids', ids)
        if (this.hasSelectAllOfferTarget) {
          url.searchParams.set('select_all_filtered', String(this.selectAllFilteredValue))
        }

        action.href = url.href
      } else {
        action.value = ids
      }
    })
  }

  updateSelectAllFilteredFields = () => {
    this.selectAllFilteredFieldTargets.forEach(field => {
      field.value = String(this.selectAllFilteredValue)
    })
  }

  // La oferta solo tiene sentido cuando la página está entera y hay más resultados detrás;
  // el aviso la reemplaza mientras el modo está encendido.
  updateSelectAllFilteredBar = () => {
    if (!this.hasSelectAllOfferTarget) return

    const offered = !this.selectAllFilteredValue && this.pageFullySelected &&
      this.totalCount > this.selectableItems.length

    this.selectAllOfferTarget.classList.toggle('hidden', !offered)

    if (this.hasSelectAllNoticeTarget) {
      this.selectAllNoticeTarget.classList.toggle('hidden', !this.selectAllFilteredValue)
    }
  }

  updateActionsContainer = () => {
    if (!this.hasActionsContainerTarget) return

    if (this.selectionCount > 0) {
      this.actionsContainerTarget.classList.remove('hidden')
    } else {
      this.actionsContainerTarget.classList.add('hidden')
    }
  }

  updateSelectedCount = () => {
    if (this.hasSelectedCountTarget) {
      this.selectedCountTarget.innerText = this.selectionCount
    }

    if (!this.hasSelectedLabelOneTarget || !this.hasSelectedLabelOtherTarget) return

    // El plural lo sirve el servidor en dos nodos: acá solo se elige cuál se ve, así no
    // hay que interpolar i18n en JS.
    const one = this.selectionCount === 1
    this.selectedLabelOneTarget.classList.toggle('hidden', !one)
    this.selectedLabelOtherTarget.classList.toggle('hidden', one)
  }

  updateSelectAll = () => {
    if (!this.hasSelectAllTarget) return

    const total = this.selectableItems.length
    const selected = this.selectedIdsValue.length

    this.selectAllTarget.checked = total > 0 && selected === total
    this.selectAllTarget.indeterminate = selected > 0 && selected < total
  }

  // El cambio de selección no mueve el foco, así que sin anunciarlo el usuario de lector de
  // pantalla marca N filas sin ninguna confirmación de que la selección existe.
  announceSelection = () => {
    if (!this.hasAnnouncementTarget) return

    const count = this.selectionCount
    if (count === 0) {
      this.announcementTarget.textContent = ''
      return
    }

    const { selectedOne, selectedOther } = this.announcementTarget.dataset
    this.announcementTarget.textContent = `${count} ${count === 1 ? selectedOne : selectedOther}`.trim()
  }

  // La fila contextual REEMPLAZA la toolbar: mismo hueco, nunca las dos a la vez.
  updateToolbar = () => {
    if (!this.hasToolbarTarget) return

    this.toolbarTarget.classList.toggle('hidden', this.selectionCount > 0)
  }
}
