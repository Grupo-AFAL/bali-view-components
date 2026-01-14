import { Controller } from '@hotwired/stimulus'

export class TreeViewItemController extends Controller {
  static targets = ['caret', 'children']
  static values = { url: String }

  toggle (event) {
    event.preventDefault()

    this.caretTarget.classList.toggle('caret-down')

    if (this.hasChildrenTarget) {
      this.childrenTarget.classList.toggle('hidden')
    }
  }

  navigateTo (event) {
    if (this.caretTarget === event.target) return

    if (window.Turbo) {
      window.Turbo.visit(this.urlValue)
    } else {
      event.preventDefault()
      console.log('Turbo not configured')
    }
  }
}
