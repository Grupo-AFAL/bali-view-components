/**
 * Per-device memory of a DataTable's column visibility. Written by the column selector, and
 * read by the saved-views control when no selector is on screen (cards, calendar).
 *
 * THE KEY NAME NEVER CHANGES: `bali:columns:<listing_id>` (`ListingIdentity`). Host apps
 * assert on that exact string, and renaming it would orphan every user's preference without
 * saying so. The VALUE is what carries the version.
 *
 * Format v2:
 *
 *   { "v": 2, "hidden": [3], "known": [0, 1, 2, 3], "serverHidden": [3] }
 *
 * A user's decision is the DIFFERENCE between `hidden` (what was off screen) and
 * `serverHidden` (what the host declared `visible: false` at the time). `known` is the set of
 * columns the selector declared, so a column the memory never saw is no decision either:
 *
 *   hidden ∧ ¬serverHidden → the user hid it     → hide
 *   ¬hidden ∧ serverHidden → the user showed it  → show
 *   hidden = serverHidden  → nobody decided      → the server wins
 *   ∉ known                → never seen          → the server wins
 *
 * Both baselines earn their place. Without `serverHidden`, a column the host declared
 * `visible: false` and the user never touched is recorded as the user's own preference on the
 * first write, and a later `visible: true` from the host never reaches them. Without `known`
 * — v1, a bare list of visible indices — a column added later is born hidden, which is #1144.
 *
 * Format v3 is v2 with column IDS in the lists: a String is a column's `key:`, an Integer the
 * index of a column without one — inserting a column moves every index after it (#1213). v3
 * is only written when the selector declares a key: a table without keys writes exactly what it
 * wrote before, and a rollback to ≤3.6.0 still reads it. v1 and v2 are read as positions against
 * the current layout (`positional: true`) and rewritten as v3.
 */

const POSITIONS_VERSION = 2
const IDS_VERSION = 3

// How the memory and a saved view name the column a checkbox toggles.
export const columnId = (checkbox) =>
  checkbox.dataset.columnKey || parseInt(checkbox.dataset.columnIndex, 10)

// Valid indices are 0..255; a real table is nowhere near. The ceiling is there so a corrupt
// value — `[999999999]` written by something else — cannot make `fromLegacy` build a
// billion-entry array and hang the page.
const MAX_TRACKED_COLUMNS = 256

// Sanitised column indices: integers, non-negative, under the ceiling, deduped and sorted.
// The value comes from `localStorage`, that is, from outside the program.
const columnIndices = (value) => {
  if (!Array.isArray(value)) return []

  const seen = new Set()
  for (const entry of value) {
    const index = parseInt(entry, 10)
    if (!isNaN(index) && index >= 0 && index < MAX_TRACKED_COLUMNS) seen.add(index)
  }

  return [...seen].sort((a, b) => a - b)
}

// Must match ColumnSelector::Component::KEY.
const COLUMN_KEY = /^[A-Za-z_][\w-]{0,63}$/

const columnIds = (value) => {
  if (!Array.isArray(value)) return []

  const keys = [...new Set(value.filter((entry) => typeof entry === 'string' && COLUMN_KEY.test(entry)))]

  return [...columnIndices(value.filter((entry) => typeof entry === 'number')), ...keys.sort()]
}

/**
 * v1 was a bare array of VISIBLE indices with no record of which columns existed. All such a
 * value PROVES it knew is up to its highest index; above that there is no evidence the column
 * was there, so it is treated as new and shown.
 *
 * Measured cost of that inference, and bounded: if what the user had hidden was the LAST
 * column of the table, it comes back once — that preference is indistinguishable from a column
 * that did not exist. Everything below the ceiling is preserved intact.
 *
 * An empty v1 (`[]`) proves it knew no column at all, so nothing migrates and the listing goes
 * back to its defaults. `serverHidden` is `null`: v1 recorded no baseline, and the caller
 * decides what to read in its place.
 */
const fromLegacy = (visible) => {
  const ceiling = Math.max(-1, ...visible)
  const known = []
  for (let index = 0; index <= ceiling; index++) known.push(index)

  return {
    hidden: known.filter((index) => !visible.includes(index)),
    known,
    serverHidden: null,
    stale: true,
    positional: true
  }
}

/**
 * Reads the memory at `key`. Returns `{ hidden, known, serverHidden, stale, positional }` —
 * always in the same shape, whatever format was stored — or `null` when there is nothing
 * readable. `positional` says the lists hold indices (v1, v2) rather than ids (v3).
 *
 * `serverHidden` is `null` when the stored value recorded no baseline: all of v1, and a v2
 * missing the list. `stale: true` says the caller may rewrite it so the inference does not run
 * on every load; nobody is obliged to.
 *
 * A future version (v4) reads as `null` and is left untouched: falling back to the server's
 * defaults beats misreading a format this code does not know.
 */
export function readColumnState (key) {
  if (!key) return null

  let raw
  try {
    raw = window.localStorage.getItem(key)
  } catch { return null }
  if (!raw) return null

  let parsed
  try {
    parsed = JSON.parse(raw)
  } catch { return null }

  if (Array.isArray(parsed)) return fromLegacy(columnIndices(parsed))
  if (!parsed || ![POSITIONS_VERSION, IDS_VERSION].includes(parsed.v)) return null

  const ids = parsed.v === IDS_VERSION ? columnIds : columnIndices
  const baseline = Array.isArray(parsed.serverHidden) ? ids(parsed.serverHidden) : null

  return {
    hidden: ids(parsed.hidden),
    known: ids(parsed.known),
    serverHidden: baseline,
    stale: baseline === null,
    positional: parsed.v === POSITIONS_VERSION
  }
}

export function writeColumnState (key, { hidden, known, serverHidden }) {
  if (!key) return

  const keyed = known.some((id) => typeof id === 'string')
  const ids = keyed ? columnIds : columnIndices
  const value = {
    v: keyed ? IDS_VERSION : POSITIONS_VERSION,
    hidden: ids(hidden),
    known: ids(known),
    serverHidden: ids(serverHidden)
  }

  try {
    window.localStorage.setItem(key, JSON.stringify(value))
  } catch { /* storage full or blocked: the session runs on without persisting */ }
}

/**
 * The VISIBLE columns according to the memory, or `null` when there is none. That is what a
 * saved view's payload needs, and it is still — deliberately — a list of visible columns (ids,
 * or indices from a positional memory); see `saved_views_controller#storedColumns`.
 *
 * Derived from `known \ hidden`, that is from the RESOLVED state and not from the decisions: a
 * column the host declared hidden and the user never touched is not on screen, so it does not
 * belong in the view either.
 */
export function visibleColumns (state) {
  if (!state) return null

  return state.known.filter((id) => !state.hidden.includes(id))
}
