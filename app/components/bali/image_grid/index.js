import { Controller } from '@hotwired/stimulus'

const TRANSITION_MS = 200

/**
 * Opens an image in a fullscreen lightbox overlay when the trigger is clicked.
 *
 * Attach to the trigger (a <button> wrapping the image). The full-size source
 * comes from `data-image-expander-src-value`; if absent, falls back to the
 * inner <img>'s `src`. Closes on ESC, backdrop click, or close button.
 *
 * Usage:
 *   <button data-controller="image-expander"
 *           data-action="click->image-expander#open"
 *           data-image-expander-src-value="/path/to/full.jpg">
 *     <img src="/path/to/thumb.jpg" alt="Sunset">
 *   </button>
 */
export class ImageExpanderController extends Controller {
  static values = { src: String }

  open (event) {
    event.preventDefault()
    if (this.overlay) return

    this.previouslyFocusedElement = document.activeElement

    const innerImg = this.element.querySelector('img')
    const src = this.srcValue || innerImg?.src
    if (!src) return

    const alt = innerImg?.alt || ''
    const closeLabel = this.element.getAttribute('aria-label') || 'Close'

    this.overlay = this._buildOverlay(closeLabel)
    document.body.appendChild(this.overlay)
    document.body.style.overflow = 'hidden'

    window.requestAnimationFrame(() => this.overlay.classList.add('is-open'))

    this._loadImage(src, alt)

    this.overlay.querySelector('.bali-image-expander-close').focus()

    this._onKeydown = this._onKeydown.bind(this)
    document.addEventListener('keydown', this._onKeydown)
  }

  close () {
    if (!this.overlay) return

    document.removeEventListener('keydown', this._onKeydown)
    const overlay = this.overlay
    this.overlay = null

    overlay.classList.remove('is-open')
    const cleanup = () => {
      overlay.remove()
      document.body.style.overflow = ''
      this.previouslyFocusedElement?.focus()
      this.previouslyFocusedElement = null
    }
    overlay.addEventListener('transitionend', cleanup, { once: true })
    setTimeout(cleanup, TRANSITION_MS + 50)
  }

  disconnect () {
    if (this.overlay) {
      document.removeEventListener('keydown', this._onKeydown)
      this.overlay.remove()
      this.overlay = null
      document.body.style.overflow = ''
    }
  }

  _onKeydown (event) {
    if (event.key === 'Escape') this.close()
  }

  _loadImage (src, alt) {
    const spinner = this.overlay.querySelector('.bali-image-expander-spinner')
    const img = new window.Image()
    img.onload = () => {
      if (!this.overlay) return
      const visibleImg = document.createElement('img')
      visibleImg.src = src
      visibleImg.alt = alt
      visibleImg.className = 'bali-image-expander-image'
      visibleImg.addEventListener('click', (event) => event.stopPropagation())
      spinner.replaceWith(visibleImg)
      window.requestAnimationFrame(() => visibleImg.classList.add('is-loaded'))
    }
    img.onerror = () => {
      if (!spinner.parentNode) return
      const error = document.createElement('div')
      error.className = 'bali-image-expander-error'
      error.textContent = 'Could not load image'
      spinner.replaceWith(error)
    }
    img.src = src
  }

  _buildOverlay (closeLabel) {
    const overlay = document.createElement('div')
    overlay.className = 'bali-image-expander-overlay'
    overlay.setAttribute('role', 'dialog')
    overlay.setAttribute('aria-modal', 'true')
    overlay.addEventListener('click', (event) => {
      if (event.target === overlay) this.close()
    })

    const spinner = document.createElement('div')
    spinner.className = 'bali-image-expander-spinner'
    spinner.setAttribute('role', 'status')
    spinner.setAttribute('aria-label', 'Loading')

    const closeBtn = document.createElement('button')
    closeBtn.type = 'button'
    closeBtn.className = 'bali-image-expander-close'
    closeBtn.setAttribute('aria-label', closeLabel)
    closeBtn.textContent = '✕'
    closeBtn.addEventListener('click', () => this.close())

    overlay.appendChild(spinner)
    overlay.appendChild(closeBtn)
    return overlay
  }
}
