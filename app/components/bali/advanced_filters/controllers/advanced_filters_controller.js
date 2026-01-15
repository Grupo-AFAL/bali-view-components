import { Controller } from '@hotwired/stimulus'

/**
 * Main controller for the AdvancedFilters component.
 * Handles adding/removing groups, form submission, and URL management.
 */
export class AdvancedFiltersController extends Controller {
  static targets = [
    'form',
    'groupsContainer',
    'groupTemplate',
    'group',
    'groupCombinator',
    'addGroupButton',
    'applyButton',
    'clearButton',
    'dropdown',
    'dropdownContent'
  ]

  static values = {
    url: String,
    attributes: Array,
    applyMode: { type: String, default: 'batch' },
    maxGroups: { type: Number, default: 10 },
    popover: { type: Boolean, default: true }
  }

  groupIndex = 0

  connect () {
    // Initialize group index based on existing groups
    this.groupIndex = this.groupTargets.length

    // Update UI state
    this.updateAddGroupButton()

    // Handle clicks outside dropdown to close it (use window to catch clicks outside html element)
    if (this.popoverValue && this.hasDropdownTarget) {
      this.boundCloseOnClickOutside = this.closeOnClickOutside.bind(this)
      window.addEventListener('click', this.boundCloseOnClickOutside)
    }
  }

  disconnect () {
    if (this.boundCloseOnClickOutside) {
      window.removeEventListener('click', this.boundCloseOnClickOutside)
    }
  }

