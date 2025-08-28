import { Controller } from '@hotwired/stimulus'
import { RRule, rrulestr } from 'rrule'

export class RecurringEventRuleController extends Controller {
  static targets = [
    'input', 
    'endMethodSelect',
    'endCustomizationInputsContainer',
    'intervalInputContainer',
    'freqCustomizationInputsContainer',
    'freqCustomizationInputs'
  ]

  connect () {
    this.inputTarget.value ||= 'FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1'
    const options = rrulestr(this.inputTarget.value).origOptions

    this._syncRruleOptionsWithInputs(options)
    
    this.endMethodSelectTarget.value = options.count ? 'count' : (options.until ? 'until' : '')
    this.checkRadios(this.inputTarget.value)

    this.toggleFreqCustomizationInputsContainer({ target: { value: options.freq } })
    this.toggleIntervalInputContainer({ target: { value: options.freq } })
    this.toggleEndCustomizationInputsContainer(
      { target: { value: this.endMethodSelectTarget.value }}
    )
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

  toggleEndCustomizationInputsContainer = (event) => {
    this.endCustomizationInputsContainerTargets.forEach(element => {
      if (event.target.value === element.dataset.endValue) {
        this._show(element)
        this._activateInputs(element)
      } else {
        this._hide(element)
        this._deactivateInputs(element)
      }
    });
  }

  setRule = () => {
    const options = {}
    this.element.querySelectorAll('[data-input-active="true"]').forEach(input => {
      if (!input.dataset.rruleAttr.includes('byweekday')) {
        options[input.dataset.rruleAttr] = this._parseInputValue(input.dataset.rruleAttr, input.value)
      } else if (input.type !== 'checkbox' || input.checked) {
        options.byweekday ??= []
        options.byweekday = options.byweekday.concat(input.value.split(','))
      }
    })

    this.inputTarget.value = new RRule(options).toString().replace('RRULE:', '')
  }

  _parseInputValue = (attribute, value) => {    
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

  _syncRruleOptionsWithInputs = (options) => {
    this._syncRruleByweekdayOptionWithInputs(options.freq, options.byweekday)

    for (const [attribute, value] of Object.entries(options)) {
      if (attribute === 'byweekday') continue

      this.element.querySelectorAll(`[data-rrule-attr="${attribute}"]`)
          .forEach(element => { element.value = value })
    }
  }

  _syncRruleByweekdayOptionWithInputs = (freq, value) => {
    if (!value) return
    if (freq === RRule.WEEKLY) this._checkByWeekDayInputs(value)
    
    this._setSelectedIndexToByWeekDaySelect(value.map(opt => opt.weekday).join(',')) 
  }

  _checkByWeekDayInputs = (weekdays) => {
    for (const weekday of weekdays) {
      const checkbox = this.element.querySelector(
        `input[type="checkbox"][data-rrule-attr="byweekday"][value="${weekday.weekday}"]`
      )
      if (!checkbox) continue

      checkbox.checked = true
    }
  }

  _setSelectedIndexToByWeekDaySelect = (selectedValue) => {
    const inputs = this.element.querySelectorAll(`select[data-rrule-attr="byweekday"]`)
    inputs.forEach(element => {
      element.options.selectedIndex = Math.max(
        [...element.options].findIndex(opt => opt.value === selectedValue ), 0
      )
    })
  }
}
