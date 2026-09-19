# Installation Guide

This guide covers complete setup of Bali ViewComponents in your Rails application.

## Prerequisites

- Rails 8.1+ (the gemspec requires `>= 8.1, < 9.0`)
- Ruby 4.0+
- Node.js 18+ and npm/yarn
- Tailwind CSS v4 (via tailwindcss-rails or Vite)
- daisyUI 5.7+

---

## Step 0: `bin/rails g bali:install`

Steps 1 and 2 are yours. Everything from Step 3 down, the generator writes:

```bash
bin/rails g bali:install          # add --block-editor to turn the Block Editor on
yarn install
bin/rails tailwindcss:build
```

| Step below | What the generator writes |
|---|---|
| 3 — Tailwind + daisyUI | `@plugin "daisyui"`, the engine bridge and `bali.css`, in the order Tailwind needs, into whichever Tailwind entry point this app has |
| 4 — JavaScript | the `registerAll` / `registerCharts` imports and calls |
| 5 — FormBuilder | `config/initializers/bali.rb` with the one line and the reason for it |
| 6 — peer dependencies | every REQUIRED peer, into `package.json` — `daisyui` into `devDependencies`, where all seven keep it, the rest into `dependencies` |

**What it does not write, and why.** Across the seven applications using Bali,
`application.css` shares exactly three substantive lines, the initializer shares exactly one,
and `controllers/index.js` shares two calls. The rest genuinely differs — the AFAL theme alone
is done four ways — so the generator prints those as text to paste rather than inventing an
eighth way. The list it prints: the daisyUI `themes:` block, `@custom-variant dark`, the AFAL
theme import, `@plugin "@tailwindcss/typography"` (yours, not Bali's — Bali only ships the
patch that keeps `prose-invert` working under daisyUI), `installConfirmDialog` with localised
labels, and `bin/rails bali:install:migrations:<feature>`.

**Running it twice writes nothing twice, and so does running it on an app that was wired by
hand** — which is what makes it the right thing to run after an upgrade: a line added to this
list in a later version lands, and everything already there is left alone. "Already there" is
matched on shape, not on this generator's spelling of it, because the fleet does not use that
spelling: a daisyUI plugin in block form with your themes inside, an
`import { registerAll, installConfirmDialog } from "bali-view-components"` with two symbols on
the line, `registerAll` imported under an alias from a private path, `daisyui` sitting in
`devDependencies`. All four are left exactly as they are, and each has a test.

**The one thing it never rewrites is your `bali-view-components` pin.** A pin is a decision —
a tag, a branch, a `link:` to a local checkout — so after a bump the generator tells you the
pin and the gem version and lets you move it:

```
    warn  package.json pins bali-view-components at github:Grupo-AFAL/bali-view-components#<the
          tag you are on>, and this gem is v<the one you just bundled>. Move the pin yourself so
          the JavaScript and the Ruby are the same release
```

**Scope: esbuild and jsbundling**, which is what all seven use. A Vite application gets the
same four files. An importmap application gets Steps 3 and 5 and **keeps its Stimulus index
exactly as it is** — the generator asks whether anything here resolves a bare specifier
(`package.json`? `config/importmap.rb`? what shape is the index?), not whether
`app/javascript/controllers/index.js` exists, because a bare `rails new` has that file and
writing into it would cost the app every controller it registers, not just Bali's. It says
which of the three answers stopped it and prints the lines to add once a bundler is in. See
Step 4.

**The CSS half asks the same kind of question**: not "is there a Tailwind entry point here"
but "will anything compile one". With neither tailwindcss-rails nor a `build:css` script in
`package.json`, no entry point is written — the file would be the input to a build that does
not exist, and Bali would render unstyled with nothing to say why. And an app with no
`package.json` at all gets only the engine bridge, the one line of the three that resolves
without node_modules; the other two are printed.

**`bin/rails g bali:install` and `bin/rails bali:install:migrations` share a prefix and are
different things.** The second is the rake namespace the Rails engine API generates: one task
that copies every engine migration into your app, plus six that copy one each
(`:saved_views`, `:content_versions`, `:entity_references`, `:acknowledgments`,
`:block_editor_comments`, `:dashboard_widgets`). The generator copies no migrations on
purpose: the engine's tables belong to the features that use them, only three of the seven
applications mount the engine at all, and installing tables for the other four would be
writing schema nobody asked for. Forgetting the `g` is not silent either — `bin/rails
bali:install` answers `Unrecognized command "bali:install"` and then
`Did you mean?  bali:install:migrations`.

