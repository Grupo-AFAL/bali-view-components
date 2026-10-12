import { Controller } from '@hotwired/stimulus'
import { get, post } from '@rails/request.js'
import { topLayerHost, enterTopLayer, leaveTopLayer } from '../utils/top-layer.js'
import { optionalPeer } from '../utils/optional-peer.js'

// What a text value left unset falls back to, in the `lang` of the page. A select written by
// hand carries none of the values slim_select_fields.rb writes from
// `bali_view.form_builder.slim_select` (its TEXT_KEYS), so these are those same strings from
// config/locales/bali_view.{en,es}.yml, keyed by the value's name: slim_select_fields_test.rb
// fails when the two drift apart.
const TEXTS = {
  en: {
    placeholder: 'Select value',
    searchPlaceholder: 'Search',
    noResultsText: 'No results',
    searchingText: 'Searching...',
    resultsText: 'Results',
    ajaxPlaceholder: 'Type 2 chars to search...',
    maxValuesMessage: '{number} selected',
    addableText: 'Press "Enter" to add {value}',
    deselectText: 'Clear',
    removeText: 'Remove',
    resultsCountText: '{count} results available'
  },
  es: {
    placeholder: 'Selecciona una opción',
    searchPlaceholder: 'Buscar',
    noResultsText: 'Sin resultados',
    searchingText: 'Buscando...',
    resultsText: 'Resultados',
    ajaxPlaceholder: 'Escribe al menos 2 caracteres para buscar...',
    maxValuesMessage: '{number} seleccionados',
    addableText: 'Presiona "Enter" para agregar {value}',
    deselectText: 'Borrar selección',
    removeText: 'Quitar',
    resultsCountText: '{count} resultados disponibles'
  }
}

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
    noResultsText: String,
    searchingText: String,
    resultsText: String,
    maxValuesMessage: String,
    addableText: String,
    deselectText: String,
    removeText: String,
    // SlimSelect's `resultsText`: the name `resultsText` here already belongs to the label of
    // the remote results' group.
    resultsCountText: String,
    ajaxParamName: String,
    ajaxValueName: String,
    ajaxTextName: String,
    ajaxUrl: String,
    // What the remote search sends BESIDES the term (#1084). `ajaxExtraParams` is
    // the fixed scope, known at render time; `ajaxParamSelectors` is a
    // `parameter -> CSS selector` map that is READ ON EVERY SEARCH, which is what makes
    // a select that depends on another field of the form possible.
    ajaxExtraParams: Object,
    ajaxParamSelectors: Object,
    placeholder: String,
    ajaxPlaceholder: String,
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
    // this — `this.selectEl.dataset.ssid && this.destroy()` — but it is dead code in 3.4.3
    // and still in 4.5.0: `ssid` appears once in the whole bundle, at that read, and is never
    // written. So the two instances coexist, each with its own MutationObserver on the same
    // <select>, and the orphan reverts what the live one writes: the user picks an option,
    // the widget shows it, and the <select> that FormData serializes stays empty.
    const generation = (this.generation = (this.generation || 0) + 1)

    try {
      const slimSelect = await import('slim-select').catch(optionalPeer('slim-select'))
      if (!slimSelect) return
      const { default: SlimSelect } = slimSelect
      const texts = this.texts

      const options = {
        select: this.selectTarget,
        settings: {
          placeholderText: texts.placeholder,
          showSearch: this.showSearchValue,
          openPosition:
            this.showContentValue === 'undefined'
              ? 'down'
              : this.showContentValue,
          searchPlaceholder: texts.searchPlaceholder,
          closeOnSelect: this.closeOnSelectValue,
          allowDeselect: this.allowDeselectOptionValue,
          disabled: this.disabledValue,
          hideSelected: this.hideSelectedValue,
          searchHighlight: this.searchHighlightValue,
          searchText: texts.noResultsText,
          searchingText: texts.searchingText,
          maxValuesMessage: texts.maxValuesMessage,
          addableText: texts.addableText,
          deselectText: texts.deselectText,
          removeText: texts.removeText,
          resultsText: texts.resultsCountText,
          // 4.x opens the list as a modal below 768px by default, and slim_select.css has no
          // rules for `.ss-modal-*`: measured at 375px, the overlay stayed `position: static`
          // and 0px tall, the list 264px wide under a 343px trigger, and its options unpainted
          // beneath the search row.
          modal: 'off'
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

      // After the import, not before it: `teardown()` only ever looks at
      // `this.select`, so a listener registered while it is still null buys
      // nothing, and in an app without slim-select the early `return` above left
      // one attached to `document` for every connected select.
      this.beforeCacheHandler = () => this.teardown()
      document.addEventListener('turbo:before-cache', this.beforeCacheHandler)

      // Disable the select if disabled value is set
      // Note: settings.disabled in constructor doesn't work reliably,
      // so we call disable() explicitly after initialization
      if (this.disabledValue) {
        this.select.disable()
      }

      // Remove DaisyUI select classes from the dropdown content to prevent centering
      // SlimSelect copies classes from the original select element, including DaisyUI's
      // 'select' and 'select-bordered' classes which cause centering issues.
      const contentEl = this.select.render.content.main
      contentEl.classList.remove('select', 'select-bordered')

      // Propagate size variant class to dropdown content (it renders outside the wrapper)
      if (this.element.classList.contains('slim-select-sm')) {
        contentEl.classList.add('slim-select-sm-content')
      }

      this.forwardAccessibility()
      this.leavePlaceholderOutOfResults()
      this.joinTopLayerOnOpen()
    } catch (error) {
      console.error('[SlimSelect] Failed to initialize:', error)
    }
  }

  // Each text value as written on the element, or else the page language's, read off the
  // nearest `lang` as the browser does. A page without one, or in a language with no entry,
  // reads English.
  //
  // Present, not truthy: an empty value is kept. SlimSelect takes '' as "no placeholder" —
  // `placeholderText` is the one text setting it checks against `undefined` (3.4.3 to 4.6.0) — and
  // `slim_select_field placeholder: ""` writes exactly that. The other texts fall back to
  // SlimSelect's own through `||`.
  get texts () {
    const lang = this.element.closest('[lang]')?.lang.toLowerCase().split(/[-_]/)[0]
    const defaults = TEXTS[lang] || TEXTS.en

    return Object.fromEntries(
      Object.entries(defaults).map(([name, text]) => [
        name,
        this.data.has(`${name}Value`) ? this[`${name}Value`] : text
      ])
    )
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

  // SlimSelect hides the <select> behind `aria-hidden` and carries only its name over to the
  // combobox it draws, so the error and help ids the FormBuilder writes
  // (html_utils.rb#aria_attributes) sit on a node nobody reads. Copying them at connect is
  // enough: a form with errors comes back as a new render, with its own controller.
  //
  // Its listbox is labelled `ariaLabel + " listbox"` ("Combobox listbox" on every field), so
  // it gets the attributes that name the combobox. They are read off the combobox, not the
  // <select>: SlimSelect has already chosen among aria-label, aria-labelledby and, from 3.5,
  // the select's <label for>.
  forwardAccessibility () {
    const select = this.selectTarget
    const combobox = this.select.render.main.main
    const listbox = this.select.render.content.list

    for (const attribute of ['aria-describedby', 'aria-invalid']) {
      const value = select.getAttribute(attribute)
      if (value) combobox.setAttribute(attribute, value)
    }

    for (const attribute of ['aria-label', 'aria-labelledby']) {
      const value = combobox.getAttribute(attribute)
      if (value) listbox.setAttribute(attribute, value)
    }
  }

  // SlimSelect counts the placeholder among the results it reads out, though it draws it
  // hidden, and a remote search keeps it in the list because it is the selected option.
  // Measured on 4.5.0 and 4.6.0: a remote search with no matches left the list blank and read
  // out "1 results available", and four matches read "5". Reported upstream as
  // https://github.com/brianvoe/slim-select/issues/719 — this method goes once that is fixed.
  // A list holding nothing but the placeholder takes SlimSelect's own empty branch — "No
  // results", or the addable hint — as a select without one does. SlimSelect has already
  // rendered once while mounting, so a list that counted one is rendered again.
  //
  // `announce` is the one private member this touches: the count comes from the data handed
  // in, so a renamed internal cannot throw in here, ahead of `afterChange`.
  leavePlaceholderOutOfResults () {
    const render = this.select.render
    const renderOptions = render.renderOptions.bind(render)
    const optionsIn = data => data.flatMap(item => item.options || [item])

    render.renderOptions = data => {
      const options = optionsIn(data)
      const results = options.filter(option => !option.placeholder)
      if (results.length === 0) return renderOptions([])

      renderOptions(data)
      // `announce` arrived with the count, in 3.6.
      if (render.announce && results.length < options.length) {
        render.announce(this.select.settings.resultsText.replace('{count}', results.length))
      }
    }

    const data = this.select.store.getData(false)
    if (optionsIn(data).some(option => option.placeholder)) render.renderOptions(data)
  }

  // SlimSelect portals `.ss-content` to <body>, which a modal overlay both covers
  // and renders inert — see utils/top-layer.js for the hit-test that measured it.
  //
  // On each open, not at connect: a select rendered inside a closed Modal or Drawer connects
  // before `showModal()`, with no host to join — and so does one a Modal puts back on close,
  // when it restores the content it was rendered with.
  //
  // From `render.open()`, not SlimSelect's `beforeOpen`: `beforeOpen`, `afterOpen` and
  // `afterClose` are debounced by 100ms in 3.x and 4.x. Joined from `beforeOpen`, the list sat
  // under the dialog that long and its search box, focused while still inert, took no
  // keystroke. `Render#open` is public in SlimSelect's typings; a bump that stops routing
  // opens through it fails slim-select-in-dialog.cy.js, and nothing at runtime.
  //
  // Closed, the list is transparent and then `scaleY(0)`, so it stays joined until
  // `teardown()` rather than leaving from `afterClose`, which is as late and races a reopen.
  joinTopLayerOnOpen () {
    const render = this.select.render
    const open = render.open.bind(render)

    render.open = (...args) => {
      this.joinTopLayer()
      return open(...args)
    }
  }

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

  search = (search, currentData, catalog) => {
    // From 4.4 emptying the search box reaches this callback as well, and rejecting it shows
    // `ajaxPlaceholder` where the options were. The catalog is what 4.0–4.3 restored on their
    // own; 3.x never asks.
    if (search === '') return Promise.resolve(catalog)

    return new Promise((resolve, reject) => {
      if (search.length < 2) {
        return reject(this.texts.ajaxPlaceholder)
      }

      get(this.ajaxUrlValue, {
        query: {
          ...this.ajaxExtraParamsValue,
          ...this.dependentParams(),
          // The term goes LAST on purpose: an extra parameter named the same as
          // `ajaxParamName` is a call site mistake, and being left with no search is the
          // worst way to find out.
          [this.ajaxParamNameValue]: search
        },
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

          resolve([{ label: this.texts.resultsText, options }])
        })
    })
  }

  /**
   * The parameters that come from other fields, resolved at search time and not at
   * connect: the field they depend on changes afterwards, and that is the whole use case.
   *
   * An empty field sends no parameter rather than sending an empty one: `?type=` and `no
   * type` are two different questions on the server side, and "no narrowing" is the right
   * one when nothing is picked.
   *
   * A selector that matches nothing WARNS. It is exactly the failure mode this value
   * exists to remove: without the warning the filter silently stops narrowing and the
   * widget keeps working, returning the whole universe. Once per selector, since the
   * search runs on every keystroke.
   */
  dependentParams () {
    this.missingSelectors ||= new Set()

    return Object.entries(this.ajaxParamSelectorsValue).reduce((params, [key, selector]) => {
      const field = document.querySelector(selector)

      if (!field) {
        if (!this.missingSelectors.has(selector)) {
          this.missingSelectors.add(selector)
          console.warn(
            `slim-select: ajaxParamSelectors matched no element with "${selector}", ` +
            `so the remote search runs without the "${key}" parameter`
          )
        }
        return params
      }

      if (field.value !== '') params[key] = field.value

      return params
    }, {})
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
