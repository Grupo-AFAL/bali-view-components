import { Controller } from '@hotwired/stimulus'
import { get, post } from '@rails/request.js'

// TODO: Add tests (Issue: #157)
export class SlimSelectController extends Controller {
  static values = {
    addItems: Boolean,
    showContent: String,
    showSearch: Boolean,
    searchPlaceholder: String,
    addToBody: Boolean,
    closeOnSelect: Boolean,
    allowDeselectOption: Boolean,
    ajaxParamName: String,
    ajaxValueName: String,
    ajaxTextName: String,
    ajaxUrl: String,
    placeholder: { type: String, default: 'Select value' },
    ajaxPlaceholder: {
      type: String,
      default: 'Type 2 chars to search...'
    },
    afterChangeFetchUrl: String,
    afterChangeFetchMethod: { type: String, default: 'get' }
  }

  static targets = ['select', 'selectAllButton', 'deselectAllButton']

  async connect () {
    const { default: SlimSelect } = await import('slim-select')

    const options = {
      select: this.selectTarget,
      settings: {
        placeholderText: this.placeholderValue,
        showSearch: this.showSearchValue,
        openPosition:
          this.showContentValue === 'undefined' ? 'down' : this.showContentValue,
        searchPlaceholder: this.searchPlaceholderValue,
        closeOnSelect: this.closeOnSelectValue,
        allowDeselect: this.allowDeselectOptionValue
      },
      events: { }
    }

    if (this.hasInnerHTML()) {
      options.data = this.dataWithHTML()
    }

    if (this.hasAjaxValues()) {
      options.events.search = this.search
    }

    if (this.addItemsValue) {
      options.events.addable = (value) => value
    }

    if (this.hasAfterChangeFetchUrlValue) {
      options.events.afterChange = this.fetchAfterChange
    }

    this.select = new SlimSelect(options)
  }

  disconnect () {
    this.select?.destroy()
  }

  dataWithHTML () {
    return Array.from(this.selectTarget.children).map(option => {
      return {
        text: option.text,
        value: option.value,
        innerHTML: option.dataset.innerHtml,
        selected: option.selected,
        disabled: option.disabled
      }
    })
  }

  hasInnerHTML () {
    const firstOption = this.selectTarget.children[0]
    return firstOption && !!firstOption.dataset.innerHtml
  }

  selectAll () {
    const allValues = Array.from(this.selectTarget.children).map(
      option => option.value
    )

    this.select.set(allValues)
    this.selectAllButtonTarget.style.display = 'none'
    this.deselectAllButtonTarget.style.display = 'block'
  }

  deselectAll () {
    this.select.set([])
    this.deselectAllButtonTarget.style.display = 'none'
    this.selectAllButtonTarget.style.display = 'block'
  }

  search = (search, currentData) => {
    return new Promise((resolve, reject) => {
      if (search.length < 2) {
        return reject(this.ajaxPlaceholderValue)
      }

      get(
        this.ajaxUrlValue, { query: { [this.ajaxParamNameValue]: search }, responseKind: 'json' }
      ).then((response) => response.json)
        .then((data) => {
          const options = data.map(record => {
            return {
              text: record[this.ajaxTextNameValue],
              value: record[this.ajaxValueNameValue],
              html: record.html
            }
          })

          resolve(options)
        })
    })
  }

  hasAjaxValues () {
    return (
      this.hasAjaxParamNameValue &&
      this.hasAjaxValueNameValue &&
      this.hasAjaxTextNameValue &&
      this.hasAjaxUrlValue
    )
  }

  fetchAfterChange = (newValues) => {
    const params = { [this.select.select.select.name]: newValues.map(val => val.value) }

    // POST request is needed to send an array of values. With a GET request the multiple
    // values are sent as a serialized array string, instead of an actual array.
    if (this.afterChangeFetchMethodValue === 'post') {
      post(this.afterChangeFetchUrlValue, { body: params, responseKind: 'turbo-stream' })
    } else {
      get(this.afterChangeFetchUrlValue, { query: params, responseKind: 'turbo-stream' })
    }
  }
}
