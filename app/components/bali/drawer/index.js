import { ModalController } from '../modal/index.js'
import { autoFocusInput } from '../../../assets/javascripts/bali/utils/form.js'

// Size classes matching Drawer::Component::SIZES
const SIZE_CLASSES = {
  sm: 'max-w-sm',
  md: 'max-w-lg',
  lg: 'max-w-2xl',
  xl: 'max-w-4xl',
  full: 'max-w-full'
}

const DEFAULT_SIZE = 'md'

export class DrawerController extends ModalController {
  async connect () {
    this.setupListeners('openDrawer')

    // Store original skeleton content for restoration on close
    if (this.hasContentTarget) {
      this._originalContent = this.contentTarget.innerHTML
    }

    // Store the default size class from the panel
    this._defaultSizeClass = SIZE_CLASSES[DEFAULT_SIZE]
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

    // Apply dynamic size class if specified
    if (this.drawerSize && SIZE_CLASSES[this.drawerSize]) {
      this._applySize(this.drawerSize)
    }

    this.templateTarget.classList.add('drawer-open')

    // Only replace content if provided - allows showing skeleton first
    if (content !== null && content !== undefined) {
      this.contentTarget.innerHTML = content
      autoFocusInput(this.contentTarget)
      this.trapFocus()
    }
  }

  _applySize (size) {
    const sizeClass = SIZE_CLASSES[size]
    if (!sizeClass) return

    // Remove all size classes first
    Object.values(SIZE_CLASSES).forEach(cls => {
      this.wrapperTarget.classList.remove(cls)
    })

    // Apply the new size class
    this.wrapperTarget.classList.add(sizeClass)
    this._currentSizeClass = sizeClass
  }

  _restoreDefaultSize () {
    if (this._currentSizeClass) {
      this.wrapperTarget.classList.remove(this._currentSizeClass)
      this.wrapperTarget.classList.add(this._defaultSizeClass)
      this._currentSizeClass = null
    }
  }

  _closeModal = () => {
    this.templateTarget.classList.remove('drawer-open')
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
    const drawerSize = target.getAttribute('data-drawer-size')

    // Show drawer immediately with skeleton (content already in template)
    document.dispatchEvent(new CustomEvent('openDrawer', {
      detail: {
        content: null, // Don't replace content - show existing skeleton
        options: { wrapperClasses, redirectTo, skipRender, extraProps, drawerSize }
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
        options: { wrapperClasses, redirectTo, skipRender, extraProps, drawerSize }
      }
    }))
  }
}
