import { Controller } from '@hotwired/stimulus'
import debounce from 'lodash.debounce'

/**
 * SubmitOnChange Controller
 * Automatically submits the form when the form element changes value
 *
 * How to use:
 *
 * <form action="/"
 *       data-controller="submit-on-change"
 *       data-submit-on-change-action-value="/users"
 *       data-submit-on-change-method-value="get">
 *  <select data-action="submit-on-change#submit">
 *    <option value="1">One</option>
 *    <option value="2">Two</option>
 *  </select>
 *  <input type="search" data-action="submit-on-change#debouncedSubmit">
 * </form>
 *
 */

/** Debounce applied to `debouncedSubmit` when the form declares no `delay` of its own. */
const DEFAULT_DELAY = 300

export class SubmitOnChangeController extends Controller {
  static values = {
    delay: Number,
    action: String,
    method: String,
    skipInitial: { type: Boolean, default: true }
  }

  connect () {
    // Skip change events fired during SlimSelect initialization: it emits one on the
    // native <select> while it builds itself over it, which submitted a form nobody had
    // touched. `skip-initial-value="false"` opts back into the old behavior for a host
    // that does submit as the form connects.
    this.ready = !this.skipInitialValue
    if (!this.ready) this.becomeReadyAfterFirstFrame()

    this.submitAfterDelay = debounce(() => this.submitNow(), this.delay)

    if (this.hasActionValue || this.hasMethodValue) {
      this.submitterNode = this.createSubmitterNode()
      this.element.appendChild(this.submitterNode)
    }
  }

  disconnect () {
    window.cancelAnimationFrame(this.readyFrame)
    clearTimeout(this.readyTimer)
    this.submitAfterDelay.cancel()
  }

  becomeReadyAfterFirstFrame () {
    const markReady = () => { this.ready = true }

    this.readyFrame = window.requestAnimationFrame(markReady)

    // A hidden document never paints, so that frame never arrives and the form would stay
    // inert for good — measured: no rAF callback in 2s in a background tab. There is also
    // nothing to guard against while hidden, because SlimSelect's initialization is
    // frame-driven too and has not run either. So a hidden document gets a timer instead,
    // and a visible one keeps waiting for the frame.
    if (document.hidden) this.readyTimer = setTimeout(markReady, 0)
  }

  /** Immediate, unless the form sets `delay` — which has always debounced this action. */
  submit () {
    if (!this.ready) return

    if (this.hasDelayValue && this.delayValue > 0) {
      this.submitAfterDelay()
    } else {
      this.submitNow()
    }
  }

  /**
   * Always debounced, so one controller serves both kinds of control on the same form:
   * selects submit through `submit`, text inputs through this one.
   */
  debouncedSubmit () {
    if (!this.ready) return

    this.submitAfterDelay()
  }

  submitNow () {
    this.element.requestSubmit(this.submitterNode)
  }

  get delay () {
    return this.hasDelayValue && this.delayValue > 0 ? this.delayValue : DEFAULT_DELAY
  }

  createSubmitterNode () {
    const input = document.createElement('input')
    input.type = 'submit'
    input.className = 'hidden'
    input.setAttribute('formaction', this.formAction)
    input.setAttribute('formmethod', this.formMethod)
    return input
  }

  get formAction () {
    return this.hasActionValue
      ? this.actionValue
      : this.element.getAttribute('action')
  }

  get formMethod () {
    return this.hasMethodValue
      ? this.methodValue
      : this.element.getAttribute('method')
  }
}
