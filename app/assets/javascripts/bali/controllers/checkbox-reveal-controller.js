import { Controller } from '@hotwired/stimulus'

export class CheckboxRevealController extends Controller {
  static targets = ['checkbox', 'item']
  static classes = ['hidden']

  // A stream with `method="morph"` keeps the item, which would keep the class the
  // server painted.
  connect () {
    this.class = this.hasHiddenClass ? this.hiddenClass : 'hidden'
    this.toggle()
    this.element.addEventListener('turbo:morph-element', this.retoggle)
  }

  disconnect () {
    this.element.removeEventListener('turbo:morph-element', this.retoggle)
  }

  retoggle = () => this.toggle()

  toggle () {
    if (!this.hasCheckboxTarget || !this.hasItemTarget) return

    const checked = this.checkboxTargets.reduce((acc, element) => (acc || element.checked), false)

    this.itemTargets.forEach(element => {
      if (checked) {
        element.classList.remove(this.class)
      } else {
        element.classList.add(this.class)
      }
    })
  }
}
