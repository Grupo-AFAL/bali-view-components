# Migrating from Bali v2 to v3

The largest single area v3.0 breaks is **the index page** — `DataTable`, its toolbar,
`Bali::Table` selection and the surface that wraps them — and that is what most of this
guide is about. Three things apply to every app regardless of whether it renders a
`DataTable`: the *Version floors* below, the *npm peer dependencies* right after them, and
one behaviour change listed under *Behaviour changes* — `FilterForm` now reads `?view=` on
any listing that declares grouping.

## Version floors

| | v2 | v3.0 |
|---|---|---|
| Rails | `>= 7.0, < 9.0` | `>= 8.1, < 9.0` |
| Ruby | `>= 4.0` (the docs wrongly said 3.0+) | `>= 4.0` |
| daisyUI | 5.6.x | 5.7.x |

Bundler resolves the gem floor for you — an app still on Rails 7 gets a resolution error,
not a runtime surprise. daisyUI is not enforced by anything: it is the host's npm
dependency, and Bali's component CSS is written against the 5.7 class set.

## npm peer dependencies

v2's npm package declared `daisyui` as a regular dependency and left almost everything else
undeclared. v3 declares three **required** peers and 62 optional ones. Peers are not
installed for you — Yarn Classic ignores them entirely, and npm 7+ will auto-install the
required ones but now reports version conflicts instead of nesting a second copy.

Add the three required peers to your app if they are not already there:

```bash
yarn add @hotwired/stimulus @hotwired/turbo-rails daisyui
```

| Peer | Was | Now | If missing |
|------|-----|-----|------------|
| `daisyui` | a `dependency` of Bali, so you got it transitively | **required peer** | Components render with correct markup and **no styling** |
| `@hotwired/stimulus` | undeclared | **required peer** | Build error |
| `@hotwired/turbo-rails` | undeclared | **required peer** | **Silent** — it is used via the `window.Turbo` global, never imported, so no bundler warns you. Components stop reacting |

`daisyui` is the one to check first: an app that never installed it explicitly was relying
on Bali's transitive copy, and that copy is gone. Pin it yourself at 5.7.x.

Everything else is optional and declared per feature, so install only what you render — the
table in *Step 6* of the [installation guide](installation.md) maps each optional peer to
the component that loads it. If you already had a working v2 app, you almost certainly have
these installed; nothing new is required unless you adopt a component you were not using.

### `Bali.deprecator`

Every deprecation warning the gem emits now goes through a single
`ActiveSupport::Deprecation` registered as `Rails.application.deprecators[:bali]`. It obeys
the `config.active_support.deprecation` an app already sets, and it can be addressed on its
own:

```ruby
config.active_support.deprecators[:bali].behavior = :raise   # fail the build on Bali warnings
Bali.deprecator.silence { ... }                              # or scope one exception
```

### Removed, and deprecated

| Removed | Replacement |
|---|---|
| `Bali::Clipboard::SucessContent` | `Bali::Clipboard::SuccessContent` (the alias existed only for the typo) |
| `Bali::Utils::Url#add_query_params` | `#add_query_param(url, name, value)`, one name at a time |

`Bali::FilterForm.simple_filter` is **deprecated, not removed** — it still declares the
filter and now warns. It goes away in v4; migrate at your own pace:

```ruby
# v2
simple_filter :status, collection: [%w[Done done]], blank: "All", type: :slim_select

# v3 — one declaration that can also feed the advanced Filters popover
filter_attribute :status, type: :select, input: :slim_select,
  simple: true, advanced: false, options: [%w[Done done]], blank: "All"
```

