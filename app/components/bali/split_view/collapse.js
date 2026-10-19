import { Controller } from '@hotwired/stimulus'

// `Bali::SplitView` with `collapsible: true`: the master takes the whole
// width until a detail arrives, then shrinks while the detail slides in; Close
// (or Esc) gives the master the width back and empties the detail.
//
// What opens it is the detail itself: a Turbo Frame load, or anything an app
// puts into the frame (the frame's children are watched), so a row click, a
// `<template>` cloned by the app and a server-rendered deep link all open it
// the same way. Emptied, it closes.
//
// A frame fetch opens it at once, with the loading state (`data-split-load`
// on the pane: "loading", then "error" with «Retry» if it fails). Closing it
// while it loads cancels the fetch: Turbo aborts it when `src` goes.
//
// The look lives in index.css, keyed on `data-split-state`; this only moves
// the state, the focus and the `inert` of the pane that is out of view.
// Events, on the container: `split-view:open` and `split-view:close`.
const MOTION_MS = 300
const FOCUSABLE = 'a[href], button:not([disabled]), input, select, textarea, [tabindex]:not([tabindex="-1"])'

export class SplitViewCollapseController extends Controller {
  static targets = ['pane', 'frame', 'loading', 'error']

  connect () {
    this.opener = null
    this.onKey = (event) => {
      if (event.key !== 'Escape' || event.defaultPrevented || !this.isOpen) return
      // An open dialog or menu owns its own Escape.
      if (event.target.closest && event.target.closest('dialog[open], [role="dialog"], [role="menu"]')) return
      this.close()
    }
    document.addEventListener('keydown', this.onKey)
    // What a click opened the detail from: the focusable element around the
    // pointer (a row, a diagram node), which a click does not always focus.
    this.onPointer = (event) => {
      if (this.paneTarget.contains(event.target)) return
      this.lastPointed = event.target.closest(FOCUSABLE)
    }
    this.element.addEventListener('pointerdown', this.onPointer, true)
    this.observer = new window.MutationObserver(() => this.sync())
    this.observer.observe(this.frameTarget, { childList: true })
    // Turbo dispatches these on the frame itself (a nested frame's bubble up:
    // only this frame's own count).
    this.frameEvents = {
      'turbo:before-fetch-request': (event) => this.fetchStarted(event),
      'turbo:before-fetch-response': (event) => this.fetchAnswered(event),
      'turbo:frame-load': (event) => this.fetchEnded(event),
      'turbo:fetch-request-error': (event) => this.fetchFailed(event),
      'turbo:frame-missing': (event) => this.fetchFailed(event)
    }
    for (const [name, handler] of Object.entries(this.frameEvents)) this.frameTarget.addEventListener(name, handler)
    this.apply(this.hasDetail, { initial: true })
  }

  disconnect () {
    document.removeEventListener('keydown', this.onKey)
    this.element.removeEventListener('pointerdown', this.onPointer, true)
    for (const [name, handler] of Object.entries(this.frameEvents)) this.frameTarget.removeEventListener(name, handler)
    this.observer.disconnect()
    clearTimeout(this.timer)
  }

  // --- The frame's fetch ---

  ownEvent (event) { return event.target === this.frameTarget }

  fetchStarted (event) {
    if (!this.ownEvent(event)) return
    this.url = event.detail?.url?.href || this.frameTarget.src
    this.setLoad('loading')
    if (!this.isOpen) {
      this.loadOpened = true
      this.apply(true)
    }
  }

  fetchEnded (event) {
    if (!this.ownEvent(event)) return
    this.setLoad(null)
    // Opened empty by the fetch: the focus waited in the pane for the detail.
    if (this.loadOpened && this.isOpen && (this.paneTarget.contains(document.activeElement) || document.activeElement === document.body)) {
      this.focusDetail()
    }
    this.loadOpened = false
  }

  // Turbo renders nothing from a response that is not HTML (a bare 500, JSON)
  // and says nothing either: no frame-load follows.
  fetchAnswered (event) {
    if (!this.ownEvent(event)) return
    const response = event.detail?.fetchResponse
    if (response && !response.isHTML) this.fetchFailed(event)
  }

  // A network error, a response that is not HTML, or one without this frame
  // (an error page).
  fetchFailed (event) {
    if (!this.ownEvent(event)) return
    // The error state says it; Turbo's own would write «Content missing» into the frame and throw.
    if (event.type === 'turbo:frame-missing') event.preventDefault()
    if (!this.isOpen) {
      this.setLoad(null)
      return
    }
    this.setLoad('error')
    this.loadOpened = false
  }

  retry () {
    const frame = this.frameTarget
    if (frame.src && typeof frame.reload === 'function') frame.reload()
    else if (this.url) frame.src = this.url
  }

