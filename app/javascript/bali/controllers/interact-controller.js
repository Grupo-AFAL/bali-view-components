import { Controller } from '@hotwired/stimulus'
import useDispatch from '../utils/use-dispatch'

export class InteractController extends Controller {
  static values = {
    position: Number,
    increment: { type: Number, default: 25 },
    params: { type: Object, default: {} },
    startDelta: { type: Number, default: 0 },
    endDelta: { type: Number, default: 0 }
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
    let diffX

    if (this.handle === 'left') {
      diffX = this.snap(this.positionX - event.clientX)
      this.startDeltaValue -= diffX / this.incrementValue
      this.positionValue = this.positionValue - diffX
      this.width = this.width + diffX
    } else {
      diffX = this.snap(event.clientX - this.positionX)
      this.endDeltaValue += diffX / this.incrementValue
      this.width = this.width + diffX
    }

    this.element.style.left = `${this.positionValue}px`
    this.element.style.width = `${this.width}px`

    this.dispatch('onResizeEnd', {
      params: this.paramsValue,
      position: this.positionValue,
      width: this.width,
      startDelta: this.startDeltaValue,
      endDelta: this.endDeltaValue
    })
    this.resetMovement()
  }

  onDragStart = event => {
    event.preventDefault()

    this.positionX = event.clientX

    document.onmousemove = this.onDragging
    document.onmouseup = this.onDragEnd
  }

  onDragging = event => {
    event.preventDefault()

    const diffX = this.positionX - event.clientX
    this.element.style.left = `${this.positionValue - diffX}px`
  }

  onDragEnd = event => {
    event.preventDefault()

    const diffX = this.snap(this.positionX - event.clientX)
    this.positionValue = this.positionValue - diffX
    this.element.style.left = `${this.positionValue}px`
    this.startDeltaValue -= diffX / this.incrementValue
    this.endDeltaValue -= diffX / this.incrementValue

    this.dispatch('onDragEnd', {
      params: this.paramsValue,
      position: this.positionValue,
      startDelta: this.startDeltaValue,
      endDelta: this.endDeltaValue,
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
