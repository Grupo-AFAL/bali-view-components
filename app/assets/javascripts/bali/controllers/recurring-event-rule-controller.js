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
    this.ruleOptions = rrulestr(this.inputTarget.value).origOptions
  
    // {
    //   freq: RRule.WEEKLY,
    //   interval: null,
    //   wkst: null, // RRule.MO,
    //   count: null,
    //   until: null,
    //   bysetpos: null,
    //   bymonthday: null,
    //   byyearday: null,
    //   byweekno: null,
    //   byweekday: null,
    //   byhour: null,
    //   byminute: null,
    //   bysecond: null
    // }

    for (const [attribute, value] of Object.entries(this.ruleOptions)) {
      this.element.querySelectorAll(`[data-input-target="${attribute}"]`)
          .forEach(element => { element.value = value })
        }
    
    this.endSelectTarget.value = this.ruleOptions.count ? 'after' : (this.ruleOptions.until ? 'on_date' : 'never')
    this.toggleFreqInputsContainer({ target: { value: this.ruleOptions.freq } })
    this.toggleIntervalInput({ target: { value: this.ruleOptions.freq } })
    this.toggleEndInputsContainer({ target: { value: this.endSelectTarget.value }})
  }

  toggleFreqInputsContainer = (event) => {
    if (!this.hasFreqInputsContainerTarget) return

    this.freqInputsContainerTargets.forEach(element => {
      const inputs = element.querySelectorAll('[data-input-target]')

      if (element.dataset.freqValue.split(',').includes(event.target.value)) {
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
    const inputs = radio.closest('.inputs-container').querySelectorAll('[data-input-target]')
    if (radio.checked) {
      inputs.forEach(input => { this.setInputActiveDataAttribute(input, 'true') })
    } else {
      inputs.forEach(input => { this.setInputActiveDataAttribute(input, 'false') })
    }
  }


  toggleIntervalInput = (event) => {
    const intervalInput = this.element.querySelector('[data-input-target="interval"]')
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
    if (!this.hasEndInputsContainerTarget)return

    this.endInputsContainerTargets.forEach(element => {
      const inputs = element.querySelectorAll('[data-input-target]')

      if (event.target.value === element.dataset.endValue) {
        element.classList.remove('is-hidden')
        inputs.forEach(input => { this.setInputActiveDataAttribute(input, "true") })
      } else {
        element.classList.add('is-hidden')
        inputs.forEach(input => { this.setInputActiveDataAttribute(input, "false") })
      }
    });
  }

  setRule =  () => {
    console.log('setting rule')
    const options = {}

    this.element.querySelectorAll('[data-input-active="true"]').forEach(input => {
      if (!input.dataset.inputTarget.includes('byweekday')) {
        options[input.dataset.inputTarget] = this.parseInputValue(input.dataset.inputTarget, input.value)
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
