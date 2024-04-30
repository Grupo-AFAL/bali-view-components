import { Controller } from '@hotwired/stimulus'
import useDispatch from 'bali/utils/use-dispatch'

export class GanttFoldableItemController extends Controller {
  static values = {
    folded: { type: Boolean, default: false },
    visible: { type: Boolean, default: true },
    parentId: { type: Number, default: 0 }
  }

  connect () {
    useDispatch(this)
  }

  toggle () {
    this.element.classList.toggle('is-folded')

    this.directChildren.forEach(child => {
      child.dataset.ganttFoldableItemVisibleValue = this.foldedValue
    })

    this.foldedValue = !this.foldedValue

    this.dispatch('toggle', { folded: this.foldedValue })
  }

  get directChildren () {
    return Array.from(
      this.element.querySelectorAll(
        `[data-gantt-foldable-item-parent-id-value="${this.element.dataset.id}"]`
      )
    )
  }
}
