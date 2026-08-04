import { Controller } from '@hotwired/stimulus'
import { confirmDialog } from '../../../assets/javascripts/bali/confirm/confirm_dialog.js'

// Hardcoded instead of letting `dispatch` default to `this.identifier`, so the
// public event names stay put when a host registers this controller under a
// different identifier. DrawerController overrides it with 'bali:drawer'.
export const MODAL_EVENT_PREFIX = 'bali:modal'

// Size classes matching Modal::Component::SIZES
const SIZE_CLASSES = {
  sm: 'max-w-sm',
  md: 'max-w-md',
  lg: 'max-w-lg',
  xl: 'max-w-xl',
  full: 'max-w-full'
}

/**
 * Loads remote content into a modal window and handles form submission
 *
 * It expects the following structure:
 *
 * <section data-controller="modal">
 *   <a href="http://localhost/customers/new" data-action="modal#open">
 *    Add Customer
 *   </a>
 *   <dialog id="modal-template" class="modal" data-modal-target="template">
 *     <button data-action="modal#submit">Save</button>
 *     <button data-action="modal#close">Cancel</button>
 *   </dialog>
 * </section>
 *
 * The panel is a native `<dialog>` opened with `showModal()`. That is where the
 * top layer, the inertness of the page behind it and the browser's own focus
 * containment come from; what stays hand-written is everything the element does
 * not know about — the remote load, the skeleton, the unsaved-form prompt, and
 * the popups (flatpickr, SlimSelect) that portal themselves out of the panel and
 * have to be brought back into the top layer with it.
 *
 * Events, all dispatched on `document`:
 *   - bali:modal:open     emitted by `open()`, and listened for so a host can
 *                         open the modal without going through a trigger link.
 *                         Carries `detail.id`: when present only the overlay
 *                         whose template target has that id answers, so a page
 *                         with several modals can address one of them.
 *   - bali:modal:success  emitted after a form inside the modal (or drawer) saves
 */
export class ModalController extends Controller {
  static targets = ['template', 'background', 'wrapper', 'content', 'closeBtn']

  // confirmCloseMessage: when set, closing while the form is dirty asks for
  // confirmation first. Emitted by Drawer (default on) and Modal (opt-in).
  //
  // shared: whether this overlay answers an open event that names no overlay.
  // See `setOptionsAndOpenModal`. Subclasses inherit both.
  static values = {
    confirmCloseMessage: String,
    shared: { type: Boolean, default: true }
  }

  // Overridden by DrawerController so the two never answer each other's open event.
  get eventPrefix () {
    return MODAL_EVENT_PREFIX
  }

  // The four hooks DrawerController overrides. Everything else — opening,
  // closing, focus, the confirm-on-close guards and `submit` — is shared, so a
  // fix lands once instead of once per overlay.
  get openClass () {
    return 'modal-open'
  }

  get sizeClasses () {
    return SIZE_CLASSES
  }

  // Attribute the trigger link carries, and the matching key in the options
  // payload of the open event.
  get sizeAttribute () {
    return 'data-modal-size'
  }

  get sizeOptionKey () {
    return 'modalSize'
  }

  async connect () {
    this.setupListeners(`${this.eventPrefix}:open`)
  }

  setupListeners = eventName => {
    this._dirty = false

    // Track edits so we can warn before discarding an unsaved form. Only wired
    // when confirm-on-close is configured, so the shared body/main-level
    // controller (no value) stays inert.
    if (this.hasConfirmCloseMessageValue) {
      this.element.addEventListener('input', this._markDirty)
      this.element.addEventListener('change', this._markDirty)
    }

    if (this.hasWrapperTarget) {
      this.wrapperClasses = this.normalizeClass(
        this.wrapperTarget.getAttribute('data-wrapper-class')
      )
    }

    // Store original skeleton content for restoration on close
    if (this.hasContentTarget) {
      this._originalContent = this.contentTarget.innerHTML
    }

    if (this.hasTemplateTarget) {
      // Listen on the template (overlay) instead of the backdrop because DaisyUI 5's
      // modal-backdrop has z-index: -1 which can prevent clicks from reaching it.
      // We detect clicks outside the wrapper to close the modal.
      this.templateTarget.addEventListener('mousedown', this._onOverlayMousedown)
      this.templateTarget.addEventListener('click', this._onOverlayClick)
      this.templateTarget.addEventListener('cancel', this._onDialogCancel)

      // Capture-phase probe for the flatpickr popup guard (see _recordPopupState).
      this.element.addEventListener('keydown', this._recordPopupState, true)
    }

    if (this.hasCloseBtnTarget) {
      this.closeBtnTarget.addEventListener('click', this._closeModal)
    }

    document.addEventListener(eventName, this.setOptionsAndOpenModal)
    document.addEventListener('turbo:before-morph-element', this._keepOpenPanelThroughMorph)

    this._promoteInitiallyOpenOverlay()
  }

