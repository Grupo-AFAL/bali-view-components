/**
 * Bali Charts - Optional Module
 *
 * This module contains the Chart controller which depends on Chart.js.
 * Import separately to keep the main bundle lightweight.
 *
 * Usage:
 *   import { ChartController, registerCharts } from 'bali/charts'
 *   application.register('chart', ChartController)
 *   // OR
 *   registerCharts(application)
 */

import { ChartController } from '../../components/bali/chart/index'

export { ChartController } from '../../components/bali/chart/index'

/**
 * Register chart controller with a Stimulus application
 * @param {Application} application - Stimulus application instance
 */
export function registerCharts (application) {
  application.register('chart', ChartController)
}
