// WCAG 2.5.8: a pointer target of at least 24×24. SlimSelect's ✕ buttons grow for the pointer
// only, so the chip and the trigger they sit in keep their size.
const expectTarget = button => {
  const box = button.getBoundingClientRect()
  expect(box.width, 'width').to.be.at.least(24)
  expect(box.height, 'height').to.be.at.least(24)
  // What the pointer reaches, not only the box: the trigger could clip it, a sibling cover it.
  ;[[box.left + 1, box.top + 1], [box.right - 1, box.bottom - 1]].forEach(([x, y]) => {
    expect(button.contains(button.ownerDocument.elementFromPoint(x, y)), `hit at ${x}, ${y}`).to.equal(true)
  })
}

const height = el => el.getBoundingClientRect().height

// A chip scales in (`ss-valueIn`) and reports a smaller box until that finishes.
const running = el => el.getAnimations({ subtree: true }).filter(animation => animation.playState !== 'finished')

const pick = options => options.forEach(option => {
  cy.get('body').then($body => {
    if (!$body.find('.ss-content.ss-open').length) cy.get('.ss-main .ss-values').click()
  })
  cy.contains('.ss-content.ss-open .ss-option', new RegExp(`^${option}$`)).click()
})

describe('SlimSelect: the ✕ that clears the value', () => {
  ;[
    ['a form field', 1280, '/bali/form/slim_select/allow_deselect', 40],
    ['a filter', 1280, '/bali/data_table/simple_filters/slim_select?owner=beto', 32],
    ['an iconed filter on a phone', 375, '/bali/data_table/simple_filters/with_icons?owner=beto', 32]
  ].forEach(([where, width, path, triggerHeight]) => {
    it(`is a 24×24 target in ${where}`, () => {
      cy.viewport(width, 600)
      cy.visit(path)

      cy.get('.ss-main .ss-deselect').scrollIntoView().should($deselect => {
        expectTarget($deselect[0])
        expect(height($deselect[0].closest('.ss-main')), 'trigger height').to.equal(triggerHeight)
      })
    })
  })

  // A trigger that sizes to its content. No preview has one with a ✕, because SimpleFilters gives
  // a multiple none; `allow_deselect_option: true` would show it, so the test shows it by hand.
  it('does not grow a `sm` multiple holding chips', () => {
    cy.viewport(1280, 600)
    cy.visit('/bali/data_table/simple_filters/multiple')
    pick(['USA', 'France'])
    cy.get('.ss-value').should('have.length', 2)

    cy.get('.ss-main .ss-deselect').invoke('removeClass', 'ss-hide').should($deselect => {
      expectTarget($deselect[0])
      expect(height($deselect[0].closest('.ss-main')), 'trigger height').to.equal(32)
    })
  })
})

describe('SlimSelect: the ✕ on a chip', () => {
  ;[
    ['a form field', '/bali/form/slim_select/multiple', ['Option 1', 'Option 2'], 26, 40],
    ['a `sm` multiple', '/bali/data_table/simple_filters/multiple', ['USA', 'France'], 20, 32]
  ].forEach(([where, path, options, chipHeight, triggerHeight]) => {
    it(`is a 24×24 target in ${where}, and the chip keeps its size`, () => {
      cy.viewport(1280, 600)
      cy.visit(path)
      pick(options)

      cy.get('.ss-main').should($main => {
        expect(running($main[0])).to.have.length(0)
        const chips = $main.find('.ss-value').toArray()
        expect(chips).to.have.length(2)
        chips.forEach(chip => {
          expectTarget(chip.querySelector('.ss-value-delete'))
          expect(height(chip), 'chip height').to.equal(chipHeight)
          // Beside the text the ✕ takes only its 10px glyph and 8px of padding, as it always has.
          const text = chip.querySelector('.ss-value-text').getBoundingClientRect().width
          expect(chip.getBoundingClientRect().width, 'chip width').to.be.closeTo(text + 18, 0.5)
        })
        expect(height($main[0]), 'trigger height').to.equal(triggerHeight)
      })
    })
  })

  // A `sm` chip's ✕ overflows its 20px pill by 2px each side, so stacked rows must not share it.
  it('keeps each ✕ its own 24×24 across the rows of a `sm` multiple', () => {
    cy.viewport(1280, 600)
    cy.visit('/bali/data_table/simple_filters/multiple')
    pick(['USA', 'UK', 'France', 'Germany', 'Japan', 'India'])

    cy.get('.ss-main').should($main => {
      expect(running($main[0])).to.have.length(0)
      const boxes = $main.find('.ss-value-delete').toArray().map(button => button.getBoundingClientRect())
      expect(new Set(boxes.map(box => box.top)).size, 'rows of chips').to.be.greaterThan(1)
      boxes.forEach((a, i) => boxes.slice(i + 1).forEach((b, j) => {
        const width = Math.min(a.right, b.right) - Math.max(a.left, b.left)
        const height = Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top)
        expect(width > 0 && height > 0, `✕ ${i} and ✕ ${i + j + 1} overlap by ${width}×${height}`).to.equal(false)
      }))
    })
  })
})
