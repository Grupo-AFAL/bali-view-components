// Toolbar of the Gantt: search · status filter · column toggles · view
// toggles (Critical/Deps) · color-by (Status/Owner/Group/Priority) · zoom
// (Day/Week/Month) · Today · fullscreen. The status filter uses a native
// <details> dropdown. Search/filter/color-by/toggles are pure VIEW STATE
// (they never touch the server's schedule). Icons are inline SVG (no icon-set
// dependency inside the React island). All texts come from the `t` translator
// (decision D12) and the status vocabulary from `catalogs` (decision D11).
import { memo, useEffect, useRef } from 'react'
import ZoomControls from './ZoomControls'
import { statusColor } from './ganttColors'

const COLOR_MODES = [
  ['status', 'color_status'],
  ['assignee', 'color_assignee'],
  ['group', 'color_group'],
  ['priority', 'color_priority']
]

const COLUMN_DEFS = [
  ['assignee', 'col_assignee'],
  ['dates', 'col_dates'],
  ['days', 'col_days'],
  ['status', 'col_status'],
  ['progress', 'col_progress']
]

function IconSearch () {
  return (
    <svg viewBox='0 0 16 16' width='14' height='14' className='shrink-0 fill-current opacity-50' aria-hidden='true'>
      <path d='M11.3 10.3l3.4 3.4-1 1-3.4-3.4a5 5 0 111-1zM7 11a4 4 0 100-8 4 4 0 000 8z' />
    </svg>
  )
}

function IconPlus () {
  return (
    <svg viewBox='0 0 16 16' width='13' height='13' className='shrink-0 fill-current' aria-hidden='true'>
      <path d='M7 7V2h2v5h5v2H9v5H7V9H2V7h5z' />
    </svg>
  )
}

function Segmented ({ options, value, onChange, ariaLabel }) {
  return (
    <div className='join' role='group' aria-label={ariaLabel}>
      {options.map(([key, label]) => {
        const active = value === key
        return (
          <button
            key={key}
            type='button'
            className={`btn btn-xs join-item ${active ? 'btn-active btn-primary' : 'btn-outline'}`}
            aria-pressed={active.toString()}
            onClick={() => onChange(key)}
          >
            {label}
          </button>
        )
      })}
    </div>
  )
}

