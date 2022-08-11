import { Controller } from '@hotwired/stimulus'
import useDispatch from '../../../javascript/bali/utils/use-dispatch'

export class GanttFoldableItemController extends Controller {
  static values = {
    folded: { type: Boolean, default: false },
    visible: { type: Boolean, default: true }
  }

  connect () {
    useDispatch(this)
  }

  toggle () {
    this.element.classList.toggle('is-folded')

    this.rowChildren.forEach(child => {
      child.dataset.ganttFoldableItemVisibleValue = this.foldedValue
    })

    this.foldedValue = !this.foldedValue

    this.dispatch('toggle', { folded: this.foldedValue })
  }

  get rowChildren () {
    return this.element.querySelectorAll('.gantt-chart-row')
  }
}
