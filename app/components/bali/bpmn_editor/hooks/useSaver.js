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
// saved state.
//
// The version is tracked apart from the document, so undoing to an older
// document never sends an older version (which would be a false 409).
export default function useSaver ({ doc, revision, urls, editable, autosave, onAdopt, onReset, onEvent, notify, t }) {
  const [status, setStatus] = useState('saved')
  const [finalizing, setFinalizing] = useState(false)
  const versionRef = useRef(doc.version ?? null)
  const savedRevision = useRef(revision)
  const inFlight = useRef(false)
  const queued = useRef(false)
  const latest = useRef({ doc, revision })
  latest.current = { doc, revision }
  const dirty = revision !== savedRevision.current

  const save = useCallback(async () => {
    if (!editable || !urls.save) return false
    if (inFlight.current) { queued.current = true; return false }
    const { doc: sent, revision: sentRevision } = latest.current
    if (sentRevision === savedRevision.current) return true
    inFlight.current = true
    setStatus('saving')
    try {
      const body = await saveDocument(urls.save, forSave(sent), versionRef.current)
      versionRef.current = body.version ?? versionRef.current
      savedRevision.current = sentRevision
      const unchanged = latest.current.revision === sentRevision
      onAdopt(normalize(body), { replace: unchanged })
      setStatus(unchanged ? 'saved' : 'dirty')
      onEvent('saved', { document: body })
      return true
    } catch (error) {
      if (error.conflict && urls.diagram) {
        try {
          const fresh = await fetchDocument(urls.diagram)
          versionRef.current = fresh.version ?? null
          onReset(normalize(fresh))
          savedRevision.current = latest.current.revision + 1
          notify(t('toast_conflict'), 'warning')
          setStatus('saved')
          return false
        } catch {
          // fall through to the error state
        }
      }
      setStatus('error')
      notify(error.errors && error.errors.length ? error.errors.join(' ') : t('change_failed'), 'error')
      return false
    } finally {
      inFlight.current = false
      if (queued.current) {
        queued.current = false
        setTimeout(() => { save() }, 0)
      }
    }
  }, [editable, urls.save, urls.diagram, onAdopt, onReset, onEvent, notify, t])

  useEffect(() => {
    if (!dirty) return
    setStatus((s) => (s === 'saving' ? s : 'dirty'))
    if (!autosave || !editable) return
    const timer = setTimeout(() => { save() }, AUTOSAVE_DELAY)
    return () => clearTimeout(timer)
  }, [revision, dirty, autosave, editable, save])

  // Only a change of `dirty` is news; a new onEvent identity is not.
  const onEventRef = useRef(onEvent)
  onEventRef.current = onEvent
  useEffect(() => { onEventRef.current('dirty-change', { dirty }) }, [dirty])

  useEffect(() => {
    if (!dirty) return
    const warn = (event) => { event.preventDefault(); event.returnValue = '' }
    window.addEventListener('beforeunload', warn)
    return () => window.removeEventListener('beforeunload', warn)
  }, [dirty])

  // "Finalize": save whatever is pending, then post the document. A 422
  // carries the server's `issues`, which the caller shows in the panel.
  const finalize = useCallback(async () => {
    if (!urls.finalize) return { ok: false }
    setFinalizing(true)
    try {
      const { doc: current, revision: currentRevision } = latest.current
      const body = await finalizeDocument(urls.finalize, forSave(current), versionRef.current)
      versionRef.current = body.version ?? versionRef.current
      savedRevision.current = currentRevision
      onAdopt(normalize(body), { replace: latest.current.revision === currentRevision })
      setStatus('finalized')
      onEvent('finalized', { document: body })
      return { ok: true }
    } catch (error) {
      if (error.issues) return { ok: false, issues: error.issues }
      notify(error.errors && error.errors.length ? error.errors.join(' ') : t('change_failed'), 'error')
      return { ok: false }
    } finally {
      setFinalizing(false)
    }
  }, [urls.finalize, onAdopt, onEvent, notify, t])

  const reload = useCallback(async () => {
    if (!urls.diagram) return
    try {
      const fresh = await fetchDocument(urls.diagram)
      versionRef.current = fresh.version ?? null
      onReset(normalize(fresh))
      savedRevision.current = latest.current.revision + 1
      setStatus('saved')
      notify(t('toast_reloaded'), 'info')
    } catch {
      notify(t('change_failed'), 'error')
    }
  }, [urls.diagram, onReset, notify, t])

  return { status: dirty && status === 'saved' ? 'dirty' : status, dirty, save, finalize, finalizing, reload }
}
