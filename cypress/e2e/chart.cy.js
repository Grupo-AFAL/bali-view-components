import { DEFICIENCIES, cvdDistance, okDistance } from '../support/color_vision'
import { paintedPixel } from '../support/painted_contrast'
import { THEMES } from '../support/themes'

// #1041 — Chart had no E2E spec, and a canvas is the one component where a
// broken render looks exactly like an empty one. Ruby writes the dataset colors
// as `color-mix(in oklch, var(--color-primary) ...)` — CSS a canvas cannot
// resolve — and the controller is what turns them into real colors before
// Chart.js ever sees them. If that step stops happening nothing throws: the
// chart just comes out blank.
describe('Chart', () => {
  const canvas = () => cy.get('canvas.chart')

  // Chart.js is imported inside render(), so the instance appears a tick after
  // the page is ready.
  const chartInstance = (callback) => {
    canvas().should(($canvas) => {
      const controller = $canvas[0].ownerDocument.defaultView.Stimulus
        .getControllerForElementAndIdentifier($canvas[0], 'chart')

      expect(controller?.chart, 'chart.js instance').to.not.eq(undefined)
      callback(controller.chart, $canvas[0])
    })
  }

  const cssVariable = (win, name) =>
    win.getComputedStyle(win.document.documentElement).getPropertyValue(name).trim()

  // A colour as the canvas paints it, alpha left out: the theme's `oklch(45% .24 277.023)` and
  // the browser's `oklch(0.45 0.24 277.023 / 0.8)` are one pixel.
  const opaque = (win, colour) => paintedPixel(win.document, colour.replace(/\s*\/\s*[\d.]+\)$/, ')'))

  describe('default bar chart', () => {
    beforeEach(() => {
      cy.visit('/bali/chart/default')
    })

    it('charts the data Ruby serialized', () => {
      chartInstance((chart) => {
        expect(chart.config.type).to.eq('bar')
        expect(chart.data.labels).to.deep.eq(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
        expect(chart.data.datasets.map((dataset) => dataset.label)).to.deep.eq(['Sales', 'Returns'])
        expect(chart.data.datasets[0].data).to.deep.eq([120, 190, 300, 250, 420, 380, 290])
      })
    })

    it('resolves the theme colors a canvas cannot', () => {
      chartInstance((chart) => {
        chart.data.datasets.forEach((dataset) => {
          const colors = [dataset.borderColor, dataset.backgroundColor].flat()

          colors.forEach((color) => {
            expect(color, 'unresolved CSS').to.not.match(/var\(|color-mix\(/)
            expect(color).to.match(/^oklch\(/)
          })
        })
      })
    })

    it('resolves the theme colors of the chrome as well', () => {
      chartInstance((chart) => {
        const { tooltip, legend } = chart.options.plugins

        // The flags Ruby sets are instructions to this controller, not options
        // Chart.js understands: they have to be consumed, not forwarded.
        expect(tooltip.useThemeColors, 'flag left behind').to.eq(undefined)
        expect(tooltip.backgroundColor).to.match(/^oklch\(/)
        expect(legend.labels.useThemeColors, 'flag left behind').to.eq(undefined)
        expect(chart.options.scales.y.ticks.color).to.match(/^oklch\(/)
      })
    })

    // The UserMenu's dark-mode switch flips <html data-theme> in place, and the
    // canvas keeps the colours it resolved from the old theme until it is painted again.
    it('paints again in the theme the page switches to', () => {
      let before
      chartInstance((chart) => {
        before = { chart, tick: chart.options.scales.y.ticks.color }
      })

      cy.document().then((doc) => doc.documentElement.setAttribute('data-theme', 'dark'))

      cy.window().then((win) => {
        const ink = cssVariable(win, '--color-base-content').replace(/^oklch\(|\)$/g, '')
        expect(before.tick, 'the old theme had other ink').to.not.include(ink)

        chartInstance((chart) => {
          expect(chart, 'the same chart.js instance').to.eq(before.chart)
          expect(chart.options.scales.y.ticks.color, 'tick ink').to.include(ink)
        })
      })
    })

    it('actually paints the canvas', () => {
      // The end of the whole pipeline: pixels. An unresolved color, a zero-height
      // container or a dead instance all end here, as an empty canvas.
      canvas().should(($canvas) => {
        const element = $canvas[0]
        const { width, height } = element

        expect(width, 'canvas width').to.be.greaterThan(0)
        expect(height, 'canvas height').to.be.greaterThan(0)

        const pixels = element.getContext('2d').getImageData(0, 0, width, height).data
        let painted = 0
        for (let i = 3; i < pixels.length; i += 4) {
          if (pixels[i] > 0) painted++
        }

        expect(painted, 'painted pixels').to.be.greaterThan(0)
      })
    })
  })

  // A bar's legend hides a dataset and a doughnut's a data index, both on the Chart.js instance,
  // which a theme switch has to repaint rather than replace.
  describe('legend', () => {
    const crossedOut = (chart) => chart.legend.legendItems.map((item) => item.hidden)
    const firstSwatch = (chart) => chart.legend.legendItems[0].fillStyle

    ;['bar', 'doughnut'].forEach((type) => {
      it(`keeps what it hid on a ${type} when the theme switches`, () => {
        cy.visit(`/bali/chart/series_palette?type=${type}`)

        let box
        chartInstance((chart) => { box = chart.legend.legendHitBoxes[1] })
        cy.then(() => canvas().click(box.left + box.width / 2, box.top + box.height / 2))

        let before
        chartInstance((chart) => {
          expect(crossedOut(chart), 'hidden by the click').to.deep.eq([false, true, false, false, false, false, false])
          before = { chart, swatch: firstSwatch(chart) }
        })

        cy.document().then((doc) => doc.documentElement.setAttribute('data-theme', 'dark'))

        cy.window().then((win) => {
          const primary = opaque(win, cssVariable(win, '--color-primary'))
          expect(opaque(win, before.swatch), 'the old theme had another primary').to.not.deep.eq(primary)

          chartInstance((chart) => {
            expect(chart, 'the same chart.js instance').to.eq(before.chart)
            expect(opaque(win, firstSwatch(chart)), 'first swatch in the new theme').to.deep.eq(primary)
            expect(crossedOut(chart), 'after the switch').to.deep.eq([false, true, false, false, false, false, false])
          })
        })
      })
    })
  })

  describe('with a declared color', () => {
    it('starts the palette from the colour Ruby named', () => {
      cy.visit('/bali/chart/with_color')

      cy.window().then((win) => {
        const success = cssVariable(win, '--color-success')
        const primary = cssVariable(win, '--color-primary')
        // Only meaningful while the theme keeps them apart.
        expect(success).to.not.eq(primary)

        chartInstance((chart) => {
          const first = opaque(win, [chart.data.datasets[0].borderColor].flat()[0])

          expect(first).to.deep.eq(opaque(win, success))
          expect(first).to.not.deep.eq(opaque(win, primary))
        })
      })
    })
  })

  describe('series palette', () => {
    // Measured between the series' own colours. Before #1281 `afal-dark`'s first two series
    // were 0.003 apart under deuteranopia, and every pair the daisyUI order brought too close
    // measured 0.047 or less. The closest neighbours now are costa-norte's accent and secondary,
    // both golds, at 0.061 under tritanopia.
    const FLOOR = 0.05

    const firstColor = (dataset) => [dataset.borderColor].flat()[0]

    beforeEach(() => {
      cy.visit('/bali/chart/series_palette')
    })

    // Ruby names every colour from Bali::Color::CYCLE, and the controller resolves each again in
    // the theme the page switches to.
    const PAINTED = { borderColor: 'colour', backgroundColor: 'fill' }

    ;['bar', 'doughnut'].forEach((type) => {
      it(`paints each ${type} colour in the one Ruby named, in every theme`, () => {
        cy.visit(`/bali/chart/series_palette?type=${type}`)

        canvas().then(($canvas) => {
          const named = JSON.parse($canvas.attr('data-chart-data-value')).datasets.map((dataset) =>
            Object.fromEntries(Object.keys(PAINTED).map((key) =>
              [key, [dataset[key]].flat().map((colour) => colour.match(/var\((--color-[\w-]+)\)/)[1])])))

          THEMES.forEach((theme) => {
            cy.document().then((doc) => doc.documentElement.setAttribute('data-theme', theme))
            cy.window().then((win) => {
              const cycle = [...new Set(named.flatMap((keys) => keys.borderColor))]
                .map((name) => opaque(win, cssVariable(win, name)).join())
              expect(new Set(cycle).size, `${theme} keeps the colours apart`).to.eq(cycle.length)

              chartInstance((chart) => {
                expect(win.document.getAnimations(), 'transitions').to.have.length(0)
                chart.data.datasets.forEach((dataset, series) => {
                  Object.entries(PAINTED).forEach(([key, part]) => {
                    [dataset[key]].flat().forEach((colour, index) => {
                      const name = named[series][key][index]
                      expect(opaque(win, colour), `${theme} series ${series + 1} ${part} ${index + 1}, ${name}`)
                        .to.deep.eq(opaque(win, cssVariable(win, name)))
                    })
                  })
                })
              })
            })
          })
        })
      })
    })

    // Chart.js fills a line's points, and its legend swatch under `usePointStyle`, from
    // `pointBackgroundColor`, which Ruby writes as the same CSS as the border. Left unresolved,
    // the swatches came out grey and the points black.
    it('paints the points and legend swatch of a line in its series colour', () => {
      cy.visit('/bali/chart/series_palette?type=line')

      chartInstance((chart) => {
        chart.data.datasets.forEach((dataset, index) => {
          expect(dataset.pointBackgroundColor, `series ${index + 1} points`).to.match(/^oklch\(/)
          expect(dataset.pointBackgroundColor, `series ${index + 1} points`).to.eq(firstColor(dataset))
          expect(chart.legend.legendItems[index].fillStyle, `series ${index + 1} legend`).to.eq(firstColor(dataset))
        })
      })
    })

    // Chart.js refreshes the options a line's points share only in an animated update: repainted
    // with `update('none')`, they kept the old theme's colour.
    it('paints the points of a line again in the theme the page switches to', () => {
      cy.visit('/bali/chart/series_palette?type=line')

      const points = (win, chart) => chart.getDatasetMeta(0).data.map((point) => opaque(win, point.options.backgroundColor))
      let before
      cy.window().then((win) => chartInstance((chart) => { before = points(win, chart) }))

      cy.document().then((doc) => doc.documentElement.setAttribute('data-theme', 'dark'))

      cy.window().then((win) => {
        const primary = opaque(win, cssVariable(win, '--color-primary'))
        expect(before[0], 'the old theme had another primary').to.not.deep.eq(primary)

        chartInstance((chart) => {
          points(win, chart).forEach((colour, index) => expect(colour, `point ${index + 1}`).to.deep.eq(primary))
        })
      })
    })

    // Seven series show each theme colour once, unless two of them are one colour: afal-dark's
    // amber-400 accent was its warning to 0.005, and series 5 repeated series 2.
    it('keeps every pair of series apart in every theme', () => {
      const alike = []

      THEMES.forEach((theme) => {
        cy.document().then((doc) => doc.documentElement.setAttribute('data-theme', theme))
        cy.window().then((win) => {
          chartInstance((chart) => {
            expect(win.document.getAnimations(), 'transitions').to.have.length(0)
            const colours = chart.data.datasets.map((dataset) => opaque(win, firstColor(dataset)))
            expect(colours[0], `${theme} resolved`).to.deep.eq(opaque(win, cssVariable(win, '--color-primary')))

            colours.forEach((colour, index) => colours.slice(index + 1).forEach((other, offset) => {
              const distance = okDistance(colour, other)
              if (distance < FLOOR) alike.push(`${theme} series ${index + 1}-${index + offset + 2} ${distance.toFixed(3)}`)
            }))
          })
        })
      })

      cy.then(() => expect(alike, `series closer than ΔE_OK ${FLOOR}`).to.deep.eq([]))
    })

    // The pair after the last series counts too: series 8 repeats series 1, and a `color:`
    // rotates the cycle so that pair lands anywhere.
    it('keeps neighbouring series apart under colour-vision deficiencies in every theme', () => {
      const collapsed = []

      THEMES.forEach((theme) => {
        cy.document().then((doc) => doc.documentElement.setAttribute('data-theme', theme))
        cy.window().then((win) => {
          chartInstance((chart) => {
            expect(win.document.getAnimations(), 'transitions').to.have.length(0)

            // The series' own colour, not the 0.8 its border is painted at.
            const colours = chart.data.datasets.map((dataset) => opaque(win, firstColor(dataset)))
            expect(colours[0], `${theme} resolved`).to.deep.eq(opaque(win, cssVariable(win, '--color-primary')))

            colours.forEach((colour, index) => {
              const next = (index + 1) % colours.length
              DEFICIENCIES.forEach((deficiency) => {
                const distance = cvdDistance(colour, colours[next], deficiency)
                if (distance < FLOOR) {
                  collapsed.push(`${theme} series ${index + 1}-${next + 1} ${deficiency} ${distance.toFixed(3)}`)
                }
              })
            })
          })
        })
      })

      cy.then(() => expect(collapsed, `neighbours closer than ΔE_OK ${FLOOR}`).to.deep.eq([]))
    })
  })

  // Only a colour naming a `var(--color-*)` is the theme's to resolve: a host's literal colours
  // reach Chart.js as written, and Ruby hands a line's points the series' own fill or border.
  describe('with its own colours', () => {
    const series = (chart, label) => {
      const index = chart.data.datasets.findIndex((dataset) => dataset.label === label)
      return { ...chart.data.datasets[index], legend: chart.legend.legendItems[index].fillStyle }
    }

    beforeEach(() => {
      cy.visit('/bali/chart/own_colors')
    })

    it('paints the points and legend swatch of a line in its fill, else its border', () => {
      chartInstance((chart) => {
        const borderOnly = series(chart, 'Border only')
        const withFill = series(chart, 'Border and fill')

        expect(borderOnly.borderColor, 'Border only border').to.eq('#2563eb')
        expect(borderOnly.pointBackgroundColor, 'Border only points').to.eq('#2563eb')
        expect(borderOnly.legend, 'Border only legend').to.eq('#2563eb')
        expect(withFill.pointBackgroundColor, 'Border and fill points').to.eq('rgba(22, 163, 74, 0.5)')
        expect(withFill.legend, 'Border and fill legend').to.eq('rgba(22, 163, 74, 0.5)')
      })
    })

    it('paints a theme var border in the colour it names, beside a fill of its own', () => {
      cy.window().then((win) => {
        chartInstance((chart) => {
          const { borderColor, pointBackgroundColor } = series(chart, 'Theme border, own fill')

          expect(opaque(win, borderColor), 'border').to.deep.eq(opaque(win, cssVariable(win, '--color-error')))
          expect(pointBackgroundColor, 'points').to.eq('rgba(220, 38, 38, 0.5)')
        })
      })
    })

    it('paints the theme fill Ruby names under a border the host wrote', () => {
      canvas().then(($canvas) => {
        const named = JSON.parse($canvas.attr('data-chart-data-value')).datasets
          .find((dataset) => dataset.label === 'Border only').backgroundColor[0].match(/var\((--color-[\w-]+)\)/)[1]

        cy.window().then((win) => {
          chartInstance((chart) => {
            const { backgroundColor } = series(chart, 'Border only')

            expect(opaque(win, [backgroundColor].flat()[0]), `fill, ${named}`).to.deep.eq(opaque(win, cssVariable(win, named)))
          })
        })
      })
    })

    it('keeps a fill of its own under the theme border', () => {
      chartInstance((chart) => {
        const fillOnly = series(chart, 'Fill only')

        expect(fillOnly.backgroundColor, 'fill').to.eq('rgba(0, 0, 0, 0)')
        expect(fillOnly.pointBackgroundColor, 'points').to.eq('rgba(0, 0, 0, 0)')
      })
    })
  })

  describe('with the accessible data table', () => {
    it('offers the same figures as text', () => {
      cy.visit('/bali/chart/with_data_table')

      // `role="img"` plus a name is everything a canvas gives the accessibility
      // tree — no numbers. The visually hidden table (`.chart-fallback-table`,
      // which also serves as the no-JS fallback) is the only way to read a value.
      canvas().should('have.attr', 'role', 'img')
      canvas().should('have.attr', 'aria-label', 'Weekly Sales Report')

      let charted
      chartInstance((chart) => {
        charted = { labels: chart.data.labels, sales: chart.data.datasets[0].data }
      })

      cy.then(() => {
        cy.get('.chart-fallback-table table tbody tr').should('have.length', charted.labels.length)
        cy.get('.chart-fallback-table table tbody tr').each(($row, index) => {
          cy.wrap($row).find('th').should('have.text', charted.labels[index])
          cy.wrap($row).find('td').first().should('have.text', String(charted.sales[index]))
        })
      })
    })
  })
})
