import { Controller } from '@hotwired/stimulus'

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

  // DaisyUI 5 theme color variable names (full form)
  static THEME_COLOR_VARS = [
    '--color-primary',
    '--color-secondary',
    '--color-accent',
    '--color-info',
    '--color-success',
    '--color-warning',
    '--color-error'
  ]

  async connect () {
    const element = this.hasCanvasTarget ? this.canvasTarget : this.element
    const options = this.optionsValue || {}
    const data = this.dataValue || {}

    this.addPrefixAndSuffixToAxisLabel(options)
    this.addPrefixAndSuffixToTooltipLabel(options)
    this.overrideTooltipTitle(options)

    if (this.displayPercentValue) {
      this.displayPercentInTooltip(options)
    }

    if (this.useThemeColorsValue) {
      this.applyThemeColors(options)
      this.applyThemeColorsToDatasets(data)
    }

    const { Chart, registerables } = await import('chart.js')

    Chart.register(...registerables)

    this.chart = new Chart(element.getContext('2d'), {
      type: this.typeValue,
      data: data,
      options
    })
  }

  disconnect () {
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
    const style = getComputedStyle(document.documentElement)
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

  // Get an array of theme colors for datasets
  getThemeColorPalette () {
    return ChartController.THEME_COLOR_VARS.map(varName => ({
      solid: this.getThemeColor(varName, 1),
      border: this.getThemeColor(varName, 0.8),
      background: this.getThemeColor(varName, 0.5)
    }))
  }

  // Check if a color string contains CSS variable or color-mix
  isCssVarColor (color) {
    return color && typeof color === 'string' && (
      color.includes('var(--color-') ||
      color.includes('color-mix(') ||
      color.includes('oklch(var(')
    )
  }

  // Apply theme colors to dataset colors
  applyThemeColorsToDatasets (data) {
    if (!data.datasets) return

    const palette = this.getThemeColorPalette()

    data.datasets.forEach((dataset, index) => {
      const colorIndex = index % palette.length
      const colors = palette[colorIndex]

      // Get the first color to check if it's a CSS variable color
      const firstBorderColor = Array.isArray(dataset.borderColor)
        ? dataset.borderColor[0]
        : dataset.borderColor

      // Replace CSS variable colors with computed colors
      if (this.isCssVarColor(firstBorderColor)) {
        if (Array.isArray(dataset.borderColor) && dataset.borderColor.length > 1) {
          // Multi-color (pie/doughnut charts) - each slice gets a different color
          dataset.borderColor = dataset.borderColor.map((_, i) =>
            palette[i % palette.length].border
          )
          dataset.backgroundColor = dataset.backgroundColor.map((_, i) =>
            palette[i % palette.length].background
          )
        } else {
          // Single color (bar/line charts) - whole dataset gets one color
          // Use the computed color for this dataset based on its index
          dataset.borderColor = colors.border
          dataset.backgroundColor = colors.background
        }
      }
    })
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

    // Configure tooltip
    if (options.plugins?.tooltip?.useThemeColors) {
      options.plugins.tooltip.backgroundColor = tooltipBg
      options.plugins.tooltip.titleColor = tooltipText
      options.plugins.tooltip.bodyColor = tooltipText
      options.plugins.tooltip.borderColor = tooltipBorder
      options.plugins.tooltip.borderWidth = 1
      options.plugins.tooltip.cornerRadius = 8
      options.plugins.tooltip.padding = 12
      delete options.plugins.tooltip.useThemeColors
    }

    // Configure legend
    if (options.plugins?.legend?.labels?.useThemeColors) {
      options.plugins.legend.labels.color = tickColor
      options.plugins.legend.labels.font = {
        size: 12,
        weight: '500'
      }
      options.plugins.legend.labels.padding = 16
      options.plugins.legend.labels.usePointStyle = true
      options.plugins.legend.labels.pointStyle = 'circle'
      delete options.plugins.legend.labels.useThemeColors
    }
  }

  addPrefixAndSuffixToAxisLabel = options => {
    if (!options.scales) return

    for (const scale in options.scales) {
      if (Object.hasOwn(options.scales[scale], 'label')) {
        const suffix = options.scales[scale].label.suffix
        const prefix = options.scales[scale].label.prefix

        options.scales[scale].ticks ||= {}
        const existingCallback = options.scales[scale].ticks.callback
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
