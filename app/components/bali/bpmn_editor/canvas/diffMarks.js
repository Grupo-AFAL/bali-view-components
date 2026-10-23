// What marks a compared element besides its colour (WCAG 1.4.1: colour is
// never the only cue): a symbol on the node and on the connection, with its
// words for assistive technology. The tones are daisyUI's, whose `-content`
// colours keep the symbol legible on them in a light and a dark theme.
export const DIFF_MARKS = {
  added: { symbol: '+', tone: 'success', label: 'compare_added' },
  removed: { symbol: '−', tone: 'error', label: 'compare_removed' },
  changed: { symbol: '✎', tone: 'warning', label: 'compare_changed' },
  moved: { symbol: '⇄', tone: 'warning', label: 'compare_moved_lane' }
}

// The mark of a state ('added' | 'removed' | 'changed') and its reasons: a
// change that moved the element to another lane is marked as moved.
export const diffMark = (state, reasons) => (state === 'changed' && reasons && reasons.includes('lane') ? 'moved' : state)
