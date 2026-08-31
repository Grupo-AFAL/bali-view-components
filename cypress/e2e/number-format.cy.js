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
      cy.visit('/bali/form/currency/default')
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
      cy.visit('/bali/form/currency/default')
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

  context('leaving the field', () => {
    beforeEach(() => {
      cy.visit('/bali/form/currency/default')
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
    // Rails renders a decimal as the machine number `1500200.75` — a dot,
    // whatever the locale — so a stored amount arrives ungrouped and is grouped
    // on connect. Without this, a field only ever looked formatted while it was
    // being typed.
    it('groups a stored amount on connect', () => {
      cy.visit('/bali/form/currency/with_value')

      field().should('have.value', '1,500,200.75')
    })

    it('groups a stored amount on a delimited number_group', () => {
      cy.visit('/bali/form/number/delimited')

      cy.get('#form_record_number').should('have.value', '1,500,200.75')
    })
  })

  context('number_group without delimited', () => {
    // The default is untouched: a native `number` input, spinners and all. It is
    // also the reason `delimited` cannot be the default — a `number` input
    // refuses to store a value with a delimiter in it.
    it('stays a native number input', () => {
      cy.visit('/bali/form/number/default')

      cy.get('#form_record_budget')
        .should('have.attr', 'type', 'number')
        .should('not.have.attr', 'data-controller')
    })
  })

  context('percentage_group', () => {
    it('is grouped too, sharing one implementation with currency', () => {
      cy.visit('/bali/form/percentage/default')

      cy.get('#form_record_percentage').type('1500200')
      cy.get('#form_record_percentage').should('have.value', '1,500,200')
    })
  })
})
