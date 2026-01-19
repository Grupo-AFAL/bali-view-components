import { Controller } from '@hotwired/stimulus'

export class SideMenuController extends Controller {
  static values = {
    collapseCheckbox: String
  }

  connect () {
    this.restoreCollapseState()
    this.setupCollapseListener()
  }

  disconnect () {
    this.removeCollapseListener()
  }

  // Toggle mobile menu visibility
  toggleMenu (e) {
    e?.stopPropagation()
    this.element.classList.toggle('is-active')
  }

  // Open mobile menu
  open () {
    this.element.classList.add('is-active')
  }

  // Close mobile menu
  close () {
    this.element.classList.remove('is-active')
  }

  // Restore collapse state from localStorage
  restoreCollapseState () {
    if (!this.hasCollapseCheckboxValue) return

    const checkbox = this.collapseCheckbox
    if (!checkbox) return

    const isCollapsed = localStorage.getItem('bali_sideMenuCollapsed') === 'true'
    checkbox.checked = isCollapsed
  }

  // Setup listener to save collapse state on change
  setupCollapseListener () {
    const checkbox = this.collapseCheckbox
    if (!checkbox) return

    this.handleCollapseChange = () => {
      localStorage.setItem('bali_sideMenuCollapsed', checkbox.checked)
    }

    checkbox.addEventListener('change', this.handleCollapseChange)
  }

  removeCollapseListener () {
    const checkbox = this.collapseCheckbox
    if (!checkbox || !this.handleCollapseChange) return

    checkbox.removeEventListener('change', this.handleCollapseChange)
  }

  // Toggle collapse via Stimulus action (for programmatic control)
  toggleCollapse () {
    const checkbox = this.collapseCheckbox
    if (!checkbox) return

    checkbox.checked = !checkbox.checked
    checkbox.dispatchEvent(new Event('change'))
  }

  get collapseCheckbox () {
    if (!this.hasCollapseCheckboxValue) return null
    return document.getElementById(this.collapseCheckboxValue)
  }
}
