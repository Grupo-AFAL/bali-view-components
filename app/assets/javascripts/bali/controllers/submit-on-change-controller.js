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
 * </form>
 *
 */
export class SubmitOnChangeController extends Controller {
  static values = { delay: Number, action: String, method: String }

  connect () {
    if (this.hasDelayValue && this.delayValue > 0) {
      this.submit = debounce(this.submit, this.delayValue)
    }

    if (this.hasActionValue || this.hasMethodValue) {
      this.submitterNode = this.createSubmitterNode()
      this.element.appendChild(this.submitterNode)
    }
  }

  async submit () {
    this.element.requestSubmit(this.submitterNode)
  }

  createSubmitterNode () {
    const input = document.createElement('input')
    input.type = 'submit'
    input.className = 'is-hidden'
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
