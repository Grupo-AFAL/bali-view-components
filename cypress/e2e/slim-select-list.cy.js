// The list SlimSelect opens, as slim_select.css draws it. Bali does not load SlimSelect's own
// stylesheet, so whatever SlimSelect 4 renders that the stylesheet used to hide or lay out
// shows up unstyled — these pin the two pieces that did.
describe('SlimSelect list', () => {
  // 4.x opens the list as a modal below 768px unless told otherwise, and Bali has no rules
  // for `.ss-modal-*`: measured at 375px, no backdrop, a list narrower than the trigger and its
  // options unpainted under the search row — which still pass `be.visible`, so the overlay and
  // the geometry are what this checks.
  it('opens as a dropdown under the trigger on a phone', () => {
    cy.viewport(375, 720)
    cy.visit('/bali/form/slim_select/default')

    cy.get('.ss-main').click()

    cy.get('.ss-content.ss-open .ss-option').first().should('be.visible')
    cy.document().then(doc => {
      expect(doc.querySelector('.ss-modal-overlay'), 'SlimSelect modal overlay').to.equal(null)

      const trigger = doc.querySelector('.ss-main').getBoundingClientRect()
      const list = doc.querySelector('.ss-content.ss-open').getBoundingClientRect()
      expect(list.top, 'list top vs trigger bottom').to.be.within(trigger.bottom - 1, trigger.bottom + 12)
      expect(list.width, 'list width vs trigger width').to.be.closeTo(trigger.width, 1)
    })
  })

  // The list is portaled to <body>, so it is found through the trigger's `aria-controls`; a
  // lookup by class picks the first list on the page, which on a form with two densities
  // belongs to the other select.
  it('gives the compact class to the list of each compact select, and to no other', () => {
    cy.visit('/bali/form/sizes/comparison')

    cy.get('.slim-select .ss-main').should('have.length.at.least', 2)
    cy.get('.slim-select').should(wrappers => {
      const compact = wrappers.toArray().map(wrapper => {
        const listId = wrapper.querySelector('.ss-main').getAttribute('aria-controls')
        const content = wrapper.ownerDocument.getElementById(listId).closest('.ss-content')
        return [wrapper.classList.contains('slim-select-sm'), content.classList.contains('slim-select-sm-content')]
      })
      expect(compact.map(([select]) => select), 'compact selects on the page').to.include(true).and.include(false)
      compact.forEach(([select, list], i) => expect(list, `list ${i} compact like its select`).to.equal(select))
    })
  })

  // From 3.6 the list carries a live region (`.ss-status`) that reads out "5 results
  // available"; SlimSelect's stylesheet is what keeps it off screen.
  it('keeps the search-result announcement for screen readers only', () => {
    cy.visit('/bali/form/slim_select/default')

    cy.get('.ss-main').click()
    cy.get('.ss-content.ss-open .ss-search input').type('Option')

    cy.get('.ss-content.ss-open .ss-status').should($status => {
      const box = $status[0].getBoundingClientRect()
      expect($status.text(), 'announcement').to.not.equal('')
      expect(box.width, 'width').to.be.at.most(1)
      expect(box.height, 'height').to.be.at.most(1)
    })
  })

  // #1389 — a prompt is SlimSelect's placeholder: the selected option while nothing else is,
  // so a remote search keeps it in the list. SlimSelect draws it hidden and counted it anyway.
  describe('after a remote search, with a prompt', () => {
    const search = term => {
      cy.get('.ss-main').click()
      cy.get('.ss-content.ss-open .ss-search input').type(term)
      cy.wait('@remoteSearch')
    }

    beforeEach(() => {
      cy.intercept('GET', '/users.json*').as('remoteSearch')
      cy.visit('/bali/form/slim_select/remote_with_prompt')
    })

    // Before any search: SlimSelect's own render, while mounting, counted the prompt too.
    it('says there are no results before a search, with nothing but the prompt', () => {
      cy.get('.ss-main').click()

      cy.get('.ss-content.ss-open .ss-list .ss-search').should('have.text', 'No results')
    })

    it('says there are no results when the search finds none', () => {
      search('zz')

      cy.get('.ss-content.ss-open .ss-status').should('have.text', 'No results')
      cy.get('.ss-content.ss-open .ss-list .ss-search').should('have.text', 'No results')
    })

    // The dummy's /users.json has four names containing "jo".
    it('leaves the prompt out of the count it reads out', () => {
      search('jo')

      cy.get('.ss-content.ss-open .ss-option:not(.ss-hide)').should('have.length', 4)
      cy.get('.ss-content.ss-open .ss-status').should('have.text', '4 results available')
    })
  })

  // The dummy's /users.json answers its ids as JSON numbers, and 1 to 5 are also the values of
  // the seed's "Option 1" to "Option 5". Closing the list puts the seed back.
  describe('after a remote search that finds a value the seed has', () => {
    const search = term => {
      cy.get('.ss-main').click()
      cy.get('.ss-content.ss-open .ss-search input').type(term)
      cy.wait('@remoteSearch')
    }
    const close = () => {
      cy.get('.ss-content.ss-open .ss-search input').type('{esc}')
      cy.get('.ss-content.ss-open').should('not.exist')
    }
    // What `after_change_fetch_url` fetches on.
    const spyOnAfterChange = () =>
      cy.get('@select').then(([select]) => { select.slim.events.afterChange = cy.stub().as('afterChange') })
    // Then a real change: the spy hears the path it was just found silent on, so a SlimSelect
    // that stops reading `events` there cannot pass for silence.
    const expectNoAfterChange = () => {
      cy.get('@afterChange').should('not.have.been.called')
      cy.get('@select').then(([select]) => select.slim.setSelected('3'))
      cy.get('@afterChange').should('have.been.calledOnce')
    }

    beforeEach(() => {
      cy.intercept('GET', '/users.json*').as('remoteSearch')
      cy.visit('/bali/form/slim_select/remote')
      cy.get('select[name="form_record[name]"]').as('select').should('have.value', '1')
    })

    it('writes the chosen result into the <select> once', () => {
      search('jane')
      cy.contains('.ss-content.ss-open .ss-optgroup .ss-option', 'Jane Smith').click()
      cy.get('.ss-content.ss-open').should('not.exist')

      cy.get('@select').should($select => {
        expect($select.val()).to.equal('4')
        expect([...$select[0].options].map(option => option.value)).to.deep.equal(['1', '2', '3', '4', '5'])
      })
    })

    it('leaves the value alone on a search that finds the seeded one', () => {
      spyOnAfterChange()
      search('john')
      cy.contains('.ss-content.ss-open .ss-optgroup .ss-option', 'John Doe')
      close()

      expectNoAfterChange()
    })

    it('leaves the value alone on a search that finds the one chosen before', () => {
      search('peter')
      cy.contains('.ss-content.ss-open .ss-optgroup .ss-option', 'Peter Jackson').click()
      cy.get('.ss-content.ss-open').should('not.exist')
      spyOnAfterChange()
      search('peter')
      cy.contains('.ss-content.ss-open .ss-optgroup .ss-option', 'Peter Jackson')
      close()

      expectNoAfterChange()
    })
  })
})
