import { useEffect } from 'react'
import * as ops from '../model/operations.js'

// What the host sends back (the bali_bpmn_event stream action, or its own
// CustomEvent): a reload, a reference or a lane assignee its drawer created,
// the node to select (`bali-bpmn:select` { node_id }, null to clear).
// Only events dispatched on this editor's own element: one that bubbles up
// from another editor on the page, or one sent to document, names no editor
// and is not ours (two editors mint the same client ids).
export default function useHostEvents (hostElement, { reload, apply, docRef, onSelect, onBadges, onCompare, takeQueued }) {
  useEffect(() => {
    if (!hostElement) return undefined
    const handlers = {
      'bali-bpmn:reload': () => reload(),
      'bali-bpmn:select': (event) => {
        const detail = event.detail || {}
        if (onSelect) onSelect(detail.node_id == null ? null : String(detail.node_id))
      },
      // `bali-bpmn:badges` { visible }: the app shows or hides the badges, and
      // no `badges-change` answers it.
      'bali-bpmn:badges': (event) => {
        const detail = event.detail || {}
        if (onBadges && typeof detail.visible === 'boolean') onBadges(detail.visible)
      },
      // `bali-bpmn:compare` { index, mode }: opens, switches or closes
      // (`mode: null`) the comparison; `compare-change` says what is shown.
      'bali-bpmn:compare': (event) => { if (onCompare) onCompare(event.detail) },
      'bali-bpmn:reference-created': (event) => {
        const { client_node_id: nodeId, reference } = event.detail || {}
        if (!nodeId || !reference || !docRef.current.nodes.some((n) => String(n.id) === String(nodeId))) return
        apply((d) => ops.updateNode(d, nodeId, { reference, name: reference.label }))
      },
      'bali-bpmn:lane-assignee-created': (event) => {
        const { client_lane_id: laneId, assignee } = event.detail || {}
        if (!laneId || !assignee || !docRef.current.lanes.some((l) => String(l.id) === String(laneId))) return
        apply((d) => ops.updateLane(d, laneId, { assignee, name: assignee.label }))
      }
    }
    const listener = (event) => { if (event.target === hostElement) handlers[event.type](event) }
    for (const name of Object.keys(handlers)) hostElement.addEventListener(name, listener)
    // What the app sent before this listener existed (hostEventQueue.js), in
    // order. After this effect, not inside it: a handler may flushSync.
    const queued = takeQueued ? takeQueued() : []
    if (queued.length) queueMicrotask(() => { for (const event of queued) handlers[event.type](event) })
    return () => { for (const name of Object.keys(handlers)) hostElement.removeEventListener(name, listener) }
  }, [hostElement, reload, apply, docRef, onSelect, onBadges, onCompare, takeQueued])
}
