// Serves `cypress/fixtures/google-maps-stub.js` in place of the Google Maps script.
// `replies` answer the first requests instead, in order: `'error'` fails the request,
// anything else is merged into the stub's response (`{ delay }` holds it back).
//
// The failure is a 503, not `forceNetworkError`: Chromium resends a request whose kept-alive
// connection drops, so once an earlier spec had loaded the stub the dropped request came back
// with the script on its second try and the page never saw an error (two requests 7 ms apart,
// no `error` event, measured running locations-map before google-maps-loader).
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
      req.reply(reply === 'error' ? { statusCode: 503 } : { ...stub, ...reply })
    }).as('mapsApi')
  })
}
