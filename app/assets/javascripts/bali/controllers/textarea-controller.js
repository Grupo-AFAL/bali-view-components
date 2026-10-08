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
 * `max-height` CSS applies to it — px, percentage, `calc()`, `clamp()` alike —
 * past which the field scrolls instead of growing. It follows `form.reset()` as
 * well as typing.
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

    textarea.style.height = 'auto'

    if (textarea.value === '') {
      this.minHeightValue = textarea.scrollHeight + this.borderHeight()
      return
    }

    // `selectionDirection` travels with the rest: `setSelectionRange` defaults its third
    // argument to 'none', so a backwards selection would come back forwards (measured).
    const { value, selectionStart, selectionEnd, selectionDirection } = textarea

    textarea.value = ''
    this.minHeightValue = textarea.scrollHeight + this.borderHeight()
    textarea.value = value
    textarea.setSelectionRange(selectionStart, selectionEnd, selectionDirection)
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
    // tab — measures 0, and anything written from that measurement is wrong. Nothing is left
    // inline either: an `overflow-y: hidden` of ours beats the stylesheet and would show the
    // field, once it finally has a box, clipped at its `rows` with no way to scroll. It still
    // will not GROW until the first keystroke, because nothing re-measures when it appears:
    // #1377.
    if (textarea.scrollHeight === 0) {
      textarea.style.height = ''
      textarea.style.overflowY = ''
      return
    }

    // `scrollHeight` is the content box and `height` is the border box (`box-sizing:
    // border-box`), so the borders have to be added back or the field lands short of its own
    // text — measured: 2px on daisyUI's `.textarea`, enough to clip a line. They come off the
    // computed style and the total is rounded UP, because `offsetHeight - clientHeight` is a
    // difference of two separately rounded integers and loses a fractional border (a 1px CSS
    // border is ~0.67 device px at 150% zoom).
    const wanted = Math.max(textarea.scrollHeight + this.borderHeight(), this.minHeightValue)
    textarea.style.height = `${Math.ceil(wanted)}px`

    // The ceiling is NOT predicted from the computed `max-height`, it is measured after the
    // fact: whatever CSS applied — px, a percentage that resolved against a sized parent,
    // `calc()`, `clamp()` — is already in `clientHeight` by now. Reading the cap instead of
    // measuring it meant guessing, and a percentage cannot be resolved from the computed value
    // (`max-h-full` computes to the string `100%`): treating it as pixels capped the field at
    // 100px, and treating it as no cap let CSS clip 414px of text with `overflow-y: hidden`
    // written over it — both measured, both the #1371 defect over again.
    textarea.style.overflowY = textarea.scrollHeight > textarea.clientHeight ? 'auto' : 'hidden'
  }

  // Top plus bottom border: what `scrollHeight` leaves out and `height` counts in.
  borderHeight () {
    const { borderTopWidth, borderBottomWidth } = window.getComputedStyle(this.inputTarget)

    return parseFloat(borderTopWidth) + parseFloat(borderBottomWidth)
  }
}
