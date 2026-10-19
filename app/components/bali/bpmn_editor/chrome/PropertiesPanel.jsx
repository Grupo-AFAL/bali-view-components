import { paletteKeyFor, isActivity, isEvent, isGateway } from '../model/catalog.js'
import { namedByReference } from '../model/document.js'
import Icon from './icons.jsx'
import FieldInput from './FieldInput.jsx'
import ReferencePicker from './ReferencePicker.jsx'
import NotesEditor from './NotesEditor.jsx'

// Mirrors Bali::BpmnEditor::Component::FIELD_TYPES (contract_test.rb).
export const FIELD_TYPES = ['text', 'textarea', 'number', 'select', 'multi_select', 'readonly']
const PORTS = ['auto', 'top', 'right', 'bottom', 'left']

function Field ({ label, children }) {
  return (
    <label className='flex flex-col gap-1'>
      <span className='text-xs font-semibold text-base-content/70'>{label}</span>
      {children}
    </label>
  )
}

function CustomFields ({ fields, values, onChange, editable, t }) {
  if (!fields || !fields.length) return null
  return fields.map((field) => (
    <Field key={field.key} label={field.label}>
      <FieldInput field={field} value={(values || {})[field.key]} disabled={!editable} t={t}
        onChange={(value) => onChange({ ...(values || {}), [field.key]: value })} />
    </Field>
  ))
}

function PortPicker ({ label, value, onChange, editable, t }) {
  return (
    <Field label={label}>
      <div className='join'>
        {PORTS.map((port) => (
          <button key={port} type='button' disabled={!editable}
            className={`btn btn-xs join-item ${(value || 'auto') === port ? 'btn-primary' : 'btn-outline'}`}
            onClick={() => onChange(port)}>
            {t(`port_${port}`)}
          </button>
        ))}
      </div>
    </Field>
  )
}

function NodeProperties ({ node, doc, api, t, editable, nodeFields, urls }) {
  const key = paletteKeyFor(node)
  const lane = doc.lanes.find((l) => String(l.id) === String(node.lane_id))
  const fields = [...(nodeFields['*'] || []), ...(nodeFields[node.type] || [])]
  const describe = isEvent(node) || isGateway(node) || isActivity(node)
  return (
    <>
      <p className='text-xs text-base-content/60'>{key ? t(`palette_${key}`) : node.type}{lane ? ` · ${lane.name || t('lane_unnamed')}` : ''}</p>
      <Field label={t('props_name')}>
        <input className='input input-sm w-full' value={node.name || ''} disabled={!editable || namedByReference(node)}
          title={namedByReference(node) ? t('props_name_from_reference') : undefined}
          onChange={(e) => api.updateNode(node.id, { name: e.target.value }, `name:${node.id}`)} />
        {namedByReference(node) && <span className='text-xs text-base-content/60'>{t('props_name_from_reference')}</span>}
      </Field>
      {describe && (
        <Field label={t('props_documentation')}>
          <textarea className='textarea textarea-sm w-full' rows={3} value={node.documentation || ''} disabled={!editable}
            placeholder={t('props_documentation_placeholder')}
            onChange={(e) => api.updateNode(node.id, { documentation: e.target.value }, `doc:${node.id}`)} />
        </Field>
      )}
      {node.event_definition && node.event_definition.kind === 'timer' && (
        <Field label={t('props_expression')}>
          <input className='input input-sm w-full font-mono' value={node.event_definition.expression || ''} disabled={!editable}
            placeholder='PT1H'
            onChange={(e) => api.updateNode(node.id, { event_definition: { ...node.event_definition, expression: e.target.value } }, `expr:${node.id}`)} />
        </Field>
      )}
      {node.type === 'sub_process' && (
        <ReferencePicker node={node} api={api} t={t} editable={editable} urls={urls} />
      )}
      <CustomFields fields={fields} values={node.fields} editable={editable} t={t}
        onChange={(values) => api.updateNode(node.id, { fields: values }, `fields:${node.id}`)} />
    </>
  )
}

