# Stimulus Controller Patterns for Bali

The patterns for Stimulus controllers in this repo, taken from the controllers that
ship. When this document and a controller disagree, the controller wins; fix the
document.

## Where controllers live

Three homes, by kind:

```
app/components/bali/[name]/index.js        # component controllers, co-located with
                                           # the component they animate (modal,
                                           # drawer, dropdown, sortable_list, …)

app/assets/javascripts/bali/controllers/   # standalone utility controllers, one per
  [name]-controller.js                     # file, kebab-case (datepicker-controller.js)

app/frontend/bali/                         # entry points and registration:
  index.js                                 #   registerAll / registerAllComponents /
  controllers/index.js                     #   registerAllControllers, named exports
  components/index.js                      # heavy modules get their own entries:
  charts.js, gantt-entry.js, …             #   charts, gantt, block-editor
```

The catalogue of every standalone utility controller — identifier, purpose, minimal
markup — is `docs/guides/controllers.md`, and `yarn check:manifest` fails if a
registered identifier is missing from it. Host-facing registration recipes (bundler
and importmaps) live in `docs/guides/javascript-integration.md`.

## Named exports, never default

```javascript
import { Controller } from '@hotwired/stimulus'

export class RevealController extends Controller { … }   // ✓ what every file does
export default class extends Controller { … }            // ✗ does not exist here
```

Named exports are what `app/frontend/bali/index.js` re-exports and what hosts import
(`import { ModalController } from 'bali-view-components'`). StandardJS is the lint
(pre-commit hook + CI) — single quotes, no semicolons, space before parens.

## A real controller, in full

`app/components/bali/reveal/index.js` — the shape most controllers take:

```javascript
import { Controller } from '@hotwired/stimulus'

export class RevealController extends Controller {
  static targets = ['item', 'trigger']
  static classes = ['hidden']

  openedClass = 'is-revealed'

  connect () {
    this.class = this.hasHiddenClass ? this.hiddenClass : 'hidden'
  }

  toggle () {
    this.opened ? this.hide() : this.show()
  }

  show () {
    this.element.classList.add(this.openedClass)
    this.itemTargets.forEach(item => item.classList.remove(this.class))
    this.syncTrigger()
  }

  hide () {
    this.element.classList.remove(this.openedClass)
    this.itemTargets.forEach(item => item.classList.add(this.class))
    this.syncTrigger()
  }

  get opened () {
    return this.element.classList.contains(this.openedClass)
  }

  syncTrigger () {
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute('aria-expanded', this.opened)
    }
  }
}
```

Note the last method: **every visual state change syncs its ARIA mirror**
(`aria-expanded`, `aria-pressed`, `aria-current`) in the same place that toggles the
class. State that only lives in CSS classes is invisible to a screen reader.

## Values

Declared with types and defaults; the Ruby side writes them through
`prepend_values(options, "identifier", { … })`:

```javascript
static values = {
  animation: { type: Number, default: 150 },
  handle: String,
  disabled: { type: Boolean, default: false }
}
```

Value names are camelCase; the DOM attribute is the dasherized form
(`data-sortable-list-position-param-name-value`). Digits do not dasherize:
`time24hr` stays `data-datepicker-time24hr-value`.

## Optional heavy dependencies load dynamically

A controller that needs an optional peer imports it inside `connect`, so the peer is
only in the bundle (and only fetched) when the component is actually on the page —
`app/components/bali/sortable_list/index.js`:

```javascript
async connect () {
  const { default: Sortable } = await import('sortablejs')

  this.sortable = new Sortable(this.element, { … })
}
```

Anything that can run before that import resolves (a keyboard path, an early event)
guards with `this.sortable?.…`. Which peer belongs to which component is mapped in
`docs/guides/installation.md`.

## Events

Every public event is `bali:<component>:<event>`, kebab-case, payload on
`event.detail`. The prefix is a hardcoded constant, NOT the default
`this.identifier`, so the public name survives a host registering the controller
under another identifier:

```javascript
// Hardcoded instead of letting `dispatch` default to `this.identifier`, so the
// public event name stays put when a host registers this controller under a
// different identifier.
const EVENT_PREFIX = 'bali:sortable-list'

this.dispatch('end', { prefix: EVENT_PREFIX, detail: { order, item, from, to } })
```

