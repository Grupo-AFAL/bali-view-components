import { avatarColor, hashHue } from '../../app/components/bali/gantt/ganttColors'
import { paintedContrast } from '../support/painted_contrast'
import { THEMES } from '../support/themes'

// The assignee avatar writes white initials, bold at 9–9.5px — normal text for WCAG, so AA is
// 4.5:1 — over a colour hashed from the assignee. The preview only seeds two assignees (hues 49
// and 50), so every hue `hashHue` can return is also painted on a rendered avatar (#1260).
// Neither the ink nor the background reads a theme token today, so the six themes measure one
// pair; they stay for the day either does (`text-primary-content`, a `--color-*` background),
// when one theme can pass while another fails. For that day the selector leaves the ink out, so
// a new ink is measured rather than not found, and the sweep paints through the element rather
// than a bare canvas, which cannot resolve `var()` and leaves its pixel black: white measured
// 21:1 over it.
describe('Gantt assignee avatar contrast', () => {
  const AA = 4.5
  const AVATAR = 'span.rounded-full[title]'

  const setTheme = (theme) => {
    cy.document().then((doc) => doc.documentElement.setAttribute('data-theme', theme))
  }

  it('paints the initials at AA over every hue an assignee can hash to, on every theme', () => {
    const idForHue = new Map()
    for (let id = 0; idForHue.size < 360 && id < 5000; id += 1) {
      if (!idForHue.has(hashHue(id))) idForHue.set(hashHue(id), id)
    }
    expect(idForHue.size, 'hues reached by integer ids').to.equal(360)

    cy.visit('/bali/gantt/default')
    cy.get('.react-flow__node').should('be.visible')

    THEMES.forEach((theme) => {
      setTheme(theme)
      cy.get(AVATAR).first().should(($avatar) => {
        expect($avatar[0].ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)
      }).then(($avatar) => {
        const avatar = $avatar[0]
        const rendered = avatar.style.background
        const failures = [...idForHue].flatMap(([hue, id]) => {
          avatar.style.background = avatarColor({ id })
          const ratio = paintedContrast(avatar)
          return ratio < AA ? [`hue ${hue}: ${ratio.toFixed(2)}`] : []
        })
        avatar.style.background = rendered
        expect(failures, `${theme}: hues below AA`).to.deep.equal([])
      })
    })
  })

  THEMES.forEach((theme) => {
    it(`every rendered avatar reads at AA on the ${theme} theme`, () => {
      cy.visit('/bali/gantt/default')
      cy.get('.react-flow__node').should('be.visible')
      setTheme(theme)

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
