import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'
import useDispatch from '../../../javascript/bali/utils/use-dispatch'

export class GanttChartController extends Controller {
  static targets = ['timeline']

  connect () {
    useDispatch(this)
  }

  onItemMoved (event) {
    console.log('onItemMoved', event)

    const timelineSortable = Sortable.get(this.timelineTarget)
    const { order } = event.detail

    timelineSortable.sort(order, true)
  }

  onItemResized (event) {
    console.log('onItemResized', event.detail)
  }
}
