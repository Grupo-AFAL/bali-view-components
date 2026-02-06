import { Controller } from '@hotwired/stimulus'
import throttle from 'lodash.throttle'

export class NavbarController extends Controller {
  static values = {
    allowTransparency: Boolean,
    throttleInterval: { type: Number, default: 1000 }
  }

  static targets = ['menu', 'burger', 'altMenu', 'altBurger']

  menuActive = false
  altMenuActive = false

  connect () {
    if (!this.allowTransparencyValue) return

    this.isTransparent = true
    this.element.classList.add('is-transparent')
    this.throttledUpdateBackgroundColor = throttle(this.updateBackgroundColor, this.throttleIntervalValue)

    document.addEventListener('scroll', this.throttledUpdateBackgroundColor)
  }

  disconnect () {
    if (this.throttledUpdateBackgroundColor) {
      document.removeEventListener('scroll', this.throttledUpdateBackgroundColor)
    }
  }

  updateBackgroundColor = () => {
    const targetHeight =
      this.burgerTarget?.offsetHeight || this.element.offsetHeight
    if (window.scrollY > targetHeight) {
      this.removeIsTransparent()
    } else {
      this.setIsTransparent()
    }
  }

  setIsTransparent () {
    if (this.isTransparent) return

    this.isTransparent = true
    this.element.classList.add('is-transparent')
  }

  removeIsTransparent () {
    if (!this.isTransparent) return

    this.isTransparent = false
    this.element.classList.remove('is-transparent')
  }

  toggleMenu (event) {
    event.preventDefault()
    this.menuActive = !this.menuActive

    if (this.hasMenuTarget) {
      this.toggleVisibility(this.menuTarget)
    }

    if (this.hasBurgerTarget) {
      this.burgerTarget.classList.toggle('is-active')
    }
  }

  toggleVisibility (element) {
    const isHidden = element.classList.contains('hidden')
    if (isHidden) {
      element.classList.remove('hidden')
      element.classList.add('flex')
    } else {
      element.classList.add('hidden')
      element.classList.remove('flex')
    }
  }

  toggleAltMenu (event) {
    event.preventDefault()
    this.altMenuActive = !this.altMenuActive

    if (this.hasAltMenuTarget) {
      this.toggleVisibility(this.altMenuTarget)
    }

    if (this.hasAltBurgerTarget) {
      this.altBurgerTarget.classList.toggle('is-active')
    }
  }

  // Toggle the side menu via global event (for cross-component communication)
  toggleSideMenu (event) {
    event.preventDefault()
    window.dispatchEvent(new CustomEvent('bali:side-menu:toggle'))
  }
}
