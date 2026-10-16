import { useState } from 'react'
import { Panel } from '@xyflow/react'
import Icon from './icons.jsx'
import { NodeIcon } from '../shapes.jsx'

export const STENCIL_MIME = 'application/x-bali-bpmn-stencil'

// Entities the host proposes to place (the document's `stencil`): dragging
// one onto the canvas creates a sub-process already linked to it.
export default function Stencil ({ t, items }) {
  const [open, setOpen] = useState(true)
  if (!items || !items.length) return null
  return (
    <Panel position='top-right' className='bpmn-chrome bpmn-stencil w-60 rounded-lg border border-base-300 bg-base-100 p-2 text-sm shadow-sm' data-testid='bpmn-stencil'>
      <button type='button' className='flex w-full items-center justify-between font-semibold' aria-expanded={open} onClick={() => setOpen((o) => !o)}>
        {t('stencil_title')} <span className='badge badge-ghost badge-sm'>{items.length}</span>
        <Icon name={open ? 'chevronDown' : 'chevronRight'} size={12} />
      </button>
      {open && <p className='mb-2 text-xs text-base-content/60'>{t('stencil_hint')}</p>}
      {open && <ul className='flex max-h-56 flex-col gap-1 overflow-y-auto'>
        {items.map((item, index) => (
          <li
            key={`${item.reference.id}-${index}`}
            draggable
            onDragStart={(e) => { e.dataTransfer.setData(STENCIL_MIME, String(index)); e.dataTransfer.effectAllowed = 'copy' }}
            className='flex cursor-grab items-center gap-2 rounded border border-base-300 px-2 py-1 hover:bg-base-200'
            title={item.reference.label}
          >
            <NodeIcon node={{ type: 'sub_process', reference: item.reference }} size={20} />
            <span className='truncate'>{item.reference.label}</span>
          </li>
        ))}
      </ul>}
    </Panel>
  )
}
