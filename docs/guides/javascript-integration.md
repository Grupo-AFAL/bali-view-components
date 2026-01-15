# JavaScript Integration Guide

This guide explains how to integrate Bali's JavaScript controllers into your Rails application.

Bali supports two approaches:
1. **Bundler** (Vite, Webpack, esbuild, etc.) - For apps with Node.js (recommended)
2. **Import Maps** - For apps without Node.js

## Option 1: Bundler Integration (Recommended)

Best for apps using any JavaScript bundler: **Vite**, **Webpack**, **esbuild**, **Rollup**, etc.

The key requirement is configuring your bundler to resolve the `bali` import path to the gem's directory. The examples below use Vite, but the same concept applies to any bundler.

### Step 1: Configure Your Bundler

#### Vite Example

Add Bali's path to your `vite.config.mts`:

```typescript
import { defineConfig } from 'vite'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'
import { execSync } from 'child_process'

const __dirname = dirname(fileURLToPath(import.meta.url))

// Get Bali gem path dynamically
const baliGemPath = execSync('bundle show bali_view_components').toString().trim()

export default defineConfig({
  resolve: {
    alias: [
      // Core Bali entry point
      { find: 'bali', replacement: resolve(baliGemPath, 'app/frontend/bali') },

      // Optional modules (import separately for smaller bundles)
      { find: 'bali/charts', replacement: resolve(baliGemPath, 'app/frontend/bali/charts.js') },
      { find: 'bali/gantt', replacement: resolve(baliGemPath, 'app/frontend/bali/gantt.js') },

      // Internal paths (needed for Bali's internal imports)
      { find: 'bali/utils', replacement: resolve(baliGemPath, 'app/assets/javascripts/bali/utils') },
      { find: 'bali/modal', replacement: resolve(baliGemPath, 'app/components/bali/modal/index.js') },
      { find: 'bali/gantt-chart/connection-line', replacement: resolve(baliGemPath, 'app/components/bali/gantt_chart/connection_line.js') },
      { find: 'bali/gantt-chart', replacement: resolve(baliGemPath, 'app/components/bali/gantt_chart') },

      // NPM dependencies (needed for imports from gem path)
      { find: 'tippy.js', replacement: resolve(__dirname, 'node_modules/tippy.js') },
      { find: 'sortablejs', replacement: resolve(__dirname, 'node_modules/sortablejs') },
      { find: 'chart.js', replacement: resolve(__dirname, 'node_modules/chart.js') },
      { find: '@glidejs/glide', replacement: resolve(__dirname, 'node_modules/@glidejs/glide') },
      { find: '@popperjs/core', replacement: resolve(__dirname, 'node_modules/@popperjs/core') },
      { find: 'date-fns', replacement: resolve(__dirname, 'node_modules/date-fns') },
      { find: 'rrule', replacement: resolve(__dirname, 'node_modules/rrule') },
      { find: 'lodash.throttle', replacement: resolve(__dirname, 'node_modules/lodash.throttle') },
      { find: '@rails/request.js', replacement: resolve(__dirname, 'node_modules/@rails/request.js') },
      { find: 'slim-select', replacement: resolve(__dirname, 'node_modules/slim-select') },
      { find: 'interactjs', replacement: resolve(__dirname, 'node_modules/interactjs') },
    ]
  },
  server: {
    fs: {
      allow: ['.', baliGemPath]
    }
  }
})
```

#### Webpack Example

For Webpack users (e.g., `jsbundling-rails` with Webpack):

```javascript
// webpack.config.js
const { execSync } = require('child_process')
const path = require('path')

const baliGemPath = execSync('bundle show bali_view_components').toString().trim()

module.exports = {
  resolve: {
    alias: {
      'bali': path.resolve(baliGemPath, 'app/frontend/bali'),
      'bali/charts': path.resolve(baliGemPath, 'app/frontend/bali/charts.js'),
      'bali/gantt': path.resolve(baliGemPath, 'app/frontend/bali/gantt.js'),
      'bali/utils': path.resolve(baliGemPath, 'app/assets/javascripts/bali/utils'),
      // Add other aliases as needed...
    }
  }
}
```

#### esbuild Example

For esbuild users:

```javascript
// esbuild.config.mjs
import { execSync } from 'child_process'
import path from 'path'

const baliGemPath = execSync('bundle show bali_view_components').toString().trim()

await esbuild.build({
  // ... other config
  alias: {
    'bali': path.resolve(baliGemPath, 'app/frontend/bali'),
    'bali/charts': path.resolve(baliGemPath, 'app/frontend/bali/charts.js'),
    'bali/gantt': path.resolve(baliGemPath, 'app/frontend/bali/gantt.js'),
  }
})
```

### Step 2: Install Dependencies

```bash
yarn add @hotwired/stimulus @hotwired/turbo flatpickr tippy.js sortablejs \
         chart.js @glidejs/glide @popperjs/core date-fns rrule \
         lodash.throttle @rails/request.js slim-select interactjs
```

### Step 3: Register Controllers

In your `application.js`:

