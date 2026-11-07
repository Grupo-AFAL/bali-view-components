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
    // Not in connect(): Turbo clears `aria-busy` only just before `turbo:load`, so an open() here
    // would count as opened during the visit and follow a row's link to the next page.
    if (reopenAfterVisit.delete(this.element)) {
      this.openedDuringVisit = true
      document.addEventListener('turbo:load', this.reopen, { once: true })
    }
    document.addEventListener('turbo:before-render', this.carryOpenPanel)
    document.addEventListener('turbo:visit', this.forgetOpenedDuringVisit)
    document.addEventListener('turbo:morph', this.forgetMorphedPopper)
    // On the frame and not as a data-action: tippy moves the panel into its popper, outside this
    // element, where Stimulus no longer routes the frame's events.
    this.frame.addEventListener('turbo:frame-missing', this.revisitPage)
    this.ready = true
  }

  // destroy() leaves the panel inside the popper it is about to throw away; a Turbo render that
  // reconnects this controller would come back without one.
  disconnect () {
    document.removeEventListener('turbo:before-render', this.carryOpenPanel)
    document.removeEventListener('turbo:load', this.reopen)
    document.removeEventListener('turbo:visit', this.forgetOpenedDuringVisit)
    document.removeEventListener('turbo:morph', this.forgetMorphedPopper)
    this.frame.removeEventListener('turbo:frame-missing', this.revisitPage)
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

  // A new visit ends the one the panel was opened during, whether it cancels it (a row's link,
  // clicked inside the panel, never goes through `close()`) or follows its redirect.
  forgetOpenedDuringVisit = () => {
    this.openedDuringVisit = false
  }

  // A morphing refresh (a stream `refresh`, or the revisit below on a page that refreshes by
  // morphing) keeps this element but drops tippy's popper from <body> and draws the panel afresh
  // inside the element: tippy would still count itself shown, and the icon would never open again.
  forgetMorphedPopper = () => {
    if (!this.tippy || this.tippy.popper.isConnected) return

    this.stopListening()
    this.tippy.destroy()
    this.tippy = null
    this.frame.removeEventListener('turbo:frame-missing', this.revisitPage)
    this.panel = this.panelTarget
    this.frame = this.frameTarget
    this.frame.addEventListener('turbo:frame-missing', this.revisitPage)
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

  // The badge frame (component.html.erb) routes `turbo:frame-missing` here. Any answer without the
  // frame, the sign-in page once the session expired or a 5xx page, keeps the count it had. Not
  // `event.detail.visit(response)`: the refresh comes from the stream, nobody asked to leave.
  keepBadge (event) {
    event.preventDefault()
  }

  // The popover frame's `turbo:frame-missing`: the person opened the panel and got another page.
  // Left alone, Turbo writes "Content missing" into the panel and throws. A redirect is taken to be an
  // auth gate turning them away (the session expired): the page they are on is visited again, not the answer,
  // because the gate remembers the path it turned away to return there after signing in, and the
  // popover's is a fragment with no layout. `replace` makes it Turbo's own refresh of the page, so
  // no cached copy is painted first. Any other answer, an error page, is shown as it came, at its own
  // URL.
  revisitPage = (event) => {
    const { response, visit } = event.detail
    event.preventDefault()
    if (response.redirected) {
      visit(window.location.href, { action: 'replace' })
    } else {
      visit(response)
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
