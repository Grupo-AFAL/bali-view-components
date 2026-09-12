import { Controller } from '@hotwired/stimulus'

/**
 * Textarea controller with optional character counter and auto-grow functionality.
 *
 * Usage:
 *   <div data-controller="textarea"
 *        data-textarea-max-length-value="500"
 *        data-textarea-auto-grow-value="true">
 *     <textarea data-textarea-target="input"></textarea>
 *     <span data-textarea-target="counter"></span>
 *   </div>
 */
export class TextareaController extends Controller {
  static targets = ['input', 'counter']
  static values = {
    maxLength: { type: Number, default: 0 },
    autoGrow: { type: Boolean, default: false },
    minHeight: { type: Number, default: 0 }
  }

  connect () {
    this.updateCounter()
    this.setupAutoGrow()
  }

  // Called on input event
  onInput () {
    this.updateCounter()
    if (this.autoGrowValue) {
      this.adjustHeight()
    }
  }

  updateCounter () {
    if (!this.hasCounterTarget || !this.hasInputTarget) return

    const length = this.inputTarget.value.length
    const max = this.maxLengthValue

    if (max > 0) {
      this.counterTarget.textContent = `${length} / ${max}`
      this.counterTarget.classList.toggle('text-error', length > max)
    } else {
      this.counterTarget.textContent = `${length}`
    }
  }

  // `auto_grow` is a textarea's option: an `<input>` has no height to grow into,
  // so the text field helper never gives its control the input target even
  // though both share this controller (#723). Without the guard, connecting on
  // a text field written `auto_grow: true` throws "Missing target element" —
  // where it used to do nothing at all, which is the right answer.
  setupAutoGrow () {
    if (!this.autoGrowValue || !this.hasInputTarget) return

    // Store initial height as minimum
    if (this.minHeightValue === 0) {
      this.minHeightValue = this.inputTarget.scrollHeight
    }

    // Remove manual resize handle and set overflow
    this.inputTarget.style.resize = 'none'
    this.inputTarget.style.overflow = 'hidden'

    // Initial adjustment
    this.adjustHeight()
  }

  adjustHeight () {
    const textarea = this.inputTarget

    // Reset height to auto to get accurate scrollHeight
    textarea.style.height = 'auto'

    // Set new height, respecting minimum
    const newHeight = Math.max(textarea.scrollHeight, this.minHeightValue)
    textarea.style.height = `${newHeight}px`
  }
}
