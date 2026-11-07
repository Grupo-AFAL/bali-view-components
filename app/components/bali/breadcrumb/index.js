import { Controller } from '@hotwired/stimulus'

// Marks the edges past which crumbs are scrolled out of view; index.css fades those edges.
export class BreadcrumbController extends Controller {
  connect () {
    this.resizeObserver = new window.ResizeObserver(() => this.update())
    this.resizeObserver.observe(this.element)
    this.resizeObserver.observe(this.element.firstElementChild)
  }

  disconnect () {
    this.resizeObserver.disconnect()
  }

  // The reversed axis (index.css) puts the scroll origin at the trail's end, in `ltr` and `rtl`
  // alike: `scrollLeft` is 0 there and grows in magnitude toward the start, negative in `ltr`.
  update () {
    const hidden = this.element.scrollWidth - this.element.clientWidth
    const fromEnd = Math.abs(this.element.scrollLeft)

    this.element.toggleAttribute('data-overflow-start', hidden - fromEnd > 0)
    this.element.toggleAttribute('data-overflow-end', fromEnd > 0)
  }
}
