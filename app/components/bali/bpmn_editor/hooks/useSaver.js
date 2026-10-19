import { useCallback, useEffect, useRef, useState } from 'react'
import { saveDocument, saveAnnotations, fetchDocument, finalizeDocument } from '../saveClient.js'
import { forSave, normalize } from '../model/document.js'
import { createSaver } from '../model/saver.js'

const AUTOSAVE_DELAY = 1200

// The save state machine lives in model/saver.js (pure, tested with node
// --test); this hook binds it to React: status, the autosave debounce, the
// page-leave guards and the save on unmount.
//
// `notesOnly` (Component `annotatable:` on a read-only diagram): the same
// serialized protocol, to `urls.annotations`, carrying only the annotations.
const annotationsOf = (doc) => doc.annotations || []

export default function useSaver ({ doc, revision, urls, editable, notesOnly = false, autosave, onAdopt, onReset, onEvent, notify, t }) {
  const saving = editable || notesOnly
  const [status, setStatus] = useState('saved')
  const [finalizing, setFinalizing] = useState(false)
  const timer = useRef(null)
  const latest = useRef({ doc, revision })
  latest.current = { doc, revision }
  const deps = {
    client: { save: notesOnly ? saveAnnotations : saveDocument, fetch: fetchDocument, finalize: finalizeDocument },
    urls: notesOnly ? { save: urls.annotations, diagram: urls.diagram } : urls,
    latest: () => latest.current,
    onAdopt,
    onReset,
    onEvent,
    notify,
    t,
    setStatus,
    prepare: normalize,
    forSave: notesOnly ? annotationsOf : forSave,
    defer: (fn) => setTimeout(fn, 0)
  }
  const saver = useRef(null)
  if (!saver.current) saver.current = createSaver(deps, { version: doc.version ?? null, revision })
  saver.current.configure(deps)
  const dirty = saver.current.isDirty(revision)

  const save = useCallback(async () => {
    if (!saving) return false
    clearTimeout(timer.current)
    return saver.current.save()
  }, [saving])

  useEffect(() => {
    if (!dirty) return
    setStatus((s) => (s === 'saving' ? s : 'dirty'))
    if (!(autosave || notesOnly) || !saving) return
    timer.current = setTimeout(() => { save() }, AUTOSAVE_DELAY)
    return () => clearTimeout(timer.current)
  }, [revision, dirty, autosave, notesOnly, saving, save])

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
  useEffect(() => () => {
    clearTimeout(timer.current)
    saver.current.leave({ autosave: autosave || notesOnly, editable: saving })
  }, [autosave, notesOnly, saving])

  const finalize = useCallback(async () => {
    clearTimeout(timer.current)
    setFinalizing(true)
    try {
      return await saver.current.finalize()
    } finally {
      setFinalizing(false)
    }
  }, [])

  const reload = useCallback(() => saver.current.reload(), [])

  return { status: dirty && status === 'saved' ? 'dirty' : status, dirty, save, finalize, finalizing, reload }
}
