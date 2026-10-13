import { Controller } from '@hotwired/stimulus'

/**
 * The two things a chat composer has to do that a plain form does not: clear itself
 * after a message goes through, and send on Enter.
 *
 * `Chat::Composer::Component` wires it. Both behaviours were the host's to
 * reimplement before — gobierno-corporativo carries its own `reset-form` for the
 * first — and the second stopped working for free the moment the composer became a
 * `<textarea>`, where Enter is a newline.
 */
export class ChatComposerController extends Controller {
  static targets = ['field']
  static values = { submitOnEnter: { type: Boolean, default: true } }

  // `turbo:submit-end` fires whether the server accepted the message or not, and the
  // event carries the verdict. Clearing unconditionally throws away what the person
  // would have to type again — a rate limit, a validation, a 500 — which is exactly
  // the complaint that got `reset-form` written in the first place.
  submitEnd (event) {
    if (!event.detail?.success) return

    this.element.closest('form')?.reset()
    // The reset does not fire `input`, so anything sizing itself off the value has to
    // be told. `textarea`'s auto-grow listens for this; so does a character counter.
    this.fieldTarget.dispatchEvent(new Event('input', { bubbles: true }))
    // No `focus()` here. Putting the caret back in the field after a send reads like an
    // obvious courtesy, and it does not work: measured in Chrome 150, the focus lands on
    // `<body>` whether it is taken in this handler or a task later. Rather than ship a line
    // that looks like it does something, it is left out until someone finds out why.
  }

  // Enter sends, Shift+Enter writes a newline — what every chat does, and what the
  // `<input>` this composer replaced did for free. `isComposing` is not optional: an
  // IME commits a candidate with Enter, and submitting there would send half a word
  // in Japanese, Chinese or Korean.
  enter (event) {
    if (!this.submitOnEnterValue) return
    if (event.shiftKey || event.isComposing) return

    const form = this.element.closest('form')
    if (!form) return

    event.preventDefault()
    form.requestSubmit()
  }
}
