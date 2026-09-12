import { Controller } from '@hotwired/stimulus'

// The Opina embed reads its credential from a message, not from its URL.
const TOKEN_MESSAGE_TYPE = 'bali:feedback:token'

// What the embed cannot find out for itself. It is cross-origin to the page being
// reported on, so `document.referrer` gives it that page's origin and nothing else:
// the path, the query and the title have to be handed over deliberately.
const CONTEXT_MESSAGE_TYPE = 'bali:feedback:context'

// The embed asking to be told that again. Sending it on the frame's `load` reaches a
// new document and nothing else, and the embed does not always get one: a Turbo-driven
// embed swaps its body over fetch, so the screen that wants a screenshot can arrive
// without a `load` ever firing. Whatever puts the form on screen asks for the context
// itself, and the answer stops depending on how the embed got there.
const CONTEXT_REQUEST_TYPE = 'bali:feedback:context-request'

// The embed asks for a picture of the host page; the reply carries the image, or the
// reason there is none.
const CAPTURE_REQUEST_TYPE = 'bali:feedback:capture-request'
const CAPTURE_RESULT_TYPE = 'bali:feedback:capture'

// Frames of the capture stream to let go by after the panel is hidden, before the
// picture is taken. See `freshFrames`.
const FRAMES_AFTER_HIDING = 3
const FRAME_TIMEOUT = 500

/**
 * Floating feedback button.
 *
 * The panel itself is a `Bali::Drawer`, so opening, closing, Escape, the focus
 * containment and the `<dialog>` in the top layer are the drawer's job and this
 * controller does not repeat any of it: it opens the drawer by name, loads the
 * embed, hands over the token and the page context, polls the unread badge, and
 * takes the screenshot the embed asks for.
 */
export class FeedbackWidgetController extends Controller {
  static targets = ['trigger', 'badge', 'iframe']
  static values = {
    drawerId: String,
    embedUrl: String,
    embedOrigin: String,
    token: String,
    badgeUrl: String,
    interval: { type: Number, default: 300000 }
  }

  connect () {
    this.checkBadge()
    this.startPolling()
    window.addEventListener('message', this.handleMessage)
  }

  disconnect () {
    this.stopPolling()
    window.removeEventListener('message', this.handleMessage)
  }

  // There is no matching `close`, and there cannot be: while the drawer is open
  // the rest of the page is inert, so the floating button is not clickable. The
  // drawer's own ✕, its overlay and Escape are the ways out.
  open () {
    // The drawer restores its markup on close, so the frame is a fresh one on
    // every open and the embed reloads instead of showing whatever it held the
    // last time it was on screen.
    //
    // NOT `{ once: true }`: the embed navigates inside the frame — a list, a report,
    // the form — and every one of those is a new document that has to be told where
    // it is all over again. The token still goes out once per opening; `handshake`
    // keeps that part to itself.
    this.pendingToken = this.hasTokenValue
    this.iframeTarget.addEventListener('load', this.handshake)
    this.iframeTarget.src = this.embedUrlValue

    this.dispatch('open', {
      prefix: 'bali:drawer',
      target: document,
      detail: { id: this.drawerIdValue, content: null, options: {} }
    })

    // Reset badge
    this.badgeTarget.classList.add('hidden')
    this.lastChecked = new Date().toISOString()
  }

  // Runs on every load of the frame. The embed is listening by then: it registers
  // for these inline, before its own document's `load` fires.
  //
  // The token goes out on the first load only — the embed trades it for a cookie and
  // the navigations after that are already authenticated. The context does not: it
  // describes the page being reported on to a document that has just replaced the one
  // that knew it.
  handshake = () => {
    if (this.pendingToken) {
      this.pendingToken = false
      this.sendToken()
    }

    this.sendContext()
  }

  sendToken = () => {
    if (!this.hasTokenValue) return

    this.postToEmbed({ type: TOKEN_MESSAGE_TYPE, token: this.tokenValue })
  }

  // Names the page being reported on, and says whether asking for a screenshot of
  // it is worth the embed's while — an embed talking to a host that cannot take one
  // should not be offering the button.
  //
  // The viewport is the host's, and has to be: the frame's own `innerWidth` is the
  // width of the panel, which describes nothing about the page in the report.
  sendContext = () => {
    this.postToEmbed({
      type: CONTEXT_MESSAGE_TYPE,
      url: window.location.href,
      title: document.title,
      viewport: { width: window.innerWidth, height: window.innerHeight },
      capture: this.captureSupported
    })
  }

  // -- Messages from the embed ---------------------------------------------------

