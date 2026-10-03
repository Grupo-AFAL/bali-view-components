// The left-hand table of the Gantt island (GanttTable.jsx), #1283.

describe('Gantt table', () => {
  // What a screen reader is handed is Chromium's accessibility tree for the preview's frame. A
  // `<span>` is `generic`, which takes no name from its `title`: the avatar read as its initials.
  it('names every assignee avatar after its assignee, in the table and on the bars', () => {
    const cdp = (command, params) => Cypress.automation('remote:debugger:protocol', { command, params })
    const framesOf = (tree) => [tree.frame, ...(tree.childFrames || []).flatMap(framesOf)]

    cy.visit('/bali/gantt/default')
    cy.get('.bali-gantt span.rounded-full.text-white').should(($avatars) => {
      expect($avatars.filter((_, a) => a.closest('.react-flow__node')), 'avatars on bars').to.have.length.at.least(1)
      expect($avatars.filter((_, a) => !a.closest('.react-flow__node')), 'avatars in the table').to.have.length.at.least(1)
    }).then(($avatars) => {
      cy.get('[data-controller="gantt"]').then(($mount) => {
        const nameOf = new Map(JSON.parse($mount.attr('data-gantt-data-value')).items
          .filter((item) => item.assignee)
          .map(({ assignee }) => [assignee.initials, assignee.name]))
        const expected = $avatars.toArray().map((avatar) => nameOf.get(avatar.textContent)).sort()

        cy.then(() => cdp('Page.getFrameTree')).then(({ frameTree }) => {
          const frame = framesOf(frameTree).find((f) => f.url.includes('/bali/gantt/default'))
          return cdp('Accessibility.getFullAXTree', { frameId: frame.id })
        }).then(({ nodes }) => {
          const named = nodes.filter((n) => !n.ignored && n.role?.value === 'image' && n.name?.value)
          expect(named.map((n) => n.name.value).sort(), 'named images').to.deep.equal(expected)
        })
      })
    })
  })
})
