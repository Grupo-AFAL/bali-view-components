import { Controller } from '@hotwired/stimulus'
import { formatDistanceToNow } from 'date-fns'
import es from 'date-fns/locale/es'
import en from 'date-fns/locale/en-US'

export class TimeagoController extends Controller {
  static values = {
    datetime: String,
    refreshInterval: { default: 1000, type: Number },
    includeSeconds: { default: true, type: Boolean },
    addSuffix: { default: false, type: Boolean },
    locale: { default: 'en', type: String }
  }

  initialize () {
    this.isValid = true
    this.locale = this.localeValue === 'es' ? es : en
  }

  connect () {
    this.load()

    if (this.hasRefreshIntervalValue && this.isValid) {
      this.startRefreshing()
    }
  }

  disconnect () {
    this.stopRefreshing()
  }

  load () {
    const datetime = this.datetimeValue
    const date = Date.parse(datetime)
    const options = {
      includeSeconds: this.hasIncludeSecondsValue,
      addSuffix: this.hasAddSuffixValue,
      locale: this.locale
    }

    if (Number.isNaN(date)) {
      this.isValid = false

      console.error(
        `[stimulus-timeago] Value given in 'data-timeago-datetime' is not a valid date (${datetime}). Please provide a ISO 8601 compatible datetime string. Displaying given value instead.`
      )
    }

    // @ts-ignore
    this.element.dateTime = datetime
    this.element.innerHTML = this.isValid ? formatDistanceToNow(date, options) : datetime
  }

  startRefreshing () {
    this.refreshTimer = setInterval(() => {
      this.load()
    }, this.refreshIntervalValue)
  }

  stopRefreshing () {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }
}
