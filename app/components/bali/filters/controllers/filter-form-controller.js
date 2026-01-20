import { Controller } from '@hotwired/stimulus'
import { queryParams } from 'bali/utils/form'

export class FilterFormController extends Controller {
  static values = { textField: String }
  static targets = ['removeButton', 'filterCounter']

  submit (e) {
    e.preventDefault()

    this.element.requestSubmit()
    this.updateButtons()
    this.updateUrl(document.title, this._buildURL())
  }

  // Toggle the remove filters button and display the number of active filters
  updateButtons () {
    const activeFilters = this.activeFilters()

    if (activeFilters.length > 0) {
      this.removeButtonTarget.classList.remove('is-hidden')
      this.filterCounterTarget.innerText = `(${activeFilters.length})`
    } else {
      this.removeButtonTarget.classList.add('is-hidden')
      this.filterCounterTarget.innerText = ''
    }
  }

  activeFilters () {
    const qParams = queryParams(this.element)

    // Don't consider the textField or the opened parameter active filters
    qParams.delete(`q[${this.textFieldValue}]`)
    qParams.delete('opened')

    const filterNames = [...qParams.entries()].map(entry => entry[0])

    // Return unique values
    return [...new Set(filterNames)]
  }

  updateUrl (title, url) {
    if (window.Turbo) {
      window.Turbo.session.history.push(url)

      // Makes the Back Button functional
      window.Turbo.session.pageBecameInteractive()
    } else {
      history.pushState({}, title, url.toString())
    }
  }

  _buildURL () {
    const url = new URL(this.element.getAttribute('action'), window.location.origin)
    for (const [key, value] of queryParams(this.element)) {
      url.searchParams.set(key, value)
    }

    return url
  }
}