One documented exception: `bali:hovercard:*` (no hyphen) — v3.0 surface the v2→v3
guide taught hosts to listen for; renaming it would break exactly the hosts that
followed the guide (#1026).

Opening a shared overlay by event **always names it**: `detail.id` plus
`detail.options` (pass `{}` when empty — the controller reads it before opening):

```javascript
document.dispatchEvent(new CustomEvent('bali:drawer:open', {
  detail: { id: 'settings-drawer', options: {} }
}))
```

Without `detail.id` the event is a broadcast and every shared modal/drawer on the
page answers (#854). The full event tables live in
`docs/guides/javascript-integration.md`.

## Module-scope state survives what a controller instance cannot

A Turbo render replaces the body and destroys the controller instance mid-flight, so
state that must survive a restore lives at module scope, keyed if needed — see the
worked example at the top of `app/components/bali/split_view/index.js`
(`restoringHistory`, `pristineDetail`). And on a `popstate`, **Turbo caches the
leaving page synchronously before your controller's own popstate listener runs** —
any `turbo:before-cache` hook has already fired by the time you compare DOM state
(#1029).

## React islands

React-backed components (Gantt, BlockEditor) do not hand-roll mounting: their
controller extends `ReactIslandController` (`app/frontend/bali/react-island.js`),
which owns `createRoot`, values→props, the error boundary, Turbo cache exclusion and
unmount. The subclass declares values and a `loadComponent()` that dynamically
imports React and the component — `app/components/bali/gantt/index.js` is the model,
`docs/api/react-island.md` the contract.

## Cleanup

Listeners added outside the element are removed in `disconnect`, using the same
bound reference:

```javascript
connect () {
  this.syncFromLocation = this.syncFromLocation.bind(this)
  window.addEventListener('popstate', this.syncFromLocation)
}

disconnect () {
  window.removeEventListener('popstate', this.syncFromLocation)
}
```

## Testing

Stimulus behaviour is tested with **Cypress against the Lookbook preview URLs** —
Minitest renders the markup but never runs the JS. The dummy server must be running
(`cd spec/dummy && bin/dev`, port 3001); the runner's `baseUrl` is
`http://localhost:3001/lookbook/preview`.

```javascript
// cypress/e2e/sortable-list.cy.js (excerpt — a real spec)
describe('SortableList', () => {
  const items = () => cy.get('.sortable-list-component > .sortable-item')

  beforeEach(() => {
    cy.visit('/bali/sortable_list/default')
    cy.intercept('PATCH', '/sortable_list*', { statusCode: 200, body: '' }).as('reorder')
    items().should('have.length', 5)
  })

  it('moves the focused item down with ArrowDown and persists like a drop', () => {
    items().first().focus().type('{downArrow}')

    items().eq(0).should('contain.text', 'Item 2')
    cy.wait('@reorder')
  })
})
```

Hard-earned rules for these specs:

- Assert **visibility/state**, not `textContent` — hidden notices are always in the
  DOM.
- After `yarn build`, **restart the dummy server**: digested assets are served with
  immutable caching and the browser keeps executing the old bundle.
- Native HTML5 drag (SortableJS on desktop) cannot be started synthetically from
  Cypress — neither mousemove sequences nor dragstart/dragover/drop with a real
  `DataTransfer`. Cover the drop contract through keyboard/state paths instead.
- "No request happened" needs a bounded `cy.wait(…)` before asserting
  `cy.get('@alias.all').should('have.length', 0)`.

## Debug mode

Because every Bali event shares the `bali:` prefix, one console snippet traces all of
them — no per-controller instrumentation and no flag to remember to turn off:

```javascript
// In browser console
const dispatchEvent = EventTarget.prototype.dispatchEvent
EventTarget.prototype.dispatchEvent = function (event) {
  if (event.type.startsWith('bali:')) console.log(event.type, event.detail)
  return dispatchEvent.call(this, event)
}
```

Do not override `dispatch` in a controller to add logging: that is what the removed
`useDispatch` mixin did, and its incompatible `(name, detail)` signature silently
broke every call that passed native options such as `target:` or `prefix:`.

## Anti-patterns

| Don't | Do |
|---|---|
| `export default class extends Controller` | `export class XController extends Controller` |
| `this.dispatch('x')` relying on `this.identifier` | hardcoded `EVENT_PREFIX = 'bali:<component>'` |
| Broadcast `bali:modal/drawer:open` without `detail.id` | always name the overlay (#854) |
| Top-level `import Sortable from 'sortablejs'` | dynamic `await import(…)` inside `connect` |
| Class toggles without their ARIA mirror | sync `aria-*` where the class toggles |
| Listeners without `disconnect` cleanup | bound reference added in `connect`, removed in `disconnect` |
| Kitchen-sink controllers | one controller, one behaviour (see any `index.js` here) |
| Instance state that must survive a Turbo render | module-scope state (`split_view/index.js`) |
