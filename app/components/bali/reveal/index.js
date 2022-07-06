import { Controller } from '@hotwired/stimulus'

export class RevealController extends Controller {
  openedClass = 'is-revealed'

  toggle () {
    this.element.classList.toggle(this.openedClass)
  }

  show () {
    this.element.classList.remove(this.openedClass)
  }

  hide () {
    this.element.classList.add(this.openedClass)
  }
}
