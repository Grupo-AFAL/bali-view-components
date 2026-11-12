// What the island holds from a document it is handed (the load, each 200,
// the comparison base): `normalize`, and under `layoutOptions.orientation`
// (Component `lock_orientation: :vertical`) turned as the toolbar's switch
// would turn it. Apart from document.js, which operations.js imports.
import { normalize } from './document.js'
import { needsLayout } from './layout.js'
import { setOrientation } from './operations.js'

export function load (data, layoutOptions) {
  const forced = layoutOptions && layoutOptions.orientation
  if (!forced) return normalize(data, layoutOptions)
  // Without coordinates it is laid out in that orientation, not turned after.
  if (needsLayout(data || {})) return normalize({ ...data, orientation: forced }, layoutOptions)
  const doc = normalize(data, layoutOptions)
  return doc.orientation === forced ? doc : setOrientation(doc, forced).doc
}

// A 200 is the document the island sent, in the forced orientation: one that
// leaves `orientation` out is in that one, not the contract's horizontal.
export function loadAnswer (body, layoutOptions) {
  const forced = layoutOptions && layoutOptions.orientation
  return load(forced && body && body.orientation == null ? { ...body, orientation: forced } : body, layoutOptions)
}
