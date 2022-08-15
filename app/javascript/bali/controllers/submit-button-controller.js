import { Controller } from '@hotwired/stimulus'

/**
 * SubmitButton Controller
 * Displays a loading button state when a form submission is started
 * It relies on @hotwired/turbo events to display and hide the loading state
 *
 * https://bulma.io/documentation/elements/button/#states
 */

// TODO: Add tests (Issue: #144)
export class SubmitButtonController extends Controller {
  connect () {
    this.element.addEventListener('turbo:submit-start', this.disableButton)
    this.element.addEventListener('turbo:submit-end', this.enableButton)
  }

  disableButton = event => {
    const button = event.detail.formSubmission.submitter
    if (!button) return

    button.classList.add('is-loading')
    button.setAttribute('disabled', '')
  }

  enableButton = event => {
    const button = event.detail.formSubmission.submitter
    if (!button) return

    button.classList.remove('is-loading')
    button.removeAttribute('disabled')
  }
}
