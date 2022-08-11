import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'
import useDispatch from '../../../javascript/bali/utils/use-dispatch'
import { toBool } from '../../../javascript/bali/utils/formatters'
import { patch } from '@rails/request.js'
import LeaderLine from './leader_line'

export class GanttChartController extends Controller {
  static targets = ['timeline', 'listRow', 'timelineRow']
  static values = {
    todayOffset: Number,
    rowHeight: Number,
    zoom: String
  }

  connect () {
    useDispatch(this)

    this.timelineTarget.scrollTo({ left: this.todayOffsetValue })

    this.dependentConnections = []
    this.establishConnections()

    this.timelineTarget.addEventListener('scroll', this.repositionConnections)
    window.addEventListener('resize', this.repositionConnections)
  }

  onFold () {
    const rowData = {}

    this.listRowTargets.forEach(listRow => {
      const rowHeight = this.calculateHeight(listRow)
      const folded = toBool(listRow.dataset.ganttFoldableItemFoldedValue)

      rowData[listRow.dataset.id] = { rowHeight, folded }
      listRow.style.height = `${rowHeight}px`
    })

    this.timelineRowTargets.forEach(timelineRow => {
      const { rowHeight, folded } = rowData[timelineRow.dataset.id]

      const operation = folded ? 'add' : 'remove'
      timelineRow.classList[operation]('is-folded')
      timelineRow.style.height = `${rowHeight}px`
    })

    const anyFolded = Object.values(rowData).some(({ folded }) => folded)
    anyFolded ? this.hideConnections() : this.showConnections()

    this.repositionConnections()
  }

  calculateHeight (listRow) {
    let visibleRowCount = 0

    const visibleRows = listRow.querySelectorAll(
      '[data-gantt-foldable-item-visible-value="true"]'
    )

    visibleRows.forEach(row => {
      const parentRow = row.parentElement.closest('.gantt-chart-row')
      const parentIsNotFolded =
        parentRow && parentRow.dataset.ganttFoldableItemFoldedValue !== 'true'

      if (parentIsNotFolded) {
        visibleRowCount += 1
      }
    })

    if (listRow.dataset.ganttFoldableItemVisibleValue === 'true') {
      visibleRowCount += 1
    }

    return visibleRowCount * this.rowHeightValue
  }

  onItemReordered (event) {
    const { order, toListId } = event.detail
    const listElement = this.timelineTarget.querySelector(
      `[data-sortable-list-list-id-value='${toListId}']`
    )

    const sortable = Sortable.get(listElement)
    sortable.sort(order, true)

    // Wait for sortableList animation to finish before updating connections
    setTimeout(this.repositionConnections, 75)
  }

  onItemResizing () {
    this.repositionConnections()
  }

  async onItemResized (event) {
    this.repositionConnections()
    await this.updateTask(event.detail)
  }

  onItemDragging () {
    this.repositionConnections()
  }

  async onItemDragged (event) {
    this.repositionConnections()
    await this.updateTask(event.detail)
  }

  /* eslint-disable camelcase */
  async updateTask (detail) {
    let {
      startDelta,
      endDelta,
      params: { start_date, end_date, update_url }
    } = detail

    start_date = this.addDays(start_date, startDelta)
    end_date = this.addDays(end_date, endDelta)

    await patch(update_url, { body: { start_date, end_date } })
  }
  /* eslint-enable camelcase */

  addDays (date, days) {
    const newDate = new Date(Date.parse(date))
    newDate.setDate(newDate.getDate() + days)

    return newDate
  }

  establishConnections = () => {
    if (this.zoomValue !== 'day') return

    this.timelineRowTargets
      .filter(t => t.dataset.dependentOnId)
      .forEach(timelineRow => {
        const endCell = timelineRow.querySelector('.gantt-chart-cell-content')
        const startCell = this.timelineTarget.querySelector(
          `[data-id="${timelineRow.dataset.dependentOnId}"] .gantt-chart-cell-content`
        )

        const options = { color: '#b5b5b5', size: 2, path: 'grid' }
        const line = new LeaderLine(startCell, endCell, options)

        this.dependentConnections.push(line)
      })
  }

  repositionConnections = () => {
    this.dependentConnections.forEach(line => line.position())
  }

  hideConnections = () => {
    this.dependentConnections.forEach(line => line.hide())
  }

  showConnections = () => {
    this.dependentConnections.forEach(line => line.show())
  }
}
