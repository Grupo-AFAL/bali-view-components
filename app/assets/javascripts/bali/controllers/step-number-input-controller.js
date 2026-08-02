import { Controller } from '@hotwired/stimulus'

export class StepNumberInputController extends Controller {
  static targets = ['input', 'add', 'subtract']

  connect () {
    this.value = parseFloat(this.inputTarget.value) || 0
    this.minValue = parseFloat(this.inputTarget.min) || 0
    this.maxValue = parseFloat(this.inputTarget.max) || Infinity
    this.step = parseFloat(this.inputTarget.step) || 1
    this.updateValue()

    this.inputTarget.addEventListener('change', this.handleInputChange)
  }

  disconnect () {
    if (this.hasInputTarget) {
      this.inputTarget.removeEventListener('change', this.handleInputChange)
    }
  }

  add (event) {
    event.preventDefault()
    this.value += this.step
    this.updateValue()
    this.dispatchChange()
  }

  subtract (event) {
    event.preventDefault()
    this.value -= this.step
    this.updateValue()
    this.dispatchChange()
  }

  updateValue () {
    this.value = Math.max(Math.min(this.value, this.maxValue), this.minValue)
    this.inputTarget.value = this.value

    this.updateButtonState(this.addTarget, this.value >= this.maxValue)
    this.updateButtonState(this.subtractTarget, this.value <= this.minValue)
  }

  // A disabled field stays disabled. The buttons carry their targets even when the
  // field is disabled, so without this the first updateValue would re-enable them.
  updateButtonState (button, atLimit) {
    const disabled = atLimit || this.inputTarget.disabled

    button.classList.toggle('btn-disabled', disabled)
    button.classList.toggle('pointer-events-none', disabled)
    button.disabled = disabled
  }

  // Arrow function preserves `this` binding when used as event listener
  handleInputChange = (event) => {
    const newValue = parseFloat(event.target.value) || 0
    if (newValue !== this.value) {
      this.value = newValue
      this.updateValue()
    }
  }

  dispatchChange () {
    this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }))
  }
}
