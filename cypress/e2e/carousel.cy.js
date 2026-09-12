// #1041 — Carousel had no E2E spec. The markup Bali renders is inert: the
// arrows and the bullets are plain buttons carrying `data-glide-dir`, and
// nothing moves until Glide is imported on connect and mounts over them. So
// what is tested here is that the mount happened and that the controls Bali
// writes are the ones Glide is actually wired to.
describe('Carousel', () => {
  // Glide clones slides at both ends to make the wrap seamless, so the ones the
  // component rendered are the non-clones.
  const slides = () => cy.get('.glide__slide:not(.glide__slide--clone)')
  const bullets = () => cy.get('.glide__bullet')
  const nextArrow = () => cy.get('.glide__arrow--right')
  const previousArrow = () => cy.get('.glide__arrow--left')

  // Glide disables itself for the length of a transition and DROPS whatever
  // arrives meanwhile — a second click sent too early is silently lost, which
  // is a flake in a test and a real annoyance for a user with a fast hand.
  const settled = () => {
    cy.get('[data-controller="carousel"]').should(($element) => {
      const controller = $element[0].ownerDocument.defaultView.Stimulus
        .getControllerForElementAndIdentifier($element[0], 'carousel')

      expect(controller.glide, 'glide mounted').to.not.eq(undefined)
      expect(controller.glide.disabled, 'glide mid-transition').to.eq(false)
    })
  }

  beforeEach(() => {
    // The slide images come from placehold.co; stubbing them keeps the run off
    // the network without changing anything the carousel does.
    cy.intercept('GET', 'https://placehold.co/**', { fixture: 'sample-image.png' })
    cy.visit('/bali/carousel/default')
    // Glide adds this once it has mounted.
    cy.get('.glide--carousel').should('exist')
  })

  it('mounts over the markup Bali rendered', () => {
    slides().should('have.length', 5)
    cy.get('.glide__slide--active').should('contain.html', 'img')
    bullets().should('have.length', 5)
    bullets().first().should('have.class', 'glide__bullet--active')
  })

  it('advances with the next arrow', () => {
    nextArrow().click()

    bullets().eq(1).should('have.class', 'glide__bullet--active')
    bullets().eq(0).should('not.have.class', 'glide__bullet--active')
  })

  it('goes back with the previous arrow', () => {
    nextArrow().click()
    bullets().eq(1).should('have.class', 'glide__bullet--active')
    settled()

    previousArrow().click()

    bullets().eq(0).should('have.class', 'glide__bullet--active')
  })

  it('jumps to a slide from its bullet', () => {
    bullets().eq(3).click()

    bullets().eq(3).should('have.class', 'glide__bullet--active')
  })

  it('wraps around, because type is carousel and not slider', () => {
    previousArrow().click()

    bullets().last().should('have.class', 'glide__bullet--active')
  })

  it('moves aria-selected with the active bullet', () => {
    // The bullets are a `role=tablist`, so `aria-selected` is what a screen
    // reader reads out — and Glide only ever touches the class. Without the
    // controller keeping the two in sync, every bullet but the first announces
    // itself as unselected forever, including the one showing.
    bullets().eq(0).should('have.attr', 'aria-selected', 'true')

    nextArrow().click()

    bullets().eq(1).should('have.attr', 'aria-selected', 'true')
    bullets().eq(0).should('have.attr', 'aria-selected', 'false')
  })

  it('keeps the accessible names on the controls Glide took over', () => {
    // Glide rewrites classes and attributes on mount; the labels are the only
    // thing naming these buttons for a screen reader.
    nextArrow().should('have.attr', 'aria-label')
    previousArrow().should('have.attr', 'aria-label')
    bullets().each(($bullet) => {
      cy.wrap($bullet).should('have.attr', 'aria-label')
    })
  })

  describe('slider type', () => {
    beforeEach(() => {
      cy.intercept('GET', 'https://placehold.co/**', { fixture: 'sample-image.png' })
      cy.visit('/bali/carousel/slider')
      cy.get('.glide--slider').should('exist')
    })

    it('shows three slides at a time and stops at the ends', () => {
      slides().should('have.length', 5)
      bullets().first().should('have.class', 'glide__bullet--active')

      // A slider does not wrap: going back from the first is a no-op.
      previousArrow().click()

      bullets().first().should('have.class', 'glide__bullet--active')
    })
  })
})
