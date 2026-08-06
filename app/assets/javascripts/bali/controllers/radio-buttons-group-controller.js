import { Controller } from '@hotwired/stimulus'

/**
 * Toggler buttons that reveal one content pane each, where the panes contain
 * radio groups. A pane is shown when its data-radio-buttons-group-value list
 * (comma-separated) includes the active toggler's value; hiding a pane
 * unchecks its radios, and keep-selection re-checks the remembered one.
 *
 * <div data-controller="radio-buttons-group" data-radio-buttons-group-current-value="one">
 *   <button type="button" value="one" data-radio-buttons-group-target="toggler"
 *           data-action="radio-buttons-group#change">One</button>
 *   <button type="button" value="two" data-radio-buttons-group-target="toggler"
 *           data-action="radio-buttons-group#change">Two</button>
 *
 *   <div data-radio-buttons-group-target="element" data-radio-buttons-group-value="one">
 *     <label><input type="radio" value="a" data-action="radio-buttons-group#select"> A</label>
 *   </div>
 *
 *   <div data-radio-buttons-group-target="element" data-radio-buttons-group-value="one,two">
 *     <label><input type="radio" value="b" data-action="radio-buttons-group#select"> B</label>
 *   </div>
 * </div>
 *
 * `f.radio_buttons_group` renders this markup; the catalog entry is
 * docs/guides/controllers.md#radio-buttons-group.
 */

export class RadioButtonsGroupController extends Controller {
  static targets = ['element', 'toggler']
  static values = {
    current: String,
    keepSelection: { type: Boolean, default: false }
  }

  static classes = ['active', 'inactive']

  // Default DaisyUI classes if not specified via data attributes
  get activeClass () {
    return this.hasActiveClass ? this.activeClasses : ['btn-primary']
  }

  get inactiveClass () {
    return this.hasInactiveClass ? this.inactiveClasses : ['btn-ghost']
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
        element.classList.remove(...this.inactiveClass)
        element.classList.add(...this.activeClass)
      } else {
        element.classList.remove(...this.activeClass)
        element.classList.add(...this.inactiveClass)
      }
    })
  }

  toggleTargets (value) {
    this.elementTargets.forEach(element => {
      const valuesProperties = element.dataset.radioButtonsGroupValue.split(',')

      if (valuesProperties.includes(value)) {
        element.classList.remove('hidden')
        this.activeTogglerContent = element
      } else {
        element.classList.add('hidden')
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
