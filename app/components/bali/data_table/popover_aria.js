/**
 * Sincroniza `aria-expanded` de un popover que abre por `:focus-within` de daisyUI.
 *
 * Los controles de la toolbar que NO son un Bali::Dropdown (columnas, vistas guardadas) son un
 * `.dropdown` de daisyUI con un `<button>` a mano: no hay ningún JS que abra el panel, lo
 * despliega el CSS al enfocarse el botón. Sin esto el botón no anunciaba nada — ni que abre un
 * popover, ni si está abierto—, así que el lector de pantalla lo leía como un botón común y el
 * panel aparecía sin avisar (WCAG 4.1.2).
 *
 * El foco es la señal REAL de apertura, así que es lo que se escucha.
 *
 * @param {HTMLElement} element el `.dropdown`
 * @param {HTMLElement} trigger el botón que lo abre
 * @returns {Function} para desconectar los listeners
 */
export function syncPopoverAria (element, trigger) {
  if (!element || !trigger) return () => {}

  const setExpanded = (expanded) => trigger.setAttribute('aria-expanded', String(expanded))
  const onFocusIn = () => setExpanded(true)
  // El foco puede saltar ENTRE hijos del popover (del botón a un checkbox): eso no es cerrar.
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
