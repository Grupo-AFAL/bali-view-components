import { Controller } from '@hotwired/stimulus'

/**
 * Dictation into a form control, through the browser's OWN speech recognition
 * (Web Speech API). No audio reaches the server and no transcription service is
 * involved.
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
 * browser has no recognition the field stays exactly what it was.
 *
 * PRIVACY. The recognition is the browser's, not the page's, and the browsers
 * that have it send the audio to THEIR vendor — Google in Chrome, Microsoft in
 * Edge, Apple in Safari. It leaves whatever perimeter the host lives in, which
 * is why `dictation:` is off by default and why the guide says so out loud.
 */
// Errors that come back on every try: permission refused, the service blocked or
// unreachable, a language the engine does not have. The button goes away and the
// status line says so, instead of a mic that stays red and grey forever.
const FATAL_ERRORS = [
  'not-allowed', 'service-not-allowed', 'network', 'audio-capture', 'language-not-supported'
]

export class SpeechInputController extends Controller {
  static targets = ['input', 'button', 'status']
  static values = { lang: { type: String, default: 'es-MX' } }

  // Turbo takes its snapshot BEFORE `disconnect`, so a page left mid-dictation
  // comes back from the cache with the button still red and `aria-pressed`. The
  // state is laid down again on every connect rather than trusted.
  connect () {
    if (!this.hasInputTarget || !this.hasButtonTarget) return

    this.setRecording(false)
    this.Recognition = window.SpeechRecognition || window.webkitSpeechRecognition
    if (!this.Recognition) return

    this.buttonTarget.hidden = false
    this.stopOnSubmit = () => this.stop()
    this.form = this.inputTarget.form
    // A submitted form leaves a mic open on a composer that is already gone. The
    // controller listens for it itself: a `data-action` on the form is one more
    // thing for a call site to forget, and forgetting it is not visible.
    this.form?.addEventListener('submit', this.stopOnSubmit)
  }

  disconnect () {
    this.stop()
    this.form?.removeEventListener('submit', this.stopOnSubmit)
  }

  toggle () {
    this.recognition ? this.stop() : this.start()
  }

  start () {
    const recognition = new this.Recognition()
    recognition.lang = this.langValue
    // `continuous` so the pauses of someone thinking out loud do not end the
    // session, `interimResults` so the words appear as they are said.
    recognition.continuous = true
    recognition.interimResults = true

    // A stopped session still delivers its last `result` and its `end` afterwards.
    // Acting on either would write over the field, or stop the session that has
    // already replaced this one.
    const ifCurrent = handler => event => { if (recognition === this.recognition) handler(event) }
    recognition.addEventListener('result', ifCurrent(event => this.transcribe(event)))
    recognition.addEventListener('end', ifCurrent(() => this.stop()))
    recognition.addEventListener('error', ifCurrent(event => this.fail(event)))

    this.base = this.inputTarget.value
    this.recognition = recognition

    try {
      recognition.start()
      this.setRecording(true)
    } catch {
      // `start()` on a session the engine has not released yet. Nothing was
      // dictated and nothing is listening: drop it and let the next click try.
      this.recognition = null
    }
  }

  stop () {
    const recognition = this.recognition
    if (!recognition) return

    this.recognition = null
    recognition.stop()
    this.setRecording(false)
  }

  // Anything that writes into the field while the mic is open ends the dictation: the
  // next result rebuilds the field from `base` and would eat what was just written.
  // Everything except the controller's OWN write, which is flagged below.
  //
  // Not `event.isTrusted`: it is true of a person's keystroke and false of every other
  // script's, so a field a datepicker or an autofill writes into would keep dictating
  // over it — and no test can produce a trusted event, which left the guard uncovered.
  typed () {
    if (!this.writing) this.stop()
  }

  // The WHOLE result list every time, not the last chunk: the API re-emits a
  // phrase as it corrects it, so appending would stutter.
  transcribe (event) {
    const said = Array.from(event.results, result => result[0].transcript)
      .join(' ').replace(/\s+/g, ' ').trim()

    this.inputTarget.value = [this.base, said].filter(Boolean).join(' ')
    // The `textarea` controller re-measures on `input` only, and a scripted value
    // fires none — without this a dictated answer grows past a box that stays put.
    // Dispatching is synchronous, so the flag is exactly as wide as the write.
    this.writing = true
    this.inputTarget.dispatchEvent(new Event('input', { bubbles: true }))
    this.writing = false
  }

  fail (event) {
    this.stop()
    if (!FATAL_ERRORS.includes(event.error)) return

    this.buttonTarget.hidden = true
    if (this.hasStatusTarget) this.statusTarget.hidden = false
  }

  setRecording (on) {
    this.buttonTarget.classList.toggle('btn-error', on)
    this.buttonTarget.classList.toggle('btn-ghost', !on)
    this.buttonTarget.setAttribute('aria-pressed', String(on))
  }
}
