import { Controller } from '@hotwired/stimulus'
import zIndexFor from '../../../../assets/javascripts/bali/utils/z-index.js'
import { topLayerHost } from '../../../../assets/javascripts/bali/utils/top-layer.js'
import { optionalPeer } from '../../../../assets/javascripts/bali/utils/optional-peer.js'

const FOCUSABLE = 'a[href], button:not([disabled]), input:not([disabled]), select, textarea, [tabindex]:not([tabindex="-1"])'

// The inbox elements of a <body> Turbo is about to render in place of one whose panel was opened
// while that visit loaded. A set and not a data attribute: a morph render copies attributes onto
// the live element, whose controller never reconnects to clear it.
const reopenAfterVisit = new WeakSet()

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
    // On the visit's `turbo:load`, once Turbo has cleared `aria-busy`: this render may be the cached
    // preview the response replaces, and a panel opened now would count as opened during the visit.
    if (reopenAfterVisit.delete(this.element)) {
      this.openedDuringVisit = true
      document.addEventListener('turbo:load', this.reopen, { once: true })
    }
    document.addEventListener('turbo:before-render', this.carryOpenPanel)
    this.ready = true
  }

  // destroy() leaves the panel inside the popper it is about to throw away; a Turbo render that
  // reconnects this controller would come back without one.
  disconnect () {
    document.removeEventListener('turbo:before-render', this.carryOpenPanel)
    document.removeEventListener('turbo:load', this.reopen)
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
    // Turbo's mark of a visit in progress.
    this.openedDuringVisit = document.documentElement.hasAttribute('aria-busy')
    const tippy = await this.ensureTippy()
    // A render replaced the page while tippy.js loaded; the link is only for a missing tippy.js.
    if (!this.element.isConnected) return
    if (!tippy) {
      window.location.assign(this.triggerTarget.href)
      return
    }

    this.load()
    tippy.show()
  }

  close ({ returnFocus = true } = {}) {
    this.openedDuringVisit = false
    if (!this.isOpen) return

    this.tippy.hide()
    if (returnFocus) this.triggerTarget.focus()
  }

  // The open panel hangs off the <body> the visit replaces. Only a panel opened while the visit
  // loaded goes on to the next page: following a link from an open panel lands with it closed.
  carryOpenPanel = ({ detail: { newBody } }) => {
    const element = this.openedDuringVisit && newBody.querySelector(`[data-controller~="${this.identifier}"]`)
    if (element) reopenAfterVisit.add(element)
  }

  reopen = () => this.open()

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
    document.addEventListener('turbo:before-stream-render', this.keepFocusInside)
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
    document.removeEventListener('turbo:before-stream-render', this.keepFocusInside)
  }

  // Marking every notice read answers with a stream that redraws the frame, the focused button
  // included, and the focus would fall to <body>, outside the dialog. Turbo's own hook for wrapping
  // a stream's render.
  keepFocusInside = (event) => {
    if (event.target.getAttribute('target') !== this.frame.id) return

    const render = event.detail.render
    event.detail.render = async (stream) => {
      await render(stream)
      this.panel.focus({ preventScroll: true })
    }
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
