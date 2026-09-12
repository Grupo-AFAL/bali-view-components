import { Controller } from '@hotwired/stimulus'

const EVENT_PREFIX = 'bali:qr-scanner'

// The getUserMedia rejections that mean "someone said no" — the user, a
// permissions policy, or an insecure context — as opposed to "there is no
// camera here". Everything else lands on `unavailable`, including
// NotReadableError (another application holds the device) and
// OverconstrainedError, because from the visitor's side those read the same:
// the camera is not usable right now, and it is not a permission they can grant.
const PERMISSION_ERRORS = ['NotAllowedError', 'PermissionDeniedError', 'SecurityError']

const MISSING_DEPENDENCY_MESSAGE =
  '[bali:qr-scanner] needs the `qr-scanner` npm package, which bali-view-components does ' +
  'not bundle. Run `yarn add qr-scanner` (or `npm install qr-scanner`) and rebuild.'

const INSECURE_CONTEXT_MESSAGE =
  '[bali:qr-scanner] navigator.mediaDevices is undefined. A camera is only reachable from a ' +
  'secure context: https, or http on localhost. Over plain http on any other host the browser ' +
  'exposes no camera at all, which is indistinguishable from a device that has none.'

/**
 * Drives the QR viewfinder: asks for the camera, decodes frames, and announces
 * each code as `bali:qr-scanner:scan`.
 *
 * The decoder is the `qr-scanner` npm package, loaded with a dynamic import so
 * an app that never renders a scanner never pays for it.
 */
export class QrScannerController extends Controller {
  static targets = ['video', 'panel']

  static values = {
    camera: { type: String, default: 'environment' },
    autostart: { type: Boolean, default: true },
    stopOnScan: { type: Boolean, default: true },
    highlight: { type: Boolean, default: true }
  }

  async connect () {
    this.active = true
    this.startWhenVisible = this.startWhenVisible.bind(this)

    if (!this.autostartValue) return this.showState('idle')

    await this.start()
  }

  disconnect () {
    this.active = false
    document.removeEventListener('visibilitychange', this.startWhenVisible)
    this.teardown()
  }

  // The action behind every button in the panels: start, scan again, try again
  // after a denial. They are one thing — open the camera and read frames — and
  // the state the visitor is looking at is the only difference between them.
  async start () {
    this.showState('requesting')

    // qr-scanner's own start() takes a shortcut while the tab is in the
    // background: it flags itself active, resolves, and touches no camera —
    // meaning to open one later, from its own visibilitychange handler. Taking
    // that resolution at face value would render "scanning" over a black box,
    // and the permission failure that arrives when the tab is finally looked at
    // would be thrown somewhere we are not listening. So we wait for the tab
    // instead, and keep the request — and its error path — on this side.
    if (document.hidden) {
      document.addEventListener('visibilitychange', this.startWhenVisible)
      return
    }

    const scanner = await this.buildScanner()
    if (!scanner) return

    try {
      await scanner.start()
    } catch (error) {
      // Disconnected mid-flight: a camera the DOM no longer has a use for is a
      // camera whose light stays on.
      if (!this.active) return this.teardown()

      return this.fail(await this.diagnose(), error)
    }

    if (!this.active) return this.teardown()

    this.showState('scanning')
  }

  startWhenVisible () {
    if (document.hidden || !this.active) return

    document.removeEventListener('visibilitychange', this.startWhenVisible)
    this.start()
  }

  // qr-scanner swallows every getUserMedia rejection — six of them, one per
  // constraint it tries — and rethrows the single string 'Camera not found.',
  // so its own error cannot tell a refused permission from a missing camera.
  // One more call, on the failure path only, asks the browser directly. The
  // happy path never pays for it, which is why the probe is here and not in
  // front of the scanner: opening a stream only to close it and let the library
  // open its own costs a second of latency and blinks the camera light.
  async diagnose () {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: false })
      stream.getTracks().forEach(track => track.stop())
      return 'unavailable'
    } catch (error) {
      return PERMISSION_ERRORS.includes(error?.name) ? 'denied' : 'unavailable'
    }
  }

  onScan (result) {
    // `returnDetailedScanResult` gets us the object form; the string is what the
    // library's own deprecated path still hands back.
    const value = typeof result === 'string' ? result : result?.data
    if (!value) return

    if (this.stopOnScanValue) {
      this.scanner?.stop()
      this.showState('scanned')
    }

    this.dispatch('scan', { prefix: EVENT_PREFIX, detail: { value, result } })
  }

  async buildScanner () {
    if (this.scanner) return this.scanner

    if (!navigator.mediaDevices?.getUserMedia) {
      console.warn(INSECURE_CONTEXT_MESSAGE)
      this.fail('unavailable', new Error('navigator.mediaDevices is unavailable'))
      return null
    }

    let QrScanner
    try {
      QrScanner = (await import('qr-scanner')).default
    } catch (error) {
      console.error(MISSING_DEPENDENCY_MESSAGE, error)
      this.fail('unavailable', error)
      return null
    }

    if (!this.active) return null

    this.scanner = new QrScanner(this.videoTarget, result => this.onScan(result), {
      preferredCamera: this.cameraValue,
      highlightScanRegion: this.highlightValue,
      highlightCodeOutline: this.highlightValue,
      returnDetailedScanResult: true
    })

    return this.scanner
  }

  // `destroy()` stops the tracks itself, but stopping first is the line that
  // says what this is for: releasing the device, so the camera light goes out.
  teardown () {
    this.scanner?.stop()
    this.scanner?.destroy()
    this.scanner = null
  }

  fail (state, error) {
    this.showState(state)
    this.dispatch('error', { prefix: EVENT_PREFIX, detail: { state, error } })
  }

  showState (state) {
    this.element.dataset.qrScannerState = state
    this.panelTargets.forEach(panel => {
      panel.classList.toggle('hidden', panel.dataset.qrScannerPanel !== state)
    })
  }
}
