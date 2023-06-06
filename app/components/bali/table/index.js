import { Controller } from '@hotwired/stimulus'
import { toInt } from '../../../javascript/bali/utils/formatters'

export class TableController extends Controller {
  static targets = [
    'checkbox',
    'toggleAll',
    'bulkAction',
    'actionsContainer',
    'selectedCount'
  ]
  static values = {
    selectedIds: { type: Array, default: [] }
  }

  connect () {
    this.update()
  }

  toggleAll (event) {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = event.target.checked
    })

    this.selectedIdsValue = event.target.checked ? this.allIds : []
    this.update()
  }

  toggle (event) {
    const recordId = toInt(event.target.value)

    if (event.target.checked) {
      this.selectedIdsValue = this.selectedIdsValue.concat(recordId)
    } else {
      this.selectedIdsValue = this.selectedIdsValue.filter(
        id => id !== recordId
      )
    }

    this.updateToggleAllCheckbox()
    this.update()
  }

  update () {
    this.updateBulkActionsSelectedIds()
    this.updateActionsContainer()
    this.updateSelectedCount()
  }

  updateToggleAllCheckbox () {
    if (this.selectedIdsValue.length === this.checkboxTargets.length) {
      this.toggleAllTarget.checked = true
    } else {
      this.toggleAllTarget.checked = false
    }
  }

  updateBulkActionsSelectedIds () {
    this.bulkActionTargets.forEach(action => {
      action.value = JSON.stringify(this.selectedIdsValue)
    })
  }

  updateActionsContainer () {
    if (this.selectedIdsValue.length > 0) {
      this.actionsContainerTarget.classList.remove('is-hidden')
    } else {
      this.actionsContainerTarget.classList.add('is-hidden')
    }
  }

  updateSelectedCount () {
    this.selectedCountTarget.innerText = this.selectedIdsValue.length
  }

  get allIds () {
    return this.checkboxTargets.map(checkbox => toInt(checkbox.value))
  }
}
