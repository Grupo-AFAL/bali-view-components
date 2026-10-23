import { test } from 'node:test'
import assert from 'node:assert/strict'
import { createSaver } from '../../../app/components/bali/bpmn_editor/model/saver.js'

// A deferred promise: the test decides when (and how) a request answers.
function deferred () {
  let resolve, reject
  const promise = new Promise((_resolve, _reject) => { resolve = _resolve; reject = _reject })
  return { promise, resolve, reject }
}
const conflict = () => Object.assign(new Error('409'), { conflict: true, errors: [] })
const invalid = (body) => Object.assign(new Error('422'), { conflict: false, errors: body.errors || [], issues: body.issues || null, version: body.version ?? null })

// The editor around the saver: a document and its revision, and a log of
// what the saver told it.
function harness ({ version = 1, urls = { save: '/s', diagram: '/d', finalize: '/f' } } = {}) {
  const state = { doc: { version, nodes: [] }, revision: 0 }
  const log = { adopted: [], reset: [], events: [], notices: [], statuses: [], sent: [] }
  const calls = { save: [], fetch: [], finalize: [] }
  const client = {
    save: (url, body, v) => { const d = deferred(); calls.save.push({ body, version: v, ...d }); return d.promise },
    fetch: (url) => { const d = deferred(); calls.fetch.push(d); return d.promise },
    finalize: (url, body, v) => { const d = deferred(); calls.finalize.push({ body, version: v, ...d }); return d.promise }
  }
  const deferredRuns = []
  const saver = createSaver({
    client,
    urls,
    latest: () => state,
    onAdopt: (doc, options) => log.adopted.push({ doc, ...options }),
    // The editor's store takes the reset at once, ahead of React's render:
    // `latest()` already carries it when onReset returns.
    onReset: (doc) => { log.reset.push(doc); state.doc = doc; state.revision++ },
    onEvent: (name) => log.events.push(name),
    notify: (text, tone) => log.notices.push(tone),
    t: (key) => key,
    setStatus: (s) => log.statuses.push(s),
    prepare: (body) => body,
    forSave: (doc) => doc,
    defer: (fn) => deferredRuns.push(fn)
  }, { version, revision: 0 })
  const edit = () => { state.revision++ }
  const tick = () => new Promise((resolve) => setImmediate(resolve))
  return { state, log, calls, saver, edit, tick, deferredRuns }
}

test('nothing to save while the revision is the saved one', async () => {
  const h = harness()
  assert.equal(await h.saver.save(), true)
  assert.equal(h.calls.save.length, 0)
})

test('a 200 with no edit since replaces the local document and carries the new version into the next save', async () => {
  const h = harness()
  h.edit()
  const saving = h.saver.save()
  h.calls.save[0].resolve({ version: 2, nodes: ['server'] })
  assert.equal(await saving, true)
  assert.deepEqual(h.log.adopted.at(-1), { doc: { version: 2, nodes: ['server'] }, replace: true })
  assert.equal(h.saver.isDirty(h.state.revision), false)
  h.edit()
  h.saver.save()
  assert.equal(h.calls.save[1].version, 2)
})

test('edits made while a save is in flight keep the local document, and are saved next', async () => {
  const h = harness()
  h.edit()
  const saving = h.saver.save()
  h.edit()
  h.calls.save[0].resolve({ version: 2 })
  await saving
  assert.equal(h.log.adopted.at(-1).replace, false)
  assert.equal(h.log.statuses.at(-1), 'dirty')
  assert.equal(h.saver.isDirty(h.state.revision), true)
})

test('a save asked for while one is in flight is queued and sent after it, one request at a time', async () => {
  const h = harness()
  h.edit()
  const first = h.saver.save()
  h.edit()
  const second = h.saver.save()
  assert.equal(h.calls.save.length, 1, 'still one request')
  h.calls.save[0].resolve({ version: 2 })
  await first
  await second
  assert.equal(h.deferredRuns.length, 1, 'the queued save runs after this one')
  h.deferredRuns[0]()
  assert.equal(h.calls.save.length, 2)
  assert.equal(h.calls.save[1].version, 2)
})

// The scenario: a 409 while the person kept editing, so a save is queued.
// That save must not send the local document, with the version the reload
// brought, over the concurrent change the 409 protected.
test('a save queued behind a 409 sends nothing: the reloaded document is the saved one', async () => {
  const h = harness()
  h.edit()
  const saving = h.saver.save()
  h.edit()
  h.saver.save()
  h.calls.save[0].reject(conflict())
  await h.tick()
  h.calls.fetch[0].resolve({ version: 7, nodes: ['theirs'] })
  await saving
  assert.equal(h.deferredRuns.length, 1)
  await h.deferredRuns[0]()
  assert.equal(h.calls.save.length, 1, 'no second PUT')
  assert.equal(h.saver.isDirty(h.state.revision), false)
})

test('a 409 on save reloads the server document as the new saved state', async () => {
  const h = harness()
  h.edit()
  const saving = h.saver.save()
  h.calls.save[0].reject(conflict())
  await h.tick()
  h.calls.fetch[0].resolve({ version: 7, nodes: ['theirs'] })
  assert.equal(await saving, false)
  assert.deepEqual(h.log.reset.at(-1), { version: 7, nodes: ['theirs'] })
  assert.equal(h.saver.version, 7)
  assert.equal(h.saver.isDirty(h.state.revision), false)
  assert.ok(h.log.notices.includes('warning'))
})

