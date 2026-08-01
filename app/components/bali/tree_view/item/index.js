import { Controller } from '@hotwired/stimulus'

export class TreeViewItemController extends Controller {
  static targets = ['caret', 'children']
  static values = { url: String }

  toggle (event) {
    event.preventDefault()
    event.stopPropagation()

    if (!this.hasChildrenTarget) return

    const expanded = !this.childrenTarget.classList.toggle('hidden')
    this.caretTarget.classList.toggle('rotate-90', expanded)
    this.caretTarget.setAttribute('aria-expanded', expanded)
  }

  navigateTo (event) {
    // Nested items bubble their clicks up here, but Stimulus only invokes the
    // binding whose scope owns the event target (Scope#containsElement), so a
    // click on a child never reaches its ancestors' navigateTo. Nothing to guard.

    // The caret toggles; it never navigates. Childless items have no caret target
    // at all, hence the hasCaretTarget check rather than a bare caretTarget read.
    if (this.hasCaretTarget && this.caretTarget.contains(event.target)) return

    // The link navigates on its own — don't do it a second time.
    if (event.target.closest('a')) return

    if (!window.Turbo) return

    event.preventDefault()
    window.Turbo.visit(this.urlValue)
  }
}
