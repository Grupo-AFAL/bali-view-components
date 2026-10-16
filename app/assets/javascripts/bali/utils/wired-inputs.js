/**
 * The `<input type="…">`s whose `data-action` calls the controller's `change`, within
 * the controller's scope as Stimulus draws it for targets: a nested controller with
 * the same identifier keeps its own inputs.
 *
 * @param {Controller} controller - the Stimulus controller the inputs are wired to
 * @param {string} type - the input type, `radio` or `checkbox`
 */
export const wiredInputs = ({ element, identifier }, type) => {
  const descriptor = new RegExp(`(^|->)${identifier}#change(:|$)`)

  return [...element.querySelectorAll(`input[type="${type}"][data-action]`)].filter(input =>
    input.closest(`[data-controller~="${identifier}"]`) === element &&
    input.dataset.action.split(/\s+/).some(token => descriptor.test(token))
  )
}