`collection:` becomes `options:`, and the old `type:` (the widget) becomes `input:`, with
`type:` now naming the *data* type that drives the advanced UI's operators. Dropping
`advanced: false` is what puts the attribute in both UIs from one line — the reason the DSL
is going away. `#add_query_param` also stopped duplicating a param already present in the
URL (**#653**); if you were compensating for that by stripping the param first, you can
stop.

The goal of the change is that the correct index layout is what you get by *default*.
The reference composition is the `Complete` scenario of the IndexPage preview
(`bali/index_page/complete` in Lookbook) — it is the only place all seven control families
render at once. `/admin/movies` in the dummy app is the end-to-end reference against real
controllers, routes and Turbo Streams — saved views included, backed by the engine's default
store and a one-user demo owner; the only family it leaves out is host toolbar buttons.

## Every translation key moves to `bali_view.*`

v2 shipped its strings under **three** roots — `bali.*`, `view_components.bali.*` and
`helpers.*` — and two of them belong to somebody else: `view_components` is the namespace
`view_component-contrib` reserves for the host (any other component library shares it), and
`helpers` is Rails', which uses it to resolve labels and submit buttons for the host's own
forms. v3 uses one root per gem in the family, and this one is `bali_view`.

Two mechanical rules cover 302 of the 306 keys:

```
bali.<anything>                  →  bali_view.<anything>
view_components.bali.<anything>  →  bali_view.<anything>
```

The rest are the `helpers.*` squatters, which move next to the FormBuilder module that
emits them:

| v2 | v3 |
|---|---|
| `helpers.add.text` | `bali_view.form_builder.dynamic_fields.add` |
| `helpers.cancel.text` | `bali_view.form_builder.submit.cancel` |
| `helpers.clear.text` | `bali_view.form_builder.coordinates_polygon.clear` |
| `helpers.clear_holes.text` | `bali_view.form_builder.coordinates_polygon.clear_holes` |
| `helpers.generic_confirm_message.text` | `bali_view.form_builder.coordinates_polygon.confirm` |
| `helpers.apply.text` | *(deleted — nothing read it)* |

Three more keys are gone because nothing ever read them either, and they duplicated a
sibling: `view_components.bali.filters.filters` (say `bali_view.filters.filters_button`),
`…filters.remove_filters` (`bali_view.filters.clear_all`) and
`…filters.attributes.date_range.custom`.

### Host overrides work now — which is why you have to fix them

This is the part to read even if you never overrode a Bali string, because the two changes
interact. In v2 the engine appended its own locale files to `i18n.load_path` by hand, on top
of the copy `Rails::Engine` already registers. I18n merges in load order and the last file
wins, so the gem's files — appended last, after the host's — beat the app. **No override of
a key Bali defined has ever taken effect.** What looked like a working override was always a
key Bali did not define, i.e. an addition.

v3 deletes that initializer. `Rails::Engine` registers `config/locales` on its own, in an
order that puts every engine before the app, so an override in the host's
`config/locales/*.yml` finally wins.

The trap: a host that "overrode" a key Bali did not define is now overriding a key Bali
*does* define, under a name that moved. `Bali::PaginationFooter` is the live example — its
`summary` and `default_item_name` only existed as inline English defaults in Ruby, so an app
that wanted them in Spanish declared `view_components.bali.pagination_footer.*` and it
worked. Both keys now ship in `bali_view.pagination_footer.*` in en and es. Rename yours or
delete it; leaving it under the old path is silently dead.

```
grep -rn "^\s*bali:\|view_components:\|bali\.\|view_components\.bali\." config/locales app/
```

### Strings that had no key at all

44 user-visible strings were hardcoded in templates — the whole `DocumentEditor` app bar,
the `RichTextEditor` bubble menu (including a `placeholder="Ingresa la URL"` sitting in an
otherwise English file), `BlockEditor`'s export buttons, `DocumentPage`'s panels, and a
handful of `aria-label`s. They now resolve through `bali_view.*` in both locales. If your
app renders these components in Spanish, text that used to come out in English changes.
Two `aria-label`s got more specific on the way (`Close` → `Close message` on
`Bali::Message`, and the Filters panel close button), because a bare "Close" gives a screen
reader nothing to distinguish it by.

### The datepicker stops assuming Spanish

`DatepickerController`'s `locale` value defaulted to `'es'`, and `setLocale` returned the
Spanish flatpickr locale for **every** code that was not `'en'` — so a host on `fr` got a
Spanish calendar and nothing said so. The default is now `'en'`, and only locales the gem
declares are loaded; anything else falls back to flatpickr's built-in English. Every Bali
call site already emits `data-datepicker-locale-value` from `I18n.locale`, so this only
affects a host wiring the controller by hand — and a host that needs another locale
registers it with `flatpickr.localize()`.

## Overlay z-index: one scale, all new numbers

Every overlay used to invent its own z-index. The full inventory, before and after:

| Component | Where | v2 | v3 |
|---|---|---|---|
| `Dropdown` menu | `dropdown/component.rb` | `z-50` | `--bali-z-dropdown` (200) |
| `ActionsDropdown` menu (CSS mode) | `actions_dropdown/component.rb` | `z-1` | `--bali-z-dropdown` |
| `Navbar::DropdownItem` menu | `navbar/dropdown_item/component.rb` | `z-50` | `--bali-z-dropdown` |
| `SideMenu` collapsed group / bottom group / item flyouts | 4 templates | `z-50` | `--bali-z-dropdown` |
| `DataTable` saved views, column selector, export | 3 templates | `z-50` | `--bali-z-dropdown` |
| `Filters` popover panel | `filters/component.html.erb` | `z-50` | `--bali-z-dropdown` |
| `Filters::Condition` value menu | `filters/condition/component.html.erb` | `z-[100]` | `--bali-z-dropdown` |
| `Filters` multi-select list (built in JS) | `condition_controller.js` | `z-50` | `.filters-multi-select-content` → `--bali-z-dropdown` |
| `Drawer` root | `drawer/component.rb` | `z-[60]` | `--bali-z-drawer` (300) |
| `Drawer` scrim / panel (inside the root) | `drawer/*` | `z-[60]` / `z-[9999]` | `z-0` / `z-10` |
| `FeedbackWidget` scrim / panel | `feedback_widget/component.html.erb` | `z-[60]` / `z-[61]` | `calc(--bali-z-drawer - 1)` / `--bali-z-drawer` |
| `Modal` | `modal/component.html.erb` | `z-61` | `--bali-z-modal` (400) |
| `ImageGrid` lightbox | `image_grid/index.css` | `z-[100]` | `--bali-z-modal` |
| `DocumentEditor` fullscreen overlay | `document_editor/component.rb` | `z-50` | `--bali-z-modal` |
| `Command` backdrop / panel | `command/component.html.erb` | `z-[100]` / `z-[101]` | `calc(--bali-z-command - 1)` / `--bali-z-command` (500) |
| flatpickr calendar (portaled + static) | `bali/datepicker.css` | `99999` / `999` | `--bali-z-popover` (600) |
| SlimSelect list | `bali/slim_select.css` | `10000` | `--bali-z-popover` |
| `Status` panel | `status/index.css` | `60` | `--bali-z-popover` |
| BlockNote emoji picker, Mantine popover/menu | `block_editor/index.css` | `9999 !important` | `--bali-z-popover !important` |
| `AppLayout` toast container | `app_layout/component.html.erb` | `z-[101]` | `--bali-z-toast` (700) |
| `Notification` fixed positions | `notification/component.rb` | `z-[101]` | `--bali-z-toast` |
| BlockEditor upload toast (built in JS) | `useFileUpload.js` | `z-50` | `.block-editor-upload-toast` → `--bali-z-toast` |
| BlockNote / Mantine tooltips | `block_editor/index.css` | `9999 !important` | `--bali-z-tooltip !important` (800) |
| `HoverCard` balloon | `hover_card/*` | `9999` (Ruby constant) | `--bali-z-tooltip`, read at connect |
| `Tooltip` balloon | `tooltip/index.js` | tippy's own `9999` | `--bali-z-tooltip`, read at connect |

### What you have to change

**Any host rule whose number was chosen against one of Bali's.** The classic shapes:

```css
/* v2: "above the modal at 61" — now under every Bali overlay */
.my-overlay { z-index: 70; }

/* v3: say which tier you mean */
.my-overlay { z-index: calc(var(--bali-z-modal) + 1); }
```

```erb
<%# v2: identity's toast above a modal %>
<div class="!z-[10001]">

<%# v3: toasts are already above modals — the override is dead weight %>
<div>
```

**A `z-*` utility still wins**, in both versions, because the tokens are read from
`@layer utilities` classes and a host utility on the same element ties and sorts after.
Nothing about escaping the scale got harder.

### Moving the scale, or slotting into it

The tokens are declared `:where(:root)` inside `@layer theme`, which is the weakest place
they can live. Three ways to override, all of which work:

```css
/* Tailwind v4 idiom — same layer, higher specificity, wins */
@theme {
  --bali-z-modal: 1400;
}

/* Unlayered — beats every layer */
:root {
  --bali-z-toast: 1700;
}
```

The gap between tiers is 100, so your own overlays go *between* Bali's without touching
them:

```css
:root {
  --app-z-help-bubble: 650; /* above popovers, below toasts */
}
```

Note this is **not** how the daisyUI structural fallbacks in `general.css` behave: those
sit in a later layer and a host cannot override them from `@theme {}` at all.

### Behaviour that did not change

- **App chrome keeps its numbers** — `Navbar` sticky (50), `SideMenu` rail (40) and mobile
  scrim (30), floating bulk-action bars (40/50). The scale starts at 200 precisely so that
  every overlay covers them; do not raise chrome into the scale.
- **A dropdown inside a stacking context is still trapped in it.** A menu rendered inside
  `Navbar`'s sticky bar competes only with that bar's other children, whatever its
  z-index — that is how `position` + `z-index` works, and 200 does not change it.
- **`HoverCard(z_index:)` still wins** when you pass it. Only the default moved.

## Every public event is now `bali:`-prefixed

v2 shipped three generations of event naming at once: a few already-prefixed `bali:*` names,
a handful with no prefix at all (`openModal`, `openDrawer`, `modal:success`), and the rest
riding Stimulus' default `<identifier>:<name>`. On top of that, a `useDispatch` mixin
replaced Stimulus' own `dispatch` with an incompatible `(name, detail)` signature, so a
controller that followed the Stimulus documentation and passed `{ detail, target, prefix }`
got an event whose `detail` was that entire options object.

The mixin is gone and every event now goes through Stimulus' native `dispatch` under one
scheme: **`bali:<component>:<event>`, kebab-case**. An event without the `bali:` prefix no
longer comes from this package.

**This breaks silently.** Nothing throws when an event is renamed — the listener simply stops
running, and the feature quietly stops working. Grep before you upgrade:

```
grep -rn "openModal\|openDrawer\|modal:success" app/ --include=*.js --include=*.erb --include=*.rb
grep -rn "hovercard:\|sortable-list:\|interact:on\|direct-upload:\|gantt-foldable-item:" app/
grep -rn "useDispatch\|use-dispatch\|baliDispatchDebugEnabled" app/ config/
```

### The complete table

| v2 | v3 | Emitted by | Dispatched on |
|---|---|---|---|
| `openModal` | `bali:modal:open` | `ModalController#open` | `document` |
| `openDrawer` | `bali:drawer:open` | `DrawerController#open` | `document` |
| `modal:success` | `bali:modal:success` | `ModalController#submit` (drawers inherit it) | `document` |
| `interact:onResizing` | `bali:interact:resizing` | `InteractController` | the element, bubbling |
| `interact:onResizeEnd` | `bali:interact:resize-end` | `InteractController` | the element, bubbling |
| `interact:onDragging` | `bali:interact:dragging` | `InteractController` | the element, bubbling |
| `interact:onDragEnd` | `bali:interact:drag-end` | `InteractController` | the element, bubbling |
| `sortable-list:onEnd` | `bali:sortable-list:end` | `SortableListController` | the list, bubbling |
| `hovercard:show` | `bali:hovercard:show` | `HovercardController` | the element, bubbling |
| `hovercard:hide` | `bali:hovercard:hide` | `HovercardController` | the element, bubbling |
| `gantt-foldable-item:toggle` | `bali:gantt-foldable-item:toggle` | `GanttFoldableItemController` | the row, bubbling |
| `direct-upload:complete` | `bali:direct-upload:complete` | `DirectUploadController` | the element, bubbling |
| `direct-upload:all-complete` | `bali:direct-upload:all-complete` | `DirectUploadController` | the element, bubbling |
| `direct-upload:error` | `bali:direct-upload:error` | `DirectUploadController` | the element, bubbling |

Already correct in v2 and **unchanged**, listed so the inventory is complete:
`bali:command:open` / `:close` / `:toggle` (listened for on `window`), `bali:command:select`
(emitted), and `bali:side-menu:toggle` / `:open` / `:close` (listened for on `window`;
`Navbar#toggleSideMenu` emits the first).

The `on` in `onEnd`, `onDragEnd` and friends is a handler-naming habit, not part of an event
name, so it is dropped rather than kebab-cased into `on-drag-end`. Every one of those pairs is
in the table above; nothing changed without a row.

### Two payload changes that come with it

**`event.detail.controller` is gone.** `useDispatch` pushed the emitting controller instance
into every payload. Native `dispatch` does not, and reaching into another controller's
instance from an event handler was never worth encouraging. If you needed the element,
`event.target` is it; if you genuinely need the controller,
`application.getControllerForElementAndIdentifier(event.target, 'sortable-list')`.

**`bali:modal:success` fires for drawers too.** That is not new — `modal:success` did the same,
because `DrawerController` inherits `submit` from `ModalController`. It is called out because
the new name makes the asymmetry look deliberate: there is no `bali:drawer:success`. One name
for "the form inside the overlay saved" is what a host wants to listen for, and the overlay's
own root tells the two apart when it matters.

### Opening a modal or drawer by hand still works

This was, and remains, the supported way to open one without a trigger link — only the name
changed:

```javascript
// v2
document.dispatchEvent(new CustomEvent('openModal', {
  detail: { content: html, options: { modalSize: 'lg' } }
}))

// v3
document.dispatchEvent(new CustomEvent('bali:modal:open', {
  detail: { content: html, options: { modalSize: 'lg' } }
}))
```

`detail.options` is still required (pass `{}` if you have nothing to set) and `detail.content`
still accepts `null` to keep the skeleton showing.

### No compatibility aliases, on purpose

v3 does not emit the old names alongside the new ones. Two reasons. The events split into ones
Bali *emits* and ones Bali *listens for*, and those need opposite shims — dual-emit for the
first, dual-listen for the second — so "emit both" would have covered barely half the surface
while reading as full coverage. And a dual-listen on `openModal` would keep a host working
without ever telling it to migrate, which only moves this same break to v4. The grep recipe
above finds every call site in one pass; that is the intended migration path.

### `useDispatch` is removed

`import { useDispatch } from 'bali-view-components/utils'` and the `bali/utils/use-dispatch`
importmap pin no longer resolve. If you built your own controller on it, the replacement is
the native `dispatch` the mixin was shadowing all along:

```javascript
// v2 — mixin signature
useDispatch(this)
this.dispatch('saved', { id: this.idValue })

// v3 — native
this.dispatch('saved', { prefix: 'myapp:widget', detail: { id: this.idValue } })
```

`window.baliDispatchDebugEnabled` went with it. The replacement traces every Bali event at
once and needs no cooperation from the controllers:

```javascript
const dispatchEvent = EventTarget.prototype.dispatchEvent
EventTarget.prototype.dispatchEvent = function (event) {
  if (event.type.startsWith('bali:')) console.log(event.type, event.detail)
  return dispatchEvent.call(this, event)
}
```

## What breaks, and what replaces it

| Removed | Replacement |
|---|---|
| `with_actions_panel` | `with_bulk_actions` |
| `with_actions_panel(export_formats:)` | `page.with_export(url:)` on the page component |
| `dt.with_export` | `page.with_export(url:)` on the page component |
| `Bali::DataTable::Export(method:)` | *(deleted — it only emitted a dead `data-method`)* |
| `with_actions_panel(grid_display_mode_enabled:)` | `with_view_switch` |
| `Bali::DataTable::ActionsPanel::Component` | *(deleted)* |
| `Bali::DataTable::Action::Component` | *(deleted)* |
| URL param `data_display_mode` | URL param `view` (configurable with `view_param:`) |
| `with_column_selector(table_id:)` | resolved from `filter_form.storage_id` |
| `with_saved_views(table_id:)` | resolved from `filter_form.storage_id` |
| `Bali::Table(id:)` as the column-selector target | the DataTable container id |
| `render Bali::Card` around the DataTable in the host | the content slot's surface |
| `toolbar_class:` | *(deleted — the toolbar is bare by design)* |

## Step by step

### 1. Delete the `Bali::Card` around the DataTable

The surface now travels with the content slot: `with_table` brings a card plus
`overflow-x-auto`, `with_grid` brings none (the cards *are* the surface), and
`with_content(surface: false)` is the escape hatch for content with its own chrome.

```erb
<%# v2 %>
<%= render Bali::Card::Component.new do %>
  <%= render Bali::DataTable::Component.new(...) do |dt| %>
    <% dt.with_table do %>...<% end %>
  <% end %>
<% end %>

<%# v3 %>
<%= render Bali::DataTable::Component.new(...) do |dt| %>
  <% dt.with_table do %>...<% end %>
<% end %>
```

Leaving the wrapper in place is not a crash — it is a card inside a card, and in grid mode
a card full of cards.

### 2. Drop `table_id:` and the `Bali::Table(id:)` that fed it

```
ArgumentError: unknown keyword: :table_id
```

A listing now has ONE name, and it is the `storage_id` its `FilterForm` already had.
`DataTable` resolves the identity itself: explicit `id:`, else `filter_form.storage_id`,
else a random hex — and in that last case **column persistence turns itself off**, because
a key that changes on every render can never restore anything.

```erb
<%# v2 %>
<% dt.with_column_selector(table_id: '#movies-table') do |cs| %>...<% end %>
<% dt.with_saved_views(url: ..., table_id: '#movies-table') %>
<%= render Bali::Table::Component.new(form: @filter_form, id: 'movies-table') do |t| %>

<%# v3 %>
<% dt.with_column_selector do |cs| %>...<% end %>
<% dt.with_saved_views %>
<%= render Bali::Table::Component.new(form: @filter_form) do |t| %>
```

If a listing has no `storage_id`, add one to the `FilterForm` before adding a column
selector or saved views to it.

### 3. Fix any `turbo_stream.replace` that hardcoded the old container id

**This is the break that leaves no trace.** The container id changed from
`data-table-<scope cache_key>` to the resolved identity. Turbo resolves a stream target with
`getElementById`: with no node it replaces nothing, raises nothing and logs nothing.

The identity is the `storage_id` **sanitized into a valid CSS identifier**, so do not target
the raw value — a `storage_id` containing `/`, `:`, `.` or a space, or one starting with a
digit, renders a different id (`'admin/movies'` → `admin-movies`, `'2026_reports'` →
`listing-2026_reports`). `Bali::DataTable::ListingIdentity.for` applies exactly the rule the
component applies:

```erb
<%# v2 %>
<%= turbo_stream.replace "data-table-#{@filter_form.id}" do %>

<%# v3 %>
<%= turbo_stream.replace Bali::DataTable::ListingIdentity.for(@filter_form) do %>
```

While you are there: render the DataTable from a **shared partial** used by both
`index.html.erb` and `index.turbo_stream.erb`. The stream replaces the node that carries
the selection controller, so the two branches must produce the same DOM.

### 4. Replace the actions panel with bulk actions

```
NoMethodError: undefined method 'with_actions_panel'
```

```erb
<%# v3 %>
<% dt.with_bulk_actions do |bulk| %>
  <% bulk.with_action(label: 'Mark as done',
                      href: bulk_actions_movies_path(bulk_action: 'mark_done'),
                      variant: :success) %>
<% end %>

<% dt.with_table do %>
  <%= render Bali::Table::Component.new(form: @filter_form, selectable: true) do |t| %>
    <% @movies.each do |movie| %>
      <% t.with_row(record_id: movie.id) do %>...<% end %>
    <% end %>
  <% end %>
<% end %>
```

Three things to check on the server side:

- **The payload is `selected_ids`**, a JSON array in a hidden field the Stimulus controller
  fills. A controller reading `params[:movie_ids]` (or any `name="x[]"` checkboxes you wrote
  by hand) stops receiving anything. Each action is its own form whose only hidden field is
  `selected_ids`, so extra parameters (which action) travel in the action's **query string**.
- **Delete your hand-written checkbox column.** `selectable: true` renders the column and
  the select-all header. If you delete the `<th>` without turning `selectable:` on, every
  column selector index shifts by one and the selector starts hiding the wrong column.
- `selectable:` and the legacy `Bali::Table(bulk_actions:)` array are mutually exclusive;
  declaring both raises `Bali::Table::Component::IncompatibleOptions`.

### 5. Replace the display-mode toggle with the view switch

```
ArgumentError: unknown keyword: :grid_display_mode_enabled
```

```erb
<%= render Bali::DataTable::Component.new(..., display_mode: params[:view]) do |dt| %>
  <% dt.with_view_switch do |switch| %>
    <% switch.with_view(name: 'Table', icon: 'list', value: :table) %>
    <% switch.with_view(name: 'Cards', icon: 'grid', value: :grid) %>
  <% end %>

  <% if dt.display_mode == :grid %>
    <% dt.with_grid do %>...<% end %>
  <% else %>
    <% dt.with_table do %>...<% end %>
  <% end %>
<% end %>
```

- The URL param is now **`view`**, not `data_display_mode`. A controller reading
  `params[:data_display_mode]` gets `nil`; old bookmarks fall back to the first declared
  view (a clean degradation — in v2 they rendered an empty listing). Use `view_param:` to
  keep another name.
- Read **`dt.display_mode`**, not the value you passed in: it is gated against the declared
  views. Declare the switch before reading it.
- Declaring two content slots now raises
  `Bali::DataTable::Component::DuplicateContent`. In v2 the second one silently won.
- Each view declares `value:`, and the DataTable builds the href, preserving the query
  string (`page` is dropped, `saved_view` is kept). `href:` is still accepted for a mode
  that lives on another route.

This also closes **#653**: the legacy toggle built its links with
`Utils::Url#add_query_params`, which duplicated a param already in the URL. That code is no
longer on this path.

## Behaviour changes with no API change

- **`toolbar_class:` is ignored, not rejected.** `DataTable#initialize` swallows unknown
  keywords in `**options`, so a leftover `toolbar_class:` raises nothing and simply loses
  its styling — unlike every other removal in the table above, which raises `ArgumentError`.
  Same for `display_mode:`'s old sibling `data_display_mode:` as a keyword. (It never
  shipped in a released 2.x — only apps tracking `main` need to grep for it.)
