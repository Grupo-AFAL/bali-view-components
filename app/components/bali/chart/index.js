import { Controller } from '@hotwired/stimulus'
import Chart from 'chart.js/auto'

export class ChartController extends Controller {
  static targets = ['canvas']
  static values = {
    type: {
      type: String,
      default: 'line'
    },
    data: Object,
    options: Object
  }

  connect() {
    const element = this.hasCanvasTarget ? this.canvasTarget : this.element
    let options = this.optionsValue || {}

    this.addPrefixAndSuffixToAxisLabel(options)
    this.addPrefixAndSuffixToTooltipLabel(options)
    this.overrideTooltipTitle(options)

    this.chart = new Chart(element.getContext('2d'), {
      type: this.typeValue,
      data: this.chartData,
      options: options
    })
  }

  disconnect() {
    this.chart.destroy()
    this.chart = undefined
  }

  get chartData() {
    if (!this.hasDataValue) {
      console.warn('[stimulus-chartjs] You need to pass data as JSON to see the chart.')
    }

    return this.dataValue
  }

  addPrefixAndSuffixToAxisLabel = (options) => {
    if (!options.scales) return

    for (const scale in options.scales) {
      if (Object.hasOwn(options.scales[scale], 'label')) {
        const suffix = options.scales[scale].label.suffix
        const prefix = options.scales[scale].label.prefix

        options.scales[scale]['ticks'] ||= {}
        options.scales[scale].ticks['callback'] = (value, index, ticks) => {
          return `${prefix || ''} ${value} ${suffix || ''}`.trim()
        }
      }
    }
  }

  addPrefixAndSuffixToTooltipLabel = (options) => {
    if (!options.plugins?.tooltip?.callbacks?.label) return

    const callbackLabelData = options.plugins?.tooltip?.callbacks?.label

    options.plugins.tooltip.callbacks.label = (context) => {
      const suffix = callbackLabelData[context.dataset.yAxisID].suffix
      const prefix = callbackLabelData[context.dataset.yAxisID].prefix

      let label = context.dataset.label
      if (label) {
        label += ':'
      }
      return `${label} ${prefix || ''} ${context.parsed.y} ${suffix || ''}`.trim();
    }
  }

  overrideTooltipTitle = (options) => {
    options.plugins ||= {}
    options.plugins.tooltip ||= {}
    options.plugins.tooltip.callbacks ||= {}

    options.plugins.tooltip.callbacks.title = (context) => {
      let contextData = context[0]
      let label = contextData.label

      if (this.dataValue.labels[contextData.dataIndex]) {
        label = this.dataValue.labels[contextData.dataIndex]
      }

      return label
    }
  }
}
