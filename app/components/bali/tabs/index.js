import { Controller } from '@hotwired/stimulus'
import { get } from '@rails/request.js'

/*
  Tabs controller
  It adds open and hide content actions to the tabs with active tab property.
  Allows to load content on demand from a given source on tab click.
*/
export class TabsController extends Controller {
  static targets = ['tab', 'tabContent']

  connect () {
    this._loadActiveTabContent()
  }

  open (event) {
    event.preventDefault()

    this._hideAllTabs()
    this._openTab(event.params, event.currentTarget)
  }

  _hideAllTabs () {
    this.tabContentTargets.forEach(tc => tc.classList.add('is-hidden'))
    this.tabTargets.forEach(t => t.classList.remove('is-active'))
  }

  _openTab (params, tabLi) {
    const contentDiv = this.tabContentTargets.find(
      t => t.dataset.tabsIndexParam === params.index.toString()
    )

    contentDiv.classList.remove('is-hidden')
    tabLi.classList.add('is-active')

    this._loadTabContent(tabLi, contentDiv, params)
  }

  _loadActiveTabContent () {
    const activeTab = this.tabTargets.find(t =>
      t.classList.contains('is-active')
    )
    const activeTabContent = this.tabContentTargets.find(
      t => t.dataset.tabsIndexParam === activeTab.dataset.tabsIndexParam
    )

    const src = activeTab.dataset.tabsSrcParam
    const reload = activeTab.dataset.tabsReloadParam

    this._loadTabContent(activeTab, activeTabContent, { src, reload })
  }

  async _loadTabContent (tabLi, tabContentDiv, { src, reload }) {
    if (!src) return

    const contentLoaded = tabLi.dataset.contentLoaded

    if (reload.toString() === 'false' && contentLoaded) return

    const response = await get(src, { query: { layout: false } })
    if (response.ok) {
      const body = await response.text
      tabContentDiv.innerHTML = body
      tabLi.dataset.contentLoaded = true
    }
  }
}
