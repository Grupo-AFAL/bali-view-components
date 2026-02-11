import { Controller } from '@hotwired/stimulus'

export class SideMenuController extends Controller {
  static values = {
    collapseCheckbox: String,
    mobileTrigger: String
  }

  connect () {
    this.restoreCollapseState()
    this.setupCollapseListener()
    this.setupGlobalListeners()
  }

  disconnect () {
    this.removeCollapseListener()
    this.removeGlobalListeners()
  }

  // Toggle mobile menu visibility
  toggleMenu (e) {
    e?.stopPropagation()
    this.element.classList.toggle('is-active')
    this.syncMobileCheckbox(this.element.classList.contains('is-active'))
  }

  // Open mobile menu
  open () {
    this.element.classList.add('is-active')
    this.syncMobileCheckbox(true)
  }

  // Close mobile menu
  close () {
    this.element.classList.remove('is-active')
    this.syncMobileCheckbox(false)
  }

  // Sync mobile checkbox state with the is-active class
  syncMobileCheckbox (checked) {
    const checkbox = this.mobileCheckbox
    if (checkbox) checkbox.checked = checked
  }

  // Listen for global events so the side menu can be opened from anywhere
  setupGlobalListeners () {
    if (!this.hasMobileTriggerValue) return

    this.boundOnGlobalToggle = () => this.toggleMobile()
    this.boundOnGlobalOpen = () => this.open()
    this.boundOnGlobalClose = () => this.close()

    window.addEventListener('bali:side-menu:toggle', this.boundOnGlobalToggle)
    window.addEventListener('bali:side-menu:open', this.boundOnGlobalOpen)
    window.addEventListener('bali:side-menu:close', this.boundOnGlobalClose)
  }

  removeGlobalListeners () {
    if (!this.boundOnGlobalToggle) return

    window.removeEventListener('bali:side-menu:toggle', this.boundOnGlobalToggle)
    window.removeEventListener('bali:side-menu:open', this.boundOnGlobalOpen)
    window.removeEventListener('bali:side-menu:close', this.boundOnGlobalClose)
  }

  // Toggle mobile via checkbox (used by global events)
  toggleMobile () {
    const checkbox = this.mobileCheckbox
    if (!checkbox) return

    checkbox.checked = !checkbox.checked
    this.element.classList.toggle('is-active', checkbox.checked)
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

  get mobileCheckbox () {
    if (!this.hasMobileTriggerValue) return null
    return document.getElementById(this.mobileTriggerValue)
  }
}
