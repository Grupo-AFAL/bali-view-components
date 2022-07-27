import { Controller } from '@hotwired/stimulus'
import { formatDistanceToNow } from 'date-fns'
import es from 'date-fns/locale/es'
import en from 'date-fns/locale/en-US'

export class TimeagoController extends Controller {
  static values = {
    datetime: String,
    refreshInterval: Number,
    includeSeconds: { default: true, type: Boolean },
    addSuffix: { default: false, type: Boolean },
    locale: { default: 'en', type: String }
  }

  initialize () {
    this.isValid = true
    this.locale = this.localeValue === 'es' ? es : en
    this.options = {
      includeSeconds: this.includeSecondsValue,
      addSuffix: this.addSuffixValue,
      locale: this.locale
    }
  }

  connect () {
    this.load()
    this.update()

    if (this.hasRefreshIntervalValue && this.isValid) {
      this.startRefreshing()
    }
  }

  disconnect () {
    this.stopRefreshing()
  }

  load () {
    this.date = Date.parse(this.datetimeValue)

    if (Number.isNaN(this.date)) {
      this.isValid = false

      console.error(
        `[timeago] Value given in 'data-timeago-datetime' is not a valid date (${this.datetimeValue}). Please provide a ISO 8601 compatible datetime string. Displaying given value instead.`
      )
    }
  }

  update () {
    this.element.innerHTML = this.isValid
      ? formatDistanceToNow(this.date, this.options)
      : this.datetimeValue
  }

  startRefreshing () {
    this.refreshTimer = setInterval(() => {
      this.update()
    }, this.refreshIntervalValue)
  }

  stopRefreshing () {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }
}
