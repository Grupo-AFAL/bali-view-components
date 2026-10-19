// The whole diagram as one standalone SVG: lanes, connections, elements,
// names, labels, review-note markers, an optional title and watermark. What
// "Download image", "Download SVG" and "Print" put on paper — at full size,
// not the part of the canvas that happens to be on screen.
//
// Self-contained on purpose: every colour arrives resolved (`paint`), so the
// file renders the same outside the page, in an <img> or another program.
import { NodeShape, AppearanceMark } from '../shapes.jsx'
import { appearanceOf } from '../model/appearance.js'
import { categoryOf, CATEGORY, edgeType } from '../model/catalog.js'
import { layoutLanes, laneRect, nodeBox, contentBounds } from '../model/geometry.js'
import { routeAll, pathWithJumps, findJumps } from '../model/routing.js'
import { placeEdgeLabels } from '../model/edgeLabels.js'
import { nodeLabelBox } from '../model/labels.js'
import { pageFit, sheetFor, EXPORT_MARGIN as MARGIN, TITLE_HEIGHT } from '../model/page.js'
import { textOn } from '../model/contrast.js'

const FONT = "system-ui, -apple-system, 'Segoe UI', sans-serif"

// Greedy word wrap by an average glyph width: good enough for labels, and
// exportable, unlike the canvas' HTML labels.
export function wrap (text, maxChars, maxLines) {
  const words = String(text || '').split(/\s+/).filter(Boolean)
  const lines = []
  let current = ''
  for (const word of words) {
    if (current && (current + ' ' + word).length > maxChars) { lines.push(current); current = word } else current = current ? `${current} ${word}` : word
  }
  if (current) lines.push(current)
  if (lines.length > maxLines) {
    const kept = lines.slice(0, maxLines)
    kept[maxLines - 1] = kept[maxLines - 1].replace(/.{0,1}$/, '…')
    return kept
  }
  return lines
}

function Text ({ x, y, text, maxChars = 22, maxLines = 3, size = 11, weight = 500, fill, anchor = 'middle', lineHeight = 13 }) {
  const lines = wrap(text, maxChars, maxLines)
  const y0 = y - ((lines.length - 1) * lineHeight) / 2
  return (
    <text x={x} y={y0} textAnchor={anchor} dominantBaseline='middle' fontSize={size} fontWeight={weight} fill={fill} fontFamily={FONT}>
      {lines.map((line, i) => <tspan key={i} x={x} y={y0 + i * lineHeight}>{line}</tspan>)}
    </text>
  )
}

// The app's badge (`node.appearance.badge`), off the bottom-right corner as
// on the canvas: on the app's colour with black or white text, whichever reads.
function Badge ({ text, color, right, bottom, colors }) {
  const width = Math.round(text.length * 6.2 + 14)
  const fill = color || colors.header
  return (
    <g transform={`translate(${right + 8 - width} ${bottom - 7})`}>
      <rect width={width} height={16} rx={8} fill={fill} stroke={color ? 'none' : colors.border} />
      <text x={width / 2} y={8.5} textAnchor='middle' dominantBaseline='middle' fontSize={10} fontWeight={600} fill={textOn(color) || colors.text}>{text}</text>
    </g>
  )
}