test('an answer to a request sent before a reload is ignored', async () => {
  const h = harness()
  h.edit()
  const saving = h.saver.save()
  const reloading = h.saver.reload()
  h.calls.fetch[0].resolve({ version: 9 })
  await reloading
  h.calls.save[0].resolve({ version: 3 })
  assert.equal(await saving, false)
  assert.equal(h.saver.version, 9, 'the late 200 does not roll the version back')
  assert.equal(h.log.adopted.length, 0)
})

test('finalize waits for the save in flight, then posts with the version that save brought', async () => {
  const h = harness()
  h.edit()
  h.saver.save()
  const finalizing = h.saver.finalize()
  await h.tick()
  assert.equal(h.calls.finalize.length, 0, 'not while the save is in flight')
  h.calls.save[0].resolve({ version: 2 })
  await h.tick(); await h.tick()
  assert.equal(h.calls.finalize[0].version, 2)
  h.calls.finalize[0].resolve({ version: 3 })
  assert.deepEqual(await finalizing, { ok: true })
  assert.equal(h.log.statuses.at(-1), 'finalized')
})

// The scenario: «Finalize», then a rename while the POST runs; its debounce
// asks for a save, which waits for the finalize and is then sent.
test('a save asked for while finalize is in flight is sent after it, and the status says it is pending', async () => {
  const h = harness()
  const finalizing = h.saver.finalize()
  h.edit()
  h.saver.save()
  assert.equal(h.calls.save.length, 0, 'not while the finalize is in flight')
  h.calls.finalize[0].resolve({ version: 3 })
  assert.deepEqual(await finalizing, { ok: true })
  assert.equal(h.log.adopted.at(-1).replace, false, 'the edit stays on screen')
  assert.equal(h.log.statuses.at(-1), 'dirty', 'not «finalized» with a change unsaved')
  assert.equal(h.deferredRuns.length, 1, 'the queued save runs after the finalize')
  h.deferredRuns[0]()
  assert.equal(h.calls.save.length, 1)
  assert.equal(h.calls.save[0].version, 3)
})

test('a finalize the server refuses still moves the version on and hands back its issues', async () => {
  const h = harness()
  const finalizing = h.saver.finalize()
  h.calls.finalize[0].reject(invalid({ version: 4, issues: [{ rule: 'R07' }] }))
  assert.deepEqual(await finalizing, { ok: false, issues: [{ rule: 'R07' }] })
  assert.equal(h.saver.version, 4)
})

test('a 409 on finalize reloads the server document', async () => {
  const h = harness()
  const finalizing = h.saver.finalize()
  h.calls.finalize[0].reject(conflict())
  await h.tick()
  h.calls.fetch[0].resolve({ version: 8 })
  assert.deepEqual(await finalizing, { ok: false })
  assert.equal(h.saver.version, 8)
})

test('a finalize the server refuses saved the draft: the status says saved, or dirty if edited meanwhile', async () => {
  const h = harness()
  h.edit()
  const finalizing = h.saver.finalize()
  h.calls.finalize[0].reject(invalid({ version: 4, issues: [{ rule: 'R07' }] }))
  await finalizing
  assert.equal(h.log.statuses.at(-1), 'saved')
  assert.equal(h.saver.isDirty(h.state.revision), false)

  const edited = harness()
  edited.edit()
  const again = edited.saver.finalize()
  edited.edit()
  edited.calls.finalize[0].reject(invalid({ version: 4, issues: [{ rule: 'R07' }] }))
  await again
  assert.equal(edited.log.statuses.at(-1), 'dirty')
})

test('a 409 on finalize with no diagram url to reload from says it failed, as a save does', async () => {
  const h = harness({ urls: { save: '/s', finalize: '/f' } })
  const finalizing = h.saver.finalize()
  h.calls.finalize[0].reject(conflict())
  assert.deepEqual(await finalizing, { ok: false })
  assert.deepEqual(h.log.notices, ['error'])
  assert.equal(h.log.statuses.at(-1), 'error')
})

test('leaving with a change waiting is a save with autosave on, and nothing otherwise', () => {
  const h = harness()
  h.edit()
  assert.equal(h.saver.leave({ autosave: false, editable: true }), null)
  assert.equal(h.calls.save.length, 0)
  assert.ok(h.saver.leave({ autosave: true, editable: true }))
  assert.equal(h.calls.save.length, 1)
  const clean = harness()
  assert.equal(clean.saver.leave({ autosave: true, editable: true }), null, 'nothing waiting, nothing sent')
})

test('reload replaces the document and says so; a failed one only says so', async () => {
  const h = harness()
  const reloading = h.saver.reload()
  h.calls.fetch[0].resolve({ version: 5 })
  await reloading
  assert.equal(h.saver.version, 5)
  assert.deepEqual(h.log.notices, ['info'])
  const failing = h.saver.reload()
  h.calls.fetch[1].reject(new Error('offline'))
  await failing
  assert.deepEqual(h.log.notices, ['info', 'error'])
  assert.equal(h.saver.version, 5)
})
