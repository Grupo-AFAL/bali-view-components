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
| `Bali::Icon::DefaultIcons` | nothing — see [The icon fallback is gone](#the-icon-fallback-is-gone) |

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

## The icon fallback is gone

`Bali::Icon::DefaultIcons` was 1,580 lines holding 166 inline SVGs, wired in as the fifth and
last step of the resolution pipeline under the heading "full backwards compatibility". It is
deleted. `Bali::Icon::Component` now resolves a name through three steps and raises if none of
them matches:

1. the Bali → Lucide name map (`LucideMapping`),
2. a Lucide name used directly,
3. the kept set (`KeptIcons` — brands, flags, domain-specific), then `Bali.custom_icons`.

**Almost nothing was still reaching that fifth step.** Of the 167 names it could serve, 137
were already intercepted by the Lucide map and 28 by the kept set, both of which sit *earlier*
in the pipeline — so for 165 of them the fallback had been unreachable code since the Lucide
migration, and deleting it changes nothing you can see. Two names were still being served by
it, and only those two lose their glyph:

| Name that stops resolving | What it drew | Use instead |
|---|---|---|
| `money-bill-wave` | a filled FontAwesome banknote | `banknote`, or `hand-coins` if the point was payment rather than cash |
| `question-circle` | a filled question mark in a circle | `circle-help` |

`question-circle` is the one worth grepping for: the Lucide map *does* carry an entry for this
icon, but under the key `question_circle` — the single underscored key in the whole table, a
leftover from the v1 hash. So `question_circle` keeps working and `question-circle`, the
spelling that matches every other name in the library, does not. Rename it to `circle-help`
rather than to the underscored form; the underscore is the accident here, not the fix.

### Every alternative spelling of a name stops resolving too

This is the larger surface, and it is invisible in a grep for the two names above. The deleted
step did not look a name up as written — it upcased it and turned dashes into underscores to
build a constant name, so `arrow_left`, `ARROW-LEFT` and `Arrow_Left` all resolved to the same
SVG as `arrow-left`. The three surviving steps match **exactly**: lowercase, dashes, as
written.

In practice that means the snake_case spelling of every multi-word icon now raises. All 73 of
them, and for 72 the fix is the same — write the dashed name:

```
address_book            alert_alt               align_center            align_left
align_right             american_express        angle_double_down       angle_double_up
arrow_back              arrow_forward           arrow_left              arrow_right
arrow_right_up          badge_percent           band_aid                box_archive
calendar_alt            chart_line              check_circle            chevron_doble_down
chevron_doble_up        chevron_down            chevron_left            chevron_right
cloud_upload_alt        comment_dollar          credit_card             credit_card_alt
cutlery_alt             door_open               edit_alt                ellipsis_h
exclamation_circle      external_link_alt       face_profile            facebook_square
file_certificate        file_export             file_signature          filter_alt
fire_alt                grin_wink               info_circle             info_circle_alt
instagram_square        laptop_code             link_alt                long_arrow_alt_left
magic_wand              map_marked_alt          map_marker_alt          mexico_flag
money_bill_wave         nested_arrow            phone_plus              plus_circle
project_diagram         recipe_book             search_minus            search_plus
shopping_cart           space_station_moon_alt  square_phone            sticky_note
times_circle            trash_alt               trophy_alt              truck_loading
us_flag                 user_plus               utensils_alt            wallet_alt
whatsapp_square
```

`money_bill_wave` is the one entry in that list with no dashed equivalent to fall back on — it
is the same casualty as the row above. The single-word names (`check`, `user`, `trash`…) are
unaffected: they spell the same either way.

The error message closes the loop. `IconNotAvailable` already suggested near names, but it
compared them literally, so `arrow_left` matched nothing and the message degraded to a link to
lucide.dev. Suggestions now ignore the dash/underscore difference:

```
Icon 'arrow_left' is not available. Did you mean: arrow-left?
Icon 'whatsapp_square' is not available. Did you mean: whatsapp, whatsapp-square?
Icon 'money-bill-wave' is not available. Check available icons at: https://lucide.dev/icons
```

`money-bill-wave` is the one that still gets no suggestion, and correctly so — no surviving
name resembles it. Take the alternative from the table above.

### `Bali::Icon::Options` only lists what ships as SVG

`Options.icons` used to be the 166 legacy SVGs merged with `Bali.custom_icons`. It is now the
28 kept icons merged with `Bali.custom_icons` — the icons Bali ships as literal markup. A
Lucide-backed name such as `user` has no SVG of its own until lucide-rails renders one at a
size, so `Options.find('user')` raises `IconNotAvailable` where it used to return the old
FontAwesome glyph. `Options` was never the rendering path; call
`render Bali::Icon::Component.new('user')`, which resolves every source.

The 28 kept SVGs moved out of Ruby into `app/components/bali/icon/svg/<name>.svg`, one file
per name, byte-for-byte the same markup. Nothing about how you reference them changes.

## The CSS cascade changes — on purpose

In v2 every stylesheet Bali shipped was **unlayered**, which in Tailwind v4 outranks every
layer. A utility class in your own template lost to a component rule, and the documented
workaround was `lg:!hidden`. v3 puts Bali's own styles in `@layer components`, so **your
utilities win**. If your app carries `!` variants that exist only to beat a Bali rule, you
can drop the `!`.

The exceptions are deliberate and documented in each file's header: `forms.css`,
`datepicker.css`, `slim_select.css`, `breadcrumb/index.css`, `data_table/index.css` and
`side_menu/daisyui-overrides.css` stay unlayered, because their job is to outrank **daisyUI**,
which emits its own components inside `@layer utilities` — a layer beats specificity, so a
rule in `components` cannot win against them at any specificity.

Two consequences worth checking in your app:

- **A CSS override you wrote against a Bali rule may now win where it used to lose, or lose
  where it used to win.** If you were fighting a Bali rule with `!important` or a very
  specific selector, try removing the escalation first — a plain utility probably does it now.
- **`--border`, `--radius-box`, `--radius-field`, `--radius-selector`, `--size-field`,
  `--size-selector`, `--depth` and `--noise` stop overriding your theme.** They were unlayered
  `:root` declarations, which beat daisyUI's `@layer base`, so Bali's values won against every
  theme. `light` and `dark` use exactly those values, which is why nobody noticed; the other 33
  built-in themes do not. **If your app uses a daisyUI theme other than light or dark, its radii,
  borders and depth will change — to what your theme actually asked for.**

  They now sit on `:where(:root)` inside `@layer base`, which is where daisyUI declares its own
  themes. **Setting them from `@theme {}` will not work**, and that is worth knowing because
  `@theme {}` is the idiomatic way to declare tokens in Tailwind v4: it compiles to
  `@layer theme`, and Tailwind orders layers `theme < base < components < utilities` (unlayered
  CSS last). A later layer wins outright, so `theme` loses to `base` however specific its
  selector is — zero specificity on Bali's side does not help you, because specificity only
  settles ties *within* a layer. Measured against `--radius-box`, whose fallback is `.5rem`:

  | Your app writes | Result |
  |---|---|
  | `@theme { --radius-box: 11px }` | `.5rem` — **ignored** |
  | `@layer base { :root { --radius-box: 77px } }` | `77px` |
  | `@layer base { [data-theme=mine] { … } }` | applies |
  | `:root { --radius-box: 55px }` (no layer) | `55px` |

  daisyUI behaves identically — its built-in themes are in `base` and shadow an `@theme` block
  the same way — so if you already set these through a daisyUI theme, nothing changes for you.
  Otherwise use a `@layer base` block or a plain unlayered `:root`.

Import stays one line:

```css
@import "bali-view-components/css/bali.css";   /* now pulls in components.css too */
```

If you import `bali-view-components/css/components.css` separately, you can drop that line —
keeping it duplicates bytes but changes nothing, since the layer assignments travel inside the
file. `css/variables.css` was empty and is gone; nothing imported it.

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

### Timeline renders each entry once, and its slots lose the `tag_` prefix

A timeline item used to emit its heading and its content twice — once in `.timeline-start`,
once in `.timeline-end` — and hide one copy with CSS. Which side an item lands on is now
decided in Ruby, so each item renders one content box.

The slot setters were named after an internal collection called `tags`, which was never a
timeline concept. Rename them:

| v2 | v3 | Notes |
|---|---|---|
| `c.with_tag_item(...)` | `c.with_item(...)` | Deprecated shim warns through `Bali.deprecator`; removed in v4 |
| `c.with_tag_header(...)` | `c.with_header(...)` | Same |
| `c.tags` | `c.entries` | The collection accessor. No shim — reading it in a host template is rare |
| `with_tag_header(tag_class: 'badge-outline badge-primary')` | `with_header(color: :primary, class: 'badge-outline')` | Deprecated shim warns; removed in v4 |

```erb
<%# v2 %>
<%= render Bali::Timeline::Component.new(position: :left) do |c| %>
  <% c.with_tag_header(text: 'Start') %>
  <% c.with_tag_item(heading: 'January 2022') do %>
    <p>Timeline event 1</p>
  <% end %>
<% end %>

<%# v3 %>
<%= render Bali::Timeline::Component.new(position: :left) do |c| %>
  <% c.with_header(text: 'Start') %>
  <% c.with_item(heading: 'January 2022') do %>
    <p>Timeline event 1</p>
  <% end %>
<% end %>
```

Three things change even if you rename nothing, because the old markup was the bug:

- **Anything with an `id` inside an item now exists once.** A `turbo_frame_tag` in a timeline
  item used to render twice under the same id: Turbo matched the second, which was the copy
  CSS had hidden, so a stream update reached a `display: none` element and the visible one
  never changed. If you worked around this — a suffix on the id, a wrapper that rendered in
  only one column — you can drop the workaround.
- **Nested components run once.** An item whose block rendered a component that queried the
  database issued that query twice per item.
- **`position: :center` alternates by item.** The old alternation was `li:nth-child(odd)`, and
  a header is an `li`, so a header between two items flipped the parity and left two
  consecutive items on the same side. Centred timelines *with headers* will move some boxes
  to the other side. Ones without headers are unchanged.

CSS that targeted the hidden copy stops matching. `app/components/bali/timeline/index.css`
now carries only the two `text-align` rules the alternating layout needs; if your app styled
`.timeline-content-box.timeline-end` on a left-aligned timeline, it was styling the copy the
user could not see.

Finally, `Bali::Timeline::Header::Component` now applies `**options` to its badge. It accepted
them and rendered none of them, so a `class:`, `data:` or `aria-*` you passed and gave up on
will start taking effect.

## The five page components get one surface

`DashboardPage`, `DocumentPage`, `FormPage`, `IndexPage` and `ShowPage` now take the same
options and the same slots, all defined in `Bali::PageComponents::Shared`. Most of the move
is additive — a page component that did not accept `back:`, `nav`, `title_tags`, `sidebar`
or `max_width:` accepts them now — so the only edits a host owes are these three.

### 1. Rename `with_preview` to `with_body` on `DocumentPage`

```erb
<%# v2 %>
<% page.with_preview do %><%= @document.body %><% end %>

<%# v3 %>
<% page.with_body do %><%= @document.body %><% end %>
```

`with_preview` still renders and warns through `Bali.deprecator` until 4.0, so nothing goes
blank if you miss one. `grep -rn "with_preview" app/` finds them all.

### 2. Expect DashboardPage's stat cards to look like `StatCard`, because they are one

`with_stat` keeps its signature (`label:`, `value:`, `icon:`, `change:`, `color:`) and now
renders `Bali::StatCard::Component`: the label becomes uppercase `text-xs`, the value
`text-3xl`, the icon sits in a tinted circle, and `change:` lands in the card's footer. If
you were relying on the old inline markup — a `text-sm` label and a `text-2xl` value — this
is the change to look at. There is no flag for the old one: shipping two stat cards is the
problem this closes.

### 3. Two spacing/size values move to the shared default

- `IndexPage`'s body gap goes from `mt-4` to `mt-6`, the value the other four use.
- `ShowPage` and `DocumentPage`'s subtitle goes from `text-base` to `text-sm`, the value
  `PageHeader::SUBTITLE_CLASSES` declares and the other three already rendered.

Neither is configurable. If a page depended on the old value, set it on your own content.

### `max_width:` now means the same thing everywhere

| key | class | accepted it in v2 |
|---|---|---|
| `:sm` | `max-w-xl` | FormPage |
| `:md` | `max-w-3xl` | FormPage |
| `:lg` | `max-w-5xl` | DashboardPage, FormPage |
| `:xl` | `max-w-7xl` | DashboardPage, FormPage |
| `:"2xl"` | `max-w-screen-2xl` | DashboardPage |
| `:full` | `max-w-full` | DashboardPage, FormPage |

Defaults are unchanged where they existed (`:"2xl"` for DashboardPage, `:md` for FormPage)
and are `:full` for the three that had no container — `:full` renders `mx-auto max-w-full`,
which moves no layout. Passing a key the table does not have raises `ArgumentError`; in v2
three of the five raised `ArgumentError` for *any* key, because they had no `max_width:`.

`sidebar_width:` is new and shared: `:default` gives the sidebar a third of the grid,
`:narrow` a quarter, `:wide` a half. Below `lg` it always stacks under the body.

### `Level` and `InfoLevel` are deprecated

Both keep working and warn until 4.0. `Level` → flex utilities
(`flex justify-between items-center gap-4`), or `Bali::PageHeader::Component` for a page
header. `InfoLevel` → a grid of `Bali::StatCard::Component`.

## What breaks, and what replaces it

| Removed | Replacement |
|---|---|
| `c.with_tag_item` / `c.with_tag_header` on `Bali::Timeline` | `c.with_item` / `c.with_header` *(deprecated shim until v4)* |
| `Bali::Timeline::Header(tag_class:)` | `color:` plus `class:` *(deprecated shim until v4)* |
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
| `Bali::Table(bulk_actions:)` | `selectable: true` inside a `Bali::BulkActions::Component` |
| `Bali::Table::BulkAction::Component` | `Bali::BulkActions::Action` (`bulk.with_action`) |
| `TableController` / `data-controller="table"` | `BulkActionsController` (`bulk-actions`) |

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
- **`Bali::Table(bulk_actions:)` is gone**, along with `Bali::Table::BulkAction::Component`
  and the `table` Stimulus controller that drove them. See the next section.

### 4b. Replace the legacy `Bali::Table(bulk_actions:)` array

```
ArgumentError: Bali::Table(bulk_actions:) was removed in v3.
```

v2 shipped two complete, mutually exclusive selection systems on the same table. The legacy
one took an array of action hashes, rendered its own checkbox column and its own floating
bar, and was driven by a `table` Stimulus controller that Bali put on **every** table
container whether or not the table had any actions. The v3 one is `selectable: true` plus a
`Bali::BulkActions::Component` ancestor. Only the second one survives.

Inside a DataTable the replacement is `with_bulk_actions`, shown in step 4 above. Standalone
— a table with no DataTable around it, which is what the legacy array was mostly used for —
wrap the table in a `BulkActions` component and let its default `variant: :floating` render
the bar:

```erb
<%# v2 %>
<%= render Bali::Table::Component.new(
      bulk_actions: [
        { name: 'Archive', href: '/products/bulk_archive', method: :post },
        { name: 'Delete',  href: '/products/bulk_delete',  method: :delete }
      ]
    ) do |t| %>
  <% @products.each do |product| %>
    <% t.with_row(record_id: product.id) do %>...<% end %>
  <% end %>
<% end %>

<%# v3 %>
<%= render Bali::BulkActions::Component.new do |bulk| %>
  <% bulk.with_action(label: 'Archive', href: '/products/bulk_archive', variant: :info) %>
  <% bulk.with_action(label: 'Delete',  href: '/products/bulk_delete',  variant: :error) %>

  <%= render Bali::Table::Component.new(selectable: true) do |t| %>
    <% @products.each do |product| %>
      <% t.with_row(record_id: product.id) do %>...<% end %>
    <% end %>
  <% end %>
<% end %>
```

What changes beyond the call site:

- **`name:` becomes `label:`**, and each action gains `variant:` (a daisyUI button colour)
  and `size:`. `method:` survives unchanged, including the `:get` case: a GET action still
  renders a link whose href the controller rewrites with `?selected_ids=[...]`, everything
  else still submits a form with a `selected_ids` hidden field.
- **The payload key is unchanged** (`selected_ids`, a JSON array), so a controller already
  reading it keeps working.
- **`data-controller="table"` disappears from every table container.** Bali emitted it
  unconditionally; nothing in v3 does. A host that hung its *own* Stimulus controller named
  `table` on Bali's markup, or that registered `TableController` from the npm package (it is
  no longer exported, and `registerAll` no longer registers it), has to move that wiring.
