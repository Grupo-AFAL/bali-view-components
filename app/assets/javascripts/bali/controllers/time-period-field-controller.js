import { Controller } from '@hotwired/stimulus'

export class TimePeriodFieldController extends Controller {
  static targets = ['select', 'dateInput', 'input']
  static values = {
    dateInputContainerClass: String,
    // Which option means "let me pick the dates myself". Empty by default because
    // `f.time_period_group` spends its blank option on exactly that. A filter row cannot:
    // its blank option has to mean "no filter", so SimpleFilters names a real one and
    // passes it here.
    custom: { type: String, default: '' }
  }

  connect = () => {
    // Resolved BEFORE the first toggle. `toggleDateInput` is what hides the container, and
    // reading the container after it left the very first render showing it — the form
    // builder only escaped that because it also bakes `hidden` into the input itself.
    if (this.hasDateInputContainerClassValue) {
      this.dateInputContainer = this.element.getElementsByClassName(
        this.dateInputContainerClassValue
      )[0]
    }

    this.toggleDateInput()
    this.setInputValue()
  }

  toggleDateInput = () => {
    if (this.selectTarget.value === this.customValue) {
      this._show([this.dateInputTarget, this.dateInputContainer])
    } else {
      this._hide([this.dateInputTarget, this.dateInputContainer])
    }
  }

  setInputValue = () => {
    if (this.selectTarget.value === this.customValue) {
      this.inputTarget.value = this.dateInputTarget.value
    } else {
      this.inputTarget.value = this.selectTarget.value
    }
  }

  _show = (elements) => {
    elements.filter(el => el).forEach(element => { element.classList.remove('hidden') })
  }

  _hide = (elements) => {
    elements.filter(el => el).forEach(element => { element.classList.add('hidden') })
  }
}
