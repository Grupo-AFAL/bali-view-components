import { useState } from 'react'
import { Panel } from '@xyflow/react'
import { NodeShape, LIVE_PAINT } from '../shapes.jsx'
import Icon from './icons.jsx'

// Swatches the legend draws. Mirrors Bali::BpmnEditor::Component::LEGEND_SWATCHES.
function Swatch ({ swatch, color }) {
  // Plain rounded boxes, as in the design: at this size the canvas shapes'
  // markers would only be noise.
  const box = (paint, width = 1.5) => (
    <svg width={24} height={16} aria-hidden='true'>
      <rect x={1} y={1} width={22} height={14} rx={3} style={{ fill: paint.fill, stroke: paint.stroke }} strokeWidth={width} />
    </svg>
  )
  switch (swatch) {
    case 'task': return box(LIVE_PAINT.activity)
    case 'sub_process': return box(LIVE_PAINT.subProcess, 2)
    case 'external_task': return box(LIVE_PAINT.externalActivity)
    case 'gateway': return <svg width={24} height={18} aria-hidden='true'><g transform='translate(3 0)'><NodeShape node={{ type: 'exclusive_gateway' }} width={18} height={18} /></g></svg>
    case 'start_event': return <svg width={24} height={18} aria-hidden='true'><g transform='translate(3 0)'><NodeShape node={{ type: 'start_event' }} width={18} height={18} /></g></svg>
    case 'end_event': return <svg width={24} height={18} aria-hidden='true'><g transform='translate(3 0)'><NodeShape node={{ type: 'end_event' }} width={18} height={18} /></g></svg>
    case 'external_lane': return <span className='bpmn-legend-lane' aria-hidden='true' />
    case 'issue': return <svg width={24} height={18} aria-hidden='true'><path d='M12,2 L21,16 L3,16 Z' style={{ fill: 'var(--color-warning)' }} /></svg>
    default: return <span className='inline-block h-3.5 w-6 rounded-sm border' style={{ borderColor: color, backgroundColor: `color-mix(in oklab, ${color} 18%, transparent)` }} aria-hidden='true' />
  }
}

// What each colour means on the canvas. The entries come from the host
// (Bali::BpmnEditor::Component `legend:`), which can add and remove them.
export default function Legend ({ t, entries, className = '', open: controlled, onToggle }) {
  const [own, setOwn] = useState(true)
  const open = controlled ?? own
  const setOpen = onToggle || setOwn
  if (!entries || !entries.length) return null
  return (
    <Panel position='bottom-right' className={`bpmn-chrome bpmn-legend w-60 rounded-lg border border-base-300 bg-base-100 text-xs shadow-sm ${className}`}>
      <button type='button' className='flex w-full items-center justify-between px-3 py-1.5 font-semibold uppercase tracking-wide text-base-content/70' aria-expanded={open} onClick={() => setOpen((o) => !o)}>
        {t('legend_title')}
        <Icon name={open ? 'chevronDown' : 'chevronRight'} size={12} />
      </button>
      {open && (
        <ul className='flex flex-col gap-1.5 px-3 pb-2' data-testid='bpmn-legend'>
          {entries.map((entry) => (
            <li key={entry.key} className='flex items-center gap-2'>
              <span className='flex w-6 shrink-0 justify-center'><Swatch swatch={entry.swatch || entry.key} color={entry.color} /></span>
              <span>{entry.label || t(`legend_${entry.key}`)}</span>
            </li>
          ))}
        </ul>
      )}
    </Panel>
  )
}
