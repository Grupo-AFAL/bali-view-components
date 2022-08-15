import { Controller } from '@hotwired/stimulus'

export class ClipboardController extends Controller {
  static targets = ['button', 'source', 'successContent']
  static values = {
    successDuration: {
      type: Number,
      default: 2000
    }
  }

  connect () {
    if (!this.hasButtonTarget) return

    this.originalHTML = this.buttonTarget.innerHTML
  }

  copy (event) {
    event.preventDefault()

    navigator.clipboard.writeText(this.sourceTarget.innerText).then(() => this.copied())
  }

  copied () {
    if (!this.hasButtonTarget) return

    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    this.buttonTarget.innerHTML = this.successContentTarget.innerHTML

    this.timeout = setTimeout(() => {
      this.buttonTarget.innerHTML = this.originalHTML
    }, this.successDurationValue)
  }
}