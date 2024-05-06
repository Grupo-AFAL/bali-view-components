/**
 * Focuses the first <input autofocus="autofocus"> if exists
 *
 * @param {HTMLElement} element containing an input with the autofocus attribute
 */
export const autoFocusInput = element => {
  const autofocusNode = element.querySelector('[autofocus]')
  if (autofocusNode) autofocusNode.focus()
}

// Build a URLSearchParam object from the Form inputs
export const queryParams = formElement => {
  const formData = new FormData(formElement)
  const formEntries = [...formData].reduce((entries, [name, value]) => {
    return entries.concat(typeof value === 'string' ? [[name, value]] : [])
  }, [])

  const params = new URLSearchParams()

  for (const [name, value] of formEntries) {
    if (value.length > 0) {
      params.append(name, value)
    }
  }

  return params
}
