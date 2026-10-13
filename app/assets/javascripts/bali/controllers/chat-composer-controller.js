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

  // Turbo dispatches `turbo:submit-end` ON the form, and events travel up. A
  // `data-action` on this element — which sits INSIDE the form — never sees it, so the
  // listener goes on the form itself, the same way `speech-input` reaches `submit`.
  connect () {
    this.form = this.element.closest('form')
    this.onSubmitEnd = event => this.submitEnd(event)
    this.form?.addEventListener('turbo:submit-end', this.onSubmitEnd)
  }

  disconnect () {
    this.form?.removeEventListener('turbo:submit-end', this.onSubmitEnd)
  }

  // It fires whether the server accepted the message or not, and the event carries the
  // verdict. Clearing unconditionally throws away what the person would have to type
  // again — a rate limit, a validation, a 500.
  submitEnd (event) {
    if (!event.detail?.success) return

    this.form.reset()
    // The reset does not fire `input`, so anything sizing itself off the value has to
    // be told. `textarea`'s auto-grow listens for this; so does a character counter.
    this.fieldTarget.dispatchEvent(new Event('input', { bubbles: true }))
    // Back in the field: writing the next message is the only thing anyone does from here.
    this.fieldTarget.focus()
  }

  // Enter sends, Shift+Enter writes a newline — what every chat does, and what the
  // `<input>` this composer replaced did for free. `isComposing` is not optional: an
  // IME commits a candidate with Enter, and submitting there would send half a word
  // in Japanese, Chinese or Korean.
  enter (event) {
    if (!this.submitOnEnterValue || !this.form) return
    if (event.shiftKey || event.isComposing) return

    event.preventDefault()
    this.form.requestSubmit()
  }
}
