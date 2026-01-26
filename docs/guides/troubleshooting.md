# Troubleshooting Guide

This guide covers common issues when using Bali ViewComponents and their solutions.

---

## Styling Issues

### Components Have No Styling / Look Broken

**Symptoms:**
- Buttons appear as unstyled text
- Cards have no borders or shadows
- DaisyUI classes like `btn-primary` don't work

**Causes & Solutions:**

#### 1. Tailwind Not Processing Bali Components

Tailwind needs to scan Bali component files to include their classes in the build.

**Fix:** Add `@source` directives in your CSS entry point:

```css
/* app/assets/tailwind/application.css */
@import "tailwindcss";
@plugin "daisyui";

/* Add these source paths */
@source "../../../node_modules/bali-view-components/app/components/**/*.{erb,rb}";
@source "../../../node_modules/bali-view-components/lib/bali/**/*.rb";
```

#### 2. Bali CSS Not Imported

**Fix:** Import Bali's CSS files:

```css
@import "bali-view-components/css/bali.css";
@import "bali-view-components/css/components.css";
```

#### 3. Wrong Tailwind Version

Bali uses Tailwind CSS v4 syntax. Tailwind v3 uses different configuration.

**Check your version:**
```bash
npm list tailwindcss
```

**Tailwind v4 syntax (correct for Bali):**
```css
@import "tailwindcss";
@plugin "daisyui";
```

**Tailwind v3 syntax (won't work with Bali's examples):**
```javascript
// tailwind.config.js
module.exports = {
  plugins: [require("daisyui")]
}
```

#### 4. DaisyUI Not Installed

**Fix:**
```bash
npm install daisyui
```

---

### Wrong Theme / Colors Don't Match

**Symptoms:**
- Colors look different than expected
- Dark mode not working

**Fix:** Configure themes in your CSS:

```css
@plugin "daisyui" {
  themes: light --default, dark;
}
```

**Enable dark mode in HTML:**
```html
<html data-theme="dark">
```

---

### Custom Classes Not Working

**Symptoms:**
- Custom Tailwind classes added to components don't appear

**Cause:** Your custom class might not be in Tailwind's scanned sources.

**Fix:** Ensure your view files are in Tailwind's source paths:

```css
@source "../../../views/**/*.erb";
@source "../../../helpers/**/*.rb";
```

---

## JavaScript Issues

### "Unknown Stimulus controller" Warnings

**Symptoms:**
- Console shows: `Unknown controller: "modal"`
- Interactive components don't respond to clicks

**Causes & Solutions:**

#### 1. Controllers Not Registered

**Fix:** Register Bali controllers in your Stimulus application:

```javascript
// app/javascript/controllers/application.js
import { Application } from "@hotwired/stimulus"
import { registerControllers } from "bali-view-components"

const application = Application.start()
registerControllers(application)
```

#### 2. JavaScript Not Loading

**Check:** Open browser DevTools console. Look for JavaScript errors.

**Common issues:**
- Import map not configured correctly
- Vite/esbuild not bundling bali-view-components

---

### Dropdowns/Modals Don't Open

**Symptoms:**
- Clicking trigger does nothing
- No console errors

**Possible causes:**

1. **Z-index conflicts:** Modal might be opening behind other elements

   **Fix:** Check CSS z-index values. DaisyUI modals use `z-50`.

2. **Event not reaching controller:**

   **Debug:** Add this to console and try clicking:
   ```javascript
   baliDispatchDebugEnabled = true
   ```

3. **Turbo interference:** Turbo Drive might be intercepting clicks

   **Fix:** Add `data-turbo="false"` to the trigger if needed.

---

### Flatpickr (Date Picker) Not Working

**Symptoms:**
- Date field shows plain text input
- No calendar popup

**Fixes:**

1. **Install Flatpickr:**
   ```bash
   npm install flatpickr
   ```

2. **Import CSS:**
   ```javascript
   import "flatpickr/dist/flatpickr.min.css"
   ```

3. **Check controller registration:** Ensure `datepicker` controller is registered.

---

### Slim Select Not Working

**Symptoms:**
- Select field looks like plain HTML select
- No search functionality

**Fixes:**

1. **Install Slim Select:**
   ```bash
   npm install slim-select
   ```

2. **Check controller:** Ensure `slim-select` controller is registered.

---

## Form Issues

### FormBuilder Methods Not Found

**Symptoms:**
- `undefined method 'text_field_group' for #<ActionView::Helpers::FormBuilder>`

**Cause:** Not using Bali's FormBuilder.

**Fix:** Use Bali::FormBuilder:

```erb
<%= form_with model: @user, builder: Bali::FormBuilder do |f| %>
  <%= f.text_field_group :name %>
<% end %>
```

Or set as default:

```ruby
# config/initializers/bali.rb
ActionView::Base.default_form_builder = Bali::FormBuilder
```

---

### Validation Errors Not Displaying

**Symptoms:**
- Form submits but errors don't show
- No red borders on invalid fields

**Possible causes:**

