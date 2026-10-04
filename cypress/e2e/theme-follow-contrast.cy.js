import { contrastRatio, paintedContrast, paintedLuminance } from '../support/painted_contrast'
import { THEMES } from '../support/themes'
import { hover, unhover } from '../support/tap'

// Pieces that used to paint fixed colours instead of the theme's: SlimSelect's and the
// Datepicker's own stylesheets froze daisyUI's light palette (SlimSelect's value read
// 1.04–1.10:1 on the dark themes, a focused day 1.00–1.08), BlockEditor's code block kept
// github-light's ink (1.00:1 on a dark theme, 3.17 on afal), and a comments sidebar portaled out
// of the editor and the editor's floating menus kept BlockNote's #3f3f3f (1.50–1.68:1 on the
// dark themes).
describe('colours that follow the theme', () => {
  afterEach(() => { unhover() })

  const AA = 4.5

  const useTheme = (theme) => {
    cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
  }

  const expectSettled = (el) => {
    expect(el.ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)
  }

  // [what, the form field that draws it, the element, { ringless }]
  const FOCUSED = [
    ['a Datepicker day', 'date', '.flatpickr-day:not(.prevMonthDay):not(.nextMonthDay):not(.today)', { ringless: true }],
    ['a Datepicker day of another month', 'date', '.flatpickr-day.nextMonthDay', { ringless: true }],
    ['the hour of the time picker', 'time', 'input.flatpickr-hour'],
    ['the AM/PM toggle of the time picker', 'time', '.flatpickr-am-pm']
  ]

  // [what, the element in the Datepicker's header, what it paints, the contrast it is held to]
  const HEADER = [
    ['the month', '.flatpickr-monthDropdown-months', el => paintedContrast(el), AA],
    ['the year', 'input.cur-year', el => paintedContrast(el), AA],
    ["the year's up arrow", '.numInputWrapper span.arrowUp',
      el => paintedContrast(el, { pseudo: '::after', property: 'borderBottomColor' }), 3]
  ]

  // An inset box-shadow is invisible to paintedContrast: its colour is read off the computed
  // style and painted over the header.
  const ringOf = (el) => {
    const colour = el.ownerDocument.defaultView.getComputedStyle(el).boxShadow.match(/^[a-z-]+\([^)]*\)/)
    if (!colour) return 1
    const doc = el.ownerDocument
    const header = doc.defaultView.getComputedStyle(el.closest('.flatpickr-months')).backgroundColor
    return contrastRatio(paintedLuminance(doc, header, colour[0]), paintedLuminance(doc, header))
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

      cy.get('.ss-main').first().click()
      everyReadsAtAA('.ss-content.ss-open .ss-option:not(.ss-disabled)', theme, 2)
      cy.get('.ss-content.ss-open .ss-option.ss-selected').should('have.length', 1)
    })

    // The selected option was `primary` as text: daisyUI's own `dark` painted it at 3.40:1, and
    // 2.69 under the pointer. Its check is an icon, so 3:1.
    it(`reads SlimSelect's selected option and its check under the pointer on the ${theme} theme`, () => {
      cy.visit('/bali/form/slim_select/default')
      useTheme(theme)
      cy.get('.ss-main').first().click()
      cy.get('.ss-content.ss-open .ss-option.ss-selected').then(hover)

      cy.get('.ss-content.ss-open .ss-option.ss-selected').should(($option) => {
        const option = $option[0]
        expectSettled(option)
        expect(option.matches(':hover'), 'under the pointer').to.equal(true)
        expect(paintedContrast(option), `${theme}: selected option`).to.be.at.least(AA)
        expect(paintedContrast(option, { pseudo: '::after', property: 'backgroundColor' }), `${theme}: its check`)
          .to.be.at.least(3)
      })
    })

    // `primary` as text too, and dimmed to 70% under the pointer, which put it under AA on all six
    // themes: 2.33–4.48:1.
    it(`reads SlimSelect's "Select all" at rest and under the pointer on the ${theme} theme`, () => {
      cy.visit('/bali/form/slim_select/select_all')
      useTheme(theme)
      everyReadsAtAA('.ss-toggle-btn:not(.hidden)', theme)
      cy.get('.ss-toggle-btn:not(.hidden)').then(hover)

      cy.get('.ss-toggle-btn:not(.hidden)').should(($toggle) => {
        expectSettled($toggle[0])
        expect($toggle[0].matches(':hover'), 'under the pointer').to.equal(true)
        expect(paintedContrast($toggle[0]), `${theme}: "Select all" under the pointer`).to.be.at.least(AA)
      })
    })

    // A day's focus fill was the same light-theme literal as its hover: on the dark themes the
    // focused day turned a near-white square with its number at 1.00–1.08:1. The hour's and
    // AM/PM's was base-200, 1.05–1.10:1 off the calendar, and a day of another month had none:
    // 1.00. `ringless` as in base-surface-steps.
    FOCUSED.forEach(([what, field, selector, { ringless = false } = {}]) => {
      it(`reads ${what} under keyboard focus on the ${theme} theme`, () => {
        cy.visit(`/bali/form/${field}/default`)
        useTheme(theme)
        cy.get('form input.input:not([type="hidden"])').click()
        cy.get(`.flatpickr-calendar.open ${selector}`).first().focus()

        cy.get(`.flatpickr-calendar.open ${selector}`).first().should(($el) => {
          const el = $el[0]
          expectSettled(el)
          expect(el.matches(':focus'), 'under focus').to.equal(true)
          expect(paintedContrast(el), `${theme}: ${what} under focus`).to.be.at.least(AA)
          expect(paintedContrast(el, { over: el.parentElement, property: 'backgroundColor' }),
            `${theme}: ${what} under focus against the calendar`).to.be.at.least(1.15)
          if (ringless) {
            expect(paintedContrast(el, { property: 'borderTopColor' }), `${theme}: the border of ${what} over its own fill`)
              .to.be.closeTo(1, 0.01)
          }
        })
      })
    })

    // A custom property resolves its var() where it is declared: declared on :root alone, the
    // tokens kept the page's ink inside a subtree with a theme of its own, and a day of another
    // month read 1.00–1.09:1 there.
    it(`re-themes the Datepicker inside a subtree on the ${theme} theme`, () => {
      const page = theme.endsWith('dark') ? 'light' : 'dark'
      cy.visit('/bali/form/date/default')
      useTheme(page)
      cy.get('form input.input:not([type="hidden"])').click()
      cy.get('.flatpickr-calendar.open').should(($calendar) => {
        expect($calendar[0].parentElement, 'appended to the body').to.equal($calendar[0].ownerDocument.body)
      })
      cy.document().then(doc => doc.body.setAttribute('data-theme', theme))

      cy.get('.flatpickr-calendar.open .flatpickr-day.nextMonthDay').first().should(($day) => {
        expectSettled($day[0])
        expect(paintedContrast($day[0]), `${theme} under a ${page} page: a day of another month`).to.be.at.least(AA)
      })
    })

    // Drawn in the same light-theme ink: at rest, at 70% and their faintest, 1.05–1.14:1 on the
    // dark themes.
    it(`draws the time picker's stepper arrows at 3:1 on the ${theme} theme`, () => {
      cy.visit('/bali/form/time/default')
      useTheme(theme)
      cy.get('form input.input:not([type="hidden"])').click()

      cy.get('.flatpickr-calendar.open .flatpickr-time .numInputWrapper').should(($wrappers) => {
        expectSettled($wrappers[0])
        expect($wrappers, 'hour and minute').to.have.length(2)
        $wrappers.toArray().forEach((wrapper) => {
          expect(wrapper.matches(':hover'), 'at rest').to.equal(false)
          expect(paintedContrast(wrapper.querySelector('.arrowUp'), { pseudo: '::after', property: 'borderBottomColor' }),
            `${theme}: up arrow`).to.be.at.least(3)
          expect(paintedContrast(wrapper.querySelector('.arrowDown'), { pseudo: '::after', property: 'borderTopColor' }),
            `${theme}: down arrow`).to.be.at.least(3)
        })
      })
    })

    // A white tint over the primary header took the month and the year under the pointer to
    // 2.96:1 on `dark`, 3.75 on `afal` and 4.33 on `light`, and the year's arrow to 2.48 on `dark`.
    // Each is held to its contrast where it reaches it at rest and to its rest where it does not:
    // `dark`'s month reads 4.13 at rest, its arrow 2.80. The ring sits at the element's edge,
    // clear of the text and the arrow.
    HEADER.forEach(([what, selector, painted, floor]) => {
      it(`marks ${what} of the Datepicker header under the pointer and keeps it legible on the ${theme} theme`, () => {
        const target = `.flatpickr-calendar.open .flatpickr-current-month ${selector}`
        let atRest
        cy.visit('/bali/form/date/default')
        useTheme(theme)
        cy.get('form input.input:not([type="hidden"])').click()

        cy.get(target).should(($el) => {
          expectSettled($el[0])
          expect($el[0].matches(':hover'), 'at rest').to.equal(false)
          expect(ringOf($el[0]), `${theme}: a ring around ${what} at rest`).to.equal(1)
          atRest = painted($el[0])
        })
        cy.get(target).then(hover)

        cy.get(target).should(($el) => {
          expectSettled($el[0])
          expect($el[0].matches(':hover'), 'under the pointer').to.equal(true)
          expect(painted($el[0]), `${theme}: ${what} under the pointer`).to.be.at.least(Math.min(floor, atRest))
          expect(ringOf($el[0]), `${theme}: the ring around ${what} under the pointer`).to.be.at.least(3)
        })
      })
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
      // Once a test in the run has failed and taken its screenshot, Electron leaves Mantine's
      // fade-in of this popover at `opacity: 0` (Chrome ends it), so every theme after the first
      // failure would time out on the fade instead of reading the colours measured here.
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

  // The tests above switch once, away from the light the page loads in. Coming back is what
  // fails when the editor stops following after its first switch, and only here.
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
