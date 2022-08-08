import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'

export class GanttChartController extends Controller {
  static targets = ['timeline']

  connect () {
    console.log('Gantt charts')
  }

  onItemMoved (event) {
    console.log('onItemMoved', event)

    const timelineSortable = Sortable.get(this.timelineTarget)
    const { order } = event.detail

    timelineSortable.sort(order, true)
  }
}