  // Only this widget's own frame, and only from the origin the token was addressed
  // to. `event.origin` alone is not enough: any other frame on the page served from
  // that origin would then be able to make the host ask the user to share a screen.
  //
  // The context request is answered under the same two checks, for a smaller reason:
  // the reply names the page the user is on, which is not something to hand to any
  // document that asks.
  handleMessage = (event) => {
    if (!this.embedOriginValue || event.origin !== this.embedOriginValue) return
    if (!this.hasIframeTarget || event.source !== this.iframeTarget.contentWindow) return

    if (event.data?.type === CONTEXT_REQUEST_TYPE) this.sendContext()
    if (event.data?.type === CAPTURE_REQUEST_TYPE) this.capture()
  }

  // -- Screen capture -----------------------------------------------------------

  async capture () {
    if (this.capturing) return
    this.capturing = true

    try {
      this.postToEmbed({ type: CAPTURE_RESULT_TYPE, image: await this.grabHostPage() })
    } catch (error) {
      this.postToEmbed({ type: CAPTURE_RESULT_TYPE, error: captureFailure(error) })
    } finally {
      this.capturing = false
    }
  }

  async grabHostPage () {
    if (!this.captureSupported) throw new Error('unsupported')

    // The transient activation this needs comes from the click inside the frame:
    // an activation is granted to the frame's ancestors as well, whatever their
    // origin. `preferCurrentTab` is Chrome's, and narrows the picker to this tab;
    // elsewhere it is an unknown dictionary member, ignored, and the person picks
    // the tab themselves.
    const stream = await navigator.mediaDevices.getDisplayMedia({
      audio: false,
      video: true,
      preferCurrentTab: true
    })

    try {
      return await this.frameFrom(stream)
    } finally {
      // Right away, so the browser's "sharing this tab" bar is gone by the time
      // the panel comes back.
      stream.getTracks().forEach((track) => track.stop())
    }
  }

  async frameFrom (stream) {
    const video = document.createElement('video')
    video.srcObject = stream
    video.muted = true
    video.playsInline = true
    await video.play()

    this.element.dataset.capturing = 'true'

    try {
      await this.freshFrames(video)

      const canvas = document.createElement('canvas')
      canvas.width = video.videoWidth
      canvas.height = video.videoHeight
      canvas.getContext('2d').drawImage(video, 0, 0)

      return await new Promise((resolve, reject) => {
        canvas.toBlob((blob) => (blob ? resolve(blob) : reject(new Error('failed'))), 'image/png')
      })
    } finally {
      delete this.element.dataset.capturing
      video.pause()
      video.srcObject = null
    }
  }

  // Hiding the panel is not the same as it being gone from the picture. The stream
  // is a live copy of the tab and runs a frame or two behind the DOM, so the frames
  // in flight at this moment still have the panel in them; the picture has to come
  // from one composited afterwards. `requestVideoFrameCallback` is the only way to
  // know that such a frame has arrived — where it is missing, a short wait is the
  // honest approximation. The timeout is there because a tab in the background
  // stops producing frames altogether, and a promise that never settles would leave
  // the panel invisible.
  freshFrames (video) {
    if (!video.requestVideoFrameCallback) {
      return new Promise((resolve) => setTimeout(resolve, 250))
    }

    return new Promise((resolve) => {
      let remaining = FRAMES_AFTER_HIDING
      const timer = setTimeout(resolve, FRAME_TIMEOUT)

      const next = () => {
        if (--remaining > 0) return video.requestVideoFrameCallback(next)

        clearTimeout(timer)
        resolve()
      }

      video.requestVideoFrameCallback(next)
    })
  }

  get captureSupported () {
    return typeof navigator.mediaDevices?.getDisplayMedia === 'function'
  }

  // -- Private ----------------------------------------------------------------

  // Addressed to the embed's exact origin, never to `*`: a wildcard would hand
  // the token to whatever document happened to be in the frame.
  postToEmbed (message) {
    if (!this.embedOriginValue) return

    this.iframeTarget.contentWindow?.postMessage(message, this.embedOriginValue)
  }

  startPolling () {
    if (this.intervalValue > 0) {
      this.pollTimer = setInterval(() => this.checkBadge(), this.intervalValue)
    }
  }

  stopPolling () {
    if (this.pollTimer) {
      clearInterval(this.pollTimer)
      this.pollTimer = null
    }
  }

  async checkBadge () {
    try {
      const since = this.lastChecked || new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()
      const response = await fetch(`${this.badgeUrlValue}?since=${since}`)
      if (!response.ok) return

      const data = await response.json()
      if (data.unread_count > 0) {
        this.badgeTarget.textContent = data.unread_count
        this.badgeTarget.classList.remove('hidden')
      } else {
        this.badgeTarget.classList.add('hidden')
      }
    } catch (e) {
      // Silently fail - badge is non-critical
    }
  }
}

// Told apart so the embed can say something true about why there is no picture:
// a refused permission prompt is not a browser that cannot take one.
function captureFailure (error) {
  if (error?.name === 'NotAllowedError') return 'denied'
  if (error?.message === 'unsupported' || error?.name === 'NotSupportedError') return 'unsupported'

  return 'failed'
}
