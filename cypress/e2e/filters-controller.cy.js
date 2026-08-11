// Regression cover for #799: rendered without `search:`, the panel's Apply button did
// nothing at all — no request, no navigation, no message.
//
// `buildUrl()` read the quick-search form through `this.searchFormTarget`, a target that is
// only painted when the host configured a search, and `_submit()` builds the URL BEFORE
// calling `requestSubmit()`. So the "Missing target element" that Stimulus throws — and
// swallows — took the whole submission with it.
//
// The two halves of this file are the two configurations, and they visit different previews
// because that split is exactly how the bug survived: every Filters preview is wired
// WITHOUT a search, while the DataTable, where the panel is usually met, always brings one.
describe('FiltersController', () => {
  const applyButton = '[data-filters-target="form"] button[type="submit"]'
  const attribute = '[data-condition-target="attribute"]'
  const value = '[data-condition-target="value"]'
  const openPanel = () => cy.get('[data-filters-target="dropdown"] > button').click()

  // The value widget for a select attribute is a SlimSelect, which hides the real <select>
  // and renders its own trigger and option list next to it.
  const pickValue = (label) => {
    cy.get('[data-condition-target="valueContainer"] .ss-main').click()
    cy.get('.ss-content .ss-option').contains(label).click()
  }

  // The form is read at the moment it is submitted, with the navigation cancelled: a
  // preview URL does not answer a filtered GET, and this is the only place where what
  // actually travels can be observed. Cancelling also freezes the URL that `_submit()`
  // pushed just before, which is the other half of what is asserted here.
  const captureSubmission = () => {
    cy.window().then((win) => {
      win.__submitted = null
      const form = win.document.querySelector('[data-filters-target="form"]')
      form.addEventListener('submit', (event) => {
        event.preventDefault()
        win.__submitted = Array.from(new win.FormData(form))
      })
    })
  }

  // Only the filter state is asserted on: the listing's own params (`view`, `locale`, ...)
  // travel as hidden fields too and are not what this file is about.
  const filterParams = () =>
    cy.window().its('__submitted').then((entries) => entries.filter(([key]) => key.startsWith('q[')))

  context('without a quick search', () => {
    it('applies from the popover panel', () => {
      cy.visit('/bali/filters/default')
      openPanel()
      cy.get(attribute).select('name')
      cy.get(value).type('Alien')
      captureSubmission()

      cy.get(applyButton).click()

      filterParams().should('deep.equal', [
        ['q[g][0][m]', 'or'],
        ['q[g][0][name_cont]', 'Alien']
      ])
    })

    // The inline panel never had a quick search by design, so `popover: false` is the
    // configuration where a host meets this first.
    it('applies from the inline panel', () => {
      cy.visit('/bali/filters/default?popover=false')
      cy.get(attribute).select('name')
      cy.get(value).type('Alien')
      captureSubmission()

      cy.get(applyButton).click()

      filterParams().should('deep.equal', [
        ['q[g][0][m]', 'or'],
        ['q[g][0][name_cont]', 'Alien']
      ])
    })
  })

  context('with a quick search', () => {
    beforeEach(() => {
      cy.visit('/bali/data_table/complete')
      openPanel()
      cy.get(attribute).select('genre')
    })

    it('still applies', () => {
      pickValue('Drama')
      captureSubmission()

      cy.get(applyButton).click()

      filterParams().should('deep.equal', [
        ['q[g][0][m]', 'or'],
        ['q[g][0][genre_eq]', 'Drama']
      ])
    })

    // The user-facing half of #824 — the widget showed the new value while the <select> that
    // FormData serializes stayed empty, so Apply dropped the condition as unfilled and the
    // old rows came back. It is here for the behaviour, NOT as a guard: it passes against the
    // unfixed controller too, because reaching the panel this way never opens the race (the
    // dynamic import is already cached by then, so the `await` resolves in the same microtask).
    // The case below is the one that fails without the fix.
    it('carries a value the user changes his mind about', () => {
      pickValue('Drama')
      pickValue('Comedy')
      captureSubmission()

      cy.get(applyButton).click()

      filterParams().should('deep.equal', [
        ['q[g][0][m]', 'or'],
        ['q[g][0][genre_eq]', 'Comedy']
      ])
    })

    // The same defect from the widget's side, and the case that actually reproduces it: the
    // race needs the controller to disconnect while `connect()` is still awaiting its dynamic
    // import. Re-parenting the value container twice in a row is what the DataTable's toolbar
    // does on every overflow recalculation — the second move lands inside the window the
    // first one opened.
    it('keeps a single SlimSelect instance when the DOM moves under it', () => {
      cy.get('[data-condition-target="valueContainer"]').then(($container) => {
        const node = $container[0]
        const parent = node.parentNode
        const anchor = node.nextSibling

        parent.removeChild(node)
        parent.insertBefore(node, anchor)
        parent.removeChild(node)
        parent.insertBefore(node, anchor)
      })

      cy.get('[data-condition-target="valueContainer"] .ss-main').should('have.length', 1)
      cy.get('body > .ss-content').should('have.length', 1)
    })

    // #798 in the configuration this issue changed: a condition with no value stays out of
    // the request instead of travelling as a blank predicate the server drops in silence.
    it('still leaves a condition with no value out of the request', () => {
      captureSubmission()

      cy.get(applyButton).click()

      filterParams().should('deep.equal', [['q[g][0][m]', 'or']])
      cy.get('[data-condition-target="hint"]').should('have.class', 'is-shown')
    })
  })

  context('the URL it pushes', () => {
    // The dummy app lives above the Lookbook preview path `baseUrl` points at, so the
    // origin is derived from it rather than written out: a literal `http://localhost:3001`
    // ignores CYPRESS_BASE_URL and quietly tests another checkout's server from a worktree.
    const appOrigin = new URL(Cypress.config('baseUrl')).origin

    // A listing whose own URL carries params (`?locale=es` here) paints them as hidden
    // fields too, so appending the form on top of that URL wrote each of them twice. The
    // server keeps one, but the address bar is what the user copies and shares.
    it('does not repeat a param the listing URL already carries', () => {
      cy.visit(`${appOrigin}/admin/movies?locale=es`)
      openPanel()
      cy.get(attribute).select('name')
      cy.get(value).type('Alien')
      captureSubmission()

      cy.get(applyButton).click()

      cy.location('search').should((search) => {
        const params = new URLSearchParams(search)
        expect(params.getAll('locale')).to.deep.equal(['es'])
        expect(params.get('q[g][0][name_cont]')).to.equal('Alien')
      })
    })
  })
})