---

## Step 1: Install the Gem

Bali is not published to RubyGems. Add to your `Gemfile`, pinning a tag:

```ruby
# Bundler resolves git sources before rubygems ones, so these two must be declared FIRST
gem "lucide-rails"
gem "view_component-contrib"

gem "bali_view_components", github: "Grupo-AFAL/bali-view-components", tag: "v3.4.0"
```

Run bundler:

```bash
bundle install
```

Nothing else. The gemspec declares everything Bali loads at boot — `csv` and `simple_command`
among them — so the lines apps used to copy into their own Gemfile under "Required by Bali"
can go. `rrule` can go too: the override that patches `RRule::Rule` with `humanize` is guarded,
so an app without the gem boots (it used to raise `NameError: uninitialized constant RRule` on
the first request). Keep `gem "rrule"` only if your own code builds recurrence rules — which is
the only way you could have an `RRule::Rule` for Bali to humanize in the first place.

`pagy` is the same shape and stays out of the gemspec for the same reason: Bali never builds a
Pagy, it only renders one you pass to `DataTable` or `Pagination`. Add `gem "pagy"` when you
paginate.

---

## Step 2: Install JavaScript Package

Install the npm package, which contains the Stimulus controllers and the CSS:

```bash
npm install bali-view-components @hotwired/stimulus @hotwired/turbo-rails daisyui
# or
yarn add bali-view-components @hotwired/stimulus @hotwired/turbo-rails daisyui
```

Those three are **required peer dependencies**, so your package manager will not install
them for you — and two of them fail quietly if you skip them:

| Peer | Why it is required |
|------|--------------------|
| `@hotwired/stimulus` | Every controller extends it. |
| `@hotwired/turbo-rails` | Reached through the `window.Turbo` global rather than an import, so **no bundler will warn you it is missing** — the components simply stop reacting. |
| `daisyui` | The Ruby components emit daisyUI class names, so without it they render *unstyled*, not merely unthemed. |

**Six more are required**, for a duller reason: shipped files import them with a plain
top-level `import`, so `registerAll` puts them in your bundle whether you render the component
or not, and esbuild has to resolve them to build at all.

```bash
yarn add @rails/activestorage @rails/request.js date-fns lodash.debounce lodash.throttle rrule
```

| Peer | Imported by |
|------|-------------|
| `@rails/activestorage` | DirectUpload |
| `@rails/request.js` | Tabs, SlimSelect, SortableList, WidgetGrid, InputOnChange |
| `date-fns` | Timeago |
| `lodash.debounce` | SubmitOnChange |
| `lodash.throttle` | Navbar, ElementsOverlap |
| `rrule` | RecurrentEventRuleForm |

They were listed as optional, which was never true: on an app that installed only the three
above and wired the documented `registerAll` + `registerCharts`, `yarn build` stopped with 22
`Could not resolve` errors across 12 packages — 13 of them from these six. Every application
in the fleet had installed all six anyway, because a build that stops is not an option a host
can decline. `bin/rails g bali:install` writes all nine.

Everything Bali touches beyond those nine is an **optional** peer declared per feature:
install only what you actually render, and if you skip one the build still succeeds. *Step 6:
External Dependencies* below lists them, and the grouped comment in the package's own
`package.json` maps every optional peer to the entry point that reaches for it.

---

## Step 3: Configure Tailwind CSS v4 + DaisyUI

Bali uses **Tailwind CSS v4** with **DaisyUI 5** for styling.

### Create/Update Your CSS Entry Point

`bin/rails g bali:install` writes the `@plugin` and the two `@import`s below into your
Tailwind entry point (and leaves an existing daisyUI block alone). **Which file that is
depends on which gem builds your Tailwind**, and the generator picks whichever of the two is
there:

| Gem | Entry point | Bridge line | Build command |
|---|---|---|---|
| `tailwindcss-rails` — what all seven apps use | `app/assets/tailwind/application.css` | `@import "../builds/tailwind/bali";` | `bin/rails tailwindcss:build` |
| `cssbundling-rails` — what `rails new --css=tailwind` gives you once a JS bundler is in the app | `app/assets/stylesheets/application.tailwind.css` | `@import "bali-view-components/tailwind/engine.css";` | `yarn build:css` |

Same file behind both bridges; the first resolves it through the gem, the second through npm.
What follows is the tailwindcss-rails shape by hand, plus the dark-mode setup the generator
prints rather than writes:

