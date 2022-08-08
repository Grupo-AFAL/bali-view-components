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
    // console.log('setup', this.interactable)

    this.width = this.element.clientWidth
    this.positionX = 0
    // this.interactable = interact(this.element)
    //   .resizable({
    //     edges: {
    //       top: false,
    //       left: true,
    //       bottom: false,
    //       right: true
    //     },
    //     onmove: this.onResize,
    //     onend: this.onResizeEnd
    //   })
    //   .draggable({
    //     onmove: this.onDrag,
    //     onend: this.onDragEnd
    //   })
  }

  reset () {
    // console.log('reset', this.interactable)

    // this.interactable.unset()
    // this.interactable = undefined

    this.setup()
  }

  onResizeStart = event => {
    console.log('onResizeStart', event.clientX)
    event.preventDefault()

    this.positionX = event.clientX
    this.handle = event.params.handle

    document.onmousemove = this.onResizing
    document.onmouseup = this.onResizeEnd
  }

  onResizing = event => {
    event.preventDefault()

    // let { x } = event.target.dataset

    // x = (parseFloat(x) || 0) + event.deltaRect.left

    // console.log({ x, width: this.width, position: this.positionValue })
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

    // Object.assign(event.target.style, {
    //   width: `${event.rect.width}px`,
    //   transform: `translateX(${x}px)`
    // })

    // Object.assign(event.target.dataset, { x })
  }

  onResizeEnd = event => {
    // let { x } = event.target.dataset

    // console.log({ x })

    // const width = this.snap(event.rect.width)
    // x = this.snap(x)

    // const left = this.positionValue + x

    // Object.assign(event.target.style, {
    //   width: `${width}px`,
    //   left: `${left}px`,
    //   transform: 'translateX(0px)'
    // })

    // const startDelta = x
    // const endDelta = width - this.width + x

    // this.positionValue = left
    // this.width = width

    // console.log('onend', { startDelta, endDelta })

    // this.dispatch('onResizeEnd', { startDelta, endDelta })

    // Object.assign(event.target.dataset, { x: 0 })

    if (this.handle === 'left') {
      const diffX = this.positionX - event.clientX
      this.positionValue = this.snap(this.positionValue - diffX)
      this.width = this.snap(this.width + diffX)
    } else {
      const diffX = event.clientX - this.positionX
      this.width = this.snap(this.width + diffX)
    }

    this.element.style.left = `${this.positionValue}px`
    this.element.style.width = `${this.width}px`
    this.positionX = 0

    document.onmouseup = null
    document.onmousemove = null
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
