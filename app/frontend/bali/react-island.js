/**
 * Bali React Island - official mechanism for mounting React inside a Hotwire app
 *
 * An "island" is a self-contained React component mounted by a Stimulus
 * controller on the HOST app's Stimulus application. This is the pattern the
 * block editor established; this module extracts its mechanics so new islands
 * (gantt, and any future canvas-heavy UI) do not re-implement them.
 *
 * Three pieces, all exported from 'bali-view-components/react-island':
 *
 *   - `ReactIslandController` -- base Stimulus controller. Subclass it and
 *     implement `loadComponent()`; the base handles createRoot, values->props,
 *     an ErrorBoundary, Turbo cache exclusion, and unmount on disconnect.
 *   - `registerIsland(name, Controller)` -- the entire body of an island's
 *     dedicated bundler entry. Registers on `window.Stimulus`, idempotently.
 *   - `startIslandLoader(name)` -- import in the MAIN bundle. Lazy-loads the
 *     island's entry the first time its controller appears in the DOM, using
 *     the <meta> tags emitted by the `react_island_meta_tags` Rails helper.
 *
 * NEVER start a second Stimulus Application for an island. Two applications
 * scanning the same DOM mount every controller twice -- afal-apps shipped
 * exactly that bug (gantt.js did `Application.start()` + TurboMount on top of
 * the app's own application). Islands register on the one the host exposes as
 * `window.Stimulus`.
 *
 * This module imports only @hotwired/stimulus. React itself is loaded by the
 * subclass inside `loadComponent()`, so the bundler attributes the dependency
 * to the island's own entry and the main bundle stays React-free.
 */
import { Controller } from '@hotwired/stimulus'

const ERROR_FALLBACK_CLASS = 'text-error text-sm p-4'

// One ErrorBoundary class per React instance. The boundary cannot be defined
// at module scope because `react` is an optional peer this module never
// imports -- it is built from the copy of React the subclass loaded.
const boundaries = new WeakMap()

const errorBoundaryFor = (react) => {
  if (!boundaries.has(react)) {
    boundaries.set(react, class ReactIslandErrorBoundary extends react.Component {
      constructor (props) {
        super(props)
        this.state = { error: null }
      }

      static getDerivedStateFromError (error) {
        return { error }
      }

      componentDidCatch (error, info) {
        this.props.onError?.(error, info)
      }

      render () {
        if (this.state.error) return this.props.fallback(this.state.error)

        return this.props.children
      }
    })
  }

  return boundaries.get(react)
}

export class ReactIslandController extends Controller {
  // Global error hook for every island: `(error, context) => {}` where context
  // carries { identifier, element, phase: 'load' | 'render' }. Assign it ONCE
  // from the host app to plug an error tracker in, e.g.:
  //
  //   ReactIslandController.onError = (error) => Sentry.captureException(error)
  //
  // Bali deliberately does not depend on any tracker itself; this hook exists
  // because real consumers (gobierno-corporativo) wrap their islands in
  // Sentry.ErrorBoundary and the gem cannot carry @sentry/react for them.
  static onError = null

  /**
   * REQUIRED override. Load React and the island's component, e.g.:
   *
   *   async loadComponent () {
   *     const [react, reactDom, { default: Component }] = await Promise.all([
   *       import('react'),
   *       import('react-dom/client'),
   *       import('./MyIsland.jsx')
   *     ])
   *     return { react, reactDom, Component }
   *   }
   *
   * The subclass performs the `import()` calls itself so the bundler
   * attributes react/react-dom and the JSX to the ISLAND's entry, keeping
   * them out of the main bundle and optional for apps without islands.
   *
   * @returns {Promise<{react: object, reactDom: object, Component: Function}>}
   *   `react` and `reactDom` are the module namespaces of 'react' and
   *   'react-dom/client'.
   */
  async loadComponent () {
    throw new Error(
      `Bali ReactIsland [${this.identifier}]: subclasses must implement ` +
      'loadComponent() and return { react, reactDom, Component }.'
    )
  }

  /**
   * Props passed to the React component. Default: every declared Stimulus
   * value, by its camelCase name. Override to rename, filter or derive.
   */
  componentProps () {
    const props = {}
    for (const name of this._valueNames()) props[name] = this[`${name}Value`]

    return props
  }