```css
@import "tailwindcss";
@plugin "daisyui";

/* =============================================
   Bali ViewComponents - Tailwind class scanning
   =============================================
   Tailwind v4 needs to scan Bali's Ruby, ERB *and JS* files to detect
   the utility classes its components use, and the gem installs to a
   system directory outside your project. The gem resolves that itself:
   it ships app/assets/tailwind/bali/engine.css with its @source globs
   relative to itself, and tailwindcss-rails (>= 4.3) writes
   app/assets/builds/tailwind/bali.css — an @import to that file's real
   path on this machine — before every tailwindcss:build,
   tailwindcss:watch and assets:precompile (`bin/rails
   tailwindcss:engines` runs that step alone). One import, nothing to
   keep in sync when the gem moves. */
@import "../builds/tailwind/bali";

/* =============================================
   Bali CSS Import
   =============================================
   One line. bali.css pulls in base styles, forms, typography and every
   component sheet. (Before v3 you also had to import components.css by hand;
   forgetting it left every component unstyled with no error.)
*/
@import "bali-view-components/css/bali.css";

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

> **Note**: Bali components define Tailwind classes in Ruby files (e.g., `'flex gap-2 btn-primary'`) and in JavaScript — `modal/index.js` swaps the submit button for `loading loading-spinner loading-sm` while a drawer form is in flight — and the FormBuilder, which lives entirely under `lib/bali/form_builder/`, is the only place that writes the error and state classes: `input-error`, `select-error`, `textarea-error`, `checkbox-error`, `radio-error`, `toggle-error`, `fieldset-label`, the whole `range-*` family. `engine.css` scans `app/**/*.{rb,erb,js,jsx,ts,tsx,mjs,cjs}` and `lib/bali/**/*.rb` for exactly that reason; scanning only `app/` would compile without a warning and silently drop every form error style, and a glob without `jsx` compiled just as quietly while leaving out 54 classes of Gantt and BlockEditor — the React components — which is how v3.2.1 shipped (#1124).
>
> `app/assets/builds` is already in the `.gitignore` tailwindcss-rails installs; the generated file is never committed. Do **not** write a `@source` glob at the gem directory yourself (`vendor/bundle/...`, `/usr/local/bundle/...`): the path differs per machine, and a glob that matches nothing does not fail — it silently leaves every Bali class out of the build.
>
> If your app builds Tailwind without tailwindcss-rails, import the same file from the npm package instead: `@import "bali-view-components/tailwind/engine.css";`. `@source` paths resolve relative to the stylesheet that declares them, so both routes scan the same tree.

### Overriding Bali styles

Bali's own component CSS ships in `@layer components`, so **a utility class on
the element wins** — `class="menu-item lg:hidden"` hides the item, no `!`
variant needed. Put the import after `@import "tailwindcss"` and after
`@plugin "daisyui"` so the layer order is the one Tailwind sets up.

A handful of sheets stay unlayered on purpose, because their whole job is to
beat a rule daisyUI emits inside `@layer utilities` (daisyUI 5 does not use
`@layer components`): `forms.css`, `datepicker.css`, `slim_select.css`,
`breadcrumb/index.css`, `data_table/index.css` and
`side_menu/daisyui-overrides.css`. Each file's header names the rule it is
fighting. To override one of those from your app, use a `!` utility variant or
plain unlayered CSS imported after Bali.

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

Bali needs a JavaScript bundler: esbuild (through jsbundling-rails) or Vite. That is what all
seven applications in the fleet use, what `bin/rails g bali:install` writes, and the only thing
that resolves what Bali imports.

### Import maps: not supported, and there is nothing to pin

This page used to say `pin "bali-view-components", to: "bali-view-components.js"`. **No such
file exists**, in the gem or in the npm package: what ships is ESM source — 91 modules behind
the root entry (counted with an esbuild metafile), importing their peers by bare specifier
(`@hotwired/stimulus`, `date-fns`, `@rails/request.js`…). Pinning that means pinning every one
of the 91 plus every peer, by hand, and re-pinning them on each upgrade. The
[JavaScript integration guide](javascript-integration.md#import-maps-not-supported) carries
the measurement on the 31-pin recipe that used to live there.

An unresolved bare specifier does not degrade, it fails the whole module: `eagerLoadControllersFrom`
never runs and the app loses **every** controller it registers, with one console line as the
only symptom. So `bin/rails g bali:install` leaves an importmap app's Stimulus index alone and
prints these three lines instead:

```bash
bundle add jsbundling-rails
bin/rails javascript:install:esbuild
bin/rails g bali:install
```

Vite resolves the same imports with no extra step. It may need the gem's path allowed —
`server: { fs: { allow: ['.', baliGemPath] } }`.

### What the generator writes into your Stimulus index

```javascript
// app/javascript/controllers/index.js
import { Application } from "@hotwired/stimulus"
import { registerAll } from "bali-view-components"

