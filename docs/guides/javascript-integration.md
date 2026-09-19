# JavaScript Integration Guide

This guide explains how to integrate Bali's JavaScript controllers into your Rails application.

**Bali needs a bundler.** What ships is ESM source — 91 modules behind the root entry, counted
with an esbuild metafile — importing their peers by bare specifier. Import maps cannot resolve
that; see [Import maps](#import-maps-not-supported) below for the measurement, and
[Installation § Step 0](installation.md) for `bin/rails g bali:install`, which writes the
bundler wiring and refuses to touch an importmap app's Stimulus index.

## Bundler Integration (Vite, esbuild, Webpack)

Best for apps using any JavaScript bundler: **Vite**, **esbuild**, **Webpack**, **Rollup**, etc.

### Step 1: Install Dependencies

Three peers are required. Bali does not work without them, and two of the three fail
silently rather than at build time:

```bash
yarn add bali-view-components @hotwired/stimulus @hotwired/turbo-rails daisyui
```

Everything else is an optional peer that the controller needing it loads with a dynamic
`import()`. Add only what you actually render:

```bash
yarn add flatpickr slim-select sortablejs @glidejs/glide date-fns rrule \
         @rails/request.js @rails/activestorage @googlemaps/markerclusterer \
         lodash.throttle lodash.debounce
```

*Step 6* of the [installation guide](installation.md) maps each optional peer to the
component that loads it. Charts, the block editor and the rich text editor sit behind
their own entry points and carry their own dependency sets.

### Step 2: Register Controllers

In your `application.js`:

```javascript
import { Application } from '@hotwired/stimulus'
import { registerAll } from 'bali-view-components'

const application = Application.start()

// Register all core controllers at once (simplest)
registerAll(application)

// Or register only what you need (smaller bundle, better tree-shaking)
import { DatepickerController, BulkActionsController } from 'bali-view-components'
application.register('datepicker', DatepickerController)
application.register('bulk-actions', BulkActionsController)
```

### Step 3: Add Optional Modules (if needed)

```javascript
// Charts (requires chart.js - adds ~208KB)
import { registerCharts } from 'bali-view-components/charts'
registerCharts(application)

```

### Bundler Configuration (Only If Needed)

**For esbuild users**: No configuration needed. Just import and go.

**For Vite users** loading from the gem path (not npm): Add `fs.allow`:

```typescript
// vite.config.mts
import { execSync } from 'child_process'

const baliGemPath = execSync('bundle show bali_view_components').toString().trim()

export default defineConfig({
  resolve: {
    alias: [
      // Main entry points
      { find: 'bali', replacement: resolve(baliGemPath, 'app/frontend/bali') },
      { find: 'bali/charts', replacement: resolve(baliGemPath, 'app/frontend/bali/charts.js') },
      // NPM dependencies (needed when loading from gem path)
      { find: 'tippy.js', replacement: resolve(__dirname, 'node_modules/tippy.js') },
      { find: 'sortablejs', replacement: resolve(__dirname, 'node_modules/sortablejs') },
      // ... other npm packages as needed
    ]
  },
  server: {
    fs: { allow: ['.', baliGemPath] }
  }
})
```

---

## Import maps: not supported

This section used to be "Option 2", with 31 `pin` lines. The recipe never worked, and the
pins are the measurement: of the 28 Bali modules it told you to pin, the files themselves
import **eight bare specifiers the same section does not pin** — `@rails/request.js`,
`lodash.debounce`, `lodash.throttle`, `tippy.js`, `sortablejs`, `slim-select`,
`@glidejs/glide` and `flatpickr/dist/l10n/es.js` — and **17 relative imports**, which leave
the pin map entirely because a relative specifier resolves against the URL the asset was
served from. Five of the modules they reach (`utils/optional-peer.js`, `utils/top-layer.js`,
`utils/z-index.js`, `utils/time.js`, `confirm/confirm_dialog.js`) are not in the list at all.

A single unresolved specifier is not a missing feature, it is the whole module failing to
instantiate: the browser reports `Failed to resolve module specifier "…"` once and every
controller registered from that file — yours included — never connects.

Add a bundler:

```bash
bundle add jsbundling-rails
bin/rails javascript:install:esbuild
bin/rails g bali:install
```

Vite resolves the same imports with no extra step; see the `fs.allow` note above.

---

## Available Controllers

### Utility Controllers

All 25 standalone controllers — identifier, what each does, and a minimal markup
example — are catalogued in the [Stimulus utility controllers guide](controllers.md).
That page is the single source of truth: `yarn check:manifest` fails if a registered
utility identifier is missing from it.

Registering a subset is supported, but note which controllers the FormBuilder mounts
on your behalf: leave one out and the field renders and submits exactly as before,
with the behaviour silently missing. `number-format` is mounted by any numeric
family given `delimited: true`, so an app that uses that option needs it registered
or those fields quietly stop grouping.

### Component Controllers

| Controller | Description |
|------------|-------------|
| `ModalController` | Modal dialogs |
| `DrawerController` | Side panel drawer |
| `DropdownController` | Dropdown menus |
| `TabsController` | Tab navigation |
| `TooltipController` | Tooltips (tippy.js) |
| `HovercardController` | Hover popups |
| `CarouselController` | Image carousel (Glide.js) |
| `ClipboardController` | Copy to clipboard |
| `RevealController` | Show/hide content |
| `SortableListController` | Drag-drop sorting |
| `NavbarController` | Navigation bar |
| `SideMenuController` | Sidebar menu |
| `TimeagoController` | Relative time display |
| `RateController` | Star rating |
| `AvatarController` | User avatars |
| `BulkActionsController` | Bulk selection actions |
| `TableGroupsController` | Collapsible group bands in `Bali::Table` |
| `ImageFieldController` | Image upload field |
| `LocationsMapController` | Google Maps display |

### Optional Modules (Heavy Dependencies)

| Module | Import Path | Dependencies | Size |
|--------|-------------|--------------|------|
| Charts | `bali-view-components/charts` | chart.js | ~208KB |
| Rich Text Editor | `bali-view-components/rich-text-editor` | TipTap | N/A |

---

## Events

Every event the package emits or listens for is named `bali:<component>:<event>`, kebab-case,
and carries its payload on `event.detail`. Nothing else is public: an event without the `bali:`
prefix does not come from this package.

One deliberate exception: the hover card's events are `bali:hovercard:*` (no hyphen). The
spelling shipped in v3.0 and the v2→v3 migration guide taught hosts to listen for it, so
renaming it to match the rule would break exactly the hosts that followed the guide — for
nothing a user can see (#1026).

### Emitted by Bali

| Event | Dispatched on | `detail` |
|---|---|---|
| `bali:modal:open` | `document` | `{ id, content, options }` |
| `bali:modal:success` | `document` | the redirect params merged over `data-extra-props`; also fires for drawers |
| `bali:drawer:open` | `document` | `{ id, content, options }` |
| `bali:side-menu:toggle` | `window` | — (emitted by `Navbar#toggleSideMenu`) |
| `bali:command:select` | the palette element (bubbles) | `{ row, value }` |
| `bali:direct-upload:complete` | the controller element (bubbles) | `{ id, filename, signedId }` |
| `bali:direct-upload:all-complete` | the controller element (bubbles) | `{ count }` |
| `bali:direct-upload:error` | the controller element (bubbles) | `{ message }` |
| `bali:hovercard:show` / `bali:hovercard:hide` | the controller element (bubbles) | `{ tippy }` |
| `bali:sortable-list:end` | the list element (bubbles) | `{ order, toListId, item, from, to, oldIndex, newIndex }` |
| `bali:interact:dragging` / `bali:interact:drag-end` | the dragged element (bubbles) | `{ element, params, position, startDelta, endDelta, width }` |
| `bali:interact:resizing` / `bali:interact:resize-end` | the resized element (bubbles) | same, plus the live `width`/`position` while resizing |

### Listened for by Bali

Dispatch these yourself to drive a component without a trigger element.

| Event | Dispatch on | Effect |
|---|---|---|
| `bali:modal:open` | `document` | Opens the modal. **`detail.id` names WHICH one** — without it the event is a broadcast and every shared modal on the page answers (#854). `detail.content` is the HTML for the body (`null` keeps the skeleton), `detail.options` accepts `wrapperClasses`, `redirectTo`, `skipRender`, `extraProps`, `modalSize` |
| `bali:drawer:open` | `document` | Same, with `drawerSize` instead of `modalSize` — and the same rule: always send `detail.id` |
| `bali:command:open` / `:close` / `:toggle` | `window` | Drives the command palette |
| `bali:side-menu:open` / `:close` / `:toggle` | `window` | Drives the mobile side menu |

```javascript
// Open a modal from anywhere
document.dispatchEvent(new CustomEvent('bali:modal:open', {
  detail: { content: '<h3>Hello</h3>', options: { modalSize: 'lg' } }
}))
```

To trace all of them at once, see the debug snippet in
[Troubleshooting](troubleshooting.md).

---

## Bundle Size Optimization

### Tree Shaking

Modern bundlers (Vite, Webpack, esbuild) automatically remove unused code. Import only what you need:

```javascript
// Good: Import specific controllers
import { DatepickerController, BulkActionsController } from 'bali-view-components'

// Avoid: Register all if you only need a few
import { registerAll } from 'bali-view-components'
registerAll(application)  // Includes all 50+ controllers (and installs the confirm dialog)
```

### Code Splitting

Some bundlers (like Vite) automatically split large dependencies into separate chunks that load on demand. This happens automatically - no configuration needed.

---

## Troubleshooting

### "Cannot find module 'bali-view-components'"

Ensure you've installed the package: `yarn add bali-view-components`

### "Module not found: tippy.js"

Install the npm dependency: `yarn add tippy.js`

### Controllers not connecting

1. Check browser console for errors
2. Verify the controller is registered with correct name
3. Ensure `data-controller` attribute matches registration name

### "Failed to resolve module specifier"

The app is loading Bali through import maps, which cannot work — see
[Import maps](#import-maps-not-supported).

---

## Migration from Import Maps to a Bundler

1. **Choose a bundler**: Vite (`vite_rails`), esbuild (`jsbundling-rails`), or Webpack
2. **Install bali-view-components**: `yarn add bali-view-components`
3. **Update application.js**: Use ES module imports from `'bali-view-components'`
4. **Update layout**: Replace `javascript_importmap_tags` with your bundler's tag
5. **Run `bin/rails g bali:install`**, which writes steps 2 and 3 for you

Keeping `config/importmap.rb` for a handful of your own pins is fine; the generator reads it
as "no bundler here" and leaves the Stimulus index alone, so delete it once esbuild owns the
index.
