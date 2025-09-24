import { Controller } from '@hotwired/stimulus'

export class CheckboxRevealController extends Controller {
  static targets = ['checkbox', 'item']
  static classes = ['hidden']

  connect () {
    this.class = this.hasHiddenClass ? this.hiddenClass : 'is-hidden'
    this.toggle()
  }

  toggle () {
    if (!this.hasCheckboxTarget || !this.hasItemTarget) return

    const checked = this.checkboxTargets.reduce((acc, element) => (acc || element.checked), false)

    this.itemTargets.forEach(element => {
      if (checked) {
        element.classList.remove(this.class)
      } else {
        element.classList.add(this.class)
      }
    });
  }
}
