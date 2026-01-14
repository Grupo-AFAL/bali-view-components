import { Controller } from '@hotwired/stimulus'

export class TimePeriodFieldController extends Controller {
  static targets = ['select', 'dateInput', 'input']
  static values = { dateInputContainerClass: String }

  connect = () => {
    this.toggleDateInput()
    this.setInputValue()

    if (!this.hasDateInputContainerClassValue) return
    this.dateInputContainer = this.element.getElementsByClassName(this.dateInputContainerClassValue)[0]
  }

  toggleDateInput = () => {
    if (this.selectTarget.value === '') {
      this._show([this.dateInputTarget, this.dateInputContainer])
    } else {
      this._hide([this.dateInputTarget, this.dateInputContainer])
    }
  }

  setInputValue = () => {
    if (this.selectTarget.value === '') {
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
