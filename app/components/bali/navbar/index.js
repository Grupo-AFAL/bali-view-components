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
    this._boundCloseOnClickOutside = this._closeOnClickOutside.bind(this)

    if (!this.allowTransparencyValue) return

    this.isTransparent = true
    this.element.classList.add('is-transparent')
    this.throttledUpdateBackgroundColor = throttle(this.updateBackgroundColor, this.throttleIntervalValue)

    document.addEventListener('scroll', this.throttledUpdateBackgroundColor)
  }

  disconnect () {
    document.removeEventListener('click', this._boundCloseOnClickOutside)

    if (this.throttledUpdateBackgroundColor) {
      document.removeEventListener('scroll', this.throttledUpdateBackgroundColor)
    }
  }

  updateBackgroundColor = () => {
    // `hasBurgerTarget` and not `?.`: the getter Stimulus generates for a singular target
    // THROWS when the element is missing (stimulus 3.2.2, dist/stimulus.js:2286-2294), and
    // `?.` is evaluated on its RESULT — so the `||` below was unreachable, not a fallback.
    // A navbar whose only burger is `type: :sidebar` declares no `burger` target at all
    // (Burger::CONFIGURATIONS[:sidebar] is empty; :alt points at `altBurger`; the `href:`
    // form never calls configure_attrs). Rendered and measured: that navbar comes out with
    // `allow-transparency-value="true"` and only a `menu` target, so with transparency on
    // every throttled scroll tick threw in here and `removeIsTransparent()` never ran —
    // the navbar stayed `bg-transparent shadow-none` over the scrolled page for good.
    //
    // The `||` stays, because it earns its keep in the case where the target IS there: the
    // burger is `lg:hidden`, so above the lg breakpoint its offsetHeight is 0 and the
    // navbar's own height is the right thing to compare the scroll position against.
    const targetHeight =
      (this.hasBurgerTarget && this.burgerTarget.offsetHeight) || this.element.offsetHeight
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

    this._updateClickOutsideListener()
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

    this._updateClickOutsideListener()
  }

  // Toggle the side menu via global event (for cross-component communication).
  // Targets `window` because that is where SideMenuController listens: the two
  // are siblings, so an event bubbling out of the navbar never reaches it.
  toggleSideMenu (event) {
    event.preventDefault()
    this.dispatch('toggle', { prefix: 'bali:side-menu', target: window })
  }

  // Close mobile menu when clicking outside the navbar
  _closeOnClickOutside (event) {
    if (this.element.contains(event.target)) return

    if (this.menuActive) {
      this.menuActive = false
      if (this.hasMenuTarget) {
        this.menuTarget.classList.add('hidden')
        this.menuTarget.classList.remove('flex')
      }
      if (this.hasBurgerTarget) {
        this.burgerTarget.classList.remove('is-active')
      }
    }

    if (this.altMenuActive) {
      this.altMenuActive = false
      if (this.hasAltMenuTarget) {
        this.altMenuTarget.classList.add('hidden')
        this.altMenuTarget.classList.remove('flex')
      }
      if (this.hasAltBurgerTarget) {
        this.altBurgerTarget.classList.remove('is-active')
      }
    }

    this._updateClickOutsideListener()
  }

  _updateClickOutsideListener () {
    if (this.menuActive || this.altMenuActive) {
      document.addEventListener('click', this._boundCloseOnClickOutside)
    } else {
      document.removeEventListener('click', this._boundCloseOnClickOutside)
    }
  }
}
