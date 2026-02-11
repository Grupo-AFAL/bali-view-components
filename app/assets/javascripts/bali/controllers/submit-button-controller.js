import { Controller } from '@hotwired/stimulus'

/**
 * SubmitButton Controller
 * Displays a loading button state when a form submission is started
 * It relies on @hotwired/turbo events to display and hide the loading state
 *
 * https://daisyui.com/components/loading/
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

    const spinner = document.createElement('span')
    spinner.classList.add('loading', 'loading-spinner')
    spinner.setAttribute('data-submit-button-spinner', '')
    button.insertBefore(spinner, button.firstChild)
    button.setAttribute('disabled', '')
  }

  enableButton = event => {
    const button = event.detail.formSubmission.submitter
    if (!button) return

    const spinner = button.querySelector('[data-submit-button-spinner]')
    if (spinner) spinner.remove()

    button.removeAttribute('disabled')
  }
}
