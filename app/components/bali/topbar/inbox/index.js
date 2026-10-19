import { Controller } from '@hotwired/stimulus'
import zIndexFor from '../../../../assets/javascripts/bali/utils/z-index.js'
import { topLayerHost } from '../../../../assets/javascripts/bali/utils/top-layer.js'
import { optionalPeer } from '../../../../assets/javascripts/bali/utils/optional-peer.js'

const FOCUSABLE = 'a[href], button:not([disabled]), input:not([disabled]), select, textarea, [tabindex]:not([tabindex="-1"])'

// Bali::Topbar::Inbox (#1512). The trigger is a link to the full page: a plain click opens the
// popover instead, and a modified click, or a page without this controller, still navigates.
// The popover's frame has no `src` until the first open, so a page that never opens it never
// requests it.
export class TopbarInboxController extends Controller {
  static targets = ['trigger', 'panel', 'frame', 'badge', 'signal']
  static values = { popoverUrl: String, badgeUrl: String }

  // Target callbacks fire for the targets already on the page BEFORE `connect`, so the signal the
  // server rendered never counts as a new notice.
  connect () {
    this.panel = this.panelTarget
    this.frame = this.frameTarget
    this.ready = true
  }

  // destroy() leaves the panel inside the popper it is about to throw away; a Turbo render that
  // reconnects this controller would come back without one.
  disconnect () {
    this.stopListening()
    if (this.tippy) {
      this.tippy.destroy()
      this.tippy = null
    }
    if (!this.element.contains(this.panel)) {
      this.panel.hidden = true
      this.element.appendChild(this.panel)
    }
    this.ready = false
  }

  toggle (event) {
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button > 0) return

    event.preventDefault()
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  async open () {
    const tippy = await this.ensureTippy()
    if (!tippy) {
      window.location.assign(this.triggerTarget.href)
      return
    }

    this.load()
    tippy.show()
  }

  close ({ returnFocus = true } = {}) {
    if (!this.isOpen) return

    this.tippy.hide()
    if (returnFocus) this.triggerTarget.focus()
  }

  get isOpen () {
    return this.triggerTarget.getAttribute('aria-expanded') === 'true'
  }

  load () {
    if (this.frame.getAttribute('src')) {
      this.frame.reload()
    } else {
      this.frame.src = this.popoverUrlValue
    }
  }

  // A new notice arrived on the stream: Bali::Inbox::Badge.refresh broadcast a fresh element in
  // place of Bali::Topbar::Inbox::Component::SIGNAL_ID, carrying no count, and the icon asks for
  // its own — the badge frame, BADGE_FRAME_ID, which the `badge` action answers.
  signalTargetConnected () {
    if (!this.ready || !this.hasBadgeTarget || !this.badgeUrlValue) return

    if (this.badgeTarget.getAttribute('src') === this.badgeUrlValue) {
      this.badgeTarget.reload()
    } else {
      this.badgeTarget.src = this.badgeUrlValue
    }
  }

  async ensureTippy () {
    if (this.tippy) return this.tippy

    const tippyModule = await import('tippy.js').catch(optionalPeer('tippy.js'))
    if (!tippyModule || !this.element.isConnected) return null
    if (this.tippy) return this.tippy

    const { default: tippy } = tippyModule
    this.panel.hidden = false
    // `manual` and `hideOnClick: false`: tippy only positions the panel. Opening and closing go
    // through `open()` and `close()`, which own `aria-expanded` and the focus.
    this.tippy = tippy(this.triggerTarget, {
      content: this.panel,
      appendTo: (reference) => topLayerHost(reference) ?? document.body,
      trigger: 'manual',
      hideOnClick: false,
      interactive: true,
      arrow: false,
      offset: [0, 8],
      placement: 'bottom-end',
      maxWidth: 'none',
      zIndex: zIndexFor('dropdown'),
      role: 'presentation',
      aria: { content: null, expanded: false },
      onShow: this.onShow,
      onMount: this.onMount,
      onHide: this.onHide
    })
    return this.tippy
  }

  onShow = () => {
    this.triggerTarget.setAttribute('aria-expanded', 'true')
    document.addEventListener('click', this.handleOutsideClick, true)
    document.addEventListener('keydown', this.handleKeydown)
  }

  // `onMount` and not `onShown`: tippy runs `onShown` on the box's transitionend, and this panel
  // has no transition, so it never ran.
  onMount = () => {
    this.panel.focus({ preventScroll: true })
  }

  onHide = () => {
    this.triggerTarget.setAttribute('aria-expanded', 'false')
    this.stopListening()
  }

  stopListening () {
    document.removeEventListener('click', this.handleOutsideClick, true)
    document.removeEventListener('keydown', this.handleKeydown)
  }

  handleOutsideClick = (event) => {
    if (this.triggerTarget.contains(event.target) || this.panel.contains(event.target)) return

    this.close({ returnFocus: false })
  }

  // The panel hangs at the end of <body>, far from the trigger: Tab past its last control, or
  // Shift+Tab before its first, would carry on from there. Both close it and land back on the
  // trigger instead.
  handleKeydown = (event) => {
    if (event.key === 'Escape') {
      event.preventDefault()
      this.close()
      return
    }
    if (event.key !== 'Tab' || !this.panel.contains(document.activeElement)) return

    const focusable = [...this.panel.querySelectorAll(FOCUSABLE)].filter((node) => node.offsetParent !== null)
    const leavingForward = !event.shiftKey && document.activeElement === focusable.at(-1)
    const leavingBack = event.shiftKey && [this.panel, focusable[0]].includes(document.activeElement)
    if (leavingForward || leavingBack) {
      event.preventDefault()
      this.close()
    }
  }
}
