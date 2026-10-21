// BPMN notation drawn as SVG in a node's own box (0,0,w,h). The canvas, the
// palette icons and the image export all draw through here, so the three can
// never disagree on what an element looks like.
//
// Colours come in a `paint` table of CSS colour strings. On the canvas they
// are daisyUI variables (theme-aware); the export resolves them first,
// because an SVG rasterised through <img> has no access to the page's custom
// properties.
import { categoryOf, CATEGORY, isBinaryDecision } from './model/catalog.js'
import { markerZone, taskMarkerAt, activityRadius } from './model/labels.js'

const soft = (token, amount = 12) => `color-mix(in oklab, var(${token}) ${amount}%, var(--color-base-100))`
// The related procedure (collapsed sub-process): grey with its [+] unless the
// host sets `--bpmn-sub-process` on the editor (AFAL SUB-01, VIS-09).
const SUB_PROCESS = 'var(--bpmn-sub-process, color-mix(in oklab, var(--color-base-content) 55%, var(--color-base-100)))'

export const LIVE_PAINT = {
  activity: { fill: soft('--color-primary', 10), stroke: 'var(--color-primary)' },
  externalActivity: { fill: 'var(--color-base-100)', stroke: 'var(--color-primary)' },
  subProcess: { fill: `color-mix(in oklab, ${SUB_PROCESS} 14%, var(--color-base-100))`, stroke: SUB_PROCESS },
  gateway: { fill: soft('--color-warning', 12), stroke: 'var(--color-warning)' },
  // The Yes/No decision, blue and without its X (AFAL COM-02).
  decision: { fill: soft('--color-info', 14), stroke: 'var(--color-info)' },
  start: { fill: soft('--color-success', 12), stroke: 'var(--color-success)' },
  intermediate: { fill: 'var(--color-base-100)', stroke: 'var(--color-warning)' },
  end: { fill: soft('--color-error', 10), stroke: 'var(--color-error)' },
  neutral: { fill: 'var(--color-base-100)', stroke: 'color-mix(in oklab, var(--color-base-content) 60%, transparent)' },
  text: 'var(--color-base-content)',
  marker: 'var(--color-base-100)'
}

function paintFor (node, paint, external) {
  const category = categoryOf(node)
  if (node.type === 'sub_process') return paint.subProcess
  if (category === CATEGORY.activity) return external ? paint.externalActivity : paint.activity
  if (isBinaryDecision(node)) return paint.decision
  if (category === CATEGORY.gateway) return paint.gateway
  if (node.type === 'start_event') return paint.start
  if (node.type === 'end_event') return paint.end
  if (category === CATEGORY.event) return paint.intermediate
  return paint.neutral
}

// ── event definitions ─────────────────────────────────────────────────────
// Drawn centred on (cx, cy) at radius r; `filled` = throwing (BPMN fills the
// glyph of a throw event and leaves a catch event's hollow).
export function EventGlyph ({ kind, cx, cy, r, color, filled, background }) {
  const s = r / 18
  const line = { stroke: color, strokeWidth: 1.4, fill: filled ? color : 'none', strokeLinejoin: 'round', strokeLinecap: 'round' }
  const p = (d) => <path d={d} transform={`translate(${cx} ${cy}) scale(${s})`} {...line} vectorEffect='non-scaling-stroke' />
  switch (kind) {
    case 'timer':
      return (
        <g>
          <circle cx={cx} cy={cy} r={r * 0.55} fill={background} stroke={color} strokeWidth={1.4} />
          <path d={`M${cx},${cy - r * 0.38} L${cx},${cy} L${cx + r * 0.28},${cy + r * 0.14}`} stroke={color} strokeWidth={1.4} fill='none' strokeLinecap='round' />
        </g>
      )
    case 'message':
      return (
        <g>
          <rect x={cx - r * 0.5} y={cy - r * 0.34} width={r} height={r * 0.68} {...line} />
          <path d={`M${cx - r * 0.5},${cy - r * 0.34} L${cx},${cy + r * 0.06} L${cx + r * 0.5},${cy - r * 0.34}`} stroke={filled ? background : color} strokeWidth={1.2} fill='none' />
        </g>
      )
    case 'conditional':
      return (
        <g>
          <rect x={cx - r * 0.38} y={cy - r * 0.48} width={r * 0.76} height={r * 0.96} stroke={color} strokeWidth={1.3} fill='none' />
          <path d={`M${cx - r * 0.22},${cy - r * 0.24}h${r * 0.44}M${cx - r * 0.22},${cy}h${r * 0.44}M${cx - r * 0.22},${cy + r * 0.24}h${r * 0.44}`} stroke={color} strokeWidth={1.2} />
        </g>
      )
    case 'signal': return p('M0,-10 L9,7 L-9,7 Z')
    case 'multiple': return p('M0,-10 L9.5,-3 L6,8 L-6,8 L-9.5,-3 Z')
    case 'parallel_multiple': return p('M-2.5,-10 h5 v7.5 h7.5 v5 h-7.5 v7.5 h-5 v-7.5 h-7.5 v-5 h7.5 Z')
    case 'escalation': return p('M0,-10 L7,9 L0,3 L-7,9 Z')
    case 'compensation': return p('M-1,-6 L-1,6 L-10,0 Z M9,-6 L9,6 L0,0 Z')
    case 'link': return p('M-8,-3.5 h8 v-5 l8,8.5 l-8,8.5 v-5 h-8 Z')
    case 'error': return p('M-8,9 L-3,-8 L2,1 L8,-9 L3,8 L-2,-1 Z')
    case 'cancel': return p('M-7,-9.5 L0,-2.5 L7,-9.5 L9.5,-7 L2.5,0 L9.5,7 L7,9.5 L0,2.5 L-7,9.5 L-9.5,7 L-2.5,0 L-9.5,-7 Z')
    case 'terminate': return <circle cx={cx} cy={cy} r={r * 0.6} fill={color} />
    default: return null
  }
}

