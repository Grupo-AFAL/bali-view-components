import { Controller } from '@hotwired/stimulus'

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
    allowDeselectOption: Boolean
  }

  static targets = ['select', 'selectAllButton', 'deselectAllButton']

  async connect () {
    const { default: SlimSelect } = await import('slim-select')

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
      addable: this.addable()
    }

    if (this.hasInnerHTML()) {
      options.data = this.dataWithHTML()
    }

    this.select = new SlimSelect(options)
  }

  disconnect () {
    // BUG: Destroy is causing an error because the slim instance is not
    // present in the document anymore. My assumption is that it has something
    // to do with Turbo snapshot caching.
    // this.select.destroy()

    // Remove event listeners setup by slim-select
    // https://github.com/brianvoe/slim-select/blob/master/src/slim-select/index.ts#L498
    document.removeEventListener('click', this.select.documentClick)
    if (this.select.config.showContent === 'auto') {
      window.removeEventListener('scroll', this.select.windowScroll, false)
    }
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
}