// #1013 — la misma familia que el drawer, en el panel: el `.ss-content` de un
// valor de tipo select se portalea a <body>, fuera del dropdown, así que
// `dropdownTarget.contains(target)` decía "afuera" y cerraba el panel al tocar
// el buscador del slim select. `closeOnClickOutside` ya excusaba el calendario
// de flatpickr por selector; el slim select se había quedado fuera de esa lista.
describe('FiltersController: widgets portaleados dentro del panel', () => {
  const panel = '[data-filters-target="dropdownContent"]'

  beforeEach(() => {
    // El widget de valor aparece al elegir un atributo de tipo select, y ahi es
    // donde el panel monta un slim-select (filters/condition/component.html.erb).
    cy.visit('/bali/data_table/complete')
    cy.get('[data-filters-target="dropdown"] > button').click()
    cy.get('[data-condition-target="attribute"]').select('genre')
    cy.get(panel).should('not.have.class', 'hidden')
  })

  it('keeps the panel open while searching in a slim select value', () => {
    cy.get('[data-condition-target="valueContainer"] .ss-main').click()
    cy.get('.ss-content .ss-search input').should('be.visible').click().type('a')

    cy.get(panel).should('not.have.class', 'hidden')
  })

  // El control: un click de verdad afuera sigue cerrando el panel.
  it('still closes on a real outside click', () => {
    cy.get('body').click('bottomRight')

    cy.get(panel).should('have.class', 'hidden')
  })
})
