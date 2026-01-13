import { ModalController } from 'bali/modal'
import { autoFocusInput } from 'bali/utils/form'

export class DrawerController extends ModalController {
  async connect () {
    this.setupListeners('openDrawer')
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
    this.contentTarget.innerHTML = content

    autoFocusInput(this.contentTarget)
    this.trapFocus()
  }

  _closeModal = () => {
    this.templateTarget.classList.remove('drawer-open')
    if (this.wrapperClasses) {
      this.wrapperTarget.classList.remove(...this.wrapperClasses)
    }
    this.contentTarget.innerHTML = ''

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
}