```javascript
import { Application } from '@hotwired/stimulus'

const application = Application.start()

// Option A: Register all controllers at once (simplest)
import { registerAllControllers, registerAllComponents } from 'bali'
registerAllControllers(application)
registerAllComponents(application)

// Option B: Import individual controllers (smallest bundle)
import { DatepickerController, TableController } from 'bali'
application.register('datepicker', DatepickerController)
application.register('table', TableController)
```

### Step 4: Add Optional Modules (if needed)

```javascript
// Charts (requires chart.js - adds ~208KB)
import { registerCharts } from 'bali/charts'
registerCharts(application)

// Gantt Chart (requires sortablejs, lodash.throttle)
import { registerGantt } from 'bali/gantt'
registerGantt(application)
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

### Utility Controllers (from `bali/controllers/`)

| Controller | Import Path | Description |
|------------|-------------|-------------|
| `DatepickerController` | `bali/controllers/datepicker-controller` | Flatpickr date picker |
| `SubmitButtonController` | `bali/controllers/submit-button-controller` | Loading state on submit |
| `SubmitOnChangeController` | `bali/controllers/submit-on-change-controller` | Auto-submit on change |
| `DynamicFieldsController` | `bali/controllers/dynamic-fields-controller` | Add/remove form fields |
| `CheckboxToggleController` | `bali/controllers/checkbox-toggle-controller` | Toggle visibility with checkbox |
| `RadioToggleController` | `bali/controllers/radio-toggle-controller` | Toggle visibility with radio |
| `FileInputController` | `bali/controllers/file-input-controller` | File input display |
| `FocusOnConnectController` | `bali/controllers/focus-on-connect-controller` | Auto-focus on connect |
| `PrintController` | `bali/controllers/print-controller` | Print current page |
| `SlimSelectController` | `bali/controllers/slim-select-controller` | Slim Select dropdown |
| `StepNumberInputController` | `bali/controllers/step-number-input-controller` | Number increment/decrement |
| `InteractController` | `bali/controllers/interact-controller` | Drag/resize with interact.js |

### Component Controllers (from `bali/components/`)

| Controller | Import Path | Description |
|------------|-------------|-------------|
| `TableController` | `bali/table` | Data table with sorting |
| `ModalController` | `bali/modal` | Modal dialogs |
| `DrawerController` | `bali/drawer` | Side panel drawer |
| `DropdownController` | `bali/dropdown` | Dropdown menus |
| `TabsController` | `bali/tabs` | Tab navigation |
| `TooltipController` | `bali/tooltip` | Tooltips (tippy.js) |
| `HovercardController` | `bali/hover_card` | Hover popups |
| `CarouselController` | `bali/carousel` | Image carousel (Glide.js) |
| `ClipboardController` | `bali/clipboard` | Copy to clipboard |
| `NotificationController` | `bali/notification` | Toast notifications |
| `RevealController` | `bali/reveal` | Show/hide content |
| `SortableListController` | `bali/sortable_list` | Drag-drop sorting |
| `NavbarController` | `bali/navbar` | Navigation bar |
| `SideMenuController` | `bali/side_menu` | Sidebar menu |
| `TimeagoController` | `bali/timeago` | Relative time display |
| `RateController` | `bali/rate` | Star rating |
| `AvatarController` | `bali/avatar` | User avatars |
| `BulkActionsController` | `bali/bulk_actions` | Bulk selection actions |
| `ImageFieldController` | `bali/image_field` | Image upload field |
| `LocationsMapController` | `bali/locations_map` | Google Maps display |

### Optional Modules (Heavy Dependencies)

| Module | Import Path | Dependencies | Size |
|--------|-------------|--------------|------|
| Charts | `bali/charts` | chart.js | ~208KB |
| Gantt | `bali/gantt` | sortablejs, lodash.throttle | ~50KB |
| Rich Text Editor | `bali/rich-text-editor` | TipTap (broken) | N/A |

---

## Bundle Size Optimization

### Tree Shaking

Modern bundlers (Vite, Webpack, esbuild) automatically remove unused code. Import only what you need:

```javascript
// Good: Import specific controllers
import { DatepickerController, TableController } from 'bali'

// Avoid: Register all if you only need a few
import { registerAllControllers } from 'bali'
registerAllControllers(application)  // Includes all 40+ controllers
```

### Code Splitting

Some bundlers (like Vite) automatically split large dependencies into separate chunks that load on demand. This happens automatically - no configuration needed.

---

## Troubleshooting

### "Cannot find module 'bali'"

Ensure your bundler config has the correct alias pointing to the gem path. Verify with:
```bash
bundle show bali_view_components
```

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

1. **Choose a bundler**: Vite (`vite_rails`), Webpack (`jsbundling-rails`), or esbuild
2. **Configure aliases**: Point `bali` to the gem's `app/frontend/bali` directory
3. **Install npm dependencies**: See Step 2 above
4. **Update layout**: Replace `javascript_importmap_tags` with your bundler's tag
5. **Update application.js**: Use ES module imports

The Bali controllers work identically with any bundler or import maps.
