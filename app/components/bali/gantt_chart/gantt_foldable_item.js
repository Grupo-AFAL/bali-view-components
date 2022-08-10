import { Controller } from '@hotwired/stimulus'
import useDispatch from '../../../javascript/bali/utils/use-dispatch'
import { toBool } from '../../../javascript/bali/utils/formatters'

export class GanttFoldableItemController extends Controller {
  static targets = ['item']
  static values = {
    taskId: { type: Number, default: 0 },
    parentId: { type: Number, default: 0 },
    rowHeight: { type: Number, default: 35 },
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

    console.log('toggle', {
      taskId: this.taskIdValue,
      parentId: this.parentIdValue,
      folded: this.foldedValue
    })

    this.dispatch('toggle', {
      taskId: this.taskIdValue,
      parentId: this.parentIdValue,
      folded: this.foldedValue
    })
  }

  get rowChildren () {
    return this.element.querySelectorAll(`.gantt-chart-row`)
  }
}
