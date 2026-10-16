import { strokeOf } from '../shapes.jsx'

// Minimap colours: each element's own outline colour (shapes.jsx), lanes by kind.
export function minimapColor (rfNode) {
  if (rfNode.type === 'lane') return rfNode.data.lane.kind === 'external' ? 'var(--color-base-300)' : 'var(--color-base-200)'
  return strokeOf(rfNode.data.node, rfNode.data.external)
}
