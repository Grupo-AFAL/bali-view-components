import { Controller } from '@hotwired/stimulus'

export class ImageFieldController extends Controller {
  static targets = ['output', 'input', 'placeholder']

  show () {
    const file = this.inputTarget.files[0]
    if (file) {
      this.outputTarget.src = URL.createObjectURL(file)
      this.outputTarget.style.objectFit = 'cover'
    }
  }

  clear () {
    if (this.hasOutputTarget) this.outputTarget.src = this.placeholderTarget.src
    if (this.hasInputTarget) this.inputTarget.value = ''
  }
}
