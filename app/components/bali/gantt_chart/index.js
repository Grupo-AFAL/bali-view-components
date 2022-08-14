import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'
import useDispatch from '../../../javascript/bali/utils/use-dispatch'
import { toBool, toInt } from '../../../javascript/bali/utils/formatters'
import { addDaysToDate } from '../../../javascript/bali/utils/time'
import { patch } from '@rails/request.js'
import LeaderLine from './leader_line'

const TASK_NAME_PADDING = 8

export class GanttChartController extends Controller {
  static targets = [
    'list',
    'listResizer',
    'timeline',
    'listRow',
    'timelineRow',
    'timelineCell',
    'dragShadow'
  ]

  static values = {
    resourceName: String,
    todayOffset: Number,
    offset: Number,
    rowHeight: Number,
    colWidth: Number,
    zoom: String,
    listWidth: { type: Number, default: 200 }
  }

  connect () {
    useDispatch(this)

    this.setStoredListWidth()

    this.timelineTarget.scrollTo({ left: this.offsetValue })
    this.cellsById = this.timelineCellTargets.reduce((acc, target) => {
      acc[target.dataset.taskId] = target
      return acc
    }, {})

    this.cellsByParentId = this.timelineCellTargets.reduce((acc, target) => {
      acc[target.dataset.parentId] ||= []
      acc[target.dataset.parentId].push(target)
      return acc
    }, {})

    this.timelineCellTargets.forEach(cell => {
      this.setTaskNameTooLongClass({ element: cell })
    })

    this.dependentConnections = []
    this.establishConnections()

    this.timelineTarget.addEventListener('scroll', this.repositionConnections)
    this.timelineTarget.addEventListener('scroll', this.updateScroll)
    window.addEventListener('resize', this.repositionConnections)
  }

  disconnect () {
    this.removeConnections()
    this.timelineTarget.removeEventListener(
      'scroll',
      this.repositionConnections
    )
    this.timelineTarget.removeEventListener('scroll', this.updateScroll)
    window.removeEventListener('resize', this.repositionConnections)
  }

  updateScroll = () => {
    this.offsetValue = this.timelineTarget.scrollLeft
  }

  scrollToToday () {
    this.timelineTarget.scrollTo({
      left: this.todayOffsetValue - this.colWidthValue
    })
    this.updateScroll()
  }

  setStoredListWidth = () => {
    const storedListWidth = localStorage.getItem('ganttChartListWidth')
    if (storedListWidth) {
      this.listWidthValue = toInt(storedListWidth)
      this.setListWidth(this.listWidthValue)
    }
  }

  resizeListValues = event => {
    const diffX = this.listResizerPosition - event.clientX
    this.setListWidth(this.listWidthValue - diffX)
    this.repositionConnections()

    return diffX
  }

  setListWidth = width => {
    this.listTarget.style.minWidth = `${width}px`
    this.listResizerTarget.style.left = `${width - 5}px`
  }

  onResizeListStart (event) {
    event.preventDefault()

    this.listResizerPosition = event.clientX

    document.onmousemove = this.onResizingList
    document.onmouseup = this.onResizeListEnd
  }

  onResizingList = event => {
    this.resizeListValues(event)
  }

