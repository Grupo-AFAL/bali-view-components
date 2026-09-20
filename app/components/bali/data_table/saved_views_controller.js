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
 * A view still travels as a list of VISIBLE columns, and did not follow the selector to the
 * new polarity. It is an EXPLICIT, named choice, so it shows exactly what it recorded; the
 * device memory is implicit, and there the server's default wins ties. The payload also lives
 * in `bali_saved_views.payload`, already written in three apps of the group — the contract
 * with `apply_visible_columns` does not move.
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

  // The selector is only painted in table mode. Without it, the columns imposed by the
  // APPLIED view win (the server serializes them): the per-device memory predates that view,
  // so saving from cards or calendar persisted columns the user could not see. With no view
  // applied the device memory does count — otherwise the new view was saved with no columns,
  // "forgetting" half of its state depending on which mode it was saved from.
  columnsWithoutSelector () {
    return this.serverColumnsValue.length > 0 ? this.serverColumnsValue : this.storedColumns()
  }

  // Same key the column-selector persists to, and — since v2 — the same READER. The server
  // sends the key because the target (`#<listing_id> table`) no longer contains it, and because
  // a key derived separately drifts apart: that is how the columns went missing in silence.
  //
  // Read-only on purpose: with no selector on screen there is no way to enumerate the table's
  // columns, so a listing left in cards mode keeps its old format until someone returns to the
  // table.
  storedColumns () {
    return visibleColumns(readColumnState(this.storageKeyValue))
  }
}
