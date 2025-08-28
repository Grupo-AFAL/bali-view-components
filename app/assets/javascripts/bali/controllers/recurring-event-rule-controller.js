import { Controller } from '@hotwired/stimulus'
import { RRule, rrulestr } from 'rrule'

export class RecurringEventRuleController extends Controller {
  static targets = [
    'input', 
    'endSelect',
    'freqCustomizationInputsContainer',
    'freqCustomizationInputs',
    'endInputsContainer',
    'intervalInputContainer'
  ]

  connect () {
    this.inputTarget.value ||= 'FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1'
    const options = rrulestr(this.inputTarget.value).origOptions

    for (const [attribute, value] of Object.entries(options)) {
      if (attribute !== 'byweekday') {
        this.element.querySelectorAll(`[data-rrule-attr="${attribute}"]`)
            .forEach(element => { element.value = value })
      } else if (options.freq !== RRule.WEEKLY) {
        const joinedValue = value.map(opt => opt.weekday).join(',')
        this.element.querySelectorAll(`select[data-rrule-attr="${attribute}"]`)
            .forEach(element => {
              element.options.selectedIndex = Math.max(
                [...element.options].findIndex(opt => opt.value === joinedValue ), 0
              )
            })
      } else {
        value.map(opt => {
          const checkbox = this.element.querySelector(
            `input[type="checkbox"][data-rrule-attr="${attribute}"][value="${opt.weekday}"]`
          )
          if (checkbox) checkbox.checked = true
        })
      } 
    }
    
    this.endSelectTarget.value = options.count ? 'count' : (options.until ? 'until' : '')
    this.checkRadios(this.inputTarget.value)
    this.toggleFreqCustomizationInputsContainer({ target: { value: options.freq } })
    this.toggleIntervalInputContainer({ target: { value: options.freq } })
    this.toggleEndInputsContainer({ target: { value: this.endSelectTarget.value }})
  }

  checkRadios = (rule) => {
    this.freqCustomizationInputsContainerTargets.forEach(element => {
      const radios = element.querySelectorAll('input[type="radio"]')

      if (radios.length === 1) {
        radios[0].checked = true
      } else if (radios.length > 0 && rule.includes('BYSETPOS')) {
        radios[0].checked = false
        radios[radios.length - 1].checked = true
      } else if (radios.length > 0 ) {
        radios[0].checked = true
        radios[radios.length - 1].checked = false
      }
    });
  }

  toggleFreqCustomizationInputsContainer = (event) => {
    this.freqCustomizationInputsContainerTargets.forEach(element => {
      if (element.dataset.rruleFreq.split(',').includes(event.target.value.toString())) {
        this._show(element)
        this.toggleFreqCustomizationInputs(
          { target: element.querySelector('input[type="radio"]:checked') }
        )
      } else {
        this._hide(element)
        this._deactivateInputs(element)
      }
    });
  }

  toggleFreqCustomizationInputs = (event) => {
    if (!event.target) return

    this.freqCustomizationInputsTargets.forEach(element => {
      if (event.target.id.endsWith(element.dataset.rruleFreqOption)) {
        this._activateInputs(element)
      } else {
        this._deactivateInputs(element)
      }
    })
  }

  toggleIntervalInputContainer = (event) => {
    const intervalInput = this.element.querySelector('[data-rrule-attr="interval"]')
    if (event.target.value.toString() === RRule.YEARLY.toString()) {
      this._hide(this.intervalInputContainerTarget)
      this.setInputActiveDataAttribute(intervalInput, 'false')
    } else {
      this._show(this.intervalInputContainerTarget)
      this.setInputActiveDataAttribute(intervalInput, 'true')
    }  
  }

  setInputActiveDataAttribute = (target, value) => {
    target.dataset.inputActive = value
  }

  toggleEndInputsContainer = (event) => {
    this.endInputsContainerTargets.forEach(element => {
      if (event.target.value === element.dataset.endValue) {
        this._show(element)
        this._activateInputs(element)
      } else {
        this._hide(element)
        this._deactivateInputs(element)
      }
    });
  }

  _hide = (element) => {
    element.classList.add('is-hidden')
  }

  _show = (element) => {
    element.classList.remove('is-hidden')
  }

  _activateInputs = (element) =>{
    element.querySelectorAll('[data-rrule-attr]')
           .forEach(input => { this.setInputActiveDataAttribute(input, "true") })
  }

  _deactivateInputs = (element) =>{
    element.querySelectorAll('[data-rrule-attr]')
           .forEach(input => { this.setInputActiveDataAttribute(input, "false") })
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

    this.inputTarget.value = new RRule(options).toString().replace('RRULE:', '')
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
