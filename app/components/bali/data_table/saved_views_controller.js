import { Controller } from '@hotwired/stimulus'
import { syncPopoverAria } from './popover_aria'
import { readColumnState, visibleColumns } from './column_storage'

/**
 * Saved Views Controller
 *
 * Drives the DataTable "Views" dropdown: toggles the save/rename forms and, right
 * before submitting a new view, injects the CURRENT visible columns (read from the
 * column-selector controller targeting the same table) into the payload hidden field.
 *
 * The payload itself is server-rendered (FilterForm#current_view_payload) — this
 * controller only contributes what lives exclusively in the DOM: column visibility.
 *
 * Una vista guardada sigue viajando como lista de columnas VISIBLES, y no se pasó a la
 * polaridad nueva del selector. No es por compatibilidad nada más: son dos cosas distintas.
 * La memoria del dispositivo es IMPLÍCITA —el usuario apagó una columna, no pidió recordarla—
 * y por eso en la duda gana el default del servidor. Una vista es una elección EXPLÍCITA con
 * nombre («estas cinco columnas»), y cambiarla por debajo al agregar una columna sería
 * desobedecerla. Además vive en `bali_saved_views.payload`, ya escrita en tres apps del grupo:
 * el contrato con `apply_visible_columns` no se mueve.
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

  // Misma llave que usa el column-selector para su persistencia por dispositivo, y —desde el
  // formato v2— el mismo LECTOR: `column_storage.js`. La llave la manda el servidor porque el
  // target (`#<listing_id> table`) ya no la contiene, y porque una llave derivada por separado
  // se separa: ahí las columnas se perdían en silencio. Con el formato, igual.
  //
  // La memoria guarda lo oculto; acá hace falta lo visible, así que se traduce —de `known` y
  // `hidden`, o sea del estado RESUELTO, no de las decisiones: lo que el usuario veía es lo que
  // entra en la vista, venga de su elección o del default del anfitrión—. Lo que la memoria no
  // conocía queda FUERA: sin selector en pantalla no hay forma de enumerar las columnas de la
  // tabla, y la traducción devuelve lo último que el usuario sí vio. Es lo mismo que hacía
  // antes, y es coherente con que una vista sea una elección explícita.
  //
  // Corolario: acá tampoco se reescribe nunca la llave. Un listado que el usuario dejó en
  // tarjetas conserva su formato viejo hasta que alguien vuelva al modo tabla.
  storedColumns () {
    return visibleColumns(readColumnState(this.storageKeyValue))
  }
}
