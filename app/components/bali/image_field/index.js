import { Controller } from '@hotwired/stimulus'

export class ImageFieldController extends Controller {
  static targets = ['output', 'input', 'placeholder', 'clear']

  // Track blob URL for cleanup
  currentBlobUrl = null

  // The page Turbo restores for Back still shows the last controller's blob: this one owns it.
  connect () {
    if (this.outputTarget.src.startsWith('blob:')) this.currentBlobUrl = this.outputTarget.src
  }

  show () {
    const file = this.inputTarget.files[0]
    if (file) {
      // Revoke previous blob URL to prevent memory leaks
      this.revokeBlobUrl()

      this.currentBlobUrl = URL.createObjectURL(file)
      this.outputTarget.src = this.currentBlobUrl
      this.outputTarget.style.objectFit = 'cover'
      if (this.hasClearTarget) this.clearTarget.hidden = false
    }
  }

  clear () {
    this.revokeBlobUrl()

    if (this.hasOutputTarget && this.hasPlaceholderTarget) {
      this.outputTarget.src = this.placeholderTarget.src
    }
    if (this.hasInputTarget) {
      this.inputTarget.value = ''
    }
    if (this.hasClearTarget) {
      // Hiding the button that has focus would drop focus on the body.
      if (this.clearTarget.contains(document.activeElement)) this.inputTarget?.focus()
      this.clearTarget.hidden = true
    }
  }

  // Private: clean up blob URL to prevent memory leaks. Never on `disconnect`: Turbo's snapshot
  // for Back still shows the blob, and restored a broken image with the file still on the input.
  revokeBlobUrl () {
    if (this.currentBlobUrl) {
      URL.revokeObjectURL(this.currentBlobUrl)
      this.currentBlobUrl = null
    }
  }
}
