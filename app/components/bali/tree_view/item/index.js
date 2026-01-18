import { Controller } from '@hotwired/stimulus'

export class TreeViewItemController extends Controller {
  static targets = ['caret', 'children']
  static values = { url: String }

  toggle (event) {
    event.preventDefault()
    event.stopPropagation()

    // Toggle rotation on caret for smooth animation
    this.caretTarget.classList.toggle('rotate-90')

    if (this.hasChildrenTarget) {
      this.childrenTarget.classList.toggle('hidden')
    }

    // Update aria-expanded for accessibility
    const expanded = this.caretTarget.classList.contains('rotate-90')
    this.element.setAttribute('aria-expanded', expanded)
  }

  navigateTo (event) {
    // Don't navigate if clicking on the caret (toggle instead)
    if (this.caretTarget === event.target || this.caretTarget.contains(event.target)) {
      return
    }

    // Don't interfere with link clicks - let them handle navigation naturally
    if (event.target.tagName === 'A') {
      return
    }

    // For clicks on the item row (not the link), use Turbo if available
    if (window.Turbo) {
      event.preventDefault()
      window.Turbo.visit(this.urlValue)
    }
  }
}
