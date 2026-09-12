import { Controller } from '@hotwired/stimulus'

/**
 * Controller for individual filter conditions.
 * Handles attribute selection, operator changes, and dynamic value input rendering.
 */
export class ConditionController extends Controller {
  static targets = [
    'attribute',
    'operator',
    'valueContainer',
    'value',
    'rangeStart',
    'rangeEnd',
    'rangeInput',
    'attributeHidden',
    'operatorHidden',
    'hint'
  ]

  static values = {
    groupIndex: Number,
    index: Number,
    locale: { type: String, default: 'en' },
    translations: { type: Object, default: {} }
  }

  // Whether this row owes the user an explanation. A half-filled row says nothing while it
  // is still being filled in — only once it has lost a value, been checked by Apply, or
  // arrived incomplete from the server.
  flagged = false

  // Whether a value was ever chosen for the attribute currently selected.
  everHadValue = false

  /**
   * Getter for translations with fallback to empty object
   */
  get t () {
    return this.translationsValue || {}
  }

  connect () {
    // Value widgets are watched in the capture phase, on the condition root, rather than
    // with a data-action per input: SlimSelect reports a user's pick with a `change` event
    // that does NOT bubble, so a listener on an ancestor would never see it. Capture runs
    // on the way down to the target and is dispatched for non-bubbling events too.
    this.boundValueChanged = () => this.valueChanged()
    this.element.addEventListener('change', this.boundValueChanged, true)
    this.element.addEventListener('input', this.boundValueChanged, true)

    // A condition that ARRIVED incomplete came from a URL that no longer filters anything
    // (a bookmark written before #652, or a hand-edited query string). Say so straight
    // away — that one is not work in progress.
    this.everHadValue = this.hasValue()
    this.flagged = this.incomplete()
    this.refreshHint()
  }

  disconnect () {
    this.element.removeEventListener('change', this.boundValueChanged, true)
    this.element.removeEventListener('input', this.boundValueChanged, true)
  }

  /**
   * Any edit to the value widget. A row that HAD a value and no longer does now filters
   * nothing, and the list would come back wider than the user asked for without saying
   * why — so it starts explaining itself before Apply, while it can still be fixed.
   */
  valueChanged () {
    if (this.hasValue()) {
      this.everHadValue = true
    } else if (this.everHadValue) {
      this.flagged = true
    }

    this.refreshHint()
  }

  /**
   * Handle attribute selection change
   * Updates operators and value input based on the selected attribute type
   */
  attributeChanged (event) {
    const select = event.target
    const selectedOption = select.options[select.selectedIndex]
    const attributeKey = select.value
    const type = selectedOption?.dataset?.type || 'text'
    const options = this.parseOptions(selectedOption?.dataset?.options)
    const operators = this.parseOptions(selectedOption?.dataset?.operators)

    // Update hidden field
    if (this.hasAttributeHiddenTarget) {
      this.attributeHiddenTarget.value = attributeKey
    }

    // Update operators for this type (from data attribute or fallback)
    this.updateOperators(type, operators)

    // Get the current operator (may have changed)
    const operator = this.hasOperatorTarget ? this.operatorTarget.value : 'eq'
    const isMultiple = this.isMultipleOperator(operator)

    // Update value input for this type
    this.renderValueInput(type, attributeKey, options, isMultiple)

    // A different attribute is a fresh start: its option list is a different one, so
    // losing the previous value is correct and there is nothing to explain yet.
    this.everHadValue = false
    this.flagged = false

    // Update the field name
    this.updateFieldName()
    this.refreshHint()
  }

