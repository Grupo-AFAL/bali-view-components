import { useEffect, useState } from 'react'
import { remoteSearch, groupBy } from './remoteSearch.js'
import Icon from './icons.jsx'
import { safeUrl } from '../model/urls.js'

// Linking a sub-process to an entity of the host (`urls.references`), or a
// lane to its responsible (`urls.lane_assignees`). "Create new" opens the
// host's drawer; the host answers with the bali_bpmn_event stream action
// (reference-created / lane-assignee-created) and the editor links it.
export default function ReferencePicker ({ node, lane, api, t, editable, urls }) {
  const forLane = Boolean(lane)
  const current = forLane ? lane.assignee : node.reference
  const searchUrl = forLane ? urls.lane_assignees : urls.references
  const createUrl = forLane ? urls.new_lane_assignee : urls.new_reference
  const [query, setQuery] = useState('')
  const [group, setGroup] = useState('')
  const [results, setResults] = useState(null)
  const [groups, setGroups] = useState([])

  useEffect(() => {
    if (!searchUrl || !editable) return
    let live = true
    setResults(null)
    const timer = setTimeout(() => {
      remoteSearch(searchUrl, { q: query, group }).then((found) => {
        if (!live) return
        setResults(found.ok ? found.items : false)
        if (found.ok && !group) setGroups([...new Set(found.items.map((i) => i.group).filter(Boolean))])
      })
    }, 250)
    return () => { live = false; clearTimeout(timer) }
  }, [searchUrl, query, group, editable])

  const pick = (item) => {
    const value = { id: String(item.id), label: item.label, url: safeUrl(item.url), group: item.group || null }
    if (forLane) api.updateLane(lane.id, { assignee: value, name: lane.name || item.label })
    else api.updateNode(node.id, { reference: value, name: item.label })
  }

  return (
    <div className='flex flex-col gap-2'>
      <span className='text-xs font-semibold text-base-content/70'>{t(forLane ? 'props_assignee' : 'props_reference')}</span>
      {current
        ? (
          <div className='flex items-start gap-2 rounded border border-base-300 p-2'>
            <span className='grow text-sm'>{current.label}{current.group && <span className='block text-xs text-base-content/60'>{current.group}</span>}</span>
            {!forLane && safeUrl(current.url) && (
              <a href={safeUrl(current.url)} className='btn btn-ghost btn-xs' data-testid='bpmn-open-reference' onClick={(event) => { if (!api.announceOpenReference(node)) event.preventDefault() }}>
                <Icon name='external' size={12} />{t('props_open_reference')}
              </a>
            )}
            {editable && (
              <button type='button' className='btn btn-ghost btn-xs' onClick={() => (forLane ? api.updateLane(lane.id, { assignee: null }) : api.updateNode(node.id, { reference: null }))}>
                {t('props_unlink')}
              </button>
            )}
          </div>
          )
        : !forLane && <p className='flex items-center gap-1 text-xs text-warning'><Icon name='alert' size={12} />{t('props_no_reference')}</p>}
      {editable && searchUrl && (
        <>
          {groups.length > 1 && (
            <div className='flex flex-wrap gap-1'>
              {['', ...groups].map((g) => (
                <button key={g || 'all'} type='button' className={`badge badge-sm ${group === g ? 'badge-primary' : 'badge-ghost'}`} onClick={() => setGroup(g)}>
                  {g || '∗'}
                </button>
              ))}
            </div>
          )}
          <input type='search' className='input input-sm w-full' placeholder={t(forLane ? 'props_assignee_search' : 'props_search_reference')} value={query} onChange={(e) => setQuery(e.target.value)} />
          <div className='max-h-48 overflow-y-auto rounded border border-base-300'>
            {results === null && <p className='p-2 text-xs text-base-content/60'>{t('props_searching')}</p>}
            {results === false && <p className='p-2 text-xs text-error' role='alert' data-testid='bpmn-search-failed'>{t('props_search_failed')}</p>}
            {results && !results.length && <p className='p-2 text-xs text-base-content/60'>{t('props_no_results')}</p>}
            {results && groupBy(results).map(([name, items]) => (
              <div key={name || 'none'}>
                {name && <p className='bg-base-200 px-2 py-0.5 text-[11px] font-semibold uppercase text-base-content/60'>{name}</p>}
                {items.map((item) => (
                  <button key={`${item.group}-${item.id}`} type='button' className='block w-full px-2 py-1 text-left text-sm hover:bg-base-200' onClick={() => pick(item)}>
                    {item.label}
                    {item.description && <span className='block text-xs text-base-content/60'>{item.description}</span>}
                  </button>
                ))}
              </div>
            ))}
          </div>
        </>
      )}
      {editable && createUrl && (
        <button type='button' className='btn btn-outline btn-xs self-start' onClick={() => (forLane ? api.newLaneAssignee(lane.id) : api.newReference(node.id))}>
          <Icon name='plus' size={12} />{t(forLane ? 'props_new_assignee' : 'props_create_reference')}
        </button>
      )}
    </div>
  )
}
