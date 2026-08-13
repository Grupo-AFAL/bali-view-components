# React islands (`bali-view-components/react-island`)

The official mechanism for mounting React inside a Hotwire app. An **island** is a self-contained React component mounted by a Stimulus controller on the host app's own Stimulus application — the pattern the [block editor](block-editor.md) established, extracted here so new islands (the Gantt, future canvas-heavy UI) do not re-implement its mechanics.

Bali deliberately does **not** use [turbo-mount](https://github.com/skryukov/turbo_mount). Islands ride the Stimulus lifecycle the rest of the library already uses: `connect` mounts, `disconnect` unmounts, Turbo Streams and drawers/modals that inject content with `innerHTML` all work because Stimulus observes the DOM.

The Gantt used as the running example below is no longer hypothetical: Bali ships it as a ready-made island (#705). A host that wants the interactive Gantt writes **no controller at all** — its dedicated entry is one line, `import 'bali-view-components/gantt-entry'`, its main bundle imports `bali-view-components/gantt-loader`, and the shipped `GanttController` (a `ReactIslandController` subclass, `app/components/bali/gantt/index.js`) is the reference implementation of everything this page describes. The example remains as written because it shows what building a NEW island takes.

## Never start a second Stimulus Application

The one hard rule. An island registers on the application the host exposes as `window.Stimulus` — never on an `Application.start()` of its own. Two applications scanning the same DOM mount **every** controller twice: double drawers, double editors, double event handlers. This is not hypothetical; afal-apps shipped exactly this bug in its `gantt.js`:

```javascript
// afal-apps app/javascript/gantt.js — DO NOT copy this
import { Application } from '@hotwired/stimulus'
import { TurboMount } from 'turbo-mount'

const application = Application.start()   // ← second Application, same DOM
new TurboMount({ application })
```

`registerIsland` (below) encapsulates the correct dance, with an idempotence guard.

## The pieces

One npm subpath, `bali-view-components/react-island`, exports three things; one Rails helper completes the loop. The module itself imports only `@hotwired/stimulus` — React is loaded by your subclass, so the main bundle stays React-free.

| Piece | Where it goes | Job |
|---|---|---|
| `ReactIslandController` | your island's controller file | Base class: `createRoot`, values→props, ErrorBoundary, Turbo cache exclusion, unmount on disconnect, and the fallback swap below |
| `registerIsland(name, Controller)` | the island's dedicated bundler entry | Registers on `window.Stimulus`, idempotently |
| `startIslandLoader(name)` | the MAIN bundle | Lazy-loads the island's entry the first time its controller appears in the DOM |
| `react_island_meta_tags(name, js:, css: nil)` | the host layout's `<head>` | Publishes the digested bundle paths the loader injects |

### 1. The controller — subclass `ReactIslandController`

```javascript
// app/javascript/controllers/gantt_controller.js
import { ReactIslandController } from 'bali-view-components/react-island'

export default class GanttController extends ReactIslandController {
  static values = {
    tasks: { type: Array, default: [] },
    editable: { type: Boolean, default: false }
  }

  async loadComponent () {
    const [react, reactDom, { default: Gantt }] = await Promise.all([
      import('react'),
      import('react-dom/client'),
      import('../components/Gantt.jsx')
    ])
    return { react, reactDom, Component: Gantt }
  }
}
```

`loadComponent()` is the only required override. The subclass performs the `import()` calls itself so the bundler attributes `react`, `react-dom` and the JSX to the **island's** entry — they stay out of the main bundle and remain optional peers for apps without islands.

Overridable hooks, all with working defaults:

| Hook | Default | Override when |
|---|---|---|
| `loadComponent()` | throws | always — return `{ react, reactDom, Component }` (module namespaces of `react` and `react-dom/client`) |
| `componentProps()` | every declared Stimulus value, by camelCase name | renaming, filtering (drop controller-only values), deriving props |
| `mountElement()` | `this.element` | the island shares its element with server-rendered chrome (hidden inputs, fallback markup) |
| `errorFallback(error)` | `'This section failed to load.'` | localizing — serve the string through a Stimulus value |
| `beforeUnmount()` | no-op | teardown that must precede `root.unmount()` while the DOM is attached (the block editor destroys ProseMirror here) |

What the base class does so you do not have to:

- **Mounts into a fresh `<div>`** it creates inside `mountElement()`, so React owns a node nothing else morphs.
- **Guards the async gap**: if the controller disconnects while `loadComponent()` is in flight, nothing mounts.
- **Wraps your component in an ErrorBoundary** (see below), so a render crash shows a fallback instead of a white hole.
- **Adds `<meta name="turbo-cache-control" content="no-cache">`** while mounted (and removes it on disconnect). React's fiber tree does not survive Turbo's cache → preview → replace cycle; a cached page would restore as a broken island. A host-provided meta is respected and left alone.
- **Unmounts the root on `disconnect`**, after `beforeUnmount()`.

### 2. The entry — one file per island

An island bundle is heavy (React plus the component), so it gets its own bundler entry — in esbuild, an extra element in `entryPoints`. The entire body:

```javascript
// app/javascript/gantt-entry.js
import { registerIsland } from 'bali-view-components/react-island'
import GanttController from './controllers/gantt_controller'

registerIsland('gantt', GanttController)
```

If the island imports CSS from JS (e.g. `@xyflow/react/dist/style.css`), the bundler emits it as a sibling stylesheet of the entry — pass its name to the helper in step 4.

### 3. The loader — one line in the main bundle

```javascript
// app/javascript/application.js
import { startIslandLoader } from 'bali-view-components/react-island'

startIslandLoader('gantt')
```

Weighs nothing. Watches the DOM (initial content and a `MutationObserver`) and, the first time an element matching `[data-controller~="gantt"]` appears — including content drawers and modals inject with `innerHTML`, where a `<script>` tag would never execute — injects the `<link>` and `<script>` for the real bundle from the meta tags of step 4.

Defaults derive from the name; `startIslandLoader('gantt', { selector, jsMeta, cssMeta })` overrides them for special cases.

### 4. The meta tags — in the host layout

Only the server knows the digested asset paths, so the layout publishes them:

```erb
<%# app/views/layouts/application.html.erb, inside <head> %>
<%= react_island_meta_tags('gantt', js: 'gantt-entry.js', css: 'gantt-entry.css') %>
```

Emits `<meta name="bali-gantt-js">` / `<meta name="bali-gantt-css">` — exactly the names the loader derives from `'gantt'`. Pass `css: nil` (the default) if the entry emits no stylesheet.

`block_editor_meta_tags` is this helper's block-editor spelling and is **not** deprecated; both are exposed to host views by the engine.

## Whatever the server rendered inside the mount is the fallback

An island's mount element does not have to be empty. Anything the server
rendered inside it is what a visitor looks at until React is ready — and Bali
treats it that way:

- **It survives until the island actually paints.** The base prepends React's
  container and removes the fallback from inside the first commit
  (`componentDidMount` — after the DOM carries the island, before the browser
  paints). One frame shows the fallback, the next shows the island, and none
  shows an empty box. Clearing the mount up front and letting a concurrent root
  fill it later looks fine on a fast machine and is a white screen for ~2s on a
  heavy island with a throttled CPU; that is measured, on `Bali::Gantt`'s
  300-item board at 6x.
- **It survives a bundle that never arrives.** The load-error notice is
  *prepended* to it, not swapped for it — a failed chunk costs the interactive
  layer, not the page.
- **It should therefore be worth looking at.** `Bali::Gantt` `mode: :interactive`
  renders its entire static board there. An island whose mount is empty (the
  block editor's editor target) loses nothing by it: the base falls back to
  replacing the mount wholesale.

If your island measures its own viewport space in a layout effect, note that
layout effects run *before* the parent's `componentDidMount` — which is why the
container is prepended rather than appended, so the island is first in flow and
reads its real `getBoundingClientRect().top` while the fallback is still there.

## Errors: the boundary and the `onError` hook

Two failure modes, one reporting channel:

- **Load failures** (`loadComponent()` rejects — missing optional peer, network): the island prepends the `errorFallback(error)` message, keeping any server-rendered fallback underneath it.
- **Render crashes** (the component throws): a built-in React ErrorBoundary catches it and swaps the island for the same fallback. Bali builds the boundary from the React instance *you* loaded, so the gem itself never imports React.

Both report through one configurable static hook, so an app plugs its tracker in once for every island:

```javascript
import { ReactIslandController } from 'bali-view-components/react-island'
import * as Sentry from '@sentry/browser'

ReactIslandController.onError = (error, { identifier, phase }) => {
  Sentry.captureException(error, { tags: { island: identifier, phase } })
}
```

`phase` is `'load'` or `'render'`. Bali deliberately carries no tracker dependency — gobierno-corporativo wraps its islands in `Sentry.ErrorBoundary` today, and this hook is how it keeps doing that without the gem depending on `@sentry/react`.

## When does something become an island?

React is the exception in Bali, not the rule — the default remains Turbo + Stimulus + ViewComponents. The bar for adding an island **to the gem**:

1. **Two or more apps need it with the same contract.** One app's widget lives in that app; the gem hosts what is shared. The block editor and the Gantt (#704/#705) meet the bar.
2. **The interactivity genuinely exceeds Stimulus.** Canvas-style editing, drag-with-live-recalculation, virtualized trees. A form, a dropdown or a filter never qualifies.

Deferred candidate on record: **BPMN/process-flow editing** (gobierno-corporativo's `ProcessFlowEditor`). It stays app-local until a second app needs a canvas with the same contract — that is the trigger to promote it here.

## Working example

The dummy app wires a toy counter through the full production loop — loader, meta tags, entry, subclass:

- Previews: `/lookbook/preview/bali/react_island/default` (plus `two_islands` and `load_error`), templates at `app/components/bali/react_island/previews/`.
- Island + controller + entry: `spec/dummy/app/javascript/{islands/CounterIsland.jsx,controllers/react_island_demo_controller.js,island-demo.js}`.
- Contract tests: `cypress/e2e/react-island.cy.js` (mount, props, single registration across Turbo visits, unmount, both error paths) and `test/bali/react_island_helper_test.rb` / `test/requests/react_island_previews_test.rb`.
