import { Controller } from '@hotwired/stimulus'

// TODO: Add tests (Issue: #158)

export class StepNumberInputController extends Controller {
  static targets = ['input', 'add', 'subtract']

  connect () {
    this.value = parseFloat(this.inputTarget.value) || 0
    this.minValue = parseInt(this.inputTarget.min) || 0
    this.maxValue = parseInt(this.inputTarget.max) || 10
    this.step = parseFloat(this.inputTarget.step) || 1
    this.setValue()

    this.inputTarget.addEventListener('change', this.updateValue)
  }

  disconnect () {
    this.inputTarget.removeEventListener('change', this.updateValue)
  }

  add (e) {
    e.preventDefault()
    this.value += this.step
    this.setValue()
    this.triggerChangeEvent()
  }

  subtract (e) {
    e.preventDefault()
    this.value -= this.step
    this.setValue()
    this.triggerChangeEvent()
  }

  setValue () {
    this.value = Math.max(Math.min(this.value, this.maxValue), this.minValue)
    this.inputTarget.value = this.value

    if (this.hasAddTarget) {
      if (this.value === this.maxValue) {
        this.addTarget.classList.add('is-static')
      } else {
        this.addTarget.classList.remove('is-static')
      }
    }

    if (this.hasSubtractTarget) {
      if (this.value === this.minValue) {
        this.subtractTarget.classList.add('is-static')
      } else {
        this.subtractTarget.classList.remove('is-static')
      }
    }
  }

  updateValue = event => {
    const newValue = parseFloat(event.target.value) || 0

    if (newValue === this.value) return

    this.value = newValue
    this.setValue()
  }

  triggerChangeEvent () {
    const event = document.createEvent('HTMLEvents')
    event.initEvent('change', false, true)
    this.inputTarget.dispatchEvent(event)
  }
}
