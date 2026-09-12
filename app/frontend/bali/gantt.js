/**
 * Bali Gantt Island - Optional Module
 *
 * WARNING: this module requires React and React Flow. Import it separately
 * and only where the interactive Gantt is needed — never from the main
 * bundle. Required optional peers:
 *
 *   yarn add react react-dom @xyflow/react date-fns @rails/request.js
 *
 * Usage (see docs/api/react-island.md for the full island wiring):
 *
 *   import { GanttController, registerGantt } from 'bali-view-components/gantt'
 *   registerGantt(application)
 *   // OR make 'bali-view-components/gantt-entry' your dedicated bundler
 *   // entry, which self-registers on window.Stimulus, and lazy-load it with
 *   // 'bali-view-components/gantt-loader' from the main bundle.
 *
 * The subpath deliberately reuses `./gantt` (decision D13): the old
 * GanttChart export was removed in 3.0 with zero consumers, so the name is
 * free and keeps exact symmetry with ./block-editor + -entry + -loader.
 */

import { GanttController } from '../../components/bali/gantt/index'

export { GanttController } from '../../components/bali/gantt/index'

/**
 * Register the Gantt island controller with a Stimulus application.
 * @param {Application} application - Stimulus application instance
 */
export function registerGantt (application) {
  application.register('gantt', GanttController)
}
