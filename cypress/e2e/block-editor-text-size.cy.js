// BlockNote declares the size of the editor body ONCE, in
// `.bn-editor.bn-default-styles`, and everything it draws inside comes out in `em` from there:
// headings at 3em/2em/1.3em, and `font-size: inherit` for paragraphs, list items
// and cells. That is why `size:` is a single declaration and still moves the whole
// document proportionally.
//
// What is measured here is that proportion, which is exactly what breaks silently:
// it is enough for someone to pin back in `rem` one of the values Bali moved to `em`
// —the code block, the nested indent, the checklist box— for that piece
// to stay put while the rest shrinks, and nothing fails until someone looks at it.
//
// `md` counts twice: besides scaling, it has to give EXACTLY the px BlockNote
// came with before `size:` existed. If this half falls, the default changed.
const preview = size =>
  `bali/block_editor/with_initial_content${size ? `?size=${size}` : ''}`

const px = value => parseFloat(value)

const measure = () => {
  const css = (selector, prop) =>
    cy.get(selector).first().then($el => px(getComputedStyle($el[0])[prop]))

  return {
    body: () => css('.bn-editor.bn-default-styles', 'fontSize'),
    paragraph: () => css('[data-content-type="paragraph"]', 'fontSize'),
    bullet: () => css('[data-content-type="bulletListItem"]', 'fontSize'),
    code: () => css('[data-content-type="codeBlock"] pre code', 'fontSize'),
    indent: () => css('.bn-block-group .bn-block-group', 'marginLeft'),
    checkbox: () => css('[data-content-type="checkListItem"] > div > input', 'height')
  }
}

// The editor is React mounted by Stimulus: you have to wait for the content to exist,
// not just the container, or you measure the empty div the server sent.
const openPreview = size => {
  cy.visit(preview(size))
  cy.get('.bn-editor.bn-default-styles').should('exist')
  cy.get('[data-content-type="paragraph"]').should('exist')
}

describe('BlockEditor: `size:` scales the whole document', () => {
  it('in `md` it leaves the measurements BlockNote came with untouched', () => {
    openPreview('md')

    cy.get('.block-editor-component').should('have.class', 'block-editor-size-md')

    const m = measure()
    m.body().should('eq', 16)
    m.code().should('eq', 14)
    m.indent().should('eq', 24)
    m.checkbox().should('eq', 24)
  })

  it('is the default when nobody passes `size:`', () => {
    openPreview(null)

    cy.get('.block-editor-component').should('have.class', 'block-editor-size-md')
    measure().body().should('eq', 16)
  })

  const scales = [
    { size: 'xs', factor: 0.75 },
    { size: 'sm', factor: 0.875 },
    { size: 'lg', factor: 1.125 }
  ]

  scales.forEach(({ size, factor }) => {
    it(`in \`${size}\` it moves text and geometry by the same factor`, () => {
      openPreview(size)

      cy.get('.block-editor-component').should('have.class', `block-editor-size-${size}`)

      const m = measure()
      m.body().should('eq', 16 * factor)
      m.paragraph().should('eq', 16 * factor)
      m.bullet().should('eq', 16 * factor)
      m.code().should('eq', 14 * factor)
      m.indent().should('eq', 24 * factor)
      m.checkbox().should('eq', 24 * factor)
    })
  })

  // The menus and the toolbar are UI, not content: shrinking them below their touch
  // target is not what a compact field asked for. The `h2` is what gets measured, which is
  // content, against the 2em ratio BlockNote gives it -- if someone puts the size on the
  // heading ramp instead of on the body, this proportion breaks.
  it('keeps the heading ramp proportional to the body', () => {
    openPreview('xs')

    const m = measure()
    m.body().then(body => {
      cy.get('[data-content-type="heading"][data-level="2"]')
        .first()
        .then($h2 => {
          expect(px(getComputedStyle($h2[0]).fontSize)).to.eq(body * 2)
        })
    })
  })
})
