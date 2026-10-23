// HTTP side of the save contract (docs/api/bpmn-editor.md):
//
//   PUT  urls.save      { diagram, version } → 200 document · 409 stale · 422 { errors }
//   GET  urls.diagram                        → 200 document
//   POST urls.finalize  { diagram, version } → 200 document · 422 { errors, issues, version }
//   PUT  urls.annotations { annotations, version } → as urls.save (Component `annotatable:`)
//
// Every answer that succeeds is the COMPLETE document: the server is
// authoritative, the island never patches.
import { get, put, post } from '@rails/request.js'

export class SaveError extends Error {
  constructor (statusCode, body = {}) {
    const errors = Array.isArray(body.errors) ? body.errors : []
    super(errors.join('. ') || `HTTP ${statusCode}`)
    this.name = 'SaveError'
    this.statusCode = statusCode
    this.errors = errors
    this.issues = Array.isArray(body.issues) ? body.issues : null
    // A failed finalize was still saved: the 422 carries the new version.
    this.version = body.version ?? null
  }

  get conflict () { return this.statusCode === 409 }
}

async function settle (request) {
  let response
  try {
    response = await request()
  } catch {
    throw new SaveError(0)
  }
  let body = {}
  try {
    body = await response.json
  } catch {
    body = {}
  }
  if (response.ok) return body
  throw new SaveError(response.statusCode, body || {})
}

export const saveDocument = (url, diagram, version) =>
  settle(() => put(url, { body: { diagram, version }, responseKind: 'json' }))

export const fetchDocument = (url) =>
  settle(() => get(url, { responseKind: 'json' }))

export const finalizeDocument = (url, diagram, version) =>
  settle(() => post(url, { body: { diagram, version }, responseKind: 'json' }))

// Review notes on a read-only diagram: only `annotations` travel.
export const saveAnnotations = (url, annotations, version) =>
  settle(() => put(url, { body: { annotations, version }, responseKind: 'json' }))
