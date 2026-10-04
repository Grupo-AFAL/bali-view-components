import { Controller } from '@hotwired/stimulus'
import { optionalPeer } from '../../../assets/javascripts/bali/utils/optional-peer.js'

export class ChartController extends Controller {
  static targets = ['canvas']
  static values = {
    type: {
      type: String,
      default: 'line'
    },
    data: Object,
    options: Object,
    labels: Array,
    displayPercent: { type: Boolean, default: false },
    useThemeColors: { type: Boolean, default: true }
  }

  // System font stack matching DaisyUI/Tailwind
  static FONT_FAMILY = 'ui-sans-serif, system-ui, sans-serif, "Apple Color Emoji", "Segoe UI Emoji"'

  connect () {
    this.rendering = this.render()

    // The colours are read from the theme once and painted into a canvas, so a dark-mode
    // switch that flips <html data-theme> in place (Bali::Topbar::UserMenu) would leave the
    // chart in the old theme until the next page.
    if (this.useThemeColorsValue) {
      // A paint that failed must not stop the ones after it.
      this.themeObserver = new MutationObserver(() => {
        this.rendering = this.rendering.catch(() => {}).then(() => this.render())
      })
      this.themeObserver.observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] })
    }
  }

  async render () {
    const element = this.hasCanvasTarget ? this.canvasTarget : this.element
    const options = this.optionsValue || {}
    // Parsed from the attribute on every read: a theme switch resolves Ruby's colours again,
    // not the ones the previous theme resolved them to.
    const data = this.dataValue || {}

    this.addPrefixAndSuffixToAxisLabel(options)
    this.addPrefixAndSuffixToTooltipLabel(options)
    this.overrideTooltipTitle(options)

    if (this.displayPercentValue) {
      this.displayPercentInTooltip(options)
    }

    if (this.useThemeColorsValue) {
      this.applyThemeColors(options)
      this.resolveThemeColors(data)
    }

    const chartjs = await import('chart.js').catch(optionalPeer('chart.js'))
    // disconnect() can land while the import is pending, and nothing would ever destroy a
    // chart built on the detached canvas.
    if (!chartjs || !this.element.isConnected) return
    const { Chart, registerables } = chartjs

    Chart.register(...registerables)

    // What the legend hid lives on the instance a theme switch replaces: a series as its
    // dataset's visibility, which the new one reads from `hidden`, and a slice of a pie, doughnut
    // or polar area by data index, which it can only be told once built.
    if (this.chart) {
      data.datasets?.forEach((dataset, index) => { dataset.hidden = !this.chart.isDatasetVisible(index) })
    }
    const hiddenSlices = this.hiddenSlices()

    this.chart?.destroy()
    this.chart = new Chart(element.getContext('2d'), {
      type: this.typeValue,
      data,
      options
    })
    hiddenSlices.forEach((index) => this.chart.toggleDataVisibility(index))
    if (hiddenSlices.length) this.chart.update()
  }

  hiddenSlices () {
    if (!this.chart) return []

    return this.chart.data.labels.flatMap((_, index) => this.chart.getDataVisibility(index) ? [] : [index])
  }

  disconnect () {
    this.themeObserver?.disconnect()
    this.chart?.destroy()
    this.chart = undefined
  }

  get chartData () {
    if (!this.hasDataValue) {
      console.warn(
        '[stimulus-chartjs] You need to pass data as JSON to see the chart.'
      )
    }

    return this.dataValue
  }

  // Get computed CSS color from DaisyUI theme variables
  // DaisyUI 5 variables return full oklch values like "oklch(45% .24 277.023)"
  getThemeColor (varName, alpha = 1) {
    const style = window.getComputedStyle(document.documentElement)
    const colorValue = style.getPropertyValue(varName).trim()

    if (!colorValue) return null

    // The value is already a complete oklch() string
    if (alpha < 1) {
      // Extract the oklch parameters and add alpha
      // oklch(45% .24 277.023) -> oklch(45% .24 277.023 / 0.5)
      const match = colorValue.match(/oklch\(([^)]+)\)/)
      if (match) {
        return `oklch(${match[1]} / ${alpha})`
      }
      // Fallback: wrap with color-mix for other formats
      return `color-mix(in oklch, ${colorValue} ${Math.round(alpha * 100)}%, transparent)`
    }
    return colorValue
  }

  // Ruby writes the theme's colours as CSS naming a `var(--color-*)` (Bali::Color.css, alone or
  // inside Chart::Dataset#apply_alpha's color-mix()), which a canvas cannot paint. The browser
  // resolves each one in the current theme; any other colour is the host's and stays as written.
  resolveThemeColors (data) {
    const probe = document.body.appendChild(document.createElement('span'))
    probe.hidden = true
    const resolve = (colour) => {
      if (typeof colour !== 'string' || !colour.includes('var(--color-')) return colour

      probe.style.color = colour
      return window.getComputedStyle(probe).color
    }

    data.datasets?.forEach((dataset) => {
      Object.keys(dataset).filter((key) => key.endsWith('Color')).forEach((key) => {
        dataset[key] = Array.isArray(dataset[key]) ? dataset[key].map(resolve) : resolve(dataset[key])
      })
    })
    probe.remove()
  }

  // Apply DaisyUI theme colors to chart options
  applyThemeColors (options) {
    // DaisyUI 5 uses full variable names
    const gridColor = this.getThemeColor('--color-base-content', 0.1)
    const tickColor = this.getThemeColor('--color-base-content', 0.7)
    const tooltipBg = this.getThemeColor('--color-base-200', 0.95)
    const tooltipText = this.getThemeColor('--color-base-content')
    const tooltipBorder = this.getThemeColor('--color-base-content', 0.2)

    // Configure scales
    if (options.scales) {
      for (const scale in options.scales) {
        const scaleConfig = options.scales[scale]

        // Apply grid styling
        if (scaleConfig.grid?.useThemeColors) {
          scaleConfig.grid.color = gridColor
          scaleConfig.grid.borderColor = gridColor
          delete scaleConfig.grid.useThemeColors
        }

        // Apply tick styling
        if (scaleConfig.ticks?.useThemeColors) {
          scaleConfig.ticks.color = tickColor
          delete scaleConfig.ticks.useThemeColors
        }

        // Apply title styling
        if (scaleConfig.title) {
          scaleConfig.title.color = tickColor
        }
      }
    }

    // Configure tooltip with enhanced styling
    if (options.plugins?.tooltip?.useThemeColors) {
      options.plugins.tooltip.backgroundColor = tooltipBg
      options.plugins.tooltip.titleColor = tooltipText
      options.plugins.tooltip.bodyColor = tooltipText
      options.plugins.tooltip.borderColor = tooltipBorder
      options.plugins.tooltip.borderWidth = 1
      options.plugins.tooltip.cornerRadius = 8
      options.plugins.tooltip.padding = { top: 10, bottom: 10, left: 14, right: 14 }
      options.plugins.tooltip.boxPadding = 6
      options.plugins.tooltip.displayColors = true
      options.plugins.tooltip.usePointStyle = true
      options.plugins.tooltip.titleFont = {
        family: ChartController.FONT_FAMILY,
        size: 13,
        weight: '600'
      }
      options.plugins.tooltip.bodyFont = {
        family: ChartController.FONT_FAMILY,
        size: 12,
        weight: '400'
      }
      options.plugins.tooltip.titleMarginBottom = 8
      options.plugins.tooltip.caretSize = 6
      options.plugins.tooltip.caretPadding = 8
      delete options.plugins.tooltip.useThemeColors
    }

    // Configure legend
    if (options.plugins?.legend?.labels?.useThemeColors) {
      options.plugins.legend.labels.color = tickColor
      options.plugins.legend.labels.font = {
        family: ChartController.FONT_FAMILY,
        size: 12,
        weight: '500'
      }
      options.plugins.legend.labels.padding = 16
      options.plugins.legend.labels.usePointStyle = true
      options.plugins.legend.labels.pointStyle = 'circle'
      options.plugins.legend.labels.boxWidth = 8
      options.plugins.legend.labels.boxHeight = 8
      delete options.plugins.legend.labels.useThemeColors
    }

    // Ensure ticks have proper font
    if (options.scales) {
      for (const scale in options.scales) {
        const scaleConfig = options.scales[scale]
        if (scaleConfig.ticks) {
          scaleConfig.ticks.font = {
            family: ChartController.FONT_FAMILY,
            size: 12,
            ...(scaleConfig.ticks.font || {})
          }
        }
      }
    }
  }

  addPrefixAndSuffixToAxisLabel = options => {
    if (!options.scales) return

    for (const scale in options.scales) {
      if (Object.hasOwn(options.scales[scale], 'label')) {
        const suffix = options.scales[scale].label.suffix
        const prefix = options.scales[scale].label.prefix

        options.scales[scale].ticks ||= {}
        options.scales[scale].ticks.callback = (value, index, ticks) => {
          return `${prefix || ''} ${value} ${suffix || ''}`.trim()
        }
      }
    }
  }

  addPrefixAndSuffixToTooltipLabel = options => {
    if (!options.plugins?.tooltip?.callbacks?.label) return

    const callbackLabelData = options.plugins?.tooltip?.callbacks?.label

    // Skip if it's not an object (already processed or custom function)
    if (typeof callbackLabelData !== 'object') return

    options.plugins.tooltip.callbacks.label = context => {
      const suffix = callbackLabelData[context.dataset.yAxisID]?.suffix
      const prefix = callbackLabelData[context.dataset.yAxisID]?.prefix

      let label = context.dataset.label
      if (label) {
        label += ':'
      }
      return (
        `${label} ${prefix ?? ''} ${context.parsed.y ?? context.parsed} ${suffix ?? ''}`.trim()
      )
    }
  }

  overrideTooltipTitle = options => {
    options.plugins ||= {}
    options.plugins.tooltip ||= {}
    options.plugins.tooltip.callbacks ||= {}

    options.plugins.tooltip.callbacks.title = context => {
      return this.labelsValue[context[0].dataIndex]
    }
  }

  displayPercentInTooltip (options) {
    options.plugins.tooltip.callbacks.label = context => {
      const label = context.formattedValue || ''

      const total = context.dataset.data.reduce((a, b) => a + b, 0)
      const percent = (context.dataset.data[context.dataIndex] / total) * 100

      return `${label} (${percent.toFixed(2)}%)`
    }
  }
}
