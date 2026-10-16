import { useCallback, useEffect, useRef, useState } from 'react'
import { Panel, useOnViewportChange } from '@xyflow/react'
import { NodeShape, NodeIcon } from '../shapes.jsx'
import Icon from './icons.jsx'

// The swatches the legend draws; mirrors Bali::BpmnEditor::Component::LEGEND_SWATCHES
// (contract_test.rb).
export const LEGEND_SWATCHES = ['task', 'sub_process', 'gateway', 'start_event', 'end_event', 'external_lane', 'external_task', 'issue', 'color']

function Swatch ({ swatch, color }) {
  // The canvas shapes themselves (shapes.jsx), so a colour here is the
  // element's colour there.
  switch (swatch) {
    case 'task': return <NodeIcon node={{ type: 'task' }} size={24} />
    case 'sub_process': return <NodeIcon node={{ type: 'sub_process', reference: {} }} size={24} />
    case 'external_task': return <NodeIcon node={{ type: 'task' }} size={24} external />
    case 'gateway': return <svg width={24} height={18} aria-hidden='true'><g transform='translate(3 0)'><NodeShape node={{ type: 'exclusive_gateway' }} width={18} height={18} /></g></svg>
    case 'start_event': return <svg width={24} height={18} aria-hidden='true'><g transform='translate(3 0)'><NodeShape node={{ type: 'start_event' }} width={18} height={18} /></g></svg>
    case 'end_event': return <svg width={24} height={18} aria-hidden='true'><g transform='translate(3 0)'><NodeShape node={{ type: 'end_event' }} width={18} height={18} /></g></svg>
    case 'external_lane': return <span className='bpmn-legend-lane' aria-hidden='true' />
    case 'issue': return <svg width={24} height={18} aria-hidden='true'><path d='M12,2 L21,16 L3,16 Z' style={{ fill: 'var(--color-warning)' }} /></svg>
    default: return <span className='inline-block h-3.5 w-6 rounded-sm border' style={{ borderColor: color, backgroundColor: `color-mix(in oklab, ${color} 18%, transparent)` }} aria-hidden='true' />
  }
}

// Whether an element of the diagram is drawn under `panel` right now.
export function coversContent (panel) {
  const flow = panel && panel.closest('.react-flow')
  if (!flow) return false
  const r = panel.getBoundingClientRect()
  return [...flow.querySelectorAll('.react-flow__node-bpmn')].some((node) => {
    const b = node.getBoundingClientRect()
    return b.left < r.right && r.left < b.right && b.top < r.bottom && r.top < b.bottom
  })
}

// What each colour means on the canvas. The entries come from the host
// (Bali::BpmnEditor::Component `legend:`), which can add and remove them.
// The canvas reserves no room for it: when the view settles with an element
// under the open legend, it folds itself to its title. Opened again, it stays
// open until the view moves.
export default function Legend ({ t, entries, className = '', open: controlled, onToggle }) {
  const [own, setOwn] = useState(true)
  const open = controlled ?? own
  const setOpen = onToggle || setOwn
  const panel = useRef(null)
  const foldIfCovering = useCallback(() => {
    if (open && coversContent(panel.current)) setOpen(false)
  }, [open, setOpen])
  useOnViewportChange({ onEnd: foldIfCovering })
  // Once, after the first fit has settled.
  const latest = useRef(foldIfCovering)
  latest.current = foldIfCovering
  useEffect(() => {
    const timer = setTimeout(() => latest.current(), 400)
    return () => clearTimeout(timer)
  }, [])
  if (!entries || !entries.length) return null
  return (
    <Panel ref={panel} position='bottom-right' className={`bpmn-chrome bpmn-legend w-60 rounded-lg border border-base-300 bg-base-100 text-xs shadow-sm ${className}`}>
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
