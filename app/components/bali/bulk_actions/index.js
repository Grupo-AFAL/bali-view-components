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
    'toolbar'
  ]

  static values = {
    selectedIds: { type: Array, default: [] }
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

  // Derivado, nunca incremental: seleccionar-todo y limpiar mueven muchas filas de una
  // y un contador incremental se llenaría de duplicados o de ids fantasma.
  syncSelectedIds = () => {
    this.selectedIdsValue = this.selectableItems
      .filter(item => item.classList.contains(SELECTED_CLASS))
      .map(item => toInt(item.dataset.recordId))

    this.update()
  }

  get selectableItems () {
    return this.itemTargets.filter(item => item.dataset.recordId)
  }

  update = () => {
    this.updateBulkActionsSelectedIds()
    this.updateActionsContainer()
    this.updateSelectedCount()
    this.updateSelectAll()
    this.updateToolbar()
    this.announceSelection()
  }

  updateBulkActionsSelectedIds = () => {
    this.bulkActionTargets.forEach(action => {
      if (action.tagName.toLowerCase() === 'a') {
        const url = new URL(action.href)
        url.searchParams.set('selected_ids', JSON.stringify(this.selectedIdsValue))

        action.href = url.href
      } else {
        action.value = JSON.stringify(this.selectedIdsValue)
      }
    })
  }

  updateActionsContainer = () => {
    if (!this.hasActionsContainerTarget) return

    if (this.selectedIdsValue.length > 0) {
      this.actionsContainerTarget.classList.remove('hidden')
    } else {
      this.actionsContainerTarget.classList.add('hidden')
    }
  }

  updateSelectedCount = () => {
    if (this.hasSelectedCountTarget) {
      this.selectedCountTarget.innerText = this.selectedIdsValue.length
    }

    if (!this.hasSelectedLabelOneTarget || !this.hasSelectedLabelOtherTarget) return

    // El plural lo sirve el servidor en dos nodos: acá solo se elige cuál se ve, así no
    // hay que interpolar i18n en JS.
    const one = this.selectedIdsValue.length === 1
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

    const count = this.selectedIdsValue.length
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

    this.toolbarTarget.classList.toggle('hidden', this.selectedIdsValue.length > 0)
  }
}
