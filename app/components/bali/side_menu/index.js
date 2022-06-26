import { Controller } from '@hotwired/stimulus'

export class SideMenuController extends Controller {
  static targets = ['overlay']

  connect () {
    this.element.addEventListener('click', this.closeMenu)

    if (this.hasOverlayTarget) {
      this.overlayTarget.addEventListener('click', this.closeMenu)
    }
  }

  disconnect () {
    this.element.removeEventListener('click', this.closeMenu)

    if (this.hasOverlayTarget) {
      this.overlayTarget.removeEventListener('click', this.closeMenu)
    }
  }

  toggleMenu (e) {
    e.stopPropagation()
    this.element.classList.toggle('is-active')
  }

  closeMenu = e => {
    this.element.classList.remove('is-active')
  }
}
