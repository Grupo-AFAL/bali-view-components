import { Controller } from '@hotwired/stimulus'

/**
 * Dictation into a form control, through the browser's OWN speech recognition
 * (Web Speech API).
 *
 * `f.text_area_group(:body, dictation: true)` builds it; by hand:
 *
 *   <div data-controller="speech-input" data-speech-input-lang-value="es-MX">
 *     <textarea data-speech-input-target="input"
 *               data-action="input->speech-input#typed"></textarea>
 *     <button type="button" hidden
 *             data-speech-input-target="button"
 *             data-action="speech-input#toggle">…</button>
 *     <p role="status" hidden data-speech-input-target="status">…</p>
 *   </div>
 *
 * The button is born `hidden` and this controller is what reveals it: where the
 * browser has no recognition — or the field is `readonly` or `disabled` — the
 * field stays exactly what it was.
 *
 * PRIVACY. The page never receives the audio, but the BROWSER sends it to its own
 * vendor to transcribe: Google in Chrome, Microsoft in Edge, Apple in Safari. It
 * leaves whatever perimeter the host lives in. Say so to whoever will be talking
 * into it; the guide carries the long version.
 */
// Errors worth telling the person about, rather than a mic that simply did nothing. The button
// STAYS either way: `not-allowed` is also what Chrome reports when the permission prompt is
// dismissed without choosing, and `network` can be one bad second — retiring the mic for either
// would need a reload to undo.
const REPORTED_ERRORS = [
  'not-allowed', 'service-not-allowed', 'network', 'audio-capture', 'language-not-supported'
]

export class SpeechInputController extends Controller {
  static targets = ['input', 'button', 'status']
  // No default: without `lang` the API uses the page's own `<html lang>`, which is right far
  // more often than any language this file could pick for every host.
  static values = { lang: String }

  // Turbo takes its snapshot BEFORE `disconnect`, so a page left mid-dictation — or left after a
  // failure — comes back from the cache with the button red and the status line showing. Both
  // are laid down again on every connect rather than trusted.
  connect () {
    if (!this.hasInputTarget || !this.hasButtonTarget) return

    this.setRecording(false)
    this.report(null)

    const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition
    if (!Recognition || this.inputTarget.readOnly || this.inputTarget.disabled) return

    this.Recognition = Recognition
    this.buttonTarget.hidden = false

    // A submitted form leaves a mic open on a composer that is already gone. The controller
    // listens for it itself: a `data-action` on the form is one more thing for a call site to
    // forget, and forgetting it is not visible.
    this.form = this.inputTarget.form
    this.cancelOnSubmit = () => this.cancel()
    this.form?.addEventListener('submit', this.cancelOnSubmit)
  }

  disconnect () {
    this.cancel()
    this.form?.removeEventListener('submit', this.cancelOnSubmit)
  }

  toggle () {
    this.recognition ? this.finish() : this.start()
  }

  start () {
    if (!this.Recognition) return

    const recognition = new this.Recognition()
    if (this.hasLangValue) recognition.lang = this.langValue
    // `continuous` so the pauses of someone thinking out loud do not end the session,
    // `interimResults` so the words appear as they are said.
    recognition.continuous = true
    recognition.interimResults = true

    // A session that has already been replaced still delivers events; acting on them would write
    // over the field, or clean up after the session that took its place.
    const ifCurrent = handler => event => { if (recognition === this.recognition) handler(event) }
    recognition.addEventListener('result', ifCurrent(event => this.transcribe(event)))
    recognition.addEventListener('end', ifCurrent(() => this.released()))
    recognition.addEventListener('error', ifCurrent(event => this.fail(event)))

    this.base = this.inputTarget.value
    this.recognition = recognition
    this.report(null)

    try {
      recognition.start()
      this.setRecording(true)
    } catch {
      // `start()` on a session the engine has not released yet. Nothing was dictated and nothing
      // is listening: drop it and let the next tap try again.
      this.recognition = null
    }
  }

  // Tapping the mic again ENDS the dictation and keeps what was already said. `stop()` is the
  // call that delivers the audio the engine is still holding — `abort()` is the one that throws
  // it away — so the session stays current until its `end`, and the last phrase lands.
  finish () {
    if (!this.recognition) return

    this.setRecording(false)
    this.recognition.stop()
  }

  // Typing or submitting means the field has moved on: whatever the engine is still holding
  // would be written over what is there now, so here it IS thrown away.
  cancel () {
    const recognition = this.recognition
    if (!recognition) return

    this.recognition = null
    this.setRecording(false)
    recognition.abort()
  }

  // The engine let go, after a `stop()`, a silence of its own, or an error.
  released () {
    this.recognition = null
    this.setRecording(false)
  }

  // Anything that writes into the field while the mic is open ends the dictation: the next
  // result rebuilds the field from `base` and would eat what was just written. Everything except
  // the controller's own write, which is flagged in `transcribe`.
  //
  // Not `event.isTrusted`: it is true of a person's keystroke and false of every other script's,
  // so a field a datepicker or an autofill writes into would keep dictating over it — and no
  // test can produce a trusted event, which left the guard uncovered.
  typed () {
    if (!this.writing) this.cancel()
  }

  // The WHOLE result list every time, not the last chunk: the API re-emits a phrase as it
  // corrects it, so appending would stutter.
  transcribe (event) {
    const said = Array.from(event.results, result => result[0].transcript)
      .join(' ').replace(/\s+/g, ' ').trim()

    this.inputTarget.value = [this.base, said].filter(Boolean).join(' ')
    // The `textarea` controller re-measures on `input` only, and a scripted value fires none —
    // without this a dictated answer grows past a box that stays put. Dispatching is synchronous,
    // so the flag is exactly as wide as the write.
    this.writing = true
    this.inputTarget.dispatchEvent(new Event('input', { bubbles: true }))
    this.writing = false
  }

  fail (event) {
    this.released()
    this.report(REPORTED_ERRORS.includes(event.error) ? event.error : null)
  }

  // The line that says the dictation did not happen. The button is NOT retired with it: the
  // person keeps the one control that can retry, and the next `start()` clears the line.
  report (error) {
    if (!this.hasStatusTarget) return

    this.statusTarget.hidden = !error
  }

  setRecording (on) {
    this.buttonTarget.classList.toggle('btn-error', on)
    this.buttonTarget.classList.toggle('btn-ghost', !on)
    this.buttonTarget.setAttribute('aria-pressed', String(on))
  }
}
