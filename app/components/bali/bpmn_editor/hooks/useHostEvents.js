import { useEffect } from 'react'
import * as ops from '../model/operations.js'

// What the host sends back (the bali_bpmn_event stream action, or its own
// CustomEvent): a reload, a reference or a lane assignee its drawer created.
// Only events dispatched on this editor's own element: one that bubbles up
// from another editor on the page, or one sent to document, names no editor
// and is not ours (two editors mint the same client ids).
export default function useHostEvents (hostElement, { reload, apply, docRef }) {
  useEffect(() => {
    if (!hostElement) return undefined
    const handlers = {
      'bali-bpmn:reload': () => reload(),
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
    return () => { for (const name of Object.keys(handlers)) hostElement.removeEventListener(name, listener) }
  }, [hostElement, reload, apply, docRef])
}
