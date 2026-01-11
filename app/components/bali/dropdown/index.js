import { Controller } from '@hotwired/stimulus'

export class DropdownController extends Controller {
  static values = {
    closeOnClick: { type: Boolean, default: true }
  }

  connect () {
    if (this.closeOnClickValue) {
      document.addEventListener('click', this.handleOutsideClick)
    }
  }

  disconnect () {
    if (this.closeOnClickValue) {
      document.removeEventListener('click', this.handleOutsideClick)
    }
  }

  handleOutsideClick = (event) => {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  close () {
    this.element.classList.remove('dropdown-open')
    this.element.querySelector('[tabindex]')?.blur()
  }
}