function EventShape ({ node, w, h, paint }) {
  const colors = paintFor(node, paint)
  const cx = w / 2
  const cy = h / 2
  const r = Math.min(w, h) / 2 - 2
  const kind = node.event_definition && node.event_definition.kind
  const intermediate = node.type !== 'start_event' && node.type !== 'end_event'
  const filled = node.type === 'end_event' || node.type === 'intermediate_throw_event'
  return (
    <g>
      <circle cx={cx} cy={cy} r={r} style={{ fill: colors.fill, stroke: colors.stroke }} strokeWidth={node.type === 'end_event' ? 3.5 : 1.6} />
      {intermediate && <circle cx={cx} cy={cy} r={r - 3.5} fill='none' style={{ stroke: colors.stroke }} strokeWidth={1.4} />}
      <EventGlyph kind={kind} cx={cx} cy={cy} r={r * 0.62} color={colors.stroke} filled={filled} background={paint.marker} />
    </g>
  )
}

function GatewayShape ({ node, w, h, paint }) {
  const colors = paintFor(node, paint)
  const cx = w / 2
  const cy = h / 2
  const r = Math.min(w, h) / 2 - 1
  const k = r / 25
  const mark = { stroke: colors.stroke, strokeWidth: 3, strokeLinecap: 'round', fill: 'none' }
  let inner = null
  switch (node.type) {
    case 'exclusive_gateway':
      if (isBinaryDecision(node)) break
      inner = <path d={`M${cx - 7 * k},${cy - 7 * k} L${cx + 7 * k},${cy + 7 * k} M${cx + 7 * k},${cy - 7 * k} L${cx - 7 * k},${cy + 7 * k}`} {...mark} />
      break
    case 'parallel_gateway':
      inner = <path d={`M${cx},${cy - 10 * k} L${cx},${cy + 10 * k} M${cx - 10 * k},${cy} L${cx + 10 * k},${cy}`} {...mark} />
      break
    case 'inclusive_gateway':
      inner = <circle cx={cx} cy={cy} r={9 * k} {...mark} strokeWidth={2.6} />
      break
    case 'complex_gateway':
      inner = <path d={`M${cx},${cy - 10 * k} L${cx},${cy + 10 * k} M${cx - 10 * k},${cy} L${cx + 10 * k},${cy} M${cx - 7 * k},${cy - 7 * k} L${cx + 7 * k},${cy + 7 * k} M${cx + 7 * k},${cy - 7 * k} L${cx - 7 * k},${cy + 7 * k}`} {...mark} strokeWidth={2.4} />
      break
    case 'event_based_gateway': {
      const parallel = node.event_gateway_type === 'parallel'
      inner = (
        <g>
          <circle cx={cx} cy={cy} r={11 * k} fill='none' stroke={colors.stroke} strokeWidth={1.3} />
          {!node.instantiate && !parallel && <circle cx={cx} cy={cy} r={8.5 * k} fill='none' stroke={colors.stroke} strokeWidth={1.3} />}
          {parallel
            ? <path d={`M${cx - 2 * k},${cy - 7 * k} h${4 * k} v${5 * k} h${5 * k} v${4 * k} h${-5 * k} v${5 * k} h${-4 * k} v${-5 * k} h${-5 * k} v${-4 * k} h${5 * k} Z`} fill='none' stroke={colors.stroke} strokeWidth={1.3} strokeLinejoin='round' />
            : <path d={`M${cx},${cy - 5.5 * k} L${cx + 5.2 * k},${cy - 1.7 * k} L${cx + 3.2 * k},${cy + 4.5 * k} L${cx - 3.2 * k},${cy + 4.5 * k} L${cx - 5.2 * k},${cy - 1.7 * k} Z`} fill='none' stroke={colors.stroke} strokeWidth={1.3} />}
        </g>
      )
      break
    }
    default:
  }
  return (
    <g>
      <path d={`M${cx},${cy - r} L${cx + r},${cy} L${cx},${cy + r} L${cx - r},${cy} Z`} style={{ fill: colors.fill, stroke: colors.stroke }} strokeWidth={1.6} strokeLinejoin='round' />
      {inner}
    </g>
  )
}

