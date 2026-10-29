import { Controller } from '@hotwired/stimulus'
import { observeTopOffset } from '../../../assets/javascripts/bali/utils/top-offset.js'

// `Bali::SplitView` with `height: :screen`: the CSS fills from the split's top
// edge to the bottom of the viewport (index.css), from `--bali-split-top`.
export class SplitViewScreenController extends Controller {
  connect () {
    this.stopObserving = observeTopOffset(this.element, '--bali-split-top')
  }

  disconnect () {
    this.stopObserving()
  }
}
