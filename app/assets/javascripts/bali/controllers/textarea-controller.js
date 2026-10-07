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
 *
 * Auto-grow runs between two bounds the markup already carries: the height of the
 * textarea EMPTY (its `rows`, unless `min-height-value` says otherwise) and any
 * `max-height` resolved for it in CSS, past which the field scrolls instead of
 * growing. It follows `form.reset()` as well as typing.
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

  disconnect () {
    this.form?.removeEventListener('reset', this.onReset)
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
      // The red of the field's error message, ERROR_MESSAGE_CLASS in
      // lib/bali/form_builder/html_utils.rb: `text-error` read 2.75:1 on `afal`. The grey is
      // COUNTER_CLASS's, and it comes off: two colour utilities on one element resolve by the
      // order Tailwind emits them, not by which one this line adds.
      this.counterTarget.classList.toggle('text-soft-error', length > max)
      this.counterTarget.classList.toggle('text-base-content/70', length <= max)
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

    this.measureMinHeight()

    // Only the horizontal handle and axis are fixed here. Vertical overflow is
    // adjustHeight's, because it depends on whether the cap is biting.
    this.inputTarget.style.resize = 'none'
    this.inputTarget.style.overflowX = 'hidden'

    this.listenForReset()

    // Initial adjustment
    this.adjustHeight()
  }

  // The floor is the height of the field EMPTY, not the height it happens to have on
  // connect. Measuring the rendered content made a pre-filled field unable to ever shrink
  // below what it was first rendered with, which is `rows` read off whatever the server
  // sent rather than off the markup (#1371). Clearing and restoring `value` runs inside one
  // task: nothing paints in between and no `input` event is fired.
  measureMinHeight () {
    if (this.minHeightValue !== 0) return

    const textarea = this.inputTarget
    const value = textarea.value

    textarea.value = ''
    textarea.style.height = 'auto'
    this.minHeightValue = textarea.scrollHeight
    textarea.value = value
  }

  // `form.reset()` clears the value WITHOUT firing `input`, so nothing ever told the
  // controller to shrink and the inline height from the last keystroke stayed behind: a long
  // message sent through a Turbo form left the field grown and EMPTY, covering the content
  // under it until a reload (#1371).
  //
  // The `reset` event fires BEFORE the controls are cleared — cancelling it cancels the reset —
  // so the measurement cannot run inside the handler. It has to wait for a TASK, and the two
  // shorter waits are both wrong here:
  //
  // A microtask runs too early. On a REAL click the checkpoint happens between the event
  // dispatch and the button's activation behaviour (the form reset), so the field is still
  // full when it measures and it writes the grown height right back. It looks correct under
  // `el.click()` and under Cypress, where the dispatch is nested in a JS stack and the
  // checkpoint is pushed past the reset — measured: cleared field, `height: 128px` after a
  // real click, 80px under both synthetic ones.
  //
  // `requestAnimationFrame` never fires in a background tab — measured: `visibilityState:
  // 'hidden'`, no callback in 300ms, field left grown until the tab came forward.
  listenForReset () {
    this.form = this.inputTarget.form
    if (!this.form) return

    this.onReset = () => window.setTimeout(() => this.adjustHeight(), 0)
    this.form.addEventListener('reset', this.onReset)
  }

  adjustHeight () {
    const textarea = this.inputTarget

    // Reset height to auto to get accurate scrollHeight
    textarea.style.height = 'auto'

    // Set new height, respecting minimum and the host's cap
    const wanted = Math.max(textarea.scrollHeight, this.minHeightValue)
    const height = Math.min(wanted, this.maxAllowedHeight())
    textarea.style.height = `${height}px`

    // Decided here, and no longer a fixed `hidden` written once at setup. A host that capped
    // the growth with `max-h-*` got a box that clipped the text with no way to reach it: the
    // inline `hidden` beat the stylesheet, so there was no scrollbar and no scrolling, which
    // ruled out capping an auto-grow field at all (#1371). Hidden while the content still
    // fits, so no scrollbar flashes as it grows; `auto` the moment the cap bites.
    textarea.style.overflowY = wanted > height ? 'auto' : 'hidden'
  }

  // The ceiling is whatever the cascade resolved for `max-height` — a host writes `max-h-48`
  // or `max-height: 12rem` and it is honoured. No new option to pass and nothing to keep in
  // sync: `none` parses to NaN, which is no ceiling.
  maxAllowedHeight () {
    const max = parseFloat(window.getComputedStyle(this.inputTarget).maxHeight)

    return Number.isNaN(max) ? Infinity : max
  }
}
