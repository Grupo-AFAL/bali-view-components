/**
 * Syncs the `aria-expanded` of a popover that opens through daisyUI's `:focus-within`.
 *
 * The toolbar controls that are NOT a Bali::Dropdown (columns, saved views) are a daisyUI
 * `.dropdown` with a hand-written `<button>`: no JS opens the panel, the CSS unfolds it when
 * the button takes focus. Without this the button announced nothing — neither that it opens a
 * popover, nor whether it is open —, so the screen reader read it as an ordinary button and
 * the panel appeared unannounced (WCAG 4.1.2).
 *
 * Focus is the REAL open signal, so that is what is listened to.
 *
 * @param {HTMLElement} element the `.dropdown`
 * @param {HTMLElement} trigger the button that opens it
 * @returns {Function} to disconnect the listeners
 */
export function syncPopoverAria (element, trigger) {
  if (!element || !trigger) return () => {}

  const setExpanded = (expanded) => trigger.setAttribute('aria-expanded', String(expanded))
  const onFocusIn = () => setExpanded(true)
  // Focus can jump BETWEEN children of the popover (button to checkbox): that is not closing.
  const onFocusOut = (event) => {
    if (event.relatedTarget && element.contains(event.relatedTarget)) return

    setExpanded(false)
  }

  element.addEventListener('focusin', onFocusIn)
  element.addEventListener('focusout', onFocusOut)

  return () => {
    element.removeEventListener('focusin', onFocusIn)
    element.removeEventListener('focusout', onFocusOut)
  }
}