- **`DataTable#with_content` shadows `ViewComponent::Base#with_content`.** The content band
  is declared with keywords (`with_content(surface:, scroll:)`), so the base one-positional
  form raises `ArgumentError: wrong number of arguments`. It was a silent no-op on
  `DataTable` before, so nothing that worked stops working — but the error is new.
- **Stored column preferences reset once.** The localStorage key moved from
  `bali:columns:<table_id>` to `bali:columns:<storage_id>`. The old keys are orphaned; no
  one cleans them up. If two listings shared a `table_id` (a very common copy-paste, e.g.
  `/movies` and `/admin/movies` both using `#movies-table`), they now have independent
  memories — which is the bug being fixed, at the cost of one reset per listing.
- **The toolbar is bare and single-row**, identical in every display mode, and its secondary
  controls **move** into a `⋯` menu whenever the row does not fit — measured, not guessed
  from the viewport, because a sidebar can leave a 1400px window with a 700px toolbar. They
  are never duplicated (the old `hidden md:block` + mobile copy pattern is gone). The order
  **inside a group** is defined by `OVERFLOW_PRIORITIES`, not by your template. Anything you
  put in `with_toolbar_button` needs an idempotent `connect()`, no `data-turbo-permanent`,
  and the `toolbar-control-label` class on a label that hides on mobile.
