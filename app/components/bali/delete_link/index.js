import { Controller } from '@hotwired/stimulus'

// The button of a `DeleteLink` rendered `in_form: true`. Its form arrives inside a <template>
// and reaches the document only when the button is pressed, placed before the outer form. The
// click's default action, which runs after this, submits it: the button's `form` attribute
// names it.
//
// Not placed inside the outer form: Chrome stops a nested form's submit event at the outer
// form, so Turbo's listener on the document never sees it — measured, no confirm, and the page
// navigated to the DELETE's response. Before it rather than after, so the outer form stays its
// parent's last child for `space-y-*` and `divide-y`, which skip `:last-child`.
//
// Not placed on connect: a refresh morph rewrites the template's content and removes every
// node the new page does not have, a form placed outside included, while this controller stays
// connected — measured, the buttons then did nothing.
export class DeleteLinkController extends Controller {
  static targets = ['template']

  placeForm () {
    if (this.element.form) return

    const form = this.templateTarget.content.firstElementChild.cloneNode(true)
    const anchor = this.element.closest('form') || this.element
    anchor.before(form)
  }

  // Found by id rather than kept from the click: a page restored from Turbo's cache brings back
  // the form an earlier copy of this button placed.
  disconnect () {
    document.getElementById(this.element.getAttribute('form'))?.remove()
  }
}
