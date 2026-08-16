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

      rule().should('have.value', 'FREQ=DAILY;INTERVAL=1')
      frequency().should('be.disabled')
      cy.get('#form_record_rule_interval').should('be.disabled')
    })
  })
})
