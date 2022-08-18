export default class ConnectionLine {
  constructor (context, parent, start, end, colWidth) {
    this.context = context
    this.parent = parent
    this.start = start
    this.end = end
    this.colWidth = colWidth

    this.draw()
  }

  draw () {
    const boundingClient = this.parent.getBoundingClientRect()
    this.parentX = boundingClient.x
    this.parentY = boundingClient.y

    let {
      x: startX,
      y: startY,
      width: startWidth,
      height: startHeight
    } = this.start.getBoundingClientRect()

    startX = Math.round(startX + startWidth - this.parentX)
    startY = Math.round(startY + startHeight / 2 - this.parentY)

    let {
      x: endX,
      y: endY,
      height: endHeight
    } = this.end.getBoundingClientRect()

    endX = Math.round(endX - this.parentX)
    endY = Math.round(endY + endHeight / 2 - this.parentY)

    this.context.lineWidth = 2
    this.context.lineJoin = 'round'
    this.context.strokeStyle = 'black'

    this.context.beginPath()
    this.context.moveTo(startX, startY)

    const endXStartPath = Math.round(startX + this.colWidth / 2)

    this.context.lineTo(endXStartPath, startY)
    this.context.lineTo(endXStartPath, endY)
    this.context.lineTo(endX, endY)
    this.context.stroke()

    // console.log({ startX, startY, endX, endY, endXStartPath })
  }
}
