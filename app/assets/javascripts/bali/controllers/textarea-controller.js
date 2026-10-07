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
    this.listenForReset()
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

    // Only the horizontal handle and axis are fixed here. Vertical overflow is
    // adjustHeight's, because it depends on whether the cap is biting.
    this.inputTarget.style.resize = 'none'
    this.inputTarget.style.overflowX = 'hidden'

    this.measureMinHeight()
    this.adjustHeight()
  }

  // The floor is the height of the field EMPTY, not the height it happens to have on connect.
  // Measuring the rendered content made a pre-filled field unable to ever shrink below what
  // the server sent it (#1371).
  //
  // An empty field is already at its floor, which is the usual case and costs no mutation at
  // all. A field rendered with content has to be emptied to be measured, and assigning `value`
  // moves the caret and drops the browser's undo stack, so the selection is put back; the undo
  // stack is not recoverable, and this runs once, at connect, on a field nobody has typed in
  // yet.
  measureMinHeight () {
    if (this.minHeightValue !== 0) return

    const textarea = this.inputTarget

    textarea.style.overflowY = 'hidden'
    textarea.style.height = 'auto'

    if (textarea.value === '') {
      this.minHeightValue = textarea.scrollHeight + this.borderHeight()
      return
    }

    const { value, selectionStart, selectionEnd } = textarea

    textarea.value = ''
    this.minHeightValue = textarea.scrollHeight + this.borderHeight()
    textarea.value = value
    textarea.setSelectionRange(selectionStart, selectionEnd)
  }

  // `form.reset()` clears the value WITHOUT firing `input`, the only event this controller
  // listened to, so neither the height nor the counter were told: a long message sent through
  // a Turbo form left the field grown and EMPTY over the content under it, and a counter left
  // reading `523 / 500` in red on an empty field (#1371). It goes through `onInput`, which is
  // what both of those already answer to, and it is registered whether or not the field grows
  // — the counter has the same problem on a fixed-height textarea.
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
    if (!this.hasInputTarget) return

    this.form = this.inputTarget.form
    if (!this.form) return

    this.onReset = () => window.setTimeout(() => this.onInput(), 0)
    this.form.addEventListener('reset', this.onReset)
  }

  adjustHeight () {
    const textarea = this.inputTarget

    // Measured with no scrollbar and no previous height: a visible bar narrows the content box
    // and inflates `scrollHeight`, so a field that had reached the cap kept its bar after the
    // text that needed it was deleted.
    textarea.style.overflowY = 'hidden'
    textarea.style.height = 'auto'

    // A field that is not being rendered — `display: none`, a closed `<details>`, an inactive
    // tab — measures 0. Writing that back collapses it until someone types; leave the height
    // alone and let the stylesheet hold it until it is on screen.
    if (textarea.scrollHeight === 0) return

    // `scrollHeight` is the content box and `height` is the border box (`box-sizing:
    // border-box`), so the borders have to be added back or the field lands short of its own
    // text — measured: 2px on daisyUI's `.textarea`, enough to clip a line with no way to
    // scroll to it.
    const wanted = Math.max(textarea.scrollHeight + this.borderHeight(), this.minHeightValue)
    const height = Math.min(wanted, this.maxAllowedHeight())

    textarea.style.height = `${height}px`

    // Decided here, and no longer a fixed `hidden` written once at setup. A host that capped
    // the growth with `max-h-*` got a box that clipped the text with no way to reach it: the
    // inline `hidden` beat the stylesheet, so there was no scrollbar and no scrolling, which
    // ruled out capping an auto-grow field at all (#1371). Hidden while the content still
    // fits, so no scrollbar flashes as it grows; `auto` the moment the cap bites.
    textarea.style.overflowY = wanted > height ? 'auto' : 'hidden'
  }

  // Top plus bottom border: what `scrollHeight` leaves out and `height` counts in. Read with
  // the vertical scrollbar already off, so it is the borders and nothing else.
  borderHeight () {
    return this.inputTarget.offsetHeight - this.inputTarget.clientHeight
  }

  // The ceiling is the `max-height` the cascade resolved, as long as it is ABSOLUTE. A
  // percentage is not resolved against the container in the computed value — `max-height` is
  // not one of the properties whose resolved value is the used value — so `max-h-full`
  // computes to the string `100%` (measured), and reading a number out of it would cap the
  // field at 100px. A percentage is therefore no ceiling at all, like `none`; `calc()` does
  // compute to px and is honoured.
  maxAllowedHeight () {
    const { maxHeight } = window.getComputedStyle(this.inputTarget)

    return maxHeight.endsWith('px') ? parseFloat(maxHeight) : Infinity
  }
}
