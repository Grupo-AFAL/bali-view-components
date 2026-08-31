// The `number-format` controller. Every expectation here is on the value the
// user would read in the field, because that is the whole feature: the server
// side already accepted a delimiter and parsed it back out, it just never put
// one there.
//
// The caret cases assert a value rather than a caret offset on purpose. A caret
// that drifts one position per group is invisible in `selectionStart` assertions
// that only ever type at the end — it shows up as a digit landing in the wrong
// place, which is what a typist actually experiences.
describe('NumberFormat', () => {
  const field = () => cy.get('#form_record_currency')

  context('typing an amount', () => {
    beforeEach(() => {
      cy.visit('/bali/form/currency/delimited')
    })

    it('groups the thousands keystroke by keystroke', () => {
      field().type('1')
      field().should('have.value', '1')

      field().type('5')
      field().should('have.value', '15')

      field().type('0')
      field().should('have.value', '150')

      field().type('0')
      field().should('have.value', '1,500')

      field().type('200')
      field().should('have.value', '1,500,200')
    })

    it('leaves the decimals alone while they are being typed', () => {
      field().type('1500200.7')
      field().should('have.value', '1,500,200.7')

      field().type('5')
      field().should('have.value', '1,500,200.75')
    })

    it('accepts a delimiter the typist enters by hand without doubling it', () => {
      field().type('1,500,200')
      field().should('have.value', '1,500,200')
    })

    it('keeps a leading minus', () => {
      field().type('-1234567')
      field().should('have.value', '-1,234,567')
    })

    it('drops anything that is not part of a number', () => {
      field().type('1a5b0c0d')
      field().should('have.value', '1,500')
    })
  })

  context('editing in the middle of an amount', () => {
    beforeEach(() => {
      cy.visit('/bali/form/currency/delimited')
    })

    // The caret regression this controller is written around: a naive mask
    // reassigns `value` and the caret snaps to the end, so the second digit of
    // any correction lands after every digit the typist was trying to fix.
    it('inserts a digit where the caret is, not at the end', () => {
      field().type('1234567')
      field().should('have.value', '1,234,567')

      field().type('{leftarrow}{leftarrow}{leftarrow}9')
      field().should('have.value', '12,349,567')
    })

    it('keeps the caret put across two corrections in a row', () => {
      field().type('1234567')
      field().type('{leftarrow}{leftarrow}{leftarrow}9')
      field().type('8')

      field().should('have.value', '123,498,567')
    })

    // Backspace over a delimiter used to look like a dead key: the delimiter was
    // deleted, the digits regrouped, and the same delimiter reappeared in the
    // same place. Holding the key down did nothing forever.
    it('deletes the digit behind a delimiter instead of the delimiter', () => {
      field().type('1234')
      field().should('have.value', '1,234')

      field().type('{leftarrow}{leftarrow}{leftarrow}{backspace}')
      field().should('have.value', '234')
    })

    it('deletes the digit in front of a delimiter on Delete', () => {
      field().type('1234')
      field().type('{leftarrow}{leftarrow}{leftarrow}{leftarrow}{del}')

      field().should('have.value', '134')
    })

    it('deletes a digit normally', () => {
      field().type('1234567')
      field().type('{backspace}')

      field().should('have.value', '123,456')
    })
  })

  context('the two ways the caret used to drift', () => {
    beforeEach(() => {
      cy.visit('/bali/form/currency/delimited')
    })

    // Word-wise deletion belongs to the browser, and it removes far more than the
    // one character the delimiter redirect reasons about. Without a modifier
    // check, Option+Backspace over a delimiter lost its whole word and took out a
    // single digit instead.
    //
    // What is asserted is non-intervention, not the deletion: Cypress dispatches
    // the keydown with `altKey` but does not emulate the OS-level word delete, so
    // nothing is removed here either way. That is precisely what makes the value
    // a clean probe — before the modifier check this same sequence left
    // `123,567`, the digit the redirect ate.
    it('leaves word-wise deletion to the browser', () => {
      field().type('1234567')
      field().should('have.value', '1,234,567')

      // Caret right after a delimiter is where the redirect would fire.
      field().type('{leftarrow}{leftarrow}{leftarrow}')
      field().type('{alt}{backspace}')

      field().should('have.value', '1,234,567')
    })

    // `grouped` keeps only a LEADING sign, so counting a minus typed into the
    // middle advanced the caret past a character that is not in the result and
    // sent it to the end of the field.
    it('does not jump to the end when a minus is typed mid-number', () => {
      field().type('1234')
      field().should('have.value', '1,234')

      field().type('{leftarrow}-')
      field().should('have.value', '1,234')

      // The caret is still before the 4, so the next digit lands there.
      field().type('9')
      field().should('have.value', '12,394')
    })
  })

  context('leaving the field', () => {
    beforeEach(() => {
      cy.visit('/bali/form/currency/delimited')
    })

    // Both shapes are rejected by the `pattern` the FormBuilder puts on the
    // field, so finishing them here beats letting the typist discover it at
    // submit time from a bubble that only says the format is wrong.
    it('drops a decimal separator with nothing after it', () => {
      field().type('1500.')
      field().should('have.value', '1,500.')

      field().blur()
      field().should('have.value', '1,500')
    })

    it('completes a decimal separator with nothing before it', () => {
      field().type('.5')
      field().should('have.value', '.5')

      field().blur()
      field().should('have.value', '0.5')
    })

    it('leaves a finished amount alone', () => {
      field().type('1500200.75')
      field().blur()

      field().should('have.value', '1,500,200.75')
    })
  })

  context('a value that came from the server', () => {
    // Grouped by the SERVER, not here. `1.500` is a machine number in English and
    // a delimited fifteen hundred in Spanish, so deciding in the browser meant
    // guessing and each guess corrupted the case it got wrong. These assertions
    // are what the field reads on arrival, before anyone types.
    it('arrives already grouped', () => {
      cy.visit('/bali/form/currency/with_value')

      field().should('have.value', '1,500,200.75')
    })

    it('arrives already grouped on a delimited number_group', () => {
      cy.visit('/bali/form/number/delimited')

      cy.get('#form_record_number').should('have.value', '1,500,200.75')
    })

    it('is left alone by the controller, not re-derived from it', () => {
      cy.visit('/bali/form/currency/with_value')

      // Focus and blur without typing: nothing the controller does may alter a
      // value it did not produce.
      field().focus()
      field().blur()
      field().should('have.value', '1,500,200.75')
    })
  })

  context('without delimited', () => {
    // `delimited` is opt-in in every family. It reads like a free upgrade and it
    // is not: the delimiter changes what the field SUBMITS, and a grouped amount
    // only survives the trip if the model carries `currency_attribute`. Measured
    // across the group's apps: twelve live money fields, not one model with the
    // concern — every one would have started storing 1.
    it('leaves a currency field ungrouped', () => {
      cy.visit('/bali/form/currency/default')

      cy.get('#form_record_currency').should('not.have.attr', 'data-controller')
      cy.get('#form_record_currency').type('1500200')
      cy.get('#form_record_currency').should('have.value', '1500200')
    })

    it('leaves number_group as a native number input', () => {
      cy.visit('/bali/form/number/default')

      cy.get('#form_record_budget')
        .should('have.attr', 'type', 'number')
        .should('not.have.attr', 'data-controller')
    })
  })

  context('percentage_group', () => {
    it('is grouped too, sharing one implementation with currency', () => {
      cy.visit('/bali/form/percentage/delimited')

      cy.get('#form_record_percentage').type('1500200')
      cy.get('#form_record_percentage').should('have.value', '1,500,200')
    })
  })
})
