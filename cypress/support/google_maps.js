// Serves `cypress/fixtures/google-maps-stub.js` in place of the Google Maps script.
export const stubGoogleMaps = () => {
  // `readFile`, not `fixture`: Cypress EVALUATES a .js fixture as a module and
  // this one is meant to run in the page, not in the test.
  cy.readFile('cypress/fixtures/google-maps-stub.js').then((script) => {
    cy.intercept('GET', 'https://maps.googleapis.com/maps/api/js*', {
      statusCode: 200,
      headers: { 'content-type': 'application/javascript' },
      body: script
    }).as('mapsApi')
  })
}