function EdgeProperties ({ edge, doc, api, t, editable }) {
  const name = (id) => (doc.nodes.find((n) => String(n.id) === String(id)) || {}).name || t('unnamed')
  const ports = edge.ports || {}
  // A parallel split takes every path unconditionally (BPMN 2.0 §10.6.4): its
  // flows carry no condition, so no label either.
  const source = doc.nodes.find((n) => String(n.id) === String(edge.source))
  const unlabelled = source && source.type === 'parallel_gateway'
  return (
    <>
      <p className='text-sm'>{name(edge.source)} <span className='text-base-content/50'>→</span> {name(edge.target)}</p>
      <Field label={t('props_edge_label')}>
        <input className='input input-sm w-full' value={edge.label || ''} disabled={!editable || unlabelled}
          onChange={(e) => api.updateEdge(edge.id, { label: e.target.value }, `label:${edge.id}`)} />
      </Field>
      <PortPicker label={t('props_source_port')} value={ports.source} editable={editable} t={t}
        onChange={(port) => api.updateEdge(edge.id, { ports: { ...ports, source: port }, waypoints: [] })} />
      <PortPicker label={t('props_target_port')} value={ports.target} editable={editable} t={t}
        onChange={(port) => api.updateEdge(edge.id, { ports: { ...ports, target: port }, waypoints: [] })} />
      <button type='button' className='btn btn-outline btn-sm gap-1' disabled={!editable}
        onClick={() => api.updateEdge(edge.id, { ports: { source: 'auto', target: 'auto' }, waypoints: [] })}>
        <Icon name='route' size={14} />{t('props_reroute')}
      </button>
    </>
  )
}

function LaneProperties ({ lane, api, t, editable, laneFields, urls, canMove, externalLanes }) {
  const external = lane.kind === 'external'
  return (
    <>
      <Field label={t('props_name')}>
        <input className='input input-sm w-full' value={lane.name || ''} disabled={!editable}
          onChange={(e) => api.updateLane(lane.id, { name: e.target.value }, `lane:${lane.id}`)} />
      </Field>
      {externalLanes && (
        <label className='flex cursor-pointer items-start gap-2' data-testid='bpmn-lane-external'>
          <input type='checkbox' className='checkbox checkbox-sm mt-0.5' checked={external} disabled={!editable}
            onChange={(e) => api.updateLane(lane.id, { kind: e.target.checked ? 'external' : 'internal' })} />
          <span className='text-sm'>{t('props_lane_external')}
            <span className='block text-xs text-base-content/60'>{t('props_lane_external_hint')}</span>
          </span>
        </label>
      )}
      {urls.lane_assignees && <ReferencePicker lane={lane} api={api} t={t} editable={editable} urls={urls} />}
      <div className='flex gap-1'>
        <button type='button' className='btn btn-outline btn-xs gap-1' disabled={!editable || !canMove.up} onClick={() => api.moveLane(lane.id, -1)}>
          <Icon name='arrowUp' size={12} />{t('move_up')}
        </button>
        <button type='button' className='btn btn-outline btn-xs gap-1' disabled={!editable || !canMove.down} onClick={() => api.moveLane(lane.id, 1)}>
          <Icon name='arrowDown' size={12} />{t('move_down')}
        </button>
      </div>
      <CustomFields fields={laneFields} values={lane.fields} editable={editable} t={t}
        onChange={(values) => api.updateLane(lane.id, { fields: values }, `lanefields:${lane.id}`)} />
    </>
  )
}

function Participants ({ doc, t, onPick }) {
  const lanes = [...doc.lanes].sort((a, b) => (Number(a.order) || 0) - (Number(b.order) || 0))
  let internal = 0
  return (
    <ul className='flex flex-col gap-1'>
      {lanes.map((lane) => {
        const external = lane.kind === 'external'
        const count = doc.nodes.filter((n) => String(n.lane_id) === String(lane.id) && isActivity(n)).length
        if (!external) internal++
        return (
          <li key={lane.id}>
            <button type='button' className='flex w-full items-center gap-2 rounded px-2 py-1 text-left hover:bg-base-200' onClick={() => onPick(lane.id)}>
              <span className='badge badge-sm badge-ghost font-mono'>{external ? t('external_short') : `P-${String(internal).padStart(2, '0')}`}</span>
              <span className='grow text-sm'>{lane.name || t('lane_unnamed')}
                <span className='block text-xs text-base-content/60'>{t('participants_activities', { count })}{external ? ` · ${t('lane_external')}` : ''}</span>
              </span>
            </button>
          </li>
        )
      })}
    </ul>
  )
}

