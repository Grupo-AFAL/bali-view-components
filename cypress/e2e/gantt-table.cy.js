import { statusColor } from '../../app/components/bali/gantt/ganttColors'
import { cdp, frameAt } from '../support/accessibility_tree'
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

// What shows of `el` through every box above it that clips, each at its padding box.
const shownBox = (el) => {
  const shown = box(el).toJSON()
  for (let clip = el.parentElement; clip; clip = clip.parentElement) {
    const { overflowX, overflowY } = getComputedStyle(clip)
    if (overflowX === 'visible' && overflowY === 'visible') continue
    const left = box(clip).left + clip.clientLeft
    const top = box(clip).top + clip.clientTop
    Object.assign(shown, {
      left: Math.max(shown.left, left),
      right: Math.min(shown.right, left + clip.clientWidth),
      top: Math.max(shown.top, top),
      bottom: Math.min(shown.bottom, top + clip.clientHeight)
    })
  }
  return { width: Math.max(0, shown.right - shown.left), height: Math.max(0, shown.bottom - shown.top) }
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
    const AVATARS = '.bali-gantt span.rounded-full.text-white'

    cy.visit('/bali/gantt/default')
    cy.get(AVATARS).should(($avatars) => {
      expect($avatars.filter((_, a) => a.closest('.react-flow__node')), 'avatars on bars').to.have.length.at.least(1)
      expect($avatars.filter((_, a) => !a.closest('.react-flow__node')), 'avatars in the table').to.have.length.at.least(1)
    })

    cy.url().then((url) =>
      cdp('Page.getFrameTree')
        .then(({ frameTree }) => cdp('Accessibility.getFullAXTree', { frameId: frameAt(frameTree, url).id }))
    ).then(({ nodes }) => {
      // Read right after the tree, so both see the same bars.
      cy.document().then((doc) => {
        const nameOf = new Map(JSON.parse(doc.querySelector('[data-controller="gantt"]').dataset.ganttDataValue).items
          .filter((item) => item.assignee)
          .map(({ assignee }) => [assignee.initials, assignee.name]))
        const expected = [...doc.querySelectorAll(AVATARS)].map((avatar) => nameOf.get(avatar.textContent)).sort()
        const named = nodes.filter((n) => !n.ignored && n.role?.value === 'image' && n.name?.value)
        expect(named.map((n) => n.name.value).sort(), 'named images').to.deep.equal(expected)
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

  // In a 1000 px window the table opened at 42% of a 968 px board, 407 px: the Name column kept
  // 65 px, and 11 of the preview's 14 rows showed no name at all.
  it('opens the table wide enough for every column in a 1000 px window', () => {
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

  // Every column fits only on a board of 840 px or more. Below that the table stops where the
  // timeline keeps 40% of the board: opened with every column, it would leave a phone's 358 px
  // board no timeline at all, and a 300 px floor left a 288 px one none.
  ;[['tablet', 768, 1024], ['phone', 320, 700]].forEach(([device, width, height]) => {
    it(`leaves the timeline 40% of a ${device} board and gives the table the rest`, () => {
      cy.viewport(width, height)
      cy.visit('/bali/gantt/default')
      cy.get(ROWS).should('have.length.at.least', 1)

      cy.document().should((doc) => {
        const { table } = tableOf(doc)
        const board = box(table.parentElement.parentElement).width
        expect(board - box(table).width, 'px beside the table, for the splitter and the timeline')
          .to.be.at.least(Math.floor(board * 0.4))
        expect(box(table).width, 'table width').to.be.closeTo(board * 0.6, 0.5)
      })
    })
  })

  // A column the table cannot hold whole is left out, not cut at its edge: at 390 px the first
  // 4 px of DAYS showed after DATES, a stray "D", and at 768 the start of PROGRESS.
  ;[[390, 844], [768, 1024]].forEach(([width, height]) => {
    it(`shows every column whole or not at all in a ${width} px window`, () => {
      cy.viewport(width, height)
      cy.visit('/bali/gantt/default')
      cy.get(ROWS).should('have.length.at.least', 1)

      cy.document().should((doc) => {
        const { rows, header } = tableOf(doc)
        ;[header, ...rows].forEach((line) => {
          ;[...line.children].forEach((cell, i) => {
            const shown = shownBox(cell)
            if (shown.width < 0.5 || shown.height < 0.5) return

            const what = `${line.title || 'header'}: "${header.children[i].textContent}" column`
            expect(shown.width, `${what}, px showing`).to.be.closeTo(box(cell).width, 0.5)
            expect(box(cell).top, `${what} beside Name, top`).to.be.below(box(line.children[0]).bottom - 0.5)
          })
        })
      })
    })
  })

  // The Status column fits afal-apps' `Completada`; a longer label — `Ready for review` here —
  // is cut short, and the pill's tooltip carries it whole.
  it('titles every status pill with its whole label', () => {
    cy.viewport(1280, 800)
    cy.visit('/bali/gantt/default')

    cy.get(`${ROWS} span.rounded-full.font-semibold`).should(($pills) => {
      const cut = $pills.toArray().filter((pill) => pill.scrollWidth > pill.clientWidth)
      expect(cut.map((pill) => pill.textContent), 'pills cut short').to.include('Ready for review')
      $pills.toArray().forEach((pill) => expect(pill.title, `"${pill.textContent}" tooltip`).to.equal(pill.textContent))
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
  // every daisyUI colour a host's catalog can name — afal-apps passes all but neutral — on a
  // hovered task row and on a selected one.
  const COLOURS = [null, '--color-neutral', '--color-primary', '--color-secondary', '--color-accent',
    '--color-info', '--color-success', '--color-warning', '--color-error']

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
