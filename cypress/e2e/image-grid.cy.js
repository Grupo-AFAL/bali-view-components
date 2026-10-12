// #1041 — ImageGrid had no E2E spec. With `expandable: true` each thumbnail
// opens a lightbox that exists nowhere in the markup: the controller builds the
// overlay, moves it to the top layer, loads the full-size image and takes over
// the page — scroll locked, Escape closing it, focus put back where it was. All
// of that is only observable in a browser.
describe('ImageGrid lightbox', () => {
  const overlay = () => cy.get('.bali-image-expander-overlay')
  const thumbnails = () => cy.get('[data-controller="image-expander"]')

  beforeEach(() => {
    // The sample images are remote; serving them from a fixture keeps the run
    // off the network and makes `onload` fire on a schedule.
    cy.intercept('GET', 'https://placehold.co/**', { fixture: 'sample-image.png' }).as('image')
    cy.visit('/bali/image_grid/expandable')
  })

  it('opens the full-size image in a dialog', () => {
    overlay().should('not.exist')

    thumbnails().first().click()

    overlay().should('exist')
    overlay().should('have.attr', 'role', 'dialog')
    overlay().should('have.attr', 'aria-modal', 'true')
    // `full_src:`, not the thumbnail's own src.
    overlay().find('img').should('have.attr', 'src', 'https://placehold.co/1600x1067?text=Full+1')
    // The alt travels with it: the lightbox is the same picture, larger.
    overlay().find('img').should('have.attr', 'alt', 'Sample image 1')
  })

  it('locks the page behind it and gives the close button the focus', () => {
    thumbnails().first().click()

    cy.get('body').should('have.css', 'overflow', 'hidden')
    cy.focused().should('have.class', 'bali-image-expander-close')
  })

  it('closes with Escape and gives the focus back', () => {
    thumbnails().eq(2).click()
    overlay().should('exist')

    cy.get('body').type('{esc}')

    overlay().should('not.exist')
    cy.get('body').should('not.have.css', 'overflow', 'hidden')
    // Back on the thumbnail that opened it, not lost at the top of the page.
    cy.focused().should('have.attr', 'data-image-expander-src-value', 'https://placehold.co/1600x1067?text=Full+3')
  })

  it('closes from the close button', () => {
    thumbnails().first().click()

    cy.get('.bali-image-expander-close').click()

    overlay().should('not.exist')
  })

  it('closes on a click outside the picture but not on the picture itself', () => {
    thumbnails().first().click()
    overlay().find('img').should('exist')

    overlay().find('img').click()
    overlay().should('exist')

    // The backdrop is the overlay itself; a corner is guaranteed to miss the image.
    overlay().click('topLeft')
    overlay().should('not.exist')
  })

  it('says so when the image cannot be loaded', () => {
    cy.intercept('GET', 'https://placehold.co/1600x1067**', { statusCode: 500, body: '' }).as('broken')
    cy.visit('/bali/image_grid/expandable')

    thumbnails().first().click()

    overlay().find('.bali-image-expander-error').should('contain.text', 'Could not load image')
  })

  // #1428 — the spinner and the error are written by the controller, so they need the page
  // language handed to them: Bali's translations from ImageGrid, or else the `lang` of the page
  // around a trigger a host wrote by hand.
  describe('in the language of the page', () => {
    // The spinner lives as long as the request is held, so its assertion has to give up before
    // the request is answered: past that, a wrong label reads as a spinner that never existed.
    const openBroken = () => {
      cy.intercept('GET', 'https://placehold.co/1600x1067**', { statusCode: 500, body: '', delay: 3000 })
      thumbnails().first().click()
    }
    const expectSpanish = () => {
      overlay().find('.bali-image-expander-spinner', { timeout: 2000 }).should('have.attr', 'aria-label', 'Cargando')
      overlay().find('.bali-image-expander-error').should('have.text', 'No se pudo cargar la imagen')
    }

    it('from ImageGrid', () => {
      cy.visit('/bali/image_grid/expandable?locale=es')
      // The preview layout writes `lang` too; without it, only ImageGrid's translations speak Spanish.
      cy.document().then((doc) => doc.documentElement.removeAttribute('lang'))
      openBroken()

      expectSpanish()
    })

    it('from a trigger with no translations', () => {
      cy.visit('/bali/image_grid/expandable?locale=es')
      thumbnails().first().invoke('removeAttr', 'data-image-expander-translations-value')
      openBroken()

      expectSpanish()
    })
  })

  it('leaves a plain grid alone', () => {
    cy.visit('/bali/image_grid/default')

    // Without `expandable` the images are figures, not buttons: nothing to
    // click, and no controller waiting for a click.
    cy.get('[data-controller="image-expander"]').should('not.exist')
    cy.get('figure').should('have.length.greaterThan', 0)
  })

  // #1391 — inside a Drawer or Modal the lightbox is a popover, and the browser's
  // `[popover] { width/height: fit-content }` beat its `inset-0`: a box the size of
  // the photo in the top-left corner.
  describe('covering the window', () => {
    // The viewport without its scrollbar, which is what `inset: 0` covers.
    const expectWholeWindow = ($overlay) => {
      const { clientWidth, clientHeight } = $overlay[0].ownerDocument.documentElement
      const { x, y, width, height } = $overlay[0].getBoundingClientRect()

      expect({ x, y, width, height }).to.deep.equal({ x: 0, y: 0, width: clientWidth, height: clientHeight })
    }

    it('from a page', () => {
      thumbnails().first().click()

      overlay().should(expectWholeWindow)
    })

    ;['drawer', 'modal'].forEach((panel) => {
      it(`from a ${panel}`, () => {
        cy.visit(`/bali/image_grid/in_overlay?overlay=${panel}`)

        thumbnails().first().click()

        // The popover path, or this measures the page case again.
        overlay().should(($overlay) => {
          expect($overlay[0].parentElement.tagName, 'parent').to.equal('DIALOG')
          expect($overlay[0].matches(':popover-open'), ':popover-open').to.equal(true)
        })
        overlay().should(expectWholeWindow)
      })
    })
  })
})
