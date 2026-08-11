import { Controller } from '@hotwired/stimulus'

// Widgets the panel renders whose popup lives OUTSIDE it: flatpickr portals its
// calendar and SlimSelect its `.ss-content`, both to `<body>`, so
// `dropdownTarget.contains(target)` answers "outside" about a click the reader
// made on this panel's own controls. The calendar was excused here from the
// start; the slim select — which every select-type condition mounts — was not,
// so typing in its search box closed the panel (#1013, the same defect the
// Drawer had).
const PORTALED_POPUPS = '.flatpickr-calendar, .ss-content'

/**
 * Main controller for the Filters component.
 * Handles adding/removing groups, form submission, and URL management.
 */
export class FiltersController extends Controller {
  static targets = [
    'form',
    'groupsContainer',
    'groupTemplate',
    'group',
    'groupCombinator',
    'groupCombinatorToggle',
    'addGroupButton',
    'applyButton',
    'clearButton',
    'dropdown',
    'dropdownContent',
    'searchForm',
    'searchInput',
    'searchClearButton'
  ]

  static values = {
    url: String,
    attributes: Array,
    applyMode: { type: String, default: 'batch' },
    maxGroups: { type: Number, default: 10 },
    popover: { type: Boolean, default: true },
    translations: { type: Object, default: {} }
  }

  /**
   * Getter for translations with fallback to empty object
   */
  get t () {
    return this.translationsValue || {}
  }

  groupIndex = 0
  _dropdownOpen = false
  _currentAnimation = null

  connect () {
    // Initialize group index based on existing groups
    this.groupIndex = this.groupTargets.length

    // Update UI state
    this.updateAddGroupButton()

    // Sync dropdown state with DOM (in case of Turbo restoration)
    if (this.hasDropdownContentTarget) {
      this._dropdownOpen = !this.dropdownContentTarget.classList.contains('hidden')
    }

    // Handle clicks outside dropdown to close it (use window to catch clicks outside html element)
    if (this.popoverValue && this.hasDropdownTarget) {
      this.boundCloseOnClickOutside = this.closeOnClickOutside.bind(this)
      window.addEventListener('click', this.boundCloseOnClickOutside)

      // Close dropdown before Turbo caches the page (instant, no animation)
      this.boundCloseBeforeCache = () => this.closeDropdown(false)
      document.addEventListener('turbo:before-cache', this.boundCloseBeforeCache)
    }
  }

  disconnect () {
    this._cancelAnimation()
    if (this.boundCloseOnClickOutside) {
      window.removeEventListener('click', this.boundCloseOnClickOutside)
    }
    if (this.boundCloseBeforeCache) {
      document.removeEventListener('turbo:before-cache', this.boundCloseBeforeCache)
    }
  }

  /**
   * Toggle the dropdown open/closed with animation
   */
  toggleDropdown (event) {
    event.preventDefault()
    event.stopPropagation()

    if (this._dropdownOpen) {
      this.closeDropdown()
    } else {
      this.openDropdown()
    }
  }

  /**
   * Open the dropdown with animation
   */
  openDropdown () {
    if (!this.hasDropdownContentTarget || this._dropdownOpen) return
    this._dropdownOpen = true
    this._cancelAnimation()

    this.dropdownContentTarget.classList.remove('hidden')

    const inner = this.dropdownContentTarget.firstElementChild
    if (!inner) return

    const isMobile = window.matchMedia('(max-width: 639px)').matches

    if (isMobile) {
      this._currentAnimation = inner.animate(
        [{ transform: 'translateY(100%)' }, { transform: 'translateY(0)' }],
        { duration: 300, easing: 'cubic-bezier(0.32, 0.72, 0, 1)', fill: 'both' }
      )
    } else {
      inner.style.transformOrigin = 'top left'
      this._currentAnimation = inner.animate(
        [
          { opacity: 0, transform: 'scale(0.95) translateY(-4px)' },
          { opacity: 1, transform: 'scale(1) translateY(0)' }
        ],
        { duration: 150, easing: 'cubic-bezier(0.32, 0.72, 0, 1)', fill: 'both' }
      )
    }

    this._currentAnimation.onfinish = () => {
      this._currentAnimation.cancel()
      this._currentAnimation = null
      inner.style.transformOrigin = ''
    }
  }

