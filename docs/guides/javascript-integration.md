# JavaScript Integration Guide

This guide explains how to integrate Bali's JavaScript controllers into your Rails application.

Bali supports two approaches:
1. **Bundler** (Vite, esbuild, Webpack, etc.) - For apps with Node.js (recommended)
2. **Import Maps** - For apps without Node.js

## Option 1: Bundler Integration (Recommended)

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

## Option 2: Import Maps Integration (No Node.js)

Best for apps using `importmap-rails` without a bundler.

### Step 1: Pin Bali in config/importmap.rb

```ruby
# config/importmap.rb

# Core dependencies (from CDN)
pin "@hotwired/stimulus", to: "https://ga.jspm.io/npm:@hotwired/stimulus@3.2.2/dist/stimulus.js"
pin "@hotwired/turbo-rails", to: "https://ga.jspm.io/npm:@hotwired/turbo-rails@8.0.4/app/javascript/turbo/index.js"
pin "flatpickr", to: "https://ga.jspm.io/npm:flatpickr@4.6.13/dist/esm/index.js"

# Bali utility controllers
pin "bali/controllers/datepicker-controller", to: "bali/controllers/datepicker-controller.js"
pin "bali/controllers/submit-button-controller", to: "bali/controllers/submit-button-controller.js"
pin "bali/controllers/submit-on-change-controller", to: "bali/controllers/submit-on-change-controller.js"
pin "bali/controllers/dynamic-fields-controller", to: "bali/controllers/dynamic-fields-controller.js"
pin "bali/controllers/checkbox-toggle-controller", to: "bali/controllers/checkbox-toggle-controller.js"
pin "bali/controllers/radio-toggle-controller", to: "bali/controllers/radio-toggle-controller.js"
pin "bali/controllers/file-input-controller", to: "bali/controllers/file-input-controller.js"
pin "bali/controllers/focus-on-connect-controller", to: "bali/controllers/focus-on-connect-controller.js"
pin "bali/controllers/print-controller", to: "bali/controllers/print-controller.js"
pin "bali/controllers/slim-select-controller", to: "bali/controllers/slim-select-controller.js"
pin "bali/controllers/step-number-input-controller", to: "bali/controllers/step-number-input-controller.js"

# Bali component controllers
pin "bali/bulk_actions", to: "bali/bulk_actions/index.js"
pin "bali/modal", to: "bali/modal/index.js"
pin "bali/dropdown", to: "bali/dropdown/index.js"
pin "bali/tabs", to: "bali/tabs/index.js"
pin "bali/tooltip", to: "bali/tooltip/index.js"
pin "bali/carousel", to: "bali/carousel/index.js"
pin "bali/clipboard", to: "bali/clipboard/index.js"
pin "bali/reveal", to: "bali/reveal/index.js"
pin "bali/drawer", to: "bali/drawer/index.js"
pin "bali/navbar", to: "bali/navbar/index.js"
pin "bali/side_menu", to: "bali/side_menu/index.js"
pin "bali/sortable_list", to: "bali/sortable_list/index.js"

# Bali utilities (used by components internally)
pin "bali/utils/domHelpers", to: "bali/utils/domHelpers.js"
pin "bali/utils/formatters", to: "bali/utils/formatters.js"
pin "bali/utils/form", to: "bali/utils/form.js"
pin "bali/utils/use-click-outside", to: "bali/utils/use-click-outside.js"
```

### Step 2: Register Controllers

In your `application.js`:

```javascript
import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Import individual controllers as needed
import { DatepickerController } from "bali/controllers/datepicker-controller"
import { BulkActionsController } from "bali/bulk_actions"
import { ModalController } from "bali/modal"
import { DropdownController } from "bali/dropdown"

application.register("datepicker", DatepickerController)
application.register("bulk-actions", BulkActionsController)
application.register("modal", ModalController)
application.register("dropdown", DropdownController)
```

---

## Available Controllers

### Utility Controllers

All 24 standalone controllers — identifier, what each does, and a minimal markup
example — are catalogued in the [Stimulus utility controllers guide](controllers.md).
That page is the single source of truth: `yarn check:manifest` fails if a registered
utility identifier is missing from it.

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

### Emitted by Bali

| Event | Dispatched on | `detail` |
|---|---|---|
| `bali:modal:open` | `document` | `{ content, options }` |
| `bali:modal:success` | `document` | the redirect params merged over `data-extra-props`; also fires for drawers |
| `bali:drawer:open` | `document` | `{ content, options }` |
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
| `bali:modal:open` | `document` | Opens the modal. `detail.content` is the HTML for the body (`null` keeps the skeleton), `detail.options` accepts `wrapperClasses`, `redirectTo`, `skipRender`, `extraProps`, `modalSize` |
| `bali:drawer:open` | `document` | Same, with `drawerSize` instead of `modalSize` |
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

### Import Maps: "Failed to resolve module"

Pin the missing module in `config/importmap.rb`. Check the asset path exists.

---

## Migration from Import Maps to a Bundler

If you're migrating from importmaps to a bundler:

1. **Choose a bundler**: Vite (`vite_rails`), esbuild (`jsbundling-rails`), or Webpack
2. **Install bali-view-components**: `yarn add bali-view-components`
3. **Update application.js**: Use ES module imports from `'bali-view-components'`
4. **Update layout**: Replace `javascript_importmap_tags` with your bundler's tag

The Bali controllers work identically with any bundler or import maps.
