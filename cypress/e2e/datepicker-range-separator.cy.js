// Bali::Types::DateRangeValue::SEPARATORS splits a range on what this writes between its dates,
// and both pick it by the locale's language. The dummy only declares `en` and `es`, so `es-MX`
// is written into the response.
describe('Datepicker range separator', () => {
  ;[
    ['en', ' to '],
    ['es', ' a '],
    ['es-MX', ' a ']
  ].forEach(([locale, separator]) => {
    it(`writes "${separator}" between the dates in ${locale}`, () => {
      cy.intercept('GET', '**/bali/form/date/date_range', (req) => {
        req.continue((res) => {
          res.body = res.body.replace('data-datepicker-locale-value="en"', `data-datepicker-locale-value="${locale}"`)
        })
      })
      cy.visit('/bali/form/date/date_range')

      cy.get('input[name="form_record[date]"]')
        .should(($input) => expect($input[0]._flatpickr, 'flatpickr').to.exist)
        .then(($input) => {
          // flatpickr tests `instanceof Array`, which an array from the spec's window fails.
          const { Array } = $input[0].ownerDocument.defaultView
          $input[0]._flatpickr.setDate(Array.of('2026-01-01', '2026-03-31'))
          expect($input.val()).to.equal(`2026-01-01${separator}2026-03-31`)
        })
    })
  })
})
