import { useCallback, useEffect, useRef, useState } from 'react'

// The attributes Bali::BpmnEditor::Component writes on the header of
// `full_page:` (component.html.erb): «Exit», and the slots the save status and
// the document's status are drawn into. Mirror PAGE_EXIT_ATTRIBUTE,
// PAGE_SAVE_STATUS_ATTRIBUTE and PAGE_STATUS_ATTRIBUTE (contract_test.rb).
export const PAGE_EXIT_SELECTOR = '[data-bpmn-page-exit]'
export const PAGE_SAVE_STATUS_SELECTOR = '[data-bpmn-page-save-status]'
export const PAGE_STATUS_SELECTOR = '[data-bpmn-page-status]'

const plainClick = (event) => event.button === 0 && !event.metaKey && !event.ctrlKey && !event.shiftKey && !event.altKey

// «Exit» is the host's link to `close_url`, so it navigates without the
// island too. With something unsaved or a request out, the click waits for
// the save (useSaver flush) and then follows the link; a save that fails
// leaves `failed` set, for the dialog that offers «Retry» or «Exit without
// saving». A 409 met on the way replaced the document: the editor stays,
// and its notice says why.
export default function usePageExit (hostElement, { enabled, saver }) {
  const saverRef = useRef(saver)
  saverRef.current = saver
  const [failed, setFailed] = useState(null) // the «Exit» link whose save failed
  const [exiting, setExiting] = useState(false)
  const busy = useRef(false)
  const leavingTo = useRef(null)

  const go = useCallback((link, mode) => {
    saverRef.current.markLeaving(mode)
    const url = link.href
    leavingTo.current = url
    if (window.Turbo && typeof window.Turbo.visit === 'function' && !link.closest('[data-turbo="false"]')) window.Turbo.visit(url)
    else window.location.assign(url)
  }, [])

  const exit = useCallback(async (link) => {
    if (busy.current) return
    busy.current = true
    setExiting(true)
    link.setAttribute('aria-busy', 'true')
    try {
      const result = await saverRef.current.flush()
      if (result.ok) { setFailed(null); go(link, 'saved') } else setFailed(result.reset ? null : link)
    } finally {
      busy.current = false
      setExiting(false)
      link.removeAttribute('aria-busy')
    }
  }, [go])

  useEffect(() => {
    if (!enabled || !hostElement) return
    const onClick = (event) => {
      const link = event.target.closest && event.target.closest(PAGE_EXIT_SELECTOR)
      if (!link || !hostElement.contains(link) || !plainClick(event)) return
      if (saverRef.current.isSettled() && !busy.current) { saverRef.current.markLeaving('saved'); return }
      event.preventDefault()
      exit(link)
    }
    hostElement.addEventListener('click', onClick)
    return () => hostElement.removeEventListener('click', onClick)
  }, [enabled, hostElement, exit])

  // «Exit»'s visit cancelled by a host's `turbo:before-visit` leaves the person
  // here: the leave guards and the unmount's send are theirs again. On window,
  // after the document's listeners have had their say. A failed request is
  // not a stay: Turbo loads `close_url` in full instead, and the page's other
  // requests (a lazy frame, a prefetch) fail on the same event.
  useEffect(() => {
    if (!enabled) return
    const stayed = (event) => {
      if (!event.defaultPrevented || event.detail.url !== leavingTo.current) return
      leavingTo.current = null
      saverRef.current.markLeaving(null)
    }
    window.addEventListener('turbo:before-visit', stayed)
    return () => window.removeEventListener('turbo:before-visit', stayed)
  }, [enabled])

  return {
    failed: Boolean(failed),
    exiting,
    retry: () => failed && exit(failed),
    discard: () => failed && go(failed, 'discard'),
    stay: () => setFailed(null)
  }
}
