import { ReactIslandController } from 'bali/react-island'

// Reference subclass for the react-island base controller. This is the whole
// per-island surface: declare values, implement loadComponent(). Everything
// else (createRoot, ErrorBoundary, values->props, Turbo cache exclusion,
// unmount on disconnect) comes from the base class.
export default class ReactIslandDemoController extends ReactIslandController {
  static values = {
    label: { type: String, default: 'Counter' },
    start: { type: Number, default: 0 },
    explodeLabel: { type: String, default: 'Explode' },
    failLoad: { type: Boolean, default: false }
  }

  async loadComponent () {
    // `failLoad` simulates a bundle that cannot load (network error, missing
    // optional peer...) so the previews can show the load-error fallback.
    if (this.failLoadValue) {
      throw new Error('ReactIslandDemo: load failure requested by the preview')
    }

    const [react, reactDom, { default: CounterIsland }] = await Promise.all([
      import('react'),
      import('react-dom/client'),
      import('../islands/CounterIsland.jsx')
    ])

    return { react, reactDom, Component: CounterIsland }
  }

  // Default componentProps() forwards every Stimulus value; `failLoad` is
  // controller configuration, not a component prop, so drop it here. This is
  // the override pattern documented in docs/api/react-island.md.
  componentProps () {
    const { failLoad, ...props } = super.componentProps()
    return props
  }
}
