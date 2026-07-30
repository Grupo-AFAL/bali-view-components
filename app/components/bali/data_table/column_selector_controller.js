import { Controller } from '@hotwired/stimulus'

/**
 * Column Selector Controller
 *
 * Toggles visibility of table columns based on checkbox state.
 * Works with any table by targeting columns by index.
 *
 * Usage:
 *   <div data-controller="column-selector" data-column-selector-table-value="#my-listing table">
 *     <input type="checkbox" data-action="column-selector#toggle" data-column-index="0" checked>
 *     <input type="checkbox" data-action="column-selector#toggle" data-column-index="1">  <!-- hidden by default -->
 *   </div>
 */
export default class extends Controller {
  static values = {
    table: String, // Selector for the target table
    storageKey: String, // localStorage key for per-device persistence ('' disables)
    serverState: Boolean // true when a saved view imposed the state (skip localStorage restore)
  }

  connect () {
    this.table = document.querySelector(this.tableValue)
    if (!this.table) {
      console.warn(`Column selector: table not found with selector "${this.tableValue}"`)
      return
    }

    // Per-device persistence (B2): restore the stored column set — unless a saved
    // view imposed the state server-side (the view wins over the device memory).
    if (!this.serverStateValue) this.restoreStoredState()

    // Apply initial visibility based on checkbox state
    this.applyInitialState()
  }

  restoreStoredState () {
    if (!this.storageKeyValue) return

    let stored
    try {
      stored = JSON.parse(window.localStorage.getItem(this.storageKeyValue))
    } catch { return }
    if (!Array.isArray(stored)) return

    this.element.querySelectorAll('[data-column-index]').forEach(checkbox => {
      const index = parseInt(checkbox.dataset.columnIndex, 10)
      if (!isNaN(index)) checkbox.checked = stored.includes(index)
    })
  }

  persistState () {
    if (!this.storageKeyValue) return

    const visible = [...this.element.querySelectorAll('[data-column-index]')]
      .filter(checkbox => checkbox.checked)
      .map(checkbox => parseInt(checkbox.dataset.columnIndex, 10))
    try {
      window.localStorage.setItem(this.storageKeyValue, JSON.stringify(visible))
    } catch { /* almacenamiento lleno o bloqueado: la sesión sigue sin persistir */ }
  }

  applyInitialState () {
    const checkboxes = this.element.querySelectorAll('[data-column-index]')
    checkboxes.forEach(checkbox => {
      const index = parseInt(checkbox.dataset.columnIndex, 10)
      if (!isNaN(index)) {
        this.setColumnVisibility(index, checkbox.checked)
      }
    })
  }

  toggle (event) {
    const checkbox = event.target
    const columnIndex = parseInt(checkbox.dataset.columnIndex, 10)
    const visible = checkbox.checked

    if (isNaN(columnIndex) || !this.table) return

    this.setColumnVisibility(columnIndex, visible)
    // Con una vista aplicada (serverState) el toggle es un ajuste SOBRE la vista: no debe
    // volverse el default del dispositivo en localStorage.
    if (!this.serverStateValue) this.persistState()
  }

  setColumnVisibility (index, visible) {
    // Toggle header
    const headers = this.table.querySelectorAll('thead th')
    if (headers[index]) {
      headers[index].style.display = visible ? '' : 'none'
    }

    // Toggle cells in each row
    const rows = this.table.querySelectorAll('tbody tr')
    rows.forEach(row => {
      const cells = row.querySelectorAll('td')
      if (cells[index]) {
        cells[index].style.display = visible ? '' : 'none'
      }
    })

    // Toggle footer cells if present
    const footerRows = this.table.querySelectorAll('tfoot tr')
    footerRows.forEach(row => {
      const cells = row.querySelectorAll('td, th')
      if (cells[index]) {
        cells[index].style.display = visible ? '' : 'none'
      }
    })
  }
}
