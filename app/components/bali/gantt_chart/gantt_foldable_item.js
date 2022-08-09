import { Controller } from '@hotwired/stimulus'
import useDispatch from '../../../javascript/bali/utils/use-dispatch'

export class GanttFoldableItemController extends Controller {
  static targets = ['item']
  static values = {
    taskId: { type: Number, default: 0 },
    rowHeight: { type: Number, default: 35 },
    childCount: Number,
    folded: { type: Boolean, default: false }
  }

  connect () {
    useDispatch(this)
  }

  toggle () {
    this.element.classList.toggle('is-folded')

    const newHeight = this.foldedValue
      ? this.expandedHeight
      : this.rowHeightValue
    this.element.style.height = `${newHeight}px`

    this.itemTargets.forEach(item => {
      item.classList.toggle('is-hidden')
    })

    this.foldedValue = !this.foldedValue

    this.dispatch('toggle', {
      taskId: this.taskIdValue,
      folded: this.foldedValue,
      height: newHeight
    })
  }

  get expandedHeight () {
    return (this.childCountValue + 1) * this.rowHeightValue
  }
}
