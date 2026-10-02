import { paintedContrast } from '../support/painted_contrast'
import { THEMES } from '../support/themes'

// Pieces that used to paint fixed colours and only broke under a dark theme: SlimSelect's
// own stylesheet froze daisyUI's light palette (the value read 1.04–1.10:1 on the dark themes),
// BlockEditor's code block kept github-light's ink (1.00:1), and a comments sidebar portaled out
// of the editor kept BlockNote's #3f3f3f (1.51–1.68:1).
describe('colours that follow the theme', () => {
  const AA = 4.5
  // github-light on base-200 measures 3.17–3.29:1 on the light themes, before and after this
  // guard existed: that is the light palette's own debt, not what this guards.
  const DARK_THEMES = ['dark', 'afal-dark', 'costa-norte-dark']

  const useTheme = (theme) => {
    cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
  }

  const expectSettled = (el) => {
    expect(el.ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)
  }

  const everyReadsAtAA = (selector, theme, fewest = 1) => {
    cy.get(selector).should(($els) => {
      const els = $els.toArray()
      expectSettled(els[0])
      expect(els, selector).to.have.length.at.least(fewest)
      els.forEach((el) => {
        expect(paintedContrast(el), `${theme}: ${el.textContent.trim().slice(0, 30)}`).to.be.at.least(AA)
      })
    })
  }

  THEMES.forEach((theme) => {
    it(`reads SlimSelect's value and its open list at AA on the ${theme} theme`, () => {
      cy.visit('/bali/form/slim_select/default')
      useTheme(theme)
      everyReadsAtAA('.ss-main .ss-single', theme)

      // The selected option is `primary` as text, which theme-primary-contrast.cy.js guards
      // on Bali's themes; daisyUI's own `dark` paints it at 3.40:1.
      cy.get('.ss-main').first().click()
      everyReadsAtAA('.ss-content.ss-open .ss-option:not(.ss-disabled):not(.ss-selected)', theme, 2)
    })

    it(`reads SlimSelect's count of a long selection at AA on the ${theme} theme`, () => {
      cy.visit('/bali/form/slim_select/many_selected')
      useTheme(theme)
      everyReadsAtAA('.ss-main .ss-max', theme)
    })

    it(`reads a portaled comments sidebar at AA on the ${theme} theme`, () => {
      cy.visit('/bali/block_editor/with_portaled_read_only_comments_sidebar')
      useTheme(theme)
      everyReadsAtAA('.bn-threads-sidebar .bn-inline-content', theme, 2)
    })
  })

  DARK_THEMES.forEach((theme) => {
    it(`paints the code block's tokens at AA on the ${theme} theme`, () => {
      cy.visit('/bali/block_editor/readonly')
      cy.get('[data-content-type="codeBlock"] pre .shiki[style*="--shiki-dark"]').should('exist')
      useTheme(theme)
      cy.get('[data-content-type="codeBlock"] pre .shiki').should(($tokens) => {
        const tokens = $tokens.toArray().filter(el => el.textContent.trim())
        expectSettled(tokens[0])
        expect(tokens, 'code tokens').to.have.length.at.least(5)
        tokens.forEach((el) => {
          expect(paintedContrast(el), `${theme}: ${el.textContent.trim()}`).to.be.at.least(AA)
        })
      })
    })
  })
})
