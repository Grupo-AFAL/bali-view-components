import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'
import useDispatch from '../../../javascript/bali/utils/use-dispatch'
import { patch } from '@rails/request.js'

export class GanttChartController extends Controller {
  static targets = ['timeline', 'item']
  static values = {
    todayOffset: Number
  }

  connect () {
    useDispatch(this)

    this.timelineTarget.scrollTo({ left: this.todayOffsetValue / 2 })
  }

  onFold (event) {
    const { taskId, height } = event.detail
    const listElement = this.timelineTarget.querySelector(
      `[data-sortable-list-list-id-value='${taskId}']`
    )

    listElement.classList.toggle('is-hidden')
    listElement.closest('.gantt-chart-row').style.height = `${height}px`
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
