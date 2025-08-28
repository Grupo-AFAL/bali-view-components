import { Controller } from '@hotwired/stimulus'
import { datetime, RRule, RRuleSet, rrulestr } from 'rrule'

export class RecurringEventRuleController extends Controller {
  static targets = [
    'input', 
    'endSelect',
    'freqInputsContainer',
    'endInputsContainer',
    'intervalInputContainer'
  ]

  connect () {
    this.inputTarget.value ||= 'FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1'
    const options = rrulestr(this.inputTarget.value).origOptions

    for (const [attribute, value] of Object.entries(options)) {
      this.element.querySelectorAll(`[data-rrule-attr="${attribute}"]`)
          .forEach(element => { element.value = value })
    }
    
    this.endSelectTarget.value = options.count ? 'count' : (options.until ? 'until' : '')
    this.toggleFreqInputsContainer({ target: { value: options.freq } })
    this.toggleIntervalInput({ target: { value: options.freq } })
    this.toggleEndInputsContainer({ target: { value: this.endSelectTarget.value }})
  }

  toggleFreqInputsContainer = (event) => {
    this.freqInputsContainerTargets.forEach(element => {
      const inputs = element.querySelectorAll('[data-rrule-attr]')

      if (element.dataset.freqValue.split(',').includes(event.target.value.toString())) {
        element.classList.remove('is-hidden')
        const radio = element.querySelector('input[type="radio"]')
        if (radio) this.toggleInputActiveAttribute({ target: radio })
      } else {
        element.classList.add('is-hidden')
        inputs.forEach(input => { this.setInputActiveDataAttribute(input, "false") })
      }
    });
  }

  toggleInputActiveAttribute = (event) => {
    const container = event.target.closest('[data-recurring-event-rule-target="freqInputsContainer"]')
    container.querySelectorAll('input[type="radio"]')
             .forEach(input  => { this._toggleInputActiveAttribute(input) })
  }

  _toggleInputActiveAttribute = (radio) => {
    const inputs = radio.closest('.inputs-container').querySelectorAll('[data-rrule-attr]')
    if (radio.checked) {
      inputs.forEach(input => { this.setInputActiveDataAttribute(input, 'true') })
    } else {
      inputs.forEach(input => { this.setInputActiveDataAttribute(input, 'false') })
    }
  }

  toggleIntervalInput = (event) => {
    const intervalInput = this.element.querySelector('[data-rrule-attr="interval"]')
    if (event.target.value.toString() === RRule.YEARLY.toString()) {
      this.intervalInputContainerTarget.classList.add('is-hidden')
      this.setInputActiveDataAttribute(intervalInput, 'false')
    } else {
      this.intervalInputContainerTarget.classList.remove('is-hidden')
      this.setInputActiveDataAttribute(intervalInput, 'true')
    }  
  }

  setInputActiveDataAttribute = (target, value) => {
    target.dataset.inputActive = value
  }

  toggleEndInputsContainer = (event) => {
    this.endInputsContainerTargets.forEach(element => {
      const inputs = element.querySelectorAll('[data-rrule-attr]')

      if (event.target.value === element.dataset.endValue) {
        element.classList.remove('is-hidden')
        inputs.forEach(input => { this.setInputActiveDataAttribute(input, "true") })
      } else {
        element.classList.add('is-hidden')
        inputs.forEach(input => { this.setInputActiveDataAttribute(input, "false") })
      }
    });
  }

  setRule = () => {
    const options = {}
    this.element.querySelectorAll('[data-input-active="true"]').forEach(input => {
      if (!input.dataset.rruleAttr.includes('byweekday')) {
        options[input.dataset.rruleAttr] = this.parseInputValue(input.dataset.rruleAttr, input.value)
      } else if (input.type !== 'checkbox' || input.checked) {
        options.byweekday ??= []
        options.byweekday = options.byweekday.concat(input.value.split(','))
      }
    })

    this.inputTarget.value = new RRule(options).toString()
  }

  parseInputValue = (attribute, value) => {    
    let parsedValue = value
    switch (attribute) {
      case 'byweekday':
        parsedValue = value.split(',')
        break;
      case 'bysetpos':
        parsedValue = parseInt(value)
        break;
      default:
        break;
    }

    return parsedValue
  }
}
