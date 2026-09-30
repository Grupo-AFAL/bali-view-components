import { Controller } from '@hotwired/stimulus'

/**
 * Shows different elements based on the value of a radio button
 *
 * <div data-controller="radio-toggle" data-radio-toggle-current-value="one">
 *   <input type="radio" data-action="radio-toggle#change" value="one">
 *   <input type="radio" data-action="radio-toggle#change" value="two">
 *
 *   <div data-radio-toggle-target="element" data-radio-toggle-value="one">
 *     <h1 class="title is-1">One</h1>
 *   </div>
 *
 *   <div data-radio-toggle-target="element" data-radio-toggle-value="two">
 *     <h1 class="title is-1">Two</h1>
 *   </div>
 * </div>
 *
 *
 * Shows the same result with multiple radio buttons value
 *
 * <div data-controller="radio-toggle" data-radio-toggle-current-value="one">
 *   <input type="radio" data-action="radio-toggle#change" value="one">
 *   <input type="radio" data-action="radio-toggle#change" value="two">
 *
 *   <div data-radio-toggle-target="element" data-radio-toggle-value="one">
 *     <h1 class="title is-1">One</h1>
 *   </div>
 *
 *   <div data-radio-toggle-target="element" data-radio-toggle-value="one,two">
 *     <h1 class="title is-1">Two</h1>
 *   </div>
 * </div>
 *
 *
 * Requires a checkbox as well: `+` joins conditions, and a checkbox wired to
 * `radio-toggle#change` counts with its `value` while checked
 *
 * <input type="checkbox" data-action="radio-toggle#change" value="serial_unknown">
 * <div data-radio-toggle-target="element" data-radio-toggle-value="damaged+serial_unknown">
 *
 *
 * `data-radio-toggle-disable-hidden-value="true"` disables the fields of a hidden
 * target, so the form does not send them, and enables them again when it shows.
 */

export class RadioToggleController extends Controller {
  static targets = ['element']
  static values = { current: String, disableHidden: Boolean }

  connect () {
    this.toggleTargets()
  }

  change (event) {
    if (event.target.type === 'radio') this.currentValue = event.target.value

    this.toggleTargets()
  }

  // A target that arrives after connect — a Turbo Stream replacing it — carries
  // the state the server painted, which can lag behind the radio on screen.
  elementTargetConnected (element) {
    this.toggle(element)
  }

  toggleTargets (value = this.currentValue) {
    this.elementTargets.forEach(element => this.toggle(element, value))
  }

  toggle (element, value = this.currentValue) {
    const visible = this.matches(element, value)

    element.classList.toggle('hidden', !visible)
    if (this.disableHiddenValue) this.disableFields(element, !visible)
  }

  matches (element, value) {
    const checked = this.checkedBoxValues

    return element.dataset.radioToggleValue.split(',').some(condition =>
      condition.split('+').every(token => token === value || checked.has(token))
    )
  }

  // Disabled rather than emptied, so a file already chosen survives a trip to
  // another option and back. Only what this controller disabled is re-enabled:
  // a field the server rendered `disabled` stays that way.
  disableFields (element, disabled) {
    const fields = [element, ...element.querySelectorAll('input, select, textarea')]
      .filter(field => field.matches('input, select, textarea'))

    fields.forEach(field => {
      if (disabled && !field.disabled) {
        field.disabled = true
        field.dataset.radioToggleDisabled = ''
      } else if (!disabled && 'radioToggleDisabled' in field.dataset) {
        field.disabled = false
        delete field.dataset.radioToggleDisabled
      }
    })
  }

  get checkedBoxValues () {
    const boxes = this.element.querySelectorAll('input[type="checkbox"][data-action*="radio-toggle#change"]')

    return new Set(
      [...boxes]
        .filter(box => box.checked && box.closest('[data-controller~="radio-toggle"]') === this.element)
        .map(box => box.value)
    )
  }
}
