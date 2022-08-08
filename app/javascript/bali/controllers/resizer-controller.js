import { Controller } from '@hotwired/stimulus'
import interact from 'interactjs'

export class ResizerController extends Controller {
  static values = {
    position: Number,
    increment: { type: Number, default: 25 }
  }

  connect () {
    this.width = this.element.clientWidth

    interact(this.element).resizable({
      edges: {
        top: false,
        left: true,
        bottom: false,
        right: true
      },
      onmove: this.onMove,
      onend: this.onEnd
    })
  }

  onMove = event => {
    let { x } = event.target.dataset

    x = (parseFloat(x) || 0) + event.deltaRect.left

    console.log({ x })

    Object.assign(event.target.style, {
      width: `${event.rect.width}px`,
      transform: `translateX(${x}px)`
    })

    Object.assign(event.target.dataset, { x })
  }

  onEnd = event => {
    let { x } = event.target.dataset

    const width =
      Math.round(event.rect.width / this.incrementValue) * this.incrementValue
    x = Math.round(x / this.incrementValue) * this.incrementValue

    Object.assign(event.target.style, {
      width: `${width}px`,
      transform: `translateX(${x}px)`
    })

    const startDelta = x
    const endDelta = width - this.width + x

    console.log('onend', { startDelta, endDelta })

    this.dispatch('onEnd', { startDelta, endDelta })

    Object.assign(event.target.dataset, { x })
  }
}
