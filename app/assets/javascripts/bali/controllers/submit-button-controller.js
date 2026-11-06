import { Controller } from '@hotwired/stimulus'

/**
 * SubmitButton Controller
 * Displays a loading button state when a form submission is started
 * It relies on @hotwired/turbo events to display and hide the loading state
 *
 * Options, all opt-in:
 * - `hold-others` (Boolean): on a wrapper around several forms (a launcher of choices, each its own button_to),
 *   the other submit buttons inside it are disabled while one submits, so a second tap doesn't start a second
 *   action. They are released when the submit fails, and before Turbo caches the page: a copy cached while they
 *   were held would come back from Back with dead buttons. Buttons already disabled are left alone.
 * - `spinner` (Boolean, default true): false leaves the submitter's content alone, for a button that shows its own
 *   busy text through Turbo's `data-turbo-submits-with`.
 * - `status` target: a `role="status"` element that receives the submitter's busy text (its
 *   `data-turbo-submits-with`), so a screen reader hears what is happening.
 *
 * https://daisyui.com/components/loading/
 */

export class SubmitButtonController extends Controller {
  static targets = ['status']
  static values = { holdOthers: Boolean, spinner: { type: Boolean, default: true } }

  connect () {
    this.element.addEventListener('turbo:submit-start', this.disableButton)
    this.element.addEventListener('turbo:submit-end', this.enableButton)
  }

  holdOthersValueChanged (holding) {
    document.removeEventListener('turbo:before-cache', this.releaseOthers)
    if (holding) document.addEventListener('turbo:before-cache', this.releaseOthers)
  }

  disconnect () {
    this.element.removeEventListener('turbo:submit-start', this.disableButton)
    this.element.removeEventListener('turbo:submit-end', this.enableButton)
    document.removeEventListener('turbo:before-cache', this.releaseOthers)
  }

  disableButton = event => {
    const button = event.detail.formSubmission.submitter
    if (this.holdOthersValue) this.holdOthers(button)
    if (this.hasStatusTarget) this.statusTarget.textContent = button?.dataset.turboSubmitsWith || ''
    // Once per button: a form's own controller inside a wrapper's runs first, and a second swap would save its
    // spinner as the label to put back.
    if (!button || !this.spinnerValue || button.hasAttribute('data-submit-button-original-html')) return

    // Capture styles BEFORE disabling. DaisyUI 5 overrides --btn-fg to
    // near-transparent on :disabled, turning the button gray and hiding
    // the spinner. We preserve the original colors for a polished look.
    const styles = window.getComputedStyle(button)
    const spinnerColor = styles.color
    const bgColor = styles.backgroundColor

    button.style.width = `${button.offsetWidth}px`
    button.setAttribute('data-submit-button-original-html', button.innerHTML)
    button.innerHTML = `<span class="loading loading-spinner loading-sm" style="color: ${spinnerColor}"></span>`
    button.setAttribute('disabled', '')

    // Override DaisyUI's disabled styling to keep the primary tone
    button.style.backgroundColor = bgColor
    button.style.opacity = '0.7'
  }

  enableButton = event => {
    // A submit that succeeded is on its way to the next page: the others stay held until Turbo caches this one. A
    // failed one clears the status, so a retry with the same text is announced again.
    if (this.holdOthersValue && !event.detail.success) this.releaseOthers()
    if (this.hasStatusTarget && !event.detail.success) this.statusTarget.textContent = ''

    const button = event.detail.formSubmission.submitter
    if (!button || !this.spinnerValue) return

    const originalHtml = button.getAttribute('data-submit-button-original-html')
    if (originalHtml !== null) {
      button.innerHTML = originalHtml
      button.removeAttribute('data-submit-button-original-html')
    }

    button.style.width = ''
    button.style.backgroundColor = ''
    button.style.opacity = ''
    button.removeAttribute('disabled')
  }

  holdOthers (pressed) {
    this.element.querySelectorAll('button[type="submit"], button:not([type]), input[type="submit"]')
      .forEach(button => {
        if (button === pressed || button.disabled) return

        button.disabled = true
        button.setAttribute('data-submit-button-held', '')
      })
  }

  releaseOthers = () => {
    this.element.querySelectorAll('[data-submit-button-held]').forEach(button => {
      button.disabled = false
      button.removeAttribute('data-submit-button-held')
    })
    if (this.hasStatusTarget) this.statusTarget.textContent = ''
  }
}
