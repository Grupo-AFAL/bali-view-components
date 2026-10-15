import { categoryOf } from '../model/catalog.js'

// Minimap colours by element family, the same families the canvas paints.
const FAMILY = {
  activity: 'var(--color-primary)',
  gateway: 'var(--color-warning)',
  event: 'var(--color-warning)',
  artifact: 'var(--color-base-300)',
  data: 'var(--color-base-300)',
  unknown: 'var(--color-base-300)'
}

export function minimapColor (rfNode) {
  if (rfNode.type === 'lane') return rfNode.data.lane.kind === 'external' ? 'var(--color-base-300)' : 'var(--color-base-200)'
  const node = rfNode.data.node
  if (node.type === 'start_event') return 'var(--color-success)'
  if (node.type === 'end_event') return 'var(--color-error)'
  if (node.type === 'sub_process') return 'var(--color-secondary)'
  return FAMILY[categoryOf(node)]
}
