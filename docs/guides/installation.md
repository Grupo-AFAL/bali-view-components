# Installation Guide

This guide covers complete setup of Bali ViewComponents in your Rails application.

## Prerequisites

- Rails 7.0+ (Rails 8.x supported)
- Ruby 3.0+
- Node.js 18+ and npm/yarn
- Tailwind CSS v4 (via tailwindcss-rails or Vite)

---

## Step 1: Install the Gem

Add to your `Gemfile`:

```ruby
gem "bali_view_components"
```

Run bundler:

```bash
bundle install
```

---

## Step 2: Install JavaScript Package

Install the npm package which contains Stimulus controllers and CSS:

```bash
npm install bali-view-components
# or
yarn add bali-view-components
```

This package includes:
- Pre-built CSS for components with custom styling
- Peer dependency on DaisyUI 5.x

---

## Step 3: Configure Tailwind CSS v4 + DaisyUI

Bali uses **Tailwind CSS v4** with **DaisyUI 5** for styling.

### Create/Update Your CSS Entry Point

Create `app/assets/tailwind/application.css` (or similar):

```css
@import "tailwindcss";
@plugin "daisyui" {
  themes: light --default, dark;
}

/* =============================================
   Source Paths - Tailwind class scanning
   =============================================
   Add Bali components to Tailwind's content scanning
   so all component classes are included in the build.
*/

/* Your app sources */
@source "../../../views/**/*.erb";
@source "../../../helpers/**/*.rb";
@source "../../../javascript/**/*.js";

/* Bali ViewComponents sources (via node_modules) */
@source "../../../node_modules/bali-view-components/app/components/**/*.{erb,rb}";
@source "../../../node_modules/bali-view-components/lib/bali/**/*.rb";

/* =============================================
   Bali CSS Imports
   =============================================
   Import base styles and component-specific CSS.
*/
@import "bali-view-components/css/bali.css";
@import "bali-view-components/css/components.css";
```

### DaisyUI Themes

The plugin configuration above enables `light` (default) and `dark` themes. You can customize:

```css
/* Multiple themes */
@plugin "daisyui" {
  themes: light --default, dark, corporate, retro;
}

/* Theme switching in HTML */
<!-- Set theme on html element -->
<html data-theme="dark">
```

See [DaisyUI Themes](https://daisyui.com/docs/themes/) for all available themes.

---

## Step 4: JavaScript Setup

### Option A: Import Maps (Rails Default)

If using importmap-rails, pin the Stimulus controllers:

```ruby
# config/importmap.rb
pin "bali-view-components", to: "bali-view-components.js"
```

Then register controllers in your Stimulus application:

```javascript
// app/javascript/controllers/application.js
import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Register Bali controllers
import { registerControllers } from "bali-view-components"
registerControllers(application)

export { application }
```

### Option B: Vite / esbuild

If using Vite or esbuild:

```javascript
// app/javascript/controllers/index.js
import { Application } from "@hotwired/stimulus"
import { registerControllers } from "bali-view-components"

const application = Application.start()

// Register your local controllers
import HelloController from "./hello_controller"
application.register("hello", HelloController)

// Register all Bali controllers
registerControllers(application)

export { application }
```

### Manual Controller Registration

If you prefer to import controllers individually:

```javascript
import { Application } from "@hotwired/stimulus"

// Import specific Bali controllers
import ModalController from "bali-view-components/controllers/modal_controller"
import DropdownController from "bali-view-components/controllers/dropdown_controller"
import SlimSelectController from "bali-view-components/controllers/slim-select-controller"

const application = Application.start()
application.register("modal", ModalController)
application.register("dropdown", DropdownController)
application.register("slim-select", SlimSelectController)
```

---

## Step 5: Configure FormBuilder (Optional)

To use Bali's enhanced form helpers, configure it as the default form builder:

```ruby
# config/initializers/bali.rb

# Set as default form builder globally
ActionView::Base.default_form_builder = Bali::FormBuilder

# Or configure per-form
# <%= form_with model: @user, builder: Bali::FormBuilder do |f| %>
```

---

## Step 6: External Dependencies

Some components require additional JavaScript libraries:

| Component | Dependency | Installation |
|-----------|------------|--------------|
| Calendar, DatePicker | Flatpickr | `npm install flatpickr` |
| SlimSelect | Slim Select | `npm install slim-select` |
| Chart | Chart.js | `npm install chart.js` |
| SortableList | SortableJS | `npm install sortablejs` |
| RichTextEditor | Trix | Included with Rails |
| AutocompleteAddress | Google Maps API | Add script to layout |

### Flatpickr Setup

```javascript
// Import CSS in your JS entry point
import "flatpickr/dist/flatpickr.min.css"
```

### Google Maps (for AutocompleteAddress)

Add to your layout:

```erb
<%= javascript_include_tag "https://maps.googleapis.com/maps/api/js?key=#{ENV['GOOGLE_MAPS_API_KEY']}&libraries=places" %>
```

---

## Verification

### 1. Check Gem Installation

```bash
bundle exec rails console
> Bali::VERSION
=> "1.4.19"  # or current version
```

### 2. Check Component Rendering

Create a test view:

```erb
<%# app/views/home/index.html.erb %>
<%= render Bali::Button::Component.new(name: 'Test Button', variant: :primary) %>
<%= render Bali::Card::Component.new do %>
  <p>Card content</p>
<% end %>
```

### 3. Check CSS Loading

Inspect the rendered button - it should have classes like `btn btn-primary`. If styling is missing:

1. Check Tailwind is processing your CSS
2. Verify `@source` paths are correct
3. Ensure `bali-view-components/css/bali.css` is imported

### 4. Check Stimulus Controllers

Open browser console and look for:
- No "Unknown controller" warnings
- Components respond to interactions (dropdowns open, modals work)

---

## Troubleshooting

### "Component not styled"

The Tailwind build isn't scanning Bali component files.

**Fix:** Ensure `@source` paths in your CSS point to `node_modules/bali-view-components/app/components/**/*.{erb,rb}`.

### "Unknown Stimulus controller"

Controllers aren't registered.

**Fix:** Ensure `registerControllers(application)` is called in your JavaScript.

### "Can't find bali-view-components CSS"

Package not installed or wrong import path.

**Fix:**
1. Run `npm install bali-view-components`
2. Check import paths match package.json exports

### Icons not showing

Bali uses Lucide icons via Iconify.

**Fix:** Ensure your app includes Iconify or the icon CSS is loaded. Icons should render as `<span class="iconify lucide--icon-name">`.

---

## Next Steps

- [Component Usage Guide](components.md) - Learn component patterns and slots
- [FormBuilder Guide](form-builder.md) - Enhanced form helpers
- [Accessibility Guide](accessibility.md) - WCAG compliance
