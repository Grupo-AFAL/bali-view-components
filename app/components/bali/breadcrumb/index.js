import { Controller } from '@hotwired/stimulus'

// `scrollWidth` and `clientWidth` are whole pixels and `scrollLeft` is not under display scaling,
// so a trail scrolled flush to an edge can read a fraction of a pixel short of it.
const EDGE = 1

// Marks the edges past which crumbs are scrolled out of view; index.css fades those edges.
export class BreadcrumbController extends Controller {
  connect () {
    this.resizeObserver = new window.ResizeObserver(() => this.update())
    this.resizeObserver.observe(this.element)
    // The nav alone looks enough and is not: the list can grow inside a box that keeps its size
    // (a web font arriving late, a crumb added by a stream).
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

    this.element.toggleAttribute('data-overflow-start', hidden - fromEnd > EDGE)
    this.element.toggleAttribute('data-overflow-end', fromEnd > EDGE)
  }
}
