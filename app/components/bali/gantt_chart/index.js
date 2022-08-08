import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'
import useDispatch from '../../../javascript/bali/utils/use-dispatch'

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

    // TODO: Fix resizing after reordering items
    // this.itemTargets.forEach(item => {
    //   const resizer = this.application.getControllerForElementAndIdentifier(
    //     item,
    //     'resizer'
    //   )
    //   resizer.reset()
    // })
  }

  onItemResized (event) {
    console.log('onItemResized', event.detail)
  }

  onItemDragged (event) {
    console.log('onItemDragged', event.detail)
  }
}