  /**
   * Toggle the dropdown open/closed
   */
  toggleDropdown (event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.hasDropdownContentTarget) {
      this.dropdownContentTarget.classList.toggle('hidden')
    }
  }

  /**
   * Close the dropdown
   */
  closeDropdown () {
    if (this.hasDropdownContentTarget) {
      this.dropdownContentTarget.classList.add('hidden')
    }
  }

  /**
   * Open the dropdown
   */
  openDropdown () {
    if (this.hasDropdownContentTarget) {
      this.dropdownContentTarget.classList.remove('hidden')
    }
  }

  /**
   * Close dropdown when clicking outside
   */
  closeOnClickOutside (event) {
    // Check if dropdown is open
    if (!this.hasDropdownContentTarget || this.dropdownContentTarget.classList.contains('hidden')) {
      return
    }

    const target = event.target

    // No target means click outside document - close
    if (!target) {
      this.closeDropdown()
      return
    }

    // Don't close if clicking inside the dropdown
    if (this.hasDropdownTarget && this.dropdownTarget.contains(target)) {
      return
    }

    // Don't close if clicking on Flatpickr calendar (rendered outside dropdown)
    if (target.closest && target.closest('.flatpickr-calendar')) {
      return
    }

    // Don't close if target was removed from DOM (e.g., condition removed)
    // But allow clicks on html/body which are outside our component
    if (target !== document.documentElement &&
        target !== document.body &&
        !document.body.contains(target)) {
      return
    }

    this.closeDropdown()
  }

  /**
   * Add a new filter group
   */
  addGroup (event) {
    event.preventDefault()

    if (this.groupTargets.length >= this.maxGroupsValue) {
      return
    }

    // Clone the template
    const template = this.groupTemplateTarget.content.cloneNode(true)

    // Update indices in the template
    const newIndex = this.groupIndex++
    this.updateTemplateIndices(template, '__GROUP_INDEX__', newIndex)

    // Add combinator divider before the new group (if not first)
    if (this.groupTargets.length > 0) {
      const divider = this.createCombinatorDivider()
      this.groupsContainerTarget.appendChild(divider)
    }

    // Append the new group
    this.groupsContainerTarget.appendChild(template)

    // Focus the first select in the new group
    const newGroup = this.groupTargets[this.groupTargets.length - 1]
    newGroup?.querySelector('select')?.focus()

    // Update UI
    this.updateAddGroupButton()
  }

  /**
   * Remove a filter group
   */
  removeGroup (groupElement) {
    const groupIndex = this.groupTargets.indexOf(groupElement)

    // Remove the combinator divider
    if (groupIndex > 0) {
      // Remove preceding divider
      const prevSibling = groupElement.previousElementSibling
      if (prevSibling?.classList.contains('flex')) {
        prevSibling.remove()
      }
    } else if (this.groupTargets.length > 1) {
      // First group, remove following divider
      const nextSibling = groupElement.nextElementSibling
      if (nextSibling?.classList.contains('flex')) {
        nextSibling.remove()
      }
    }

    // Remove the group
    groupElement.remove()

    // Update UI
    this.updateAddGroupButton()

    // If no groups left, add a default one
    if (this.groupTargets.length === 0) {
      this.addGroup(new Event('click'))
    }
  }

  /**
   * Apply filters - submit the form
   */
  apply (event) {
    event.preventDefault()

    // Update URL for history
    const url = this.buildUrl()
    this.pushHistory(url)

    // Submit the form (Turbo will handle the response with morphing)
    this.formTarget.requestSubmit()
  }

  /**
   * Reset all filters
   */
  reset (event) {
    event.preventDefault()

    // Clear all groups except one
    while (this.groupTargets.length > 1) {
      this.removeGroup(this.groupTargets[this.groupTargets.length - 1])
    }

    // Reset the remaining group
    const firstGroup = this.groupTargets[0]
    if (firstGroup) {
      const controller = this.application.getControllerForElementAndIdentifier(
        firstGroup,
        'filter-group'
      )
      controller?.reset()
    }
  }

  /**
   * Clear all filters and submit
   */
  clearAll (event) {
    event.preventDefault()

    this.reset(event)

    // Navigate to URL without filters
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set('clear_filters', 'true')

    this.pushHistory(url)
    this.formTarget.requestSubmit()
  }

  /**
   * Build the current URL with all filter params
   */
  buildUrl () {
    const url = new URL(this.urlValue, window.location.origin)
    const formData = new FormData(this.formTarget)

    // Clear existing q params
    for (const key of [...url.searchParams.keys()]) {
      if (key.startsWith('q[')) {
        url.searchParams.delete(key)
      }
    }

    // Add form params (only non-empty values)
    for (const [key, value] of formData) {
      if (value && value.trim() !== '') {
        url.searchParams.append(key, value)
      }
    }

    return url
  }

  /**
   * Push URL to browser history
   */
  pushHistory (url) {
    if (window.Turbo) {
      window.Turbo.session.history.push(url)
    } else {
      history.pushState({}, '', url.toString())
    }
  }

  /**
   * Update indices in a template
   */
  updateTemplateIndices (template, placeholder, newIndex) {
    // Update name attributes
    template.querySelectorAll('[name]').forEach((el) => {
      el.name = el.name.replace(new RegExp(placeholder, 'g'), newIndex)
    })

    // Update data attributes
    template.querySelectorAll('[data-filter-group-index-value]').forEach((el) => {
      el.dataset.filterGroupIndexValue = newIndex
    })

    template.querySelectorAll('[data-condition-group-index-value]').forEach((el) => {
      el.dataset.conditionGroupIndexValue = newIndex
    })
  }

  /**
   * Create a combinator divider element
   */
  createCombinatorDivider () {
    const divider = document.createElement('div')
    divider.className = 'flex items-center justify-center gap-2'
    divider.innerHTML = `
      <div class="flex-1 border-t border-base-300"></div>
      <select class="select select-sm select-bordered font-medium"
              name="q[m]"
              data-advanced-filters-target="groupCombinator">
        <option value="and" selected>AND</option>
        <option value="or">OR</option>
      </select>
      <div class="flex-1 border-t border-base-300"></div>
    `
    return divider
  }

  /**
   * Update the add group button state
   */
  updateAddGroupButton () {
    if (this.hasAddGroupButtonTarget) {
      this.addGroupButtonTarget.disabled =
        this.groupTargets.length >= this.maxGroupsValue
    }
  }
}
