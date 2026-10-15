import { useCallback, useEffect, useRef, useState } from 'react'
import { saveDocument, fetchDocument, finalizeDocument } from '../saveClient.js'
import { forSave, normalize } from '../model/document.js'

const AUTOSAVE_DELAY = 1200

// Saving the whole document (#1489 mutation contract).
//
// `revision` counts local changes. A save remembers the revision it carried;
// when the 200 comes back with no change made since, the server's document
// replaces the local one (it may have normalized ids or names). If the user
// kept editing meanwhile, only the new `version` and `issues` are taken and
// the newer local state is saved next — the server's copy is already older
// than what is on screen.
//
// A reset (409, reload) bumps the revision by exactly one and is itself the
// saved state. It also starts a new `generation`: an answer to a request sent
// before the reset is ignored, or a late 200 would roll the version and the
// saved revision back to the document the reset just replaced.
//
// Requests are serialized: one save or finalize at a time, each carrying the
// version the previous answer gave. The version is tracked apart from the
// document, so undoing to an older document never sends an older version.
export default function useSaver ({ doc, revision, urls, editable, autosave, onAdopt, onReset, onEvent, notify, t }) {
  const [status, setStatus] = useState('saved')
  const [finalizing, setFinalizing] = useState(false)
  const versionRef = useRef(doc.version ?? null)
  const savedRevision = useRef(revision)
  const generation = useRef(0)
  const pending = useRef(null) // promise of the request in flight
  const queued = useRef(false)
  const timer = useRef(null)
  const latest = useRef({ doc, revision })
  latest.current = { doc, revision }
  const dirty = revision !== savedRevision.current
  const dirtyRef = useRef(dirty)
  dirtyRef.current = dirty

  const resetTo = useCallback((fresh) => {
    generation.current++
    versionRef.current = fresh.version ?? null
    onReset(normalize(fresh))
    savedRevision.current = latest.current.revision + 1
  }, [onReset])

  const reloadAfterConflict = useCallback(async () => {
    if (!urls.diagram) return false
    try {
      resetTo(await fetchDocument(urls.diagram))
      notify(t('toast_conflict'), 'warning')
      setStatus('saved')
      return true
    } catch {
      return false
    }
  }, [urls.diagram, resetTo, notify, t])

  const send = useCallback(async () => {
    const { doc: sent, revision: sentRevision } = latest.current
    if (sentRevision === savedRevision.current) return true
    const gen = generation.current
    setStatus('saving')
    try {
      const body = await saveDocument(urls.save, forSave(sent), versionRef.current)
      if (gen !== generation.current) return false
      versionRef.current = body.version ?? versionRef.current
      savedRevision.current = sentRevision
      const unchanged = latest.current.revision === sentRevision
      onAdopt(normalize(body), { replace: unchanged })
      setStatus(unchanged ? 'saved' : 'dirty')
      onEvent('saved', { document: body })
      return true
    } catch (error) {
      if (gen !== generation.current) return false
      if (error.conflict && await reloadAfterConflict()) return false
      setStatus('error')
      notify(error.errors && error.errors.length ? error.errors.join(' ') : t('change_failed'), 'error')
      return false
    }
  }, [urls.save, onAdopt, onEvent, notify, t, reloadAfterConflict])

  const save = useCallback(async () => {
    if (!editable || !urls.save) return false
    clearTimeout(timer.current)
    if (pending.current) { queued.current = true; return pending.current }
    pending.current = send()
    try {
      return await pending.current
    } finally {
      pending.current = null
      if (queued.current) {
        queued.current = false
        setTimeout(() => { save() }, 0)
      }
    }
  }, [editable, urls.save, send])

  useEffect(() => {
    if (!dirty) return
    setStatus((s) => (s === 'saving' ? s : 'dirty'))
    if (!autosave || !editable) return
    timer.current = setTimeout(() => { save() }, AUTOSAVE_DELAY)
    return () => clearTimeout(timer.current)
  }, [revision, dirty, autosave, editable, save])

  // Only a change of `dirty` is news; a new onEvent identity is not.
  const onEventRef = useRef(onEvent)
  onEventRef.current = onEvent
  useEffect(() => { onEventRef.current('dirty-change', { dirty }) }, [dirty])

  // Leaving with unsaved changes. A full page load asks the browser to warn;
  // a Turbo visit fires no beforeunload, so with autosave the pending change
  // is sent right away (the request outlives the page), and without it the
  // visitor confirms.
  useEffect(() => {
    if (!dirty) return
    const warn = (event) => { event.preventDefault(); event.returnValue = '' }
    const beforeVisit = (event) => {
      if (autosave) { save(); return }
      if (!window.confirm(t('unsaved_changes'))) event.preventDefault()
    }
    window.addEventListener('beforeunload', warn)
    document.addEventListener('turbo:before-visit', beforeVisit)
    return () => {
      window.removeEventListener('beforeunload', warn)
      document.removeEventListener('turbo:before-visit', beforeVisit)
    }
  }, [dirty, autosave, save, t])

  // Unmounted with a change still waiting for its debounce (a Turbo visit, a
  // drawer closing): send it instead of dropping it.
  const saveRef = useRef(save)
  saveRef.current = save
  useEffect(() => () => {
    if (dirtyRef.current && autosave && editable) saveRef.current()
  }, [autosave, editable])

  // "Finalize": waits for any save in flight, then posts the current document.
  // The server saves it either way, so a 422 still answers with the new
  // `version` (kept on the error) and its `issues`, which open the panel.
  const finalize = useCallback(async () => {
    if (!urls.finalize) return { ok: false }
    clearTimeout(timer.current)
    setFinalizing(true)
    try {
      while (pending.current) await pending.current
      const { doc: current, revision: currentRevision } = latest.current
      const gen = generation.current
      const request = finalizeDocument(urls.finalize, forSave(current), versionRef.current)
      pending.current = request.catch(() => {})
      try {
        const body = await request
        if (gen !== generation.current) return { ok: false }
        versionRef.current = body.version ?? versionRef.current
        savedRevision.current = currentRevision
        onAdopt(normalize(body), { replace: latest.current.revision === currentRevision })
        setStatus('finalized')
        onEvent('finalized', { document: body })
        return { ok: true }
      } catch (error) {
        if (gen !== generation.current) return { ok: false }
        if (error.version != null) {
          versionRef.current = error.version
          savedRevision.current = currentRevision
        }
        if (error.conflict) { await reloadAfterConflict(); return { ok: false } }
        if (error.issues) return { ok: false, issues: error.issues }
        notify(error.errors && error.errors.length ? error.errors.join(' ') : t('change_failed'), 'error')
        return { ok: false }
      } finally {
        pending.current = null
      }
    } finally {
      setFinalizing(false)
    }
  }, [urls.finalize, onAdopt, onEvent, notify, t, reloadAfterConflict])

  const reload = useCallback(async () => {
    if (!urls.diagram) return
    try {
      resetTo(await fetchDocument(urls.diagram))
      setStatus('saved')
      notify(t('toast_reloaded'), 'info')
    } catch {
      notify(t('change_failed'), 'error')
    }
  }, [urls.diagram, resetTo, notify, t])

  return { status: dirty && status === 'saved' ? 'dirty' : status, dirty, save, finalize, finalizing, reload }
}
