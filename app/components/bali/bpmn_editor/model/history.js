// Undo/redo over whole documents. Pure, so the editor hook stays a thin
// wrapper and the behaviour is testable without React.
//
// `coalesce` merges consecutive commits that share a key into one undo step —
// typing a name letter by letter is one change, not twenty.
export const HISTORY_LIMIT = 100

export function initialHistory (doc) {
  return { past: [], present: doc, future: [], coalesce: null, revision: 0 }
}

export function commit (state, doc, { coalesce = null } = {}) {
  if (doc === state.present) return state
  const merge = coalesce && state.coalesce === coalesce
  const past = merge ? state.past : [...state.past, state.present].slice(-HISTORY_LIMIT)
  return { past, present: doc, future: [], coalesce, revision: state.revision + 1 }
}

export function undo (state) {
  if (!state.past.length) return state
  const present = state.past[state.past.length - 1]
  return { past: state.past.slice(0, -1), present, future: [state.present, ...state.future], coalesce: null, revision: state.revision + 1 }
}

export function redo (state) {
  if (!state.future.length) return state
  const [present, ...future] = state.future
  return { past: [...state.past, state.present], present, future, coalesce: null, revision: state.revision + 1 }
}

// The server's answer replaces the present without becoming an undo step and
// without counting as a local change.
export function adopt (state, doc) {
  return { ...state, present: doc }
}

// A reload (409, `bali-bpmn:reload`) starts a fresh history.
export function reset (state, doc) {
  return { past: [], present: doc, future: [], coalesce: null, revision: state.revision + 1 }
}
