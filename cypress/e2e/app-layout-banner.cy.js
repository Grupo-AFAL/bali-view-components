// The banner offset is geometry, so geometry is what gets measured: the COMPUTED `top` and
// `height` of the fixed rail against the real height of the strip. No textContent and no
// hardcoded pixels — the strip measures whatever its font and its padding measure, and what
// is under test is that the sidebar follows it, not how tall it is.
describe('AppLayout: the fixed sidebar starts below the banner', () => {
  const DESKTOP = [1440, 900]

  const visitWithBanners = (banners) => {
    cy.viewport(...DESKTOP)
    cy.visit(`/bali/app_layout/with_banner?banners=${banners}`)
    // The controller writes the offset after measuring, so the variable has to be waited
    // for: without this we measure the frame before `connect()`.
    cy.get('body').should($body => {
      expect($body[0].style.getPropertyValue('--bali-banner-height')).to.not.equal('')
    })
  }

  // The strip and the rail touch, with no overlap and no page left in between.
  const sidebarSitsUnderBanner = () => {
    cy.get('.app-layout-banner').then($banner => {
      const strip = $banner[0].getBoundingClientRect()

      cy.get('.side-menu-component--fixed').should($sidebar => {
        const rail = $sidebar[0].getBoundingClientRect()

        expect(rail.top, 'the rail starts where the strip ends').to.be.closeTo(strip.bottom, 1)
        expect(rail.bottom, 'and reaches the bottom of the viewport').to.be.closeTo(
          $sidebar[0].ownerDocument.defaultView.innerHeight, 1
        )
      })
    })
  }

  it('with one banner, the rail drops by exactly its height', () => {
    visitWithBanners(1)
    sidebarSitsUnderBanner()

    cy.get('.side-menu-component--fixed').should($sidebar => {
      expect($sidebar[0].getBoundingClientRect().top, 'not still at zero').to.be.greaterThan(0)
    })
  })

  // The case gc patches by hand with `top: 5.5rem !important`: two stacked strips.
  it('with two stacked banners, it drops by the sum of both', () => {
    visitWithBanners(2)
    sidebarSitsUnderBanner()

    cy.get('.app-layout-banner').then($withTwo => {
      const heightWithTwo = $withTwo[0].getBoundingClientRect().height

      visitWithBanners(1)
      cy.get('.app-layout-banner').should($withOne => {
        expect(heightWithTwo, 'two strips measure more than one').to.be.greaterThan(
          $withOne[0].getBoundingClientRect().height
        )
      })
    })
  })

  it('dismissing one of the two raises the rail to the new height', () => {
    visitWithBanners(2)

    cy.get('.side-menu-component--fixed').then($before => {
      const topBefore = $before[0].getBoundingClientRect().top

      cy.get('.app-layout-banner [data-action="alert#dismiss"]').click()

      cy.get('.side-menu-component--fixed').should($after => {
        expect($after[0].getBoundingClientRect().top, 'the rail moved up').to.be.lessThan(topBefore)
      })

      sidebarSitsUnderBanner()
    })
  })

  // With no banner there is no variable to apply: the rail stays where it always was, and that
  // is the guarantee that the banner offset does not touch whoever does not use the slot.
  it('with no banner, the rail stays flush with the top', () => {
    cy.viewport(...DESKTOP)
    cy.visit('/bali/app_layout/default')

    cy.get('.side-menu-component--fixed').should($sidebar => {
      expect($sidebar[0].getBoundingClientRect().top, 'top 0').to.be.closeTo(0, 1)
    })
  })

  // D726-1: full-width strip. If the banner took the sidebar's padding-left, its left edge
  // would start at 16rem and end up tucked into the content column.
  it('the strip spans the full width, not the content column', () => {
    visitWithBanners(2)

    cy.get('.app-layout-banner').should($banner => {
      const strip = $banner[0].getBoundingClientRect()

      expect(strip.left, 'flush with the left edge').to.be.closeTo(0, 1)
      // clientWidth and not innerWidth: the preview page overflows vertically, and on
      // Linux the classic scrollbar takes ~15px off the layout width while innerWidth
      // still includes it — the test failed on CI and passed on macOS (overlay). What
      // is watched is "the whole layout width, not the content column" (~half of it),
      // and that is exactly documentElement.clientWidth.
      expect(strip.width, 'full layout width').to.be.closeTo(
        $banner[0].ownerDocument.documentElement.clientWidth, 1
      )
    })
  })
})