  // A page morph must not touch a panel that is currently open.
  //
  // Idiomorph writes every attribute the new node carries and REMOVES every one the old
  // node has that the new one does not. The markup the server sends for an open panel is a
  // CLOSED panel, so a morph strips both `open` and the open class — and stripping `open`
  // from a dialog opened with `showModal()` does not take it out of the top layer. The
  // document stays inert, the UA simply stops painting the panel, and `close()` returns
  // early on a dialog with no `open` attribute: nothing is left that can free the page. It
  // does not even throw.
  //
  // Cancelling the element (rather than `turbo:before-morph-attribute`, which is finer) is
  // what is wanted here: idiomorph stops at the element AND its subtree, and a panel the
  // user has open is live state a morph should be leaving alone anyway. The attribute event
  // would not be enough on its own — the morph also overwrites `class`, which would leave
  // the panel in the top layer without the class that shows it.
  //
  // Listens on `document`, not `this.element`: the panel and the controller element are
  // often different subtrees (the shared body-level overlay), and the event bubbles.
  _keepOpenPanelThroughMorph = event => {
    if (!this.hasTemplateTarget) return
    if (event.target !== this.templateTarget) return

    const dialog = this.templateTarget
    // The class as well as the attribute: in `_showOverlay`'s fallback, where `showModal()`
    // was unavailable, the class is the only thing holding the panel open.
    if (!dialog.open && !dialog.classList.contains(this.openClass)) return

    event.preventDefault()
  }

  // A panel rendered `active:` arrives with the open class already on it and no
  // script in the loop, so nothing has put it in the top layer. Promoting it here
  // is what makes a server-opened overlay behave like a user-opened one: same
  // inertness behind it, same Escape, same handling of the popups inside it.
  _promoteInitiallyOpenOverlay () {
    if (!this.hasTemplateTarget) return
    if (!this.templateTarget.classList.contains(this.openClass)) return

    this._showOverlay()
  }

  disconnect () {
    this.removeListeners(`${this.eventPrefix}:open`)
  }

  removeListeners = eventName => {
    if (this.hasConfirmCloseMessageValue) {
      this.element.removeEventListener('input', this._markDirty)
      this.element.removeEventListener('change', this._markDirty)
    }

    if (this.hasTemplateTarget) {
      this.templateTarget.removeEventListener('mousedown', this._onOverlayMousedown)
      this.templateTarget.removeEventListener('click', this._onOverlayClick)
      this.templateTarget.removeEventListener('cancel', this._onDialogCancel)
      this.element.removeEventListener('keydown', this._recordPopupState, true)
    }

    if (this.hasCloseBtnTarget) {
      this.closeBtnTarget.removeEventListener('click', this._closeModal)
    }

    document.removeEventListener(eventName, this.setOptionsAndOpenModal)
    document.removeEventListener('turbo:before-morph-element', this._keepOpenPanelThroughMorph)
  }

  templateTargetConnected () {
    this.templateTarget.addEventListener('mousedown', this._onOverlayMousedown)
    this.templateTarget.addEventListener('click', this._onOverlayClick)
    this.templateTarget.addEventListener('cancel', this._onDialogCancel)
  }

  templateTargetDisconnected () {
    this.templateTarget.removeEventListener('mousedown', this._onOverlayMousedown)
    this.templateTarget.removeEventListener('click', this._onOverlayClick)
    this.templateTarget.removeEventListener('cancel', this._onDialogCancel)
  }

