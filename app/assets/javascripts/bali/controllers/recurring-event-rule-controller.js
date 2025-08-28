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

    this._setSelectedIndexToEndMethodSelect(options)
    this._syncRruleOptionsWithInputs(options)
    this._syncFreqCustomizationInputsRadios()

    this.toggleFreqCustomizationInputsContainer({ target: { value: options.freq } })
    this.toggleIntervalInputContainer({ target: { value: options.freq } })
    this.toggleEndCustomizationInputsContainer(
      { target: { value: this.endMethodSelectTarget.value }}
    )
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

  _setSelectedIndexToEndMethodSelect = (options) => {
    let selectedValue = ''
    const keys = ['count', 'until']
    keys.forEach(key => { if (options[key]) selectedValue = key })

    this._setSelectedIndexToSelect(this.endMethodSelectTarget, selectedValue)
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
    
    const selectedValue = value.map(opt => opt.weekday).join(',')
    this.element.querySelectorAll(`select[data-rrule-attr="byweekday"]`)
                .forEach(element => { this._setSelectedIndexToSelect(element, selectedValue) })
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

  _setSelectedIndexToSelect = (element, selectedValue) => {
    element.selectedIndex = Math.max(
      [...element.options].findIndex(opt => opt.value == selectedValue), 0
    )
  }

  _syncFreqCustomizationInputsRadios = () => {
    for (const element of this.freqCustomizationInputsContainerTargets) {
      const radios = element.querySelectorAll('input[type="radio"]')
      if (radios.length === 0) continue

      radios.forEach(radio => { radio.checked = false })
      const index = this.inputTarget.value.includes('BYSETPOS') ? radios.length - 1 : 0
      radios[index].checked = true
    }
  }
}
