import { Controller } from '@hotwired/stimulus'

export class FilterAttributeController extends Controller {
  static values = { multiple: Boolean }
  static targets = ['checkbox']

  change ({ target }) {
    if (!target.checked || this.multipleValue) return

    this.checkboxTargets.forEach(checkbox => {
      if (checkbox !== target) {
        checkbox.checked = false
        checkbox.parentElement.classList.remove('is-selected')
      }
    })
  }
}
