import { ModalController } from 'bali/modal'
import { autoFocusInput } from 'bali/utils/form'

export class DrawerController extends ModalController {
  async connect () {
    this.setupListeners('openDrawer')

    // Store original skeleton content for restoration on close
    if (this.hasContentTarget) {
      this._originalContent = this.contentTarget.innerHTML
    }
  }

  disconnect () {
    this.removeListeners('openDrawer')
  }

  // Override to use drawer-open class instead of modal-open
  openModal (content) {
    this.previouslyFocusedElement = document.activeElement

    if (this.wrapperClasses) {
      this.wrapperTarget.classList.add(...this.wrapperClasses)
    }

    this.templateTarget.classList.add('drawer-open')

    // Only replace content if provided - allows showing skeleton first
    if (content !== null && content !== undefined) {
      this.contentTarget.innerHTML = content
      autoFocusInput(this.contentTarget)
      this.trapFocus()
    }
  }

  _closeModal = () => {
    this.templateTarget.classList.remove('drawer-open')
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

    // Restore focus to the element that triggered the drawer
    if (this.previouslyFocusedElement) {
      this.previouslyFocusedElement.focus()
      this.previouslyFocusedElement = null
    }
  }

  close = (event) => {
    if (event) event.preventDefault()
    this._closeModal()
  }

  // Override open to dispatch 'openDrawer' event with skeleton shown first
  open = async (event) => {
    event.preventDefault()
    const target = event.currentTarget

    const wrapperClasses = this.normalizeClass(
      target.getAttribute('data-wrapper-class')
    )
    const redirectTo = target.getAttribute('data-redirect-to')
    const skipRender = Boolean(target.getAttribute('data-skip-render'))
    const extraProps = JSON.parse(target.getAttribute('data-extra-props'))

    // Show drawer immediately with skeleton (content already in template)
    document.dispatchEvent(new CustomEvent('openDrawer', {
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
    document.dispatchEvent(new CustomEvent('openDrawer', {
      detail: {
        content: body,
        options: { wrapperClasses, redirectTo, skipRender, extraProps }
      }
    }))
  }
}
