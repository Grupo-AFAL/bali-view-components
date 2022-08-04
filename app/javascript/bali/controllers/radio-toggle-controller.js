import { Controller } from '@hotwired/stimulus'

/**
 * Shows different elements based on the value of a radio button
 *
 * <div data-controller="radio-toggle" data-toggle-radio-current-value="one">
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
 * <div data-controller="radio-toggle" data-toggle-radio-current-value="one">
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
 */

// TODO: Add tests (Issue: #143)
export class RadioToggleController extends Controller {
  static targets = ['element']
  static values = { current: String }

  connect () {
    this.toggleTargets(this.currentValue)
  }

  change (event) {
    this.toggleTargets(event.target.value)
  }

  toggleTargets (value) {
    this.elementTargets.forEach(element => {
      const valuesProperties = element.dataset.radioToggleValue.split(',')

      if (valuesProperties.includes(value)) {
        element.classList.remove('is-hidden')
      } else {
        element.classList.add('is-hidden')
      }
    })
  }
}