  /**
   * Handle operator selection change
   */
  operatorChanged (event) {
    const operator = event.target.value
    const selectedOption = event.target.options[event.target.selectedIndex]
    const isMultiple = selectedOption?.dataset?.multiple === 'true'
    const isRange = selectedOption?.dataset?.range === 'true'

    // Update hidden field
    if (this.hasOperatorHiddenTarget) {
      this.operatorHiddenTarget.value = operator
    }

    // Get current attribute info
    const attributeKey = this.hasAttributeTarget ? this.attributeTarget.value : ''
    const attributeOption = this.hasAttributeTarget
      ? this.attributeTarget.options[this.attributeTarget.selectedIndex]
      : null
    const type = attributeOption?.dataset?.type || 'text'
    const options = this.parseOptions(attributeOption?.dataset?.options)

    // Only rebuild the value input when the operator changes the WIDGET: single vs
    // multiple for a select, single vs range for a date. "is" -> "is not" keeps the same
    // widget over the same option list, so rebuilding it only threw the user's choice
    // away — and the empty condition then travelled as a blank Ransack predicate, which
    // the server discards without a word (#652).
    if (this.needsWidgetSwap(type, isMultiple, isRange)) {
      const hadValue = this.hasValue()
      const previous = this.selectedValues()
      this.renderValueInput(type, attributeKey, options, isMultiple, isRange)
      const kept = this.restoreSelectedValues(previous, isMultiple)
      // The swap dropped something the user had chosen. That IS the silent loss this
      // component was reported for, so the row owes an explanation from here on.
      if (hadValue && !kept) this.flagged = true
    }

    // Update the field name
    this.updateFieldName()
    this.refreshHint()
  }

  /**
   * Whether the new operator needs a different value widget than the one on screen.
   * The answer comes from the rendered DOM rather than from the previous operator, so a
   * server-rendered row and a JS-rendered one are read the same way.
   */
  needsWidgetSwap (type, isMultiple, isRange) {
    if (type === 'select') return isMultiple !== this.rendersMultiSelect()
    if (type === 'date' || type === 'datetime') return isRange !== this.rendersRange()
    return false
  }

  rendersMultiSelect () {
    return (
      this.hasValueContainerTarget &&
      !!this.valueContainerTarget.querySelector('[data-controller~="multi-select"]')
    )
  }

  rendersRange () {
    return this.hasRangeStartTarget
  }

  /**
   * The values chosen in this condition, as an array of strings: one entry for a single
   * widget, one per checked box for a multi-select. A range widget reports nothing —
   * a point in time and an interval are different kinds of value, so moving between
   * them starts over on purpose.
   */
  selectedValues () {
    if (!this.hasValueContainerTarget || this.rendersRange()) return []

    const checkboxes = this.valueContainerTarget.querySelectorAll('input[type="checkbox"]')
    if (checkboxes.length > 0) {
      return Array.from(checkboxes).filter((box) => box.checked).map((box) => box.value)
    }

    const input = this.valueContainerTarget.querySelector('select, input')
    return input && input.value !== '' ? [input.value] : []
  }

  /**
   * Re-apply values that survived a widget swap, and report whether they all made it.
   * Only a one-to-one mapping carries over: the single choice becomes the one checked
   * box and vice versa. Several checked boxes collapsing into a single select would
   * drop all but one, so they are dropped as a whole and the row is flagged instead.
   */
  restoreSelectedValues (values, isMultiple) {
    if (values.length === 0 || !this.hasValueContainerTarget || this.rendersRange()) {
      return false
    }

    if (isMultiple) {
      const checkboxes = this.valueContainerTarget.querySelectorAll('input[type="checkbox"]')
      if (checkboxes.length === 0) return false
      checkboxes.forEach((box) => { box.checked = values.includes(box.value) })
      return true
    }

    if (values.length > 1) return false

    const input = this.valueContainerTarget.querySelector('select, input')
    if (!input) return false
    input.value = values[0]
    // A select silently refuses a value it has no option for; report what actually stuck.
    return input.value === values[0]
  }

