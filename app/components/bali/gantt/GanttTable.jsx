// Left table of the Gantt: a columnar table — Name (WBS + hierarchy +
// collapse), Owner (avatar), Dates, Days, Status (badge) and Progress (bar +
// %). Columns are configurable (`cols`, shown/hidden from the toolbar) and
// the table width is adjustable (splitter in GanttFlow). It shares the SAME
// `rows` list as the bars (useGanttModel, single source) → row N aligned to
// the bar at y=rowY(N). It reflects the React Flow viewport's `translateY` to
// scroll with the bars (scale pinned at zoom=1 → 1px=1px). Must render INSIDE
// <ReactFlowProvider>.
import { memo } from 'react'
import { ROW_H } from './useGanttModel'
import { statusColor, statusLabel, avatarColor } from './ganttColors'
import { fmtDayMonth, durationDays } from './timeScale'
import { useViewportFollow } from './useViewportFollow'

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
      className={`flex items-end pb-1.5 text-[10px] font-bold uppercase tracking-wide text-base-content/70 ${className}`}
      style={style}
    >
      {label}
    </div>
  )
}

const DEFAULT_COLS = { assignee: true, dates: true, days: true, status: true, progress: true }

// Widths (px) of the columns after Name. `assignee` keeps 2 px either side of `OWNER` in DejaVu
// Sans, the widest fallback measured (43.7 px; 39 in Noto Sans). `status` fits a 78 px pill,
// afal-apps' `Completada`; a longer one, such as its `Listo para revisión`, is cut short and
// carries the whole label in its title.
const COL_W = { assignee: 48, dates: 108, days: 32, status: 88, progress: 88 }

// `minWidth: 0`, or a cell grows to its content and Name gives up the room, putting every edge
// between them out of line: the padded `DAYS` header grows 6 px, a `Ready for review` pill its
// cell 21 px. With Name at its minimum, the cells after the grown one are pushed instead.
const colStyle = (key) => ({ flex: `0 0 ${COL_W[key]}px`, minWidth: 0 })

// The Name column gives way to the others down to this: the toggle, the WBS and the start of
// the name of a second-level row. Below it the header and every row wrap, and a column they
// cannot hold whole drops below Name's full height, where their `overflow-hidden` hides it. Cut
// at the table's edge instead, the first 4 px of `DAYS` showed after `DATES` at 390 px.
const NAME_MIN_W = 140

