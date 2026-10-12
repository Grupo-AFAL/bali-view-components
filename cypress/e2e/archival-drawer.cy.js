// #721 -- archiving a movie through the engine's drawer, against the real endpoints.
//
// The dummy app lives above the Lookbook preview path `baseUrl` points at, so the origin is
// derived from it: a literal origin ignores CYPRESS_BASE_URL and tests another server.
const appOrigin = new URL(Cypress.config('baseUrl')).origin
const moviePath = '/movies/2'
const unarchiveUrl = `${appOrigin}/bali/archivals/unarchive?record_type=Movie&record_id=2`

// The dummy's Movie is reversible, so a run leaves the movie as it found it. A run that failed
// halfway left it archived: reopening first is a no-op otherwise (the engine redirects).
const reopenIfArchived = () => {
  cy.visit(`${appOrigin}${moviePath}`)
  cy.get('meta[name="csrf-token"]').invoke('attr', 'content').then(token => {
    cy.request({ method: 'POST', url: unarchiveUrl, form: true, body: { authenticity_token: token } })
  })
}

const openDrawer = () => {
  cy.visit(`${appOrigin}${moviePath}`)
  cy.get('a[href*="/bali/archivals/new"]').click()
  return cy.get('#main-drawer form[action*="/bali/archivals"]', { timeout: 10000 })
}

const successorFieldset = '[data-radio-toggle-target="element"]'

describe('Archival drawer', () => {
  beforeEach(reopenIfArchived)

  it('reveals the successor for "Replaced by another", archives, and shows the notice', () => {
    openDrawer().within(() => {
      cy.get(successorFieldset).should('not.be.visible')
      cy.contains('label', 'Replaced by another').click()
      cy.get(successorFieldset).should('be.visible')
      cy.get('select[name="archival[successor_id]"]').select(1)
      cy.get('textarea[name="archival[note]"]').type('Remastered')
      cy.get('button[type="submit"]').click()
    })

    cy.location('pathname').should('eq', moviePath)
    cy.get('.archival-notice-component').should('be.visible')
      .and('contain', 'Reason: Replaced by another.')
      .find('a').should('have.attr', 'href').and('match', /^\/movies\/\d+/)
    cy.get('a[href*="/bali/archivals/new"]').should('not.exist')
  })

  it('keeps the successor hidden for a reason that does not need one, and reopens', () => {
    openDrawer().within(() => {
      cy.contains('label', 'Expired').click()
      cy.get(successorFieldset).should('not.be.visible')
      cy.get('button[type="submit"]').click()
    })

    cy.get('.archival-notice-component').should('be.visible').and('contain', 'Reason: Expired.')
      .and('not.contain', 'Replaced by')
    cy.contains('button', 'Reopen').click()

    cy.location('pathname').should('eq', moviePath)
    cy.get('.archival-notice-component').should('not.exist')
    cy.get('a[href*="/bali/archivals/new"]').should('be.visible')
  })

  it('keeps the drawer open on a 422, shows why, and the re-rendered form still toggles', () => {
    openDrawer().within(() => {
      cy.contains('label', 'Replaced by another').click()
      cy.get('button[type="submit"]').click()
    })

    cy.get('#main-drawer #archival_successor_id_error').should('be.visible')
    cy.location('pathname').should('eq', moviePath)
    cy.get('.archival-notice-component').should('not.exist')

    // radio-toggle reconnected on the re-rendered body: the successor hides again.
    cy.get('#main-drawer form[action*="/bali/archivals"]').within(() => {
      cy.get(successorFieldset).should('be.visible')
      cy.contains('label', 'Expired').click()
      cy.get(successorFieldset).should('not.be.visible')
    })
  })
})