  /**
   * Element whose children are replaced by the React mount point.
   * Default: the controller's element. Override when the island shares its
   * element with server-rendered chrome (e.g. a hidden form input).
   *
   * Whatever the server rendered inside this element is the island's FALLBACK:
   * it is what a visitor sees until React mounts, what a visitor without
   * JavaScript keeps, and — since the load-error path is non-destructive — what
   * stays on screen if the bundle never arrives. Render something usable there
   * when you can.
   */
  mountElement () {
    return this.element
  }

  /**
   * Message shown when the island fails to load or render. Override to
   * localize (e.g. serve the string through a Stimulus value).
   */
  errorFallback (_error) {
    return 'This section failed to load.'
  }

  /**
   * Hook invoked right before the React root unmounts, while the island's DOM
   * is still attached. Override for teardown that must precede unmount (the
   * block editor destroys its ProseMirror instance here -- see its CLAUDE.md).
   */
  beforeUnmount () {}

  async connect () {
    this._disconnected = false
    this._addTurboCacheMeta()

    try {
      const { react, reactDom, Component } = await this.loadComponent()
      if (this._disconnected) return

      this._react = react
      this._mountPoint = document.createElement('div')
      this.mountElement().replaceChildren(this._mountPoint)
      this.root = reactDom.createRoot(this._mountPoint)

      const { createElement } = react
      const Boundary = errorBoundaryFor(react)
      this.root.render(
        createElement(Boundary, {
          fallback: (error) =>
            createElement('p', { className: ERROR_FALLBACK_CLASS }, this.errorFallback(error)),
          onError: (error, info) => this._reportError(error, { phase: 'render', ...info })
        }, createElement(Component, this.componentProps()))
      )
    } catch (error) {
      this._reportError(error, { phase: 'load' })
      this._renderLoadFallback(error)
    }
  }

  disconnect () {
    this._disconnected = true
    this._removeTurboCacheMeta()

    try {
      this.beforeUnmount()
    } catch (error) {
      console.error(`Bali ReactIsland [${this.identifier}]: beforeUnmount failed:`, error)
    }

    if (this.root) {
      try { this.root.unmount() } catch { /* noop */ }
      this.root = null
    }
    this._mountPoint = null
    this._react = null
  }

  // --- Private ---

  _valueNames () {
    const names = new Set()
    let ctor = this.constructor
    while (ctor && ctor !== ReactIslandController) {
      if (Object.hasOwn(ctor, 'values')) {
        for (const key of Object.keys(ctor.values)) names.add(key)
      }
      ctor = Object.getPrototypeOf(ctor)
    }

    return names
  }

  _reportError (error, context = {}) {
    console.error(`Bali ReactIsland [${this.identifier}]:`, error)
    try {
      this.constructor.onError?.(error, {
        identifier: this.identifier,
        element: this.element,
        ...context
      })
    } catch (hookError) {
      console.error('Bali ReactIsland: the onError hook itself threw:', hookError)
    }
  }

  // NON-DESTRUCTIVE when the mount carries server-rendered content: that
  // content IS the fallback. Bali::Gantt `mode: :interactive` renders its whole
  // static board inside the mount precisely so something usable is on screen
  // until React takes over; replacing it with an error message would take a
  // working, navigable, keyboard-reachable UI away from a visitor whose only
  // problem is that a JS chunk did not arrive (rotated digest after a deploy,
  // dropped connection, a CSP that blocks the bundle). The message goes FIRST,
  // so it is read before the content it is warning about.
  //
  // An empty mount (the block editor's editor target, any island that renders
  // no fallback) still gets the plain replacement — same behaviour as before.
  _renderLoadFallback (error) {
    const mount = this.mountElement()
    mount.querySelectorAll(':scope > [data-bali-island-error]').forEach((el) => el.remove())

    const message = document.createElement('p')
    message.className = ERROR_FALLBACK_CLASS
    message.textContent = this.errorFallback(error)
    message.setAttribute('data-bali-island-error', '')

    if (mount.childElementCount > 0) mount.prepend(message)
    else mount.replaceChildren(message)
  }

  // Tell Turbo not to cache pages with a mounted island. React's internal
  // state (fiber tree, __reactContainer$ expando properties) does not survive
  // Turbo's cache -> preview -> replace cycle: the revisited page shows a
  // broken island. Added on connect, removed on disconnect; an existing
  // host-provided meta is respected and left alone.
  _addTurboCacheMeta () {
    if (document.querySelector('meta[name="turbo-cache-control"]')) return

    this._turboMeta = document.createElement('meta')
    this._turboMeta.name = 'turbo-cache-control'
    this._turboMeta.content = 'no-cache'
    document.head.appendChild(this._turboMeta)
  }

