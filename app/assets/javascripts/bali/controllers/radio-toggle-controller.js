import { Controller } from '@hotwired/stimulus'
import { wiredInputs } from '../utils/wired-inputs.js'

/**
 * Shows different elements based on the value of a radio button
 *
 * <div data-controller="radio-toggle" data-radio-toggle-current-value="one">
 *   <input type="radio" data-action="radio-toggle#change" value="one" checked>
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
 *   <input type="radio" data-action="radio-toggle#change" value="one" checked>
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
 * Joins a checkbox with `+`: a checked checkbox target counts with its `value`
 *
 * <input type="checkbox" value="serial_unknown"
 *        data-radio-toggle-target="checkbox" data-action="radio-toggle#change">
 * <div data-radio-toggle-target="element" data-radio-toggle-value="damaged+serial_unknown">
 *
 *
 * `data-radio-toggle-disable-hidden-value="true"` disables every hidden target, so
 * the form does not send its fields. The targets have to be `<fieldset>`s.
 */

export class RadioToggleController extends Controller {
  static targets = ['element', 'checkbox']
  static values = { current: String, disableHidden: Boolean }

  // A stream with `method="morph"` keeps the target, so no `elementTargetConnected`
  // runs for it and it would keep what the server painted.
  connect () {
    this.element.addEventListener('turbo:morph-element', this.retoggle)
  }

  disconnect () {
    this.element.removeEventListener('turbo:morph-element', this.retoggle)
  }

  change (event) {
    if (event.target.type !== 'checkbox') this.currentValue = event.target.value

    this.toggleTargets()
  }

  // Stimulus also calls this for the targets present at connect, so it is the
  // whole initial render. A target a Turbo Stream replaces later lands here too,
  // and takes the choice on screen rather than the one the server painted.
  elementTargetConnected (element) {
    this.toggle(element)
  }

  // A checkbox a Turbo Stream replaces brings its own state, and no event says so.
  checkboxTargetConnected () {
    this.toggleTargets()
  }

  // A morph that checks another radio, or none, fires no `change`, and the radios
  // as it leaves them are what the form sends.
  retoggle = () => {
    const radios = wiredInputs(this, 'radio')
    if (radios.length) this.currentValue = radios.find(radio => radio.checked)?.value ?? ''

    this.toggleTargets()
  }

  toggleTargets () {
    const active = this.activeTokens
    this.elementTargets.forEach(element => this.toggle(element, active))
  }

  toggle (element, active = this.activeTokens) {
    const visible = element.dataset.radioToggleValue.split(',').some(condition =>
      condition.split('+').every(token => active.has(token))
    )

    element.classList.toggle('hidden', !visible)
    // A disabled fieldset sends none of its fields, keeps their own `disabled`
    // and a file already chosen, and covers fields a stream appends later.
    if (this.disableHiddenValue) element.disabled = !visible
  }

  get activeTokens () {
    const checked = this.checkboxTargets.filter(box => box.checked).map(box => box.value)

    return new Set([this.currentValue, ...checked])
  }
}
