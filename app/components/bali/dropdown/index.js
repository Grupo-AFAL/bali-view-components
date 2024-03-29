import { Controller } from '@hotwired/stimulus'

/**
 * Dropdown Controller
 * Provides the JS functionality for the Bulma Dropdown component:
 * https://bulma.io/documentation/components/dropdown/
 *
 * How to use
 *
 * <div class="dropdown is-active" data-controller="dropdown">
 *   <div class="dropdown-trigger">
 *     <button class="button" data-action="dropdown#toggleMenu">
 *       <span>Dropdown button</span>
 *     </button>
 *   </div>
 *   <div class="dropdown-menu">
 *     <div class="dropdown-content">
 *       <a href="#" class="dropdown-item">
 *         Dropdown item
 *       </a>
 *     </div>
 *   </div>
 * </div>
 */
export class DropdownController extends Controller {
  static values = {
    hoverable: { type: Boolean, default: false },
    closeOnClick: { type: Boolean, default: true }
  }

  connect () {
    if (this.closeOnClickValue) {
      document.addEventListener('click', this.closeDropdowns)
    }

    if (!this.hoverableValue) return

    this.element.addEventListener('mouseenter', this.toggleMenu)
    this.element.addEventListener('mouseleave', this.closeDropdowns)
  }

  disconnect () {
    if (this.closeOnClickValue) {
      document.removeEventListener('click', this.closeDropdowns)
    }

    if (!this.hoverableValue) return

    this.element.removeEventListener('mouseenter', this.toggleMenu)
    this.element.removeEventListener('mouseleave', this.closeDropdowns)
  }

  toggleMenu = e => {
    e.stopPropagation()
    e.preventDefault()
    this.element.classList.toggle('is-active')
  }

  closeDropdowns = () => {
    this.element.classList.remove('is-active')
  }
}
