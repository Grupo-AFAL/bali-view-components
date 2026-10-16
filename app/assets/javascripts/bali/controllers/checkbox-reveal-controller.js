import { Controller } from '@hotwired/stimulus'

export class CheckboxRevealController extends Controller {
  static targets = ['checkbox', 'item']
  static classes = ['hidden']

  // A stream with `method="morph"` keeps the item, so `itemTargetConnected` does
  // not run for it and it would keep the class the server painted.
  connect () {
    this.element.addEventListener('turbo:morph-element', this.retoggle)
  }

  disconnect () {
    this.element.removeEventListener('turbo:morph-element', this.retoggle)
  }

  // Stimulus also calls this for the items present at connect, so it is the whole
  // initial render. An item a Turbo Stream replaces later lands here too, and takes
  // the checkboxes on screen rather than the class the server painted.
  itemTargetConnected () {
    this.toggle()
  }

  retoggle = () => this.toggle()

  toggle () {
    if (!this.hasCheckboxTarget || !this.hasItemTarget) return

    const checked = this.checkboxTargets.reduce((acc, element) => (acc || element.checked), false)

    this.itemTargets.forEach(element => {
      if (checked) {
        element.classList.remove(this.hidingClass)
      } else {
        element.classList.add(this.hidingClass)
      }
    })
  }

  // Not set in `connect`: Stimulus runs `itemTargetConnected` before it.
  get hidingClass () {
    return this.hasHiddenClass ? this.hiddenClass : 'hidden'
  }
}
