import { Controller } from '@hotwired/stimulus'
import interact from 'interactjs'
import useDispatch from '../../../javascript/bali/utils/use-dispatch'

export class ResizerController extends Controller {
  static values = {
    position: Number,
    increment: { type: Number, default: 25 }
  }

  connect () {
    useDispatch(this)
    this.setup()
  }

  setup () {
    console.log('setup', this.interactable)

    this.width = this.element.clientWidth
    this.positionX = 0
    this.interactable = interact(this.element)
      .resizable({
        edges: {
          top: false,
          left: true,
          bottom: false,
          right: true
        },
        onmove: this.onResize,
        onend: this.onResizeEnd
      })
      .draggable({
        onmove: this.onDrag,
        onend: this.onDragEnd
      })
  }

  reset () {
    console.log('reset', this.interactable)

    this.interactable.unset()
    this.interactable = undefined

    this.setup()
  }

  onResize = event => {
    let { x } = event.target.dataset

    x = (parseFloat(x) || 0) + event.deltaRect.left

    console.log({ x, width: this.width, position: this.positionValue })

    Object.assign(event.target.style, {
      width: `${event.rect.width}px`,
      transform: `translateX(${x}px)`
    })

    Object.assign(event.target.dataset, { x })
  }

  onResizeEnd = event => {
    let { x } = event.target.dataset

    console.log({ x })

    const width = this.snap(event.rect.width)
    x = this.snap(x)

    const left = this.positionValue + x

    Object.assign(event.target.style, {
      width: `${width}px`,
      left: `${left}px`,
      transform: 'translateX(0px)'
    })

    const startDelta = x
    const endDelta = width - this.width + x

    this.positionValue = left
    this.width = width

    console.log('onend', { startDelta, endDelta })

    this.dispatch('onResizeEnd', { startDelta, endDelta })

    Object.assign(event.target.dataset, { x: 0 })
  }

  onDrag = event => {
    this.positionX += event.dx
    event.target.style.transform = `translateX(${this.positionX}px)`
  }

  onDragEnd = event => {
    console.log(event.type, event.target)

    const left = this.positionValue + this.snap(this.positionX)
    this.positionValue = left
    this.positionX = 0

    this.dispatch('onDragEnd', { left })

    Object.assign(event.target.style, {
      left: `${left}px`,
      transform: 'translateX(0px)'
    })
  }

  snap (value) {
    return Math.round(value / this.incrementValue) * this.incrementValue
  }
}
