import { Controller } from '@hotwired/stimulus'

/**
 * Manages user preference for filter persistence.
 *
 * When enabled, filters are saved and restored when returning to the page.
 * Stores preference in both localStorage and a cookie (for server-side access).
 *
 * Usage:
 * <div data-controller="filter-persistence"
 *      data-filter-persistence-storage-id-value="movies"
 *      data-filter-persistence-enabled-value="false">
 *   <button data-action="filter-persistence#toggle"
 *           data-filter-persistence-target="button">
 *     <span data-filter-persistence-target="iconEnabled" class="hidden">filled bookmark</span>
 *     <span data-filter-persistence-target="iconDisabled">outline bookmark</span>
 *   </button>
 * </div>
 */
export class FilterPersistenceController extends Controller {
  static targets = ['button', 'iconEnabled', 'iconDisabled']
  static values = {
    storageId: String,
    enabled: Boolean
  }

  connect () {
    // Initialize from localStorage (client-side source of truth)
    const stored = localStorage.getItem(this.storageKey)
    if (stored !== null) {
      this.enabledValue = stored === 'true'
    }
    this.updateUI()
    this.syncCookie()
  }

  toggle () {
    this.enabledValue = !this.enabledValue
    localStorage.setItem(this.storageKey, this.enabledValue.toString())
    this.syncCookie()
    this.updateUI()

    // Refresh page to apply the change
    // Use Turbo if available, otherwise standard reload
    if (window.Turbo) {
      window.Turbo.visit(window.location.href, { action: 'replace' })
    } else {
      window.location.reload()
    }
  }

  updateUI () {
    if (this.hasIconEnabledTarget && this.hasIconDisabledTarget) {
      if (this.enabledValue) {
        this.iconEnabledTarget.classList.remove('hidden')
        this.iconDisabledTarget.classList.add('hidden')
      } else {
        this.iconEnabledTarget.classList.add('hidden')
        this.iconDisabledTarget.classList.remove('hidden')
      }
    }

    // Update tooltip text
    if (this.hasButtonTarget) {
      const tooltip = this.enabledValue
        ? this.data.get('enabledTooltip') || 'Filter persistence enabled. Click to disable.'
        : this.data.get('disabledTooltip') || 'Filter persistence disabled. Click to enable.'
      this.buttonTarget.setAttribute('data-tip', tooltip)
    }
  }

  syncCookie () {
    // Set cookie for server-side access (expires in 1 year)
    const expires = new Date()
    expires.setFullYear(expires.getFullYear() + 1)
    document.cookie = `bali_persist_${this.storageIdValue}=${this.enabledValue ? '1' : '0'}; path=/; expires=${expires.toUTCString()}; SameSite=Lax`
  }

  get storageKey () {
    return `bali_filter_persist_${this.storageIdValue}`
  }
}
