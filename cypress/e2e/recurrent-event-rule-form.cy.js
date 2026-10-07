import { paintedContrast } from '../support/painted_contrast'
import { hover, unhover } from '../support/tap'
import { THEMES } from '../support/themes'

// #1041 — RecurrentEventRuleForm had no E2E spec, and it is the component with
// the widest gap between what is on screen and what is submitted: every control
// is inert decoration except one hidden input, which the controller rewrites as
// an RFC 5545 RRULE on every change. The parts worth freezing are the round
// trip (a rule that comes in has to come out the same) and the `data-input-active`
// bookkeeping — an input left active while hidden puts a clause into the rule
// that the user cannot see.
describe('RecurrentEventRuleForm', () => {
  const rule = () => cy.get('#form_record_rule')
  const frequency = () => cy.get('#form_record_rule_freq')
  const endMethod = () => cy.get('#form_record_rule_end')
  const weekday = (index) => cy.get(`#byweekday_form_record_rule_${index}`)
  const dayLabel = (index) => cy.get(`label[for="byweekday_form_record_rule_${index}"]`)
  // A transition's first frame still paints the previous theme or state, and can pass.
  const expectSettled = (el) => {
    expect(el.ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)
  }
  // The two ways a control ends up disabled, each opened on `rule`.
  const disabledBy = {
    'disabled: true': (rule) => {
      cy.visit(`/bali/recurrent_event_rule_form/disabled?value=${encodeURIComponent(rule)}`)
    },
    // A host disabling the whole form: the controls are disabled without the component's option.
    'a disabled fieldset': (rule) => {
      cy.visit(`/bali/recurrent_event_rule_form/with_value?value=${encodeURIComponent(rule)}`)
      cy.get('form').then(([form]) => {
        const fieldset = form.ownerDocument.createElement('fieldset')
        fieldset.disabled = true
        form.before(fieldset)
        fieldset.append(form)
      })
    }
  }
  // The select values are RRule's own frequency constants.
  const YEARLY = '0'
  const MONTHLY = '1'
  const WEEKLY = '2'
  const DAILY = '3'

  describe('starting empty', () => {
    beforeEach(() => {
      cy.visit('/bali/recurrent_event_rule_form/default')
    })

    it('fills the empty input with a valid default rule', () => {
      // The form cannot submit "no rule": something has to be in there from the
      // first render.
      rule().should('have.value', 'FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1')
      frequency().should('have.value', YEARLY)
    })

    it('hides the interval for a yearly rule and shows it for the rest', () => {
      // "Every 1 year(s)" is noise; every other frequency needs the number.
      cy.get('[data-recurrent-event-rule-target="intervalInputContainer"]').should('not.be.visible')

      frequency().select(WEEKLY)

      cy.get('[data-recurrent-event-rule-target="intervalInputContainer"]').should('be.visible')
      cy.get('#form_record_rule_interval').should('have.attr', 'data-input-active', 'true')
    })

    it('swaps the options panel with the frequency', () => {
      cy.get('[data-rrule-freq="0"][data-recurrent-event-rule-target="freqCustomizationInputsContainer"]')
        .should('be.visible')

      frequency().select(MONTHLY)

      cy.get('[data-rrule-freq="0"][data-recurrent-event-rule-target="freqCustomizationInputsContainer"]')
        .should('not.be.visible')
      cy.get('[data-rrule-freq="1"][data-recurrent-event-rule-target="freqCustomizationInputsContainer"]')
        .should('be.visible')
      rule().should('have.value', 'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=1')
    })

    it('keeps the hidden panels out of the rule', () => {
      frequency().select(DAILY)

      // A daily rule has no month, no month day and no weekday, even though all
      // of those controls are still in the DOM holding values.
      rule().should('have.value', 'FREQ=DAILY;INTERVAL=1')
      cy.get('#form_record_rule_yearly_on_1_bymonth')
        .should('have.attr', 'data-input-active', 'false')
    })

    it('writes the weekdays the user ticks', () => {
      frequency().select(WEEKLY)
      // `force`: the checkboxes are `sr-only`, clicked through their labels.
      weekday(1).check({ force: true })
      weekday(3).check({ force: true })

      rule().should('have.value', 'FREQ=WEEKLY;INTERVAL=1;BYDAY=TU,TH')

      weekday(1).uncheck({ force: true })

      rule().should('have.value', 'FREQ=WEEKLY;INTERVAL=1;BYDAY=TH')
    })

    it('adds the end condition only once it has been chosen', () => {
      rule().should('not.contain.value', 'COUNT')

      endMethod().select('count')

      cy.get('[data-end-value="count"]').should('be.visible')
      cy.get('#form_record_rule_count').clear()
      cy.get('#form_record_rule_count').type('7')
      cy.get('#form_record_rule_count').blur()

      rule().should('have.value', 'FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1;COUNT=7')

      endMethod().select('')

      // Back to "never ends": the count input is still on the page with 7 in
      // it, and must not reach the rule.
      rule().should('not.contain.value', 'COUNT')
    })
  })

  describe('starting from an existing rule', () => {
    beforeEach(() => {
      cy.visit('/bali/recurrent_event_rule_form/with_value')
    })

    it('reads the rule back into the controls', () => {
      // FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR;COUNT=10
      frequency().should('have.value', WEEKLY)
      cy.get('#form_record_rule_interval').should('have.value', '2')
      weekday(0).should('be.checked')
      weekday(2).should('be.checked')
      weekday(4).should('be.checked')
      weekday(1).should('not.be.checked')
      endMethod().should('have.value', 'count')
      cy.get('#form_record_rule_count').should('have.value', '10')
    })

    it('survives the round trip untouched', () => {
      // Editing and undoing has to land back on the rule that came in, or
      // opening a form and closing it rewrites the record.
      weekday(1).check({ force: true })
      rule().should('contain.value', 'TU')

      weekday(1).uncheck({ force: true })

      rule().should('have.value', 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR;COUNT=10')
    })
  })

  describe('a monthly rule written by position', () => {
    it('opens on the "the last Friday" row, not the day-of-month one', () => {
      cy.visit('/bali/recurrent_event_rule_form/monthly_pattern')

      // FREQ=MONTHLY;INTERVAL=1;BYSETPOS=-1;BYDAY=FR — the second radio is the
      // one the rule was written with.
      frequency().should('have.value', MONTHLY)
      cy.get('#form_record_rule_monthly_on_2').should('be.checked')
      cy.get('#form_record_rule_monthly_on_1').should('not.be.checked')
      cy.get('#form_record_rule_monthly_on_2_bysetpos').should('have.value', '-1')
      cy.get('#form_record_rule_monthly_on_2_byweekday').should('have.value', '4')
    })
  })

  describe('restricted and disabled forms', () => {
    it('leaves only the allowed frequencies choosable', () => {
      cy.visit('/bali/recurrent_event_rule_form/limited_frequencies')

      // frequency_options: %w[weekly daily]. The options stay in the list and
      // are disabled instead of removed, so the values keep their meaning.
      frequency().find('option').should('have.length', 5)
      frequency().find('option:not(:disabled)').should('have.length', 2)
      frequency().find('option:not(:disabled)').first().should('have.value', WEEKLY)
    })

    // #1051: the form used to open on yearly — a disabled option — because the
    // server preselected nothing and the controller's fallback rule was a
    // hardcoded yearly one it then synced the select back to. Submitted
    // untouched, it persisted a frequency the host had forbidden.
    it('starts from the first frequency the host allowed', () => {
      cy.visit('/bali/recurrent_event_rule_form/limited_frequencies')

      frequency().should('have.value', WEEKLY)
      frequency().should(($select) => {
        const select = $select[0]

        expect(select.options[select.selectedIndex].disabled, 'selected option').to.eq(false)
      })

      // And the rule an untouched submit would carry is that frequency's.
      rule().should('have.value', 'FREQ=WEEKLY;INTERVAL=1')
      // The panel on screen agrees with it: weekly's, not yearly's.
      cy.get('[data-rrule-freq="2"][data-recurrent-event-rule-target="freqCustomizationInputsContainer"]')
        .should('be.visible')
      cy.get('[data-rrule-freq="0"][data-recurrent-event-rule-target="freqCustomizationInputsContainer"]')
        .should('not.be.visible')
    })

    it('hides the end section when the host skipped it', () => {
      cy.visit('/bali/recurrent_event_rule_form/without_end')

      cy.get('#form_record_rule_end').should('not.be.visible')
      rule().should('not.contain.value', 'COUNT')
      rule().should('not.contain.value', 'UNTIL')
    })

    it('cannot be edited when disabled', () => {
      cy.visit('/bali/recurrent_event_rule_form/disabled')

      rule().should('have.value', 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE')
      frequency().should('be.disabled')
      cy.get('#form_record_rule_interval').should('be.disabled')
    })
  })

  // A checked day is the theme's primary pair, which test/bali/theme_contrast_test.rb holds at AA
  // on Bali's themes; daisyUI's `dark` paints it at 4.13:1, so the bar under the cursor is the day
  // at rest, not 4.5.
  describe('the weekdays as painted', () => {
    // An outline is drawn outside the box, over whatever the element sits on: measured as text
    // of its colour placed beside it.
    const ringContrast = (el) => {
      const probe = el.ownerDocument.createElement('span')
      probe.style.color = getComputedStyle(el).outlineColor
      el.after(probe)
      try {
        return paintedContrast(probe)
      } finally {
        probe.remove()
      }
    }

    beforeEach(() => {
      cy.then(unhover)
      cy.visit('/bali/recurrent_event_rule_form/with_value')
      // Monday, checked by the preview's BYDAY=MO,WE,FR.
      weekday(0).should('be.checked')
    })

    afterEach(() => cy.then(unhover))

    THEMES.forEach((theme) => {
      it(`rings a checked day under the cursor, as legible as at rest, on the ${theme} theme`, () => {
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

        let atRest
        dayLabel(0).should(([label]) => {
          expectSettled(label)
          expect(label.matches(':hover'), 'at rest').to.equal(false)
          atRest = paintedContrast(label)
        })

        dayLabel(0).then(hover)

        dayLabel(0).should(([label]) => {
          expectSettled(label)
          expect(label.matches(':hover'), 'under the cursor').to.equal(true)
          expect(paintedContrast(label), `${theme}: text under the cursor`).to.be.at.least(atRest)
          expect(getComputedStyle(label).outlineStyle, 'ring drawn').to.not.equal('none')
          expect(ringContrast(label), `${theme}: hover ring`).to.be.at.least(3)
        })
      })

      // The checkbox is `sr-only`: its own focus ring is clipped away with it.
      it(`rings the day the keyboard is on at 3:1 on the ${theme} theme`, () => {
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
        weekday(0).focus()

        dayLabel(0).should(([label]) => {
          expectSettled(label)
          expect(label.control.matches(':focus-visible'), 'keyboard focus').to.equal(true)
          expect(getComputedStyle(label).outlineStyle, 'ring drawn').to.not.equal('none')
          expect(ringContrast(label), `${theme}: focus ring`).to.be.at.least(3)
        })
      })
    })
  })

  // #1272: a disabled day scaled, tinted and ringed under the cursor as if it could be picked.
  describe('a disabled day', () => {
    // Everything the cursor changes on an enabled day.
    const reaction = (label) => {
      const style = getComputedStyle(label)

      return {
        scale: style.scale,
        background: style.backgroundColor,
        outline: style.outlineStyle,
        shadow: style.boxShadow
      }
    }

    const rule = 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE'
    const days = {
      'a checked': [0, 'be.checked'],
      'an unchecked': [1, 'not.be.checked']
    }

    Object.entries(disabledBy).forEach(([way, visit]) => {
      describe(`through ${way}`, () => {
        beforeEach(() => {
          cy.then(unhover)
          visit(rule)
        })

        afterEach(() => cy.then(unhover))

        Object.entries(days).forEach(([day, [index, state]]) => {
          it(`does not react to the cursor on ${day} day`, () => {
            weekday(index).should('be.disabled').and(state)

            let atRest
            dayLabel(index).should(([label]) => {
              expectSettled(label)
              expect(label.parentElement.matches(':hover'), 'at rest').to.equal(false)
              atRest = reaction(label)
            })

            dayLabel(index).then(hover)

            // Read through the day's wrapper: a disabled label does not take the pointer itself.
            dayLabel(index).should(([label]) => {
              expect(label.parentElement.matches(':hover'), 'under the cursor').to.equal(true)
              expectSettled(label)
              expect(reaction(label), 'under the cursor').to.deep.equal(atRest)
            })
          })
        })

        it('shows the not-allowed cursor over a day', () => {
          weekday(0).should('be.disabled')
          dayLabel(0).then(([label]) => label.scrollIntoView({ block: 'center' }))

          dayLabel(0).should(([label]) => {
            const box = label.getBoundingClientRect()
            const hit = label.ownerDocument.elementFromPoint(box.left + box.width / 2, box.top + box.height / 2)

            expect(label.parentElement.contains(hit), 'the point is on the day').to.equal(true)
            expect(getComputedStyle(hit).cursor, 'cursor').to.equal('not-allowed')
          })
        })
      })
    })
  })

  // #1272: a disabled yearly or monthly row tinted under the cursor and showed a pointer.
  describe('a disabled option row', () => {
    // Each rule opens its panel with one row ticked and the other not.
    const panels = {
      yearly: 'FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1',
      monthly: 'FREQ=MONTHLY;INTERVAL=1;BYSETPOS=-1;BYDAY=FR'
    }
    const rows = [1, 2]
    const radio = (panel, row) => cy.get(`#form_record_rule_${panel}_on_${row}`)
    const rowText = (panel, row) => radio(panel, row).siblings('span')

    Object.entries(disabledBy).forEach(([way, visit]) => {
      Object.entries(panels).forEach(([panel, rule]) => {
        describe(`on the ${panel} panel, through ${way}`, () => {
          beforeEach(() => {
            cy.then(unhover)
            visit(rule)
          })

          afterEach(() => cy.then(unhover))

          it('does not react to the cursor on either row', () => {
            rows.forEach((row) => {
              radio(panel, row).should('be.disabled').and('be.visible')

              let atRest
              radio(panel, row).parent().should(([label]) => {
                expectSettled(label)
                expect(label.parentElement.matches(':hover'), `row ${row} at rest`).to.equal(false)
                atRest = getComputedStyle(label).backgroundColor
              })

              rowText(panel, row).then(hover)

              // Read through the panel: a disabled row does not take the pointer itself.
              radio(panel, row).parent().should(([label]) => {
                expect(label.parentElement.matches(':hover'), `row ${row} under the cursor`).to.equal(true)
                expectSettled(label)
                expect(getComputedStyle(label).backgroundColor, `row ${row} under the cursor`).to.equal(atRest)
              })

              cy.then(unhover)
            })
          })

          it('shows the not-allowed cursor over either row', () => {
            rows.forEach((row) => {
              radio(panel, row).should('be.disabled')
              rowText(panel, row).then(([text]) => text.scrollIntoView({ block: 'center' }))

              rowText(panel, row).should(([text]) => {
                const box = text.getBoundingClientRect()
                const hit = text.ownerDocument.elementFromPoint(box.left + box.width / 2, box.top + box.height / 2)

                expect(text.closest('label').parentElement.contains(hit), `row ${row}: the point is on the panel`).to.equal(true)
                expect(getComputedStyle(hit).cursor, `row ${row}: cursor`).to.equal('not-allowed')
              })
            })
          })
        })
      })
    })
  })

  // #1286: at 390px the yearly row "On the First / Sunday / of January" stretched its panel to
  // 485px, and the page scrolled sideways under it, with "On the" broken over two lines.
  describe('the yearly and monthly rows', () => {
    const panels = {
      yearly: { freq: YEARLY, rule: 'FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1' },
      monthly: { freq: MONTHLY, rule: 'FREQ=MONTHLY;INTERVAL=1;BYSETPOS=-1;BYDAY=FR' }
    }
    const widths = [390, 320]
    const open = (rule) => cy.visit(`/bali/recurrent_event_rule_form/with_value?value=${encodeURIComponent(rule)}`)

    Object.entries(panels).forEach(([panel, { freq, rule }]) => {
      widths.forEach((width) => {
        it(`fit the ${panel} panel into ${width}px without scrolling the page sideways`, () => {
          cy.viewport(width, 844)
          open(rule)

          cy.get(`fieldset[data-rrule-freq="${freq}"]`).should('be.visible')
          cy.document().should((doc) => {
            const { scrollWidth, clientWidth } = doc.documentElement
            expect(scrollWidth, `scrollWidth of a page ${clientWidth}px wide`).to.equal(clientWidth)
          })
        })

        it(`keep each ${panel} row label on one line at ${width}px`, () => {
          cy.viewport(width, 844)
          open(rule)

          cy.get(`fieldset[data-rrule-freq="${freq}"] label > span`).should(($labels) => {
            expect($labels, 'row labels').to.have.length(2)
            $labels.each((_, text) => {
              const range = text.ownerDocument.createRange()
              range.selectNodeContents(text)
              const lines = new Set([...range.getClientRects()].map((rect) => Math.round(rect.top)))
              expect(lines.size, `lines of "${text.textContent.trim()}"`).to.equal(1)
            })
          })
        })
      })

      // A modal or a side panel gives the form less than a 320px page does: in 280px the yearly
      // "On" row, before it could wrap, measured 285.
      it(`fit the ${panel} panel into a 280px container`, () => {
        cy.viewport(390, 844)
        open(rule)

        cy.get('.recurrent-event-rule-form-component').then(([form]) => { form.style.width = '280px' })
        cy.get('.recurrent-event-rule-form-component').should(([form]) => {
          expect(form.scrollWidth, 'scrollWidth of a form 280px wide').to.equal(form.clientWidth)
        })
      })

      // Every row wraps now, and a select without `w-auto` takes daisyUI's 100% width once it
      // can: the monthly pair went one under the other at 208px each.
      it(`keep each ${panel} row on one line at 1280px`, () => {
        cy.viewport(1280, 800)
        open(rule)

        cy.get(`fieldset[data-rrule-freq="${freq}"] [data-recurrent-event-rule-target="freqCustomizationInputs"]`)
          .should(($rows) => {
            expect($rows, 'rows').to.have.length(2)
            $rows.each((_, row) => {
              const tops = [...row.querySelectorAll('select')].map((select) => Math.round(select.getBoundingClientRect().top))
              expect(new Set(tops).size, `lines in ${row.dataset.rruleFreqOption}`).to.equal(1)
            })
          })
      })

      // A closed select draws only the chosen option, clipped to its own width: a fixed `w-28`
      // cut "Weekend day", and the monthly pair, shrunk to 101px (82 at 320), cut "Wednesday".
      ;[...widths, 1280].forEach((width) => {
        it(`fit every option of the ${panel} selects at ${width}px`, () => {
          cy.viewport(width, 844)
          open(rule)

          cy.get(`fieldset[data-rrule-freq="${freq}"] select`).should(($selects) => {
            // The page's own document: the spec's has none of its web fonts.
            const context = $selects[0].ownerDocument.createElement('canvas').getContext('2d')

            $selects.each((_, select) => {
              const style = getComputedStyle(select)
              const room = select.getBoundingClientRect().width -
                ['borderLeftWidth', 'paddingLeft', 'paddingRight', 'borderRightWidth']
                  .reduce((sum, side) => sum + parseFloat(style[side]), 0)
              context.font = `${style.fontWeight} ${style.fontSize} ${style.fontFamily}`

              ;[...select.options].forEach((option) => {
                expect(context.measureText(option.text).width, `${select.id}: "${option.text}"`).to.be.at.most(room)
              })
            })
          })
        })
      })
    })
  })
})
