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
 */

export const COLUMN_STORAGE_VERSION = 2

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
    stale: true
  }
}

/**
 * Reads the memory at `key`. Returns `{ hidden, known, serverHidden, stale }` — always in the
 * v2 shape, whatever format was stored — or `null` when there is nothing readable.
 *
 * `serverHidden` is `null` when the stored value recorded no baseline: all of v1, and a v2
 * missing the list. `stale: true` says the caller may rewrite it so the inference does not run
 * on every load; nobody is obliged to.
 *
 * A future version (v3) reads as `null` and is left untouched: falling back to the server's
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
  if (!parsed || parsed.v !== COLUMN_STORAGE_VERSION) return null

  const baseline = Array.isArray(parsed.serverHidden) ? columnIndices(parsed.serverHidden) : null

  return {
    hidden: columnIndices(parsed.hidden),
    known: columnIndices(parsed.known),
    serverHidden: baseline,
    stale: baseline === null
  }
}

export function writeColumnState (key, { hidden, known, serverHidden }) {
  if (!key) return

  const value = {
    v: COLUMN_STORAGE_VERSION,
    hidden: columnIndices(hidden),
    known: columnIndices(known),
    serverHidden: columnIndices(serverHidden)
  }

  try {
    window.localStorage.setItem(key, JSON.stringify(value))
  } catch { /* storage full or blocked: the session runs on without persisting */ }
}

/**
 * The VISIBLE columns according to the memory, or `null` when there is none. That is what a
 * saved view's payload needs, and it is still — deliberately — a list of visible indices; see
 * `saved_views_controller#storedColumns`.
 *
 * Derived from `known \ hidden`, that is from the RESOLVED state and not from the decisions: a
 * column the host declared hidden and the user never touched is not on screen, so it does not
 * belong in the view either.
 */
export function visibleColumns (state) {
  if (!state) return null

  return state.known.filter((index) => !state.hidden.includes(index))
}
