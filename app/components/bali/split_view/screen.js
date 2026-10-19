import { Controller } from '@hotwired/stimulus'

// `Bali::SplitView` with `height: :screen`: the CSS fills from the split's top
// edge to the bottom of the viewport (index.css), and this keeps that edge in
// `--bali-split-top` — its offset in the page, so scrolling does not move it,
// while a banner above it, a resize or a font loading does.
export class SplitViewScreenController extends Controller {
  connect () {
    this.measure = this.measure.bind(this)
    window.addEventListener('resize', this.measure)
    // The page's size changes whenever something above the split does; the
    // split's own height changes it too, which leaves the offset as it was
    // and so writes nothing.
    this.observer = new window.ResizeObserver(this.measure)
    this.observer.observe(document.body)
    this.measure()
  }

  disconnect () {
    window.removeEventListener('resize', this.measure)
    this.observer.disconnect()
  }

  measure () {
    const top = `${Math.round(this.element.getBoundingClientRect().top + window.scrollY)}px`
    if (this.element.style.getPropertyValue('--bali-split-top') !== top) this.element.style.setProperty('--bali-split-top', top)
  }
}
