// #1495 — options written with `data-inner-html` draw that markup, a badge here, wherever the
// option sits. The controller used to look only at the select's first child, which on a flat
// list with `include_blank:` is the placeholder `build_select` puts first
// (lib/bali/form_builder/slim_select_fields.rb), and on a grouped list is an <optgroup>.
const PREVIEW = '/bali/form/slim_select/custom_html'

const open = attribute => {
  cy.get(`#form_record_${attribute}_select_div .ss-main`).as('main').click()
  cy.get('.ss-content.ss-open .ss-list').as('list')
}

describe('SlimSelect HTML options', () => {
  beforeEach(() => cy.visit(PREVIEW))

  it('draws the option markup when a blank comes first, and keeps the blank as the placeholder', () => {
    open('text')

    cy.get('@list').find('.ss-option .badge').should('have.length', 3)
    cy.get('@main').find('.ss-values .ss-placeholder').should('have.text', 'Any status')
  })

  it('draws the option markup inside option groups', () => {
    open('email')

    cy.get('@list').find('.ss-optgroup').should('have.length', 2)
    cy.get('@list').find('.ss-optgroup .ss-option .badge').should('have.length', 3)
  })

  // What a Turbo Stream into the <select>, or a host's script, does.
  it('draws the markup of an option added after the widget mounted', () => {
    cy.get('#form_record_name_select_div .ss-main').should('exist')
    cy.get('#form_record_name').then(([select]) => {
      const option = select.ownerDocument.createElement('option')
      option.value = 'late'
      option.text = 'Late User'
      option.dataset.innerHtml = '<span class="badge badge-info badge-xs"></span> Late User'
      select.append(option)
    })

    open('name')

    cy.get('@list').contains('.ss-option', 'Late User').find('.badge').should('have.length', 1)
  })
})
