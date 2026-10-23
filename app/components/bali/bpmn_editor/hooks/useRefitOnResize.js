import { useEffect, useRef } from 'react'

// Calls `refit` once the element's size settles after a change — a split
// pane dragged, a container that opened, a panel laid out after its first
// paint. The first observation (the size it mounted at) is skipped: the
// initial fit is React Flow's own.
// `delay: 0` calls it on every observed size instead, in the same frame: a
// container that animates its size is followed frame by frame.
export default function useRefitOnResize (ref, refit, enabled = true, delay = 120) {
  const latest = useRef(refit)
  latest.current = refit
  useEffect(() => {
    const element = ref.current
    if (!enabled || !element || !window.ResizeObserver) return undefined
    let size = null
    let timer = null
    let observer = null
    // Created in an animation frame, never inside another observer's delivery:
    // an effect can be flushed there (React runs pending effects before an
    // update another editor makes from its observer), and an observer created
    // mid-delivery is left undelivered — Chrome's «ResizeObserver loop».
    const frame = window.requestAnimationFrame(() => {
      observer = new window.ResizeObserver(([entry]) => {
        const { width, height } = entry.contentRect
        const next = `${Math.round(width)}x${Math.round(height)}`
        if (size === null || next === size || !width || !height) { size = size || next; return }
        size = next
        if (!delay) { latest.current(); return }
        clearTimeout(timer)
        timer = setTimeout(() => latest.current(), delay)
      })
      observer.observe(element)
    })
    return () => { window.cancelAnimationFrame(frame); clearTimeout(timer); if (observer) observer.disconnect() }
  }, [ref, enabled, delay])
}
