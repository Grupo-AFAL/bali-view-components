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
    displayPercent: { type: Boolean, default: false }
  }

  async connect () {
    const element = this.hasCanvasTarget ? this.canvasTarget : this.element
    const options = this.optionsValue || {}

    this.addPrefixAndSuffixToAxisLabel(options)
    this.addPrefixAndSuffixToTooltipLabel(options)
    this.overrideTooltipTitle(options)

    if (this.displayPercentValue) {
      this.displayPercentInTooltip(options)
    }

    const { Chart, registerables } = await import('chart.js')

    Chart.register(...registerables)

    this.chart = new Chart(element.getContext('2d'), {
      type: this.typeValue,
      data: this.chartData,
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

    options.plugins.tooltip.callbacks.label = context => {
      const suffix = callbackLabelData[context.dataset.yAxisID]?.suffix
      const prefix = callbackLabelData[context.dataset.yAxisID]?.prefix

      let label = context.dataset.label
      if (label) {
        label += ':'
      }
      return `${label} ${prefix || ''} ${context.parsed.y} ${
        suffix || ''
      }`.trim()
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
