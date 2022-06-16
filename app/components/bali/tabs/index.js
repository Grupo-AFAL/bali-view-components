import { Controller } from '@hotwired/stimulus'

/*
  Tabs controller
  It adds open and hide content actions to the tabs with active tab property.
  Allows to load content on demand from a given source on tab click.
*/
export class TabsController extends Controller {
  connect () {
    this._loadActiveTabContent()
  }

  open (event) {
    event.preventDefault()
    const index = event.currentTarget.getAttribute('data-tab-index')

    this._hideAllTabs()
    this._openTab(index)
  }

  _hideAllTabs () {
    Array.from(this._allContents()).forEach(t => t.classList.add('is-hidden'))
    Array.from(this._allTabs()).forEach(t => t.classList.remove('is-active'))
  }

  _openTab (index) {
    const contentDiv = this.element.querySelector(
      `[data-content-index="${index}"]`
    )
    contentDiv.classList.remove('is-hidden')

    const tabLi = this.element.querySelector(`[data-tab-index="${index}"]`)
    tabLi.classList.add('is-active')

    this._loadTabContent(tabLi, contentDiv)
  }

  _loadActiveTabContent () {
    const activeTab = Array.from(this._allTabs()).find(t =>
      t.classList.contains('is-active')
    )
    const activeTabContent = this.element.querySelector(
      `[data-content-index="${activeTab.dataset.tabIndex}"]`
    )

    this._loadTabContent(activeTab, activeTabContent)
  }

  _loadTabContent (tabLi, tabContentDiv) {
    const url = tabLi.getAttribute('data-tab-src')

    if (!url) return

    const contentLoaded = tabLi.hasAttribute('data-tab-content-loaded')
    const reloadContent = tabLi.getAttribute('data-tab-reload-on-click')

    if (reloadContent === 'false' && contentLoaded) return

    fetch(this._buildURL(url))
      .then(r => r.text())
      .then(html => (tabContentDiv.innerHTML = html))
      .then(() => (tabLi.dataset.tabContentLoaded = true))
  }

  _allTabs () {
    return this.element.querySelectorAll('[data-tab-index]')
  }

  _allContents () {
    return this.element.querySelectorAll('[data-content-index]')
  }

  _buildURL = path => {
    const url = new URL(path, window.location.origin)
    url.searchParams.set('layout', 'false')

    return url.toString()
  }
}
