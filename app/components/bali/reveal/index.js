import { Controller } from '@hotwired/stimulus'

export class RevealController extends Controller {
  static targets = ['item', 'trigger']
  static classes = ['hidden']

  openedClass = 'is-revealed'

  connect () {
    this.class = this.hasHiddenClass ? this.hiddenClass : 'hidden'
  }

  toggle () {
    this.opened ? this.hide() : this.show()
  }

  show () {
    this.element.classList.add(this.openedClass)
    this.itemTargets.forEach(item => item.classList.remove(this.class))
    this.syncTrigger()
  }

  hide () {
    this.element.classList.remove(this.openedClass)
    this.itemTargets.forEach(item => item.classList.add(this.class))
    this.syncTrigger()
  }

  get opened () {
    return this.element.classList.contains(this.openedClass)
  }

  syncTrigger () {
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute('aria-expanded', this.opened)
    }
  }
}
