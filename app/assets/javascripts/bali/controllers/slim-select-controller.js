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
    try {
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

      // Remove DaisyUI select classes from the dropdown content to prevent centering
      // SlimSelect copies classes from the original select element, including DaisyUI's
      // 'select' and 'select-bordered' classes which cause centering issues.
      // Use DOM query since SlimSelect's internal API varies between versions.
      const contentEl = this.element.querySelector('.ss-content') ||
                        document.querySelector('.ss-content')
      if (contentEl) {
        contentEl.classList.remove('select', 'select-bordered')
      }
    } catch (error) {
      console.error('[SlimSelect] Failed to initialize:', error)
    }
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

    this.select.setSelected(allValues)

    if (this.hasSelectAllButtonTarget) {
      this.selectAllButtonTarget.classList.add('hidden')
    }
    if (this.hasDeselectAllButtonTarget) {
      this.deselectAllButtonTarget.classList.remove('hidden')
    }
  }

  deselectAll () {
    this.select.setSelected([])

    if (this.hasDeselectAllButtonTarget) {
      this.deselectAllButtonTarget.classList.add('hidden')
    }
    if (this.hasSelectAllButtonTarget) {
      this.selectAllButtonTarget.classList.remove('hidden')
    }
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
