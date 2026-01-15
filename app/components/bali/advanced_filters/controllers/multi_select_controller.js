import { Controller } from '@hotwired/stimulus'

/**
 * Controller for multi-select dropdown in advanced filters.
 * Uses custom dropdown with checkboxes for consistent styling.
 */
export class MultiSelectController extends Controller {
  static targets = ['trigger', 'label', 'dropdown']

  connect () {
    this.updateLabel()
    this.boundCloseOnClickOutside = this.closeOnClickOutside.bind(this)
    document.addEventListener('click', this.boundCloseOnClickOutside)
  }

  disconnect () {
    document.removeEventListener('click', this.boundCloseOnClickOutside)
  }

  toggle (event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.toggle('hidden')
    }
  }

  close () {
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.add('hidden')
    }
  }

  closeOnClickOutside (event) {
    if (!this.hasDropdownTarget || this.dropdownTarget.classList.contains('hidden')) {
      return
    }

    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  updateSelection (event) {
    event.stopPropagation() // Keep dropdown open when selecting
    this.updateLabel()
  }

  updateLabel () {
    const checkboxes = this.element.querySelectorAll('input[type="checkbox"]:checked')
    const labels = Array.from(checkboxes).map(cb => cb.dataset.label)

    if (labels.length === 0) {
      this.labelTarget.textContent = 'Select values...'
      this.labelTarget.classList.add('text-base-content/50')
    } else if (labels.length <= 2) {
      this.labelTarget.textContent = labels.join(', ')
      this.labelTarget.classList.remove('text-base-content/50')
    } else {
      this.labelTarget.textContent = `${labels.length} selected`
      this.labelTarget.classList.remove('text-base-content/50')
    }
  }

  // Get selected values (useful for form submission)
  get selectedValues () {
    const checkboxes = this.element.querySelectorAll('input[type="checkbox"]:checked')
    return Array.from(checkboxes).map(cb => cb.value)
  }
}