const application = Application.start()

// Register your local controllers
import HelloController from "./hello_controller"
application.register("hello", HelloController)

// Register all Bali controllers
registerAll(application)

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

# Set as default form builder globally. Use the config key, not
# `ActionView::Base.default_form_builder = ...`: touching ActionView::Base from an
# initializer fires every `on_load(:action_view)` hook before the autoloader is
# ready, which breaks engines that include helpers there (bali-analytics does).
Rails.application.config.action_view.default_form_builder = "Bali::FormBuilder"

# Or configure per-form
# <%= form_with model: @user, builder: Bali::FormBuilder do |f| %>
```

---

## Step 6: External Dependencies

Every library below is an **optional peer dependency**: it is declared in Bali's
`package.json` but never installed for you, and the controller that needs it loads it with
a dynamic `import()`. That means a component you do not use costs you nothing, and a
component you *do* use fails at runtime rather than at build time if its library is
missing.

> That last sentence is true as of this version, and it was not free. esbuild resolves `import()`
> at BUNDLE time like any other import and fails the build on a specifier it cannot find —
> dynamic or not — **unless the call carries a `.catch()`**; its own error message says so.
> Every one of these calls now does, through `optionalPeer()`, which logs the package name
> and the `yarn add` line and lets the controller return. Before that, skipping any of them
> broke `yarn build` with `Could not resolve` and this paragraph was simply wrong.
>
> The six peers that this could NOT be done for — the ones a top-level `import` pulls in
> unconditionally — were moved to *required* in Step 2 instead. The rule, both directions:
> **statically imported means required; lazily imported means optional.**

| Component | Dependency | Installation |
|-----------|------------|--------------|
| Datepicker, Calendar | Flatpickr | `npm install flatpickr` |
| SlimSelect | Slim Select | `npm install slim-select` |
| SortableList, Kanban | SortableJS | `npm install sortablejs` |
| Carousel | Glide | `npm install @glidejs/glide` |
| Tooltip, Dropdown, HoverCard | Tippy | `npm install tippy.js` |
| QrScanner | qr-scanner | `npm install qr-scanner` |
| Chart (`/charts` entry) | Chart.js | `npm install chart.js` |
| LocationsMap | Google Maps marker clusterer | `npm install @googlemaps/markerclusterer` + the Maps script below |
| AutocompleteAddress | Google Maps API | Add the script to your layout (below) |
| TrixAttachments | Trix | Included with Rails (Action Text) |

Timeago (`date-fns`), RecurrentEventRuleForm (`rrule`), DirectUpload (`@rails/activestorage`),
Tabs/SlimSelect/SortableList/DataTable (`@rails/request.js`) and
Navbar/ElementsOverlap/SubmitOnChange (`lodash.throttle`, `lodash.debounce`) used to be on
this table. They are in **Step 2** now: they are required, because they are in your bundle
either way.

Components behind their own entry point carry their own dependency sets, which are larger:

| Entry point | Dependency set |
|-------------|----------------|
| `bali-view-components/charts` | `chart.js` |
| `bali-view-components/block-editor` | `@blocknote/core` `/react` `/mantine` (>= 0.53.0, and all three pinned to the *same* version), `@mantine/core`, `@mantine/hooks`, `react`, `react-dom`; `shiki` only for syntax-highlighted code blocks. See [the BlockEditor API guide](../api/block-editor.md). |
| `bali-view-components/rich-text-editor` | The `@tiptap/*` set plus `lowlight`, `highlight.js` and `tippy.js`. **Deprecated in v3, removed in v4** — migrate to the block editor. |

### Flatpickr Setup

```javascript
// Import CSS in your JS entry point
import "flatpickr/dist/flatpickr.min.css"
```

### Google Maps (for AutocompleteAddress)

No script tag: Bali loads the Maps API itself, on demand, from the controller that
needs it. Give it the key instead.

```ruby
# config/initializers/bali.rb — read by LocationsMap and coordinates_polygon
Bali.config { |config| config.google_maps_key = Rails.application.credentials.dig(:google, :maps_key) }
```

The `autocomplete-address` controller is wired by hand, so it takes its key from the
element (or from a global):

```erb
<div data-controller="autocomplete-address"
     data-autocomplete-address-api-key-value="<%= Bali.google_maps_key %>">
```

See [External Services](external-services.md) for the full setup.

---

## Verification

### 1. Check Gem Installation

```bash
bundle exec rails console
> Bali::VERSION
=> "3.4.0"  # the tag you pinned in Step 1, without the leading v
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

Bali components define Tailwind classes in Ruby files (e.g., `'flex gap-2 btn-primary'`) — under `app/` **and** under `lib/` (the FormBuilder). If components appear unstyled or specific classes aren't working, Tailwind isn't scanning the component files.

**Fix:** Ensure your `@source` directives scan Bali's source files in node_modules — both lines:

```css
/* Correct - scans the components (app/) AND the FormBuilder (lib/) */
@source "../../../node_modules/bali-view-components/app/**/*.{rb,erb,js,jsx,ts,tsx,mjs,cjs}";
@source "../../../node_modules/bali-view-components/lib/bali/**/*.rb";