  _removeTurboCacheMeta () {
    if (!this._turboMeta) return

    this._turboMeta.remove()
    this._turboMeta = null
  }
}

/**
 * The entire body of an island's dedicated bundler entry:
 *
 *   // app/javascript/gantt-entry.js (host app)
 *   import { registerIsland } from 'bali-view-components/react-island'
 *   import { GanttController } from 'bali-view-components/gantt'
 *   registerIsland('gantt', GanttController)
 *
 * Registers the controller on the Stimulus application the host exposes as
 * `window.Stimulus` -- never on a second Application (see the module header).
 * Idempotent: loading the entry twice (Turbo navigations re-inject nothing,
 * but belt and braces) registers once.
 */
export const registerIsland = (name, ControllerClass) => {
  const register = (application) => {
    if (!application) return false

    application.baliRegisteredIslands ??= new Set()
    if (!application.baliRegisteredIslands.has(name)) {
      application.baliRegisteredIslands.add(name)
      application.register(name, ControllerClass)
    }

    return true
  }

  const explain = () => {
    console.error(
      `Bali ReactIsland: window.Stimulus is not defined, so the "${name}" ` +
      'island cannot register. Expose your Stimulus application ' +
      '(window.Stimulus = application) or register the controller manually.'
    )
  }

  if (register(window.Stimulus)) return

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      if (!register(window.Stimulus)) explain()
    }, { once: true })
  } else {
    explain()
  }
}

/**
 * Import in the MAIN bundle (it weighs nothing):
 *
 *   import { startIslandLoader } from 'bali-view-components/react-island'
 *   startIslandLoader('gantt')
 *
 * An island bundle is heavy (React plus the component): too much for the main
 * bundle, which travels on every page. But linking it from the page's view
 * does not work either, because Bali drawers and modals inject their content
 * with fetch + innerHTML -- and <script> tags inserted through innerHTML never
 * execute. The island would stay unmounted: an empty div and no error.
 *
 * This watches the DOM and, the first time an element with the island's
 * controller appears, injects the <link> and <script> for the real bundle.
 * The digested asset paths are only known server-side, so the layout
 * publishes them in <meta> tags via the `react_island_meta_tags` helper:
 *
 *   <%= react_island_meta_tags('gantt', js: 'gantt.js', css: 'gantt.css') %>
 *
 * Defaults derive from `name`; pass `selector`, `jsMeta` or `cssMeta` to
 * override (e.g. a loader that watches several controller identifiers).
 */
export const startIslandLoader = (name, { selector, jsMeta, cssMeta } = {}) => {
  const islandSelector = selector ?? `[data-controller~="${name}"]`
  const jsMetaSelector = `meta[name="${jsMeta ?? `bali-${name}-js`}"]`
  const cssMetaSelector = `meta[name="${cssMeta ?? `bali-${name}-css`}"]`

  let requested = false

  const inject = (tag, attrs) => {
    const el = Object.assign(document.createElement(tag), attrs)
    document.head.appendChild(el)
  }

  const load = () => {
    if (requested) return
    requested = true

    const js = document.querySelector(jsMetaSelector)?.content
    const css = document.querySelector(cssMetaSelector)?.content

    if (!js) {
      console.error(
        `Bali ReactIsland: a "${name}" island is on the page but the ` +
        `${jsMetaSelector} tag is missing. Add ` +
        `<%= react_island_meta_tags('${name}', js: ...) %> to the <head> ` +
        'of your layout.'
      )
      return
    }

    if (css) inject('link', { rel: 'stylesheet', href: css })
    inject('script', { type: 'module', src: js })
  }

  const scan = (node) => {
    if (node?.nodeType !== Node.ELEMENT_NODE) return
    if (node.matches?.(islandSelector) || node.querySelector?.(islandSelector)) load()
  }

  const start = () => {
    scan(document.body)
    new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        for (const node of mutation.addedNodes) scan(node)
      }
    }).observe(document.documentElement, { childList: true, subtree: true })
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start, { once: true })
  } else {
    start()
  }
}
