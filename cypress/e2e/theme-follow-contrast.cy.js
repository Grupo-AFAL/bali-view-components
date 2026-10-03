import { paintedContrast, paintedLuminance } from '../support/painted_contrast'
import { THEMES } from '../support/themes'
import { hover, unhover } from '../support/tap'

// Pieces that used to paint fixed colours instead of the theme's: SlimSelect's own stylesheet
// froze daisyUI's light palette (the value read 1.04–1.10:1 on the dark themes), BlockEditor's
// code block kept github-light's ink (1.00:1 on a dark theme, 3.17 on afal), and a comments
// sidebar portaled out of the editor and the editor's floating menus kept BlockNote's #3f3f3f
// (1.50–1.68:1 on the dark themes).
describe('colours that follow the theme', () => {
  afterEach(() => { unhover() })

  const AA = 4.5

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

  const codeTokensReadAtAA = (theme) => {
    cy.get('[data-content-type="codeBlock"] pre .shiki').should(($tokens) => {
      const tokens = $tokens.toArray().filter(el => el.textContent.trim())
      expectSettled(tokens[0])
      expect(tokens, 'code tokens').to.have.length.at.least(5)
      // Of the colours the supported grammars get, a comment is the faintest in both shiki
      // themes, so the preview's snippet has to keep one for this to measure the worst case.
      expect(tokens.some(el => el.textContent.trim().startsWith('//')), 'a comment token').to.equal(true)
      tokens.forEach((el) => {
        expect(paintedContrast(el), `${theme}: ${el.textContent.trim()}`).to.be.at.least(AA)
      })
    })
  }

  THEMES.forEach((theme) => {
    it(`reads SlimSelect's value and its open list at AA on the ${theme} theme`, () => {
      cy.visit('/bali/form/slim_select/default')
      useTheme(theme)
      everyReadsAtAA('.ss-main .ss-single', theme)

      // The selected option is `primary` as text, and daisyUI's own `dark` paints it at 3.40:1.
      const options = theme === 'dark' ? '.ss-option:not(.ss-disabled):not(.ss-selected)' : '.ss-option:not(.ss-disabled)'
      cy.get('.ss-main').first().click()
      everyReadsAtAA(`.ss-content.ss-open ${options}`, theme, 2)
    })

    // base-200 stepped down on the dark themes: a hovered option read 1.05:1 against the list.
    it(`shows SlimSelect's hovered option on the ${theme} theme`, () => {
      cy.visit('/bali/form/slim_select/default')
      useTheme(theme)
      cy.get('.ss-main').first().click()
      cy.get('.ss-content.ss-open .ss-option:not(.ss-disabled):not(.ss-selected)').eq(1).then(hover)

      cy.get('.ss-content.ss-open').should(($list) => {
        const doc = $list[0].ownerDocument
        const style = (el) => doc.defaultView.getComputedStyle(el)
        const option = $list[0].querySelector('.ss-option:hover')
        expect(option, 'an option under the pointer').to.not.equal(null)
        expectSettled(option)

        const ground = style($list[0]).backgroundColor
        const [hi, lo] = [paintedLuminance(doc, ground, style(option).backgroundColor), paintedLuminance(doc, ground)]
          .sort((a, b) => b - a)
        expect((hi + 0.05) / (lo + 0.05), `${theme}: hovered option against the list`).to.be.at.least(1.15)
      })
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

    // AA alone also passes with BlockNote's own palette once BlockNote is told the scheme
    // (#cfcfcf on the dark themes), so the menu is held to the editor's ink as well.
    it(`reads the BlockEditor's "/" menu at AA, in the editor's ink, on the ${theme} theme`, () => {
      const menuText = [
        '.bn-suggestion-menu-label',
        '.bn-mt-suggestion-menu-item-title',
        '.bn-mt-suggestion-menu-item-subtitle'
      ].map(part => `.bn-suggestion-menu ${part}`).join(', ')

      cy.visit('/bali/block_editor/default')
      useTheme(theme)
      cy.get('.bn-editor').click().type('/')
      everyReadsAtAA(menuText, theme, 10)
      cy.get(menuText).should(($els) => {
        const style = el => el.ownerDocument.defaultView.getComputedStyle(el)
        const ink = style($els[0].ownerDocument.querySelector('.bn-editor')).color
        $els.each((_, el) => {
          expect(style(el).color, `${theme}: ${el.textContent.trim()}`).to.equal(ink)
        })
      })
    })

    // Icons, so 3:1 (WCAG 1.4.11). BlockNote's #cfcfcf painted 1.56:1 on the light themes.
    it(`shows the BlockEditor's side menu on the ${theme} theme`, () => {
      cy.visit('/bali/block_editor/with_initial_content')
      useTheme(theme)
      cy.get('.bn-editor [data-content-type="paragraph"]').first().then(hover)
      cy.get('.bn-side-menu svg').should(($icons) => {
        expectSettled($icons[0])
        expect($icons, 'the add and drag icons').to.have.length(2)
        $icons.each((i, icon) => {
          expect(paintedContrast(icon), `${theme}: side menu icon ${i + 1}`).to.be.at.least(3)
        })
      })
    })

    // Mantine writes `color: var(--mantine-color-dimmed)` on the date, its gray-6 in a light
    // scheme: 3.32:1 on the light themes.
    it(`reads a comment's date in the BlockEditor's sidebar at AA on the ${theme} theme`, () => {
      cy.viewport(1280, 900)
      cy.visit('/bali/block_editor/with_comments')
      useTheme(theme)
      everyReadsAtAA('.bn-threads-sidebar .bn-thread-comment .mantine-Text-root > .mantine-Text-root', theme, 2)
    })

    // Mantine's placeholder grey: gray-5 in a light scheme, 2.07:1, and dark-3 in a dark one,
    // 2.88–3.23.
    it(`reads the BlockEditor's link field placeholder at AA on the ${theme} theme`, () => {
      cy.visit('/bali/block_editor/default')
      useTheme(theme)
      cy.get('.bn-editor').should(($editor) => expectSettled($editor[0]))
      // Under Electron, Mantine's fade-in of a popover opened after a theme switch never starts:
      // the popover computes `opacity: 0` for good (Chrome ends the fade). The colours are what
      // is measured here, so the fade goes.
      cy.document().then((doc) => {
        doc.head.insertAdjacentHTML('beforeend', '<style>.bn-form-popover { transition: none !important }</style>')
      })
      cy.get('.bn-editor').click().type('Bali{selectall}')
      cy.get('.bn-formatting-toolbar [data-test="createLink"]').click()
      cy.get('.bn-form-popover').should('have.css', 'opacity', '1')
      cy.get('.bn-form-popover input').should(($input) => {
        expect(paintedContrast($input[0], { pseudo: '::placeholder' }), `${theme}: ${$input.attr('placeholder')}`)
          .to.be.at.least(AA)
      })
    })

    it(`paints the code block's tokens at AA on the ${theme} theme`, () => {
      cy.visit('/bali/block_editor/readonly')
      cy.get('[data-content-type="codeBlock"] pre .shiki[style*="--shiki-dark"]').should('exist')
      useTheme(theme)
      codeTokensReadAtAA(theme)
    })
  })

  // Each render of the editor reads the page's scheme, and it is still rendering as it mounts:
  // with no subscription at all, the single switch above passed on one or two of the three
  // dark themes. Switching back as well failed 10 runs out of 10.
  it('follows a data-theme switched in place, to dark and back', () => {
    cy.visit('/bali/block_editor/readonly')
    cy.get('[data-content-type="codeBlock"] pre .shiki[style*="--shiki-dark"]').should('exist')
    useTheme('dark')
    codeTokensReadAtAA('dark')
    useTheme('light')
    codeTokensReadAtAA('light')
  })

  // With the `bali_theme` cookie the page arrives dark from the server instead.
  it('paints the code block\'s tokens at AA on a page that arrives dark', () => {
    cy.setCookie('bali_theme', 'dark')
    cy.visit('/bali/block_editor/readonly')
    cy.get('html').should('have.attr', 'data-theme', 'dark')
    codeTokensReadAtAA('dark')
  })

  // `color: :neutral` on these, and the neutral outline button, paint ink, not a fill. A dark
  // theme's neutral is a dark fill, so as ink over the page it measured 1.72:1 on afal-dark,
  // 1.54 on costa-norte-dark and 1.26 on daisyUI's dark; base-content is the same colour as
  // neutral on Bali's light themes.
  const NEUTRAL_INK = [
    ['gauge', '/bali/gauge/default?color=neutral', '.bali-gauge', AA],
    ['loader text', '/bali/loader/default?color=neutral', 'p.text-xl', AA],
    ['stat card icon', '/bali/stat_card/default?color=neutral', '.card-body .rounded-full svg', 3],
    ['timeline marker', '/bali/timeline/with_colors', 'li:contains("Archived") .timeline-middle', 3],
    ['outline button', '/bali/button/default?variant=neutral&style=outline', '.btn-outline', AA],
    ['progress bar', '/bali/progress/default?color=neutral', 'progress', 3]
  ]

  THEMES.forEach((theme) => {
    NEUTRAL_INK.forEach(([what, url, selector, floor]) => {
      it(`reads a neutral ${what} on the ${theme} theme`, () => {
        cy.visit(url)
        useTheme(theme)
        cy.get(selector).should(($els) => {
          expectSettled($els[0])
          expect(paintedContrast($els[0]), `${theme}: neutral ${what}`).to.be.at.least(floor)
        })
      })
    })
  })
})