1. **Not using `_group` methods:**

   ```erb
   <%# This shows errors %>
   <%= f.text_field_group :email %>

   <%# This does NOT show errors %>
   <%= f.text_field :email %>
   ```

2. **Model doesn't have errors:** Check your model validations are firing.

   ```ruby
   # In controller, ensure validation happens
   if @user.save  # or @user.valid?
     # ...
   else
     # errors will now be present
   end
   ```

---

### Form Submission Issues with Modals

**Symptoms:**
- Form in modal submits but modal doesn't close
- Modal closes but form doesn't submit

**Fix:** Use the `modal: true` option on submit:

```erb
<%= f.submit_actions "Save", modal: true %>
```

This adds the correct Stimulus actions for modal integration.

---

## Component Issues

### Component Not Found

**Symptoms:**
- `uninitialized constant Bali::ComponentName::Component`

**Possible causes:**

1. **Typo in component name:** Check exact spelling in `app/components/bali/`

2. **Gem not loaded:** Ensure `bali_view_components` is in your Gemfile and bundled.

3. **Zeitwerk autoloading issue:** Try `rails restart` or check for naming conflicts.

---

### Slots Not Rendering

**Symptoms:**
- `with_header`, `with_actions`, etc. content doesn't appear

**Fix:** Ensure you're using the block syntax correctly:

```erb
<%# WRONG - missing block variable %>
<%= render Bali::Card::Component.new do %>
  <% with_header { "Title" } %>  <%# This won't work! %>
<% end %>

<%# CORRECT - use block variable %>
<%= render Bali::Card::Component.new do |card| %>
  <% card.with_header { "Title" } %>
<% end %>
```

---

### Icons Not Showing

**Symptoms:**
- Icon placeholders appear but no actual icons
- Empty space where icons should be

**Context:** Bali uses Lucide icons via Iconify.

**Possible fixes:**

1. **Check icon name:** Use correct Lucide icon names. See [lucide.dev/icons](https://lucide.dev/icons).

   ```erb
   <%# Correct %>
   <%= render Bali::Icon::Component.new('pencil') %>

   <%# Old Bali names still work via mapping %>
   <%= render Bali::Icon::Component.new('edit') %>  <%# maps to 'pencil' %>
   ```

2. **Iconify not loading:** Ensure Iconify CSS/JS is loading if using external icons.

---

## Preview / Lookbook Issues

### Previews Not Showing

**Symptoms:**
- Lookbook sidebar is empty
- Components don't appear in preview list

**Fixes:**

1. **Start the preview server:**
   ```bash
   cd spec/dummy && bin/dev
   ```

2. **Check preview files exist:** Each component should have `preview.rb` in its folder.

3. **Check for syntax errors:** Ruby errors in preview files will hide them.

---

### Preview Crashes with Request/Path Errors

**Symptoms:**
- `undefined method 'path' for nil:NilClass`
- Errors related to `request.path`

**Cause:** Using `request` in preview context where it's not available.

**Fix:** Use hardcoded paths in previews:

```ruby
# BAD - crashes in preview
def default
  render Component.new(url: helpers.request.path)
end

# GOOD - works in preview
def default
  render Component.new(url: '/lookbook')
end
```

---

### Preview Shows Raw HTML Instead of Rendered Components

**Symptoms:**
- See literal HTML tags instead of rendered component
- `safe_join` output appears as text

**Cause:** Using `safe_join` inside component blocks in previews.

**Fix:** Use `render_with_template` with an ERB file:

```ruby
# BAD
def with_multiple_items
  render Component.new do |c|
    c.with_item { safe_join([render(OtherComponent.new)]) }  # Won't work!
  end
end

# GOOD
def with_multiple_items
  render_with_template
end
```

Then create `with_multiple_items.html.erb` in the preview folder.

---

## Performance Issues

### Slow Initial Page Load

**Possible causes:**

1. **Many components on page:** Consider lazy loading or pagination.

2. **N+1 queries in components:** Use eager loading in controllers.

3. **Large CSS file:** Ensure Tailwind is purging unused classes.

---

### Stimulus Controllers Loading Slowly

**Fix:** Ensure controllers are bundled, not loaded from CDN:

```javascript
// Good - bundled
import { Application } from "@hotwired/stimulus"

// Avoid - slow CDN load
// import { Application } from "https://cdn.jsdelivr.net/..."
```

---

## Getting Help

### Debug Information to Collect

When asking for help, include:

1. **Versions:**
   ```bash
   bundle exec rails -v
   ruby -v
   npm list tailwindcss daisyui bali-view-components
   ```

2. **Browser console errors** (full text)

3. **Server logs** (relevant parts)

4. **Component code** you're trying to use

### Resources

- [GitHub Issues](https://github.com/Grupo-AFAL/bali/issues) - Report bugs
- [Lookbook](http://localhost:3001/lookbook) - Component examples (run locally)
- [DaisyUI Docs](https://daisyui.com/) - Styling reference
- [ViewComponent Docs](https://viewcomponent.org/) - Framework reference
