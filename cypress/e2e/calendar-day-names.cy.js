// "Wednesday" is 98px at text-lg, and at 390px each full name ran into the next. A column under
// 98px shows `date.abbr_day_names` instead; the column decides, not the screen.
describe('Calendar day names', () => {
  const month = '/bali/calendar/default?start_date=2026-10-01'
  const full = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
  const abbreviated = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
  const names = ($ths) => [...$ths].map((th) => th.innerText.trim())
  const textBox = (th) => {
    const range = th.ownerDocument.createRange()
    range.selectNodeContents(th)
    const rects = [...range.getClientRects()].filter((rect) => rect.width > 0)
    return { left: Math.min(...rects.map((rect) => rect.left)), right: Math.max(...rects.map((rect) => rect.right)) }
  }

  ;[390, 320].forEach((width) => {
    it(`keeps each name clear of the next at ${width}px`, () => {
      cy.viewport(width, 844)
      cy.visit(month)

      cy.get('.calendar-component thead th').should(($ths) => {
        const boxes = [...$ths].map(textBox)
        boxes.slice(1).forEach((box, i) => {
          expect(box.left, `${names($ths)[i + 1]} starts after ${names($ths)[i]} ends`).to.be.at.least(boxes[i].right)
        })
        expect(names($ths)).to.deep.equal(abbreviated)
      })
    })
  })

  it('shows the full names at 1280px', () => {
    cy.viewport(1280, 800)
    cy.visit(month)

    cy.get('.calendar-component thead th').should(($ths) => {
      expect(names($ths)).to.deep.equal(full)
    })
  })

  // One 640px screen, two answers: seven columns of 80px abbreviate, five of 112px do not.
  it('decides by the width of the column, not of the screen', () => {
    cy.viewport(640, 844)
    cy.visit(month)
    cy.get('.calendar-component thead th').should(($ths) => {
      expect(names($ths)).to.deep.equal(abbreviated)
    })

    cy.visit(`${month}&weekdays_only=true`)
    cy.get('.calendar-component thead th').should(($ths) => {
      expect(names($ths)).to.deep.equal(full.slice(0, 5))
    })
  })
})
