import { Controller } from '@hotwired/stimulus'
import { autoFocusInput } from 'bali/utils/form'

/**
 * Loads remote content into a modal window and handles form submission
 *
 * It expects the following structure:
 *
 * <section data-controller="modal">
 *   <a href="http://localhost/customers/new" data-action="modal#open">
 *    Add Customer
 *   </a>
 *   <div id="modal-template" class="modal">
 *     <button data-action="modal#submit">Save</button>
 *     <a data-action="modal#close">Cancel</a>
 *   </div>
 * </section>
 */
export class ModalController extends Controller {
  static targets = ['template', 'background', 'wrapper', 'content', 'closeBtn']

  async connect () {
    this.setupListeners('openModal')
  }

  setupListeners = eventName => {
    if (this.hasWrapperTarget) {
      this.wrapperClasses = this.normalizeClass(
        this.wrapperTarget.getAttribute('data-wrapper-class')
      )
    }

    // Store original skeleton content for restoration on close
    if (this.hasContentTarget) {
      this._originalContent = this.contentTarget.innerHTML
    }

    if (this.hasBackgroundTarget) {
      this.backgroundTarget.addEventListener('click', this._closeModal)
    }

    if (this.hasCloseBtnTarget) {
      this.closeBtnTarget.addEventListener('click', this._closeModal)
    }

    document.addEventListener(eventName, this.setOptionsAndOpenModal)
  }

  disconnect () {
    this.removeListeners('openModal')
  }

  removeListeners = eventName => {
    if (this.hasBackgroundTarget) {
      this.backgroundTarget.removeEventListener('click', this._closeModal)
    }

    if (this.hasCloseBtnTarget) {
      this.closeBtnTarget.removeEventListener('click', this._closeModal)
    }

    document.removeEventListener(eventName, this.setOptionsAndOpenModal)
  }

  templateTargetConnected () {
    if (!this.hasBackgroundTarget) return

    this.backgroundTarget.addEventListener('click', this._closeModal)
  }

  templateTargetDisconnected () {
    if (!this.hasBackgroundTarget) return

    this.backgroundTarget.removeEventListener('click', this._closeModal)
  }

  setOptionsAndOpenModal = event => {
    // Only process if this controller has the required targets
    // This allows multiple controllers to exist (e.g., on body and component)
    // but only the one with targets will actually open the modal
    if (!this.hasContentTarget || !this.hasTemplateTarget || !this.hasWrapperTarget) return

    this.setOptions(event.detail.options)
    this.openModal(event.detail.content)
  }

  openModal (content) {
    // Store the element that triggered the modal for focus restoration
    this.previouslyFocusedElement = document.activeElement

    if (this.wrapperClasses) {
      this.wrapperTarget.classList.add(...this.wrapperClasses)
    }

    this.templateTarget.classList.add('modal-open')

    // Only replace content if provided - allows showing skeleton first
    if (content !== null && content !== undefined) {
      this.contentTarget.innerHTML = content
      autoFocusInput(this.contentTarget)
      // Set up focus trap after content is loaded
      this.trapFocus()
    }
  }

  trapFocus () {
    const focusableElements = this.wrapperTarget.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )
    if (focusableElements.length === 0) return

    this.firstFocusable = focusableElements[0]
    this.lastFocusable = focusableElements[focusableElements.length - 1]

    // Focus first element
    this.firstFocusable.focus()

    this.wrapperTarget.addEventListener('keydown', this.handleTabKey)
  }

  handleTabKey = (event) => {
    if (event.key !== 'Tab') return

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

  _closeModal = () => {
    this.templateTarget.classList.remove('modal-open')
    if (this.wrapperClasses) {
      this.wrapperTarget.classList.remove(...this.wrapperClasses)
    }

    // Restore original skeleton content for next open
    if (this._originalContent) {
      this.contentTarget.innerHTML = this._originalContent
    } else {
      this.contentTarget.innerHTML = ''
    }

    // Clean up focus trap
    if (this.wrapperTarget) {
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
  open = async (event) => {
    event.preventDefault()
    const target = event.currentTarget

    const wrapperClasses = this.normalizeClass(
      target.getAttribute('data-wrapper-class')
    )
    const redirectTo = target.getAttribute('data-redirect-to')
    const skipRender = Boolean(target.getAttribute('data-skip-render'))
    const extraProps = JSON.parse(target.getAttribute('data-extra-props'))

    // Show modal immediately with skeleton (content already in template)
    document.dispatchEvent(new CustomEvent('openModal', {
      detail: {
        content: null, // Don't replace content - show existing skeleton
        options: { wrapperClasses, redirectTo, skipRender, extraProps }
      }
    }))

    // Fetch actual content
    const response = await fetch(this._buildURL(target.href))
    const body = await response.text()

    if (response.redirected) {
      this._replaceBodyAndURL(body, response.url)
      return
    }

    // Replace skeleton with actual content
    document.dispatchEvent(new CustomEvent('openModal', {
      detail: {
        content: body,
        options: { wrapperClasses, redirectTo, skipRender, extraProps }
      }
    }))
  }

  close = event => {
    event.preventDefault()
    this._closeModal()
  }

  /**
   * submit
   *
   * This action is called when a form within a modal is submitted. There
   * are 2 scenarios we need to handle:
   *
   * 1. When Form is submitted successfully, the server redirects to a new page.
   * 2. When Form has an error, the server returns the form with the errors.
   *
   * On a successful scenario we get a full HTML page and we then proceed to extract
   * the <body> tag from the page and replace the existing body tag.
   *
   * On a error scenario we just replace the modal contents with the response, since we
   * are already only getting the contents inside the modal.
   */
  submit = event => {
    event.preventDefault()
    event.target.classList.add('loading')
    event.target.setAttribute('disabled', '')

    const form = event.target.closest('form')
    if (!form.checkValidity()) {
      event.target.classList.remove('loading')
      event.target.removeAttribute('disabled')
      form.querySelectorAll('input').forEach(input => { input.reportValidity() })
      return
    }

    const formURL = form.getAttribute('action')
    const enableTurbo = event.target.dataset.turbo || form.dataset.turbo

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
        return response.text()
      })
      .then(responseText => {
        const event = new CustomEvent('modal:success', { detail: redirectData })

        if (redirected) {
          document.dispatchEvent(event)

          if (this.skipRender) {
            this._closeModal()
          } else {
            this._replaceBodyAndURL(responseText, redirectURL)
          }
        } else {
          if (responseOk) { document.dispatchEvent(event) }

          this.openModal(responseText)
        }
      })
  }

  normalizeClass (classes) {
    if (!classes) return []

    return classes.split(' ')
  }
}