  setLoad (state) {
    if (state) this.paneTarget.dataset.splitLoad = state
    else delete this.paneTarget.dataset.splitLoad
    this.paneTarget.setAttribute('aria-busy', String(state === 'loading'))
    if (this.hasLoadingTarget) this.loadingTarget.hidden = state !== 'loading'
    if (this.hasErrorTarget) this.errorTarget.hidden = state !== 'error'
  }

  get loadState () { return this.paneTarget.dataset.splitLoad || null }

  get isOpen () { return this.element.dataset.splitState === 'open' }

  // Something to show: an element in the frame other than the empty state.
  get hasDetail () {
    return [...this.frameTarget.children].some((child) => !child.matches('[data-split-view-empty]'))
  }

  sync () {
    // Opened by a fetch, the pane is empty until the response lands.
    if (!this.hasDetail && this.loadState) return
    if (this.hasDetail !== this.isOpen) this.apply(this.hasDetail)
  }

  close () {
    if (!this.isOpen) return
    this.setLoad(null)
    this.loadOpened = false
    this.apply(false)
    // A closed frame points nowhere, at once. Without `src`, Turbo aborts a
    // fetch in flight, so a late response cannot open the pane again; a `src`
    // left behind is reloaded when Turbo restores the page, which would open the pane again, and a
    // click on the same row while it slides out set that same `src` again,
    // which Turbo does not load. The stash is what split-view's traversal
    // reads as «the pane shows this» (index.js).
    this.frameTarget.removeAttribute('src')
    this.frameTarget.removeAttribute('data-split-view-src')
    // The detail is emptied once it has slid out, so it does not vanish
    // mid-animation; the frame keeps its empty state, if it had one.
    clearTimeout(this.timer)
    this.timer = setTimeout(() => {
      if (this.isOpen) return
      const empty = this.frameTarget.querySelector(':scope > [data-split-view-empty]')
      this.frameTarget.replaceChildren(...(empty ? [empty] : []))
    }, this.reducedMotion ? 0 : MOTION_MS)
  }

  apply (open, { initial = false } = {}) {
    if (!initial) this.hold(open ? this.openWidth() : this.frameTarget.offsetWidth)
    this.element.dataset.splitState = open ? 'open' : 'closed'
    this.paneTarget.inert = !open
    this.paneTarget.setAttribute('aria-hidden', String(!open))
    if (initial) return
    if (open) {
      this.opener = this.lastPointed || document.activeElement
      this.lastPointed = null
      // After the slide, so the browser does not scroll a moving pane.
      setTimeout(() => this.focusDetail(), this.reducedMotion ? 0 : MOTION_MS)
    } else if (this.opener && this.opener.isConnected && !this.paneTarget.contains(this.opener)) {
      this.opener.focus({ preventScroll: true })
    }
    this.dispatch(open ? 'open' : 'close', { prefix: 'split-view' })
  }

  // While its column opens or closes, the detail is laid out at the width it
  // has open, and the pane clips it (`data-split-moving`, index.css): what is
  // inside lays out once, at its real size. Squeezed with the column instead,
  // a diagram fitted itself to a sliver and jumped to its real zoom at the end
  // (and, closing, React Flow warned about a 0-wide parent, its error 004).
  hold (width) {
    clearTimeout(this.holdTimer)
    this.frameTarget.style.minWidth = width ? `${width}px` : ''
    this.element.dataset.splitMoving = ''
    this.holdTimer = setTimeout(() => {
      this.frameTarget.style.minWidth = ''
      delete this.element.dataset.splitMoving
    }, this.reducedMotion ? 0 : MOTION_MS)
  }

  // The frame's width once open, measured in the open layout with the
  // transitions off, before the closed one is put back to animate from.
  openWidth () {
    const moving = [this.element, this.paneTarget]
    moving.forEach((element) => { element.style.transition = 'none' })
    this.frameTarget.style.minWidth = ''
    this.element.dataset.splitState = 'open'
    const width = this.frameTarget.getBoundingClientRect().width
    this.element.dataset.splitState = 'closed'
    this.element.getBoundingClientRect() // commits the closed layout the transition starts from
    moving.forEach((element) => { element.style.transition = '' })
    return width
  }

  // The detail's heading, else its first focusable element, else the pane.
  focusDetail () {
    if (!this.isOpen) return
    const target = this.frameTarget.querySelector('h1, h2, h3, [data-split-view-focus]') ||
      this.frameTarget.querySelector(FOCUSABLE) ||
      this.paneTarget
    if (!target.hasAttribute('tabindex') && !target.matches('a[href], button, input, select, textarea')) target.setAttribute('tabindex', '-1')
    target.focus({ preventScroll: true })
  }

  get reducedMotion () {
    return window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches
  }
}