- **`view` is now a reserved param for every `FilterForm` that declares grouping.** The form
  reads `params[:view]` (rename it with `view_param:`) and applies the grouping only in
  `group_by_modes` — default `[:table]`. This has nothing to do with having a `DataTable`:
  a plain `Filters` + `Table` listing that groups and already uses `?view=` for its own
  purpose (a density switch, a print mode, a tab) silently **stops grouping** after the
  upgrade — the page still returns 200, only the bands and their counts are gone. Pass
  `view_param:` on both sides, or widen `group_by_modes:`.
- **A listing whose default view is not the table must tell the form.** The `DataTable`
  resolves an absent `?view=` to the *first declared view*; the form, seeing no param,
  assumes the grouping applies. Declare the table first, or pass the same value to both
  (`Bali::FilterForm.new(..., display_mode: params[:view] || :grid)`). While they disagree
  the `DataTable` raises `ArgumentError` on render rather than sorting cards by a group
  nobody can see.
- **"No grouping" now leaves `?group_by=` in the URL** instead of dropping the param. With
  filter persistence on, an absent param means "restore whatever was cached", so removing
  it brought the grouping straight back.
- **The active view travels as a hidden field on filter submits**, like `group_by` already
  did, so filtering from the cards view no longer drops you back into the table.