  /**
   * Close the dropdown with animation
   * @param {boolean} animate - Set to false for instant close (e.g., Turbo cache)
   */
  closeDropdown (animate = true) {
    if (!this.hasDropdownContentTarget) return
    if (!this._dropdownOpen) {
      this.dropdownContentTarget.classList.add('hidden')
      return
    }
    this._dropdownOpen = false
    this._cancelAnimation()

    if (!animate) {
      this.dropdownContentTarget.classList.add('hidden')
      return
    }

    const inner = this.dropdownContentTarget.firstElementChild
    if (!inner) {
      this.dropdownContentTarget.classList.add('hidden')
      return
    }

    const isMobile = window.matchMedia('(max-width: 639px)').matches

    if (isMobile) {
      this._currentAnimation = inner.animate(
        [{ transform: 'translateY(0)' }, { transform: 'translateY(100%)' }],
        { duration: 200, easing: 'cubic-bezier(0.4, 0, 1, 1)', fill: 'forwards' }
      )
    } else {
      inner.style.transformOrigin = 'top left'
      this._currentAnimation = inner.animate(
        [
          { opacity: 1, transform: 'scale(1) translateY(0)' },
          { opacity: 0, transform: 'scale(0.95) translateY(-4px)' }
        ],
        { duration: 100, easing: 'ease-in', fill: 'forwards' }
      )
    }

    this._currentAnimation.onfinish = () => {
      this.dropdownContentTarget.classList.add('hidden')
      this._currentAnimation.cancel()
      this._currentAnimation = null
      inner.style.transformOrigin = ''
    }
  }