// Task-type marker in the top-left corner (BPMN 2.0 §10.3.3), 16 px at `scale` 1.
export function TaskMarker ({ type, x, y, color, background, scale = 1 }) {
  const line = { stroke: color, strokeWidth: 1.3 / scale, fill: 'none', strokeLinecap: 'round', strokeLinejoin: 'round' }
  const t = `translate(${x} ${y}) scale(${scale})`
  switch (type) {
    case 'user_task':
      return <g transform={t}><circle cx={8} cy={5} r={3.2} {...line} /><path d='M2,15 C2.5,10.5 5,9 8,9 C11,9 13.5,10.5 14,15 Z' {...line} /></g>
    case 'service_task':
      return <g transform={t}><circle cx={8} cy={8} r={2.6} {...line} /><path d='M8,1.5v2.4M8,12.1v2.4M1.5,8h2.4M12.1,8h2.4M3.4,3.4l1.7,1.7M10.9,10.9l1.7,1.7M3.4,12.6l1.7-1.7M10.9,5.1l1.7-1.7' {...line} /></g>
    case 'send_task':
      return <g transform={t}><rect x={1} y={3} width={14} height={10} fill={color} stroke={color} /><path d='M1,3 L8,8.5 L15,3' stroke={background} strokeWidth={1.2} fill='none' /></g>
    case 'receive_task':
      return <g transform={t}><rect x={1} y={3} width={14} height={10} {...line} /><path d='M1,3 L8,8.5 L15,3' {...line} /></g>
    case 'script_task':
      return <g transform={t}><path d='M4,1.5 h9 c-2,2 -2,4 0,6.5 c2,2.5 2,4.5 0,6.5 h-9 c2,-2 2,-4 0,-6.5 c-2,-2.5 -2,-4.5 0,-6.5 Z M5.5,5 h5 M5.5,8 h6 M5.5,11 h5' {...line} /></g>
    case 'business_rule_task':
      return <g transform={t}><rect x={1} y={2} width={14} height={12} {...line} /><path d='M1,6 h14 M1,10 h14 M5,6 v8' {...line} /><rect x={1} y={2} width={14} height={4} fill={color} fillOpacity={0.35} stroke='none' /></g>
    case 'manual_task':
      return <g transform={t}><path d='M2,9 L2,6.5 C2,5.6 3.4,5.6 3.4,6.5 L3.4,4 C3.4,3.1 4.8,3.1 4.8,4 L4.8,3 C4.8,2.1 6.2,2.1 6.2,3 L6.2,4 L13.5,4 C14.4,4 14.4,5.4 13.5,5.4 L8.5,5.4 L14.5,5.4 C15.4,5.4 15.4,6.8 14.5,6.8 L8.5,6.8 L13.8,6.8 C14.7,6.8 14.7,8.2 13.8,8.2 L8.5,8.2 L12.5,8.2 C13.4,8.2 13.4,9.6 12.5,9.6 L4.5,9.6 C3,9.6 2,9.2 2,9 Z' {...line} /></g>
    default: return null
  }
}

const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v))