- `Bali::ViewSwitch#icon_only?` is now `== true` rather than truthy: a host passing a
  non-boolean truthy value (`"true"`, `1`) changes behaviour. `:responsive` is a new value
  that collapses only the label below `sm`.
- **Bulk selection order.** `selected_ids` is derived from the DOM, so it comes in row
  order rather than click order. Non-numeric record ids (UUIDs) still serialize as `null` —
  a pre-existing limitation of the controller, now reachable by many more apps.
- **The filter-persistence bookmark left the Filters panel.** Inside a `DataTable` it is a
  toolbar control of its own (`Bali::Filters::PersistenceToggle::Component`, `memory`
  group) and the panel receives `persistence_toggle: false`, so nothing renders it twice.
  Standalone `Filters` / `SimpleFilters` are unchanged and still render it (default
  `persistence_toggle: true`). No API changed, but a system test scoping the bookmark
  inside the panel (`within('.filters') { … }`) or CSS doing the same stops matching.
- **Host `toolbar_buttons` moved to their own overflow group** (`host`) between the memory
  group and the right edge, so the view switch stays pinned to the edge. A listing that
  declares toolbar buttons and *no* view switch no longer pushes them to the far right.

## Checklist

```
grep -rn "with_actions_panel\|with_export\|table_id:\|data_display_mode\|toolbar_class:" app/
grep -rn "turbo_stream.replace \"data-table-" app/
grep -rn "Bali::Card.*DataTable\|render Bali::Card" app/views/**/index*
# any listing that groups and already used `view`, or that does not start on the table?
grep -rn "group_by_attribute" app/
grep -rn "view=\|params\[:view\]" app/views app/controllers
# events — these break with no error at all, see the table above
grep -rn "openModal\|openDrawer\|modal:success" app/
grep -rn "hovercard:\|sortable-list:\|interact:on\|direct-upload:\|gantt-foldable-item:" app/
grep -rn "useDispatch\|use-dispatch\|baliDispatchDebugEnabled" app/ config/
```

Then load each index page in a browser and check, in this order: the toolbar is not inside
a card, filtering over Turbo Streams still replaces the listing, selecting a row swaps the
toolbar for the contextual bar, and the column selector still hides the column you named.
