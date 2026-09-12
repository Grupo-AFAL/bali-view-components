/**
 * Bali Gantt Island - Self-registering entry
 *
 * Make this the entire body of a dedicated bundler entry (e.g.
 * app/javascript/gantt-island.js):
 *
 *   import 'bali-view-components/gantt-entry'
 *
 * A dedicated entry matters for two reasons:
 *   1. GanttFlow imports CSS from JS (@xyflow/react's stylesheet plus the
 *      island's own flow.css). In its own entry, esbuild emits it as the
 *      entry's .css file; inside the main entry it would be appended to the
 *      application stylesheet instead.
 *   2. React + React Flow are far too heavy for the main bundle. Pair this
 *      entry with 'bali-view-components/gantt-loader' to load it on demand.
 *
 * `registerIsland` registers on the Stimulus application the host exposes as
 * window.Stimulus — NEVER a second Application (two applications scanning the
 * same DOM mount every controller twice; afal-apps shipped exactly that bug
 * in its old gantt.js) — with an idempotence guard.
 */
import { registerIsland } from './react-island'
import { GanttController } from '../../components/bali/gantt/index'

registerIsland('gantt', GanttController)
