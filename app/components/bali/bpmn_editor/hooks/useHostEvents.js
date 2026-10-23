import { useEffect, useRef } from 'react'
import { hostEventHandlers, replayThenReady } from '../model/hostEvents.js'

// Listens for what the host sends back (model/hostEvents.js), and announces
// `ready` once (`onReady`) after applying what it sent before.
// Only events dispatched on this editor's own element: one that bubbles up
// from another editor on the page, or one sent to document, names no editor
// and is not ours (two editors can hold the same ids).
export default function useHostEvents (hostElement, { reload, apply, docRef, onSelect, onBadges, onCompare, takeQueued, onReady }) {
  const announced = useRef(false)
  useEffect(() => {
    const ready = () => {
      if (announced.current) return
      announced.current = true
      onReady()
    }
    if (!hostElement) { replayThenReady([], null, ready); return undefined }
    const handlers = hostEventHandlers({ reload, apply, docRef, onSelect, onBadges, onCompare })
    const listener = (event) => { if (event.target === hostElement) handlers[event.type](event) }
    for (const name of Object.keys(handlers)) hostElement.addEventListener(name, listener)
    replayThenReady(takeQueued ? takeQueued() : [], (event) => handlers[event.type](event), ready)
    return () => { for (const name of Object.keys(handlers)) hostElement.removeEventListener(name, listener) }
  }, [hostElement, reload, apply, docRef, onSelect, onBadges, onCompare, takeQueued, onReady])
}
