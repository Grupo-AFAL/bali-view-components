// Left table of the Gantt: a columnar table — Name (WBS + hierarchy +
// collapse), Owner (avatar), Dates, Days, Status (badge) and Progress (bar +
// %). Columns are configurable (`cols`, shown/hidden from the toolbar) and
// the table width is adjustable (splitter in GanttFlow). It shares the SAME
// `rows` list as the bars (useGanttModel, single source) → row N aligned to
// the bar at y=rowY(N). It reflects the React Flow viewport's `translateY` to
// scroll with the bars (scale pinned at zoom=1 → 1px=1px). Must render INSIDE
// <ReactFlowProvider>.
import { useStore } from '@xyflow/react'
import { ROW_H } from './useGanttModel'
import { statusColor, statusLabel, avatarColor } from './ganttColors'
import { fmtDayMonth, durationDays } from './timeScale'

function Caret ({ collapsed }) {
  return (
    <svg
      viewBox='0 0 16 16'
      width='12'
      height='12'
      className={`shrink-0 fill-current transition-transform ${collapsed ? '' : 'rotate-90'}`}
    >
      <path d='M6 4l4 4-4 4z' />
    </svg>
  )
}

function HeaderCell ({ label, style, className = '' }) {
  return (
    <div
      className={`flex items-end pb-1.5 text-[10px] font-bold uppercase tracking-wide text-base-content/55 ${className}`}
      style={style}
    >
      {label}
    </div>
  )
}

const DEFAULT_COLS = { assignee: true, dates: true, days: true, status: true, progress: true }

export default function GanttTable ({
  rows,
  criticalIds,
  selectedIds,
  onToggle,
  onSelect,
  onOpen,
  catalogs,
  t,
  headerHeight,
  width,
  cols = DEFAULT_COLS
}) {
  const translateY = useStore((s) => s.transform[1])
  const critical = criticalIds || new Set()
  const selected = selectedIds || new Set()

  return (
    <div className='relative flex h-full min-h-0 flex-col overflow-hidden bg-base-100' style={{ width }}>
      {/* Column header (height = timeline header, so row 0 aligns). */}
      <div
        className='flex shrink-0 items-stretch border-b border-base-300 bg-base-200/60'
        style={{ height: headerHeight }}
      >
        <HeaderCell label={t('col_name')} style={{ flex: '1 1 auto', paddingLeft: 12 }} />
        {cols.assignee && <HeaderCell label={t('col_assignee_short')} style={{ flex: '0 0 38px', justifyContent: 'center' }} className='justify-center' />}
        {cols.dates && <HeaderCell label={t('col_dates')} style={{ flex: '0 0 108px' }} />}
        {cols.days && <HeaderCell label={t('col_days')} style={{ flex: '0 0 32px', justifyContent: 'flex-end' }} className='justify-end' />}
        {cols.status && <HeaderCell label={t('col_status')} style={{ flex: '0 0 76px' }} />}
        {cols.progress && <HeaderCell label={t('col_progress')} style={{ flex: '0 0 88px', paddingRight: 12 }} />}
      </div>

      {/* Body shifted with the viewport (same translateY as the bars). */}
      <div className='relative min-h-0 flex-1 overflow-hidden'>
        <div
          className='absolute inset-x-0 top-0'
          style={{ transform: `translateY(${translateY}px)`, willChange: 'transform' }}
        >
          {rows.map((row) => (
            <Row
              key={`${row.kind}-${row.id}`}
              row={row}
              isCritical={row.kind !== 'group' && critical.has(String(row.id))}
              isSelected={row.kind !== 'group' && selected.has(String(row.id))}
              onToggle={onToggle}
              onSelect={onSelect}
              onOpen={onOpen}
              catalogs={catalogs}
              t={t}
              cols={cols}
            />
          ))}
        </div>
      </div>
    </div>
  )
}

