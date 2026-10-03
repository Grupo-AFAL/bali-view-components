import { paintedContrast } from '../support/painted_contrast'
import { THEMES, token } from '../support/themes'

// Modal's box and Drawer's panel paint base-100, and both took their text colour from wherever
// they were rendered: inside a `neutral` Navbar the title measured 1.27:1 on `light` and 1.00 on
// `afal`, and a ghost "Cancel" followed it there (#1284).
describe('Modal and Drawer inside a container with a text colour of its own', () => {
  const TEXT = 4.5
  const PANELS = [
    { name: 'Modal', preview: 'modal/with_slots', dialog: 'dialog.modal-component', panel: '.modal-box', texts: ['h3', '.btn-ghost:not(.btn-circle)'] },
    { name: 'Drawer', preview: 'drawer/with_slots', dialog: 'dialog.drawer-component', panel: '.drawer-panel', texts: ['.drawer-header h2', '.drawer-inner p', '.drawer-footer .btn-ghost'] }
  ]

  THEMES.forEach((theme) => {
    PANELS.forEach(({ name, preview, dialog, panel, texts }) => {
      it(`${name}: its text reads on its panel inside a neutral Navbar, ${theme} theme`, () => {
        cy.visit(`/bali/${preview}`)
        cy.get(dialog).then(($dialog) => {
          const doc = $dialog[0].ownerDocument
          const nav = doc.createElement('nav')
          nav.className = 'navbar navbar-neutral'
          $dialog[0].before(nav)
          nav.append($dialog[0])
          doc.documentElement.setAttribute('data-theme', theme)
        })

        // Not the document: while a daisyUI `.modal` is open, `set-page-has-scroll` runs on `:root`.
        cy.get(panel).should(($panel) => {
          expect($panel[0].getAnimations({ subtree: true }), 'transitions settled').to.have.length(0)
          texts.forEach((selector) => {
            const el = $panel[0].querySelector(selector)
            expect(el, selector).not.to.equal(null)
            expect(paintedContrast(el), `${theme}: ${name} ${selector}`).to.be.at.least(TEXT)
          })
        })
      })
    })
  })
})

// What `wrapper_class:` renders, and what a trigger's `data-wrapper-class` adds when it opens the
// modal: a class on the box. The header of modal/index.css says why the box's own colour has to
// lose to it.
describe('Modal: a text colour passed in wrapper_class', () => {
  it('beats the box\'s base-content', () => {
    cy.visit('/bali/modal/with_slots')
    cy.get('dialog.modal-component .modal-box').then(($box) => $box[0].classList.add('text-accent-content'))

    cy.get('dialog.modal-component .modal-box').should(($box) => {
      expect($box[0].getAnimations({ subtree: true }), 'transitions settled').to.have.length(0)
      const accent = token($box[0], 'accent-content')
      expect(accent, 'two colours to tell apart').not.to.equal(token($box[0], 'base-content'))
      expect(window.getComputedStyle($box[0]).color, 'accent-content').to.equal(accent)
    })
  })
})
