import { Controller } from '@hotwired/stimulus'

// Hardcoded instead of letting `dispatch` default to `this.identifier`, so the
// public event name stays put when a host registers this controller under a
// different identifier.
const EVENT_PREFIX = 'bali:gantt-foldable-item'

export class GanttFoldableItemController extends Controller {
  static values = {
    folded: { type: Boolean, default: false },
    visible: { type: Boolean, default: true },
    parentId: { type: Number, default: 0 }
  }

  toggle () {
    this.element.classList.toggle('is-folded')

    this.directChildren.forEach(child => {
      child.dataset.ganttFoldableItemVisibleValue = this.foldedValue
    })

    this.foldedValue = !this.foldedValue

    this.dispatch('toggle', {
      prefix: EVENT_PREFIX,
      detail: { folded: this.foldedValue }
    })
  }

  get directChildren () {
    return Array.from(
      this.element.querySelectorAll(
        `[data-gantt-foldable-item-parent-id-value="${this.element.dataset.id}"]`
      )
    )
  }
}
