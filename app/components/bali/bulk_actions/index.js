import { Controller } from '@hotwired/stimulus'
import { toInt } from 'bali/utils/formatters'

const IGNORED_TAG_NAMES = ['select', 'input']
export class BulkActionsController extends Controller {
  static targets = [
    'bulkAction',
    'actionsContainer',
    'selectedCount'
  ]

  static values = {
    selectedIds: { type: Array, default: [] }
  }

  connect () {
    this.update()

    this.element.addEventListener('dblclick', this.handleDoubleClick)
  }

  disconnect () {
    this.element.removeEventListener('dblclick', this.handleDoubleClick)
  }

  handleDoubleClick = (event) => {
    if (IGNORED_TAG_NAMES.includes(event.target.tagName.toLowerCase())) return

    const item = event.target.closest('[data-bulk-actions-target="item"]')

    if (item) { this.toggle(item) }
  }

  toggle = (eventOrItem) => {
    const item = eventOrItem.currentTarget || eventOrItem
    if (!item.dataset.recordId) return

    const selected = item.classList.toggle('selected')
    const recordId = toInt(item.dataset.recordId)

    // Sync checkbox state if present
    const checkbox = item.querySelector('input[type="checkbox"]')
    if (checkbox) checkbox.checked = selected

    if (selected) {
      this.selectedIdsValue = this.selectedIdsValue.concat(recordId)
    } else {
      this.selectedIdsValue = this.selectedIdsValue.filter(
        id => id !== recordId
      )
    }

    this.update()
  }

  update = () => {
    this.updateBulkActionsSelectedIds()
    this.updateActionsContainer()
    this.updateSelectedCount()
  }

  updateBulkActionsSelectedIds = () => {
    this.bulkActionTargets.forEach(action => {
      if (action.tagName.toLowerCase() === 'a') {
        const url = new URL(action.href)
        url.searchParams.set('selected_ids', JSON.stringify(this.selectedIdsValue))

        action.href = url.href
      } else {
        action.value = JSON.stringify(this.selectedIdsValue)
      }
    })
  }

  updateActionsContainer = () => {
    if (!this.hasActionsContainerTarget) return

    if (this.selectedIdsValue.length > 0) {
      this.actionsContainerTarget.classList.remove('hidden')
    } else {
      this.actionsContainerTarget.classList.add('hidden')
    }
  }

  updateSelectedCount = () => {
    if (!this.hasSelectedCountTarget) return

    this.selectedCountTarget.innerText = this.selectedIdsValue.length
  }
}
