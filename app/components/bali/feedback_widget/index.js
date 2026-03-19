import { Controller } from '@hotwired/stimulus'

export class FeedbackWidgetController extends Controller {
  static targets = ['trigger', 'badge', 'overlay', 'panel', 'iframe']
  static values = {
    embedUrl: String,
    badgeUrl: String,
    interval: { type: Number, default: 300000 }
  }

  connect () {
    this.open = false
    this._checkBadge()
    this._startPolling()
  }

  disconnect () {
    this._stopPolling()
  }

  toggle () {
    this.open ? this.close() : this._open()
  }

  close () {
    this.open = false
    this.panelTarget.classList.add('translate-x-full')
    this.overlayTarget.classList.add('hidden')
    document.body.classList.remove('overflow-hidden')
  }

  _open () {
    this.open = true

    // Load iframe on first open
    if (!this.iframeTarget.src) {
      this.iframeTarget.src = this.embedUrlValue
    }

    this.overlayTarget.classList.remove('hidden')
    this.panelTarget.classList.remove('translate-x-full')
    document.body.classList.add('overflow-hidden')

    // Reset badge
    this.badgeTarget.classList.add('hidden')
    this._lastChecked = new Date().toISOString()
  }

  _startPolling () {
    if (this.intervalValue > 0) {
      this._pollTimer = setInterval(() => this._checkBadge(), this.intervalValue)
    }
  }

  _stopPolling () {
    if (this._pollTimer) {
      clearInterval(this._pollTimer)
      this._pollTimer = null
    }
  }

  async _checkBadge () {
    try {
      const since = this._lastChecked || new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()
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
