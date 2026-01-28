/**
 * Bali Gantt Chart - Optional Module
 *
 * This module contains the Gantt Chart controllers.
 * Import separately to keep the main bundle lightweight.
 *
 * Usage:
 *   import { GanttChartController, GanttFoldableItemController, registerGantt } from 'bali-view-components/gantt'
 *   application.register('gantt-chart', GanttChartController)
 *   application.register('gantt-foldable-item', GanttFoldableItemController)
 *   // OR
 *   registerGantt(application)
 */

import { GanttChartController } from '../../components/bali/gantt_chart/index'
import { GanttFoldableItemController } from '../../components/bali/gantt_chart/gantt_foldable_item'

export { GanttChartController } from '../../components/bali/gantt_chart/index'
export { GanttFoldableItemController } from '../../components/bali/gantt_chart/gantt_foldable_item'

/**
 * Register gantt controllers with a Stimulus application
 * @param {Application} application - Stimulus application instance
 */
export function registerGantt (application) {
  application.register('gantt-chart', GanttChartController)
  application.register('gantt-foldable-item', GanttFoldableItemController)
}
