import { Controller } from '@hotwired/stimulus'

/*
  Tabs controller
  It generates a tabs component with open and hide content actions
  with active tab property.
*/
export class TabsController extends Controller {
  connect () {
    this._loadActiveTabContent()
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

  _loadTabContent (tabLi, tabContentDiv) {
    if (tabContentDiv.innerHTML !== '\n') return

    const urlValue = tabLi.querySelector('a').getAttribute('href')

    if (urlValue) {
      fetch(urlValue)
        .then(r => r.text())
        .then(html => (tabContentDiv.innerHTML = html))
    }
  }

  _allTabs () {
    return this.element.querySelectorAll('[data-tab-index]')
  }

  _allContents () {
    return this.element.querySelectorAll('[data-content-index]')
  }
}
