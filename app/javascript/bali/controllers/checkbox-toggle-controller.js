import { Controller } from '@hotwired/stimulus'

/**
 * Toggles ON and OFF different elements based on the state of a checkbox
 *
 * <div data-controller="checkbox-toggle" data-checkbox-toggle-checked-value="true">
 *   <input data-action="checkbox-toggle#change" type="checkbox">
 *   <div data-checkbox-toggle-target="off">
 *     Off content
 *   </div>
 *  <div data-checkbox-toggle-target="on">
 *    On content
 *  </div>
 * </div>
 */

// TODO: Add tests (Issue: #138)
export class CheckboxToggleController extends Controller {
  static targets = ['on', 'off']
  static values = { checked: Boolean }

  connect () {
    this.toggleTargets(this.checkedValue)
  }

  change (event) {
    this.toggleTargets(event.target.checked)
  }

  toggleTargets (checked) {
    if (checked) {
      this.onTarget.classList.remove('is-hidden')
      this.offTarget.classList.add('is-hidden')
    } else {
      this.onTarget.classList.add('is-hidden')
      this.offTarget.classList.remove('is-hidden')
    }
  }
}