// The side panel: properties of what is selected (a node, a connection, a
// lane, several nodes) or the list of participants. Replaces the modal
// dialogs of the old editor.
export default function PropertiesPanel ({ t, doc, selection, api, editable, notesEditable = false, nodeFields, laneFields, urls, view, onClose, onPickLane, annotationTags = [], externalLanes = true }) {
  const nodes = selection.nodes.map((id) => doc.nodes.find((n) => String(n.id) === id)).filter(Boolean)
  const edge = selection.edges.length === 1 ? doc.edges.find((e) => String(e.id) === selection.edges[0]) : null
  const lane = selection.lanes.length === 1 ? doc.lanes.find((l) => String(l.id) === selection.lanes[0]) : null
  const order = [...doc.lanes].sort((a, b) => (Number(a.order) || 0) - (Number(b.order) || 0)).map((l) => String(l.id))
  let title = t('props_title')
  let body = <p className='text-sm text-base-content/60'>{t('props_empty')}</p>
  if (view === 'participants') {
    title = t('participants_title')
    body = <Participants doc={doc} t={t} onPick={onPickLane} />
  } else if (nodes.length > 1) {
    title = t('props_multi', { count: nodes.length })
    body = (
      <>
        <Field label={t('props_align')}>
          <div className='flex gap-1'>
            <button type='button' className='btn btn-outline btn-xs gap-1' disabled={!editable} onClick={() => api.align('vertical')}>
              <Icon name='alignV' size={12} />{t('align_vertical')}
            </button>
            <button type='button' className='btn btn-outline btn-xs gap-1' disabled={!editable} onClick={() => api.align('horizontal')}>
              <Icon name='alignH' size={12} />{t('align_horizontal')}
            </button>
          </div>
        </Field>
        <p className='text-xs text-base-content/60'>{t('props_align_note')}</p>
      </>
    )
  } else if (nodes.length === 1) {
    title = nodes[0].name || t('props_title')
    body = <NodeProperties node={nodes[0]} doc={doc} api={api} t={t} editable={editable} nodeFields={nodeFields} urls={urls} />
  } else if (edge) {
    title = t('props_edge')
    body = <EdgeProperties edge={edge} doc={doc} api={api} t={t} editable={editable} />
  } else if (lane) {
    title = t('props_lane_title')
    const index = order.indexOf(String(lane.id))
    body = <LaneProperties lane={lane} api={api} t={t} editable={editable} laneFields={laneFields} urls={urls} canMove={{ up: index > 0, down: index < order.length - 1 }} externalLanes={externalLanes} />
  }
  const target = nodes.length === 1 ? nodes[0] : edge
  const notes = target ? (doc.annotations || []).filter((a) => String(a.target_id) === String(target.id)) : []
  // `notesEditable`: a read-only diagram whose notes may be written (Component `annotatable:`).
  if (target && view !== 'participants' && (editable || notesEditable || notes.length)) {
    body = (
      <>
        {body}
        <NotesEditor
          t={t} notes={notes} tags={annotationTags} editable={editable || notesEditable}
          onAdd={() => api.addNote(target.id)} onChange={api.updateNote} onDelete={api.deleteNote}
        />
      </>
    )
  }
  const hasSelection = nodes.length || edge || lane
  return (
    <aside className='bpmn-chrome absolute bottom-3 right-3 top-14 z-10 flex w-72 flex-col rounded-lg border border-base-300 bg-base-100 shadow-lg' aria-label={title} data-testid='bpmn-properties'>
      <div className='flex items-center gap-2 border-b border-base-300 px-3 py-2'>
        <h3 className='grow truncate text-sm font-semibold' title={title}>{title}</h3>
        <button type='button' className='btn btn-ghost btn-xs btn-square' onClick={onClose} aria-label={t('close')}>
          <Icon name='x' size={14} />
        </button>
      </div>
      <div className='flex flex-1 flex-col gap-3 overflow-y-auto p-3'>{body}</div>
      {editable && view !== 'participants' && hasSelection && (
        <div className='border-t border-base-300 p-3'>
          <button type='button' className='btn btn-error btn-outline btn-sm w-full gap-1' onClick={api.deleteSelection} title='Supr / Delete'>
            <Icon name='trash' size={14} />{t('delete_selection')}
          </button>
        </div>
      )}
    </aside>
  )
}