  /**
   * Remove this condition
   */
  remove (event) {
    event.preventDefault()
    event.stopPropagation() // Prevent dropdown from closing

    // Find the parent filter-group controller
    const filterGroupElement = this.element.closest('[data-controller~="filter-group"]')
    if (filterGroupElement) {
      const controller = this.application.getControllerForElementAndIdentifier(
        filterGroupElement,
        'filter-group'
      )
      controller?.removeCondition(this.element)
    }
  }

  /**
   * Reset this condition to default state
   */
  reset () {
    if (this.hasAttributeTarget) {
      this.attributeTarget.value = ''
    }
    if (this.hasOperatorTarget) {
      this.operatorTarget.value = 'cont'
    }
    if (this.hasValueTarget) {
      this.valueTarget.value = ''
    }
    if (this.hasAttributeHiddenTarget) {
      this.attributeHiddenTarget.value = ''
    }
    if (this.hasOperatorHiddenTarget) {
      this.operatorHiddenTarget.value = 'cont'
    }

    // Reset to text input
    this.renderValueInput('text', '', [], false)
    this.updateOperators('text')

    this.everHadValue = false
    this.flagged = false
    this.refreshHint()
  }

  /**
   * Check this row and let it explain itself from now on. Called when the user presses
   * Apply, which is the moment a condition that filters nothing becomes confusing.
   */
  validate () {
    this.flagged = true
    this.refreshHint()
  }

  /**
   * The named inputs that must be kept out of the submission. A condition with no
   * attribute names the `__ATTR__` placeholder, and one with no value serializes as a
   * blank Ransack predicate; both are discarded server-side without a word, and the
   * list comes back unfiltered with nothing on screen to explain it (#652).
   */
  unsubmittableInputs () {
    if (!this.hasValueContainerTarget || this.submittable()) return []

    return Array.from(this.valueContainerTarget.querySelectorAll('[name]'))
  }

  submittable () {
    return this.selectedAttribute() !== '' && this.hasValue()
  }

  /**
   * An attribute with no value: the row the user meant to fill and didn't. A row with no
   * attribute at all is not incomplete, it is simply empty, and saying so would nag.
   */
  incomplete () {
    return this.selectedAttribute() !== '' && !this.hasValue()
  }

  hasValue () {
    if (this.rendersRange()) {
      // `between` needs both ends. Half a range is a different filter, not a narrower
      // one, so it does not travel and the row says it is unfinished.
      return (
        !!this.rangeStartTarget.value &&
        this.hasRangeEndTarget &&
        !!this.rangeEndTarget.value
      )
    }

    return this.selectedValues().length > 0
  }

  selectedAttribute () {
    return this.hasAttributeTarget ? this.attributeTarget.value : ''
  }

  refreshHint () {
    if (!this.hasHintTarget) return

    this.hintTarget.classList.toggle('is-shown', this.flagged && this.incomplete())
  }

  /**
   * Sync the Flatpickr range dates to hidden fields for form submission.
   * Flatpickr range mode returns dates separated by " to " in the input value,
   * but we need separate _gteq and _lteq params for Ransack.
   */
  syncRangeDates (event) {
    const input = event.target
    // Get the Flatpickr instance to access selectedDates
    const flatpickr = input._flatpickr

    if (flatpickr && flatpickr.selectedDates.length === 2) {
      // Format dates as YYYY-MM-DD for Ransack
      const formatDate = (date) => {
        const year = date.getFullYear()
        const month = String(date.getMonth() + 1).padStart(2, '0')
        const day = String(date.getDate()).padStart(2, '0')
        return `${year}-${month}-${day}`
      }

      const startDate = formatDate(flatpickr.selectedDates[0])
      const endDate = formatDate(flatpickr.selectedDates[1])

      if (this.hasRangeStartTarget) {
        this.rangeStartTarget.value = startDate
      }
      if (this.hasRangeEndTarget) {
        this.rangeEndTarget.value = endDate
      }
    }

    // The capture-phase watcher already ran for this same event, before this action, so
    // it read the hidden fields as they were BEFORE the two lines above.
    this.refreshHint()
  }

