import { Controller } from '@hotwired/stimulus'
import { get, post } from '@rails/request.js'
import { topLayerHost, enterTopLayer, leaveTopLayer } from '../utils/top-layer.js'

export class SlimSelectController extends Controller {
  static values = {
    addItems: Boolean,
    showContent: String,
    showSearch: { type: Boolean, default: true },
    searchPlaceholder: String,
    addToBody: Boolean,
    closeOnSelect: { type: Boolean, default: true },
    allowDeselectOption: Boolean,
    disabled: Boolean,
    hideSelected: Boolean,
    searchHighlight: Boolean,
    noResultsText: { type: String, default: 'No results' },
    searchingText: { type: String, default: 'Searching...' },
    resultsText: { type: String, default: 'Results' },
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
    afterChangeFetchMethod: { type: String, default: 'get' },
    contentWidth: String
  }

  static targets = ['select', 'selectAllButton', 'deselectAllButton']

  async connect () {
    // A Turbo restoration visit (back/forward, or navigating to an already
    // cached page) replays a snapshot that was captured while this controller
    // was still connected, so it already contains the `.ss-main` widget
    // SlimSelect injected. Re-initializing on top of it would stack a second,
    // event-less widget over the dead cached one — the visible select then
    // neither filters on search nor selects on click. Drop any stale widget
    // before (re)initializing, and tear SlimSelect down again right before
    // Turbo caches the page so the stored snapshot stays clean.
    this.removeStaleWidget()

    // `connect()` is async, and the `await` below is a window in which Stimulus can
    // disconnect this controller — any DOM move does it, and the DataTable toolbar moves its
    // items on every overflow recalculation. A `teardown()` inside that window destroys
    // `this.select`, which is still null, so it destroys nothing; the in-flight `connect()`
    // then finishes and builds an instance nobody owns. SlimSelect ships a guard for exactly
    // this — `this.selectEl.dataset.ssid && this.destroy()` — but it is dead code in 3.4.3:
    // `ssid` appears once in the whole bundle, at that read, and is never written. So the two
    // instances coexist, each with its own MutationObserver on the same <select>, and the
    // orphan reverts what the live one writes: the user picks an option, the widget shows it,
    // and the <select> that FormData serializes stays empty.
    const generation = (this.generation = (this.generation || 0) + 1)

    this.beforeCacheHandler = () => this.teardown()
    document.addEventListener('turbo:before-cache', this.beforeCacheHandler)

    try {
      const { default: SlimSelect } = await import('slim-select')

      const options = {
        select: this.selectTarget,
        settings: {
          placeholderText: this.placeholderValue,
          showSearch: this.showSearchValue,
          openPosition:
            this.showContentValue === 'undefined'
              ? 'down'
              : this.showContentValue,
          searchPlaceholder: this.searchPlaceholderValue,
          closeOnSelect: this.closeOnSelectValue,
          allowDeselect: this.allowDeselectOptionValue,
          disabled: this.disabledValue,
          hideSelected: this.hideSelectedValue,
          searchHighlight: this.searchHighlightValue,
          searchText: this.noResultsTextValue,
          searchingText: this.searchingTextValue
        },
        events: {}
      }

      if (this.hasContentWidthValue && this.contentWidthValue) {
        options.settings.contentWidth = this.contentWidthValue
      }

      if (this.hasInnerHTML()) {
        options.data = this.dataWithHTML()
      }

      if (this.hasAjaxValues()) {
        options.events.search = this.search
      }

      if (this.addItemsValue) {
        options.events.addable = value => value
      }

      if (this.hasAfterChangeFetchUrlValue) {
        options.events.afterChange = this.fetchAfterChange
      }

      const instance = new SlimSelect(options)

      // The controller disconnected while the import was in flight: this instance belongs to
      // nobody, and leaving it alive is what corrupts the <select>. Destroying it here is the
      // only chance to — `teardown()` already ran, and it only ever looks at `this.select`.
      if (generation !== this.generation) {
        instance.destroy()
        return
      }

      this.select = instance

      // Disable the select if disabled value is set
      // Note: settings.disabled in constructor doesn't work reliably,
      // so we call disable() explicitly after initialization
      if (this.disabledValue) {
        this.select.disable()
      }

      // Remove DaisyUI select classes from the dropdown content to prevent centering
      // SlimSelect copies classes from the original select element, including DaisyUI's
      // 'select' and 'select-bordered' classes which cause centering issues.
      // Use DOM query since SlimSelect's internal API varies between versions.
      const contentEl =
        this.element.querySelector('.ss-content') ||
        document.querySelector('.ss-content')
      if (contentEl) {
        contentEl.classList.remove('select', 'select-bordered')

        // Propagate size variant class to dropdown content (it may render outside the wrapper)
        if (this.element.classList.contains('slim-select-sm')) {
          contentEl.classList.add('slim-select-sm-content')
        }
      }

      this.joinTopLayer()
    } catch (error) {
      console.error('[SlimSelect] Failed to initialize:', error)
    }
  }