- **`Bali::Table::Row(bulk_actions:)` is gone too.** It was internal wiring, but it also
  raises now rather than leaking into the `<tr>` as an HTML attribute.

Both removed keywords raise `ArgumentError` naming the replacement rather than being
swallowed into `**options`. Without that guard `bulk_actions:` would have landed in the
generic HTML-attribute hash and rendered `<table bulk-actions="...">`: a table that looks
right, has no checkbox column, no bar, and no error.

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

## `Reveal` and `TreeView` change their markup

Both were rows of `<div>`s with click handlers — unreachable by keyboard, unannounced by a
screen reader — and `TreeView` additionally claimed `role="tree"`, a promise of roving
tabindex, arrow-key movement and type-ahead that it has never kept. The elements now match
what the components do. **Every class name is unchanged**, so styling keyed on
`.tree-view-component`, `.tree-view-item-component`, `.item`, `.children`, `.caret` or
`.reveal-trigger` still applies; anything naming the element or the role does not.

| v2 | v3.0 |
|---|---|
| `<div class="reveal-trigger" data-action="click->reveal#toggle">` | `<button type="button" class="reveal-trigger" aria-expanded aria-controls>` |
| `<div class="reveal-content">` | same, now with an `id` (derived from the component's `id:` when you pass one) |
| `<div class="tree-view-component" role="tree">` | `<ul class="tree-view-component">` |
| `<div class="tree-view-item-component" role="treeitem" aria-expanded>` | `<li class="tree-view-item-component">` — `aria-expanded` moves to the caret |
| `<div class="children" role="group">` | `<ul class="children" id>` |
| `<span class="caret" data-action="click->tree-view-item#toggle">` | `<button type="button" class="caret" aria-expanded aria-controls>`, **only on items that have children** |
| `<span class="caret opacity-0">` on childless items | `<span class="caret" aria-hidden="true">` — no `opacity-0`, no handler, not a tab stop |

What to grep for:

```
grep -rn 'role="tree\|role="treeitem\|role="group"' app/ test/ spec/
grep -rn 'div\.reveal-trigger\|span\.caret' app/ test/ spec/
```

Two of these bite in tests rather than in the browser: a system test clicking `span.caret`
needs `button.caret`, and one asserting `aria-expanded` on the `treeitem` wrapper has to read
it off the caret button instead.

`TreeView`'s `navigateTo` action and its `url` value are unchanged, and row clicks still
navigate.

`Reveal#show` and `Reveal#hide` did the opposite of their names (see the changelog). A host
that worked around the inversion by wiring `reveal#hide` to its "show" button has to swap the
two back.

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
- **The FormBuilder no longer emits its own options as HTML attributes.** `label`, `help`,
  `mode`, `control_class`, `control_data`, `pattern_type` and the rest of
  `HtmlUtils::RESERVED_OPTIONS` reached the element because Rails forwards any key it does
  not recognise; they are now extracted before delegating. The API does not change and the
  valid markup is identical — but **a selector that depended on those invalid attributes
  stops matching**: `input[mode="range"]`, `[control_class]`, `[help]`, `select[label]` and
  the like, in CSS or in integration tests. It is the only observable change in the HTML of
  a form that already worked.
- **Helpers no longer mutate the options hash they are given.** `field_options` used to
  write the base classes onto the caller's hash, so reusing it across two fields
  accumulated the first field's classes into the second; a host relying on that side effect
  (one shared `opts = { class: 'w-full' }`, expecting the second field to inherit
  `input input-bordered`) now gets the correct classes on both. A frozen hash no longer
  raises `FrozenError` either.
- **`submit_actions` respects `show_cancel_button?` again.** The check read
  `options[:modal]` after `submit` had deleted it from the hash, so it was always true.
  With `Bali.native_app` on and `modal:` present, the cancel button is now hidden the way
  the code always said it would be. Without `native_app` nothing changes.

## Checklist

```
grep -rn "with_actions_panel\|with_export\|table_id:\|data_display_mode\|toolbar_class:" app/
grep -rn "with_tag_item\|with_tag_header\|tag_class:" app/

grep -rn "with_preview" app/                          # DocumentPage's body slot
grep -rn "Bali::Level\|Bali::InfoLevel" app/          # deprecated, removed in 4.0
grep -rn "turbo_stream.replace \"data-table-" app/
grep -rn "Bali::Card.*DataTable\|render Bali::Card" app/views/**/index*
# any listing that groups and already used `view`, or that does not start on the table?
grep -rn "group_by_attribute" app/
grep -rn "view=\|params\[:view\]" app/views app/controllers
```

Then load each index page in a browser and check, in this order: the toolbar is not inside
a card, filtering over Turbo Streams still replaces the listing, selecting a row swaps the
toolbar for the contextual bar, and the column selector still hides the column you named.
