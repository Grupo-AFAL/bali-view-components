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

// TODO: Add tests (Issue: #253)
export class RadioButtonsGroupController extends Controller {
  static targets = ['element', 'toggler']
  static values = {
    current: String,
    keepSelection: { type: Boolean, default: false }
  }

  connect () {
    this.activeToggler(this.currentValue)
    this.toggleTargets(this.currentValue)

    const radios = this.activeTogglerContent.querySelectorAll('input[checked]')

    for (const radio of radios) {
      const label = radio.closest('label')

      radio.checked = true
      label.classList.add('is-active')
      this.selectedText = label.innerText
    }
  }

  change (event) {
    const value = event.target.closest('button').value
    this.activeToggler(value)
    this.toggleTargets(value)

    if (this.keepSelectionValue) { this.keepSelection() }
  }

  activeToggler (value) {
    this.togglerTargets.forEach(element => {
      if (element.value === value) {
        element.classList.add('is-active')
      } else {
        element.classList.remove('is-active')
      }
    })
  }

  toggleTargets (value) {
    this.elementTargets.forEach(element => {
      const valuesProperties = element.dataset.radioButtonsGroupValue.split(',')

      if (valuesProperties.includes(value)) {
        element.classList.remove('is-hidden')
        this.activeTogglerContent = element
      } else {
        element.classList.add('is-hidden')
        this.uncheckedRadioButtons(element)
      }
    })
  }

  uncheckedRadioButtons () {
    const radios = this.element.querySelectorAll("input[type='radio']")

    for (const radio of radios) {
      radio.checked = false
      radio.parentNode.classList.remove('is-active')
    }
  }

  select (event) {
    this.selectedText = event.target.closest('label').innerText

    const labels = this.activeTogglerContent.querySelectorAll('label')

    for (const label of labels) {
      if (label.innerText === this.selectedText) {
        label.classList.add('is-active')
      } else {
        label.classList.remove('is-active')
      }
    }
  }

  keepSelection () {
    const radios = this.activeTogglerContent.querySelectorAll("input[type='radio']")

    for (const radio of radios) {
      const label = radio.closest('label')

      if (label.innerText === this.selectedText) {
        radio.checked = true
        label.classList.add('is-active')
      }
    }
  }
}