  setOptionsAndOpenModal = event => {
    // Only process if this controller has the required targets
    // This allows multiple controllers to exist (e.g., on body and component)
    // but only the one with targets will actually open the modal
    if (!this.hasContentTarget || !this.hasTemplateTarget || !this.hasWrapperTarget) return

    // An addressed event names its overlay. Anything else is a broadcast, and a
    // broadcast is answered by every SHARED overlay on the page — which used to
    // mean every overlay, full stop, on the assumption that a page carries one.
    // The package broke that assumption itself: `Bali::FeedbackWidget` ships its
    // own drawer, so on any page with the widget an ordinary `drawer#open`
    // trigger opened two drawers. Only one of them belongs to the button that
    // then submits, so only that one is closed — and the other stays
    // `showModal()`-ed, which makes the whole document outside it inert. The
    // page looked closed and stopped answering the mouse (#854).
    const { id } = event.detail
    if (id) {
      if (id !== this.templateTarget.id) return
    } else if (!this.sharedValue) {
      return
    }

    this.setOptions(event.detail.options)
    this.openModal(event.detail.content)
  }

  openModal (content) {
    // A freshly opened modal starts clean
    this._dirty = false

    // Store the element that triggered the modal for focus restoration. Only
    // while the focus is still outside the panel: `open()` calls this twice —
    // once for the skeleton, once for the loaded content — and now that the
    // skeleton pulls the focus in, the second call would otherwise overwrite
    // the trigger with the panel itself, and closing would restore nothing.
    if (!this.templateTarget.contains(document.activeElement)) {
      this.previouslyFocusedElement = document.activeElement
    }

    if (this.wrapperClasses) {
      this.wrapperTarget.classList.add(...this.wrapperClasses)
    }

    // Apply dynamic size class if specified
    const size = this[this.sizeOptionKey]
    if (size && this.sizeClasses[size]) {
      this._applySize(size)
    }

    this._showOverlay()

    // Only replace content if provided - allows showing skeleton first
    if (content !== null && content !== undefined) {
      this.contentTarget.innerHTML = content
    }

    // Runs for the skeleton too. Until it did, focus stayed on the trigger link
    // — a sibling subtree — so for the whole length of the fetch Escape never
    // reached the panel's handler and Tab walked the page behind the overlay.
    this.trapFocus()
  }

  // The overlay element is a real `<dialog>`, and `showModal()` is the whole
  // reason: it paints the panel in the top layer, where no z-index in the
  // document can cover it, and it makes everything outside the panel inert. The
  // open class stays on for both — it is what the stylesheets, the previews and
  // every existing call site read the state from, and it is what keeps a panel
  // rendered `active:` visible in the seconds before Stimulus connects.
  //
  // Idempotent on purpose: `open()` runs this twice per remote open, once for
  // the skeleton and once for the loaded content.
  _showOverlay () {
    const dialog = this.templateTarget
    dialog.classList.add(this.openClass)

    if (typeof dialog.showModal !== 'function' || dialog.open) return

    try {
      dialog.showModal()
    } catch {
      // Not connected, or already open from another controller instance. The
      // class alone still shows the panel; it just is not in the top layer.
    }
  }

  // The rescue for a panel that already lost the attribute. `_keepOpenPanelThroughMorph`
  // only covers panels a controller can see at the moment of the morph; this covers the one
  // that is already stranded — in the top layer, unpainted, with a `close()` that returns
  // early and leaves the whole document inert with no way out.
  //
  // Giving the attribute back is enough: measured on a bare `<dialog>`, `close()` with the
  // attribute restored drops `:modal` back to false and `elementFromPoint` over the page
  // returns the page again instead of `HTML`.
  _hideOverlay () {
    const dialog = this.templateTarget
    dialog.classList.remove(this.openClass)

    if (dialog.matches(':modal') && !dialog.open) dialog.setAttribute('open', '')

    if (dialog.open) dialog.close()
  }

  // Swaps the panel's content on an already-open overlay. Deliberately does not
  // touch `_dirty` or `previouslyFocusedElement`: the overlay never closed, so
  // the unsaved-changes state and the element to restore focus to still stand.
  // Focus is re-seated because the nodes that held it were just replaced.
  _replaceContent (content) {
    this.contentTarget.innerHTML = content
    this.trapFocus()
  }

