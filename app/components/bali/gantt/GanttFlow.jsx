// Canvas + "frame" of the Gantt island (#705, ported from afal-apps and
// decoupled from TDFlow). The SERVER (CPM scheduler) is AUTHORITATIVE: React
// never computes the schedule — it posts the edit (drag→starts_on,
// resize→duration, draw dependency) and reconciles with the returned JSON
// (cascade + critical path). Zoom/collapse/search/filter/color-by/selection
// are pure VIEW STATE (they never touch the schedule). The zoom is a data
// transform (pxPerDay), not the canvas 2D zoom, which is pinned
// (minZoom=maxZoom=1) and disabled.
//
// The island wraps in a card with a toolbar (search/filter/color-by/zoom/
// today/toggles), a columnar table on the left (GanttTable), canvas overlays
// (grid, weekend bands, group summary bars, today line+pill, row bands), a
// status footer, floating controls and a minimap. React Flow remains the
// engine for bars/edges/drag; the rest is chrome around it.
//
// Data arrives in the Bali::Gantt contract (see Bali::Gantt::Data):
// { window, groups[], items[], dependencies[], critical_ids[] } — groups nest
// one level via parent_id, items carry group_id/parent_id/name/milestone.
import { memo, useCallback, useDeferredValue, useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react'
import {
  ReactFlow,
  ReactFlowProvider,
  useNodesState,
  useEdgesState,
  useStore,
  useReactFlow,
  addEdge
} from '@xyflow/react'
import '@xyflow/react/dist/style.css'
import './flow.css'
import TaskBarNode from './TaskBarNode'
import TimeHeader, { HEADER_H } from './TimeHeader'
import GanttTable from './GanttTable'
import Toolbar from './Toolbar'
import GanttFooter from './GanttFooter'
import Minimap from './Minimap'
import {
  pxPerDayFor,
  initialZoomFromUrl,
  persistZoomInUrl,
  DEFAULT_ZOOM_PARAM,
  ZOOM_LEVELS
} from './ZoomControls'
import { useGanttModel, ROW_H, rowY, groupKey, itemKey, drawnEndsOn, DEP_PREFIX } from './useGanttModel'
import { useViewportFollow } from './useViewportFollow'
import { xToDate, daysBetween, durationDays, fmtDayMonth, weekendBands, timeTicks, addDaysIso, setDateLocale } from './timeScale'
import { legendFor, normalizeCatalogs } from './ganttColors'
import { translator } from './i18n'
import { patchItem, addDependency, removeDependency, fetchSchedule, isStale } from './scheduleClient'

const nodeTypes = { taskBar: TaskBarNode }
const ZOOM_ORDER = ['month', 'week', 'day'] // −  ...  + (more px/day = more zoom)

// Ephemeral daisyUI toast for server validation (422) or network errors.
function showErrorToast (message) {
  if (typeof document === 'undefined') return
  const toast = document.createElement('div')
  // z-index from Bali's overlay token scale: toasts live at 700.
  toast.className = 'toast toast-end toast-bottom z-[var(--bali-z-toast)]'
  const alert = document.createElement('div')
  alert.className = 'alert alert-error'
  const span = document.createElement('span')
  span.textContent = String(message) // textContent = safe by construction (no HTML)
  alert.appendChild(span)
  toast.appendChild(alert)
  document.body.appendChild(toast)
  setTimeout(() => toast.remove(), 4000)
}

// Opens a URL in the Bali drawer (AppLayout) by reusing its `drawer`
// controller with a synthetic <a href>; if the drawer is unavailable it
// navigates as fallback. Used for item detail/edit and for creation
// (New group / New item).
function openDrawerUrl (url) {
  if (!url || typeof document === 'undefined') return
  const app = typeof window !== 'undefined' ? window.Stimulus : null
  const host = document.querySelector('[data-controller~="drawer"]')
  const ctrl = app && host ? app.getControllerForElementAndIdentifier(host, 'drawer') : null
  if (ctrl && typeof ctrl.open === 'function') {
    const a = document.createElement('a')
    a.href = url
    a.setAttribute('data-turbo', 'false')
    try {
      // `open` is ASYNC in Bali v3 (`open = async (event) => {…}`) and fetches
      // inside, so a network failure becomes a rejected promise this
      // synchronous `catch` never sees: hook the fallback onto the promise.
      // `Promise.resolve` covers both shapes: if `open` ever throws
      // synchronously again, the catch below gets it.
      Promise.resolve(ctrl.open({ preventDefault () {}, currentTarget: a }))
        .catch(() => window.location.assign(url))
      return
    } catch {
      // drawer failed outright — fall through to plain navigation.
    }
  }
  window.location.assign(url)
}

function openItemDrawer (itemUrlTemplate, itemId) {
  if (!itemUrlTemplate) return
  openDrawerUrl(itemUrlTemplate.replace('__ID__', String(itemId)))
}

// ---- Canvas overlays (siblings of <ReactFlow>, synced by transform) ----

// Vertical grid + weekend bands. Reflect translateX (follow horizontal pans).
const GridBands = memo(function GridBands ({ ticks, weekend, height }) {
  const followRef = useViewportFollow('x')
  return (
    <div className='pointer-events-none absolute inset-0 z-0 overflow-hidden'>
      <div ref={followRef} className='absolute inset-y-0 left-0' style={{ willChange: 'transform' }}>
        {weekend.map((w) => (
          <div key={`we-${w.key}`} className='absolute top-0 bg-base-content/[0.035]' style={{ left: w.x, width: w.width, height }} />
        ))}
        {ticks.map((tick) => (
          <div key={`grid-${tick.key}`} className='absolute top-0 border-r border-base-content/10' style={{ left: tick.x, width: tick.width, height }} />
        ))}
      </div>
    </div>
  )
})

// Row bands: background + label of each group, and tint of selected rows.
// Reflect translateY (follow vertical scrolls).
const RowBands = memo(function RowBands ({ rows, selection }) {
  const followRef = useViewportFollow('y')
  return (
    <div className='pointer-events-none absolute inset-0 z-0 overflow-hidden'>
      <div ref={followRef} className='absolute inset-x-0 top-0' style={{ willChange: 'transform' }}>
        {rows.map((row) => {
          if (row.kind === 'group') {
            // Background band only; the group's name lives in the left table
            // (repeating it here overlapped the summary bar).
            return (
              <div
                key={`band-${row.id}`}
                className='absolute inset-x-0 border-t border-base-300 bg-base-200/70'
                style={{ top: row.rowIndex * ROW_H, height: ROW_H }}
              />
            )
          }
          if (selection.has(String(row.id))) {
            return (
              <div
                key={`sel-${row.id}`}
                className='absolute inset-x-0 bg-primary/[0.06]'
                style={{ top: row.rowIndex * ROW_H, height: ROW_H }}
              />
            )
          }
          return null
        })}
      </div>
    </div>
  )
})

// Group summary bars (rollup with triangular caps). Reflect translateX+Y.
const SummaryBars = memo(function SummaryBars ({ bars, showCritical }) {
  const followRef = useViewportFollow('xy')
  if (!bars.length) return null
  return (
    <div className='pointer-events-none absolute inset-0 z-[1] overflow-hidden'>
      <div ref={followRef} className='absolute left-0 top-0' style={{ willChange: 'transform' }}>
        {bars.map((b) => {
          const color =
            b.critical && showCritical
              ? 'color-mix(in oklch, var(--color-error) 70%, transparent)'
              : 'color-mix(in oklch, var(--color-base-content) 50%, transparent)'
          const top = b.rowIndex * ROW_H + ROW_H / 2 - 3
          const cap = { width: 0, height: 0, borderLeft: '4px solid transparent', borderRight: '4px solid transparent', borderTop: `5px solid ${color}` }
          return (
            <div key={`sum-${b.id}`} className='absolute' style={{ left: b.x, top, width: b.width, height: 6, background: color, borderRadius: 2 }}>
              <span className='absolute' style={{ left: 0, top: 5, ...cap }} />
              <span className='absolute' style={{ right: 0, top: 5, ...cap }} />
            </div>
          )
        })}
      </div>
    </div>
  )
})

// "Today" line + pill. Reflect translateX.
const TodayOverlay = memo(function TodayOverlay ({ todayXValue, label }) {
  const followRef = useViewportFollow('x', todayXValue || 0)
  if (todayXValue == null) return null
  return (
    <div className='pointer-events-none absolute inset-0 z-20 overflow-hidden'>
      <div ref={followRef} className='absolute inset-y-0 left-0 w-0'>
        <div className='absolute inset-y-0 left-0 w-0.5 bg-warning/85' />
        <div className='absolute left-0 top-0.5 grid h-4 -translate-x-1/2 place-items-center whitespace-nowrap rounded bg-warning px-1.5 text-[9px] font-bold text-warning-content'>
          {label}
        </div>
      </div>
    </div>
  )
})

// Floating buttons (bottom-left): zoom in / zoom out / fit / today.
function FloatingControls ({ onZoomIn, onZoomOut, onFit, onToday, t }) {
  const btn = 'grid h-[30px] w-8 place-items-center text-base-content/70 hover:bg-base-200'
  return (
    <div className='absolute bottom-3.5 left-3.5 z-30 flex flex-col overflow-hidden rounded-lg border border-base-300 bg-base-100 shadow-lg'>
      <button type='button' className={`${btn} border-b border-base-300`} onClick={onZoomIn} title={t('zoom_in')}>
        <svg viewBox='0 0 16 16' width='16' height='16' className='fill-current'><path d='M7 3h2v4h4v2H9v4H7V9H3V7h4z' /></svg>
      </button>
      <button type='button' className={`${btn} border-b border-base-300`} onClick={onZoomOut} title={t('zoom_out')}>
        <svg viewBox='0 0 16 16' width='16' height='16' className='fill-current'><path d='M3 7h10v2H3z' /></svg>
      </button>
      <button type='button' className={`${btn} border-b border-base-300`} onClick={onFit} title={t('fit')}>
        <svg viewBox='0 0 16 16' width='15' height='15' className='fill-current'><path d='M2 2h5v2H4v3H2V2zm12 0v5h-2V4H9V2h5zM2 9h2v3h3v2H2V9zm10 3V9h2v5H9v-2h3z' /></svg>
      </button>
      <button type='button' className={btn} onClick={onToday} title={t('go_to_today')}>
        <svg viewBox='0 0 16 16' width='14' height='14' className='fill-current'><path d='M8 1a7 7 0 100 14A7 7 0 008 1zm0 2a5 5 0 110 10A5 5 0 018 3zm0 2a3 3 0 100 6 3 3 0 000-6z' /></svg>
      </button>
    </div>
  )
}

function GanttCanvas (props) {
  const editable = Boolean(props.editable)
  const manageable = Boolean(props.manageable)
  const patchUrl = props.patchUrl
  const dependenciesUrl = props.dependenciesUrl
  const scheduleUrl = props.scheduleUrl
  const itemUrlTemplate = props.itemUrlTemplate
  const newGroupUrl = props.newGroupUrl
  const newItemUrl = props.newItemUrl
  const zoomParam = props.zoomParam || DEFAULT_ZOOM_PARAM

  const catalogs = useMemo(() => normalizeCatalogs(props.catalogs), [props.catalogs])
  const t = useMemo(() => translator(props.i18n), [props.i18n])

  const { setViewport, getViewport } = useReactFlow()
  const paneW = useStore((s) => s.width) // stable while panning (changes on resize)
  const paneH = useStore((s) => s.height)

  // --- VIEW STATE (never touches the server's schedule) ---
  const [zoom, setZoom] = useState(() => initialZoomFromUrl(zoomParam, props.initialZoom))
  const pxPerDay = pxPerDayFor(zoom)
  const [collapsedIds, setCollapsedIds] = useState(() => new Set())
  const [search, setSearch] = useState('')
  const [filterStatus, setFilterStatus] = useState('all')
  // The TOOLBAR reads the immediate values (the field echoes the keystroke at
  // once); the MODEL reads the deferred ones, so rebuilding rows/nodes/edges
  // for a 300-item document never blocks the keystroke. Same final result —
  // only the priority differs.
  const deferredSearch = useDeferredValue(search)
  const deferredFilterStatus = useDeferredValue(filterStatus)
  const [colorBy, setColorBy] = useState('status')
  const [showCritical, setShowCritical] = useState(true)
  const [showDeps, setShowDeps] = useState(true)
  const [selection, setSelection] = useState(() => new Set())
  const [tableWidth, setTableWidth] = useState(null) // null = responsive default width
  const [hiddenCols, setHiddenCols] = useState(() => new Set())

  // The authoritative schedule lives in state: it starts from the props and
  // is REPLACED with the JSON each mutation returns (reconcile).
  const [schedule, setSchedule] = useState(() => {
    const data = props.data || {}
    return {
      items: data.items || [],
      groups: data.groups || [],
      dependencies: data.dependencies || [],
      critical_ids: data.critical_ids || null,
      window: data.window || {}
    }
  })

  // `window:` is optional in the contract (Bali::Gantt::Data derives it from
  // the data when absent); the island derives the same way.
  const win = useMemo(() => {
    const w = schedule.window || {}
    if (w.starts_on && w.ends_on) return w
    const dates = []
    for (const item of schedule.items) {
      if (!item.starts_on) continue
      dates.push(item.starts_on, drawnEndsOn(item) || item.starts_on)
    }
    for (const g of schedule.groups) {
      if (!g.starts_on) continue
      dates.push(g.starts_on, g.ends_on || g.starts_on)
    }
    if (dates.length === 0) return {}
    dates.sort() // ISO dates compare lexicographically
    return { starts_on: dates[0], ends_on: dates[dates.length - 1] }
  }, [schedule])
  const windowStart = win.starts_on
  const windowEnd = win.ends_on

  const [nodes, setNodes, onNodesChange] = useNodesState([])
  const [edges, setEdges, onEdgesChange] = useEdgesState([])

  const nodesRef = useRef(nodes)
  const edgesRef = useRef(edges)
  nodesRef.current = nodes
  edgesRef.current = edges

  const applySchedule = useCallback((result) => {
    if (!result || !result.items) return
    setSchedule((prev) => ({
      items: result.items,
      groups: result.groups || prev.groups,
      dependencies: result.dependencies || [],
      critical_ids: result.critical_ids || null,
      window: result.window || {}
    }))
  }, [])

  const handleMutationError = useCallback(
    async (err, snapshot) => {
      if (err && err.statusCode === 404 && scheduleUrl) {
        try {
          const fresh = await fetchSchedule(scheduleUrl)
          applySchedule(fresh)
          showErrorToast(t('schedule_refreshed'))
          return
        } catch {
          // if the re-fetch fails too, fall through to the rollback below.
        }
      }
      if (snapshot) {
        setNodes(snapshot.nodes)
        setEdges(snapshot.edges)
      }
      showErrorToast((err && err.message) || t('change_failed'))
    },
    [scheduleUrl, applySchedule, setNodes, setEdges, t]
  )

  const handleZoomChange = useCallback((zoomKey) => {
    setZoom(zoomKey)
    persistZoomInUrl(zoomKey, zoomParam)
  }, [zoomParam])

  const handleToggle = useCallback((kind, id) => {
    const key = kind === 'group' ? groupKey(id) : itemKey(id)
    setCollapsedIds((prev) => {
      const next = new Set(prev)
      if (next.has(key)) next.delete(key)
      else next.add(key)
      return next
    })
  }, [])

  // Selection (view state): click = one; ⌘/Ctrl+click = toggle.
  const selectId = useCallback((id, e) => {
    setSelection((prev) => {
      if (e && (e.metaKey || e.ctrlKey)) {
        const next = new Set(prev)
        if (next.has(id)) next.delete(id)
        else next.add(id)
        return next
      }
      return new Set([id])
    })
  }, [])
  const openItem = useCallback((id) => openItemDrawer(itemUrlTemplate, id), [itemUrlTemplate])
  const addGroup = useCallback(() => openDrawerUrl(newGroupUrl), [newGroupUrl])
  const addItem = useCallback(() => openDrawerUrl(newItemUrl), [newItemUrl])

  // --- RESIZE (custom, from TaskBarNode): onResize(side, deltaDays) ---
  // right: changes duration (start fixed). left: moves the start and adjusts
  // the duration inversely (the end stays fixed). Optimistic + server
  // reconcile.
  const handleResize = useCallback(
    async (itemData, side, deltaDays) => {
      const dur = durationDays(itemData.starts_on, itemData.ends_on)
      let newStart = itemData.starts_on
      let newDur = dur
      if (side === 'right') {
        newDur = Math.max(1, dur + deltaDays)
      } else {
        newDur = Math.max(1, dur - deltaDays)
        newStart = addDaysIso(itemData.starts_on, dur - newDur) // the end stays fixed
      }
      if (newStart === itemData.starts_on && newDur === dur) return
      const snapshot = { nodes: nodesRef.current, edges: edgesRef.current }
      try {
        const result = await patchItem(patchUrl, { id: itemData.id, startsOn: newStart, durationDays: newDur })
        if (isStale(result)) return
        applySchedule(result)
      } catch (err) {
        await handleMutationError(err, snapshot)
      }
    },
    [patchUrl, applySchedule, handleMutationError]
  )

  // Derives rows/nodes/edges/summaryBars from the schedule (server
  // authoritative).
  const model = useGanttModel({
    groups: schedule.groups,
    items: schedule.items,
    dependencies: schedule.dependencies,
    window: win,
    pixelsPerDay: pxPerDay,
    criticalIds: schedule.critical_ids,
    collapsedIds,
    search: deferredSearch,
    filterStatus: deferredFilterStatus
  })

  // X of "today" relative to windowStart (same origin as the bars). The axis
  // extends to always cover today (see rightDays), so the line is visible.
  const todayXMemo = useMemo(() => {
    if (!windowStart) return null
    return daysBetween(windowStart, new Date().toISOString().slice(0, 10)) * pxPerDay
  }, [windowStart, pxPerDay])

  // Critical ids for the table (gated by the Critical toggle).
  const criticalIds = useMemo(() => {
    if (!showCritical) return new Set()
    return new Set((schedule.critical_ids || []).map((id) => String(id)))
  }, [schedule.critical_ids, showCritical])

  const nodeLabels = useMemo(
    () => ({
      resizeStart: t('resize_start'),
      resizeDuration: t('resize_duration'),
      dragDependency: t('drag_dependency')
    }),
    [t]
  )

  // Decoration in TWO passes, because they change at very different rates.
  // (a) everything that belongs to the bar itself — rebuilt only when the
  // schedule or a view option changes.
  const baseNodes = useMemo(
    () =>
      model.nodes.map((n) => ({
        ...n,
        draggable: editable,
        selectable: false,
        data: {
          ...n.data,
          editable,
          pxPerDay,
          colorBy,
          catalogs,
          labels: nodeLabels,
          is_critical: n.data.is_critical && showCritical,
          onResize: editable ? (side, deltaDays) => handleResize(n.data, side, deltaDays) : undefined
        }
      })),
    [model.nodes, editable, pxPerDay, colorBy, catalogs, nodeLabels, showCritical, handleResize]
  )

  // (b) the `selected` BIT, which changes on every click. Rebuilding `data`
  // here too would hand React Flow a new object for all 300 bars per click
  // and re-render every one of them; instead the previous node object is
  // REUSED whenever its bit did not change (RF's `adoptUserNodes` keeps its
  // internal node when the user node is identical, so those bars never
  // re-render). When `baseNodes` itself changed there is nothing to reuse —
  // every node object is new anyway.
  const decoratedRef = useRef({ base: null, nodes: [] })
  const decoratedNodes = useMemo(() => {
    const previous = decoratedRef.current
    const reusable = previous.base === baseNodes ? previous.nodes : null
    const nodes = baseNodes.map((base, i) => {
      const selected = selection.has(String(base.id))
      const cached = reusable && reusable[i]
      return cached && cached.selected === selected ? cached : { ...base, selected }
    })
    decoratedRef.current = { base: baseNodes, nodes }
    return nodes
  }, [baseNodes, selection])

  const displayEdges = useMemo(() => {
    if (!showDeps) return []
    return model.edges.map((e) => ({ ...e, className: showCritical ? e.className : '' }))
  }, [model.edges, showDeps, showCritical])

  useEffect(() => {
    setNodes(decoratedNodes)
  }, [decoratedNodes, setNodes])
  useEffect(() => {
    setEdges(displayEdges)
  }, [displayEdges, setEdges])

  // --- DRAG: move an item (changes starts_on) ---
  const onNodeDrag = useCallback(
    (_event, node) => {
      const ri = node.data?.rowIndex
      if (typeof ri === 'number') {
        setNodes((ns) =>
          ns.map((n) => (n.id === node.id ? { ...n, position: { x: node.position.x, y: rowY(ri) } } : n))
        )
      }
    },
    [setNodes]
  )

  const onNodeDragStop = useCallback(
    async (_event, node) => {
      if (!editable || !windowStart) return
      const startsOn = xToDate(node.position.x, windowStart, pxPerDay)
      const item = node.data
      if (item.starts_on === startsOn) return

      const prevNodes = nodesRef.current
      const prevEdges = edgesRef.current
      setNodes((ns) =>
        ns.map((n) =>
          n.id === node.id
            ? { ...n, position: node.position, className: `${n.className || ''} opacity-60`.trim() }
            : n
        )
      )

      try {
        const result = await patchItem(patchUrl, {
          id: item.id,
          startsOn,
          durationDays: durationDays(item.starts_on, item.ends_on)
        })
        if (isStale(result)) return
        applySchedule(result)
      } catch (err) {
        await handleMutationError(err, { nodes: prevNodes, edges: prevEdges })
      }
    },
    [editable, windowStart, pxPerDay, patchUrl, applySchedule, handleMutationError]
  )

  // --- CONNECT: draw a dependency (predecessor -> successor) ---
  // Defining dependencies is CPM STRUCTURE (governance) -> manageable, not
  // editable: the team can move/resize items (editable) but not rewrite the
  // topology.
  const onConnect = useCallback(
    async (connection) => {
      if (!manageable) return
      const { source, target } = connection
      if (!source || !target || source === target) return
      const prevEdges = edgesRef.current
      if (prevEdges.some((e) => e.source === source && e.target === target)) return

      setEdges((es) =>
        addEdge(
          { ...connection, sourceHandle: 'out', targetHandle: 'in', id: `optimistic-${source}-${target}`, type: 'smoothstep' },
          es
        )
      )

      try {
        const result = await addDependency(dependenciesUrl, {
          predecessorId: Number(source),
          successorId: Number(target),
          lagDays: 0
        })
        if (isStale(result)) {
          setEdges(prevEdges)
          return
        }
        applySchedule(result)
      } catch (err) {
        await handleMutationError(err, { nodes: nodesRef.current, edges: prevEdges })
      }
    },
    [manageable, dependenciesUrl, setEdges, applySchedule, handleMutationError]
  )

  // Double-click on an arrow = delete the dependency. Deleting a dependency
  // is also structure (governance) -> manageable.
  const handleDeleteDep = useCallback(
    async (_event, edge) => {
      if (!manageable || !edge || !String(edge.id).startsWith(DEP_PREFIX)) return
      const depId = String(edge.id).slice(DEP_PREFIX.length)
      const prevEdges = edgesRef.current
      const prevNodes = nodesRef.current
      setEdges((es) => es.filter((e) => e.id !== edge.id)) // optimistic
      try {
        const result = await removeDependency(dependenciesUrl, depId)
        if (isStale(result)) {
          setEdges(prevEdges)
          return
        }
        applySchedule(result)
      } catch (err) {
        await handleMutationError(err, { nodes: prevNodes, edges: prevEdges })
      }
    },
    [manageable, dependenciesUrl, setEdges, applySchedule, handleMutationError]
  )

  const onNodeClick = useCallback((event, node) => selectId(node.id, event), [selectId])
  const onNodeDoubleClick = useCallback((_event, node) => openItem(node.id), [openItem])

  // Available height / container width (React Flow demands a defined height;
  // the width decides the responsive table). Measured under the toolbar with
  // a ResizeObserver.
  const rootRef = useRef(null)
  const [availableHeight, setAvailableHeight] = useState(0)
  const [rootWidth, setRootWidth] = useState(0)
  useLayoutEffect(() => {
    const el = rootRef.current
    if (!el) return undefined
    const measure = () => {
      const rect = el.getBoundingClientRect()
      setAvailableHeight(Math.max(360, window.innerHeight - rect.top - 16))
      setRootWidth(rect.width)
    }
    measure()
    const ro = new ResizeObserver(measure)
    ro.observe(document.body)
    window.addEventListener('resize', measure)
    return () => {
      ro.disconnect()
      window.removeEventListener('resize', measure)
    }
  }, [])

  const rowsHeight = Math.max(model.rowCount, 1) * ROW_H
  const windowDays = windowStart && windowEnd ? daysBetween(windowStart, windowEnd) + 1 : 60
  // The axis extends on BOTH sides of the data range, with the ORIGIN at
  // windowStart (bars/arrows do NOT move; they stay at flow x ≥ 0). Left so
  // the user can scroll back; right to fill the width + include "today".
  // Grid/axis/today use canvasStart..axisEnd with origin=windowStart.
  const LEFT_PAD_DAYS = 21
  const RIGHT_PAD_DAYS = 14
  const todayIso = new Date().toISOString().slice(0, 10)
  const paneDays = Math.ceil((paneW || 1000) / pxPerDay) + 2
  const daysToToday = windowStart ? daysBetween(windowStart, todayIso) : 0
  const rightDays = Math.max(windowDays + RIGHT_PAD_DAYS, daysToToday + RIGHT_PAD_DAYS, LEFT_PAD_DAYS + paneDays)
  const canvasStartIso = windowStart ? addDaysIso(windowStart, -LEFT_PAD_DAYS) : windowStart
  const axisEndIso = windowStart ? addDaysIso(windowStart, rightDays) : windowEnd
  const minFlowX = -LEFT_PAD_DAYS * pxPerDay // canvasStart in flow coords (negative)
  const maxFlowX = rightDays * pxPerDay // axisEnd in flow coords
  const canvasWidthPx = maxFlowX - minFlowX
  const translateExtent = [
    [minFlowX, 0],
    [maxFlowX, rowsHeight]
  ]

  // Table width: adjustable via the splitter (tableWidth) or responsive.
  const defaultTableW = rootWidth ? Math.min(520, Math.max(300, Math.round(rootWidth * 0.42))) : 380
  const effTableW = tableWidth != null ? tableWidth : defaultTableW
  const cols = useMemo(
    () => ({
      assignee: !hiddenCols.has('assignee'),
      dates: !hiddenCols.has('dates'),
      days: !hiddenCols.has('days'),
      status: !hiddenCols.has('status'),
      progress: !hiddenCols.has('progress')
    }),
    [hiddenCols]
  )

  const gridTicks = useMemo(() => timeTicks(canvasStartIso, axisEndIso, pxPerDay, zoom, windowStart), [canvasStartIso, axisEndIso, pxPerDay, zoom, windowStart])
  const weekend = useMemo(() => weekendBands(canvasStartIso, axisEndIso, pxPerDay, zoom, windowStart), [canvasStartIso, axisEndIso, pxPerDay, zoom, windowStart])
  const gridHeight = Math.max(rowsHeight, paneH || 600)

  // Splitter: drag the table's right edge to adjust its width.
  const onSplitterDown = useCallback(
    (e) => {
      e.preventDefault()
      const startX = e.clientX
      const startW = effTableW
      const move = (ev) => setTableWidth(Math.max(260, Math.min(900, startW + (ev.clientX - startX))))
      const up = () => {
        document.removeEventListener('pointermove', move)
        document.removeEventListener('pointerup', up)
      }
      document.addEventListener('pointermove', move)
      document.addEventListener('pointerup', up)
    },
    [effTableW]
  )

  // Stable identities: an inline arrow here would give `Toolbar` a new prop on
  // every canvas render and defeat its memo.
  const toggleCritical = useCallback(() => setShowCritical((v) => !v), [])
  const toggleDeps = useCallback(() => setShowDeps((v) => !v), [])

  const toggleCol = useCallback((key) => {
    setHiddenCols((prev) => {
      const next = new Set(prev)
      if (next.has(key)) next.delete(key)
      else next.add(key)
      return next
    })
  }, [])

  // Viewport clamp: bounds panning to the canvas [minFlowX, maxFlowX] ×
  // [0, rowsHeight]. Horizontal: allows scrolling BACK to canvasStart (x up
  // to +leftRoom) and forward to the axis end; no overscroll beyond.
  // Vertical: y ≤ 0 (no gap above row 0).
  const clampViewport = useCallback(
    (vp) => {
      const maxRight = Math.max(0, maxFlowX - (paneW || 0))
      const leftRoom = -minFlowX // = LEFT_PAD_DAYS × pxPerDay (positive)
      const maxY = Math.max(0, rowsHeight - (paneH || 0))
      return {
        x: Math.max(-maxRight, Math.min(leftRoom, vp.x)),
        y: Math.min(0, Math.max(-maxY, vp.y))
      }
    },
    [maxFlowX, minFlowX, rowsHeight, paneW, paneH]
  )
  const onMoveEnd = useCallback(
    (_e, vp) => {
      const c = clampViewport(vp)
      if (Math.abs(c.x - vp.x) > 0.5 || Math.abs(c.y - vp.y) > 0.5) setViewport({ ...c, zoom: 1 })
    },
    [clampViewport, setViewport]
  )

  // --- Floating controls ---
  const stepZoom = useCallback(
    (dir) => {
      const i = ZOOM_ORDER.indexOf(zoom)
      const ni = Math.max(0, Math.min(ZOOM_ORDER.length - 1, (i < 0 ? 1 : i) + dir))
      handleZoomChange(ZOOM_ORDER[ni])
    },
    [zoom, handleZoomChange]
  )
  const fitView = useCallback(() => {
    const w = paneW || 1000
    let pick = 'month'
    // From most zoom to least (ZOOM_ORDER is month→day): pick the TIGHTEST
    // level that still fits; if none fits, fall back to "month". Keeps DRY
    // with ZOOM_ORDER.
    for (const z of [...ZOOM_ORDER].reverse()) {
      if (windowDays * pxPerDayFor(z) <= w - 8) {
        pick = z
        break
      }
    }
    handleZoomChange(pick)
    setViewport({ x: 0, y: 0, zoom: 1 }) // reframe to the start
  }, [paneW, windowDays, handleZoomChange, setViewport])
  const scrollToday = useCallback(() => {
    if (todayXMemo == null) return
    const w = paneW || 1000
    const desired = -(todayXMemo - w / 2)
    const x = Math.max(-Math.max(0, maxFlowX - w), Math.min(-minFlowX, desired))
    setViewport({ x, y: getViewport().y, zoom: 1 })
  }, [todayXMemo, paneW, maxFlowX, minFlowX, setViewport, getViewport])

  // Fullscreen on the Gantt card.
  const onFullscreen = useCallback(() => {
    const el = rootRef.current
    if (!el || typeof document === 'undefined') return
    if (document.fullscreenElement) document.exitFullscreen?.()
    else if (el.requestFullscreen) el.requestFullscreen()
  }, [])

  // Opens the server-rendered "no dates" drawer (#1015) by name. The event
  // MUST carry the drawer's id — a broadcast would open every shared drawer
  // on the page (#854) — and `options` is part of the contract even when
  // empty.
  const undatedDrawerId = props.undatedDrawerId
  const onShowUndated = useCallback(() => {
    if (!undatedDrawerId || typeof document === 'undefined') return
    document.dispatchEvent(
      new CustomEvent('bali:drawer:open', { detail: { id: undatedDrawerId, options: {} } })
    )
  }, [undatedDrawerId])

  // The "no dates" pill opens the server-rendered drawer (#1015), so it must
  // count what THAT drawer lists — the items of the schedule the server
  // rendered — not the live one: a reconcile can change the set, but the
  // drawer's list cannot follow it, and a count that disagrees with the list
  // it opens is worse than one that ages alongside it (#1029).
  const undatedCount = useMemo(
    () => ((props.data && props.data.items) || []).filter((item) => !item.starts_on).length,
    [props.data]
  )

  // --- Footer metrics ---
  const footer = useMemo(() => {
    const leaves = schedule.items || []
    const durOf = (item) => (item.starts_on ? durationDays(item.starts_on, item.ends_on) : 0)
    const totalDur = leaves.reduce((a, item) => a + durOf(item), 0) || 1
    const wprog = Math.round(leaves.reduce((a, item) => a + durOf(item) * (item.percent_complete || 0), 0) / totalDur)
    const critCount = (schedule.critical_ids || []).length
    const durDays = windowStart && windowEnd ? daysBetween(windowStart, windowEnd) + 1 : 0
    const assignees = []
    const seen = new Set()
    for (const item of leaves) {
      if (item.assignee && !seen.has(item.assignee.id)) {
        seen.add(item.assignee.id)
        assignees.push(item.assignee)
      }
    }
    return {
      countLabel: t('items_count', { count: leaves.length }),
      undatedLabel: undatedCount > 0 ? t('undated_count', { count: undatedCount }) : '',
      progressLabel: t('progress_label', { percent: wprog }),
      criticalLabel: t('critical_count', { count: critCount }),
      rangeLabel: windowStart && windowEnd ? `${fmtDayMonth(windowStart)} → ${fmtDayMonth(windowEnd)}` : '',
      durationLabel: t('range_days', { count: durDays }),
      legend: legendFor(colorBy, {
        catalogs,
        groups: (schedule.groups || []).filter((g) => !g.parent_id),
        assignees
      })
    }
  }, [schedule, undatedCount, colorBy, windowStart, windowEnd, catalogs, t])

  return (
    <div
      ref={rootRef}
      className='flex flex-col overflow-hidden rounded-xl border border-base-300 bg-base-100 shadow-sm'
      style={{ height: availableHeight || undefined }}
    >
      <Toolbar
        search={search}
        onSearch={setSearch}
        filterStatus={filterStatus}
        onFilterStatus={setFilterStatus}
        colorBy={colorBy}
        onColorBy={setColorBy}
        zoom={zoom}
        onZoom={handleZoomChange}
        showCritical={showCritical}
        onToggleCritical={toggleCritical}
        showDeps={showDeps}
        onToggleDeps={toggleDeps}
        onToday={scrollToday}
        onFullscreen={onFullscreen}
        catalogs={catalogs}
        t={t}
        cols={cols}
        onToggleCol={toggleCol}
        manageable={manageable}
        hasGroups={schedule.groups.length > 0}
        onAddGroup={newGroupUrl ? addGroup : undefined}
        onAddItem={newItemUrl ? addItem : undefined}
      />

      <div className='flex min-h-0 flex-1'>
        <GanttTable
          rows={model.rows}
          criticalIds={criticalIds}
          selectedIds={selection}
          onToggle={handleToggle}
          onSelect={selectId}
          onOpen={openItem}
          catalogs={catalogs}
          t={t}
          headerHeight={HEADER_H}
          width={effTableW}
          cols={cols}
        />
        {/* Splitter: drag to adjust the table width. */}
        <div
          onPointerDown={onSplitterDown}
          className='w-1 shrink-0 cursor-col-resize border-r border-base-300 bg-base-200 transition-colors hover:bg-primary/40'
          title={t('splitter_hint')}
        />

        <div className='flex min-w-0 flex-1 flex-col'>
          <TimeHeader windowStart={canvasStartIso} windowEnd={axisEndIso} pxPerDay={pxPerDay} unit={zoom} origin={windowStart} />
          <div className='relative min-h-0 flex-1'>
            <GridBands ticks={gridTicks} weekend={weekend} height={gridHeight} />
            <RowBands rows={model.rows} selection={selection} />
            <SummaryBars bars={model.summaryBars} showCritical={showCritical} />
            <ReactFlow
              nodes={nodes}
              edges={edges}
              nodeTypes={nodeTypes}
              onNodesChange={onNodesChange}
              onEdgesChange={onEdgesChange}
              onNodeDrag={onNodeDrag}
              onNodeDragStop={onNodeDragStop}
              onNodeClick={onNodeClick}
              onNodeDoubleClick={onNodeDoubleClick}
              onEdgeDoubleClick={handleDeleteDep}
              onConnect={onConnect}
              onMove={onMoveEnd}
              autoPanOnNodeDrag={false}
              minZoom={1}
              maxZoom={1}
              zoomOnScroll={false}
              zoomOnPinch={false}
              zoomOnDoubleClick={false}
              panOnScroll
              translateExtent={translateExtent}
              nodesDraggable={editable}
              nodesConnectable={manageable}
              elementsSelectable={false}
              snapToGrid
              snapGrid={[pxPerDay, ROW_H]}
              onlyRenderVisibleElements
              proOptions={{ hideAttribution: true }}
              defaultViewport={{ x: 0, y: 0, zoom: 1 }}
            />
            <TodayOverlay todayXValue={todayXMemo} label={t('today')} />
            <FloatingControls
              onZoomIn={() => stepZoom(1)}
              onZoomOut={() => stepZoom(-1)}
              onFit={fitView}
              onToday={scrollToday}
              t={t}
            />
            <Minimap
              nodes={model.nodes}
              canvasWidth={canvasWidthPx}
              canvasMinX={minFlowX}
              canvasHeight={rowsHeight}
              todayXValue={todayXMemo}
              hint={t('minimap_hint')}
            />
          </div>
        </div>
      </div>

      <GanttFooter
        selectionActive={selection.size > 0}
        selectionLabel={selection.size > 0 ? t('selected', { count: selection.size }) : t('selection_none')}
        countLabel={footer.countLabel}
        undatedLabel={footer.undatedLabel}
        onShowUndated={undatedDrawerId ? onShowUndated : undefined}
        legend={footer.legend}
        rangeLabel={footer.rangeLabel}
        durationLabel={footer.durationLabel}
        criticalLabel={footer.criticalLabel}
        progressLabel={footer.progressLabel}
      />
    </div>
  )
}

export default function GanttFlow (props) {
  // date-fns formats in English unless the host asks for the one supported
  // alternative; set before any tick/label memo runs.
  setDateLocale(props.dateLocale)
  return (
    <ReactFlowProvider>
      <GanttCanvas {...props} />
    </ReactFlowProvider>
  )
}

export { ZOOM_LEVELS }
