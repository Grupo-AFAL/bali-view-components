// #1041 — Chart had no E2E spec, and a canvas is the one component where a
// broken render looks exactly like an empty one. Ruby writes the dataset colors
// as `color-mix(in oklch, var(--color-primary) ...)` — CSS a canvas cannot
// resolve — and the controller is what turns them into real colors before
// Chart.js ever sees them. If that step stops happening nothing throws: the
// chart just comes out blank.
describe('Chart', () => {
  const canvas = () => cy.get('canvas.chart')

  // Chart.js is imported inside connect(), so the instance appears a tick after
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
