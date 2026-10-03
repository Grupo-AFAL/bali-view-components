import { DEFICIENCIES, cvdDistance } from '../support/color_vision'
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
          expect(chart, 'a fresh chart.js instance').to.not.eq(before.chart)
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

  describe('with a declared color', () => {
    it('starts the palette from the colour Ruby named', () => {
      cy.visit('/bali/chart/with_color')

      cy.window().then((win) => {
        const success = cssVariable(win, '--color-success')
        const primary = cssVariable(win, '--color-primary')
        // Only meaningful while the theme keeps them apart.
        expect(success).to.not.eq(primary)

        chartInstance((chart) => {
          const first = [chart.data.datasets[0].borderColor].flat()[0]

          expect(first).to.include(success.replace(/^oklch\(|\)$/g, ''))
          expect(first).to.not.include(primary.replace(/^oklch\(|\)$/g, ''))
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

    const bare = (colour) => colour.replace(/^oklch\(|\)$/g, '')
    const firstColor = (dataset) => [dataset.borderColor].flat()[0]

    beforeEach(() => {
      cy.visit('/bali/chart/series_palette')
    })

    // Ruby names each series' colour from Bali::Color::CYCLE and the controller repaints it
    // from THEME_COLOR_VARS: two lists that have to agree.
    it('paints each series in the colour Ruby named for it', () => {
      canvas().then(($canvas) => {
        const named = JSON.parse($canvas.attr('data-chart-data-value')).datasets
          .map((dataset) => firstColor(dataset).match(/var\((--color-[\w-]+)\)/)[1])

        cy.window().then((win) => {
          const tokens = named.map((name) => bare(cssVariable(win, name)))
          expect(new Set(tokens).size, 'the theme keeps them apart').to.eq(new Set(named).size)

          chartInstance((chart) => {
            chart.data.datasets.forEach((dataset, index) => {
              expect(firstColor(dataset), `series ${index + 1}, ${named[index]}`).to.include(tokens[index])
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
          expect(dataset.pointBackgroundColor, `series ${index + 1} points`).to.eq(firstColor(dataset))
          expect(chart.legend.legendItems[index].fillStyle, `series ${index + 1} legend`).to.eq(firstColor(dataset))
        })
      })
    })

    // The pair after the last series counts too: series 8 repeats series 1, and a `color:`
    // rotates the cycle so that pair lands anywhere.
    it('keeps neighbouring series apart under colour-vision deficiencies in every theme', () => {
      const collapsed = []

      THEMES.forEach((theme) => {
        cy.document().then((doc) => doc.documentElement.setAttribute('data-theme', theme))
        cy.window().then((win) => {
          const primary = bare(cssVariable(win, '--color-primary'))

          chartInstance((chart) => {
            expect(win.document.getAnimations(), 'transitions').to.have.length(0)
            expect(firstColor(chart.data.datasets[0]), `${theme} repainted`).to.include(primary)

            // The series' own colour, not the 0.8 its border is painted at.
            const colours = chart.data.datasets
              .map((dataset) => paintedPixel(win.document, firstColor(dataset).replace(/\s*\/\s*[\d.]+\)$/, ')')))

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

  // The controller repaints only the series whose border is the theme's, so a host's own
  // colours reach the points from Ruby. Before #1281 they stayed on the theme's CSS: black
  // points and a legend swatch in the legend's text colour.
  describe('with its own colours', () => {
    it('paints the points and legend swatch of a line in its fill, else its border', () => {
      cy.visit('/bali/chart/own_colors')

      chartInstance((chart) => {
        const expected = ['#2563eb', 'rgba(22, 163, 74, 0.5)']

        chart.data.datasets.forEach((dataset, index) => {
          expect(dataset.pointBackgroundColor, `${dataset.label} points`).to.eq(expected[index])
          expect(chart.legend.legendItems[index].fillStyle, `${dataset.label} legend`).to.eq(expected[index])
        })
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
