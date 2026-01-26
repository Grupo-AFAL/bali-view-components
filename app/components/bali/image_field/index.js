import { Controller } from '@hotwired/stimulus'

export class ImageFieldController extends Controller {
  static targets = ['output', 'input', 'placeholder']

  // Track blob URL for cleanup
  currentBlobUrl = null

  show () {
    const file = this.inputTarget.files[0]
    if (file) {
      // Revoke previous blob URL to prevent memory leaks
      this.revokeBlobUrl()

      this.currentBlobUrl = URL.createObjectURL(file)
      this.outputTarget.src = this.currentBlobUrl
      this.outputTarget.style.objectFit = 'cover'
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
  }

  disconnect () {
    this.revokeBlobUrl()
  }

  // Private: clean up blob URL to prevent memory leaks
  revokeBlobUrl () {
    if (this.currentBlobUrl) {
      URL.revokeObjectURL(this.currentBlobUrl)
      this.currentBlobUrl = null
    }
  }
}
