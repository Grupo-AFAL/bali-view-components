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

    // Capture the button's visible text color BEFORE disabling.
    // DaisyUI 5 sets --btn-fg to near-transparent on :disabled,
    // which makes the loading spinner invisible via currentColor.
    const spinnerColor = getComputedStyle(button).color

    button.style.width = `${button.offsetWidth}px`
    button.setAttribute('data-submit-button-original-html', button.innerHTML)
    button.innerHTML = `<span class="loading loading-spinner loading-sm" style="color: ${spinnerColor}"></span>`
    button.setAttribute('disabled', '')
  }

  enableButton = event => {
    const button = event.detail.formSubmission.submitter
    if (!button) return

    const originalHtml = button.getAttribute('data-submit-button-original-html')
    if (originalHtml !== null) {
      button.innerHTML = originalHtml
      button.removeAttribute('data-submit-button-original-html')
    }

    button.style.width = ''
    button.removeAttribute('disabled')
  }
}