export default memo(function Toolbar ({
  search,
  onSearch,
  filterStatus,
  onFilterStatus,
  colorBy,
  onColorBy,
  zoom,
  onZoom,
  showCritical,
  onToggleCritical,
  showDeps,
  onToggleDeps,
  onToday,
  onFullscreen,
  catalogs,
  t,
  cols = {},
  onToggleCol,
  manageable = false,
  hasGroups = false,
  onAddGroup,
  onAddItem
}) {
  // Close the <details> dropdowns on outside clicks (native <details> does not).
  const rootRef = useRef(null)
  useEffect(() => {
    const onDocDown = (e) => {
      if (!rootRef.current) return
      rootRef.current.querySelectorAll('details[open]').forEach((d) => {
        if (!d.contains(e.target)) d.open = false
      })
    }
    document.addEventListener('pointerdown', onDocDown)
    return () => document.removeEventListener('pointerdown', onDocDown)
  }, [])

  const statuses = catalogs.statuses
  const statusLabelOf = (value) => statuses.find((s) => s.value === value)?.label || value
  const filterActive = filterStatus && filterStatus !== 'all'
  const filterLabel = filterActive ? statusLabelOf(filterStatus) : t('filter')
  const filterOptions = [['all', t('all')], ...statuses.map((s) => [s.value, s.label || s.value])]

  return (
    <div ref={rootRef} className='flex flex-wrap items-center gap-2 border-b border-base-300 bg-base-100 px-3 py-2'>
      {/* Creation (over the items column): + Group / + Item. Gated by
          `manageable`; "Item" requires ≥1 group. They open the Bali drawer
          (onAdd* → openDrawerUrl). */}
      {manageable && onAddGroup && (
        <>
          <button
            type='button'
            className='btn btn-xs btn-ghost shrink-0 gap-1'
            onClick={onAddGroup}
            title={t('add_group_hint')}
          >
            <IconPlus />
            {t('add_group')}
          </button>
          {hasGroups && onAddItem && (
            <button
              type='button'
              className='btn btn-xs btn-primary shrink-0 gap-1'
              onClick={onAddItem}
              title={t('add_item_hint')}
            >
              <IconPlus />
              {t('add_item')}
            </button>
          )}
          <div className='h-4 w-px shrink-0 bg-base-content/15' />
        </>
      )}

      {/* Search by name (client-side filter). */}
      <label className='flex h-[30px] shrink-0 items-center gap-1.5 rounded-md border border-base-300 px-2'>
        <IconSearch />
        <input
          type='text'
          value={search}
          onChange={(e) => onSearch(e.target.value)}
          placeholder={t('search_placeholder')}
          className='w-[140px] border-none bg-transparent text-xs text-base-content outline-none'
        />
      </label>

      {/* Filter by status — <details> dropdown. Closes on pick. */}
      <details className='relative shrink-0'>
        <summary className={`btn btn-xs list-none gap-1 ${filterActive ? 'btn-primary btn-outline' : 'btn-ghost'}`}>
          {filterLabel}
          <svg viewBox='0 0 16 16' width='12' height='12' className='fill-current opacity-60' aria-hidden='true'>
            <path d='M4 6l4 4 4-4z' />
          </svg>
        </summary>
        <ul className='menu absolute left-0 top-full z-50 mt-1 w-48 rounded-box border border-base-300 bg-base-100 p-1.5 shadow-lg'>
          <li className='menu-title px-2 py-1 text-[10px] uppercase tracking-wide'>{t('filter_by_status')}</li>
          {filterOptions.map(([key, label]) => {
            const active = (filterStatus || 'all') === key
            const dot = key === 'all' ? null : statusColor(key, catalogs).solid
            return (
              <li key={key}>
                <button
                  type='button'
                  className={`flex items-center gap-2 text-[12.5px] ${active ? 'active' : ''}`}
                  onClick={(e) => {
                    onFilterStatus(key)
                    e.currentTarget.closest('details').open = false
                  }}
                >
                  {dot ? (
                    <span className='h-2.5 w-2.5 shrink-0 rounded-sm' style={{ background: dot }} />
                  ) : (
                    <span className='h-2.5 w-2.5 shrink-0' />
                  )}
                  <span className='flex-1 text-left'>{label}</span>
                  {active && (
                    <svg viewBox='0 0 16 16' width='13' height='13' className='fill-primary' aria-hidden='true'>
                      <path d='M6.5 11.5l-3-3 1-1 2 2 5-5 1 1z' />
                    </svg>
                  )}
                </button>
              </li>
            )
          })}
        </ul>
      </details>

      {/* Table columns (show/hide) — stays open for several toggles. */}
      <details className='relative shrink-0'>
        <summary className='btn btn-xs btn-ghost list-none gap-1'>
          {t('columns')}
          <svg viewBox='0 0 16 16' width='12' height='12' className='fill-current opacity-60' aria-hidden='true'>
            <path d='M4 6l4 4 4-4z' />
          </svg>
        </summary>
        <ul className='menu absolute left-0 top-full z-50 mt-1 w-44 rounded-box border border-base-300 bg-base-100 p-1.5 shadow-lg'>
          <li className='menu-title px-2 py-1 text-[10px] uppercase tracking-wide'>{t('show_columns')}</li>
          {COLUMN_DEFS.map(([key, i18nKey]) => {
            const on = cols[key] !== false
            return (
              <li key={key}>
                <button
                  type='button'
                  className='flex items-center gap-2 text-[12.5px]'
                  onClick={() => onToggleCol && onToggleCol(key)}
                >
                  <span className={`grid h-3.5 w-3.5 place-items-center rounded border ${on ? 'border-primary bg-primary text-primary-content' : 'border-base-content/30'}`}>
                    {on && (
                      <svg viewBox='0 0 16 16' width='10' height='10' className='fill-current' aria-hidden='true'>
                        <path d='M6.5 11.5l-3-3 1-1 2 2 5-5 1 1z' />
                      </svg>
                    )}
                  </span>
                  <span className='flex-1 text-left'>{t(i18nKey)}</span>
                </button>
              </li>
            )
          })}
        </ul>
      </details>

      <div className='h-4 w-px shrink-0 bg-base-content/15' />

      {/* View toggles. */}
      <button
        type='button'
        className={`btn btn-xs shrink-0 gap-1 ${showCritical ? 'btn-primary btn-outline' : 'btn-ghost'}`}
        aria-pressed={showCritical.toString()}
        onClick={onToggleCritical}
        title={t('critical_hint')}
      >
        {t('critical')}
      </button>
      <button
        type='button'
        className={`btn btn-xs shrink-0 gap-1 ${showDeps ? 'btn-primary btn-outline' : 'btn-ghost'}`}
        aria-pressed={showDeps.toString()}
        onClick={onToggleDeps}
        title={t('deps_hint')}
      >
        {t('deps')}
      </button>

      <span className='flex-1' />

      {/* Color-by. */}
      <span className='shrink-0 text-[10px] font-bold uppercase tracking-wide text-base-content/40'>{t('color')}</span>
      <div className='shrink-0'>
        <Segmented
          options={COLOR_MODES.map(([key, i18nKey]) => [key, t(i18nKey)])}
          value={colorBy}
          onChange={onColorBy}
          ariaLabel={t('color_by')}
        />
      </div>

      <div className='h-4 w-px shrink-0 bg-base-content/15' />

      {/* Zoom + Today. */}
      <div className='shrink-0'>
        <ZoomControls zoom={zoom} onChange={onZoom} t={t} />
      </div>
      <button type='button' className='btn btn-xs btn-ghost shrink-0 gap-1' onClick={onToday} title={t('go_to_today')}>
        {t('today')}
      </button>
      {onFullscreen && (
        <button
          type='button'
          className='btn btn-xs btn-ghost btn-square shrink-0'
          onClick={onFullscreen}
          title={t('fullscreen')}
          aria-label={t('fullscreen')}
        >
          <svg viewBox='0 0 16 16' width='15' height='15' className='fill-current' aria-hidden='true'>
            <path d='M2 2h5v2H4v3H2V2zm12 0v5h-2V4H9V2h5zM2 9h2v3h3v2H2V9zm10 3V9h2v5H9v-2h3z' />
          </svg>
        </button>
      )}
    </div>
  )
})
