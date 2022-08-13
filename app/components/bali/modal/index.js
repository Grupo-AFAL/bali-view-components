import { Controller } from '@hotwired/stimulus'
import { autoFocusInput } from '../../../javascript/bali/utils/form'

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
    if (this.hasWrapperTarget) {
      this.wrapperClass = this.wrapperTarget.getAttribute('data-wrapper-class')
    }

    if (this.hasBackgroundTarget) {
      this.backgroundTarget.addEventListener('click', this._closeModal)
    }

    if (this.hasCloseBtnTarget) {
      this.closeBtnTarget.addEventListener('click', this._closeModal)
    }

    document.addEventListener('openModal', e => {
      this.setOptions(e.detail.options)
      this.openModal(e.detail.content)
    })
  }

  disconnect () {
    if (this.hasBackgroundTarget) {
      this.backgroundTarget.removeEventListener('click', this._closeModal)
    }

    if (this.hasCloseBtnTarget) {
      this.closeBtnTarget.removeEventListener('click', this._closeModal)
    }
  }

  templateTargetConnected () {
    if (!this.hasBackgroundTarget) return

    this.backgroundTarget.addEventListener('click', this._closeModal)
  }

  templateTargetDisconnected () {
    if (!this.hasBackgroundTarget) return

    this.backgroundTarget.removeEventListener('click', this._closeModal)
  }

  openModal (content) {
    this.wrapperTarget.classList.add(this.wrapperClass)

    this.templateTarget.classList.add('is-active')
    this.contentTarget.innerHTML = content

    autoFocusInput(this.contentTarget)
  }

  setOptions (options) {
    const keys = Object.keys(options)
    keys.forEach((key, _i) => {
      this[key] = options[key]
    })
  }

  _closeModal = () => {
    this.templateTarget.classList.remove('is-active')
    if (this.wrapperClass) {
      this.wrapperTarget.classList.remove(this.wrapperClass)
    }
    this.contentTarget.innerHTML = ''
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
    history.pushState({}, title, url)
  }

  /**
   * Public Methods
   */
  open = event => {
    event.preventDefault()
    const target = event.currentTarget

    this.wrapperClass = target.getAttribute('data-wrapper-class')
    this.redirectTo = target.getAttribute('data-redirect-to')
    this.skipRender = Boolean(target.getAttribute('data-skip-render'))
    this.extraProps = JSON.parse(target.getAttribute('data-extra-props'))

    fetch(this._buildURL(target.href))
      .then(response => response.text())
      .then(body => this.openModal(body))
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
    event.target.classList.add('is-loading')
    event.target.setAttribute('disabled', '')

    const form = event.target.closest('form')
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
    const redirectData = this.extraProps || {}

    fetch(url, options)
      .then(response => {
        redirected = response.redirected
        redirectURL = response.url

        const url = new URL(response.url)
        url.searchParams.forEach((value, key) => {
          redirectData[key] = value
        })

        return response.text()
      })
      .then(responseText => {
        if (redirected) {
          const event = new CustomEvent('modal:success', {
            detail: redirectData
          })
          document.dispatchEvent(event)

          if (this.skipRender) {
            this._closeModal()
          } else {
            this._replaceBodyAndURL(responseText, redirectURL)
          }
        } else {
          this.openModal(responseText)
        }
      })
  }
}
