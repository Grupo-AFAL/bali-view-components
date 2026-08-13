// Time-axis header of the Gantt. Paints the tick bands (day / week / month by
// zoom) OUTSIDE the React Flow pane and shifts them horizontally to follow
// the viewport pan.
//
// VIEWPORT SYNC (the fiddly part): React Flow stores its transform as
// `[translateX, translateY, zoom]`. We subscribe with `useStore` and reflect
// ONLY `translateX` on the bands. Because the scale is pinned
// (minZoom=maxZoom=1) the zoom factor never enters: 1 canvas px = 1 header
// px, and the bands (in window coords × pxPerDay) stay aligned with the bars
// while panning. Must render INSIDE <ReactFlowProvider> for the store.
import { memo, useMemo } from 'react'
import { timeTicks, timeBands } from './timeScale'
import { useViewportFollow } from './useViewportFollow'

const BAND_H = 20 // upper tier (month/year context).
const TICK_H = 28 // lower tier (day/week/month).
export const HEADER_H = BAND_H + TICK_H // total two-tier header height (px).

export default memo(function TimeHeader ({ windowStart, windowEnd, pxPerDay, unit, origin = windowStart }) {
  // transform = [translateX, translateY, zoom]. Only X matters (time axis),
  // and only the band WRAPPER uses it — `useViewportFollow` writes it
  // imperatively so a pan frame does not re-render the ticks at all.
  const followRef = useViewportFollow('x')
  const ticks = useMemo(
    () => timeTicks(windowStart, windowEnd, pxPerDay, unit, origin),
    [windowStart, windowEnd, pxPerDay, unit, origin]
  )
  const bands = useMemo(
    () => timeBands(windowStart, windowEnd, pxPerDay, unit, origin),
    [windowStart, windowEnd, pxPerDay, unit, origin]
  )

  return (
    <div
      className='relative overflow-hidden border-b border-base-300 bg-base-200/60 select-none'
      style={{ height: HEADER_H }}
      aria-hidden='true'
    >
      {/* Band shifted with the viewport (same translateX as the bars). */}
      <div
        ref={followRef}
        className='absolute inset-y-0 left-0'
        style={{ willChange: 'transform' }}
      >
        {/* Upper tier: month/year context. */}
        {bands.map((band) => (
          <div
            key={`band-${band.key}`}
            className='absolute top-0 flex items-center border-r border-base-300/70 bg-base-200 text-[11px] font-semibold uppercase tracking-wide text-base-content/60'
            style={{ left: band.x, width: band.width, height: BAND_H }}
            title={band.label}
          >
            <span className='sticky left-0 truncate px-2'>{band.label}</span>
          </div>
        ))}
        {/* Lower tier: fine day/week/month ticks. */}
        {ticks.map((tick) => (
          <div
            key={`tick-${tick.key}`}
            className='absolute flex items-center justify-center border-r border-base-300/70 text-[11px] font-medium text-base-content/70'
            style={{ left: tick.x, top: BAND_H, height: TICK_H, width: tick.width }}
            title={tick.label}
          >
            <span className='truncate px-1'>{tick.label}</span>
          </div>
        ))}
      </div>
    </div>
  )
})
