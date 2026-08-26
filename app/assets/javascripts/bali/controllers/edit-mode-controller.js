import { Controller } from '@hotwired/stimulus'

// Puts a page into an edit mode and remembers it in the URL. Knows nothing about
// widgets — it toggles a class, swaps the control that enters for the one that
// leaves, marks a subtree `inert`, and announces the change.
//
// Compose them on one element:
//
//   <div data-controller="bali-widget-grid edit-mode" ...>
//
export class EditModeController extends Controller {
  static targets = ['enter', 'leave', 'inert', 'announcer']
  static classes = ['editing']
  static values = {
    editing: { type: Boolean, default: false },
    onText: String,
    offText: String
  }

  connect () {
    // Back leaves edit mode rather than the page, and a restore visit has to
    // re-enter it — so the flag lives in the URL, not only in memory.
    //
    // `restoring` because Stimulus already ran its default-value pass before
    // `connect`: this assignment fires `editingValueChanged(true, false)`, where
    // `wasEditing` is `false` rather than `undefined`, so the "initial render is
    // not a transition" guard below misses it and a page opened at `?editing=1`
    // announces on load. The class toggle and `inert` still need to happen.
    this.restoring = true
    this.editingValue = this.editingInUrl
    this.restoring = false

    this.popstate = () => { this.editingValue = this.editingInUrl }
    window.addEventListener('popstate', this.popstate)
  }

  disconnect () {
    window.removeEventListener('popstate', this.popstate)
  }

  get editingInUrl () {
    return new URLSearchParams(window.location.search).has('editing')
  }

  // The controls are real links to real URLs, so the default action is a correct
  // — just wasteful — full page load. Cancelling it turns the same navigation
  // into a class flip, and the page still works if this controller never loads.
  enter (event) {
    event?.preventDefault()
    this.push(true)
    this.editingValue = true
  }

  leave (event) {
    event?.preventDefault()
    this.push(false)
    this.editingValue = false
  }

  // Ignored while idle so it doesn't swallow Escape from a modal or a dropdown —
  // and ignored when something nested already handled it. A widget's `body` slot
  // can hold a modal or a popover with its own Escape-to-close, and those call
  // `preventDefault` without stopping propagation, so the keydown reaches this
  // window listener too. Without the `defaultPrevented` check, closing a dropdown
  // inside a card would also drop the user out of edit mode.
  keydown (event) {
    if (event.defaultPrevented) return
    if (event.key === 'Escape' && this.editingValue) this.leave()
  }

  // A turbo-stream can replace a card WHILE edit mode is on — the grid does
  // exactly that when a resize changes a card's shape — and
  // `editingValueChanged` does not fire again for the new element. Without this
  // the replacement arrives live inside a dimmed, inert grid: tabbable, and one
  // Enter away from navigating out of an arrangement in progress.
  inertTargetConnected (target) {
    target.inert = this.editingValue
  }

  editingValueChanged (editing, wasEditing) {
    this.element.classList.toggle(this.editingClass, editing)
    // Enter and leave occupy the same slot: the control you press to leave
    // should be where the one you pressed to enter was.
    if (this.hasEnterTarget) this.enterTarget.hidden = editing
    if (this.hasLeaveTarget) this.leaveTarget.hidden = !editing
    // The one piece of edit state CSS cannot express: `pointer-events-none`
    // stops the mouse and leaves every link in the tab order.
    this.inertTargets.forEach(target => { target.inert = editing })

    // A sighted user sees the page change. Without this, a screen-reader user
    // gets silence and finds the mode by stumbling into new buttons. Skipped on
    // the initial set, which is a render rather than a transition.
    if (wasEditing === undefined || this.restoring) return
    this.announce(editing ? this.onTextValue : this.offTextValue)
  }

  push (editing) {
    const url = new URL(window.location.href)
    if (editing) url.searchParams.set('editing', '1')
    else url.searchParams.delete('editing')
    window.history.pushState({}, '', url)
  }

  // Same clear-then-set as the grid controller: they share one announcer node, and
  // a live region only announces changes.
  announce (message) {
    if (!this.hasAnnouncerTarget || !message) return

    this.announcerTarget.textContent = ''
    window.requestAnimationFrame(() => {
      this.announcerTarget.textContent = message
    })
  }
}
