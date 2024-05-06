import { Controller } from '@hotwired/stimulus'
import useDispatch from 'bali/utils/use-dispatch'

const CLICK_DISTANCE_THRESHOLD = 6 // pixels
const CLICK_DURATION_THRESHOLD = 500 // miliseconds

export class InteractController extends Controller {
  static targets = ['link']
  static values = {
    position: Number,
    increment: { type: Number, default: 25 },
    params: { type: Object, default: {} },
    startDelta: { type: Number, default: 0 },
    endDelta: { type: Number, default: 0 },
    width: { type: Number, default: 0 }
  }

  connect () {
    useDispatch(this)

    this.widthValue = this.element.clientWidth
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

    let diffX, position
    if (this.handle === 'left') {
      diffX = this.positionX - event.clientX
      position = this.positionValue - diffX
    } else {
      diffX = event.clientX - this.positionX
      position = this.positionValue
    }

    const width = this.widthValue + diffX

    if (width < this.incrementValue) return

    this.element.style.left = `${position}px`
    this.element.style.width = `${width}px`

    this.dispatch('onResizing', { ...this.dispatchParams, width, position })
  }

  onResizeEnd = event => {
    let diffX

    if (this.handle === 'left') {
      diffX = this.snap(this.positionX - event.clientX)
      if (this.widthValue + diffX < this.incrementValue) {
        return this.resetMovement()
      }

      this.startDeltaValue -= diffX / this.incrementValue
      this.positionValue = this.positionValue - diffX
    } else {
      diffX = this.snap(event.clientX - this.positionX)
      if (this.widthValue + diffX < this.incrementValue) {
        return this.resetMovement()
      }

      this.endDeltaValue += diffX / this.incrementValue
    }

    this.widthValue = this.widthValue + diffX

    this.element.style.left = `${this.positionValue}px`
    this.element.style.width = `${this.widthValue}px`

    this.dispatch('onResizeEnd', this.dispatchParams)
    this.resetMovement()
  }

  onClick (event) {
    event.preventDefault()
    const diffX = this.positionX - event.clientX

    if (this.isClick(diffX)) {
      this.resetMovement()
    }
  }

  onDragStart = event => {
    event.preventDefault()

    this.positionX = event.clientX
    this.dragStartTime = Date.now()

    document.onmousemove = this.onDragging
    document.onmouseup = this.onDragEnd
  }

  onDragging = event => {
    event.preventDefault()

    const diffX = this.positionX - event.clientX
    const position = this.positionValue - diffX

    this.element.style.left = `${position}px`

    this.dispatch('onDragging', { ...this.dispatchParams, position })
  }

  onDragEnd = event => {
    event.preventDefault()

    const diffX = this.snap(this.positionX - event.clientX)

    if (this.isClick(diffX)) {
      this.element.style.left = `${this.positionValue}px`

      if (!this.hasLinkTarget) {
        this.resetMovement()
      }

      return
    }

    this.positionValue = this.positionValue - diffX
    this.element.style.left = `${this.positionValue}px`
    this.startDeltaValue -= diffX / this.incrementValue
    this.endDeltaValue -= diffX / this.incrementValue

    this.dispatch('onDragEnd', this.dispatchParams)
    this.resetMovement()
  }

  isClick = diffX => {
    const mouseDownDuration = Date.now() - this.dragStartTime

    return (
      Math.abs(diffX) < CLICK_DISTANCE_THRESHOLD &&
      mouseDownDuration < CLICK_DURATION_THRESHOLD
    )
  }

  resetMovement = () => {
    this.positionX = 0

    document.onmouseup = null
    document.onmousemove = null
  }

  snap (value) {
    return Math.round(value / this.incrementValue) * this.incrementValue
  }

  get dispatchParams () {
    return {
      element: this.element,
      params: this.paramsValue,
      position: this.positionValue,
      startDelta: this.startDeltaValue,
      endDelta: this.endDeltaValue,
      width: this.widthValue
    }
  }
}
