import { statusColor } from '../../app/components/bali/gantt/ganttColors'
import { paintedContrast } from '../support/painted_contrast'
import { hover, unhover } from '../support/tap'
import { THEMES } from '../support/themes'

// The left-hand table of the Gantt island (GanttTable.jsx), #1283 and item 3 of #1281.
const AA = 4.5
const appOrigin = new URL(Cypress.config('baseUrl')).origin

// The Minimap is the other `cursor-pointer` with a `title`.
const ROWS = '.bali-gantt div.group.cursor-pointer[title]'
const rowFor = (name) => cy.get(`.bali-gantt div.group.cursor-pointer[title="${name}"]`)

// The header row is the sibling before the box the body rows scroll in.
const tableOf = (doc) => {
  const rows = [...doc.querySelectorAll(ROWS)]
  const header = rows[0].parentElement.parentElement.previousElementSibling
  return { rows, header, table: header.parentElement }
}

const box = (el) => el.getBoundingClientRect()
const textBox = (el) => {
  const range = el.ownerDocument.createRange()
  range.selectNodeContents(el)
  return range.getBoundingClientRect()
}

// Each header cell spans exactly the body cells of its column, at whatever width the Name
// column gets: at 390 px the header's Name cell kept its label's width while the body's
// shrank, and every header after it sat 12 px right of its column.
const expectHeaderOverColumns = ({ rows, header }) => {
  const cells = [...header.children]
  rows.forEach((row) => {
    expect(row.children, `${row.title}: one cell per header`).to.have.length(cells.length)
    cells.forEach((cell, i) => {
      const what = `${row.title}: "${cell.textContent}" column`
      expect(box(row.children[i]).left, `${what} starts under its header`).to.be.closeTo(box(cell).left, 0.5)
      expect(box(row.children[i]).right, `${what} ends under its header`).to.be.closeTo(box(cell).right, 0.5)
    })
  })
}

// Toggle, WBS and the start of the name stay in the Name column, where nothing paints over them.
const expectNameColumnWhole = ({ rows }) => {
  rows.forEach((row) => {
    const name = row.children[0]
    const wbs = name.querySelector('.font-mono')
    expect(box(wbs).right, `${row.title}: WBS ${wbs.textContent} inside the Name column`).to.be.at.most(box(name).right)
    expect(box(name.lastElementChild).width, `${row.title}: some of the name shows`).to.be.greaterThan(0)
  })
}

