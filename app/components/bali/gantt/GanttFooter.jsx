// Bottom status bar of the Gantt: selection · counts · legend (per color-by)
// · range · duration · critical path · progress. Purely presentational: the
// metrics are computed in GanttFlow (already localized) and arrive as props.
import { memo } from 'react'

// Separator ("·") between metrics. At module level so React reconciles it
// instead of remounting (defining it inside render creates a new type per
// frame).
function Sep () {
  return <span className='text-base-content/30'>·</span>
}

export default memo(function GanttFooter ({
  selectionLabel = '',
  countLabel = '',
  legend = [],
  rangeLabel = '',
  durationLabel = '',
  criticalLabel = '',
  progressLabel = '',
  selectionActive = false
}) {
  return (
    <div className='flex h-8 shrink-0 items-center gap-3.5 overflow-hidden whitespace-nowrap border-t border-base-300 bg-base-200/50 px-3.5 font-mono text-[11px] text-base-content/60'>
      <span className={selectionActive ? 'font-semibold text-primary' : ''}>{selectionLabel}</span>
      <span>{countLabel}</span>

      {legend.length > 0 && (
        <div className='flex items-center gap-2.5'>
          {legend.map((l, i) => (
            <div key={`${l.label}-${i}`} className='flex items-center gap-1.5'>
              <span className='h-2.5 w-2.5 shrink-0 rounded-sm' style={{ background: l.color }} />
              <span className='whitespace-nowrap font-sans text-[11px] text-base-content/60'>{l.label}</span>
            </div>
          ))}
        </div>
      )}

      <span className='flex-1' />

      {rangeLabel && <span>{rangeLabel}</span>}
      {durationLabel && (
        <>
          <Sep />
          <span>{durationLabel}</span>
        </>
      )}
      {criticalLabel && (
        <>
          <Sep />
          <span className='font-semibold text-error'>{criticalLabel}</span>
        </>
      )}
      {progressLabel && (
        <>
          <Sep />
          <span className='font-semibold text-success'>{progressLabel}</span>
        </>
      )}
    </div>
  )
})
