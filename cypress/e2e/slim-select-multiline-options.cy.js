// #1695 — the list is a flex column of a fixed height, and an option that could shrink was
// squeezed to its 40 px minimum when the options together passed it: its lines ran over the
// next option instead of the list scrolling.
const PREVIEW = '/bali/form/slim_select/multiline_options'

describe('SlimSelect options of several lines', () => {
  it('keeps each option as tall as its text, one under another, and scrolls the list', () => {
    cy.visit(PREVIEW)
    cy.get('#form_record_name_select_div .ss-main').click()
    cy.get('.ss-content.ss-open .ss-list').then(([list]) => {
      const options = [...list.querySelectorAll('.ss-option')]
      expect(options).to.have.length(8)
      options.forEach((option, index) => {
        expect(option.scrollHeight, `option ${index + 1} holds its content`).to.be.at.most(option.clientHeight)
        expect(option.clientHeight, `option ${index + 1} is taller than the minimum`).to.be.greaterThan(40)
        if (index) expect(option.getBoundingClientRect().top, `option ${index + 1} starts under the one before`).to.be.at.least(options[index - 1].getBoundingClientRect().bottom)
      })
      expect(list.scrollHeight, 'the list scrolls').to.be.greaterThan(list.clientHeight)
    })
  })
})
