import { Controller } from '@hotwired/stimulus'

export class FilterAttributeController extends Controller {
  static values = { multiple: Boolean }
  static targets = ['checkbox']

  change ({ target }) {
    if (this.multipleValue) return

    console.log('target', target)

    if (target.checked) {
      this.checkboxTargets.forEach(checkbox => {
        if (checkbox !== target) {
          console.log('not target', checkbox)
          checkbox.checked = false
          checkbox.parentElement.classList.remove('is-selected')
        } else {
          console.log('is target', checkbox)
        }
      })
    } else {
      console.log('not checked', target)
      target.checked = false
    }
  }
}
