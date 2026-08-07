// Custom React Flow node: one item's bar in the Gantt. Translucent fill +
// border by color-by mode, solid progress overlay, label inside (or outside
// when the bar is very short), assignee avatar when it fits, a link handle
// (primary dot on hover) and two grabbable resize handles. Colors are
// computed per color-by mode with INLINE styles (var(--color-*)/oklch) —
// never interpolated Tailwind classes (v4 purges them).
//
// A `milestone: true` item (contract decision D6) renders as a DIAMOND
// anchored on its date with the name outside. Milestones have no duration,
// so the resize handles are dropped;
// dragging (moving the date) and dependency handles remain.
import { useState } from 'react'
import { Handle, Position } from '@xyflow/react'
import { BAR_H } from './useGanttModel'
import { colorForItem, avatarColor } from './ganttColors'

export default function TaskBarNode ({ data, width, selected }) {
  const {
    name,
    percent_complete: percent = 0,
    is_critical: critical,
    milestone = false,
    editable = false,
    pxPerDay = 24,
    colorBy = 'status',
    groupIndex = 0,
    assignee,
    catalogs,
    labels = {},
    onResize
  } = data

  const col = colorForItem(data, colorBy, { groupIndex, catalogs })
  const w = Number(width) || data.barWidth || 0
  const pct = Math.max(0, Math.min(100, Number(percent) || 0))
  const shortBar = w > 0 && w < 56
  const showAvatar = Boolean(assignee) && w >= 92

  // LIVE resize preview: while dragging an edge the bar grows/shrinks
  // (instant feedback); on release, onResize posts and the server reconciles.
  const [preview, setPreview] = useState(null) // { side, deltaDays } | null

  // CUSTOM resize (instead of NodeResizeControl, whose internal positioning
  // could not be aligned nor receive the press here). Pressing an edge
  // measures the drag in days (live preview) and calls
  // onResize(side, deltaDays) on release.
  function startResize (e, side) {
    if (!editable || !onResize || e.button !== 0) return
    e.stopPropagation() // do not start the node's own drag/move
    e.preventDefault()
    const startX = e.clientX
    const move = (ev) => {
      ev.preventDefault()
      setPreview({ side, deltaDays: Math.round((ev.clientX - startX) / pxPerDay) })
    }
    const up = (ev) => {
      document.removeEventListener('pointermove', move)
      document.removeEventListener('pointerup', up)
      setPreview(null)
      const deltaDays = Math.round((ev.clientX - startX) / pxPerDay)
      if (deltaDays !== 0) onResize(side, deltaDays)
    }
    document.addEventListener('pointermove', move)
    document.addEventListener('pointerup', up)
  }

  // Bar width/shift during the resize preview (base = w).
  let previewW = null
  let previewShift = 0
  if (preview && w > 0) {
    const dpx = preview.deltaDays * pxPerDay
    if (preview.side === 'right') {
      previewW = Math.max(pxPerDay, w + dpx)
    } else {
      previewW = Math.max(pxPerDay, w - dpx)
      previewShift = w - previewW // the end stays fixed; the start moves
    }
  }

  const diamond = BAR_H - 8

  return (
    <div className='group relative h-full w-full' title={name}>
      {milestone ? (
        // Diamond on the item's date (start of the node), name outside.
        <span
          className='absolute top-1/2 z-10 -translate-y-1/2 rotate-45'
          data-milestone='true'
          style={{
            left: 2,
            width: diamond,
            height: diamond,
            background: col.solid,
            border: critical ? '1.5px solid var(--color-error)' : `1px solid ${col.border}`,
            borderRadius: 2,
            boxShadow: selected ? '0 0 0 2px var(--color-primary)' : undefined,
            cursor: editable ? 'grab' : 'pointer'
          }}
        />
      ) : (
        // Bar: fill/label/avatar (clipped).
        <div
          className='relative flex h-full w-full items-center overflow-hidden rounded-[5px]'
          style={{
            background: col.fill,
            border: critical ? '1.5px solid var(--color-error)' : `1px solid ${col.border}`,
            boxShadow: selected
              ? '0 0 0 2px var(--color-primary), 0 3px 8px color-mix(in oklch, var(--color-base-content) 22%, transparent)'
              : '0 1px 2px color-mix(in oklch, var(--color-base-content) 10%, transparent)',
            cursor: editable ? 'grab' : 'pointer',
            ...(previewW != null ? { width: `${previewW}px`, marginLeft: `${previewShift}px` } : null)
          }}
        >
          {/* Progress overlay (% complete). */}
          <div
            className='absolute inset-y-0 left-0'
            style={{ width: `${pct}%`, background: col.solid, opacity: pct > 0 ? 0.9 : 0 }}
          />
          {!shortBar && (
            <span
              className='relative z-10 truncate px-2 text-[10.5px] font-semibold text-base-content'
              style={{
                textShadow: '0 1px 1px color-mix(in oklch, var(--color-base-100) 50%, transparent)',
                paddingRight: showAvatar ? BAR_H - 2 : undefined // room for the avatar
              }}
            >
              {name}
            </span>
          )}
          {showAvatar && (
            <span
              className='absolute right-1 top-1/2 z-20 grid -translate-y-1/2 place-items-center rounded-full text-[9px] font-bold text-white'
              style={{
                width: BAR_H - 8,
                height: BAR_H - 8,
                background: avatarColor(assignee),
                border: '1.5px solid var(--color-base-100)'
              }}
              title={assignee.name}
            >
              {assignee.initials}
            </span>
          )}
        </div>
      )}

      {/* Label outside (to the right) for short bars and milestones. */}
      {(shortBar || milestone) && (
        <span
          className='pointer-events-none absolute top-0 flex h-full items-center whitespace-nowrap pl-1.5 text-[10.5px] font-medium text-base-content/70'
          style={{ left: milestone ? diamond + 6 : '100%' }}
        >
          {name}
        </span>
      )}

      {/* Target handle (left): the dot arrows ENTER through, flush to the
          left edge. Does not start a drag on press. */}
      <Handle
        id='in'
        type='target'
        position={Position.Left}
        className='!h-2 !w-2 !border-0 !bg-base-content/30'
      />
      {/* "out" source handle: FLUSH to the right edge and NOT interactive —
          only the arrows' CONNECTION point (so they leave glued to the bar).
          isConnectable=false + pointer-events:none keeps it from stealing the
          press from the resize handle. */}
      <Handle
        id='out'
        type='source'
        position={Position.Right}
        isConnectable={false}
        className='!opacity-0'
        style={{ right: 0, width: 1, minWidth: 1, height: 1, minHeight: 1, border: 'none', pointerEvents: 'none' }}
      />
      {/* LINK dot (grab): SEPARATED from the edge (right:-13) so it does not
          clash with the resize; drag it to another bar to create the
          dependency. Appears on hover/selection. The resulting arrow draws
          from "out" (flush). */}
      <Handle
        id='grab'
        type='source'
        position={Position.Right}
        className={`!h-[11px] !w-[11px] !bg-primary transition-opacity ${
          selected ? '!opacity-100' : '!opacity-0 group-hover:!opacity-100'
        }`}
        style={{ border: '2px solid var(--color-base-100)', right: -13, cursor: 'crosshair' }}
        title={labels.dragDependency}
      />

      {/* Resize (left/right): own divs on the WRAPPER, LAST (above the bar
          and the handles) and exactly aligned (top:0, height = bar). They
          receive the edge press and measure the drag in days (startResize).
          Milestones have no duration → no resize handles. */}
      {editable && !milestone && (
        <>
          <div
            onPointerDown={(e) => startResize(e, 'left')}
            className='group/rz absolute top-0 z-20 cursor-ew-resize'
            style={{ left: -2, width: 8, height: BAR_H }}
            title={labels.resizeStart}
          >
            <span className='pointer-events-none absolute inset-y-0 left-0 w-1.5 rounded-l-[5px] bg-base-content/40 opacity-0 transition-opacity group-hover:opacity-100' />
          </div>
          <div
            onPointerDown={(e) => startResize(e, 'right')}
            className='group/rz absolute top-0 z-20 cursor-ew-resize'
            style={{ right: -2, width: 8, height: BAR_H }}
            title={labels.resizeDuration}
          >
            <span className='pointer-events-none absolute inset-y-0 right-0 w-1.5 rounded-r-[5px] bg-base-content/40 opacity-0 transition-opacity group-hover:opacity-100' />
          </div>
        </>
      )}
    </div>
  )
}