function Row ({ row, isCritical, isSelected, onToggle, onSelect, onOpen, catalogs, t, cols }) {
  const isGroup = row.kind === 'group'
  const item = row.item
  const label = isGroup ? row.name : item.name
  const paddingLeft = 8 + row.depth * 15
  const sc = isGroup ? null : statusColor(item.status, catalogs)
  const pct = isGroup ? 0 : Math.max(0, Math.min(100, Number(item.percent_complete) || 0))

  const bg = isSelected
    ? 'color-mix(in oklch, var(--color-primary) 12%, transparent)'
    : isGroup
      ? 'color-mix(in oklch, var(--color-base-content) 4%, transparent)'
      : 'transparent'

  return (
    <div
      className='group absolute inset-x-0 flex cursor-pointer select-none items-center border-b border-base-200/70 hover:bg-base-content/[0.06]'
      style={{ top: row.rowIndex * ROW_H, height: ROW_H, background: bg, fontWeight: isGroup ? 700 : 400 }}
      title={label}
      onClick={isGroup ? () => onToggle(row.kind, row.id) : (e) => onSelect(String(row.id), e)}
      onDoubleClick={isGroup ? undefined : () => onOpen(String(row.id))}
    >
      {/* Name column: collapse + WBS + name (+ critical mark on the edge). */}
      <div
        className='flex min-w-0 flex-1 items-center gap-1.5 pr-1.5'
        style={{ paddingLeft, borderLeft: isCritical ? '2px solid var(--color-error)' : '2px solid transparent' }}
      >
        {row.hasChildren ? (
          <button
            type='button'
            className='flex h-4 w-4 shrink-0 items-center justify-center rounded text-base-content/50 hover:bg-base-200 hover:text-base-content'
            onClick={(e) => {
              e.stopPropagation()
              onToggle(row.kind, row.id)
            }}
            aria-label={row.collapsed ? t('expand') : t('collapse')}
            aria-expanded={(!row.collapsed).toString()}
          >
            <Caret collapsed={row.collapsed} />
          </button>
        ) : (
          <span className='inline-block w-4 shrink-0' />
        )}
        <span className='shrink-0 font-mono text-[10px] text-base-content/40'>{row.wbs}</span>
        <span
          className={`truncate ${isGroup ? 'text-[12.5px] text-base-content' : 'text-[12px] text-base-content/90'}`}
        >
          {label}
        </span>
      </div>

      {/* Owner: assignee avatar. */}
      {cols.assignee && (
        <div className='flex shrink-0 items-center justify-center' style={{ flex: '0 0 38px' }}>
          {!isGroup && item.assignee && (
            <span
              className='grid h-[21px] w-[21px] place-items-center rounded-full text-[9.5px] font-bold text-white'
              style={{ background: avatarColor(item.assignee) }}
              title={item.assignee.name}
            >
              {item.assignee.initials}
            </span>
          )}
        </div>
      )}

      {/* Dates + Days. */}
      {cols.dates && (
        <div
          className='flex items-center truncate px-1.5 font-mono text-[10px] text-base-content/55'
          style={{ flex: '0 0 108px' }}
        >
          {!isGroup && item.starts_on && item.ends_on
            ? `${fmtDayMonth(item.starts_on)} → ${fmtDayMonth(item.ends_on)}`
            : ''}
        </div>
      )}
      {cols.days && (
        <div
          className='flex items-center justify-end px-1.5 font-mono text-[11px] text-base-content/70'
          style={{ flex: '0 0 32px' }}
        >
          {!isGroup && item.starts_on ? durationDays(item.starts_on, item.ends_on) : ''}
        </div>
      )}

      {/* Status: pill badge. */}
      {cols.status && (
        <div className='flex items-center px-1' style={{ flex: '0 0 76px' }}>
          {!isGroup && (
            <span
              className='truncate whitespace-nowrap rounded-full px-2 py-0.5 text-[10px] font-semibold'
              style={{ color: sc.text, background: sc.fill, border: `1px solid ${sc.border}` }}
            >
              {statusLabel(item.status, catalogs)}
            </span>
          )}
        </div>
      )}

      {/* Progress: bar + %. */}
      {cols.progress && (
        <div className='flex items-center gap-1.5 py-0' style={{ flex: '0 0 88px', paddingRight: 12, paddingLeft: 4 }}>
          {!isGroup && (
            <>
              <div className='h-[5px] flex-1 overflow-hidden rounded-full bg-base-content/10'>
                <div className='h-full rounded-full' style={{ width: `${pct}%`, background: sc.solid }} />
              </div>
              <span className='w-[26px] shrink-0 text-right font-mono text-[10px] text-base-content/60'>{pct}%</span>
            </>
          )}
        </div>
      )}
    </div>
  )
}
