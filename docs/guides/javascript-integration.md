# JavaScript Integration Guide

This guide explains how to integrate Bali's JavaScript controllers into your Rails application.

Bali supports two approaches:
1. **Bundler** (Vite, esbuild, Webpack, etc.) - For apps with Node.js (recommended)
2. **Import Maps** - For apps without Node.js

## Option 1: Bundler Integration (Recommended)

Best for apps using any JavaScript bundler: **Vite**, **esbuild**, **Webpack**, **Rollup**, etc.

### Step 1: Install Dependencies

```bash
yarn add bali-view-components @hotwired/stimulus @hotwired/turbo flatpickr \
         tippy.js sortablejs chart.js @glidejs/glide @popperjs/core date-fns \
         rrule lodash.throttle @rails/request.js slim-select interactjs
```

### Step 2: Register Controllers

In your `application.js`:

```javascript
import { Application } from '@hotwired/stimulus'
import { registerAll } from 'bali-view-components'

const application = Application.start()

// Register all core controllers at once (simplest)
registerAll(application)

// Or register only what you need (smaller bundle, better tree-shaking)
import { DatepickerController, TableController } from 'bali-view-components'
application.register('datepicker', DatepickerController)
application.register('table', TableController)
```

### Step 3: Add Optional Modules (if needed)

```javascript
// Charts (requires chart.js - adds ~208KB)
import { registerCharts } from 'bali-view-components/charts'
registerCharts(application)

// Gantt Chart (requires sortablejs, lodash.throttle)
import { registerGantt } from 'bali-view-components/gantt'
registerGantt(application)
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
      { find: 'bali/gantt', replacement: resolve(baliGemPath, 'app/frontend/bali/gantt.js') },
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
pin "bali/table", to: "bali/table/index.js"
pin "bali/modal", to: "bali/modal/index.js"
pin "bali/dropdown", to: "bali/dropdown/index.js"
pin "bali/tabs", to: "bali/tabs/index.js"
pin "bali/tooltip", to: "bali/tooltip/index.js"
pin "bali/carousel", to: "bali/carousel/index.js"
pin "bali/clipboard", to: "bali/clipboard/index.js"
pin "bali/notification", to: "bali/notification/index.js"
pin "bali/reveal", to: "bali/reveal/index.js"
pin "bali/drawer", to: "bali/drawer/index.js"
pin "bali/navbar", to: "bali/navbar/index.js"
pin "bali/side_menu", to: "bali/side_menu/index.js"
pin "bali/sortable_list", to: "bali/sortable_list/index.js"

# Bali utilities (used by components internally)
pin "bali/utils/domHelpers", to: "bali/utils/domHelpers.js"
pin "bali/utils/formatters", to: "bali/utils/formatters.js"
pin "bali/utils/form", to: "bali/utils/form.js"
pin "bali/utils/use-dispatch", to: "bali/utils/use-dispatch.js"
pin "bali/utils/use-click-outside", to: "bali/utils/use-click-outside.js"
```

### Step 2: Register Controllers

In your `application.js`:

```javascript
import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Import individual controllers as needed
import { DatepickerController } from "bali/controllers/datepicker-controller"
import { TableController } from "bali/table"
import { ModalController } from "bali/modal"
import { DropdownController } from "bali/dropdown"

application.register("datepicker", DatepickerController)
application.register("table", TableController)
application.register("modal", ModalController)
application.register("dropdown", DropdownController)
```

---

## Available Controllers

### Utility Controllers

| Controller | Description |
|------------|-------------|
| `DatepickerController` | Flatpickr date picker |
| `SubmitButtonController` | Loading state on submit |
| `SubmitOnChangeController` | Auto-submit on change |
| `DynamicFieldsController` | Add/remove form fields |
| `CheckboxToggleController` | Toggle visibility with checkbox |
| `RadioToggleController` | Toggle visibility with radio |
| `FileInputController` | File input display |
| `FocusOnConnectController` | Auto-focus on connect |
| `PrintController` | Print current page |
| `SlimSelectController` | Slim Select dropdown |
| `StepNumberInputController` | Number increment/decrement |
| `InteractController` | Drag/resize with interact.js |

### Component Controllers

| Controller | Description |
|------------|-------------|
| `TableController` | Data table with sorting |
| `ModalController` | Modal dialogs |
| `DrawerController` | Side panel drawer |
| `DropdownController` | Dropdown menus |
| `TabsController` | Tab navigation |
| `TooltipController` | Tooltips (tippy.js) |
| `HovercardController` | Hover popups |
| `CarouselController` | Image carousel (Glide.js) |
| `ClipboardController` | Copy to clipboard |
| `NotificationController` | Toast notifications |
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
| Gantt | `bali-view-components/gantt` | sortablejs, lodash.throttle | ~50KB |
| Rich Text Editor | `bali-view-components/rich-text-editor` | TipTap | N/A |

---

## Bundle Size Optimization

### Tree Shaking

Modern bundlers (Vite, Webpack, esbuild) automatically remove unused code. Import only what you need:

```javascript
// Good: Import specific controllers
import { DatepickerController, TableController } from 'bali-view-components'

// Avoid: Register all if you only need a few
import { registerAll } from 'bali-view-components'
registerAll(application)  // Includes all 40+ controllers
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
