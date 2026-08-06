// Minimap of the Gantt: miniature bars + "today" mark + viewport rectangle;
// click/drag to navigate. Syncs with the React Flow viewport by reading its
// transform from the store and moving it with setViewport (scale pinned at
// zoom=1). Must render INSIDE <ReactFlowProvider>.
import { useCallback, useRef } from 'react'
import { useStore, useReactFlow } from '@xyflow/react'
import { ROW_H } from './useGanttModel'

const MINI_W = 204
const MINI_H = 96

export default function Minimap ({ nodes = [], canvasWidth, canvasMinX = 0, canvasHeight, todayXValue, hint }) {
  const { setViewport } = useReactFlow()
  const tx = useStore((s) => s.transform[0])
  const ty = useStore((s) => s.transform[1])
  const paneW = useStore((s) => s.width)
  const paneH = useStore((s) => s.height)
  const boxRef = useRef(null)

  const seek = useCallback(
    (clientX, clientY) => {
      const box = boxRef.current && boxRef.current.getBoundingClientRect()
      if (!box || !canvasWidth || !canvasHeight) return
      const fx = (clientX - box.left) / box.width
      const fy = (clientY - box.top) / box.height
      const targetX = canvasMinX + fx * canvasWidth // flow coord (may be negative)
      const targetY = fy * canvasHeight
      // Center the viewport on the point (RF clamps to translateExtent).
      setViewport({ x: -(targetX - paneW / 2), y: Math.min(0, -(targetY - paneH / 2)), zoom: 1 })
    },
    [canvasWidth, canvasMinX, canvasHeight, paneW, paneH, setViewport]
  )

  const onPointerDown = useCallback(
    (e) => {
      e.preventDefault()
      seek(e.clientX, e.clientY)
      const move = (ev) => seek(ev.clientX, ev.clientY)
      const up = () => {
        document.removeEventListener('pointermove', move)
        document.removeEventListener('pointerup', up)
      }
      document.addEventListener('pointermove', move)
      document.addEventListener('pointerup', up)
    },
    [seek]
  )

  if (!canvasWidth || !canvasHeight) return null

  const sx = MINI_W / canvasWidth
  const sy = MINI_H / Math.max(canvasHeight, 1)
  const vpLeft = Math.max(0, (-tx - canvasMinX) * sx)
  const vpTop = Math.max(0, -ty * sy)
  const vpW = Math.min(MINI_W, (paneW || 0) * sx)
  const vpH = Math.min(MINI_H, (paneH || 0) * sy)

  return (
    <div
      ref={boxRef}
      onPointerDown={onPointerDown}
      className='absolute bottom-3.5 right-3.5 z-30 cursor-pointer overflow-hidden rounded-lg border border-base-300 bg-base-100 shadow-lg'
      style={{ width: MINI_W, height: MINI_H }}
      title={hint}
    >
      {nodes.map((n) => {
        const ri = n.data && typeof n.data.rowIndex === 'number' ? n.data.rowIndex : 0
        const crit = n.data && n.data.is_critical
        return (
          <div
            key={`mini-${n.id}`}
            className='absolute rounded-[1px]'
            style={{
              left: (n.position.x - canvasMinX) * sx,
              top: ri * ROW_H * sy,
              width: Math.max(2, n.width * sx),
              height: Math.max(2, ROW_H * sy - 1),
              background: crit ? 'var(--color-error)' : 'var(--color-primary)',
              opacity: 0.85
            }}
          />
        )
      })}
      {todayXValue != null && (
        <div
          className='absolute inset-y-0 w-px bg-warning/80'
          style={{ left: (todayXValue - canvasMinX) * sx }}
        />
      )}
      <div
        className='absolute rounded-sm border-[1.5px] border-primary bg-primary/10'
        style={{ left: vpLeft, top: vpTop, width: vpW, height: vpH }}
      />
    </div>
  )
}
