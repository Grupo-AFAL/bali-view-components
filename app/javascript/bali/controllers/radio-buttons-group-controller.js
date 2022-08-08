import { Controller } from '@hotwired/stimulus'

/**
 * Shows different elements based on the value of a radio button
 *
 * <div data-controller="radio-buttons-grouped" data-radio-buttons-grouped-current-value="one">
 *   <input type="radio" data-action="radio-buttons-grouped#change" value="one">
 *   <input type="radio" data-action="radio-buttons-grouped#change" value="two">
 *
 *   <div data-radio-buttons-grouped-target="element" data-radio-buttons-grouped-value="one">
 *     <input type="radio" value="a">
 *     <input type="radio" value="b">
 *   </div>
 *
 *   <div data-radio-buttons-grouped-target="element" data-radio-buttons-grouped-value="two">
 *     <input type="radio" value="c">
 *     <input type="radio" value="d">
 *   </div>
 * </div>
 *
 *
 * Shows the same result with multiple radio buttons value
 *
 * <div data-controller="radio-buttons-grouped" data-radio-buttons-grouped-current-value="one">
 *   <input type="radio" data-action="radio-buttons-grouped#change" value="one">
 *   <input type="radio" data-action="radio-buttons-grouped#change" value="two">
 *
 *   <div data-radio-buttons-grouped-target="element" data-radio-buttons-grouped-value="one">
 *     <input type="radio" value="a">
 *     <input type="radio" value="b">
 *   </div>
 *
 *   <div data-radio-buttons-grouped-target="element" data-radio-buttons-grouped-value="one,two">
 *     <input type="radio" value="c">
 *     <input type="radio" value="d">
 *   </div>
 * </div>
 *
 */

// TODO: Add tests (Issue: #143)
export class RadioButtonsGroupController extends Controller {
  static targets = ['element', 'toggler']
  static values = { current: String }

  connect () {
    this.activeToggler(this.currentValue)
  }

  change (event) {
    this.activeToggler(event.target.value)
  }

  activeToggler (value) {
    this.togglerTargets.forEach(element => {
      if (element.value === value) {
        element.classList.add('is-active')
      } else {
        element.classList.remove('is-active')
      }
    })

    this.toggleTargets(value)
  }

  toggleTargets (value) {
    this.elementTargets.forEach(element => {
      const valuesProperties = element.dataset.radioButtonsGroupValue.split(',')

      if (valuesProperties.includes(value)) {
        element.classList.remove('is-hidden')
      } else {
        element.classList.add('is-hidden')
        this.uncheckedRadioButtons(element)
      }
    })
  }

  uncheckedRadioButtons (element) {
    const radios = element.querySelectorAll("input[type='radio']")

    for (const radio of radios) {
      radio.checked = false
    }
  }
}
