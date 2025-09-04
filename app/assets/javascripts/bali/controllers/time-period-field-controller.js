import { Controller } from '@hotwired/stimulus'

export class TimePeriodFieldController extends Controller {
  static targets = ['select', 'dateInput', 'input']

  connect = () => {
    this.toggleDateInput()
    this.setInputValue()
  }

  toggleDateInput = () => {
    if (this.selectTarget.value === '') {
      this.dateInputTarget.classList.remove('is-hidden')
    } else {
      this.dateInputTarget.classList.add('is-hidden')
    }
  }

  setInputValue = () => {
    if (this.selectTarget.value === '') {
      this.inputTarget.value = this.dateInputTarget.value
    } else {
      this.inputTarget.value = this.selectTarget.value
    }
  }
}
