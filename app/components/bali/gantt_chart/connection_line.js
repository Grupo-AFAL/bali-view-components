const STROKE_COLOR = 'hsl(0, 0%, 71%)'
const LINE_WIDTH = 2
const ARROW_SIZE = 6

export default class ConnectionLine {
  constructor (context, parent, start, end, colWidth, rowHeight) {
    this.context = context
    this.parent = parent
    this.start = start
    this.end = end
    this.colWidth = colWidth
    this.rowHeight = rowHeight

    this.context.lineJoin = 'round'
    this.context.lineWidth = LINE_WIDTH
    this.context.strokeStyle = STROKE_COLOR
    this.context.fillStyle = STROKE_COLOR

    this.draw()
  }

  draw () {
    const { x: parentX, y: parentY } = this.parent.getBoundingClientRect()
    let {
      x: startX,
      y: startY,
      width: startWidth,
      height: startHeight
    } = this.start.getBoundingClientRect()
    let {
      x: endX,
      y: endY,
      height: endHeight
    } = this.end.getBoundingClientRect()

    startX = Math.round(startX + startWidth - parentX)
    startY = Math.round(startY + startHeight / 2 - parentY)

    endX = Math.round(endX - parentX)
    endY = Math.round(endY + endHeight / 2 - parentY)

    this.context.beginPath()

    let currentX = startX
    let currentY = startY
    const nodeSegmentWidth = Math.round(this.colWidth / 2)

    // Initial position
    this.context.moveTo(currentX, currentY)

    // Create the first segment moving out from the end of the start element.
    currentX = currentX + nodeSegmentWidth
    this.context.lineTo(currentX, currentY)

    const lastPathX = endX - nodeSegmentWidth

    // When the X position is greater than the last X position we need to move
    // down and backwards to give enough space for the last segment.
    if (currentX > lastPathX) {
      // Move down half the row height
      currentY = currentY + Math.round(this.rowHeight / 2)
      this.context.lineTo(currentX, currentY)

      // Move left the needed amount
      currentX -= currentX - lastPathX
      this.context.lineTo(currentX, currentY)
    }

    // Move down
    this.context.lineTo(currentX, endY)

    // Create last segment
    this.context.lineTo(endX, endY)

    // Finish line
    this.context.stroke()

    // Create arrow head
    this.context.beginPath()
    this.context.moveTo(endX, endY)
    this.context.lineTo(endX - ARROW_SIZE, endY + ARROW_SIZE)
    this.context.lineTo(endX - ARROW_SIZE, endY - ARROW_SIZE)
    this.context.fill()
  }
}
