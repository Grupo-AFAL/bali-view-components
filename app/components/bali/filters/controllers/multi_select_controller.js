import { Controller } from '@hotwired/stimulus'

/**
 * Controller for multi-select dropdown in filters.
 * Uses custom dropdown with checkboxes for consistent styling.
 */
export class MultiSelectController extends Controller {
  static targets = ['trigger', 'label', 'dropdown']

  static values = {
    translations: { type: Object, default: {} }
  }

  /**
   * Getter for translations with fallback to empty object
   */
  get t () {
    return this.translationsValue || {}
  }

  connect () {
    this.updateLabel()
    this.boundCloseOnClickOutside = this.closeOnClickOutside.bind(this)
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('click', this.boundCloseOnClickOutside)
    this.element.addEventListener('keydown', this.boundHandleKeydown)
    this.focusedIndex = -1
  }

  disconnect () {
    document.removeEventListener('click', this.boundCloseOnClickOutside)
    this.element.removeEventListener('keydown', this.boundHandleKeydown)
  }

  /**
   * Handle keyboard navigation for accessibility (WCAG 2.1)
   */
  handleKeydown (event) {
    const checkboxes = this.getCheckboxes()
    if (checkboxes.length === 0) return

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.focusedIndex = Math.min(this.focusedIndex + 1, checkboxes.length - 1)
        checkboxes[this.focusedIndex]?.focus()
        break
      case 'ArrowUp':
        event.preventDefault()
        this.focusedIndex = Math.max(this.focusedIndex - 1, 0)
        checkboxes[this.focusedIndex]?.focus()
        break
      case 'Enter':
      case ' ':
        // Allow default checkbox behavior if a checkbox is focused
        if (document.activeElement?.type === 'checkbox') {
          // Enter doesn't toggle checkboxes by default, so we handle it
          if (event.key === 'Enter') {
            event.preventDefault()
            document.activeElement.checked = !document.activeElement.checked
            this.updateLabel()
          }
        }
        break
      case 'Escape':
        event.preventDefault()
        this.close()
        this.triggerTarget?.focus()
        break
    }
  }

  getCheckboxes () {
    return Array.from(this.element.querySelectorAll('input[type="checkbox"]'))
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

    // Get translated strings with fallbacks
    const selectValuesLabel = this.t.select_values || 'Select values...'
    const selectedCountTemplate = this.t.selected_count || '%{count} selected'

    if (labels.length === 0) {
      this.labelTarget.textContent = selectValuesLabel
      this.labelTarget.classList.add('text-base-content/50')
    } else if (labels.length <= 2) {
      this.labelTarget.textContent = labels.join(', ')
      this.labelTarget.classList.remove('text-base-content/50')
    } else {
      // Replace %{count} placeholder with actual count (Rails I18n style)
      this.labelTarget.textContent = selectedCountTemplate.replace('%{count}', labels.length)
      this.labelTarget.classList.remove('text-base-content/50')
    }
  }

  // Get selected values (useful for form submission)
  get selectedValues () {
    const checkboxes = this.element.querySelectorAll('input[type="checkbox"]:checked')
    return Array.from(checkboxes).map(cb => cb.value)
  }
}
