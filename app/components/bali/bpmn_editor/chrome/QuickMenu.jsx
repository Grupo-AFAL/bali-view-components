import { useState } from 'react'
import { PALETTE_ITEMS } from '../model/catalog.js'
import { NodeIcon } from '../shapes.jsx'
import Icon from './icons.jsx'

// The four quick picks and, under "More", the rest of the palette's node
// items. Only what the host left enabled in the palette is offered.
const PICKS = [
  ['quick_task', ['task', 'user_task', 'service_task', 'manual_task']],
  ['quick_event', ['message_event', 'timer_event', 'conditional_event', 'signal_event']],
  ['quick_gateway', ['exclusive_gateway', 'parallel_gateway', 'inclusive_gateway']],
  ['quick_end', ['end_event', 'terminate_end_event', 'message_end_event']]
]
const DIRECTIONS = [['up', 'arrowUp'], ['left', 'arrowLeft'], ['right', 'arrowRight'], ['down', 'arrowDown']]
const MORE_GROUPS = ['activities', 'gateways', 'intermediate_events', 'end_events']
const SPLITS = ['binary_decision', 'exclusive_gateway', 'parallel_gateway', 'inclusive_gateway']

// "Add the next element", already connected, in the chosen direction.
// `blocked` maps a direction to why nothing can be added there (its button is
// disabled and says so). `needsGateway`: the element already has its way
// out, so the new one is a branch and the menu first asks which gateway
// splits the path.
export default function QuickMenu ({ t, enabled, direction, onDirection, onAdd, onConnect, blocked = {}, needsGateway = false }) {
  const [more, setMore] = useState(false)
  const [pending, setPending] = useState(null)
  const splits = SPLITS.filter((k) => enabled.has(k))
  const add = (key) => {
    if (blocked[direction]) return
    if (needsGateway) setPending(key)
    else onAdd(key)
  }
  const first = (keys) => keys.find((k) => enabled.has(k))
  const picks = PICKS.map(([label, keys]) => [label, first(keys)]).filter(([, key]) => key)
  const extra = [...enabled].filter((k) => PALETTE_ITEMS[k] && PALETTE_ITEMS[k].node && MORE_GROUPS.includes(PALETTE_ITEMS[k].group) && !picks.some(([, p]) => p === k))
  return (
    <div className='bpmn-chrome nodrag nopan flex flex-col gap-1 rounded-lg border border-base-300 bg-base-100 p-1 shadow-md' data-testid='bpmn-quick-menu' onPointerDown={(e) => e.stopPropagation()}>
      <div className='flex items-center gap-0.5'>
        {picks.map(([label, key]) => (
          <button key={key} type='button' className={`btn btn-ghost btn-xs btn-square h-8 w-8 ${blocked[direction] ? 'btn-disabled pointer-events-auto' : ''}`} title={blocked[direction] || t(label)} aria-label={t(label)} aria-disabled={blocked[direction] ? 'true' : undefined} data-quick={key} aria-pressed={pending === key ? 'true' : undefined} onClick={() => add(key)}>
            <NodeIcon node={PALETTE_ITEMS[key].node} size={22} />
          </button>
        ))}
        {extra.length > 0 && (
          <button type='button' className={`btn btn-ghost btn-xs btn-square h-8 w-8 ${more ? 'btn-active' : ''}`} title={t('quick_more')} aria-label={t('quick_more')} aria-expanded={more} onClick={() => setMore((m) => !m)}>
            <Icon name='more' size={16} />
          </button>
        )}
        {onConnect && (
          // To an element already on the canvas — a way back for rework among them.
          <button type='button' className='btn btn-ghost btn-xs btn-square h-8 w-8' title={t('quick_connect')} aria-label={t('quick_connect')} data-quick-connect onClick={onConnect}>
            <Icon name='arrowRight' size={16} />
          </button>
        )}
        <span className='mx-0.5 h-6 w-px bg-base-300' />
        <div className='grid grid-cols-3 grid-rows-3 gap-px' role='group' aria-label={t('quick_direction')}>
          {DIRECTIONS.map(([dir, icon]) => (
            // aria-disabled, not disabled: a disabled button shows no tooltip.
            <button
              key={dir} type='button'
              className={`btn btn-ghost btn-xs btn-square h-4 min-h-0 w-4 p-0 ${direction === dir ? 'btn-active text-primary' : ''} ${blocked[dir] ? 'btn-disabled pointer-events-auto' : ''} ${{ up: 'col-start-2 row-start-1', left: 'col-start-1 row-start-2', right: 'col-start-3 row-start-2', down: 'col-start-2 row-start-3' }[dir]}`}
              aria-label={t(`dir_${dir}`)} aria-pressed={direction === dir} aria-disabled={blocked[dir] ? 'true' : undefined}
              title={blocked[dir] || t(`dir_${dir}`)} data-direction={dir}
              onClick={() => { if (!blocked[dir]) onDirection(dir) }}
            >
              <Icon name={icon} size={10} />
            </button>
          ))}
        </div>
      </div>
      {pending && (
        <div className='flex max-w-64 flex-wrap items-center gap-1 border-t border-base-300 px-1 pt-1 text-xs' role='group' aria-label={t('branch_with')} data-testid='bpmn-branch-with'>
          <span className='text-base-content/70'>{t('branch_with')}:</span>
          {splits.map((gateway) => (
            <button key={gateway} type='button' className='btn btn-ghost btn-xs gap-1 font-normal' data-branch={gateway} onClick={() => { onAdd(pending, gateway); setPending(null) }}>
              <NodeIcon node={PALETTE_ITEMS[gateway].node} size={16} />{t(`branch_${gateway}`)}
            </button>
          ))}
        </div>
      )}
      {more && (
        <div className='grid max-h-48 grid-cols-6 gap-0.5 overflow-y-auto border-t border-base-300 pt-1'>
          {extra.map((key) => (
            <button key={key} type='button' className={`btn btn-ghost btn-xs btn-square h-8 w-8 ${blocked[direction] ? 'btn-disabled pointer-events-auto' : ''}`} title={blocked[direction] || t(`palette_${key}`)} aria-label={t(`palette_${key}`)} aria-disabled={blocked[direction] ? 'true' : undefined} data-quick={key} aria-pressed={pending === key ? 'true' : undefined} onClick={() => add(key)}>
              <NodeIcon node={PALETTE_ITEMS[key].node} size={22} />
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
