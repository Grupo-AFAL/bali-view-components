// Minimap of the Gantt: miniature bars + "today" mark + viewport rectangle;
// click/drag to navigate. Syncs with the React Flow viewport by reading its
// transform from the store (imperatively — see below) and moving it with
// setViewport (scale pinned at zoom=1). Must render INSIDE
// <ReactFlowProvider>.
import { memo, useCallback, useLayoutEffect, useRef } from 'react'
import { useStore, useStoreApi, useReactFlow } from '@xyflow/react'
import { ROW_H } from './useGanttModel'

const MINI_W = 204
const MINI_H = 96

export default memo(function Minimap ({ nodes = [], canvasWidth, canvasMinX = 0, canvasHeight, todayXValue, hint }) {
  const { setViewport } = useReactFlow()
  const store = useStoreApi()
  // Pane size changes on RESIZE only, so it stays a render-time subscription;
  // the transform does not (see the viewport rectangle effect below).
  const paneW = useStore((s) => s.width)
  const paneH = useStore((s) => s.height)
  const boxRef = useRef(null)
  const viewportRef = useRef(null)

  const sx = MINI_W / canvasWidth
  const sy = MINI_H / Math.max(canvasHeight, 1)

  // Only the viewport RECTANGLE follows the pan; the miniature bars do not.
  // Writing its position imperatively keeps a pan frame from re-rendering the
  // one mini bar per item this map draws. No dependency array on purpose: the
  // map now renders so rarely that re-subscribing each time is cheaper than
  // getting the dependency list wrong (the scales and the mount of the rect
  // itself all have to re-place it).
  useLayoutEffect(() => {
    const place = ([tx, ty]) => {
      const el = viewportRef.current
      if (!el || !canvasWidth || !canvasHeight) return
      el.style.left = `${Math.max(0, (-tx - canvasMinX) * sx)}px`
      el.style.top = `${Math.max(0, -ty * sy)}px`
    }
    place(store.getState().transform)
    let previous = store.getState().transform
    return store.subscribe((state) => {
      if (state.transform === previous) return
      previous = state.transform
      place(state.transform)
    })
  })

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
        ref={viewportRef}
        className='absolute rounded-sm border-[1.5px] border-primary bg-primary/10'
        style={{ width: vpW, height: vpH }}
      />
    </div>
  )
})
