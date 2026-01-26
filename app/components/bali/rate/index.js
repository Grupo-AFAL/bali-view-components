import { Controller } from '@hotwired/stimulus'

/**
 * RateController - Handles auto-submit functionality for Rate component
 *
 * When autoSubmit is enabled, clicking a star will:
 * 1. Update the hidden input with the selected value
 * 2. Submit the parent form
 */
export class RateController extends Controller {
  static targets = ['input']
  static values = { autoSubmit: Boolean }

  submit (event) {
    if (!this.autoSubmitValue) return

    const rate = event.target.dataset.rate
    if (this.hasInputTarget) {
      this.inputTarget.value = rate
    }

    // Submit the parent form
    const form = this.element.closest('form')
    if (form) {
      form.requestSubmit()
    }
  }
}
