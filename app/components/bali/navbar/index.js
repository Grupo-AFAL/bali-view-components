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
    if (!this.altMenuActive) {
      this.element.classList.toggle('is-active')
    }

    if (this.hasMenuTarget) {
      this.menuTarget.classList.toggle('is-active')
    }

    if (this.hasBurgerTarget) {
      this.burgerTarget.classList.toggle('is-active')
    }
  }

  toggleAltMenu (event) {
    event.preventDefault()
    this.altMenuActive = !this.altMenuActive
    if (!this.menuActive) {
      this.element.classList.toggle('is-active')
    }

    if (this.hasAltMenuTarget) {
      this.altMenuTarget.classList.toggle('is-active')
    }

    if (this.hasAltBurgerTarget) {
      this.altBurgerTarget.classList.toggle('is-active')
    }
  }
}
