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

  connect () {
    const element = this.hasCanvasTarget ? this.canvasTarget : this.element

    this.chart = new Chart(element.getContext('2d'), {
      type: this.typeValue,
      data: this.chartData,
      options: this.chartOptions
    })
  }

  disconnect () {
    this.chart.destroy()
    this.chart = undefined
  }

  get chartData () {
    if (!this.hasDataValue) {
      console.warn('[stimulus-chartjs] You need to pass data as JSON to see the chart.')
    }

    return this.dataValue
  }

  get chartOptions () {
    return {
      ...this.defaultOptions,
      ...this.optionsValue
    }
  }

  get defaultOptions () {
    return {}
  }
}
