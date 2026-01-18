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
    if (!this.hasCounterTarget) return

    const length = this.inputTarget.value.length
    const max = this.maxLengthValue

    if (max > 0) {
      this.counterTarget.textContent = `${length} / ${max}`
      this.counterTarget.classList.toggle('text-error', length > max)
    } else {
      this.counterTarget.textContent = `${length}`
    }
  }

  setupAutoGrow () {
    if (!this.autoGrowValue) return

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
