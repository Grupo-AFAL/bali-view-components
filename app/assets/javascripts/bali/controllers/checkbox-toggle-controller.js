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
 *
 *
 * `data-checkbox-toggle-disable-hidden-value="true"` disables the hidden target, so
 * the form does not send its fields. The targets have to be `<fieldset>`s.
 */

export class CheckboxToggleController extends Controller {
  static targets = ['on', 'off']
  static values = { checked: Boolean, disableHidden: Boolean }

  change (event) {
    this.checkedValue = event.target.checked
    this.toggleTargets(this.checkedValue)
  }

  // Stimulus also calls these for the targets present at connect, so they are the
  // whole initial render. A target a Turbo Stream replaces later lands here too,
  // and takes the state on screen rather than the one the server painted. Both go
  // through `toggleTargets`, not `toggle(element)`, so a subclass that overrides
  // it still renders on connect.
  onTargetConnected () {
    this.toggleTargets(this.checkedValue)
  }

  offTargetConnected () {
    this.toggleTargets(this.checkedValue)
  }

  toggleTargets (checked) {
    this.toggle(this.onTarget, checked)
    this.toggle(this.offTarget, !checked)
  }

  toggle (element, visible) {
    element.classList.toggle('hidden', !visible)
    // A disabled fieldset sends none of its fields, keeps their own `disabled`
    // and a file already chosen, and covers fields a stream appends later.
    if (this.disableHiddenValue) element.disabled = !visible
  }
}
