// Serves `cypress/fixtures/google-maps-stub.js` in place of the Google Maps script.
// `replies` answer the first requests instead, in order: `'error'` fails the request,
// anything else is merged into the stub's response (`{ delay }` holds it back).
export const stubGoogleMaps = (...replies) => {
  // `readFile`, not `fixture`: Cypress EVALUATES a .js fixture as a module and
  // this one is meant to run in the page, not in the test.
  cy.readFile('cypress/fixtures/google-maps-stub.js').then((script) => {
    const stub = {
      statusCode: 200,
      headers: { 'content-type': 'application/javascript' },
      body: script
    }

    cy.intercept('GET', 'https://maps.googleapis.com/maps/api/js*', (req) => {
      const reply = replies.shift()
      req.reply(reply === 'error' ? { forceNetworkError: true } : { ...stub, ...reply })
    }).as('mapsApi')
  })
}