describe('Gantt table', () => {
  afterEach(() => cy.then(unhover))

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

  // A word space in these 10 px bold capitals measures 2.84 px; two labels closer than about three
  // of them read as one word, as `OWNERDATES` and `DAYSSTATUS` did at 0 px.
  const MIN_GAP = 8

  ;[
    ['English', '/bali/gantt/default'],
    ['Spanish', `${appOrigin}/admin/projects/1?view=timeline&locale=es`]
  ].forEach(([language, page]) => {
    it(`separates every column header from the next and lines it up with its column, in ${language}`, () => {
      cy.viewport(1280, 800)
      cy.visit(page)
      cy.get(ROWS).should('have.length.at.least', 1)

      cy.document().should((doc) => {
        const table = tableOf(doc)
        const labels = [...table.header.children]
        expect(labels, 'every column on').to.have.length(6)
        labels.slice(0, -1).forEach((label, i) => {
          const next = labels[i + 1]
          expect(textBox(next).left - textBox(label).right, `"${label.textContent}" to "${next.textContent}"`)
            .to.be.at.least(MIN_GAP)
        })
        expectHeaderOverColumns(table)
      })
    })
  })

  it('keeps the Name column whole on a phone: no avatar or date paints over the WBS', () => {
    cy.viewport(390, 844)
    cy.visit('/bali/gantt/default')
    cy.get(ROWS).should('have.length.at.least', 1)

    cy.document().should((doc) => {
      const table = tableOf(doc)
      expectNameColumnWhole(table)
      expectHeaderOverColumns(table)
    })
  })

  // At 1000 px the table opened at 42% of the board, 407 px: the Name column kept 46 px, and 11
  // of the preview's 14 rows showed no name at all.
  it('opens the table wide enough for every column on a 1000 px board', () => {
    cy.viewport(1000, 660)
    cy.visit('/bali/gantt/default')
    cy.get(ROWS).should('have.length.at.least', 1)

    cy.document().should((doc) => {
      const table = tableOf(doc)
      expectNameColumnWhole(table)
      table.rows.forEach((row) => {
        expect(box(row.lastElementChild).right, `${row.title}: Progress column inside the table`)
          .to.be.at.most(box(table.table).right)
      })
    })
  })

  it('paints the hover over a group row and a task row', () => {
    cy.visit('/bali/gantt/default')

    ;['Discovery', 'Stakeholder interviews'].forEach((name) => {
      cy.then(unhover)
      rowFor(name).should(($row) => expect($row[0].matches(':hover'), 'at rest').to.equal(false)).then(($row) => {
        const rest = getComputedStyle($row[0]).backgroundColor
        cy.wrap($row).then(hover)
        rowFor(name).should(($hovered) => {
          expect($hovered[0].matches(':hover'), 'under the pointer').to.equal(true)
          expect(getComputedStyle($hovered[0]).backgroundColor, `${name} under the pointer`).to.not.equal(rest)
        })
      })
    })
  })

  // The pill writes its status's colour over a 16% tint of that colour, on a row that may carry
  // a tint of its own. Every pill on the page is measured as the catalog paints it, and again in
  // every colour a host's catalog names — afal-apps passes all of these — on a hovered task row
  // and on a selected one.
  const COLOURS = [null, '--color-primary', '--color-secondary', '--color-accent', '--color-info',
    '--color-success', '--color-warning', '--color-error']

  THEMES.forEach((theme) => {
    it(`reads every status pill at AA, in every catalog colour, on the ${theme} theme`, () => {
      cy.visit('/bali/gantt/default')
      rowFor('Findings summary').click()
      cy.document().then((doc) => doc.documentElement.setAttribute('data-theme', theme))

      cy.get('[data-controller="gantt"]').then(($mount) => {
        const rowsWithPill = JSON.parse($mount.attr('data-gantt-data-value')).items.filter((item) => item.group_id).length

        ;['Stakeholder interviews', 'Findings summary'].forEach((pointerOn) => {
          rowFor(pointerOn).then(hover)
          cy.document({ timeout: 10000 }).should((doc) => {
            expect(doc.getAnimations(), 'transitions settled').to.have.length(0)
            const hovered = doc.querySelector(`${ROWS}:hover`)
            expect(hovered?.title, 'under the pointer').to.equal(pointerOn)

            const pills = [...doc.querySelectorAll(`${ROWS} span.rounded-full.font-semibold`)]
            expect(pills, 'a pill on every task row').to.have.length(rowsWithPill)
            pills.forEach((pill) => {
              expect(paintedContrast(pill), `${theme}: "${pill.textContent}" on ${pill.closest(ROWS).title}`).to.be.at.least(AA)
            })
          }).then((doc) => {
            const pill = doc.querySelector(`${ROWS}:hover span.rounded-full.font-semibold`)
            const rendered = pill.getAttribute('style')
            const failures = COLOURS.flatMap((color) => {
              const paint = statusColor('x', { statuses: [{ value: 'x', color }] })
              Object.assign(pill.style, { color: paint.text, background: paint.fill, border: `1px solid ${paint.border}` })
              const ratio = paintedContrast(pill)
              return ratio < AA ? [`${color ?? 'neutral'}: ${ratio.toFixed(2)}`] : []
            })
            pill.setAttribute('style', rendered)
            expect(failures, `${theme}: catalog colours below AA on ${pointerOn}, under the pointer`).to.deep.equal([])
          })
        })
      })
    })
  })
})
