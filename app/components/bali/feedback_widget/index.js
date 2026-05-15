import { Controller } from '@hotwired/stimulus'

export class FeedbackWidgetController extends Controller {
  static targets = ['trigger', 'badge', 'overlay', 'panel', 'iframe']
  static values = {
    embedUrl: String,
    badgeUrl: String,
    interval: { type: Number, default: 300000 }
  }

  connect () {
    this.isOpen = false
    this.checkBadge()
    this.startPolling()
  }

  disconnect () {
    this.stopPolling()
  }

  toggle () {
    this.isOpen ? this.close() : this.open()
  }

  open () {
    this.isOpen = true

    // Load iframe on first open
    if (!this.iframeTarget.src) {
      this.iframeTarget.src = this.embedUrlValue
    }

    this.overlayTarget.classList.remove('hidden')
    this.panelTarget.classList.remove('translate-x-full')
    document.body.classList.add('overflow-hidden')

    // Reset badge
    this.badgeTarget.classList.add('hidden')
    this.lastChecked = new Date().toISOString()
  }

  close () {
    this.isOpen = false
    this.panelTarget.classList.add('translate-x-full')
    this.overlayTarget.classList.add('hidden')
    document.body.classList.remove('overflow-hidden')
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
