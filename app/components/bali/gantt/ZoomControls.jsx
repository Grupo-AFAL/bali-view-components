// Zoom controls of the Gantt island. The zoom is a DATA TRANSFORM, not React
// Flow's zoom (which scales both axes). Each level fixes `pxPerDay`: day 24 /
// week 8 / month 2 px per day. The KEYS are shared with
// Bali::Gantt::TimeScale, which resolves `zoom: :auto` server-side into one of
// them (a test compares the two lists). The choice persists in the URL under a
// NAMESPACED param (default `gantt_zoom`, decision D14 — never a bare `zoom`,
// which collides with any other control on the page) via history.replaceState,
// without navigating.

// Zoom levels: header band unit + pxPerDay. Order = buttons. Labels come from
// the island's i18n (`zoom_day` / `zoom_week` / `zoom_month`).
export const ZOOM_LEVELS = [
  { key: 'day', pxPerDay: 24, i18nKey: 'zoom_day' },
  { key: 'week', pxPerDay: 8, i18nKey: 'zoom_week' },
  { key: 'month', pxPerDay: 2, i18nKey: 'zoom_month' }
]

export const DEFAULT_ZOOM_PARAM = 'gantt_zoom'

export function pxPerDayFor (zoomKey) {
  return (ZOOM_LEVELS.find((z) => z.key === zoomKey) || ZOOM_LEVELS[1]).pxPerDay
}

export function normalizeZoom (value, fallback = 'week') {
  if (ZOOM_LEVELS.some((z) => z.key === value)) return value

  return ZOOM_LEVELS.some((z) => z.key === fallback) ? fallback : 'week'
}

// Reads the initial zoom from the URL (?gantt_zoom=...). With no param it takes
// `fallback`, which Bali::Gantt::Component fills with the zoom it resolved from
// the window (TimeScale's `:auto`), so the island opens at the density the
// schedule calls for instead of rescaling every bar the moment it mounts.
// Without either, "week".
export function initialZoomFromUrl (param = DEFAULT_ZOOM_PARAM, fallback = 'week') {
  if (typeof window === 'undefined') return normalizeZoom(null, fallback)
  const params = new URLSearchParams(window.location.search)
  return normalizeZoom(params.get(param), fallback)
}

// Persists the zoom in the URL without navigating (replaceState): keeps every
// other param (view, filters) and does not reload the island.
export function persistZoomInUrl (zoomKey, param = DEFAULT_ZOOM_PARAM) {
  if (typeof window === 'undefined') return
  const url = new URL(window.location.href)
  url.searchParams.set(param, zoomKey)
  window.history.replaceState(window.history.state, '', url)
}

export default function ZoomControls ({ zoom, onChange, t }) {
  return (
    <div className='join' role='group' aria-label={t('zoom_label')}>
      {ZOOM_LEVELS.map((level) => {
        const active = zoom === level.key
        return (
          <button
            key={level.key}
            type='button'
            className={`btn btn-xs join-item ${active ? 'btn-active btn-primary' : 'btn-outline'}`}
            aria-pressed={active.toString()}
            onClick={() => onChange(level.key)}
          >
            {t(level.i18nKey)}
          </button>
        )
      })}
    </div>
  )
}