// With `page`, a diagram that fits it legibly (model/page.js) is drawn on a
// sheet of that size, centred inside the print margins, shrunk only as much
// as it must; one that does not fit keeps its own size.
export default function ExportDiagram ({ doc, paint, colors, title, subtitle, watermark, notes = [], tags = [], page = null }) {
  const layout = layoutLanes(doc, { print: true })
  const routes = routeAll(doc)
  const edgeLabels = placeEdgeLabels(doc, routes)
  const jumps = findJumps(routes)
  const bounds = contentBounds(doc, layout)
  const titleHeight = title ? TITLE_HEIGHT : 0
  const x0 = bounds.x - MARGIN
  const y0 = bounds.y - MARGIN - titleHeight
  const width = Math.ceil(bounds.w + MARGIN * 2)
  const height = Math.ceil(bounds.h + MARGIN * 2 + titleHeight)
  const fit = page ? pageFit(doc, page, { title: Boolean(title) }) : null
  const sheet = fit && fit.fits ? sheetFor(fit, { x0, y0, width, height }) : null
  const external = new Set(layout.entries.filter((e) => e.lane.kind === 'external').map((e) => String(e.id)))
  const tagColor = (key) => (tags.find((tag) => tag.key === key) || {}).color || colors.primary
  const notesByElement = new Map()
  for (const note of notes) if (!notesByElement.has(String(note.target_id))) notesByElement.set(String(note.target_id), note)

  return (
    <svg
      xmlns='http://www.w3.org/2000/svg' fontFamily={FONT} data-sheet={sheet ? 'true' : undefined}
      width={sheet ? sheet.width : width} height={sheet ? sheet.height : height}
      viewBox={sheet ? sheet.viewBox : `${x0} ${y0} ${width} ${height}`}
    >
      <defs>
        <marker id='x-arrow' viewBox='0 0 10 10' refX='9' refY='5' markerWidth='7' markerHeight='7' orient='auto-start-reverse'>
          <path d='M0,0 L10,5 L0,10 z' fill={colors.line} />
        </marker>
        <marker id='x-arrow-open' viewBox='0 0 10 10' refX='9' refY='5' markerWidth='8' markerHeight='8' orient='auto-start-reverse'>
          <path d='M0,0 L10,5 L0,10 z' fill={colors.background} stroke={colors.line} />
        </marker>
        <marker id='x-circle' viewBox='0 0 10 10' refX='5' refY='5' markerWidth='7' markerHeight='7'>
          <circle cx='5' cy='5' r='3.5' fill={colors.background} stroke={colors.line} />
        </marker>
      </defs>
      {sheet
        ? <rect x={sheet.x} y={sheet.y} width={sheet.w} height={sheet.h} fill={colors.background} />
        : <rect x={x0} y={y0} width={width} height={height} fill={colors.background} />}
      {title && (
        <g>
          <text x={x0 + MARGIN} y={y0 + MARGIN + 6} fontSize={16} fontWeight={600} fill={colors.text}>{title}</text>
          {subtitle && <text x={x0 + MARGIN} y={y0 + MARGIN + 26} fontSize={11} fill={colors.muted}>{subtitle}</text>}
        </g>
      )}

      {layout.entries.map((entry) => {
        const r = laneRect(layout, entry)
        const ext = external.has(String(entry.id))
        const horizontal = layout.axis.main === 'y'
        const name = String(entry.lane.name || '').toUpperCase()
        return (
          <g key={`lane-${entry.id}`}>
            <rect x={r.x} y={r.y} width={r.w} height={r.h} fill={ext ? colors.externalLane : colors.background} stroke={colors.border} />
            {horizontal
              ? <rect x={r.x} y={r.y} width={layout.header} height={r.h} fill={ext ? colors.externalHeader : colors.header} stroke={colors.border} />
              : <rect x={r.x} y={r.y} width={r.w} height={layout.header} fill={ext ? colors.externalHeader : colors.header} stroke={colors.border} />}
            {horizontal
              ? (
                <g transform={`translate(${r.x + layout.header / 2} ${r.y + r.h / 2}) rotate(-90)`}>
                  <Text x={0} y={0} text={name} maxChars={Math.max(8, Math.floor(r.h / 8))} maxLines={2} size={11} weight={600} fill={colors.text} />
                </g>
                )
              : <Text x={r.x + r.w / 2} y={r.y + layout.header / 2} text={name} maxChars={Math.max(10, Math.floor(r.w / 8))} maxLines={2} size={11} weight={600} fill={colors.text} />}
          </g>
        )
      })}

      {(doc.edges || []).map((edge) => {
        const route = routes.get(String(edge.id))
        if (!route) return null
        const type = edgeType(edge)
        const label = edge.label
        const box = label ? edgeLabels.get(String(edge.id)) : null
        return (
          <g key={`edge-${edge.id}`}>
            <path
              d={pathWithJumps(route.points, jumps.get(String(edge.id)) || [])} fill='none' stroke={colors.line} strokeWidth={1.5} strokeLinejoin='round'
              strokeDasharray={type === 'message_flow' ? '6 4' : type === 'association' ? '2 3' : undefined}
              markerEnd={type === 'association' ? undefined : `url(#${type === 'message_flow' ? 'x-arrow-open' : 'x-arrow'})`}
              markerStart={type === 'message_flow' ? 'url(#x-circle)' : undefined}
            />
            {box && (
              <g transform={`translate(${box.x + box.w / 2} ${box.y + box.h / 2})`}>
                <rect x={-box.w / 2} y={-9} width={box.w} height={18} rx={4} fill={colors.background} stroke={colors.border} />
                <text x={0} y={0} textAnchor='middle' dominantBaseline='central' fontSize={11} fontWeight={600} fill={colors.text}>{label}</text>
              </g>
            )}
          </g>
        )
      })}

      {[...(doc.nodes || [])].sort((a, b) => (a.type === 'group' ? -1 : 0) - (b.type === 'group' ? -1 : 0)).map((node) => {
        const box = nodeBox(node)
        const category = categoryOf(node)
        const note = notesByElement.get(String(node.id))
        const look = appearanceOf(node)
        return (
          <g key={`node-${node.id}`} opacity={look && look.dimmed ? 0.45 : undefined}>
            <g transform={`translate(${box.x} ${box.y})`}>
              <NodeShape node={node} width={box.w} height={box.h} paint={paint} external={external.has(String(node.lane_id))} />
              {look && <AppearanceMark node={node} width={box.w} height={box.h} color={look.color} />}
            </g>
            {category === CATEGORY.activity && <Text x={box.cx} y={box.cy} text={node.name} maxChars={Math.floor(box.w / 6.8)} maxLines={3} fill={colors.text} />}
            {node.type === 'text_annotation' && <Text x={box.x + 18} y={box.cy} anchor='start' text={node.name} maxChars={Math.floor((box.w - 20) / 6.5)} maxLines={3} weight={400} fill={colors.text} />}
            {node.type === 'group' && node.name && <text x={box.x + 10} y={box.y + 16} fontSize={11} fontWeight={600} fill={colors.muted}>{node.name}</text>}
            {(() => {
              const lb = nodeLabelBox(node, layout.orientation)
              if (!lb) return null
              const anchor = category === CATEGORY.gateway ? 'end' : layout.orientation === 'vertical' && category === CATEGORY.event ? 'start' : 'middle'
              const x = anchor === 'end' ? lb.x + lb.w : anchor === 'start' ? lb.x : lb.x + lb.w / 2
              return <Text x={x} y={lb.y + lb.h / 2} anchor={anchor} text={node.name} maxChars={Math.max(4, Math.floor(lb.w / 6.4))} maxLines={lb.lines} size={11} fill={colors.text} />
            })()}
            {look && look.badge && <Badge text={look.badge} color={look.color} right={box.x + box.w} bottom={box.y + box.h} colors={colors} />}
            {note && (
              <g transform={`translate(${box.x - 2} ${box.y - 2})`}>
                <circle r={10} fill={tagColor(note.tag)} />
                <text textAnchor='middle' dominantBaseline='central' fontSize={11} fontWeight={700} fill={textOn(tagColor(note.tag)) || colors.background}>{note.number}</text>
              </g>
            )}
          </g>
        )
      })}

      {watermark && (
        <text
          x={x0 + width / 2} y={y0 + height / 2} textAnchor='middle' dominantBaseline='middle'
          fontSize={Math.min(140, width / 7)} fontWeight={800} fill={colors.watermark} fillOpacity={0.14}
          transform={`rotate(-18 ${x0 + width / 2} ${y0 + height / 2})`}
        >
          {watermark}
        </text>
      )}
    </svg>
  )
}

