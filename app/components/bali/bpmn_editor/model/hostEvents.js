import * as ops from './operations.js'
import { findLane } from './document.js'
import { safeUrl } from './urls.js'

// What the host sends back (the bali_bpmn_event stream action, or its own
// CustomEvent), by event name: a reload, a reference or a lane assignee its
// drawer created, the node to select (`bali-bpmn:select` { node_id }, null to
// clear). Bound to the editor by hooks/useHostEvents.js.
// As chrome/ReferencePicker.jsx: a URL that is not a path or http(s) is not
// saved, or the host's next render raises on it (Data#navigable_url!).
const navigable = (holder) => ({ ...holder, url: safeUrl(holder.url) })

export function hostEventHandlers ({ reload, apply, docRef, onSelect, onBadges, onCompare }) {
  return {
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
      apply((d) => ops.updateNode(d, nodeId, { reference: navigable(reference), name: reference.label }))
    },
    // As picking the assignee in the search (chrome/ReferencePicker.jsx): a
    // lane the person already named keeps its name.
    'bali-bpmn:lane-assignee-created': (event) => {
      const { client_lane_id: laneId, assignee } = event.detail || {}
      if (!laneId || !assignee || !findLane(docRef.current, laneId)) return
      apply((d) => ops.updateLane(d, laneId, { assignee: navigable(assignee), name: findLane(d, laneId).name || assignee.label }))
    }
  }
}

// What the app sent before the island listened (hostEventQueue.js) is applied
// in order, and only then is `ready` announced: what the app sends on hearing
// it lands after the queue, not under it. In a microtask, after the effect
// that started listening: a handler may flushSync.
export function replayThenReady (queued, handle, ready) {
  queueMicrotask(() => {
    for (const event of queued) handle(event)
    ready()
  })
}
