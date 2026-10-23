// Saving the whole document (#1489 mutation contract), as a plain object the
// hook (hooks/useSaver.js) drives and the tests drive without React or HTTP.
//
// `revision` counts local changes. A save remembers the revision it carried;
// when the 200 comes back with no change made since, the server's document
// replaces the local one (it may have normalized ids or names). If the user
// kept editing meanwhile, only the new `version` and `issues` are taken and
// the newer local state is saved next — the server's copy is already older
// than what is on screen.
//
// A reset (409, reload) is itself the saved state: `onReset` applies it at
// once, so `latest()` already carries the reset's revision. It also starts a
// new `generation`: an answer to a request sent
// before the reset is ignored, or a late 200 would roll the version and the
// saved revision back to the document the reset just replaced.
//
// Requests are serialized: one save or finalize at a time, each carrying the
// version the previous answer gave. A save asked for meanwhile is sent after
// whichever of the two is in flight. The version is tracked apart from the
// document, so undoing to an older document never sends an older version.
//
// `deps`: { client: { save, fetch, finalize } (saveClient.js), urls, latest ()
// → { doc, revision } (the latest committed state, ahead of any render: the
// decisions below are taken on it), onAdopt (doc, { replace }), onReset (doc), onEvent
// (name, detail), notify (text, tone), t, setStatus (status), prepare (body →
// doc: normalize), forSave (doc → body), defer (fn: run it after this tick) }.
export function createSaver (deps, { version = null, revision = 0 } = {}) {
  let d = deps
  let versionNow = version
  let savedRevision = revision
  let generation = 0
  let pending = null // promise of the request in flight
  let queued = false

  const resetTo = (fresh) => {
    generation++
    versionNow = fresh.version ?? null
    d.onReset(d.prepare(fresh))
    savedRevision = d.latest().revision
  }

  // The save asked for while a request was in flight, now that it is not.
  const drain = () => {
    if (!queued) return
    queued = false
    d.defer(() => { save() })
  }

  const reloadAfterConflict = async () => {
    if (!d.urls.diagram) return false
    try {
      resetTo(await d.client.fetch(d.urls.diagram))
      d.notify(d.t('toast_conflict'), 'warning')
      d.setStatus('saved')
      return true
    } catch {
      return false
    }
  }

  const send = async () => {
    const { doc: sent, revision: sentRevision } = d.latest()
    if (sentRevision === savedRevision) return true
    const gen = generation
    d.setStatus('saving')
    try {
      const body = await d.client.save(d.urls.save, d.forSave(sent), versionNow)
      if (gen !== generation) return false
      versionNow = body.version ?? versionNow
      savedRevision = sentRevision
      const unchanged = d.latest().revision === sentRevision
      d.onAdopt(d.prepare(body), { replace: unchanged })
      d.setStatus(unchanged ? 'saved' : 'dirty')
      d.onEvent('saved', { document: body })
      return true
    } catch (error) {
      if (gen !== generation) return false
      if (error.conflict && await reloadAfterConflict()) return false
      d.setStatus('error')
      d.notify(error.errors && error.errors.length ? error.errors.join(' ') : d.t('change_failed'), 'error')
      return false
    }
  }

  const save = async () => {
    if (!d.urls.save) return false
    if (pending) { queued = true; return pending }
    pending = send()
    try {
      return await pending
    } finally {
      pending = null
      drain()
    }
  }

  // Waits for any save in flight, then posts the current document. The
  // server saves it either way, so a 422 still answers with the new
  // `version` (kept on the error) and its `issues`, which open the panel.
  const finalize = async () => {
    if (!d.urls.finalize) return { ok: false }
    for (let inFlight = pending; inFlight; inFlight = pending) await inFlight
    const { doc: current, revision: currentRevision } = d.latest()
    const gen = generation
    const request = d.client.finalize(d.urls.finalize, d.forSave(current), versionNow)
    pending = request.catch(() => {})
    try {
      const body = await request
      if (gen !== generation) return { ok: false }
      versionNow = body.version ?? versionNow
      savedRevision = currentRevision
      // Edited while the POST ran: what was finalized is not what is on
      // screen, and that change is still to be saved.
      const unchanged = d.latest().revision === currentRevision
      d.onAdopt(d.prepare(body), { replace: unchanged })
      d.setStatus(unchanged ? 'finalized' : 'dirty')
      d.onEvent('finalized', { document: body })
      return { ok: true }
    } catch (error) {
      if (gen !== generation) return { ok: false }
      if (error.version != null) {
        versionNow = error.version
        savedRevision = currentRevision
        d.setStatus(d.latest().revision === currentRevision ? 'saved' : 'dirty')
      }
      if (error.conflict && await reloadAfterConflict()) return { ok: false }
      if (error.issues) return { ok: false, issues: error.issues }
      d.setStatus('error')
      d.notify(error.errors && error.errors.length ? error.errors.join(' ') : d.t('change_failed'), 'error')
      return { ok: false }
    } finally {
      pending = null
      drain()
    }
  }

  const reload = async () => {
    if (!d.urls.diagram) return
    try {
      resetTo(await d.client.fetch(d.urls.diagram))
      d.setStatus('saved')
      d.notify(d.t('toast_reloaded'), 'info')
    } catch {
      d.notify(d.t('change_failed'), 'error')
    }
  }

  // The editor goes away (a Turbo visit, a drawer closing) with a change
  // still waiting for its debounce: with autosave it is sent, not dropped.
  const leave = ({ autosave, editable }) => {
    if (autosave && editable && d.latest().revision !== savedRevision) return save()
    return null
  }

  return {
    save,
    leave,
    finalize,
    reload,
    configure (next) { d = next },
    isDirty: (revisionNow) => revisionNow !== savedRevision,
    get version () { return versionNow },
    get busy () { return Boolean(pending) }
  }
}
