import { Controller } from '@hotwired/stimulus'

const STORAGE_PREFIX = 'bali:message:dismissed:'

/**
 * Message Controller
 *
 * Dismisses a Bali::Message alert when the close button is clicked. When a
 * `dismissId` value is present the dismissed state is persisted in
 * localStorage, so the message stays hidden on future page loads.
 */
export class MessageController extends Controller {
  static values = {
    dismissId: String
  }

  connect () {
    if (this.dismissed) this.hide()
  }

  dismiss () {
    if (this.persistent) {
      localStorage.setItem(this.storageKey, 'true')
    }

    this.element.remove()
  }

  hide () {
    this.element.hidden = true
  }

  get persistent () {
    return this.hasDismissIdValue && this.dismissIdValue.length > 0
  }

  get dismissed () {
    return this.persistent && localStorage.getItem(this.storageKey) === 'true'
  }

  get storageKey () {
    return `${STORAGE_PREFIX}${this.dismissIdValue}`
  }
}
