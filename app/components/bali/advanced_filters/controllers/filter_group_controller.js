import { Controller } from '@hotwired/stimulus'

/**
 * Controller for individual filter groups.
 * Handles adding/removing conditions within a group and changing the combinator.
 */
export class FilterGroupController extends Controller {
  static targets = [
    'conditionsContainer',
    'conditionTemplate',
    'condition',
    'combinator',
    'combinatorBadge'
  ]

  static values = {
    index: Number
  }

  conditionIndex = 0

  connect () {
    // Initialize condition index based on existing conditions
    this.conditionIndex = this.conditionTargets.length
  }

  /**
   * Add a new condition to this group
   */
  addCondition (event) {
    event.preventDefault()

    // Clone the template
    const template = this.conditionTemplateTarget.content.cloneNode(true)

    // Update indices
    const newIndex = this.conditionIndex++
    this.updateConditionIndices(template, '__CONDITION_INDEX__', newIndex)

    // Add OR badge before new condition (if not first)
    if (this.conditionTargets.length > 0) {
      const orBadge = this.createConditionDivider()
      this.conditionsContainerTarget.appendChild(orBadge)
    }

    // Append the new condition
    this.conditionsContainerTarget.appendChild(template)

    // Focus the attribute selector in the new condition
    const newCondition = this.conditionTargets[this.conditionTargets.length - 1]
    newCondition?.querySelector('select')?.focus()

    // Show combinator selector if we have multiple conditions
    this.updateCombinatorVisibility()
  }

  /**
   * Remove a condition from this group
   */
  removeCondition (conditionElement) {
    const conditionIndex = this.conditionTargets.indexOf(conditionElement)

    // Remove the OR badge
    if (conditionIndex > 0) {
      const prevSibling = conditionElement.previousElementSibling
      if (prevSibling?.classList.contains('flex')) {
        prevSibling.remove()
      }
    } else if (this.conditionTargets.length > 1) {
      const nextSibling = conditionElement.nextElementSibling
      if (nextSibling?.classList.contains('flex')) {
        nextSibling.remove()
      }
    }

    // Remove the condition
    conditionElement.remove()

    // Update combinator visibility
    this.updateCombinatorVisibility()

    // If no conditions left, add a default one
    if (this.conditionTargets.length === 0) {
      this.addCondition(new Event('click'))
    }

    // Keep focus inside dropdown to prevent it from closing
    // DaisyUI dropdowns use :focus-within, so we need to maintain focus
    this.refocusDropdown()
  }

  /**
   * Refocus dropdown to keep it open after DOM changes
   */
  refocusDropdown () {
    const dropdown = this.element.closest('.dropdown-content')
    if (dropdown) {
      // Focus the dropdown content itself or the first focusable element
      const focusable = dropdown.querySelector('button, select, input')
      if (focusable) {
        focusable.focus()
      } else {
        dropdown.focus()
      }
    }
  }

  /**
   * Remove this entire group
   */
  removeGroup (event) {
    event.preventDefault()

    // Find the parent advanced-filters controller and call removeGroup
    const advancedFiltersElement = this.element.closest('[data-controller~="advanced-filters"]')
    if (advancedFiltersElement) {
      const controller = this.application.getControllerForElementAndIdentifier(
        advancedFiltersElement,
        'advanced-filters'
      )
      controller?.removeGroup(this.element)
    }
  }

  /**
   * Toggle the combinator between AND/OR when clicking a badge
   */
  toggleCombinator (event) {
    event.preventDefault()

    // Get current combinator and toggle it
    const currentCombinator = this.hasCombinatorTarget ? this.combinatorTarget.value : 'or'
    const newCombinator = currentCombinator === 'or' ? 'and' : 'or'

    // Update the hidden field
    if (this.hasCombinatorTarget) {
      this.combinatorTarget.value = newCombinator
    }

    // Update all combinator badges
    this.combinatorBadgeTargets.forEach((badgeContainer) => {
      const button = badgeContainer.querySelector('button')
      if (button) {
        button.textContent = newCombinator.toUpperCase()
      }
    })
  }

  /**
   * Reset this group to default state
   */
  reset () {
    // Remove all conditions except one
    while (this.conditionTargets.length > 1) {
      this.removeCondition(this.conditionTargets[this.conditionTargets.length - 1])
    }

    // Reset the remaining condition
    const firstCondition = this.conditionTargets[0]
    if (firstCondition) {
      const controller = this.application.getControllerForElementAndIdentifier(
        firstCondition,
        'condition'
      )
      controller?.reset()
    }

    // Reset combinator
    if (this.hasCombinatorTarget) {
      this.combinatorTarget.value = 'or'
    }

    // Reset all combinator badges to OR
    this.combinatorBadgeTargets.forEach((badgeContainer) => {
      const button = badgeContainer.querySelector('button')
      if (button) {
        button.textContent = 'OR'
      }
    })
  }

  /**
   * Update indices in the condition template
   */
  updateConditionIndices (template, placeholder, newIndex) {
    template.querySelectorAll('[name]').forEach((el) => {
      el.name = el.name.replace(new RegExp(placeholder, 'g'), newIndex)
    })

    template.querySelectorAll('[data-condition-index-value]').forEach((el) => {
      el.dataset.conditionIndexValue = newIndex
    })
  }

  /**
   * Create a clickable combinator badge divider between conditions
   */
  createConditionDivider () {
    const combinator = this.hasCombinatorTarget ? this.combinatorTarget.value : 'or'

    const divider = document.createElement('div')
    divider.className = 'flex items-center gap-2 pl-2'
    divider.dataset.filterGroupTarget = 'combinatorBadge'
    divider.innerHTML = `
      <button type="button"
              class="badge badge-sm badge-outline font-medium cursor-pointer hover:badge-primary transition-colors"
              data-action="filter-group#toggleCombinator"
              title="Click to toggle AND/OR">
        ${combinator.toUpperCase()}
      </button>
    `
    return divider
  }

  /**
   * Show/hide the combinator selector based on condition count
   */
  updateCombinatorVisibility () {
    // The combinator select is shown/hidden via CSS based on condition count
    // This method can be used for additional logic if needed
  }
}