// A rounded rectangle (BPMN 2.0, Activities › Task), its corner radius a
// tenth of its height, the marker scaled with it: the canvas node (64 px
// high) and the palette icon (21 px) are the same figure. The markers keep a
// legible floor at icon size. Where they go is model/labels.js's, which the
// name inside keeps clear of; `badge` moves the task marker under the tab.
function ActivityShape ({ node, w, h, paint, external, badge }) {
  const colors = paintFor(node, paint, external)
  const sub = node.type === 'sub_process'
  const unlinked = sub && !node.reference
  const marker = taskMarkerAt(h, badge)
  const zone = markerZone(h)
  const plus = zone.size
  const plusY = h - zone.height
  return (
    <g>
      <rect
        x={1} y={1} width={w - 2} height={h - 2} rx={activityRadius(h)}
        style={{ fill: colors.fill, stroke: colors.stroke }}
        strokeWidth={sub ? 2.2 : 1.5} strokeDasharray={unlinked ? '5 3' : undefined}
      />
      <TaskMarker type={node.type} x={marker.x} y={marker.y} scale={marker.scale} color={colors.stroke} background={paint.marker} />
      {sub && (
        <g>
          <rect x={w / 2 - plus / 2} y={plusY} width={plus} height={plus} rx={1} style={{ fill: paint.marker, stroke: colors.stroke }} strokeWidth={1.2} />
          <path d={`M${w / 2},${plusY + plus * 0.22} v${plus * 0.56} M${w / 2 - plus * 0.28},${plusY + plus / 2} h${plus * 0.56}`} style={{ stroke: colors.stroke }} strokeWidth={1.2} />
        </g>
      )}
    </g>
  )
}

function DataShape ({ node, w, h, paint }) {
  const colors = paint.neutral
  const style = { fill: colors.fill, stroke: colors.stroke }
  if (node.type === 'data_store') {
    const ry = 6
    return (
      <g>
        <path d={`M1,${ry} L1,${h - ry} A${w / 2 - 1},${ry} 0 0 0 ${w - 1},${h - ry} L${w - 1},${ry}`} style={style} strokeWidth={1.4} />
        <ellipse cx={w / 2} cy={ry} rx={w / 2 - 1} ry={ry} style={style} strokeWidth={1.4} />
        <path d={`M1,${ry + 5} A${w / 2 - 1},${ry} 0 0 0 ${w - 1},${ry + 5}`} fill='none' style={{ stroke: colors.stroke }} strokeWidth={1.2} />
      </g>
    )
  }
  const fold = 10
  return (
    <g>
      <path d={`M1,1 L${w - fold},1 L${w - 1},${fold} L${w - 1},${h - 1} L1,${h - 1} Z`} style={style} strokeWidth={1.4} strokeLinejoin='round' />
      <path d={`M${w - fold},1 L${w - fold},${fold} L${w - 1},${fold}`} fill='none' style={{ stroke: colors.stroke }} strokeWidth={1.2} />
      {node.type === 'data_collection' && (
        <path d={`M${w / 2 - 5},${h - 11} v7 M${w / 2},${h - 11} v7 M${w / 2 + 5},${h - 11} v7`} style={{ stroke: colors.stroke }} strokeWidth={1.6} />
      )}
      {(node.type === 'data_input' || node.type === 'data_output') && (
        <path d='M4,8 h5 v-3 l5,5 l-5,5 v-3 h-5 Z' style={{ stroke: colors.stroke, fill: node.type === 'data_output' ? colors.stroke : 'none' }} strokeWidth={1.1} />
      )}
    </g>
  )
}

function ArtifactShape ({ node, w, h, paint }) {
  const stroke = paint.neutral.stroke
  if (node.type === 'group') {
    // Rounded rectangle, dash-dot border (BPMN 2.0, Artifacts › Group); the
    // dashes scale with it.
    const k = clamp(h / 60, 0.4, 1)
    return <rect x={1} y={1} width={w - 2} height={h - 2} rx={Math.round(h * 0.1 * 10) / 10} fill='none' style={{ stroke }} strokeWidth={1.4} strokeDasharray={[8, 4, 2, 4].map((d) => d * k).join(' ')} />
  }
  return <path d={`M14,1 L1,1 L1,${h - 1} L14,${h - 1}`} fill='none' style={{ stroke }} strokeWidth={1.5} />
}