  onResizeListEnd = event => {
    this.listWidthValue = this.listWidthValue - this.resizeListValues(event)
    localStorage.setItem('ganttChartListWidth', this.listWidthValue)

    document.onmousemove = null
    document.onmouseup = null
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
    let visibleRowCount =
      listRow.dataset.ganttFoldableItemVisibleValue === 'true' ? 1 : 0

    const visibleSelector = '[data-gantt-foldable-item-visible-value="true"]'
    const visibleRows = Array.from(listRow.querySelectorAll(visibleSelector))

    visibleRowCount += visibleRows.filter(
      row => !row.parentElement.closest('.is-folded')
    ).length

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

  onItemResizing (event) {
    this.updateDragShadow(event.detail)
    this.updateTaskNamePosition(event.detail)
    this.setTaskNameTooLongClass(event.detail)
    this.updateParentCell(event.detail.params.parent_id)
    this.repositionConnections()
  }

  async onItemResized (event) {
    this.hideDragShadow(event.detail)
    this.updateTaskNamePosition(event.detail)
    this.setTaskNameTooLongClass(event.detail)
    this.updateParentCell(event.detail.params.parent_id)
    this.repositionConnections()
    await this.updateTask(event.detail)
  }

  onItemDragging (event) {
    this.updateDragShadow(event.detail)
    this.updateParentCell(event.detail.params.parent_id)
    this.repositionConnections()
  }

  async onItemDragged (event) {
    this.hideDragShadow(event.detail)
    this.updateParentCell(event.detail.params.parent_id)
    this.repositionConnections()
    await this.updateTask(event.detail)
  }

  updateDragShadow ({ width, position }) {
    this.dragShadowTarget.style.width = `${width}px`
    this.dragShadowTarget.style.left = `${position}px`
  }

  hideDragShadow () {
    this.dragShadowTarget.style.width = '0'
  }

  async updateTask (detail) {
    const {
      startDelta,
      endDelta,
      params: {
        start_date: startDate,
        end_date: endDate,
        update_url: updateUrl
      }
    } = detail

    const attributes = {
      start_date: addDaysToDate(startDate, startDelta),
      end_date: addDaysToDate(endDate, endDelta),
      offset: this.offsetValue
    }

    let body = {}
    if (this.resourceNameValue) {
      body[this.resourceNameValue] = attributes
    } else {
      body = attributes
    }

    await patch(updateUrl, { body })
  }

  updateTaskNamePosition ({ element, width }) {
    const rightTaskName = element.querySelector('.right-timeline-task-name')
    rightTaskName.style.left = `${width + TASK_NAME_PADDING}px`
  }

  setTaskNameTooLongClass ({ element }) {
    const taskName = element.querySelector('.timeline-task-name')
    const dragHandle = element.querySelector('.gantt-chart-drag-handle')

    const tooLong =
      taskName &&
      dragHandle &&
      (taskName.clientWidth > dragHandle.clientWidth ||
        dragHandle.clientWidth === 0)

    const operation = tooLong ? 'add' : 'remove'
    element.classList[operation]('task-name-too-long')
  }

  updateParentCell (parentId) {
    const parentCell = this.cellsById[parentId]
    if (!parentCell) return

    const children = this.cellsByParentId[parentId]
    const newParentLeft = Math.min(
      ...children.map(c => toInt(c.style.left.replace('px', '')))
    )
    const endPosition = Math.max(
      ...children.map(
        c =>
          toInt(c.style.width.replace('px', '')) +
          toInt(c.style.left.replace('px', ''))
      )
    )
    const newParentWidth = endPosition - newParentLeft

    parentCell.style.left = `${newParentLeft}px`
    parentCell.style.width = `${newParentWidth}px`
    parentCell.dataset.interactPositionValue = newParentLeft
    parentCell.dataset.interactWidthValue = newParentWidth

    this.updateTaskNamePosition({ element: parentCell, width: newParentWidth })

    if (parentCell.dataset.parentId) {
      this.updateParentCell(toInt(parentCell.dataset.parentId))
    }
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

        const options = { color: '#dbdbdb', size: 2, path: 'grid' }
        const line = new LeaderLine(startCell, endCell, options)

        this.dependentConnections.push(line)
      })
  }

  repositionConnections = () => {
    this.dependentConnections.forEach(line => line.position())
  }

  hideConnections = () => {
    this.dependentConnections.forEach(line => line.hide('none'))
  }

  showConnections = () => {
    this.dependentConnections.forEach(line => line.show())
  }

  removeConnections () {
    this.dependentConnections.forEach(line => line.remove())
  }
}
