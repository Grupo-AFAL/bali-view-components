import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'
import useDispatch from '../../../javascript/bali/utils/use-dispatch'
import { patch } from '@rails/request.js'

export class GanttChartController extends Controller {
  static targets = ['timeline', 'item', 'list', 'listRow', 'timelineRow']
  static values = {
    todayOffset: Number,
    rowHeight: Number
  }

  connect () {
    useDispatch(this)

    this.timelineTarget.scrollTo({ left: this.todayOffsetValue / 2 })
  }

  onFold (event) {
    const { taskId, parentId, height } = event.detail

    console.log('onFold', { parentId })

    this.listRowTargets.forEach(listRow => {
      listRow.style.height = `${this.calculateHeight(listRow)}px`
    })

    // if (parentId > 0) {
    //   const parentList = this.listTarget.querySelector(
    //     `[data-gantt-foldable-item-task-id-value='${parentId}']`
    //   )
    //   console.log(parentList)

    //   const openInTree = parentList.querySelectorAll(
    //     '[data-controller="gantt-foldable-item"]'
    //   )

    //   const openCount = Array.from(openInTree).filter(
    //     item => item.dataset.ganttFoldableItemHiddenValue !== 'true'
    //   ).length

    //   const parentHeight = (openCount + 1) * this.rowHeightValue
    //   parentList.style.height = `${parentHeight}px`

    //   // parentList.querySelectorAll('[data-controller="gantt-foldable-item"]')
    // }

    // const timelineList = this.timelineTarget.querySelector(
    //   `[data-sortable-list-list-id-value='${taskId}']`
    // )

    // timelineList.classList.toggle('is-hidden')
    // timelineList.closest('.gantt-chart-row').style.height = `${height}px`
  }

  calculateHeight (listRow) {
    let visibleRowCount = 0

    const visibleRows = listRow.querySelectorAll(
      '[data-gantt-foldable-item-visible-value="true"]'
    )

    visibleRows.forEach(row => {
      const parentRow = row.parentElement.closest('.gantt-chart-row')
      if (
        parentRow &&
        parentRow.dataset.ganttFoldableItemFoldedValue !== 'true'
      ) {
        visibleRowCount += 1
      }

      console.log(
        'visibleRow',
        row,
        parentRow,
        parentRow.dataset.ganttFoldableItemFoldedValue
      )
    })

    if (listRow.dataset.ganttFoldableItemVisibleValue === 'true') {
      visibleRowCount += 1
    }

    console.log('listRow', listRow.dataset.ganttFoldableItemVisibleValue)

    return visibleRowCount * this.rowHeightValue
  }

  onItemReordered (event) {
    const { order, toListId } = event.detail
    const listElement = this.timelineTarget.querySelector(
      `[data-sortable-list-list-id-value='${toListId}']`
    )

    const sortable = Sortable.get(listElement)
    sortable.sort(order, true)
  }

  async onItemResized (event) {
    await this.updateTask(event.detail)
  }

  async onItemDragged (event) {
    await this.updateTask(event.detail)
  }

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

  addDays (date, days) {
    const newDate = new Date(Date.parse(date))
    newDate.setDate(newDate.getDate() + days)

    return newDate
  }
}
