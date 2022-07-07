import { Controller } from '@hotwired/stimulus'

export class RevealController extends Controller {
  static targets = ['item']
  static classes = ['hidden']

  openedClass = 'is-revealed'

  connect () {
    this.class = this.hasHiddenClass ? this.hiddenClass : 'is-hidden'
  }

  toggle () {
    this.element.classList.toggle(this.openedClass)

    this.itemTargets.forEach(item => {
      item.classList.toggle(this.class)
    })
  }

  show () {
    this.element.classList.remove(this.openedClass)

    this.itemTargets.forEach(item => {
      item.classList.remove(this.class)
    })
  }

  hide () {
    this.element.classList.add(this.openedClass)

    this.itemTargets.forEach(item => {
      item.classList.add(this.class)
    })
  }
}
