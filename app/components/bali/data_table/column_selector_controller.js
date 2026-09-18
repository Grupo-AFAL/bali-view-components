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
 * Entre visita y visita persiste lo que el usuario ESCONDIÓ, junto con las columnas que había
 * en pantalla y con las que el servidor declaraba ocultas en ese momento (`column_storage.js`
 * tiene el formato y el porqué). Consecuencia práctica, que es el arreglo de #1144: el
 * controlador sólo opina sobre una columna cuando la memoria PRUEBA una decisión del usuario
 * —lo guardado difiere de lo que el servidor declaraba—; si no, la columna nace con el
 * `checked` que rindió el servidor, o sea con el `with_column(visible:)` del anfitrión.
 *
 * `checkbox.defaultChecked` es ese default: refleja el atributo `checked` que vino del
 * servidor y no se mueve ni cuando el usuario marca la casilla ni cuando la marca este código.
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

    // TRES respuestas y no dos. Con dos hay que elegir un lado para la columna sobre la que la
    // memoria no prueba nada, y los dos mienten: `false` es el defecto de #1144 —la columna
    // nueva nace oculta— y `true` pisa un `visible: false` que el anfitrión puso a propósito.
    this.eachColumnCheckbox((checkbox, index) => {
      // Primera: la memoria nunca vio esta columna, así que manda el servidor.
      if (!state.known.includes(index)) return

      // Lo que el anfitrión declaraba CUANDO se escribió la memoria. Un valor viejo no lo
      // registró (`null`) y ahí el mejor dato disponible es lo que declara ahora: atribuirle al
      // usuario una columna que el servidor ya traía oculta es justo el error a evitar.
      const declaredHidden = state.serverHidden
        ? state.serverHidden.includes(index)
        : !checkbox.defaultChecked
      const wasHidden = state.hidden.includes(index)

      // Segunda: coinciden, o sea que nadie eligió nada, y sigue mandando el servidor —que pudo
      // cambiar de opinión desde entonces—. Tercera: difieren, y esa diferencia ES la decisión
      // del usuario, en el sentido que sea.
      if (wasHidden !== declaredHidden) checkbox.checked = !wasHidden
    })

    // Un valor sin línea base —el formato viejo, o un v2 escrito antes de que existiera— se
    // reescribe UNA vez, tomando lo que quedó en pantalla: la inferencia corre una sola vez y
    // no en cada carga. Reescribir acá y no sólo en el toggle es lo que hace que la migración
    // llegue a quien nunca vuelve a abrir el menú. Es idempotente: la segunda lectura ya
    // encuentra el formato completo y lo aplica tal cual.
    if (state.stale) this.persistState()
  }

  // Se registra el estado resuelto (`hidden`) Y la declaración del servidor (`serverHidden`),
  // porque la decisión del usuario es la DIFERENCIA entre las dos. Guardar sólo `hidden`
  // convierte en preferencia suya cada `with_column(visible: false)` del anfitrión, sin que
  // haya tocado nada, y desde ese momento un `visible: true` posterior no le llega nunca.
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

  // `known` sale de las casillas presentes, no de las columnas de la tabla: lo que se recuerda
  // es lo que se puede alternar. Con `selectable:` la columna 0 es la casilla de selección, un
  // `<th>` real que el selector no declara, así que los índices arrancan en 1.
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
    // Con una vista aplicada (serverState) el toggle es un ajuste SOBRE la vista: no debe
    // volverse el default del dispositivo en localStorage.
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
   * La celda que ES la columna `index` en esa fila, o null cuando el índice no la nombra.
   *
   * El índice del selector es una POSICIÓN DE COLUMNA —la del `thead`—, y en una fila con
   * `colspan` esa posición no es el número de celda: hay que ir sumando `colSpan` hasta
   * llegar a ella. `Bali::Table` pinta tres filas donde la cuenta se separa: la banda de
   * grupo (su `td` lleva `colspan`, precedido o no por la celda del seleccionar-todo), el
   * estado vacío (un `td` que cubre la tabla entera) y una fila de totales en el `tfoot`,
   * cuya etiqueta abarca varias columnas. Solo la primera lleva clase propia, así que un
   * `tr:not(.bali-table-group-row)` arreglaría la banda y dejaría las otras dos rotas: por
   * eso la guarda va sobre la CELDA y no sobre la fila.
   *
   * Por índice crudo se escondía la cosa equivocada: la banda entera —con el botón de
   * plegado adentro, y con `collapsed_groups:` sus filas quedaban inalcanzables sin
   * recargar—, el mensaje de «no hay resultados», o —en el `tfoot`— el total de la columna
   * de al lado.
   *
   * LÍMITE CONOCIDO, medido y no supuesto: lo que distingue a esas filas es que su celda
   * abarca MÁS de una columna. En una tabla de UNA sola columna visible no abarca más de
   * una —la banda sale con `colspan="1"` y el estado vacío también—, así que esconder esa
   * única columna se los lleva igual. El CHANGELOG de #1144 guarda la medición.
   *
   * Tampoco encoge la celda que abarca una columna oculta: conserva su `colspan`, así que una fila
   * de totales cuya etiqueta cubre esa columna queda una columna más ancha que el encabezado.
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
