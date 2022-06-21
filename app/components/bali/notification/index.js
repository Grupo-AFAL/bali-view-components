import { Controller } from '@hotwired/stimulus'

/**
 * Notification Controller
 * Automatically hides or not the element after given delay seconds
 * Defaults:
 *  --delay: 3 seconds
 *  --animation: fadeOutRight
 *  --dismiss: true (The element will be removed if dismissValue is true)
 */
export class NotificationController extends Controller {
  static classes = ['animation']

  static values = {
    delay: { type: Number, default: 3000 },
    dismiss: { type: Boolean, default: true }
  }

  connect () {
    this.closed = false

    if (this.dismissValue) {
      setTimeout(() => this.close(), this.delayValue)
    }
  }

  disconnect () {
    if (this.closed) return
    this.removeElement()
  }

  close () {
    const animationClass = this.hasAnimationClass
      ? this.animationClass
      : 'fadeOutRight'

    this.element.classList.add(animationClass)
    this.element.addEventListener('animationend', () => {
      this.closed = true
      this.removeElement()
    })
  }

  removeElement () {
    if (this.element) {
      this.element.remove()
    }
  }
}
