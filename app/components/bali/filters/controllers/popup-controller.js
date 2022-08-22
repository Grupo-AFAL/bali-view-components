import { Controller } from '@hotwired/stimulus'
import { createPopper } from '@popperjs/core'
import useClickOutside from '../../../../javascript/bali/utils/use-click-outside'

export class PopupController extends Controller {
  static targets = ['container', 'button', 'openedInput']
  static values = {
    opened: { type: Boolean, default: false }
  }

  connect () {
    useClickOutside(this)
    this.popperInstance = createPopper(
      this.buttonTarget,
      this.containerTarget,
      {
        placement: 'bottom',
        modifiers: [
          {
            name: 'offset',
            options: {
              offset: [0, 8]
            }
          },
          {
            name: 'preventOverflow',
            options: {
              padding: 16
            }
          }
        ]
      }
    )
  }

  disconnect () {
    this.popperInstance.destroy()
  }

  open () {
    this.containerTarget.classList.remove('is-hidden')
    this.containerTarget.classList.add('popin')
    this.buttonTarget.classList.add('is-selected')
    this.openedInputTarget.value = true
    this.popperInstance.update()
    this.openedValue = true
  }

  close () {
    this.containerTarget.classList.add('is-hidden')
    this.containerTarget.classList.remove('popin')
    this.buttonTarget.classList.remove('is-selected')
    this.openedInputTarget.value = false
    this.openedValue = false
  }

  toggle () {
    if (this.openedValue) {
      this.close()
    } else {
      this.open()
    }
  }

  clickOutside () {
    this.close()
  }
}
