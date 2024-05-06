import { Controller } from '@hotwired/stimulus'

// TODO: Add tests (Issue: #154)

/**
 * Datepicker Controller
 * Uses the flatpickr library to render a Date Picker
 * https://flatpickr.js.org/
 *
 * How to use:
 *
 * <input type="text" data-controller="datepicker">
 *
 * Default language: Spanish
 */
export class DatepickerController extends Controller {
  static values = {
    enableTime: { type: Boolean, default: false },
    noCalendar: { type: Boolean, default: false },
    enableSeconds: { type: Boolean, default: false },
    disableWeekends: { type: Boolean, default: false },
    locale: { type: String, default: 'es' },
    defaultDate: String,
    defaultDates: Array,
    minDate: String,
    maxDate: String,
    minTime: String,
    maxTime: String,
    altInputClass: String,
    period: String,
    mode: { type: String, default: 'single' },
    altInput: { type: Boolean, default: true },
    allowInput: { type: Boolean, default: false },
    altFormat: String
  }

  async connect () {
    const { default: flatpickr } = await import('flatpickr')

    const input =
      this.element.nodeName === 'INPUT'
        ? this.element
        : this.element.querySelector('input')

    // this is necesary because `altInputClass` option does not inherit the original classes
    this.altInputClassValue = `form-control input ${this.altInputClassValue}`

    this.flatpickr = flatpickr(input, {
      altInput: this.altInputValue,
      altFormat: this.altFormat(),
      dateFormat: this.dateFormat(),
      enableTime: this.enableTimeValue,
      noCalendar: this.noCalendarValue,
      enableSeconds: this.enableSecondsValue,
      locale: await this.setLocale(this.localeValue),
      defaultDate: this.defaultDates(),
      minDate: this.minDateValue,
      maxDate: this.maxDateValue,
      minTime: this.minTimeValue,
      maxTime: this.maxTimeValue,
      altInputClass: this.altInputClassValue,
      mode: this.modeValue,
      disable: this.disableWeekendsValue ? [this.isWeekend] : [],
      allowInput: this.allowInputValue
    })
  }

  async setLocale (countryCode) {
    if (countryCode === 'en') {
      return 'default'
    } else {
      await import('flatpickr/dist/l10n/es.js')
      return 'es'
    }
  }

  clear () {
    this.flatpickr.clear()
  }

  disconnect () {
    this.flatpickr.destroy()
  }

  defaultDates () {
    if (this.modeValue === 'range' && this.hasDefaultDatesValue) {
      return this.defaultDatesValue
    } else {
      return this.defaultDateValue
    }
  }

  altFormat () {
    if (this.hasAltFormatValue) return this.altFormatValue

    let format = ''

    if (this.noCalendarValue || this.enableTimeValue) {
      if (this.enableSecondsValue) {
        format = this.time_24hr ? 'H:i:S' : 'h:i:S K'
      } else {
        format = this.time_24hr ? 'H:i' : 'h:i K'
      }
    }

    if (!this.noCalendarValue) {
      format = `F j, Y ${format}`.trim()
    }

    return format
  }

  dateFormat () {
    let format = 'Y-m-d'

    if (this.noCalendarValue || this.enableTimeValue) {
      format = `${format} H:i:S`
    }

    return format
  }

  nextDate () {
    const currentDate = this.flatpickr.selectedDates[0]

    switch (this.periodValue) {
      case 'day':
        currentDate.setDate(currentDate.getDate() + 1)
        break
      case 'month':
        currentDate.setMonth(currentDate.getMonth() + 1)
        break
      case 'year':
        currentDate.setFullYear(currentDate.getFullYear() + 1)
        break
      default:
        return
    }

    this.flatpickr.setDate(currentDate)
  }

  previousDate () {
    const currentDate = this.flatpickr.selectedDates[0]

    switch (this.periodValue) {
      case 'day':
        currentDate.setDate(currentDate.getDate() - 1)
        break
      case 'month':
        currentDate.setMonth(currentDate.getMonth() - 1)
        break
      case 'year':
        currentDate.setFullYear(currentDate.getFullYear() - 1)
        break
      default:
        return
    }

    this.flatpickr.setDate(currentDate)
  }

  isWeekend = date => {
    return date.getDay() === 0 || date.getDay() === 6
  }
}