export default memo(function GanttTable ({
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
  const followRef = useViewportFollow('y')
  const critical = criticalIds || new Set()
  const selected = selectedIds || new Set()

  return (
    <div className='relative flex h-full min-h-0 flex-col overflow-hidden bg-base-100' style={{ width }}>
      {/* Column header (height = timeline header, so row 0 aligns). */}
      <div
        className='flex shrink-0 flex-wrap overflow-hidden border-b border-base-300 bg-base-200/60'
        style={{ height: headerHeight }}
      >
        <HeaderCell label={t('col_name')} className='h-full flex-1 pl-3' style={{ minWidth: NAME_MIN_W }} />
        {cols.assignee && <HeaderCell label={t('col_assignee_short')} className='justify-center' style={colStyle('assignee')} />}
        {cols.dates && <HeaderCell label={t('col_dates')} className='px-1.5' style={colStyle('dates')} />}
        {cols.days && <HeaderCell label={t('col_days')} className='justify-end px-1.5' style={colStyle('days')} />}
        {cols.status && <HeaderCell label={t('col_status')} className='px-1' style={colStyle('status')} />}
        {cols.progress && <HeaderCell label={t('col_progress')} className='pl-1 pr-3' style={colStyle('progress')} />}
      </div>

      {/* Body shifted with the viewport (same translateY as the bars). */}
      <div className='relative min-h-0 flex-1 overflow-hidden'>
        <div
          ref={followRef}
          className='absolute inset-x-0 top-0'
          style={{ willChange: 'transform' }}
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
})

// Memoized: the canvas re-renders on every drag/splitter/typing frame, and
// without this each of those frames rebuilt one Row per visible row.
const Row = memo(function Row ({ row, isCritical, isSelected, onToggle, onSelect, onOpen, catalogs, t, cols }) {
  const isGroup = row.kind === 'group'
  const item = row.item
  const label = isGroup ? row.name : item.name
  const paddingLeft = 8 + row.depth * 15
  const sc = isGroup ? null : statusColor(item.status, catalogs)
  const status = isGroup ? null : statusLabel(item.status, catalogs)
  const pct = isGroup ? 0 : Math.max(0, Math.min(100, Number(item.percent_complete) || 0))

  // Set inline, the tint outranked every `hover:` class and no row ever showed the pointer.
  // A selected row keeps its tint under it: at 16% primary the warning pill on it read 4.43:1
  // on `afal`.
  const tint = isSelected
    ? 'bg-primary/12'
    : isGroup
      ? 'bg-base-content/4 hover:bg-base-content/12'
      : 'hover:bg-base-content/8'

  return (
    <div
      className={`group absolute inset-x-0 flex cursor-pointer select-none flex-wrap overflow-hidden border-b border-base-200/70 ${tint}`}
      style={{ top: row.rowIndex * ROW_H, height: ROW_H, fontWeight: isGroup ? 700 : 400 }}
      title={label}
      onClick={isGroup ? () => onToggle(row.kind, row.id) : (e) => onSelect(String(row.id), e)}
      onDoubleClick={isGroup ? undefined : () => onOpen(String(row.id))}
    >
      {/* Name column: collapse + WBS + name (+ critical mark on the edge). */}
      <div
        className='flex h-full flex-1 items-center gap-1.5 pr-1.5'
        style={{ minWidth: NAME_MIN_W, paddingLeft, borderLeft: isCritical ? '2px solid var(--color-error)' : '2px solid transparent' }}
      >
        {row.hasChildren ? (
          <button
            type='button'
            className='flex h-4 w-4 shrink-0 items-center justify-center rounded text-base-content/55 hover:bg-base-content/8 hover:text-base-content'
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
        <span className='shrink-0 font-mono text-[10px] text-base-content/70'>{row.wbs}</span>
        <span
          className={`truncate ${isGroup ? 'text-[12.5px] text-base-content' : 'text-[12px] text-base-content/90'}`}
        >
          {label}
        </span>
      </div>

      {/* Owner: assignee avatar. */}
      {cols.assignee && (
        <div className='flex items-center justify-center' style={colStyle('assignee')}>
          {!isGroup && item.assignee && (
            <span
              className='grid h-[21px] w-[21px] place-items-center rounded-full text-[9.5px] font-bold text-white'
              style={{ background: avatarColor(item.assignee) }}
              role='img'
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
          className='flex items-center truncate px-1.5 font-mono text-[10px] text-base-content/70'
          style={colStyle('dates')}
        >
          {!isGroup && item.starts_on && item.ends_on
            ? `${fmtDayMonth(item.starts_on)} → ${fmtDayMonth(item.ends_on)}`
            : ''}
        </div>
      )}
      {cols.days && (
        <div
          className='flex items-center justify-end px-1.5 font-mono text-[11px] text-base-content/70'
          style={colStyle('days')}
        >
          {!isGroup && item.starts_on ? durationDays(item.starts_on, item.ends_on) : ''}
        </div>
      )}

      {/* Status: pill badge. */}
      {cols.status && (
        <div className='flex items-center px-1' style={colStyle('status')}>
          {!isGroup && (
            <span
              className='truncate whitespace-nowrap rounded-full px-2 py-0.5 text-[10px] font-semibold'
              style={{ color: sc.text, background: sc.fill, border: `1px solid ${sc.border}` }}
              title={status}
            >
              {status}
            </span>
          )}
        </div>
      )}

      {/* Progress: bar + %. */}
      {cols.progress && (
        <div className='flex items-center gap-1.5 pl-1 pr-3' style={colStyle('progress')}>
          {!isGroup && (
            <>
              <div className='h-[5px] flex-1 overflow-hidden rounded-full bg-base-content/10'>
                <div className='h-full rounded-full' style={{ width: `${pct}%`, background: sc.solid }} />
              </div>
              <span className='w-[26px] shrink-0 text-right font-mono text-[10px] text-base-content/70'>{pct}%</span>
            </>
          )}
        </div>
      )}
    </div>
  )
})