  /**
   * Check if an operator requires multiple selection
   */
  isMultipleOperator (operator) {
    return ['in', 'not_in'].includes(operator)
  }

  /**
   * Check if an operator requires range inputs (start + end)
   */
  isRangeOperator (operator) {
    return operator === 'between'
  }

  /**
   * Update the operator dropdown based on attribute type
   * @param {string} type - The attribute type
   * @param {Array} operatorsFromData - Optional operators from data attribute (single source of truth)
   */
  updateOperators (type, operatorsFromData = null) {
    if (!this.hasOperatorTarget) return

    // Use operators from data attribute if provided, otherwise fall back to defaults
    const operators = operatorsFromData?.length > 0
      ? operatorsFromData
      : this.getOperatorsForType(type)
    const currentValue = this.operatorTarget.value

    this.operatorTarget.innerHTML = operators
      .map(
        (op) =>
          `<option value="${this.escapeHtml(op.value)}" data-multiple="${op.multiple || false}" data-range="${op.range || false}" ${op.value === currentValue ? 'selected' : ''}>${this.escapeHtml(op.label)}</option>`
      )
      .join('')

    // Select first operator if current isn't valid
    if (!operators.find((op) => op.value === currentValue)) {
      this.operatorTarget.value = operators[0]?.value || 'eq'
      if (this.hasOperatorHiddenTarget) {
        this.operatorHiddenTarget.value = this.operatorTarget.value
      }
    }
  }

  /**
   * Render the appropriate value input based on type
   */
  renderValueInput (type, attributeKey, options, isMultiple = false, isRange = false) {
    if (!this.hasValueContainerTarget) return

    const fieldName = this.buildFieldName(attributeKey)
    const rangeFieldNames = this.buildRangeFieldNames(attributeKey)
    let html = ''

    switch (type) {
      case 'select':
        html = isMultiple
          ? this.buildMultiSelectInput(fieldName, options)
          : this.buildSelectInput(fieldName, options)
        break
      case 'boolean':
        html = this.buildBooleanInput(fieldName)
        break
      case 'date':
        html = isRange
          ? this.buildDateRangeInput(rangeFieldNames)
          : this.buildDateInput(fieldName)
        break
      case 'datetime':
        html = isRange
          ? this.buildDatetimeRangeInput(rangeFieldNames)
          : this.buildDatetimeInput(fieldName)
        break
      case 'number':
        html = this.buildNumberInput(fieldName)
        break
      default:
        html = this.buildTextInput(fieldName)
    }

    this.valueContainerTarget.innerHTML = html

    // Initialize any Stimulus controllers in the new content
    this.initializeControllers()
  }

  /**
   * Initialize Stimulus controllers in dynamically added content.
   *
   * When HTML is inserted via innerHTML, Stimulus's MutationObserver detects
   * the new elements and connects controllers automatically. This method is
   * a placeholder for any additional initialization that may be needed.
   */
  initializeControllers () {
    // Stimulus's MutationObserver handles controller connection automatically.
    // No manual intervention needed - controllers connect when elements are
    // added to the DOM via innerHTML.
  }

  /**
   * Update the field name based on current attribute and operator
   */
  updateFieldName () {
    if (!this.hasValueContainerTarget) return

    const attribute = this.hasAttributeTarget ? this.attributeTarget.value : ''
    const operator = this.hasOperatorTarget ? this.operatorTarget.value : 'eq'
    const isMultiple = this.isMultipleOperator(operator)
    const isRange = this.isRangeOperator(operator)

    if (!attribute) return

    // For range operators (between), use gteq/lteq suffixes for start/end inputs
    if (isRange) {
      const rangeFieldNames = this.buildRangeFieldNames(attribute)
      if (this.hasRangeStartTarget) {
        this.rangeStartTarget.name = rangeFieldNames.start
      }
      if (this.hasRangeEndTarget) {
        this.rangeEndTarget.name = rangeFieldNames.end
      }
    } else {
      const fieldName = `q[g][${this.groupIndexValue}][${attribute}_${operator}]${isMultiple ? '[]' : ''}`

      // Update all value inputs
      this.valueContainerTarget.querySelectorAll('[name]').forEach((input) => {
        if (input.name.includes('q[g]')) {
          input.name = fieldName
        }
      })
    }
  }

