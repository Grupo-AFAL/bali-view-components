import { Controller } from '@hotwired/stimulus'
import { syncPopoverAria } from './popover_aria'

/**
 * Saved Views Controller
 *
 * Drives the DataTable "Views" dropdown: toggles the save/rename forms and, right
 * before submitting a new view, injects the CURRENT visible columns (read from the
 * column-selector controller targeting the same table) into the payload hidden field.
 *
 * The payload itself is server-rendered (FilterForm#current_view_payload) — this
 * controller only contributes what lives exclusively in the DOM: column visibility.
 */
export default class extends Controller {
  static targets = ['saveForm', 'renameForm', 'payload']
  static values = { table: String, storageKey: String, serverColumns: Array }

  connect () {
    this.disconnectAria = syncPopoverAria(this.element, this.element.querySelector('button'))
  }

  disconnect () {
    this.disconnectAria?.()
  }

  toggleSaveForm () {
    this.saveFormTarget.classList.toggle('hidden')
    const input = this.saveFormTarget.querySelector('input[type="text"]')
    if (input && !this.saveFormTarget.classList.contains('hidden')) input.focus()
  }

  toggleRename (event) {
    const id = String(event.params.id)
    this.renameFormTargets.forEach(form => {
      if (form.dataset.savedViewsId === id) form.classList.toggle('hidden')
    })
  }

  injectColumns () {
    if (!this.hasPayloadTarget || !this.tableValue) return

    const selector = document.querySelector(
      `[data-controller~="column-selector"][data-column-selector-table-value="${this.tableValue}"]`
    )

    let payload = {}
    try {
      payload = JSON.parse(this.payloadTarget.value || '{}')
    } catch { payload = {} }

    const columns = selector ? this.visibleColumnsFrom(selector) : this.columnsWithoutSelector()
    if (columns === null) return

    payload.columns = columns
    this.payloadTarget.value = JSON.stringify(payload)
  }

  visibleColumnsFrom (selector) {
    return [...selector.querySelectorAll('[data-column-index]')]
      .filter(checkbox => checkbox.checked)
      .map(checkbox => parseInt(checkbox.dataset.columnIndex, 10))
  }

  // El selector se pinta solo en modo tabla. Sin él mandan las columnas que impuso la vista
  // APLICADA (las serializa el servidor): la memoria por dispositivo es anterior a esa vista,
  // así que guardar desde tarjetas o calendario persistía columnas que el usuario no veía.
  // Sin vista aplicada sí vale la memoria del dispositivo — si no, la vista nueva se
  // guardaba sin columnas, "olvidando" la mitad de su estado según desde qué modo se guardó.
  columnsWithoutSelector () {
    return this.serverColumnsValue.length > 0 ? this.serverColumnsValue : this.storedColumns()
  }

  // Misma llave que usa el column-selector para su persistencia por dispositivo. La manda
  // el servidor porque el target (`#<listing_id> table`) ya no la contiene, y porque una
  // llave derivada por separado se separa: ahí las columnas se perdían en silencio.
  storedColumns () {
    if (!this.storageKeyValue) return null

    try {
      const parsed = JSON.parse(localStorage.getItem(this.storageKeyValue))
      return Array.isArray(parsed) ? parsed : null
    } catch {
      return null
    }
  }
}
