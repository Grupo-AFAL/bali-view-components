// Dedicated esbuild entry for the Gantt island (see esbuild.config.mjs).
// A real host app's entry is exactly this line: the gem's gantt-entry
// registers the GanttController on window.Stimulus (never a second Stimulus
// Application) with an idempotence guard, and the react/react-dom/
// @xyflow/react imports inside the controller's loadComponent() are
// attributed to THIS bundle, keeping the main one React-free. esbuild emits
// the CSS GanttFlow imports (@xyflow/react's stylesheet + flow.css) as
// gantt-island.css.
//
// The main bundle lazy-loads this file through startIslandLoader('gantt')
// plus the react_island_meta_tags helper -- see application.js and the
// previews at app/components/bali/gantt/previews/.
import 'bali/gantt-entry'
