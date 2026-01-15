import { Controller } from '@hotwired/stimulus'

/**
 * Controller for the applied filter tags/pills.
 * Handles removing individual filters by clicking the X button.
 */
export class AppliedTagsController extends Controller {
  static targets = ['tag']

  /**
   * Remove a specific filter and resubmit the form
   */
  removeFilter (event) {
    event.preventDefault()

    const button = event.currentTarget
    const groupIndex = button.dataset.groupIndex
    const conditionIndex = button.dataset.conditionIndex

    // Find the advanced filters component and remove the condition
    const advancedFiltersElement = document.querySelector(
      '[data-controller~="advanced-filters"]'
    )

    if (advancedFiltersElement) {
      const advancedFiltersController = this.application.getControllerForElementAndIdentifier(
        advancedFiltersElement,
        'advanced-filters'
      )

      // Find the specific condition to remove
      const groups = advancedFiltersElement.querySelectorAll(
        '[data-advanced-filters-target="group"]'
      )
      const group = groups[groupIndex]

      if (group) {
        const filterGroupController = this.application.getControllerForElementAndIdentifier(
          group,
          'filter-group'
        )

        const conditions = group.querySelectorAll(
          '[data-filter-group-target="condition"]'
        )
        const condition = conditions[conditionIndex]

        if (condition && filterGroupController) {
          filterGroupController.removeCondition(condition)

          // Resubmit the form
          advancedFiltersController?.apply(event)
        }
      }
    }

    // Remove the tag from the UI immediately for instant feedback
    const tag = button.closest('[data-applied-tags-target="tag"]')
    tag?.remove()
  }
}
