// A closed drawer stays rendered just past the edge of the viewport (drawer/index.css), close
// enough for the panel's `shadow-2xl` to reach ~38px back in: it greyed the right edge of every
// AppLayout page from 248 to 228 in `light` (#1286).
describe('Drawer: the shadow of the panel', () => {
  // The alpha of each layer of `box-shadow` that paints anything. Tailwind writes five, and the
  // four for rings and inset shadows are transparent.
  const paintedShadows = (el) => {
    const value = getComputedStyle(el).boxShadow
    if (value === 'none') return []

    return value.split(/,(?![^(]*\))/).map((layer) => {
      const rgba = layer.match(/rgba?\(([^)]*)\)/)
      const alpha = rgba && rgba[1].split(/[\s,/]+/).filter(Boolean)[3]
      return alpha ? parseFloat(alpha) : 1
    }).filter((alpha) => alpha > 0)
  }

  const open = (dialog) => {
    dialog.ownerDocument.dispatchEvent(new CustomEvent('bali:drawer:open', {
      detail: { id: dialog.id, content: null, options: {} }
    }))
  }

  const slideOf = (panel) => panel.getAnimations().filter((a) => /transform|translate/.test(a.transitionProperty))

  const DRAWERS = [
    { name: "AppLayout's main-drawer", path: '/bali/app_layout/default', drawer: '#main-drawer' },
    { name: 'a drawer on the right', path: '/bali/drawer/default?active=false&position=right', drawer: 'dialog.drawer-component' },
    { name: 'a drawer on the left', path: '/bali/drawer/default?active=false&position=left', drawer: 'dialog.drawer-component' }
  ]

  DRAWERS.forEach(({ name, path, drawer }) => {
    context(name, () => {
      beforeEach(() => {
        cy.visit(path)
        cy.get(drawer).should('not.have.class', 'drawer-open').and('not.have.attr', 'open')
      })

      it('paints no shadow while closed', () => {
        cy.get(`${drawer} .drawer-panel`).should(([panel]) => {
          expect(panel.getAnimations(), 'transitions settled').to.have.length(0)
          expect(paintedShadows(panel), 'shadow layers of the closed panel').to.have.length(0)
        })
      })

      // Measured in the frame the drawer opens, while the panel is still sliding in: a shadow that
      // faded in with the slide would read transparent here.
      it('carries the shadow from the first frame of the slide-in', () => {
        cy.get(drawer).then(([dialog]) => {
          const panel = dialog.querySelector('.drawer-panel')
          open(dialog)

          expect(slideOf(panel), 'the slide-in is running').to.have.length.greaterThan(0)
          expect(paintedShadows(panel), 'shadow layers on the first frame').to.have.length(1)
        })

        cy.get(`${drawer} .drawer-panel`).should(([panel]) => {
          expect(panel.getAnimations(), 'transitions settled').to.have.length(0)
          expect(paintedShadows(panel), 'shadow layers of the open panel').to.have.length(1)
        })
      })

      // Paused halfway through the slide-out: a shadow that snapped off on close reads transparent
      // there, and one held until the panel is gone reads at full strength.
      it('fades the shadow out with the slide-out, and drops it once closed', () => {
        cy.get(drawer).then(([dialog]) => open(dialog))
        cy.get(`${drawer} .drawer-panel`).should(([panel]) => {
          expect(panel.getAnimations(), 'transitions settled').to.have.length(0)
          expect(paintedShadows(panel), 'shadow layers of the open panel').to.have.length(1)
        })

        cy.get(drawer).then(([dialog]) => {
          const panel = dialog.querySelector('.drawer-panel')
          const [opened] = paintedShadows(panel)
          dialog.querySelector('.drawer-overlay').click()

          const slide = slideOf(panel)
          expect(slide, 'the slide-out is running').to.have.length.greaterThan(0)
          const transitions = panel.getAnimations()
          transitions.forEach((a) => {
            a.pause()
            a.currentTime = slide[0].effect.getComputedTiming().duration / 2
          })
          const [halfway = 0] = paintedShadows(panel)
          transitions.forEach((a) => a.play())

          expect(halfway, 'shadow alpha halfway through the slide-out').to.be.above(0).and.below(opened)
        })

        cy.get(drawer).should('not.have.class', 'drawer-open')
        cy.get(`${drawer} .drawer-panel`).should(([panel]) => {
          expect(panel.getAnimations(), 'transitions settled').to.have.length(0)
          expect(paintedShadows(panel), 'shadow layers once closed again').to.have.length(0)
        })
      })
    })
  })
})