  /**
   * Close dropdown when clicking outside
   */
  closeOnClickOutside (event) {
    if (!this._dropdownOpen) {
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

    // Don't close on a widget whose popup renders outside the dropdown
    if (target.closest && target.closest(PORTALED_POPUPS)) {
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
    this._submit(this.formTarget)
  }

  /**
   * Submit search - submit the form
   */
  submitSearch (event) {
    event.preventDefault()
    this._submit(this.searchFormTarget)
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
   * Set the group combinator (AND/OR between groups)
   */
  setGroupCombinator (event) {
    event.preventDefault()
    event.stopPropagation()

    const newCombinator = event.currentTarget.dataset.combinator

    // Update all hidden inputs
    this.groupCombinatorTargets.forEach((input) => {
      input.value = newCombinator
    })

    // Update all toggle buttons
    this.groupCombinatorToggleTargets.forEach((toggle) => {
      this.updateGroupCombinatorToggle(toggle, newCombinator)
    })
  }

  /**
   * Update toggle button states for group combinator
   */
  updateGroupCombinatorToggle (container, combinator) {
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
   * Clear all filters and submit
   */
  clearAll (event) {
    event.preventDefault()
    this.clearFiltersAndClose()
  }

  /**
   * Clear filters, close dropdown, and navigate (can be called without event)
   */
  clearFiltersAndClose () {
    // Close the dropdown first
    this.closeDropdown()

    // Navigate to URL without filters (use Turbo.visit for proper navigation)
    const url = this.preservedParamsUrl()
    url.searchParams.set('clear_filters', 'true')

    if (window.Turbo) {
      window.Turbo.visit(url.toString(), { action: 'replace' })
    } else {
      window.location.href = url.toString()
    }
  }

  /**
   * URL base del listado CON los params que tienen que sobrevivir a limpiar (el modo de
   * visualización, la agrupación, y cualquier `preserved_params` del host). `urlValue` llega
   * sin query string, así que armar la URL solo con él tiraba esos params: limpiar la
   * búsqueda estando en tarjetas devolvía al usuario a la tabla. Viven como hidden fields del
   * form; los `q[...]` quedan afuera porque son justo lo que se está limpiando.
   */
  preservedParamsUrl () {
    const url = new URL(this.urlValue, window.location.origin)
    const form = this.hasSearchFormTarget
      ? this.searchFormTarget
      : (this.hasFormTarget ? this.formTarget : null)
    if (!form) return url

    for (const [key, value] of new FormData(form)) {
      if (key.startsWith('q[')) continue
      if (value && String(value).trim() !== '') url.searchParams.set(key, value)
    }

    return url
  }

  /**
   * Build the current URL with all filter params
   */
  buildUrl () {
    const url = new URL(this.urlValue, window.location.origin)
    const formData = new FormData(this.formTarget)
    // The quick-search form is only painted when the host passed `search:`. Reading the
    // target unguarded threw "Missing target element" right here, and since `_submit()`
    // builds the URL BEFORE calling `requestSubmit()`, that exception took the whole
    // submission with it: on a Filters without a search — every inline panel, by design —
    // Apply did nothing at all, silently (#799).
    const searchFormData = this.hasSearchFormTarget
      ? new FormData(this.searchFormTarget)
      : new FormData()

    // Clear existing q params
    for (const key of [...url.searchParams.keys()]) {
      if (key.startsWith('q[')) {
        url.searchParams.delete(key)
      }
    }

    // `urlValue` is the listing's URL and can already carry the very params both forms
    // paint as hidden fields (`locale`, `group_by`, `view`), so appending them left the
    // pushed URL saying `?locale=es&locale=es`. The server keeps one, but that URL is the
    // one the user copies. The FIRST write of a key drops whatever the base URL held for
    // it; the writes after it append, so a multi-value field keeps all of its values.
    const written = new Set()
    const append = (key, value) => {
      if (!value || value.trim() === '') return

      if (!written.has(key)) {
        url.searchParams.delete(key)
        written.add(key)
      }
      url.searchParams.append(key, value)
    }

    // Add form params (only non-empty values)
    for (const [key, value] of formData) {
      append(key, value)
    }

    // Add search-form params (only non-empty values). The applied filter state (q[g]/q[m])
    // also travels as hidden fields there so submitting a search keeps the filters — but the
    // popover form above is the authority when BOTH are present: appending the hidden copy
    // too made the pushed URL describe the PREVIOUS filter (last key wins on nested parse),
    // so an edited or removed condition came back on reload.
    //
    // El set se arma con TODAS las claves del form de arriba, no solo las `q[`: el estado del
    // listado (`group_by`, `view`) se pinta como hidden en los DOS forms, así que filtrando
    // solo las de filtro cada uno se agregaba dos veces y la URL que queda en la barra —la que
    // el usuario copia— decía `?group_by=genre&view=grid&group_by=genre&view=grid`.
    const filterKeys = new Set(formData.keys())
    for (const [key, value] of searchFormData) {
      if (filterKeys.has(key) || key.startsWith('q[g]') || key === 'q[m]') continue
      append(key, value)
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
   * Create a combinator divider element with toggle buttons
   */
  createCombinatorDivider () {
    // Get current combinator value from existing hidden input
    // The combinator is a two-value toggle. Normalize to a known value instead of
    // trusting the hidden input verbatim: its `.value` is the decoded `q[m]`, which the
    // server sanitizes but which also reaches this template literal — an unexpected value
    // would break out of the attribute. Anything that is not 'or' is 'and'.
    const currentCombinator =
      this.hasGroupCombinatorTarget && this.groupCombinatorTarget.value === 'or'
        ? 'or'
        : 'and'

    // Get translated labels with fallbacks
    const andLabel = this.t.combinators?.and || 'AND'
    const orLabel = this.t.combinators?.or || 'OR'

    const divider = document.createElement('div')
    divider.className = 'flex items-center justify-center gap-2 my-2'
    divider.innerHTML = `
      <div class="flex-1 border-t border-base-300"></div>
      <input type="hidden" name="q[m]" value="${currentCombinator}" data-filters-target="groupCombinator">
      <div class="join" data-filters-target="groupCombinatorToggle">
        <button type="button"
                class="join-item btn btn-xs w-10 ${currentCombinator === 'and' ? 'btn-primary' : 'btn-outline'}"
                data-action="filters#setGroupCombinator"
                data-combinator="and">
          ${andLabel}
        </button>
        <button type="button"
                class="join-item btn btn-xs w-10 ${currentCombinator === 'or' ? 'btn-primary' : 'btn-outline'}"
                data-action="filters#setGroupCombinator"
                data-combinator="or">
          ${orLabel}
        </button>
      </div>
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

  /**
   * Toggle the search clear button visibility based on input value
   */
  toggleSearchClear () {
    if (!this.hasSearchClearButtonTarget || !this.hasSearchInputTarget) {
      return
    }

    const hasValue = this.searchInputTarget.value.trim() !== ''
    this.searchClearButtonTarget.classList.toggle('hidden', !hasValue)
  }

  /**
   * Clear the search input and navigate with clear_search param
   */
  clearSearch (event) {
    event.preventDefault()

    if (!this.hasSearchInputTarget) {
      return
    }

    // Clear the input
    this.searchInputTarget.value = ''

    // Hide the clear button
    if (this.hasSearchClearButtonTarget) {
      this.searchClearButtonTarget.classList.add('hidden')
    }

    // Navigate to URL with clear_search param (bypasses persistence restore)
    // Use standard navigation to ensure fresh server response
    const url = this.preservedParamsUrl()
    url.searchParams.set('clear_search', 'true')

    // Use window.location for reliable navigation that avoids Turbo caching
    window.location.href = url.toString()
  }

  /**
   * Private: Submit a form, updating URL and history
   */
  _submit (form) {
    const restore = this._withoutUnsubmittableConditions()

    try {
      // Update URL for history
      const url = this.buildUrl()
      this.pushHistory(url)

      // Submit the form (Turbo will handle the response with morphing)
      form.requestSubmit()
    } finally {
      restore()
    }
  }

  /**
   * Private: keep the conditions that would filter nothing out of this submission, and
   * let each of them say so on screen.
   *
   * A condition with no value serializes as `q[g][0][genre_not_eq]=`, which Ransack drops
   * in silence: the list comes back complete, no error, no hint, and the user concludes
   * the filter is broken (#652). Disabling the inputs keeps them out of the request AND
   * out of the URL that is pushed alongside it, so the address bar and the response
   * finally describe the same query.
   *
   * The group combinator (`q[g][0][m]`) stays: it is not a predicate, and it is what tells
   * the server the user DID submit a filter set that happens to be empty. Dropping it too
   * would make an emptied panel look like a request that carried no filter state at all,
   * which a host with persistence on answers by restoring the previous filters.
   *
   * The inputs are restored right after `requestSubmit()` because both Turbo and the
   * browser build the form's entry list synchronously while the submit event is being
   * dispatched — and the panel is still on screen afterwards for the user to fix.
   *
   * @returns {Function} restores every input this disabled
   */
  _withoutUnsubmittableConditions () {
    const disabled = []
    const disable = (input) => {
      if (input.disabled) return
      input.disabled = true
      disabled.push(input)
    }

    this.element.querySelectorAll('[data-controller~="condition"]').forEach((element) => {
      const controller = this.application.getControllerForElementAndIdentifier(
        element,
        'condition'
      )
      controller?.validate()
      controller?.unsubmittableInputs().forEach(disable)
    })

    return () => disabled.forEach((input) => { input.disabled = false })
  }

  /**
   * Cancel any running dropdown animation
   */
  _cancelAnimation () {
    if (this._currentAnimation) {
      this._currentAnimation.cancel()
      this._currentAnimation = null
    }
  }
}