  _applySize (size) {
    const sizeClass = this.sizeClasses[size]
    if (!sizeClass || !this.hasWrapperTarget) return

    // Remove all size classes first
    Object.values(this.sizeClasses).forEach(cls => {
      this.wrapperTarget.classList.remove(cls)
    })

    // Apply the new size class
    this.wrapperTarget.classList.add(sizeClass)
    this._currentSizeClass = sizeClass
  }

  _restoreDefaultSize () {
    if (this._currentSizeClass && this.hasWrapperTarget) {
      this.wrapperTarget.classList.remove(this._currentSizeClass)
      this._currentSizeClass = null
    }
  }

  trapFocus () {
    const focusableElements = this.wrapperTarget.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )

    this.firstFocusable = focusableElements[0]
    this.lastFocusable = focusableElements[focusableElements.length - 1]

    // Idempotent: openModal runs once for the skeleton and again for the loaded
    // content, and the same listener must not stack up.
    this.wrapperTarget.removeEventListener('keydown', this.handleTabKey)
    this.wrapperTarget.addEventListener('keydown', this.handleTabKey)

    this._setInitialFocus()
  }

  // The host's `autofocus` wins. It used to lose: this ran after
  // `autoFocusInput` and ended on the first focusable, which in the shared
  // `#main-modal` is always the standalone ✕ button.
  //
  // With neither — the skeleton phase — focus goes to the panel itself, which
  // is what keeps Escape and Tab inside the overlay while the fetch is in
  // flight. `wrapperTarget` carries tabindex="-1" so it can receive it.
  _setInitialFocus () {
    const autofocusNode = this.hasContentTarget && this.contentTarget.querySelector('[autofocus]')
    const target = autofocusNode || this.firstFocusable || this.wrapperTarget

    target.focus()
  }

  handleTabKey = (event) => {
    if (event.key !== 'Tab') return

    // Skeleton, or content with nothing focusable: there is nowhere to move to,
    // so hold focus rather than let Tab escape to the page behind the overlay.
    if (!this.firstFocusable) {
      event.preventDefault()
      this.wrapperTarget.focus()
      return
    }

    if (event.shiftKey) {
      if (document.activeElement === this.firstFocusable) {
        event.preventDefault()
        this.lastFocusable.focus()
      }
    } else {
      if (document.activeElement === this.lastFocusable) {
        event.preventDefault()
        this.firstFocusable.focus()
      }
    }
  }

  setOptions (options) {
    const keys = Object.keys(options)
    keys.forEach((key, _i) => {
      this[key] = options[key]
    })
  }

  _onOverlayMousedown = (event) => {
    const insideWrapper = this.hasWrapperTarget && this.wrapperTarget.contains(event.target)
    this._mousedownOnOverlay = !insideWrapper
  }

  _onOverlayClick = (event) => {
    const insideWrapper = this.hasWrapperTarget && this.wrapperTarget.contains(event.target)

    // Close only if both mousedown AND click were outside the wrapper
    if (this._mousedownOnOverlay && !insideWrapper) {
      this._closeWithConfirmation()
    }
    this._mousedownOnOverlay = false
  }

  _markDirty = () => {
    this._dirty = true
  }

  // A `<dialog>` answers a close request on its own, and that close knows nothing
  // about the open calendar or the unsaved form. `close()` cancels the keydown for
  // every Escape it sees, so in practice this only runs for a close request that
  // never was a keydown we saw: a platform back gesture, or Escape pressed while
  // the focus sits inside an <iframe> in the panel. Route it through the same
  // guarded path rather than let the browser discard the form.
  _onDialogCancel = event => {
    event.preventDefault()
    this._closeWithConfirmation()
  }

  // flatpickr binds its Escape handler on the input itself, so it closes the
  // calendar at the target phase — before our bubble-phase `close()` could see
  // `.flatpickr-calendar.open`. Sampling here in the capture phase (which runs
  // before the target phase) records whether a popup was open so `close()` can
  // defer to it. Kept generic to the `.flatpickr-calendar.open` marker.
  _recordPopupState = event => {
    if (event.key === 'Escape') {
      this._escapeHadOpenPopup = Boolean(document.querySelector('.flatpickr-calendar.open'))
    }
  }

  // Guards the close paths a user drives (Escape, overlay, close button) so an
  // unsaved form is not silently discarded. Never call this from `submit()`: a
  // successful submit must close without prompting.
  _closeWithConfirmation = () => {
    if (this._dirty && this.hasConfirmCloseMessageValue) {
      confirmDialog(this.confirmCloseMessageValue).then(confirmed => {
        if (confirmed) this._closeModal()
      })
    } else {
      this._closeModal()
    }
  }

  _closeModal = () => {
    // Invalidates any open still waiting on its fetch. See `_openSequence`.
    this._openSequence = (this._openSequence || 0) + 1

    // Before the focus restore below: while the dialog is open everything
    // outside it is inert, and `.focus()` on an inert element does nothing.
    this._hideOverlay()

    if (this.wrapperClasses) {
      this.wrapperTarget.classList.remove(...this.wrapperClasses)
    }

    // Restore default size
    this._restoreDefaultSize()

    // Restore original skeleton content for next open
    if (this._originalContent) {
      this.contentTarget.innerHTML = this._originalContent
    } else {
      this.contentTarget.innerHTML = ''
    }

    // Clean up focus trap. `hasWrapperTarget`, not `wrapperTarget`: reading the target
    // getter to test for its own absence throws instead of answering false — the same
    // mistake as `this.fooTarget?.bar`, spelled as a condition. Every other read of this
    // target in the file (setupListeners, _applySize, _restoreDefaultSize, the two overlay
    // handlers) already asks the has* twin.
    if (this.hasWrapperTarget) {
      this.wrapperTarget.removeEventListener('keydown', this.handleTabKey)
    }

    // Restore focus to the element that triggered the modal
    if (this.previouslyFocusedElement) {
      this.previouslyFocusedElement.focus()
      this.previouslyFocusedElement = null
    }
  }

  _buildURL = (path, redirectTo = null) => {
    const url = new URL(path, window.location.origin)
    url.searchParams.set('layout', 'false')

    if (redirectTo) {
      url.searchParams.set('redirect_to', redirectTo)
    }

    return url.toString()
  }

  _extractResponseBodyAndTitle = html => {
    const element = document.createElement('html')
    element.innerHTML = html

    return {
      body: element.querySelector('body').innerHTML,
      title: element.querySelector('title').text
    }
  }

  _replaceBodyAndURL = (html, url) => {
    const { body, title } = this._extractResponseBodyAndTitle(html)

    document.body.innerHTML = body

    if (window.Turbo) {
      window.Turbo.session.history.push(new URL(url))

      // Makes the Back Button functional
      window.Turbo.session.pageBecameInteractive()
    } else {
      history.pushState({}, title, url)
    }
  }

  /**
   * Public Methods
   */
  // Shared by Modal and Drawer: the only differences are the size attribute the
  // trigger carries and the key it travels under, both of which are hooks.
  open = async (event) => {
    event.preventDefault()
    const target = event.currentTarget

    const wrapperClasses = this.normalizeClass(
      target.getAttribute('data-wrapper-class')
    )
    const redirectTo = target.getAttribute('data-redirect-to')
    const skipRender = Boolean(target.getAttribute('data-skip-render'))
    const extraProps = JSON.parse(target.getAttribute('data-extra-props'))
    const options = {
      wrapperClasses,
      redirectTo,
      skipRender,
      extraProps,
      [this.sizeOptionKey]: target.getAttribute(this.sizeAttribute)
    }

    // Lets a trigger name the overlay it opens on a page carrying several.
    // Absent — the usual case, one shared overlay — the event stays a broadcast.
    const id = target.getAttribute(this.idAttribute) || undefined

    // Now that Escape reaches the panel during the skeleton, closing became
    // possible while the fetch is still in flight — and the arriving content
    // would pop the overlay straight back open. Every close bumps this, so an
    // open whose stamp is stale drops its response on the floor. A close
    // followed by a fresh open bumps it twice, which invalidates this one too:
    // the newer open owns the panel.
    const sequence = this._openSequence = (this._openSequence || 0) + 1

    // Show the overlay immediately with skeleton (content already in template)
    this._dispatchOpen({
      id,
      content: null, // Don't replace content - show existing skeleton
      options
    })

    // Fetch actual content
    const response = await fetch(this._buildURL(target.href))
    const body = await response.text()

    if (sequence !== this._openSequence) return

    if (response.redirected) {
      this._replaceBodyAndURL(body, response.url)
      return
    }

    // Replace skeleton with actual content
    this._dispatchOpen({ id, content: body, options })
  }

  get idAttribute () {
    return 'data-modal-id'
  }

  // Targets `document` rather than the controller element: the trigger and the
  // overlay are usually different subtrees (often a body-level controller), so a
  // bubbling event from the link never reaches the one holding the targets.
  _dispatchOpen = detail => {
    this.dispatch('open', { prefix: this.eventPrefix, target: document, detail })
  }

  close = event => {
    // Ignore synthetic keydown events from browser autocomplete selections.
    // When a user selects a browser autocomplete suggestion, some browsers fire
    // a keydown event with key: undefined, which Stimulus may not filter out.
    if (event && event.type === 'keydown' && event.key !== 'Escape') return

    // Let an open flatpickr calendar (or similar popup) consume the Escape
    // first. The popup state is sampled in the capture phase (_recordPopupState)
    // because flatpickr closes its calendar at the target phase, before this
    // bubble-phase handler runs. So the first Escape closes the calendar and
    // only the next one closes the modal/drawer.
    if (event && event.type === 'keydown' && this._escapeHadOpenPopup) {
      this._escapeHadOpenPopup = false

      // The panel is a `<dialog>`, and its own Escape knows nothing about this
      // guard: leaving the keydown alone would let the browser close the whole
      // overlay in the same keystroke that flatpickr used to close its calendar,
      // which is exactly the "first Escape belongs to the calendar" rule gone.
      event.preventDefault()
      return
    }

    if (event) event.preventDefault()
    this._closeWithConfirmation()
  }

  /**
   * submit
   *
   * This action is called when a form within a modal is submitted. There
   * are 3 scenarios we need to handle:
   *
   * 1. When Form is submitted successfully, the server redirects to a new page.
   * 2. When Form has an error, the server returns the form with the errors.
   * 3. When the form has data-turbo="true" and the server responds with
   *    text/vnd.turbo-stream.html, the streams are applied to the page and
   *    the modal/drawer closes (on success), enabling partial page updates.
   *
   * On a successful redirect scenario we get a full HTML page and we then proceed
   * to extract the <body> tag from the page and replace the existing body tag.
   *
   * On a error scenario we just replace the modal contents with the response, since we
   * are already only getting the contents inside the modal.
   */
  submit = event => {
    event.preventDefault()

    const button = event.target
    this._startSubmitting(button)

    // `reportValidity()` on the FORM, not `checkValidity()` plus a hand-rolled loop.
    //
    // The `event.preventDefault()` above has already cancelled the browser's own
    // interactive validation, so nothing will be reported unless this asks for it — and
    // what used to ask walked `input` only. A `<textarea>` or a `<select>` left empty was
    // validated (`checkValidity()` fires `invalid` on every control) and then reported to
    // nobody: the submit was blocked with no request, no message, no bubble and no focus
    // anywhere. The loop was also wrong in the small: reporting control by control leaves
    // the LAST bubble on screen, not the first invalid field's, which is the one the user
    // is looking for.
    //
    // The form-level call does all of it — validates every control the browser validates,
    // focuses the first invalid one, scrolls to it and shows its message.
    //
    // Reach is wider than "inside a panel": `AppLayout` renders `<main>` with
    // `data-controller="modal drawer"` by default, so a `submit_group(..., drawer: true)`
    // on an ordinary page is captured by this controller too.
    const form = button.closest('form')
    if (!form.reportValidity()) {
      this._stopSubmitting(button)
      return
    }

    const formURL = form.getAttribute('action')
    const enableTurbo = button.dataset.turbo || form.dataset.turbo

    const url = this._buildURL(formURL, this.redirectTo)
    const options = {
      method: 'POST',
      mode: 'same-origin',
      redirect: 'follow',
      credentials: 'include',
      body: new FormData(form)
    }

    if (enableTurbo) {
      options.headers = {
        Accept: 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml'
      }
    } else {
      options.headers = {
        Accept: 'text/html, application/xhtml+xml'
      }
    }

    let redirected = false
    let redirectURL = null
    let responseOk = null
    let turboStreamResponse = false
    const redirectData = this.extraProps || {}

    fetch(url, options)
      .then(response => {
        redirected = response.redirected
        redirectURL = response.url

        const url = new URL(response.url)
        url.searchParams.forEach((value, key) => {
          redirectData[key] = value
        })

        responseOk = response.ok
        turboStreamResponse = (response.headers.get('Content-Type') || '')
          .includes('text/vnd.turbo-stream.html')
        return response.text()
      })
      .then(responseText => {
        // Always `bali:modal:success`, drawers included: the drawer inherits this
        // method, and one name for "the form inside the overlay saved" is what a
        // host wants to listen for.
        const dispatchSuccess = () => this.dispatch('success', {
          prefix: MODAL_EVENT_PREFIX,
          target: document,
          detail: redirectData
        })

        if (redirected) {
          // A successful submit is not a discard — clear dirty so the close
          // below (and any that follows) does not prompt for confirmation.
          this._dirty = false
          dispatchSuccess()

          if (this.skipRender) {
            this._closeModal()
          } else {
            this._replaceBodyAndURL(responseText, redirectURL)
          }
        } else if (turboStreamResponse && window.Turbo) {
          if (responseOk) { dispatchSuccess() }

          // Apply the streams to the page instead of injecting the raw
          // <turbo-stream> markup as inert HTML. Close only on success: an
          // error stream may re-render the form inside the modal/drawer.
          window.Turbo.renderStreamMessage(responseText)
          if (responseOk) {
            this._dirty = false
            this._closeModal()
          }
        } else {
          if (responseOk) { dispatchSuccess() }

          // Re-render in place rather than re-open. `openModal` resets the dirty
          // flag, and this is the branch a 422 lands in: going through it left
          // the form unprotected exactly when the user had the most typed into
          // it, so the next Escape discarded the failed submit without asking.
          this._replaceContent(responseText)
        }
      })
  }

  /**
   * Put the submit button into its waiting state.
   *
   * This used to be `classList.add('loading')` on the button, which reads like a
   * modifier and is not one: in daisyUI 5 `.loading` IS the spinner. It sets
   * `aspect-ratio: 1`, a width of six selector units and `background-color:
   * currentColor` masked by the spinner SVG, so on the <button> it collapsed the
   * box — measured 66x40 to 34x40 — and painted the button itself as the spinner,
   * with the label still in the box showing through the holes in the mask. That is
   * the letter that was visible under the spinner in #839.
   *
   * So the spinner goes inside as its own element and the button keeps `.btn`. The
   * width is pinned first because the label is what was holding the button open:
   * swapping "Save" for a 20px spinner without pinning resizes the actions row at
   * exactly the moment the user is waiting on it. The height needs no pinning —
   * `.btn` sets it.
   *
   * `loading loading-spinner loading-sm` is the same trio
   * `Bali::Button::Component`'s template writes, and that is deliberate: the
   * documented `@source` globs scan the package's `.erb` and `.rb`, not its `.js`,
   * so a class that only ever appears here would be missing from a host's Tailwind
   * build.
   */
  _startSubmitting (button) {
    if (button.dataset.baliSubmitting) return

    button.dataset.baliSubmitting = 'true'
    button.style.minWidth = `${button.getBoundingClientRect().width}px`
    button.setAttribute('disabled', '')
    button.setAttribute('aria-busy', 'true')

    // The label is kept rather than serialised: moving the nodes preserves whatever
    // the call site put in the button — an icon, a translated span — and gives
    // `_stopSubmitting` something exact to put back.
    const label = document.createElement('span')
    label.hidden = true
    label.dataset.baliSubmitLabel = ''
    label.append(...button.childNodes)

    const spinner = document.createElement('span')
    spinner.className = 'loading loading-spinner loading-sm'

    button.replaceChildren(label, spinner)
  }

  // Only the client-side validation path comes back here: a 422 re-renders the
  // whole panel and a redirect replaces the page, and in both cases this button is
  // gone. Guarded on the stashed label so calling it twice is harmless.
  _stopSubmitting (button) {
    const label = button.querySelector('[data-bali-submit-label]')
    if (!label) return

    button.replaceChildren(...label.childNodes)
    button.style.minWidth = ''
    button.removeAttribute('disabled')
    button.removeAttribute('aria-busy')
    delete button.dataset.baliSubmitting
  }

  normalizeClass (classes) {
    if (!classes) return []

    return classes.split(' ')
  }
}
