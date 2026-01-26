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
@plugin "daisyui";

/* =============================================
   Bali ViewComponents - Tailwind class scanning
   =============================================
   IMPORTANT: Tailwind v4 needs to scan Bali's Ruby and ERB files
   to detect utility classes used in components. The gem installs
   to a system directory outside your project, but the npm package
   mirrors all source files in node_modules.
*/
@source "../../../node_modules/bali-view-components/app/**/*.{rb,erb}";

/* =============================================
   Bali CSS Imports
   =============================================
   - bali.css: Base styles, forms, typography, variables
   - components.css: Component-specific CSS (navbar, calendar, etc.)
*/
@import "bali-view-components/css/bali.css";
@import "bali-view-components/css/components.css";

/* =============================================
   Dark Mode Configuration
   =============================================
   Enable proper dark mode support with DaisyUI themes.
*/
@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));

:root {
  color-scheme: light;
}

[data-theme="dark"] {
  color-scheme: dark;
}
```

> **Note**: The `@source` directive is required because Bali components define Tailwind classes in Ruby files (e.g., `'flex gap-2 btn-primary'`). Without it, Tailwind won't detect these classes and components will appear unstyled.

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

### Components unstyled or classes missing

Bali components define Tailwind classes in Ruby files (e.g., `'flex gap-2 btn-primary'`). If components appear unstyled or specific classes aren't working, Tailwind isn't scanning the component files.

**Fix:** Ensure your `@source` directive scans Bali's source files in node_modules:

```css
/* Correct - scans all Ruby and ERB files */
@source "../../../node_modules/bali-view-components/app/**/*.{rb,erb}";

/* Wrong - only scans ERB, misses Ruby files where most classes are defined */
@source "../../../node_modules/bali-view-components/app/components/**/*.erb";
```

**Verify:** After fixing, rebuild CSS (`bin/rails tailwindcss:build`) and check that expected classes exist in your compiled stylesheet.

### "Component not styled"

The Tailwind build isn't scanning Bali component files.

**Fix:** Ensure `@source` paths in your CSS point to `node_modules/bali-view-components/app/**/*.{rb,erb}`.

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

### Modal or Drawer visible on page load

By default, `Bali::Modal::Component` renders with `active: true` (open state). This is intentional for modals rendered in response to user actions. For "shell" modals that get populated dynamically, you need to start them closed.

**Fix:** Pass `active: false` when rendering shell modals/drawers:

```erb
<%# Shell modal - closed by default, opened via Stimulus controller %>
<%= render Bali::Modal::Component.new(id: "main-modal", active: false) do %>
  <%= render Bali::Skeleton::Component.new(variant: :modal) %>
<% end %>

<%# Shell drawer - already defaults to active: false, but explicit is clearer %>
<%= render Bali::Drawer::Component.new(drawer_id: "main-drawer", active: false) do %>
  <%= render Bali::Skeleton::Component.new(variant: :list, lines: 5) %>
<% end %>
```

---

## Next Steps

- [Component Usage Guide](components.md) - Learn component patterns and slots
- [FormBuilder Guide](form-builder.md) - Enhanced form helpers
- [Accessibility Guide](accessibility.md) - WCAG compliance
