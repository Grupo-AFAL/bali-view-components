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

  onItemResized (event) {
    console.log('onItemResized', event.detail)
  }

  async onItemDragged (event) {
    console.log('onItemDragged', event.detail)

    let {
      delta,
      params: { start_date, end_date, update_url }
    } = event.detail

    start_date = new Date(Date.parse(start_date))
    start_date.setDate(start_date.getDate() + delta)

    end_date = new Date(Date.parse(end_date))
    end_date.setDate(end_date.getDate() + delta)

    await patch(update_url, { body: { start_date, end_date } })
  }
}
