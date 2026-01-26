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
    this.inputTarget.removeEventListener('change', this.handleInputChange)
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

  updateButtonState (button, atLimit) {
    if (!button) return

    button.classList.toggle('btn-disabled', atLimit)
    button.classList.toggle('pointer-events-none', atLimit)
    button.disabled = atLimit
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
