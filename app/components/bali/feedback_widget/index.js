import { Controller } from '@hotwired/stimulus'

// The Opina embed reads its credential from a message, not from its URL.
const TOKEN_MESSAGE_TYPE = 'bali:feedback:token'

/**
 * Floating feedback button.
 *
 * The panel itself is a `Bali::Drawer`, so opening, closing, Escape, the focus
 * containment and the `<dialog>` in the top layer are the drawer's job and this
 * controller does not repeat any of it: it opens the drawer by name, loads the
 * embed, hands over the token, and polls the unread badge.
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
  }

  disconnect () {
    this.stopPolling()
  }

  // There is no matching `close`, and there cannot be: while the drawer is open
  // the rest of the page is inert, so the floating button is not clickable. The
  // drawer's own ✕, its overlay and Escape are the ways out.
  open () {
    // The drawer restores its markup on close, so the frame is a fresh one on
    // every open and the embed reloads instead of showing whatever it held the
    // last time it was on screen.
    this.iframeTarget.addEventListener('load', this.sendToken, { once: true })
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

  // Addressed to the embed's exact origin, never to `*`: a wildcard would hand
  // the token to whatever document happened to be in the frame.
  sendToken = () => {
    if (!this.hasTokenValue || !this.embedOriginValue) return

    this.iframeTarget.contentWindow?.postMessage(
      { type: TOKEN_MESSAGE_TYPE, token: this.tokenValue },
      this.embedOriginValue
    )
  }

  // -- Private ----------------------------------------------------------------

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