  /**
   * Build the field name for the value input
   */
  buildFieldName (attributeKey) {
    const operator = this.hasOperatorTarget ? this.operatorTarget.value : 'eq'
    const isMultiple = this.isMultipleOperator(operator)

    if (attributeKey) {
      return `q[g][${this.groupIndexValue}][${attributeKey}_${operator}]${isMultiple ? '[]' : ''}`
    }
    return `q[g][${this.groupIndexValue}][__ATTR___${operator}]`
  }

  /**
   * Build field names for range inputs (between operator)
   * Returns { start: "..._gteq", end: "..._lteq" }
   */
  buildRangeFieldNames (attributeKey) {
    if (!attributeKey) {
      return {
        start: `q[g][${this.groupIndexValue}][__ATTR___gteq]`,
        end: `q[g][${this.groupIndexValue}][__ATTR___lteq]`
      }
    }
    return {
      start: `q[g][${this.groupIndexValue}][${attributeKey}_gteq]`,
      end: `q[g][${this.groupIndexValue}][${attributeKey}_lteq]`
    }
  }

  /**
   * Get operators for a given type.
   * Uses translations from Ruby if available, falls back to hardcoded defaults.
   */
  getOperatorsForType (type) {
    // Try to get operators from translations (provided by Ruby)
    const translatedOperators = this.t.operators?.[type]
    if (translatedOperators && translatedOperators.length > 0) {
      return translatedOperators
    }

    // Fallback to hardcoded defaults (English)
    const fallbackOperators = {
      text: [
        { value: 'cont', label: 'contains' },
        { value: 'eq', label: 'is exactly' },
        { value: 'start', label: 'starts with' },
        { value: 'end', label: 'ends with' },
        { value: 'not_cont', label: 'does not contain' },
        { value: 'not_eq', label: 'is not' }
      ],
      number: [
        { value: 'eq', label: '=' },
        { value: 'not_eq', label: '≠' },
        { value: 'gt', label: '>' },
        { value: 'lt', label: '<' },
        { value: 'gteq', label: '≥' },
        { value: 'lteq', label: '≤' }
      ],
      date: [
        { value: 'eq', label: 'is' },
        { value: 'between', label: 'between', range: true },
        { value: 'gt', label: 'after' },
        { value: 'lt', label: 'before' },
        { value: 'gteq', label: 'on or after' },
        { value: 'lteq', label: 'on or before' }
      ],
      datetime: [
        { value: 'eq', label: 'is' },
        { value: 'between', label: 'between', range: true },
        { value: 'gt', label: 'after' },
        { value: 'lt', label: 'before' },
        { value: 'gteq', label: 'on or after' },
        { value: 'lteq', label: 'on or before' }
      ],
      select: [
        { value: 'eq', label: 'is' },
        { value: 'not_eq', label: 'is not' },
        { value: 'in', label: 'is any of', multiple: true },
        { value: 'not_in', label: 'is not any of', multiple: true }
      ],
      boolean: [{ value: 'eq', label: 'is' }]
    }

    return fallbackOperators[type] || fallbackOperators.text
  }

