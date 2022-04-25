/**
 * Focuses the first <input autofocus="autofocus"> if exists
 *
 * @param {HTMLElement} element containing an input with the autofocus attribute
 */
export const autoFocusInput = element => {
  const autofocusNode = element.querySelector('[autofocus]')
  if (autofocusNode) autofocusNode.focus()
}
