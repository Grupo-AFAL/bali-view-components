import { avatarColor, hashHue } from '../../app/components/bali/gantt/ganttColors'
import { paintedContrast, paintedLuminance } from '../support/painted_contrast'
import { THEMES } from '../support/themes'

// The assignee avatar writes white initials, bold at 9–9.5px — normal text for WCAG, so AA is
// 4.5:1 — over a colour hashed from the assignee. The preview only seeds two assignees (hues 49
// and 50), so the formula is also swept over every hue `hashHue` can return (#1260).
describe('Gantt assignee avatar contrast', () => {
  const AA = 4.5
  const AVATAR = 'span.rounded-full.text-white[title]'

  it('paints white initials at AA over every hue an assignee can hash to', () => {
    const idForHue = new Map()
    for (let id = 0; idForHue.size < 360 && id < 5000; id += 1) {
      if (!idForHue.has(hashHue(id))) idForHue.set(hashHue(id), id)
    }
    expect(idForHue.size, 'hues reached by integer ids').to.equal(360)

    const white = paintedLuminance(document, 'white')
    const failures = [...idForHue].flatMap(([hue, id]) => {
      const ratio = (white + 0.05) / (paintedLuminance(document, avatarColor({ id })) + 0.05)
      return ratio < AA ? [`hue ${hue}: ${ratio.toFixed(2)}`] : []
    })
    expect(failures, 'hues below AA').to.deep.equal([])
  })

  THEMES.forEach((theme) => {
    it(`every rendered avatar reads at AA on the ${theme} theme`, () => {
      cy.visit('/bali/gantt/default')
      cy.get('.react-flow__node').should('be.visible')
      cy.document().then((doc) => doc.documentElement.setAttribute('data-theme', theme))

      cy.get(AVATAR).should(($avatars) => {
        const avatars = $avatars.toArray()
        expect(avatars[0].ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)
        expect(avatars.filter((a) => a.closest('.react-flow__node')), 'avatars on bars').to.have.length.at.least(1)
        expect(avatars.filter((a) => !a.closest('.react-flow__node')), 'avatars in the table').to.have.length.at.least(1)

        avatars.forEach((avatar) => {
          expect(paintedContrast(avatar), `${theme}: ${avatar.title}`).to.be.at.least(AA)
        })
      })
    })
  })
})