// The app's colour on an element (`node.appearance.color`, model/appearance.js):
// its outline, and a tint over an activity's body. Drawn over NodeShape, on
// the canvas and in the outputs alike; the task marker and the [+] stay
// visible through the tint.
export function AppearanceMark ({ node, width: w, height: h, color }) {
  if (!color) return null
  const line = { fill: 'none', stroke: color, strokeWidth: 2.6 }
  const category = categoryOf(node)
  if (category === CATEGORY.activity) {
    return <rect data-appearance={color} x={1} y={1} width={w - 2} height={h - 2} rx={Math.round(h * 0.1 * 10) / 10} fill={color} fillOpacity={0.16} stroke={color} strokeWidth={2.6} />
  }
  if (category === CATEGORY.event) return <circle data-appearance={color} cx={w / 2} cy={h / 2} r={Math.min(w, h) / 2 - 1.5} {...line} />
  if (category === CATEGORY.gateway) return <path data-appearance={color} d={`M${w / 2},1.5 L${w - 1.5},${h / 2} L${w / 2},${h - 1.5} L1.5,${h / 2} Z`} {...line} strokeLinejoin='round' />
  return <rect data-appearance={color} x={1} y={1} width={w - 2} height={h - 2} rx={4} {...line} />
}

// The colour an element is outlined in — the minimap paints with it.
export const strokeOf = (node, external = false) => paintFor(node, LIVE_PAINT, external).stroke

export function NodeShape ({ node, width, height, paint = LIVE_PAINT, external = false, badge = false }) {
  const props = { node, w: width, h: height, paint, external, badge }
  switch (categoryOf(node)) {
    case CATEGORY.activity: return <ActivityShape {...props} />
    case CATEGORY.gateway: return <GatewayShape {...props} />
    case CATEGORY.event: return <EventShape {...props} />
    case CATEGORY.data: return <DataShape {...props} />
    case CATEGORY.artifact: return <ArtifactShape {...props} />
    default:
      return <rect x={1} y={1} width={width - 2} height={height - 2} rx={4} style={{ fill: paint.neutral.fill, stroke: paint.neutral.stroke }} strokeDasharray='3 3' />
  }
}

// Icon of a palette item, the quick menu and the legend: the element's own
// shape (NodeShape, as on the canvas) in a box of the icon's size — 4:3 for
// activities and groups, as BPMN draws them, upright for data.
export function iconBox (node, size) {
  const category = categoryOf(node)
  if (category === CATEGORY.activity || node.type === 'group') return { width: size, height: Math.round(size * 0.75) }
  if (category === CATEGORY.data) return { width: Math.round(size * 0.72), height: size }
  if (node.type === 'text_annotation') return { width: size - 4, height: size - 4 }
  return { width: size, height: size }
}

export function NodeIcon ({ node, size = 28, external = false }) {
  const { width: w, height: h } = iconBox(node, size)
  return (
    <svg width={size} height={size} viewBox={`${-(size - w) / 2} ${-(size - h) / 2} ${size} ${size}`} aria-hidden='true' data-icon={node.type}>
      <NodeShape node={node} width={w} height={h} external={external} />
    </svg>
  )
}

export function ConnectorIcon ({ type, size = 28 }) {
  const color = 'var(--color-base-content)'
  return (
    <svg width={size} height={size} viewBox='0 0 24 24' aria-hidden='true'>
      {type === 'association'
        ? <path d='M3 12h18' stroke={color} strokeWidth={1.4} strokeDasharray='1.6 2' />
        : <path d='M3 12h13' stroke={color} strokeWidth={1.6} strokeDasharray={type === 'message_flow' ? '3 2' : undefined} />}
      {type !== 'association' && <path d='M15 8.4 21 12l-6 3.6Z' style={{ fill: type === 'message_flow' ? 'var(--color-base-100)' : color, stroke: color }} strokeWidth={1.2} />}
      {type === 'message_flow' && <circle cx={3.6} cy={12} r={1.8} style={{ fill: 'var(--color-base-100)', stroke: color }} strokeWidth={1.1} />}
    </svg>
  )
}

export function LaneIcon ({ size = 28 }) {
  const stroke = 'color-mix(in oklab, var(--color-base-content) 60%, transparent)'
  return (
    <svg width={size} height={size} viewBox='0 0 24 24' aria-hidden='true'>
      <rect x={3} y={4} width={18} height={16} style={{ fill: 'var(--color-base-200)', stroke }} strokeWidth={1.2} />
      <path d='M8 4v16M8 12h13' style={{ stroke }} strokeWidth={1.2} />
    </svg>
  )
}

// Yellow warning triangle marking an element with a pending issue.
export function IssueMarker ({ x, y }) {
  return (
    <g transform={`translate(${x} ${y})`}>
      <path d='M0,-8 L8.5,7 L-8.5,7 Z' style={{ fill: 'var(--color-warning)', stroke: 'var(--color-warning-content)' }} strokeWidth={1} strokeLinejoin='round' />
      <text x={0} y={4} textAnchor='middle' fontSize={10} fontWeight={800} style={{ fill: 'var(--color-warning-content)' }}>!</text>
    </g>
  )
}
