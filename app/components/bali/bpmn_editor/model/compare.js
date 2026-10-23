// Which comparison is open and how (`compare_open:`, `compare_index:`, the
// `bali-bpmn:compare` event): { index, mode } with mode null while closed.

// Mirrors Bali::BpmnEditor::Component::COMPARE_MODES (contract_test.rb).
export const COMPARE_MODES = ['side_by_side', 'overlay']
export const DEFAULT_COMPARE_MODE = 'side_by_side'

// `compare_open:` as it arrives ('true', a mode, '' when closed) → a mode or null.
export function openMode (value) {
  if (value === true || value === 'true') return DEFAULT_COMPARE_MODE
  return COMPARE_MODES.includes(value) ? value : null
}

// The comparison after `bali-bpmn:compare` { index, mode } — or null when the
// detail asks for something there is not (an index out of `count`, an
// unknown mode), and the event is dropped. `mode: null` closes; an omitted
// index keeps the current one, an omitted mode keeps the open one.
export function requestedComparison (current, detail, count) {
  if (!count || !detail || typeof detail !== 'object') return null
  if (detail.mode === null) return { index: current.index, mode: null }
  const index = detail.index === undefined ? current.index : detail.index
  if (!Number.isInteger(index) || index < 0 || index >= count) return null
  const mode = detail.mode === undefined ? current.mode || DEFAULT_COMPARE_MODE : openMode(detail.mode)
  return mode ? { index, mode } : null
}

// What is drawn: the overlay only for versions of one process
// (diff.sameProcess); asked for elsewhere, side by side.
export const shownMode = (mode, sameProcess) => (mode === 'overlay' && !sameProcess ? 'side_by_side' : mode)