/* Wrong - misses lib/: every FormBuilder state class (input-error, select-error,
   fieldset-label, the range-* family) is silently absent from the build, so
   invalid fields render with no error border */
@source "../../../node_modules/bali-view-components/app/**/*.{rb,erb,js,jsx,ts,tsx,mjs,cjs}";

/* Wrong - misses JS-written classes (the drawer submit spinner, for one) */
@source "../../../node_modules/bali-view-components/app/**/*.{rb,erb}";

/* Wrong - misses the React components: Gantt and BlockEditor are .jsx, and
   every class only they use is silently absent (#1124) */
@source "../../../node_modules/bali-view-components/app/**/*.{rb,erb,js}";

/* Wrong - only scans ERB, misses Ruby files where most classes are defined */
@source "../../../node_modules/bali-view-components/app/components/**/*.erb";
```

**Verify:** After fixing, rebuild CSS (`bin/rails tailwindcss:build`) and check that expected classes exist in your compiled stylesheet.

### "Component not styled"

The Tailwind build isn't scanning Bali component files.

**Fix:** Ensure your CSS has both `@source` globs: `node_modules/bali-view-components/app/**/*.{rb,erb,js,jsx,ts,tsx,mjs,cjs}` and `node_modules/bali-view-components/lib/bali/**/*.rb`.

### "Unknown Stimulus controller"

Controllers aren't registered.

**Fix:** Ensure `registerAll(application)` is called in your JavaScript — `bin/rails g
bali:install` writes that line, and running it again on an app that already has it writes
nothing.

### "Can't find bali-view-components CSS"

Package not installed or wrong import path.

**Fix:**
1. Run `npm install bali-view-components`
2. Check import paths match package.json exports

### Icons not showing

Bali uses Lucide icons, rendered as inline `<svg>` markup via the `lucide-rails` gem — there is no external icon font or CDN to load.

**Fix:** Check the icon name against [lucide.dev/icons](https://lucide.dev/icons) or `Bali::Icon::LucideMapping` (old Bali names). An unresolvable name raises `Bali::Options::IconNotAvailable` instead of rendering silently blank.

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

### A second drawer on the same page

A `drawer#open` trigger may name the drawer it opens, and usually does not:

```erb
<%# The ordinary spelling: no name, so the open event is a broadcast %>
<%= render Bali::Link::Component.new(name: "New Studio", href: new_studio_path,
      data: { action: "drawer#open" }) %>
```

A broadcast is answered by every **shared** drawer on the page, which is the right thing while the
page has one — the shell drawer above. The moment a page has a second drawer that belongs to one
feature and has its own trigger, that one must opt out, or an unnamed trigger opens both and only
one of them is closed afterwards. A `<dialog>` left in the top layer makes the whole document
inert, so the symptom is a page that looks normal and stops answering the mouse.

```erb
<%# Belongs to one feature, opened only by its own trigger %>
<%= render Bali::Drawer::Component.new(drawer_id: "cart", shared: false) do %>
  ...
<% end %>

<%# ...and the trigger names it %>
<%= render Bali::Button::Component.new(name: "Cart",
      data: { action: "drawer#open", drawer_id: "cart" }) %>
```

`Bali::FeedbackWidget` already does this for its own panel, so mounting the widget alongside
`AppLayout` needs nothing from you.

---

## Next Steps

- [Component Usage Guide](components.md) - Learn component patterns and slots
- [FormBuilder Guide](form-builder.md) - Enhanced form helpers
- [Accessibility Guide](accessibility.md) - WCAG compliance