  /**
   * Escape HTML to prevent XSS when inserting user-provided content
   */
  escapeHtml (text) {
    const map = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }
    return String(text).replace(/[&<>"']/g, ch => map[ch])
  }

  /**
   * Parse options from data attribute
   */
  parseOptions (optionsString) {
    if (!optionsString) return []
    try {
      return JSON.parse(optionsString)
    } catch {
      return []
    }
  }

  // Input builders

  buildTextInput (fieldName) {
    const placeholder = this.t.placeholders?.enter_value || 'Enter value...'
    return `
      <input type="text"
             class="input input-bordered input-sm w-full"
             name="${fieldName}"
             placeholder="${this.escapeHtml(placeholder)}"
             data-condition-target="value">
    `
  }

  buildNumberInput (fieldName) {
    const placeholder = this.t.placeholders?.number || '0'
    return `
      <input type="number"
             class="input input-bordered input-sm w-full"
             name="${fieldName}"
             step="any"
             placeholder="${this.escapeHtml(placeholder)}"
             data-condition-target="value">
    `
  }

  /**
   * Get concise date format based on locale
   * English: "M j, Y" → "Nov 1, 2025"
   * Spanish: "j M Y" → "1 nov 2025"
   */
  shortDateFormat () {
    return this.localeValue === 'es' ? 'j M Y' : 'M j, Y'
  }

  /**
   * Get concise datetime format based on locale
   * English: "M j, Y H:i" → "Nov 1, 2025 14:30"
   * Spanish: "j M Y H:i" → "1 nov 2025 14:30"
   */
  shortDatetimeFormat () {
    return this.localeValue === 'es' ? 'j M Y H:i' : 'M j, Y H:i'
  }

  buildDateInput (fieldName) {
    const placeholder = this.t.placeholders?.select_date || 'Select date...'
    return `
      <input type="text"
             class="input input-bordered input-sm w-full"
             name="${fieldName}"
             placeholder="${this.escapeHtml(placeholder)}"
             data-controller="datepicker"
             data-datepicker-locale-value="${this.localeValue}"
             data-datepicker-mode-value="single"
             data-datepicker-alt-format-value="${this.shortDateFormat()}"
             data-datepicker-alt-input-class-value="input input-bordered input-sm w-full"
             data-condition-target="value">
    `
  }

  buildDatetimeInput (fieldName) {
    const placeholder = this.t.placeholders?.select_datetime || 'Select date & time...'
    return `
      <input type="text"
             class="input input-bordered input-sm w-full"
             name="${fieldName}"
             placeholder="${this.escapeHtml(placeholder)}"
             data-controller="datepicker"
             data-datepicker-locale-value="${this.localeValue}"
             data-datepicker-mode-value="single"
             data-datepicker-enable-time-value="true"
             data-datepicker-alt-format-value="${this.shortDatetimeFormat()}"
             data-datepicker-alt-input-class-value="input input-bordered input-sm w-full"
             data-condition-target="value">
    `
  }

  buildDateRangeInput (rangeFieldNames) {
    const placeholder = this.t.placeholders?.select_date_range || 'Select date range...'
    return `
      <div class="w-full" data-condition-target="value">
        <input type="text"
               class="input input-bordered input-sm w-full"
               placeholder="${this.escapeHtml(placeholder)}"
               data-controller="datepicker"
               data-datepicker-locale-value="${this.localeValue}"
               data-datepicker-mode-value="range"
               data-datepicker-alt-format-value="${this.shortDateFormat()}"
               data-datepicker-alt-input-class-value="input input-bordered input-sm w-full"
               data-action="change->condition#syncRangeDates"
               data-condition-target="rangeInput">
        <input type="hidden" name="${rangeFieldNames.start}" data-condition-target="rangeStart">
        <input type="hidden" name="${rangeFieldNames.end}" data-condition-target="rangeEnd">
      </div>
    `
  }

  buildDatetimeRangeInput (rangeFieldNames) {
    const placeholder = this.t.placeholders?.select_datetime_range || 'Select date & time range...'
    return `
      <div class="w-full" data-condition-target="value">
        <input type="text"
               class="input input-bordered input-sm w-full"
               placeholder="${this.escapeHtml(placeholder)}"
               data-controller="datepicker"
               data-datepicker-locale-value="${this.localeValue}"
               data-datepicker-mode-value="range"
               data-datepicker-enable-time-value="true"
               data-datepicker-alt-format-value="${this.shortDatetimeFormat()}"
               data-datepicker-alt-input-class-value="input input-bordered input-sm w-full"
               data-action="change->condition#syncRangeDates"
               data-condition-target="rangeInput">
        <input type="hidden" name="${rangeFieldNames.start}" data-condition-target="rangeStart">
        <input type="hidden" name="${rangeFieldNames.end}" data-condition-target="rangeEnd">
      </div>
    `
  }

  buildBooleanInput (fieldName) {
    const anyLabel = this.t.boolean?.any || 'Any'
    const yesLabel = this.t.boolean?.yes || 'Yes'
    const noLabel = this.t.boolean?.no || 'No'
    return `
      <select class="select select-bordered select-sm w-full"
              name="${fieldName}"
              data-condition-target="value">
        <option value="">${this.escapeHtml(anyLabel)}</option>
        <option value="true">${this.escapeHtml(yesLabel)}</option>
        <option value="false">${this.escapeHtml(noLabel)}</option>
      </select>
    `
  }

  buildSelectInput (fieldName, options) {
    const placeholder = this.t.placeholders?.select || 'Select...'
    const searchPlaceholder = this.t.search || 'Buscar...'
    const optionsHtml = options
      .map((opt) => {
        const [label, value] = Array.isArray(opt) ? opt : [opt, opt]
        return `<option value="${this.escapeHtml(value)}">${this.escapeHtml(label)}</option>`
      })
      .join('')

    return `
      <div class="w-full slim-select-sm" data-controller="slim-select"
           data-slim-select-placeholder-value="${this.escapeHtml(placeholder)}"
           data-slim-select-search-placeholder-value="${this.escapeHtml(searchPlaceholder)}">
        <select class="select select-bordered select-sm w-full"
                name="${fieldName}"
                data-slim-select-target="select"
                data-condition-target="value">
          <option value="">${this.escapeHtml(placeholder)}</option>
          ${optionsHtml}
        </select>
      </div>
    `
  }

  buildMultiSelectInput (fieldName, options) {
    const selectValuesLabel = this.t.placeholders?.select_values || 'Select values...'
    const selectedCountTemplate = this.t.selected_count || '%{count} selected'
    const optionsHtml = options
      .map((opt) => {
        const [label, value] = Array.isArray(opt) ? opt : [opt, opt]
        const escapedLabel = this.escapeHtml(label)
        const escapedValue = this.escapeHtml(value)
        return `
          <label class="flex items-center gap-2 px-2 py-1.5 rounded hover:bg-base-200 cursor-pointer">
            <input type="checkbox"
                   class="checkbox checkbox-sm checkbox-primary"
                   name="${fieldName}"
                   value="${escapedValue}"
                   data-label="${escapedLabel}"
                   data-action="multi-select#updateSelection">
            <span class="text-sm">${escapedLabel}</span>
          </label>
        `
      })
      .join('')

    return `
      <div class="dropdown w-full"
           data-controller="multi-select"
           data-multi-select-translations-value='${JSON.stringify({
             select_values: selectValuesLabel,
             selected_count: selectedCountTemplate
           })}'
           data-condition-target="value">
        <div tabindex="0"
             role="button"
             class="select select-bordered select-sm w-full flex items-center"
             data-multi-select-target="trigger">
          <span class="flex-1 truncate text-left text-base-content/50" data-multi-select-target="label">
            ${this.escapeHtml(selectValuesLabel)}
          </span>
        </div>
        <div tabindex="0"
             class="dropdown-content filters-multi-select-content mt-1 p-2 shadow-lg bg-base-100 border border-base-300 rounded-lg w-full max-h-60 overflow-y-auto">
          ${optionsHtml}
        </div>
      </div>
    `
  }
}