  disconnect () {
    // Bumped before `teardown()` so an in-flight `connect()` sees a stale generation and
    // destroys the instance it is about to build, instead of leaving it observing the
    // <select> forever.
    this.generation = (this.generation || 0) + 1

    if (this.beforeCacheHandler) {
      document.removeEventListener('turbo:before-cache', this.beforeCacheHandler)
      this.beforeCacheHandler = null
    }
    this.teardown()
  }

  // SlimSelect portals `.ss-content` to <body>, which a modal overlay both covers
  // and renders inert — see utils/top-layer.js for the hit-test that measured it.
  //
  // Done once, at connect, rather than on each open: SlimSelect debounces all
  // four of its open/close callbacks by 100ms, so a hook that reparents there
  // fires long after the list is already on screen and clickable. The list is
  // parked at `top: -9999px` while closed, so leaving it in the top layer for the
  // widget's lifetime shows nothing; when the overlay closes it takes its
  // contents with it, and `teardown()` removes the node either way.
  //
  // Reads the list off the instance rather than off the DOM: the class-fixing
  // lookup above falls back to the first `.ss-content` in the document, which on
  // a page with several selects is somebody else's, and relocating that one would
  // be a good deal worse than mislabelling it.
  joinTopLayer () {
    const contentEl = this.select?.render?.content?.main
    const host = contentEl && topLayerHost(this.element)

    if (host) enterTopLayer(contentEl, host)
  }

  teardown () {
    leaveTopLayer(this.select?.render?.content?.main)

    this.select?.destroy()
    this.select = null
  }

  // Remove a SlimSelect widget left behind in a restored Turbo snapshot. The
  // original <select> (SlimSelect's target) is intentionally preserved so a
  // fresh instance can attach to it on connect.
  removeStaleWidget () {
    this.element
      .querySelectorAll('.ss-main')
      .forEach(widget => widget.remove())
  }

  dataWithHTML () {
    return Array.from(this.selectTarget.children).map(option => {
      return {
        text: option.text,
        value: option.value,
        html: option.dataset.innerHtml, // SlimSelect v3 uses 'html' instead of 'innerHTML'
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

      get(this.ajaxUrlValue, {
        query: { [this.ajaxParamNameValue]: search },
        responseKind: 'json'
      })
        .then(response => response.json)
        .then(data => {
          const options = data.map(record => {
            return {
              text: record[this.ajaxTextNameValue],
              value: record[this.ajaxValueNameValue],
              html: record.html
            }
          })

          resolve([{ label: this.resultsTextValue, options }])
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

  fetchAfterChange = newValues => {
    const params = {
      [this.select.select.select.name]: newValues.map(val => val.value)
    }

    // POST request is needed to send an array of values. With a GET request the multiple
    // values are sent as a serialized array string, instead of an actual array.
    if (this.afterChangeFetchMethodValue === 'post') {
      post(this.afterChangeFetchUrlValue, {
        body: params,
        responseKind: 'turbo-stream'
      })
    } else {
      get(this.afterChangeFetchUrlValue, {
        query: params,
        responseKind: 'turbo-stream'
      })
    }
  }
}
