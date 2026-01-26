import { Controller } from '@hotwired/stimulus'
import { get } from '@rails/request.js'

/*
  Tabs controller
  It adds open and hide content actions to the tabs with active tab property.
  Allows to load content on demand from a given source on tab click.
  Supports keyboard navigation with arrow keys.
*/
export class TabsController extends Controller {
  static targets = ['tab', 'tabContent']

  connect () {
    if (!this.hasTabTarget) return

    this._loadActiveTabContent()
    this.element.addEventListener('keydown', this.handleKeydown)
  }

  disconnect () {
    this.element.removeEventListener('keydown', this.handleKeydown)
    // Cancel any pending request on disconnect
    this.pendingRequest?.abort()
  }

  handleKeydown = (event) => {
    if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return
    if (!this.tabTargets.includes(event.target)) return

    event.preventDefault()
    const currentIndex = this.tabTargets.indexOf(event.target)
    let newIndex

    switch (event.key) {
      case 'ArrowLeft':
        newIndex = currentIndex > 0 ? currentIndex - 1 : this.tabTargets.length - 1
        break
      case 'ArrowRight':
        newIndex = currentIndex < this.tabTargets.length - 1 ? currentIndex + 1 : 0
        break
      case 'Home':
        newIndex = 0
        break
      case 'End':
        newIndex = this.tabTargets.length - 1
        break
    }

    const newTab = this.tabTargets[newIndex]
    newTab.focus()
    this._hideAllTabs()
    this._openTab({ index: newIndex }, newTab)
  }

  open (event) {
    event.preventDefault()

    this._hideAllTabs()
    this._openTab(event.params, event.currentTarget)
  }

  _hideAllTabs () {
    this.tabContentTargets.forEach(tc => tc.classList.add('hidden'))
    this.tabTargets.forEach(t => {
      t.classList.remove('tab-active')
      t.setAttribute('aria-selected', 'false')
      t.setAttribute('tabindex', '-1')
    })
  }

  _openTab (params, tabElement) {
    const contentDiv = this.tabContentTargets.find(
      t => t.dataset.tabsIndexParam === params.index.toString()
    )

    contentDiv.classList.remove('hidden')
    tabElement.classList.add('tab-active')
    tabElement.setAttribute('aria-selected', 'true')
    tabElement.setAttribute('tabindex', '0')

    this._loadTabContent(tabElement, contentDiv, params)
  }

  _loadActiveTabContent () {
    const activeTab = this.tabTargets.find(t =>
      t.classList.contains('tab-active')
    )
    if (!activeTab) return

    const activeTabContent = this.tabContentTargets.find(
      t => t.dataset.tabsIndexParam === activeTab.dataset.tabsIndexParam
    )

    const src = activeTab.dataset.tabsSrcParam
    const reload = activeTab.dataset.tabsReloadParam

    this._loadTabContent(activeTab, activeTabContent, { src, reload })
  }

  async _loadTabContent (tabElement, tabContentDiv, { src, reload }) {
    if (!src) return

    const contentLoaded = tabElement.dataset.contentLoaded

    if (reload.toString() === 'false' && contentLoaded) return

    // Show loading spinner
    tabContentDiv.innerHTML = `
      <div class="flex items-center justify-center py-8">
        <span class="loading loading-spinner loading-lg"></span>
      </div>
    `

    // Cancel any pending request to prevent race conditions
    this.pendingRequest?.abort()
    this.pendingRequest = new AbortController()
    const { signal } = this.pendingRequest

    // Show loading spinner
    tabContentDiv.innerHTML = `
      <div class="flex items-center justify-center py-8">
        <span class="loading loading-spinner loading-lg"></span>
      </div>
    `

    try {
      const response = await get(src, { query: { layout: false }, signal })

      // Check if request was aborted before updating DOM
      if (signal.aborted) return

      if (response.ok) {
        const body = await response.text
        // Double-check abort status before updating DOM
        if (signal.aborted) return
        tabContentDiv.innerHTML = body
        tabElement.dataset.contentLoaded = true
      } else {
        tabContentDiv.innerHTML = `
          <div class="alert alert-error">
            <span>Failed to load content</span>
          </div>
        `
      }
    } catch (error) {
      // Ignore abort errors, they're expected when switching tabs rapidly
      if (error.name === 'AbortError') return
      throw error
    }
  }
}
