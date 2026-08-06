// HTTP client of the Gantt schedule (#705, ported from afal-apps). The server
// is AUTHORITATIVE: this module only posts edits (move/resize an item,
// add/remove a dependency) and returns the full recalculated schedule for
// React to reconcile. It never computes dates or the critical path.
//
// The mutation contract (reference implementation: the dummy app's
// Admin::Projects::SchedulesController):
//   PATCH  patchUrl         { item: { id, starts_on, duration_days } }
//   POST   dependenciesUrl  { dependency: { predecessor_id, successor_id, lag_days } }
//   DELETE dependenciesUrl/:id
//   → 200 with the COMPLETE document, 422 { errors: [...] } → rollback,
//     404 → the client re-GETs scheduleUrl.
//
// STALE response discard: a module-level monotonic `reqId` plus one
// AbortController per in-flight request. A new edit aborts the previous one;
// on resolve, a response whose reqId is no longer the latest is discarded so
// an old recalculation never overwrites a newer optimistic state.
import { get, patch, post, destroy } from '@rails/request.js'

let reqCounter = 0
let inFlight = null // AbortController of the in-flight request, if any.

// Aborts the in-flight request (if any), reserves a new reqId and returns its
// AbortController. The response only applies if its reqId is still the latest.
function nextRequest () {
  if (inFlight) inFlight.abort()
  const controller = new AbortController()
  inFlight = controller
  const id = ++reqCounter
  return { id, controller }
}

// Server validation error (422): carries the messages in `errors`.
export class ScheduleError extends Error {
  constructor (messages, statusCode) {
    super(Array.isArray(messages) ? messages.join('. ') : String(messages))
    this.name = 'ScheduleError'
    this.statusCode = statusCode
    this.messages = Array.isArray(messages) ? messages : [String(messages)]
  }
}

// Marker distinguishing "this response is stale, ignore it" from a failure.
const STALE = Symbol('stale')
export function isStale (value) {
  return value === STALE
}

// Settles a request: returns the parsed schedule if its reqId is still the
// latest; STALE if it was superseded; throws ScheduleError on 422 / !ok.
async function settle (id, response) {
  // Superseded by a newer edit → discard (never reconcile with old data).
  if (id !== reqCounter) return STALE
  inFlight = null

  if (response.ok) return response.json

  let messages = [`Error ${response.statusCode}`]
  try {
    const body = await response.json
    if (body && body.errors) messages = body.errors
  } catch {
    // non-JSON response; keep the status message.
  }
  throw new ScheduleError(messages, response.statusCode)
}

// GET the full schedule: re-syncs from the server when the local state went
// stale (e.g. an item was deleted elsewhere → PATCH 404). Does not use the
// reqId (it is a recovery, not an edit); returns the JSON or throws.
export async function fetchSchedule (scheduleUrl) {
  const response = await get(scheduleUrl, { responseKind: 'json' })
  if (response.ok) return response.json
  throw new ScheduleError([`Error ${response.statusCode}`], response.statusCode)
}

// PATCH move/resize: { item: { id, starts_on, duration_days } }.
// Returns the recalculated schedule, or STALE if a newer edit superseded it.
export async function patchItem (patchUrl, { id, startsOn, durationDays }) {
  const { id: reqId, controller } = nextRequest()
  let response
  try {
    response = await patch(patchUrl, {
      body: { item: { id, starts_on: startsOn, duration_days: durationDays } },
      responseKind: 'json',
      signal: controller.signal
    })
  } catch (err) {
    if (err && err.name === 'AbortError') return STALE
    throw err
  }
  return settle(reqId, response)
}

// POST a dependency: { dependency: { predecessor_id, successor_id, lag_days } }.
// The server validates cycles/self-links (422). Returns the schedule or STALE.
export async function addDependency (dependenciesUrl, { predecessorId, successorId, lagDays = 0 }) {
  const { id: reqId, controller } = nextRequest()
  let response
  try {
    response = await post(dependenciesUrl, {
      body: {
        dependency: {
          predecessor_id: predecessorId,
          successor_id: successorId,
          lag_days: lagDays
        }
      },
      responseKind: 'json',
      signal: controller.signal
    })
  } catch (err) {
    if (err && err.name === 'AbortError') return STALE
    throw err
  }
  return settle(reqId, response)
}

// DELETE a dependency by id. `dependenciesUrl` is the collection; the id is
// appended. Returns the recalculated schedule or STALE.
export async function removeDependency (dependenciesUrl, id) {
  const { id: reqId, controller } = nextRequest()
  const url = `${dependenciesUrl.replace(/\/$/, '')}/${id}`
  let response
  try {
    response = await destroy(url, { responseKind: 'json', signal: controller.signal })
  } catch (err) {
    if (err && err.name === 'AbortError') return STALE
    throw err
  }
  return settle(reqId, response)
}
