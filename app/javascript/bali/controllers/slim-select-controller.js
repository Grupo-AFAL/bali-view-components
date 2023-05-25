import { Controller } from '@hotwired/stimulus'
import { destroyWithCheck } from './slim-select-controller/destroy-with-check'
import { get } from '@rails/request.js'

// TODO: Add tests (Issue: #157)
export class SlimSelectController extends Controller {
  static values = {
    placeholder: String,
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
    ajaxPlaceholder: {
      type: String,
      default: 'Type 2 chars to search...'
    }
  }

  static targets = ['select', 'selectAllButton', 'deselectAllButton']

  async connect () {
    const { default: SlimSelect } = await import('slim-select')

    Object.assign(SlimSelect.prototype, {
      destroy: destroyWithCheck
    })

    const options = {
      select: this.selectTarget,
      placeholder: this.hasPlaceholderValue && this.placeholderValue,
      showContent:
        this.showContentValue === 'undefined' ? 'down' : this.showContentValue,
      showSearch: this.showSearchValue,
      searchPlaceholder: this.searchPlaceholderValue,
      addToBody: this.addToBodyValue,
      closeOnSelect: this.closeOnSelectValue,
      allowDeselectOption: this.allowDeselectOptionValue,
      addable: this.addable(),
      ajax: this.ajax()
    }

    if (this.hasInnerHTML()) {
      options.data = this.dataWithHTML()
    }

    this.select = new SlimSelect(options)
  }

  disconnect () {
    // BUG: Destroy is causing an error because the slim instance is not
    // present in the document anymore. My assumption is that it has something
    // to do with Turbo snapshot caching. Fix by overriding the destroy function
    // to check for the existance in the body before attempting to remove.
    //
    // https://github.com/brianvoe/slim-select/blob/master/src/slim-select/index.ts#L521
    this.select.destroy()
  }

  addable () {
    if (!this.addItemsValue) return

    return function (value) {
      return value
    }
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

  ajax () {
    if (!this.hasAjaxValues()) return

    return async (search, callback) => {
      if (search.length < 2) {
        return callback(this.ajaxPlaceholderValue)
      }

      const response = await get(this.ajaxUrlValue, {
        query: { [this.ajaxParamNameValue]: search },
        responseKind: 'json'
      })

      const json = await response.json
      const options = json.map(record => {
        return {
          text: record[this.ajaxTextNameValue],
          value: record[this.ajaxValueNameValue]
        }
      })

      callback(options.length > 0 ? options : false)
    }
  }

  hasAjaxValues () {
    return (
      this.hasAjaxParamNameValue &&
      this.hasAjaxValueNameValue &&
      this.hasAjaxTextNameValue &&
      this.hasAjaxUrlValue
    )
  }
}
