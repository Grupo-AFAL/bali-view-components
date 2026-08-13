// Stimulus controller of the Gantt island (#705): a ReactIslandController
// subclass — the base handles createRoot, values→props, the ErrorBoundary,
// Turbo cache exclusion and unmount on disconnect (see
// docs/api/react-island.md). This file only declares the values and loads the
// component; react/react-dom/@xyflow/react are imported HERE so the bundler
// attributes them to the island's entry and the main bundle stays React-free.
//
// The element a host renders:
//
//   <div data-controller="gantt"
//        data-gantt-data-value="<%= gantt.to_json %>"
//        data-gantt-catalogs-value="..." data-gantt-i18n-value="..."
//        data-gantt-editable-value="true" data-gantt-patch-url-value="..."></div>
//
// Values map 1:1 to GanttFlow props (the base's componentProps default).
import { ReactIslandController } from '../../../frontend/bali/react-island'

export class GanttController extends ReactIslandController {
  static values = {
    // The Bali::Gantt data contract: { window, groups, items, dependencies,
    // critical_ids } — documented in Bali::Gantt::Data.
    data: Object,
    // { statuses: [{ value, label, color }], priorities: [{ value, label,
    // hue }] } (D11). color is a daisyUI variable name or null; hue is an
    // oklch hue or null. Defaults live in ganttColors.js.
    catalogs: { type: Object, default: {} },
    // Flat strings table from bali_view.gantt.island.* (D12); English
    // defaults in i18n.js fill any missing key.
    i18n: { type: Object, default: {} },
    editable: { type: Boolean, default: false },
    manageable: { type: Boolean, default: false },
    patchUrl: { type: String, default: '' },
    dependenciesUrl: { type: String, default: '' },
    scheduleUrl: { type: String, default: '' },
    // Opens the item in the Bali drawer; "__ID__" is replaced by the item id.
    itemUrlTemplate: { type: String, default: '' },
    newGroupUrl: { type: String, default: '' },
    newItemUrl: { type: String, default: '' },
    // DOM id of the server-rendered "no dates" drawer (#1015). Present only
    // when the document carries undated items; the footer names it through
    // `bali:drawer:open`. Empty = no drawer, no footer link.
    undatedDrawerId: { type: String, default: '' },
    // Namespaced query param the zoom persists into (D14).
    zoomParam: { type: String, default: 'gantt_zoom' },
    // Zoom to open at when the URL carries no param — Bali::Gantt::Component
    // fills it with the density it resolved from the window, so mounting does
    // not rescale the board under the visitor (#719). Empty = "week".
    initialZoom: { type: String, default: '' },
    // date-fns display locale: 'en' (default) or 'es'.
    dateLocale: { type: String, default: 'en' }
  }

  // The component element carries server-rendered chrome NEXT TO the mount —
  // the "no dates" drawer (#1015). React retires every child of the mount
  // element on its first commit, so the island mounts into its own inner div
  // and the drawer survives the swap.
  mountElement () {
    return this.element.querySelector('.bali-gantt-mount') || this.element
  }

  async loadComponent () {
    const [react, reactDom, { default: GanttFlow }] = await Promise.all([
      import('react'),
      import('react-dom/client'),
      import('./GanttFlow.jsx')
    ])

    return { react, reactDom, Component: GanttFlow }
  }

  errorFallback () {
    return this.i18nValue.load_error || 'The timeline failed to load.'
  }
}
