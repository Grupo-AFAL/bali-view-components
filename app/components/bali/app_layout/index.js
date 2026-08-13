import { Controller } from '@hotwired/stimulus'

const HEIGHT_PROPERTY = '--bali-banner-height'

/**
 * App Layout Controller
 *
 * Publishes the banner strip's height as `--bali-banner-height` on `<body>`, so
 * the CSS can push the pinned sidebar down by exactly as much as the banner
 * takes. Nothing else reads a height here: the offset itself is one rule in
 * ./index.css.
 *
 * MEASURED, not declared. The height cannot be a constant, because the strip is
 * whatever the host put in the slot: gc stacks an impersonation banner over a
 * content-review one (3rem + 2.5rem) and hardcodes `top: 5.5rem !important` for
 * that combination alone. It cannot be CSS either — there is no way to read an
 * element's height from a stylesheet. A ResizeObserver on the strip covers every
 * case the constants could not: two banners, one banner dismissed, a banner that
 * wraps to two lines on a phone, a font that finishes loading.
 *
 * The controller is on the layout root whether or not a banner is in the slot,
 * and the work hangs off the target callbacks rather than `connect()`. That is
 * what makes a banner arriving later — a Turbo Stream that prepends an
 * impersonation strip — measured on arrival, and a banner leaving take the
 * offset with it.
 *
 * TURBO CACHE. The property is written as an inline style on `<body>`, and an
 * inline style is part of the snapshot Turbo caches. Restoring that snapshot on a
 * page whose banner is gone would hold the sidebar down against nothing, so the
 * property is removed before the snapshot is taken; the controller reconnects on
 * the restored page and measures again from scratch.
 */
export class AppLayoutController extends Controller {
  static targets = ['banner']

  initialize () {
    this.observer = new window.ResizeObserver(() => this.measure())
  }

  connect () {
    document.addEventListener('turbo:before-cache', this.handleBeforeCache)
  }

  disconnect () {
    document.removeEventListener('turbo:before-cache', this.handleBeforeCache)
    this.observer.disconnect()
    this.clear()
  }

  bannerTargetConnected (banner) {
    this.observer.observe(banner)
    this.measure()
  }

  bannerTargetDisconnected (banner) {
    this.observer.unobserve(banner)
    this.measure()
  }

  /**
   * `getBoundingClientRect` and not `offsetHeight`: the latter rounds to whole
   * pixels, and half a pixel of rounding is a hairline of page showing through
   * between the banner and the sidebar.
   */
  measure () {
    if (!this.hasBannerTarget) return this.clear()

    const height = this.bannerTarget.getBoundingClientRect().height

    this.element.style.setProperty(HEIGHT_PROPERTY, `${height}px`)
  }

  clear () {
    this.element.style.removeProperty(HEIGHT_PROPERTY)
  }

  handleBeforeCache = () => this.clear()
}
