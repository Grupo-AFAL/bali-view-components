import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'
import useDispatch from '../../../javascript/bali/utils/use-dispatch'
import { patch } from '@rails/request.js'

export class GanttChartController extends Controller {
  static targets = ['timeline', 'item']

  connect () {
    useDispatch(this)
  }

  onItemReordered (event) {
    console.log('onItemReordered', event)

    const timelineSortable = Sortable.get(this.timelineTarget)
    const { order } = event.detail

    timelineSortable.sort(order, true)
  }

  async onItemResized (event) {
    console.log('onItemResized', event.detail)

    await this.updateTask(event.detail)
  }

  async onItemDragged (event) {
    console.log('onItemDragged', event.detail)

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
