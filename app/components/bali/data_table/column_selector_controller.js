import { Controller } from '@hotwired/stimulus'
import { syncPopoverAria } from './popover_aria'
import { readColumnState, writeColumnState } from './column_storage'

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
 *
 * Column memory is read against `checkbox.defaultChecked`: it reflects the `checked` attribute
 * the server rendered — the host's `with_column(visible:)` — and does not move when the user
 * ticks the box, or when this code does. `column_storage.js` has the format and the why.
 */
export default class extends Controller {
  static values = {
    table: String, // Selector for the target table
    storageKey: String, // localStorage key for per-device persistence ('' disables)
    serverState: Boolean // true when a saved view imposed the state (skip localStorage restore)
  }

  connect () {
    this.disconnectAria = syncPopoverAria(this.element, this.element.querySelector('button'))

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

  disconnect () {
    this.disconnectAria?.()
  }

  restoreStoredState () {
    const state = readColumnState(this.storageKeyValue)
    if (!state) return

    this.eachColumnCheckbox((checkbox, index) => {
      if (!state.known.includes(index)) return

      // What the host declared WHEN the memory was written. A v1 value recorded none (`null`),
      // and there the best data available is what it declares now: crediting the user with a
      // column the server already shipped hidden is the very mistake to avoid.
      const declaredHidden = state.serverHidden
        ? state.serverHidden.includes(index)
        : !checkbox.defaultChecked
      const wasHidden = state.hidden.includes(index)

      // Only a difference is a decision. Equal means nobody chose, so the server keeps the say —
      // and it may have changed its mind since.
      if (wasHidden !== declaredHidden) checkbox.checked = !wasHidden
    })

    // Rewriting here, and not only in `toggle`, is what gets the migration to someone who never
    // opens the menu again. Idempotent: the next read already finds the full format.
    if (state.stale) this.persistState()
  }

  persistState () {
    if (!this.storageKeyValue) return

    const hidden = []
    const known = []
    const serverHidden = []
    this.eachColumnCheckbox((checkbox, index) => {
      known.push(index)
      if (!checkbox.checked) hidden.push(index)
      if (!checkbox.defaultChecked) serverHidden.push(index)
    })

    writeColumnState(this.storageKeyValue, { hidden, known, serverHidden })
  }

  // `known` comes from the checkboxes present, not from the table's columns: what is remembered
  // is what can be toggled. With `selectable:`, column 0 is the selection box — a real `<th>`
  // the selector does not declare — so the indices start at 1.
  eachColumnCheckbox (callback) {
    this.element.querySelectorAll('[data-column-index]').forEach(checkbox => {
      const index = parseInt(checkbox.dataset.columnIndex, 10)
      if (!isNaN(index)) callback(checkbox, index)
    })
  }

  applyInitialState () {
    this.eachColumnCheckbox((checkbox, index) => this.setColumnVisibility(index, checkbox.checked))
  }

  toggle (event) {
    const checkbox = event.target
    const columnIndex = parseInt(checkbox.dataset.columnIndex, 10)
    const visible = checkbox.checked

    if (isNaN(columnIndex) || !this.table) return

    this.setColumnVisibility(columnIndex, visible)
    // With a view applied, a toggle is an adjustment ON TOP of the view, not a new device default.
    if (!this.serverStateValue) this.persistState()
  }

  setColumnVisibility (index, visible) {
    const display = visible ? '' : 'none'

    // Toggle header
    const headers = this.table.querySelectorAll('thead th')
    if (headers[index]) {
      headers[index].style.display = display
    }

    // Toggle cells in each row
    this.table.querySelectorAll('tbody tr').forEach(row => {
      const cell = this.columnCell(row.querySelectorAll('td'), index)
      if (cell) cell.style.display = display
    })

    // Toggle footer cells if present
    this.table.querySelectorAll('tfoot tr').forEach(row => {
      const cell = this.columnCell(row.querySelectorAll('td, th'), index)
      if (cell) cell.style.display = display
    })
  }

  /**
   * The cell that IS column `index` in that row, or null when the index does not name it.
   *
   * The selector's index is a COLUMN POSITION —the one in the `thead`—, and in a row with
   * `colspan` that position is not the cell number: `colSpan` has to be added up until it is
   * reached. `Bali::Table` renders three rows where the count comes apart: the group band
   * (its `td` carries `colspan`, preceded or not by the select-all cell), the empty state (a
   * `td` covering the whole table) and a totals row in the `tfoot`, whose label spans several
   * columns. Only the first one carries a class of its own, so a
   * `tr:not(.bali-table-group-row)` would fix the band and leave the other two broken: that
   * is why the guard goes on the CELL and not on the row.
   *
   * By raw index the wrong thing was hidden: the whole band —with the folding button inside
   * it, and with `collapsed_groups:` its rows left unreachable without a reload—, the "no
   * results" message, or —in the `tfoot`— the total of the column next to it.
   *
   * KNOWN LIMIT, measured and not assumed: what tells those rows apart is that their cell
   * spans MORE than one column. In a table with a SINGLE visible column it does not span more
   * than one —the band comes out with `colspan="1"` and so does the empty state—, so hiding
   * that single column takes them along anyway. The CHANGELOG for #1144 keeps the measurement.
   *
   * Nor does it shrink the cell spanning a hidden column: it keeps its `colspan`, so a totals
   * row whose label covers that column ends up one column wider than the header.
   */
  columnCell (cells, index) {
    let column = 0

    for (const cell of cells) {
      if (column === index) return cell.colSpan <= 1 ? cell : null
      if (column > index) return null

      column += cell.colSpan
    }

    return null
  }
}
