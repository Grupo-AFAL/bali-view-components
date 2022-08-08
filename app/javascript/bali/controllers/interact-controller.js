import { Controller } from '@hotwired/stimulus'
import useDispatch from '../utils/use-dispatch'

export class InteractController extends Controller {
  static values = {
    position: Number,
    increment: { type: Number, default: 25 },
    params: { type: Object, default: {} }
  }

  connect () {
    useDispatch(this)

    this.width = this.element.clientWidth
    this.positionX = 0
  }

  onResizeStart = event => {
    event.preventDefault()

    this.positionX = event.clientX
    this.handle = event.params.handle

    document.onmousemove = this.onResizing
    document.onmouseup = this.onResizeEnd
  }

  onResizing = event => {
    event.preventDefault()

    let diffX, left, width
    if (this.handle === 'left') {
      diffX = this.positionX - event.clientX
      left = this.positionValue - diffX
      width = this.width + diffX
    } else {
      diffX = event.clientX - this.positionX
      left = this.positionValue
      width = this.width + diffX
    }

    this.element.style.left = `${left}px`
    this.element.style.width = `${width}px`
  }

  onResizeEnd = event => {
    let diffX, startDelta, endDelta

    if (this.handle === 'left') {
      diffX = this.snap(this.positionX - event.clientX)
      startDelta = -diffX / this.incrementValue
      endDelta = 0

      this.positionValue = this.positionValue - diffX
      this.width = this.width + diffX
    } else {
      diffX = this.snap(event.clientX - this.positionX)
      startDelta = 0
      endDelta = diffX / this.incrementValue

      this.width = this.width + diffX
    }

    this.element.style.left = `${this.positionValue}px`
    this.element.style.width = `${this.width}px`

    this.dispatch('onResizeEnd', {
      params: this.paramsValue,
      position: this.positionValue,
      width: this.width,
      startDelta,
      endDelta
    })
    this.resetMovement()
  }

  onDragStart = event => {
    this.positionX = event.clientX

    document.onmousemove = this.onDragging
    document.onmouseup = this.onDragEnd
  }

  onDragging = event => {
    const diffX = this.positionX - event.clientX
    this.element.style.left = `${this.positionValue - diffX}px`
  }

  onDragEnd = event => {
    const diffX = this.snap(this.positionX - event.clientX)
    this.positionValue = this.positionValue - diffX
    this.element.style.left = `${this.positionValue}px`

    this.dispatch('onDragEnd', {
      params: this.paramsValue,
      position: this.positionValue,
      delta: -diffX / this.incrementValue,
      width: this.width
    })
    this.resetMovement()
  }

  resetMovement = () => {
    this.positionX = 0

    document.onmouseup = null
    document.onmousemove = null
  }

  snap (value) {
    return Math.round(value / this.incrementValue) * this.incrementValue
  }
}
