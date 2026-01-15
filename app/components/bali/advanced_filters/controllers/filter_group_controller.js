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
    'conditionRow',
    'combinator',
    'combinatorToggle'
  ]

  static values = {
    index: Number,
    combinator: { type: String, default: 'or' }
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

    // Clone the template (includes the row wrapper with toggle)
    const template = this.conditionTemplateTarget.content.cloneNode(true)

    // Update indices
    const newIndex = this.conditionIndex++
    this.updateConditionIndices(template, '__CONDITION_INDEX__', newIndex)

    // Update toggle buttons to reflect current combinator
    this.updateToggleButtons(template)

    // Append the new condition row
    this.conditionsContainerTarget.appendChild(template)

    // Focus the attribute selector in the new condition
    const newCondition = this.conditionTargets[this.conditionTargets.length - 1]
    newCondition?.querySelector('select')?.focus()
  }

  /**
   * Remove a condition from this group
   */
  removeCondition (conditionElement) {
    // Find the row containing this condition
    const row = conditionElement.closest('[data-filter-group-target="conditionRow"]')

    if (row) {
      row.remove()
    } else {
      // Fallback: remove just the condition element
      conditionElement.remove()
    }

    // If no conditions left, add a default one
    if (this.conditionTargets.length === 0) {
      this.addCondition(new Event('click'))
    }

    // Keep focus inside dropdown to prevent it from closing
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
   * Set the combinator to a specific value (AND or OR)
   */
  setCombinator (event) {
    event.preventDefault()
    event.stopPropagation()

    const newCombinator = event.currentTarget.dataset.combinator

    // Update the value
    this.combinatorValue = newCombinator

    // Update the hidden field
    if (this.hasCombinatorTarget) {
      this.combinatorTarget.value = newCombinator
    }

    // Update all toggle buttons in this group
    this.updateAllToggleButtons()
  }

  /**
   * Update toggle button states to reflect current combinator
   */
  updateAllToggleButtons () {
    this.combinatorToggleTargets.forEach((toggle) => {
      this.updateToggleButtons(toggle)
    })
  }

  /**
   * Update toggle buttons within a container to reflect current combinator
   */
  updateToggleButtons (container) {
    const combinator = this.combinatorValue || 'or'
    const buttons = container.querySelectorAll('[data-combinator]')

    buttons.forEach((btn) => {
      const btnCombinator = btn.dataset.combinator
      if (btnCombinator === combinator) {
        btn.classList.remove('btn-outline')
        btn.classList.add('btn-primary')
      } else {
        btn.classList.remove('btn-primary')
        btn.classList.add('btn-outline')
      }
    })
  }

  /**
   * Reset this group to default state
   */
  reset () {
    // Remove all condition rows except the first
    const rows = this.conditionRowTargets
    while (rows.length > 1) {
      rows[rows.length - 1].remove()
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
    this.combinatorValue = 'or'
    if (this.hasCombinatorTarget) {
      this.combinatorTarget.value = 'or'
    }
    this.updateAllToggleButtons()
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
}
