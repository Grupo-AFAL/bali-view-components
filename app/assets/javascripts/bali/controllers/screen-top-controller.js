import { Controller } from '@hotwired/stimulus'
import { observeTopOffset } from '../utils/top-offset.js'

// Keeps its element's top edge in `--bali-screen-top`, for host CSS that fills
// the window below it: `height: calc(100dvh - var(--bali-screen-top, 0px))`.
// What Bali::SplitView `height: :screen` does for itself, for any container.
export class ScreenTopController extends Controller {
  connect () {
    this.stopObserving = observeTopOffset(this.element, '--bali-screen-top')
  }

  disconnect () {
    this.stopObserving()
  }
}
