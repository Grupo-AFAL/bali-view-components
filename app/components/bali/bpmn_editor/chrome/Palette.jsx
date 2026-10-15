import { useMemo, useState } from 'react'
import { PALETTE_GROUPS, PALETTE_ITEMS } from '../model/catalog.js'
import { NodeIcon, ConnectorIcon, LaneIcon } from '../shapes.jsx'
import Icon from './icons.jsx'

export const PALETTE_MIME = 'application/x-bali-bpmn-palette'

function ItemIcon ({ itemKey }) {
  const item = PALETTE_ITEMS[itemKey]
  if (item.tool === 'lane') return <LaneIcon />
  if (item.tool === 'connect') return <ConnectorIcon type={item.edge} />
  // A palette sub-process is drawn linked: the dashed outline means "pending" on the canvas.
  return <NodeIcon node={item.node.type === 'sub_process' ? { ...item.node, reference: {} } : item.node} />
}

// The "Elements" panel: a search box and collapsible groups. What it lists is
// what the host resolved server-side (Bali::BpmnEditor::Palette): items may
// be disabled, and an item with a host note is outlined and explains itself
// in its tooltip and in the legend at the foot.
export default function Palette ({ t, palette, tool, onPick, onAddLane, collapsed, onToggle, disabled }) {
  const [query, setQuery] = useState('')
  const [closed, setClosed] = useState(() => new Set())
  const items = (palette && palette.items) || []
  const q = query.trim().toLowerCase()

  const groups = useMemo(() => PALETTE_GROUPS.map((group) => ({
    group,
    items: items.filter((it) => PALETTE_ITEMS[it.key] && PALETTE_ITEMS[it.key].group === group)
  })).filter((g) => g.items.length), [items])
  const hasNotes = items.some((it) => it.note)

  if (collapsed) {
    return (
      <aside className='bpmn-chrome flex w-9 shrink-0 flex-col items-center gap-2 border-r border-base-300 bg-base-100 py-2'>
        <button type='button' className='btn btn-ghost btn-xs btn-square' onClick={onToggle} aria-label={t('palette_show')} title={t('palette_show')}>
          <Icon name='chevronRight' size={14} />
        </button>
        <span className='text-xs font-semibold text-base-content/70 [writing-mode:vertical-rl]'>{t('palette_title')}</span>
      </aside>
    )
  }

  return (
    <aside className='bpmn-chrome flex w-56 shrink-0 flex-col border-r border-base-300 bg-base-100' aria-label={t('palette_title')}>
      <div className='flex items-center justify-between px-3 pb-1 pt-2'>
        <h3 className='text-sm font-semibold'>{t('palette_title')}</h3>
        <button type='button' className='btn btn-ghost btn-xs btn-square' onClick={onToggle} aria-label={t('palette_hide')} title={t('palette_hide')}>
          <Icon name='chevronLeft' size={14} />
        </button>
      </div>
      <label className='input input-sm mx-3 mb-2 flex w-auto items-center gap-2'>
        <Icon name='search' size={14} className='opacity-50' />
        <input type='search' className='grow' placeholder={t('palette_search')} aria-label={t('palette_search')} value={query} onChange={(e) => setQuery(e.target.value)} />
      </label>
      <div className='flex-1 overflow-y-auto px-2 pb-2'>
        {groups.map(({ group, items: groupItems }) => {
          const shown = groupItems.filter((it) => !q || t(`palette_${it.key}`).toLowerCase().includes(q))
          if (!shown.length) return null
          const open = q || !closed.has(group)
          const notes = groupItems.filter((it) => it.note).length
          return (
            <section key={group} className='mb-1'>
              <button
                type='button'
                className='flex w-full items-center gap-1 rounded bg-base-200 px-2 py-1 text-left text-xs font-semibold'
                aria-expanded={Boolean(open)}
                onClick={() => setClosed((set) => { const next = new Set(set); next.has(group) ? next.delete(group) : next.add(group); return next })}
              >
                <Icon name={open ? 'chevronDown' : 'chevronRight'} size={12} />
                <span className='grow'>{t(`palette_group_${group}`)}</span>
                {notes > 0 && (
                  <span className='bpmn-note-chip'>
                    {palette.note_label ? (notes === groupItems.length ? palette.note_label : `${notes} ${palette.note_label}`) : notes}
                  </span>
                )}
                <span className='text-base-content/60'>{groupItems.length}</span>
              </button>
              {open && (
                <div className='grid grid-cols-5 gap-1 px-1 py-1.5'>
                  {shown.map((it) => {
                    const def = PALETTE_ITEMS[it.key]
                    const label = t(`palette_${it.key}`)
                    const off = disabled || it.state === 'disabled'
                    const active = tool && tool.key === it.key
                    const placeable = Boolean(def.node) && !off
                    return (
                      <button
                        key={it.key}
                        type='button'
                        className={`bpmn-palette-item btn btn-ghost btn-sm btn-square h-9 w-9 ${it.note ? 'has-note' : ''} ${active ? 'btn-active ring-1 ring-primary' : ''}`}
                        disabled={off}
                        title={it.note ? `${label} · ${it.note}` : label}
                        aria-label={it.note ? `${label} (${it.note})` : label}
                        aria-pressed={active ? 'true' : 'false'}
                        draggable={placeable}
                        data-palette-key={it.key}
                        onDragStart={(e) => { e.dataTransfer.setData(PALETTE_MIME, it.key); e.dataTransfer.effectAllowed = 'copy' }}
                        onClick={() => (def.tool === 'lane' ? onAddLane() : onPick(active ? null : it.key))}
                      >
                        <ItemIcon itemKey={it.key} />
                      </button>
                    )
                  })}
                </div>
              )}
            </section>
          )
        })}
        {q && groups.every(({ items: groupItems }) => !groupItems.some((it) => t(`palette_${it.key}`).toLowerCase().includes(q))) && (
          <p className='px-2 py-4 text-center text-xs text-base-content/60'>{t('palette_empty')}</p>
        )}
      </div>
      {hasNotes && (
        <p className='flex items-start gap-2 border-t border-base-300 px-3 py-2 text-[11px] text-base-content/70'>
          <span className='bpmn-palette-swatch-note mt-0.5 shrink-0' />
          <span>{palette.note_legend || t('palette_note_legend')}</span>
        </p>
      )}
    </aside>
  )
}
