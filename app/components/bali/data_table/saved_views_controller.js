import { Controller } from '@hotwired/stimulus'

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
  static values = { table: String }

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
    if (!selector) return

    let payload = {}
    try {
      payload = JSON.parse(this.payloadTarget.value || '{}')
    } catch { payload = {} }

    payload.columns = [...selector.querySelectorAll('[data-column-index]')]
      .filter(checkbox => checkbox.checked)
      .map(checkbox => parseInt(checkbox.dataset.columnIndex, 10))
    this.payloadTarget.value = JSON.stringify(payload)
  }
}
