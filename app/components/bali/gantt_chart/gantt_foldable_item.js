import { Controller } from '@hotwired/stimulus'

export class GanttFoldableItemController extends Controller {
  static targets = ['item']
  static values = {
    rowHeight: { type: Number, default: 35 },
    childCount: Number,
    folded: { type: Boolean, default: false }
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
  }

  get expandedHeight () {
    return (this.childCountValue + 1) * this.rowHeightValue
  }
}
