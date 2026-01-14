import { Controller } from '@hotwired/stimulus'
import { RRule, rrulestr } from 'rrule'

export class RecurrentEventRuleController extends Controller {
  static targets = [
    'input',
    'endMethodSelect',
    'endCustomizationInputsContainer',
    'intervalInputContainer',
    'freqCustomizationInputsContainer',
    'freqCustomizationInputs',
    'freqHelperText'
  ]

  connect () {
    this.inputTarget.value ||= 'FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1'
    const options = rrulestr(this.inputTarget.value).origOptions

    this._setSelectedIndexToEndMethodSelect(options)
    this._syncRruleOptionsWithInputs(options)
    this._syncFreqCustomizationInputsRadios()

    this.toggleFreqCustomizationInputsContainer({
      target: { value: options.freq }
    })
    this.toggleFreqHelperText({ target: { value: options.freq } })
    this.toggleIntervalInputContainer({ target: { value: options.freq } })
    this.toggleEndCustomizationInputsContainer({
      target: { value: this.endMethodSelectTarget.value }
    })
  }

  toggleFreqCustomizationInputsContainer = (event) => {
    this.freqCustomizationInputsContainerTargets.forEach((element) => {
      if (
        element.dataset.rruleFreq
          .split(',')
          .includes(event.target.value.toString())
      ) {
        this._show(element)
        this.toggleFreqCustomizationInputs({
          target: element.querySelector('input[type="radio"]:checked')
        })
      } else {
        this._hide(element)
        this._deactivateInputs(element)
      }
    })
  }

  toggleFreqHelperText = (event) => {
    this.freqHelperTextTargets.forEach((element) => {
      if (
        element.dataset.rruleFreq
          .split(',')
          .includes(event.target.value.toString())
      ) {
        this._show(element)
      } else {
        this._hide(element)
      }
    })
  }

  toggleFreqCustomizationInputs = (event) => {
    if (!event.target) return

    this.freqCustomizationInputsTargets.forEach((element) => {
      if (event.target.id.endsWith(element.dataset.rruleFreqOption)) {
        this._activateInputs(element)
      } else {
        this._deactivateInputs(element)
      }
    })
  }

  toggleIntervalInputContainer = (event) => {
    const intervalInput = this.element.querySelector(
      '[data-rrule-attr="interval"]'
    )
    if (event.target.value.toString() === RRule.YEARLY.toString()) {
      this._hide(this.intervalInputContainerTarget)
      this._setInputActiveDataAttribute(intervalInput, 'false')
    } else {
      this._show(this.intervalInputContainerTarget)
      this._setInputActiveDataAttribute(intervalInput, 'true')
    }
  }

  toggleEndCustomizationInputsContainer = (event) => {
    this.endCustomizationInputsContainerTargets.forEach((element) => {
      if (event.target.value === element.dataset.endValue) {
        this._show(element)
        this._activateInputs(element)
      } else {
        this._hide(element)
        this._deactivateInputs(element)
      }
    })
  }

  setRule = () => {
    const options = {}
    this.element
      .querySelectorAll('[data-input-active="true"]')
      .forEach((input) => {
        if (input.dataset.rruleAttr === 'until') {
          const [year, month, day] = input.value.split('-')
          options[input.dataset.rruleAttr] = new Date(year, month, day)
        } else if (input.dataset.rruleAttr !== 'byweekday') {
          options[input.dataset.rruleAttr] = parseInt(input.value)
        } else if (input.type !== 'checkbox' || input.checked) {
          options.byweekday ??= []
          options.byweekday = options.byweekday.concat(input.value.split(','))
        }
      })

    this.inputTarget.value = new RRule(options)
      .toString()
      .replace('RRULE:', '')
  }

  _setInputActiveDataAttribute = (target, value) => {
    target.dataset.inputActive = value
  }

  _hide = (element) => {
    element.classList.add('hidden')
  }

  _show = (element) => {
    element.classList.remove('hidden')
  }

  _activateInputs = (element) => {
    element.querySelectorAll('[data-rrule-attr]').forEach((input) => {
      this._setInputActiveDataAttribute(input, 'true')
    })
  }

  _deactivateInputs = (element) => {
    element.querySelectorAll('[data-rrule-attr]').forEach((input) => {
      this._setInputActiveDataAttribute(input, 'false')
    })
  }

  _setSelectedIndexToEndMethodSelect = (options) => {
    let selectedValue = ''
    const keys = ['count', 'until']
    keys.forEach((key) => {
      if (options[key]) selectedValue = key
    })

    this._setSelectedIndexToSelect(this.endMethodSelectTarget, selectedValue)
  }

  _syncRruleOptionsWithInputs = (options) => {
    this._syncRruleByweekdayOptionWithInputs(options.freq, options.byweekday)
    this._syncRruleUntilOptionWithInputs(options.until)

    for (const [attribute, value] of Object.entries(options)) {
      if (attribute === 'byweekday' || attribute === 'until') continue

      this.element
        .querySelectorAll(`[data-rrule-attr="${attribute}"]`)
        .forEach((element) => {
          element.value = value
        })
    }
  }

  _syncRruleByweekdayOptionWithInputs = (freq, value) => {
    if (!value) return
    if (freq === RRule.WEEKLY) this._checkByWeekDayInputs(value)

    const selectedValue = value.map((opt) => opt.weekday).join(',')
    this.element
      .querySelectorAll('select[data-rrule-attr="byweekday"]')
      .forEach((element) => {
        this._setSelectedIndexToSelect(element, selectedValue)
      })
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
      [...element.options].findIndex((opt) => opt.value === selectedValue),
      0
    )
  }

  _syncFreqCustomizationInputsRadios = () => {
    for (const element of this.freqCustomizationInputsContainerTargets) {
      const radios = element.querySelectorAll('input[type="radio"]')
      if (radios.length === 0) continue

      radios.forEach((radio) => {
        radio.checked = false
      })
      const index = this.inputTarget.value.includes('BYSETPOS')
        ? radios.length - 1
        : 0
      radios[index].checked = true
    }
  }

  _syncRruleUntilOptionWithInputs = (date) => {
    const element = this.element.querySelector('[data-rrule-attr="until"]')
    if (!element || !date) return

    element.value = this._hyphenizeDate(date)
  }

  _hyphenizeDate = (date) => {
    console.log(date)
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = (date.getDate()).toString().padStart(2, '0')

    return `${year}-${month}-${day}`
  }
}
