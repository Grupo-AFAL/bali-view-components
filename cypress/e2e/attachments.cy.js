// What the list promises a host and only a browser sees: the stream that removes the last file
// brings up the empty text (`hidden only:block`), a long name truncates inside its chip, and a
// row too narrow for a file and its badge gives up the file's width instead of the page's.
describe('Attachments', () => {
  const items = () => cy.get('.attachments-component > li[id^="attachment_"]')
  const emptyText = () => cy.get('.attachments-component > .attachments-empty')
  const remove = target => cy.window().then(win => {
    win.Turbo.renderStreamMessage(`<turbo-stream action="remove" target="${target}"></turbo-stream>`)
  })

  beforeEach(() => cy.visit('/bali/attachments/default'))

  it('shows the empty text once a stream removes the last file', () => {
    emptyText().should('not.be.visible')

    items().then($items => [...$items].forEach(item => remove(item.id)))

    items().should('not.exist')
    emptyText().should('be.visible').and('contain.text', 'No attachments')
  })

  it('truncates a long name inside a chip no wider than 16rem, at phone width', () => {
    cy.viewport(375, 800)

    cy.contains('.attachments-component a.btn', 'Q3 budget').should(($chip) => {
      expect($chip[0].getBoundingClientRect().width).to.be.at.most(256)
      const name = $chip[0].querySelector('.truncate')
      expect(name.scrollWidth, 'the name overflows its box').to.be.greaterThan(name.clientWidth)
    })
  })
})

describe('Attachments with a badge, in a narrow row', () => {
  const staysInside = ($row) => {
    const list = $row[0].parentElement.getBoundingClientRect()
    for (const child of $row[0].children) {
      expect(child.getBoundingClientRect().right).to.be.at.most(list.right)
    }
  }
  const noPageScroll = () => cy.document().its('documentElement').should(root => {
    expect(root.scrollWidth).to.equal(root.clientWidth)
  })

  beforeEach(() => {
    cy.viewport(320, 800)
    cy.visit('/bali/attachments/with_badge')
  })

  it('narrows a long chip', () => {
    cy.contains('.attachments-component > li', 'Q3 budget').should(staysInside)
    noPageScroll()
  })

  it('narrows a wide thumbnail', () => {
    const wide = 'data:image/svg+xml;utf8,' + encodeURIComponent(
      "<svg xmlns='http://www.w3.org/2000/svg' width='600' height='300'/>"
    )
    cy.get('.attachments-component > li img').first()
      .invoke('attr', 'src', wide)
      .should($img => expect($img[0].naturalWidth).to.equal(600))
      .closest('li').should(staysInside)
    noPageScroll()
  })
})

// A remove button inside the record's form is a `DeleteLink` rendered `in_form: true`: its own
// form waits in a <template> and is placed before the record's form when the button is pressed.
describe('Attachments inside a form', () => {
  const firstItem = () => cy.get('.attachments-component > li[id^="attachment_"]').first()
  const placedForms = () => cy.get('form[id^="delete-link-form-"]')

  beforeEach(() => {
    cy.intercept('POST', '/lookbook/noop').as('outer')
    cy.intercept('POST', '/lookbook/attachments/*', req => {
      const id = req.url.split('/').pop()
      req.reply({
        headers: { 'Content-Type': 'text/vnd.turbo-stream.html' },
        body: `<turbo-stream action="remove" target="attachment_${id}"></turbo-stream>`
      })
    }).as('remove')
    cy.visit('/bali/attachments/in_a_form')
  })

  const removeFirst = () => firstItem().then($item => {
    const id = $item[0].id.replace('attachment_', '')
    cy.wrap($item).find('button').click()
    cy.get('#bali-confirm-title').should('have.text', 'Confirm deletion')
    cy.get('#bali-confirm-accept-btn').should('have.class', 'btn-error').click()

    cy.wait('@remove').its('request').should(request => {
      expect(request.url).to.match(new RegExp(`/lookbook/attachments/${id}$`))
      expect(request.body).to.include('_method=delete')
    })
    cy.get(`#${$item[0].id}`).should('not.exist')
    cy.get('@outer.all').should('have.length', 0)
  })

  it('keeps the fields and the Save button after the list in the outer form', () => {
    cy.get('#record-form').should($form => {
      const controls = [...$form[0].elements].map(el => el.name || el.textContent.trim())
      expect(controls).to.include('notes')
      expect(controls).to.include('Save')
    })
  })

  it('removes a file with its own DELETE after the confirm, and the form it placed leaves with it', () => {
    removeFirst()
    placedForms().should('not.exist')
  })

  // A refresh morph rewrites the template and removes a placed form, while the button's
  // controller stays connected.
  it('still removes a file after a refresh morph', () => {
    firstItem().find('button').click()
    cy.get('#bali-confirm-cancel-btn').click()
    placedForms().should('exist')

    cy.window().then(win => new Cypress.Promise(resolve => {
      const meta = win.document.createElement('meta')
      meta.name = 'turbo-refresh-method'
      meta.content = 'morph'
      win.document.head.append(meta)
      win.document.addEventListener('turbo:morph', resolve, { once: true })
      win.Turbo.visit(win.location.href, { action: 'replace' })
    }))

    removeFirst()
  })
})
