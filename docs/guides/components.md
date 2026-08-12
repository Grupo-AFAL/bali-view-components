# Component Usage Guide

This guide covers how to use Bali ViewComponents in your Rails views.

## Basic Rendering

All Bali components use Rails' ViewComponent library. Render them using the standard `render` helper:

```erb
<%= render Bali::Button::Component.new(name: 'Click Me') %>
```

## Component Naming Convention

Components follow this naming pattern:

```ruby
Bali::[Name]::Component
```

Examples:
- `Bali::Button::Component`
- `Bali::Card::Component`
- `Bali::Modal::Component`

---

## Common Parameters

Most components share these standard parameters:

| Parameter | Type | Description |
|-----------|------|-------------|
| `variant` | Symbol | Style variant (`:primary`, `:secondary`, etc.) |
| `size` | Symbol | Size modifier (`:xs`, `:sm`, `:md`, `:lg`, `:xl`) |
| `class` | String | Additional CSS classes |
| `data` | Hash | Data attributes for Stimulus |
| `**options` | Hash | Any additional HTML attributes |

---

## Colors

Every component that colours something takes the same two keywords, resolved by
`Bali::Color`:

| Keyword | Takes | Follows the DaisyUI theme? |
|---|---|---|
| `color:` | one of `:neutral :primary :secondary :accent :info :success :warning :error :ghost` | Yes |
| `custom_color:` | a hex string (`#rgb`, `#rrggbb`, and the alpha forms) | No — that is the point of it |

The seven components on this contract are `Tag`, `Status`, `Heatmap`, `Chart`,
`Timeline::Item` / `Timeline::Header`, `StatCard` and `Kanban::Column`. A value
outside the list raises `ArgumentError` at construction, naming the component and
the valid values; a removed Bulma name (`:danger`, `:link`, `:black`, `:dark`,
`:light`, `:white`) is told its replacement by name.

`:ghost` means "no colour of its own" — DaisyUI has no `--color-ghost`, so a
component either has a class for it (`badge-ghost`) or falls back to the theme's
own foreground.

Two components take names beyond this list on purpose: `Bali::Status` also
accepts its twelve fixed workflow colours (`:slate`, `:green`, …), which do *not*
follow the theme, because a workflow's "blue" is not the app's `primary`.

---

## Variants and Sizes

### Standard Variants

DaisyUI semantic colors available on most components:

| Variant | Use Case |
|---------|----------|
| `:primary` | Main actions, emphasis |
| `:secondary` | Secondary actions |
| `:accent` | Highlights, special elements |
| `:success` | Positive feedback, confirmations |
| `:warning` | Cautions, attention needed |
| `:error` | Errors, destructive actions |
| `:info` | Informational |
| `:neutral` | Subdued, neutral |
| `:ghost` | Minimal styling |

### Standard Sizes

| Size | Description |
|------|-------------|
| `:xs` | Extra small |
| `:sm` | Small |
| `:md` | Medium (usually default) |
| `:lg` | Large |
| `:xl` | Extra large |

---

## Components with Slots

Many components use ViewComponent slots for flexible content composition.

### Understanding Slots

Slots allow you to inject content into specific areas of a component:

```erb
<%= render Bali::Card::Component.new do |card| %>
  <% card.with_header(title: "Card Title") %>
  <% card.with_action do %>
    <%= render Bali::Button::Component.new(name: 'Save') %>
  <% end %>

  <%# Default content goes in the body %>
  <p>This is the card content.</p>
<% end %>
```

### Slot Types

| Syntax | Description |
|--------|-------------|
| `renders_one :name` | Single slot (0 or 1 instance) |
| `renders_many :name` | Multiple slots (0 or more instances) |

### Common Slot Patterns

**Single content slot:**
```erb
<%= render Bali::Card::Component.new do |c| %>
  <% c.with_title("My Title") %>
  Card body content here
<% end %>
```

**Multiple slots:**
```erb
<%= render Bali::Tabs::Component.new do |tabs| %>
  <% tabs.with_tab(title: "Tab 1", active: true) { "Content 1" } %>
  <% tabs.with_tab(title: "Tab 2") { "Content 2" } %>
  <% tabs.with_tab(title: "Tab 3") { "Content 3" } %>
<% end %>
```

**Slots with parameters:**
```erb
<%= render Bali::Card::Component.new do |c| %>
  <% c.with_image(src: "/image.jpg", alt: "Description") %>
  <% c.with_action do %>
    <%= render Bali::Button::Component.new(name: 'Action', variant: :primary) %>
  <% end %>
<% end %>
```

---

## Component Categories

### Layout Components

#### AppLayout

Top-level page shell. Renders `<body>` directly with optional banner, navbar,
sidebar, topbar, and main body slots. Designed for admin shells but the
slots are independent so non-shell layouts work too.

```erb
<%= render Bali::AppLayout::Component.new(fixed_sidebar: true) do |layout| %>
  <% layout.with_sidebar do %>
    <%= render 'layouts/admin_sidebar' %>  <%# typically a Bali::SideMenu %>
  <% end %>
  <% layout.with_topbar do %>
    <%= render 'layouts/admin_topbar' %>   <%# typically a Bali::Topbar %>
  <% end %>
  <% layout.with_body do %>
    <%= yield %>
  <% end %>
<% end %>
```

**Options:**
- `fixed_sidebar` - Sidebar uses `position: fixed`; content gets left padding (default: true). Must match the `fixed:` of the `SideMenu` in the slot — they share the same default, and a mismatch raises in development
- `viewport_locked` - Body locks to 100vh; only inner `<main>` scrolls (Linear/Notion app-shell pattern). Defaults to whether a fixed sidebar is actually rendered — pass explicitly to decouple
- `skip_link` - Render the "skip to main content" link as the first focusable element (default: true)
- `body_container` - `:wide` (default), `:contained`, `:narrow`, `:full`
- `flash` - Pass `flash` for built-in toast notifications
- `modal` / `drawer` - Render shared modal/drawer slots (default: true)
- `mobile_bottom_padding` - Room under the content on a phone, for the browser's floating bar plus the device safe area (default: false) — see below

The layout renders `<main id="main-content" tabindex="-1">` so the skip link lands focus on it.

**Decoupled scroll model**:
| `fixed_sidebar` | `viewport_locked` | Behavior |
|-----------------|-------------------|----------|
| `true` | `true` (default) | Full app shell — sidebar + topbar pinned, only body scrolls |
| `true` | `false` | Fixed sidebar but page scrolls (long forms) |
| `false` | `true` | Topbar pinned, no sidebar |
| `false` | `false` | Marketing-style page scroll |

##### The banner strip

`with_banner` is the full-width strip a host puts an impersonation warning, a
maintenance notice or a "you are in beta" note in. It spans the whole viewport
and the pinned sidebar starts **below** it — nothing to configure, and nothing
to declare about its height:

```erb
<% layout.with_banner do %>
  <div class="bg-warning text-warning-content px-4 py-2">
    Viewing as <strong>John Doe</strong>
  </div>
<% end %>
```

The `app-layout` Stimulus controller measures the strip with a `ResizeObserver`
and publishes `--bali-banner-height` on `<body>`; the sidebar's `top` and
`height` read it. That is what makes the cases apps hand-roll work for free:

- **Several banners at once.** The slot takes as many elements as you put in
  it, and the offset follows the total — no need to add up heights.
- **A banner the user dismisses**, or one a Turbo Stream adds later: measured
  when it changes, measured when it arrives.
- **A banner that wraps to two lines** on a narrow screen, or grows when a font
  finishes loading.

With no banner the variable is never written and the layout is byte-for-byte
what it was, so nothing changes for a page that does not use the slot.

The strip is `position: sticky`, so a warning that the session is impersonated
stays on screen while the page scrolls. Under `viewport_locked: true` the body
does not scroll and sticky does nothing, which is correct.

Only the *height* is JavaScript. The offset itself is one CSS rule, so a page
whose JavaScript has not run yet — or a host that never registers the
controller — renders exactly as it did before: the fallback in
`var(--bali-banner-height, 0px)` is the old behaviour.

##### Reaching the bottom of the page on a phone

`mobile_bottom_padding: true` puts breathing room under the content so the last
row of a list, or the submit button of a long form, is not stuck behind the
phone's own chrome. It is **off by default**: 4rem of air on every mobile page
is a visual change no one asked for except the apps that need it.

```erb
<%= render Bali::AppLayout::Component.new(mobile_bottom_padding: true) do |layout| %>
```

It covers two different problems at once, and the difference matters when you
are debugging one of them:

| | What it is | How it is handled |
|---|---|---|
| Home indicator | The bar on a notched phone. Real, reported by the browser. | `env(safe-area-inset-bottom)`, which is `0px` everywhere else — free on desktop |
| Safari's floating bar | The translucent address/tab bar that hovers **over** the page in mobile Safari | A flat `4rem` under `sm`. It is **not** reported by `env()` — see below |

**The gotcha: Safari's floating bar is not safe-area.** `env(safe-area-inset-*)`
describes the *display cutout*, not browser UI painted over the viewport. In
mobile Safari the bottom bar overlaps the page and `env(safe-area-inset-bottom)`
stays `0px`, so a layout that trusts `env()` alone still hides its last row
behind the bar. That is why the constant sits next to the environment value
instead of being replaced by it.

**`env()` only reports anything if the page opts in.** The insets are `0px`
until the document declares it wants the full display:

```erb
<%# In your layout's <head> %>
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#0f172a">
```

`viewport-fit=cover` is what turns the insets on — without it the safe-area half
of this option is a no-op. `theme-color` is unrelated to layout but belongs to
the same five-minute setup: it paints the browser's own chrome to match the app
instead of leaving a white strip above a dark page. Neither meta tag is Bali's
to render — they live in the host's layout `<head>`, outside the component.

#### Topbar

Top-of-content bar that sits inside the AppLayout's `with_topbar` slot. 56px
tall to align horizontally with the SideMenu's brand row. Slots: brand,
search, actions (many), user_menu.

**Topbar or Navbar?** Decide by what the strip *is*, not where it sits. When the
sidebar is the navigation and the top strip carries search / notifications / the
user menu, that strip is app chrome: use **Topbar** — a `<header>` (banner
landmark) rendered inside the content column, sharing `--bali-chrome-height`
with the sidebar's brand row, with its own mobile hamburger. When the top bar
IS the navigation (no sidebar, marketing shells), use **Navbar** — the page's
`<nav>`, rendered full-width above everything. A Navbar over a sidebar-driven
layout announces a second navigation landmark with nothing navigational in it.
The AppLayout previews model both: "Topbar + Sidebar + Content" and
"Navbar + Content".

```erb
<%= render Bali::Topbar::Component.new do |topbar| %>
  <% topbar.with_search do %>
    <%# The Command renders its own search-well trigger — no slot needed. %>
    <%= render Bali::Command::Component.new do |cmd| %>
      <% cmd.with_group(name: "Pages") do |g| %>
        <% g.with_item(title: "Dashboard", icon: 'layout-dashboard', href: '/') %>
      <% end %>
    <% end %>
  <% end %>

  <% topbar.with_action do %>
    <%= render Bali::Topbar::IconAction::Component.new(
      icon: 'bell', label: 'Notifications', badge: true, badge_id: 'notifications-badge'
    ) %>
  <% end %>

  <% topbar.with_user_menu do %>
    <%= render Bali::Topbar::UserMenu::Component.new(
      name: current_user.name,
      email: current_user.email,
      sign_out: { href: sign_out_path }
    ) do |menu| %>
      <% menu.with_item(name: 'Profile', href: profile_path, icon: 'user') %>
    <% end %>
  <% end %>
<% end %>
```

**Options:**
- `menu_id` - DOM id of the sidebar the `lg:hidden` hamburger opens. Defaults to `Bali::SideMenu::Component::DEFAULT_ID`. Pass `nil` for layouts without a sidebar

The root element is a `<header>` (the page's banner landmark) and the hamburger is a `Bali::SideMenu::Trigger::Component`.

##### Topbar::UserMenu

The prefabricated user dropdown for the `with_user_menu` slot — a preset of
`Bali::Dropdown` (like `ActionsDropdown`), so keyboard navigation, Escape,
`aria-expanded` and `popover:` come with it. The trigger is an avatar (photo
via `avatar_url:`, or initials with a deterministic colour derived from
`name:` — see Avatar), the name (hidden on mobile) and a chevron. The panel
opens with a non-actionable name/email header, then your `with_item`s, then
the sign-out entry.

**Options:**
- `name` (required) - the user's full name; feeds avatar, header and the trigger's `aria-label`
- `email` - second line of the header; omitted when absent
- `avatar_url` - photo for the avatar; wins over the derived initials
- `sign_out` - `{ href:, method: :delete }`. **No default route**: without this hash the item is not rendered, so the gem stays uncoupled from bali-auth and from the host's route names. With bali-auth: `sign_out: { href: bali_auth.sign_out_path }`. The default `:delete` submits a real form (`button_to`) that cannot degrade to a GET; extra keys (`name:`, `confirm:`, `data:`, ...) reach the item
- Everything else is `Bali::Dropdown::Component`'s (`align:` defaults to `:end` here)

`with_item` is Dropdown's items lambda: `method:`, `icon:`, `modal:`, `drawer:`
all work. A UserMenu with no items and no `sign_out:` renders nothing — a menu
with nothing actionable in it is not a menu.

##### Topbar::IconAction

One icon button for the `with_action` slot — the notification bell packaged. A
`<button>` by default, an `<a>` when given `href:`.

```erb
<%= render Bali::Topbar::IconAction::Component.new(
  icon: 'bell', label: 'Notifications', badge: 3, badge_id: 'notifications-badge'
) %>
```

**Options:**
- `icon` (required) - icon name (Bali::Icon pipeline)
- `label` (required) - accessible name (`aria-label` + `title`); an icon-only control without one has no name
- `href` - renders an `<a>` (navigation) instead of a `<button>` (action)
- `badge` - `true` draws the small dot; a number or string draws a count pill; `nil` draws nothing
- `badge_id` - DOM id of the indicator `<span>`, so the host can `turbo_stream.replace` it. Alone (no `badge:`) it renders the span empty and hidden — a stream can light it up later. The component brings no polling and no channel, only the target

#### Card

Content container with optional header, image, and actions.

```erb
<%= render Bali::Card::Component.new(style: :bordered, shadow: true) do |c| %>
  <% c.with_image(src: "/photo.jpg") %>
  <% c.with_title("Card Title") %>
  <p>Card description text.</p>
  <% c.with_action do %>
    <%= render Bali::Button::Component.new(name: 'Details', variant: :primary) %>
  <% end %>
<% end %>
```

**Options:**
- `style` - `:default`, `:bordered`, `:dash`
- `size` - `:xs`, `:sm`, `:md`, `:lg`, `:xl`
- `side` - Horizontal layout (image on side)
- `image_full` - Image overlays entire card
- `shadow` - Enable shadow (default: true)
- `href` - Renders the card's root element as an `<a class="card">` with a hover shadow affordance, making the whole card one link (drill-downs). The card's content must not contain links or buttons then — interactive content inside an `<a>` is invalid HTML (default: nil)

#### Modal

Dialog overlay for focused interactions. Renders a native `<dialog>` and opens it with
`showModal()`, so the panel is painted in the top layer, the page behind it is inert, and
Escape and focus restoration come from the element. See
[Overlays and the top layer](overlays-and-the-top-layer.md) for what that means for
anything you render over it.

There is no trigger slot: a modal opens from OUTSIDE — a `Bali::Link` with `modal: true`
fetches it (remote), or a `Bali::Button` with `modal: { id:, local: true }` opens one
already rendered on the page. The title goes in the `with_header` slot, not in a keyword.

```erb
<%# The trigger, wherever the action lives: %>
<%= render Bali::Button::Component.new(name: 'Open Modal', modal: { id: 'confirm-modal', local: true }) %>

<%# The modal itself: %>
<%= render Bali::Modal::Component.new(id: 'confirm-modal', shared: false, active: false) do |modal| %>
  <% modal.with_header(title: "Confirm Action") %>

  <p>Are you sure you want to proceed?</p>

  <% modal.with_actions do %>
    <%= render Bali::Button::Component.new(name: 'Cancel', variant: :ghost, data: { action: 'modal#close' }) %>
    <%= render Bali::Button::Component.new(name: 'Confirm', variant: :primary) %>
  <% end %>
<% end %>
```

**A pre-rendered ("local") modal** — content already on the page, opened by name with no
fetch — is declared with an explicit `id:` and `shared: false`, and opened from any
trigger carrying `modal: { id:, local: true }` (`Bali::Link`, `Bali::Button`, or a
dropdown item):

```erb
<%= render Bali::Button::Component.new(name: 'Edit health',
                                       modal: { id: 'health-modal', local: true }) %>

<%= render Bali::Modal::Component.new(id: 'health-modal', active: false, shared: false) do |m| %>
  <% m.with_header(title: 'Edit health') %>
  <% m.with_body do %>
    <%# server-rendered content; opening does not fetch anything %>
  <% end %>
<% end %>
```

`shared: false` (which requires the `id:`) keeps the modal out of broadcast opens — an
open event that names no modal must never open this one alongside the layout's shared
`#main-modal` (#854) — and gives it its own controller instance so the event naming it is
answered by this dialog and not the first one in the DOM.

#### Drawer

Slide-in panel from edge of screen. Like `Modal`, a native `<dialog>` opened with
`showModal()`.

There is no trigger slot here either — a `Bali::Link` with `drawer: true` fetches a page
into the shared drawer, and a `Bali::Button` with `drawer: { id:, local: true }` opens one
already rendered:

```erb
<%= render Bali::Link::Component.new(name: 'Open Settings', href: settings_path, drawer: true) %>

<%# Or, pre-rendered on the page: %>
<%= render Bali::Drawer::Component.new(title: "Settings", position: :right,
                                       drawer_id: 'settings-drawer', shared: false) do %>
  <p>Drawer panel content here.</p>
<% end %>
<%= render Bali::Button::Component.new(name: 'Open Settings', drawer: { id: 'settings-drawer', local: true }) %>
```

**Turbo Stream form submits** (Modal and Drawer): forms submitted with the
`modal#submit`/`drawer#submit` action and `data-turbo="true"` accept
`text/vnd.turbo-stream.html` responses — the streams are applied to the page
and the modal/drawer closes on success (an error stream keeps it open so the
form can re-render inside). Redirect and HTML responses behave as before.

```erb
<%# In the drawer content %>
<%= form_with model: @tag, data: { turbo: true } do |f| %>
  ...
  <%= render Bali::Button::Component.new(name: 'Save', data: { action: 'drawer#submit' }) %>
<% end %>
```

```ruby
# Controller — partial update instead of full-page redirect
respond_to do |format|
  format.turbo_stream do
    render turbo_stream: [
      turbo_stream.replace('systems-card', partial: 'systems_card'),
      turbo_stream.append('toast-notifications', partial: 'toast')
    ]
  end
end
```

#### Columns

Responsive column layout that stacks on mobile and sits side-by-side on `md+`; pass `cols:` to switch to CSS Grid auto-flow mode (no `with_column` wrappers needed).

```erb
<%= render Bali::Columns::Component.new(gap: :lg) do |c| %>
  <% c.with_column(size: :one_third) do %>
    Sidebar content
  <% end %>
  <% c.with_column do %>
    Main content fills remaining space
  <% end %>
<% end %>
```

**Options:**
- `gap` - Space between columns: `:none`, `:px`, `:xs`, `:sm`, `:md`, `:lg`, `:xl`, `:'2xl'` (default: `:md`)
- `cols` - Grid columns 1-12; enables grid auto-flow mode where children render directly (default: `nil`)
- `cols_md` - Grid columns at the `md` breakpoint, 768px+ (default: `nil`)
- `cols_lg` - Grid columns at the `lg` breakpoint, 1024px+ (default: `nil`)
- `cols_xl` - Grid columns at the `xl` breakpoint, 1280px+ (default: `nil`)
- `wrap` - Allow columns to wrap to multiple lines (default: `false`)
- `center` - Center columns horizontally (default: `false`)
- `middle` - Center columns vertically (default: `false`)
- `mobile` - Keep columns horizontal on mobile instead of stacking (default: `false`)

#### Hero

Full-width hero section (DaisyUI `hero`) with title, subtitle, and action slots.

```erb
<%= render Bali::Hero::Component.new(size: :md, color: :primary) do |c| %>
  <% c.with_title('Hello there') %>
  <% c.with_subtitle('Provident cupiditate voluptatem et in.') %>
  <% c.with_actions do %>
    <%= render Bali::Button::Component.new(name: 'Get Started', variant: :secondary) %>
  <% end %>
<% end %>
```

**Options:**
- `size` - Minimum height: `:sm`, `:md`, `:lg` (full screen) (default: `:md`)
- `color` - Background color: `:base`, `:primary`, `:secondary`, `:accent`, `:neutral` (default: `:base`)
- `centered` - Center-align the hero content (default: `true`)

#### Level

> **Deprecated in v3, removed in 4.0.** Level is a flex row with `justify-between` and
> nothing else: `<div class="flex justify-between items-center gap-4">` does the same
> without a component in between. For a page header use
> [PageHeader](#pageheader), which is what Level was holding up.

Horizontal bar that spreads content between left and right sides, wrapping on small screens; use `with_item` directly when positioning is not needed.

```erb
<%= render Bali::Level::Component.new(align: :center) do |c| %>
  <% c.with_left do |l| %>
    <% l.with_item(text: 'Left Item 1') %>
    <% l.with_item(text: 'Left Item 2') %>
  <% end %>
  <% c.with_right do |r| %>
    <% r.with_item(text: 'Right Item 1') %>
  <% end %>
<% end %>
```

**Options:**
- `align` - Vertical alignment of items: `:start`, `:center`, `:end` (default: `:center`)

#### PageHeader

Page-level header with title, subtitle, optional back button, and right-aligned content (the block).

```erb
<%= render Bali::PageHeader::Component.new(
  title: 'Movies',
  subtitle: 'Manage your catalog',
  back: { href: movies_path }
) do %>
  <%= render Bali::Link::Component.new(name: 'New Movie', href: new_movie_path, variant: :primary) %>
<% end %>
```

**Options:**
- `title` - Title text; use the `with_title` slot for a custom tag or classes (default: `nil`)
- `subtitle` - Subtitle text; use the `with_subtitle` slot for a custom tag or classes (default: `nil`)
- `align` - Vertical alignment of left/right content: `:top`, `:center`, `:bottom` (default: `:center`)
- `back` - Back button options hash, requires `href` (e.g. `{ href: path }`) (default: `nil`)
- `responsive` - Stack the header, and give the back button its own row, below `sm` (default: `true`)

**Slots:**
- `with_title(text, tag: :h1, **options)` - The page's heading. A block is the heading's
  *content*, not a replacement for it — a heading inside the block nests one heading in
  another. Nothing renders without text or a block.
- `with_subtitle(text, tag: :p, **options)` - Renders a `<p>`; pass `tag:` for a heading.
- `with_title_tag` - Badges beside the title. They render as siblings of the heading so they
  stay out of its accessible name, and the row wraps on narrow viewports.

**Headings.** The title is the page's `h1`. If your layout already renders one, pass
`tag: :h2` — see the [migration guide](migration-v2-to-v3.md). `tag:` sets the element only;
the size comes from `TITLE_CLASSES` and is overridden with `class:`.

**Accessibility.** The back button is icon-only, so it carries a default `aria-label` from
`bali_view.page_header.back`. Pass a visible `name:` and the label is skipped, so the
accessible name keeps matching the visible one.

#### Footer

Responsive site footer (DaisyUI `footer`) with brand, link sections, and bottom copyright slots.

```erb
<%= render Bali::Footer::Component.new(color: :neutral) do |footer| %>
  <% footer.with_brand(name: 'ACME Industries', description: 'Providing reliable tech since 1992.') %>
  <% footer.with_section(title: 'Company') do |section| %>
    <% section.with_link(name: 'About us', href: '/about') %>
    <% section.with_link(name: 'Contact', href: '/contact') %>
  <% end %>
  <% footer.with_bottom do %>
    <p>Copyright 2026 - All rights reserved</p>
  <% end %>
<% end %>
```

**Options:**
- `color` - Background color preset: `:neutral`, `:base`, `:primary`, `:secondary` (default: `:neutral`)
- `center` - Center-align footer content (default: `false`)

#### SplitView

The inbox shape: a list on the left, the detail of the selected row on the right
inside a Turbo Frame, so a row click swaps only the right column and the list
keeps its scroll position and its highlight.

```erb
<%= render Bali::SplitView::Component.new(frame_id: "inbox-detail") do |split| %>
  <% split.with_list(header: "Inbox", count: @pagy.count,
                     selected: params[:selected], pagy: @pagy) do |list| %>
    <% @items.each do |item| %>
      <% list.with_item(id: item.id, href: inbox_path(selected: item.id),
                        title: item.title, subtitle: item.subtitle,
                        icon: item.icon, meta: item.due_label,
                        meta_color: (:error if item.overdue?)) do |row| %>
        <% row.with_tag(text: item.kind_label, color: :info) %>
      <% end %>
    <% end %>
  <% end %>

  <% if @selected %>
    <% split.with_detail { render "detail_pane", item: @selected } %>
  <% else %>
    <% split.with_empty_detail do %>
      <%= render Bali::EmptyState::Component.new(title: 'Select an item', icon: 'inbox') %>
    <% end %>
  <% end %>
<% end %>
```

**Options:**
- `frame_id` - **Required.** Id of the detail Turbo Frame; rows point at it with `data-turbo-frame`, so it must be unique in the page
- `master_width` - Width of the left column from `lg` up. A CSS length or percentage (default: `"420px"`); anything more expressive overrides `--bali-split-master-width` in your own stylesheet
- `advance` - Emit `data-turbo-action="advance"` on the frame, so a row click pushes its URL into the history and the selection is deep-linkable (default: `true`)
- `height` - `:content` (default) grows with the content and lets the page scroll; `:full` fills the nearest ancestor with a definite height and gives **each pane its own scrollbar**. `:full` is `height: 100%` plus a flex chain — no measured offsets, no JavaScript — so pair it with `Bali::AppLayout::Component.new(viewport_locked: true)`, which is what makes `<main>` a bounded box. With no bounded ancestor it fills nothing, visibly. Inert below `lg`, where the panes are stacked and cannot both fill one screen

**Slots:**
- `with_list` - The structured listing, and the way to build a master
- `with_master` - Free-form left column: the escape hatch for a listing `with_list` does not fit
- `with_detail` - What the server renders for the current selection
- `with_empty_detail` - Shown inside the frame when there is no selection; ignored when `detail` is present

**The list writes the row wiring.** `data-turbo-frame`, `data-split-view-target`,
`data-action` and `aria-current` come from the component — they were the same
four attributes in every host template, and one of them missing meant a row that
silently reloaded the page. Selection is decided once: `with_list(selected:)`
takes the id of the selected record and each item its own `id:`.

**`with_list` options:** `header`, `count`, `selected`, `pagy`, `next_url`,
`infinite_scroll` (default `true`), `item_name`, `max_height`. `with_empty_state`
replaces the rows when there are none, and `with_filter` adds a pill to the filter
band between the header and the rows.

**`with_item` options:** `title` and `href` are required; `id`, `subtitle`,
`icon`, `meta`, `meta_color` (`:error`, `:warning`, `:success`, `:primary`) are
optional, `with_tag(text:, color:)` adds any number of badges, and a block
renders free content under the subtitle.

**Paging is infinite by default.** Given a `pagy:`, the list renders ordinary
pagination controls plus a sentinel; the `split-view-list` controller hides the
controls on connect and fetches the same index URL one page further on as the
sentinel comes into view, appending the rows. No endpoint, no Turbo Stream and
no partial of its own — and a reader without JavaScript keeps working controls,
because enhancement removes them rather than summoning them.

**Filtering is links, not a system.** `with_filter(label:, param:, value:, count:)`
adds a pill to a band between the header and the rows — outside the scroll area so
the pills stay put, inside the card so they read as part of the listing. There is
no form, no submit and no clear button: a filter is a URL, and **the component
builds it** from the current request. `with_list(filter_mode:)` picks the
semantics: `:single` (default) is a bucket strip where one value is active and
clicking the active pill drops the param — what replaces a Clear control — and
`:multi` toggles each pill independently over a multi-valued param
(`"q[status_in]"`), adding or removing its own value and leaving the rest alone.
Every other param survives the click; `page` is dropped, because filtering starts
the listing over. `href:`/`active:` are the escapes.

State reaches a screen reader without `aria-pressed`, which browsers drop on
`role=link`: `:single` marks the one active pill `aria-current="true"`, `:multi`
cannot (several are current at once) and both put an `sr-only` note in the active
pill saying clicking removes it. The look hangs off `data-active`, so the modes
look identical while their semantics differ. The band is one group and wraps,
because a master column is ~420px wide and a filter panel does not belong in one.

A pill click is an ordinary full-page GET, so the infinite scroll resets to page
one by itself and the filter params travel into the pages the sentinel fetches
without the controller knowing what a filter is.

Below `lg` the panes stack, master on top, with no extra JavaScript.

The full pattern — the Rails wiring, deep-linking, the two empty states a
filtered list needs, what happens when the detail request fails, and the
full-page-on-a-phone variant — lives in the
[master-detail guide](master-detail.md).

---

### Navigation Components

#### SideMenu

Vertical sidebar with brand row, sectioned nav, optional module switcher, and
bottom-pinned items. Used inside `Bali::AppLayout`'s `with_sidebar` slot.

```erb
<%= render Bali::SideMenu::Component.new(current_path: request.path, collapsible: true) do |menu| %>
  <%# Brand slot — accepts icon + text or any custom HTML %>
  <% menu.with_brand do %>
    <%= lucide_icon('clapperboard', size: 24) %>
    <span class="truncate">My App</span>
  <% end %>

  <%# Optional: multiple modules → renders a switcher dropdown above the lists %>
  <% menu.with_menu_switch(title: 'Admin', icon: 'shield', href: admin_root_path) %>
  <% menu.with_menu_switch(title: 'Reports', icon: 'bar-chart-3', href: reports_path) %>

  <% menu.with_list(title: 'Main') do |list| %>
    <% list.with_item(name: 'Dashboard', href: '/', icon: 'layout-dashboard', match: :exact) %>
    <% list.with_item(name: 'Movies', href: movies_path, icon: 'film', match: :crud) %>
  <% end %>

  <% menu.with_bottom_group(name: 'Settings', icon: 'settings') do |group| %>
    <% group.with_item(name: 'Profile', href: '#', icon: 'circle-user') %>
    <% group.with_item(name: 'Sign out', href: '#', icon: 'log-out') %>
  <% end %>
<% end %>
```

**Options:**
- `current_path` (required) - For active-state matching
- `id` - DOM id every trigger targets through `aria-controls` (default: `DEFAULT_ID`, `"side-menu"`)
- `fixed` - Fixed-to-viewport sidebar (default: true). Must match `AppLayout`'s `fixed_sidebar:`
- `collapsible` - Show desktop collapse toggle and icon-only collapsed state
- `brand` - Simple text brand. For richer brand (logo + text, custom HTML), use the `with_brand` slot instead
- `aria_label` - Accessible name of the `<nav>` landmark (default: translated "Sidebar")
- `group_behavior` - `:expandable` (default, DaisyUI collapse) or `:dropdown` (hover dropdown for nested items)

Renders a `<nav aria-label>` whose items are a `ul`/`li` list, with `aria-current="page"` on the
item pointing at the current page.

#### SideMenu::Trigger

The single button that opens a `SideMenu` — rendered for you by `Topbar`, by `AppLayout`'s
fallback mobile chrome, and by `Navbar::Burger(type: :sidebar)`. Render it directly for custom
chrome.

```erb
<%= render Bali::SideMenu::Trigger::Component.new %>
<%= render Bali::SideMenu::Trigger::Component.new(menu_id: 'reports-menu', icon: 'panel-left') %>
```

**Options:**
- `menu_id` - id of the sidebar it opens; becomes its `aria-controls` (default: `SideMenu::Component::DEFAULT_ID`)
- `icon` - icon name, or `nil` and pass content for custom markup

It keeps `aria-expanded` in sync with the sidebar, and the sidebar hands focus back to it when
the drawer closes.

**Brand row aligns** with `Bali::Topbar` (both 56px) so they form one continuous chrome divider when paired in `Bali::AppLayout`.

**Match types** for `with_item`: `:exact`, `:partial`, `:starts_with`, `:crud` (matches `/path` and `/path/123/edit` etc).

#### Command

⌘K-style command palette / launcher. Modal panel with search input, grouped
results, keyboard navigation, and a global ⌘K (Mac) / Ctrl+K (Windows) shortcut.

```erb
<%# The search-well trigger is built in — size it via `class:`, no slot needed. %>
<%= render Bali::Command::Component.new(placeholder: 'Search…', class: 'max-w-md') do |c| %>
  <% c.with_group(name: 'Pages', mode: :navigation) do |g| %>
    <% g.with_item(title: 'Dashboard', meta: 'Overview', icon: 'layout-dashboard', href: '/') %>
    <% g.with_item(title: 'Movies', meta: 'Catalog', icon: 'film', href: movies_path) %>
  <% end %>

  <% c.with_group(name: 'Recents', mode: :recent) do |g| %>
    <% g.with_item(title: 'Last viewed doc', icon: 'file-text', href: '/docs/1') %>
  <% end %>

  <% c.with_group(name: 'Actions', mode: :action) do |g| %>
    <% g.with_item(title: 'New movie', meta: 'Create a record', icon: 'plus', href: new_movie_path) %>
  <% end %>
<% end %>
```

**Group modes:**
- `:searchable` (default) - Items only show when the query matches `title + meta`
- `:navigation` - The whole list while the query is empty, then filtered like `:searchable`. What a directory of pages wants: browsable the moment the palette opens **and** narrowed as the user types
- `:recent` - Only shown when query is empty (recent activity)
- `:action` - Always shown (used as a fallback when no matches)

Picking between the last three is about what should happen to the group *as the user types*: `:navigation` narrows, `:recent` steps aside, `:action` survives every query. Reaching for `:action` to get a list on screen at open is what left palettes that never filtered (#1016).

**Options:**
- `placeholder` - Search input placeholder
- `trigger_label` - Text of the default trigger (default "Search…"/"Buscar…" via i18n). Independent of `placeholder` — the trigger is usually shorter
- `density` - `:default` (44px rows) or `:compact` (32px rows)
- `no_results_text` / `no_results_subtitle` - Empty-state copy
- `shortcut_label` - Display label for the shortcut hint on the default trigger (default `⌘K`; `nil` hides it). Actual binding is hardcoded to ⌘K/Ctrl+K

**Triggers:**
- Default — a search-well button the component renders on its own (icon + `trigger_label` + `kbd` hint). Deliberately not a `.btn`: a bordered button under the focus-visible ring reads as a double border when Escape returns focus to it
- `with_trigger` slot — REPLACES the default for shapes it cannot be (icon-only toolbar button, etc.). The slot content is the whole trigger: bring your own accessible name
- Global keyboard: ⌘K (Mac) / Ctrl+K (Windows/Linux)
- Window events: `bali:command:open` / `bali:command:close` / `bali:command:toggle`

**Keyboard:** ↑/↓ to navigate, ⏎ to activate, Esc to close.

**Emits:** `bali:command:select` (bubbles, `detail: { row, value }`) when an item without an
`href` is activated.

#### Breadcrumb

Navigation path indicator.

```erb
<%= render Bali::Breadcrumb::Component.new do |bc| %>
  <% bc.with_item(name: "Home", href: "/") %>
  <% bc.with_item(name: "Products", href: "/products") %>
  <% bc.with_item(name: "Current Page") %>  <%# No href = current %>
<% end %>
```

#### Tabs

One component, two widgets. Which one you get depends on whether the triggers navigate.

**Tabs with panels** — the click swaps a panel without leaving the page. Renders the ARIA
tabs pattern (`role="tablist"` / `role="tab"` / `role="tabpanel"`) driven by the `tabs`
Stimulus controller.

```erb
<%= render Bali::Tabs::Component.new(style: :box) do |tabs| %>
  <% tabs.with_tab(title: "Overview", active: true) do %>
    Overview content...
  <% end %>
  <% tabs.with_tab(title: "Details") do %>
    Details content...
  <% end %>
<% end %>

<%# src: loads a panel's content on demand, still without leaving the page %>
<%= render Bali::Tabs::Component.new do |tabs| %>
  <% tabs.with_tab(title: "Activity", src: activity_path(@project), active: true) %>
<% end %>
```

**Tabs that navigate** — every trigger has an `href:`, so the click leaves the page. There is
no panel to control, so this renders `<nav aria-label>` with plain links and
`aria-current="page"` on the active one, and no Stimulus controller.

```erb
<%= render Bali::Tabs::Component.new(style: :border, label: "Project sections") do |tabs| %>
  <% tabs.with_tab(title: "Summary", icon: "layout-dashboard", href: project_path(@project)) %>
  <% tabs.with_tab(title: "Quality", icon: "shield-check", href: project_quality_path(@project)) %>
<% end %>
```

Without `active:`, an `href:` tab decides for itself by comparing the URL against the current
path; pass `active:` to override that.

In navigation mode each link carries `data-turbo-action="advance"` by default. On a full-page
visit that is a no-op (advance is already Turbo's default); the value shows when the tabs
navigate inside a `turbo_frame`, where it promotes the visit to the URL so each scope stays
addressable and the back button works. Pass `turbo_action: false` on a tab to omit the
attribute, or another symbol (e.g. `:replace`) to pass it through. The tab's `**options` land
on the `<a>` itself — there is no panel div to receive them — with `class` composing with the
tab classes.

**The scopes pattern** — tabs as filtered views of one listing (Mine / Team, statuses), each
with a `count:` badge showing how many records wait behind it. `nil` renders no badge; `0`
renders — an empty scope is information. The count stays in the link's accessible name
("Mine 12"), which is what a screen reader user needs.

```erb
<%= render Bali::Tabs::Component.new(label: "Inbox scopes") do |tabs| %>
  <% tabs.with_tab(title: "Mine", count: @counts[:mine], href: inbox_path(scope: :mine)) %>
  <% tabs.with_tab(title: "Team", count: @counts[:team], href: inbox_path(scope: :team)) %>
  <% tabs.with_tab(title: "Done", count: @counts[:done], href: inbox_path(scope: :done)) %>
<% end %>
```

`count:` also takes a string (`"99+"`), and renders in panel mode too. When a page has two of
these navs (a hub page plus a sub-navigation), give each its own `label:` — it is the only
thing telling them apart in the rotor.

**Mixing the two raises `ArgumentError`.** A `role="tablist"` where half the children are
links leaving the page and half own a panel is not a widget ARIA describes, and it used to
render in silence. Split it into two components, or drop `href:` from all of them.

**Options:**
- `style` - `:default`, `:border` (default), `:box`, `:lift`
- `size` - `:xs`, `:sm`, `:md` (default), `:lg`, `:xl`
- `label` - Accessible name for the `<nav>` in navigation mode. Pass it whenever a page has more than one; defaults to `bali_view.tabs.navigation`. Ignored when the tabs have panels (default: nil)
- `**options` - Additional HTML attributes for the wrapper

**Slots:** `with_tab(title:, icon:, active:, src:, reload:, href:, count:, turbo_action:, **options)`.
In panel mode the tab's `**options` go to its `role="tabpanel"` div; in navigation mode they
go to the `<a>`. `turbo_action:` only applies in navigation mode (default `:advance`,
`false` omits it).

#### ViewSwitch

Segmented control (DaisyUI `join` of buttons) to switch between sibling views of the same content (list / table / board / schedule). Each view is a real link — keep the selected view in the PATH so GET filter forms don't lose it.

> Inside a `DataTable` do **not** use this component directly: `dt.with_view_switch { |switch| switch.with_view(value: :grid, ...) }` renders it and builds the hrefs for you, preserving the listing's query string. See the DataTable section.

```erb
<%= render Bali::ViewSwitch::Component.new(aria_label: "Views") do |switch| %>
  <% switch.with_view(name: "List", icon: "list", href: backlog_view_path("list")) %>
  <% switch.with_view(name: "Board", icon: "grid", href: backlog_view_path("board")) %>
<% end %>

<%# Icon-only for spots that compete for space (tabs row, toolbars) %>
<%= render Bali::ViewSwitch::Component.new(aria_label: "Views", icon_only: true) do |switch| %>
  <% switch.with_view(name: "List", icon: "list", href: backlog_view_path("list"),
                      data: { turbo_action: "replace" }) %>
  <% switch.with_view(name: "Board", icon: "grid", href: backlog_view_path("board"),
                      data: { turbo_action: "replace" }) %>
<% end %>

<%# Selector mode: slicing the data shown, not switching sibling views.
    No icons (a data-slice selector should not dress up as tabs), usually :xs. %>
<%= render Bali::ViewSwitch::Component.new(aria_label: "Months window", mode: :selector, size: :xs) do |switch| %>
  <% switch.with_view(name: "12 months", href: plan_path(months: 12)) %>
  <% switch.with_view(name: "24 months", href: plan_path(months: 24)) %>
<% end %>
```

**Options:**
- `aria_label` - Accessible label for the button group (required)
- `size` - Button size: `:xs`, `:sm`, `:md`, `:lg`, `:xl` (default: `:sm`)
- `icon_only` - `true` for square icon-only buttons at every size, or `:responsive` to collapse only the label below `sm` (what `DataTable` uses: the switch shrinks instead of folding into the `⋯` menu). Either way each view's `name:` becomes the native tooltip (`title`) and the accessible label, so the buttons never lose their accessible name (default: `false`)
- `mode` - `:navigation` for sibling views of the same content — the active view gets `aria-current="page"`. `:selector` for a control that slices the data shown (year, scenario, months window) — the active view gets `aria-current="true"` ("the current item of a set"). The links navigate either way; only the announced semantics change. Never `aria-pressed`: browsers discard it on links (default: `:navigation`)
- `**options` - Additional HTML attributes for the container `div`

**Each `with_view`:**
- `name` - Label of the view (visible text, or tooltip + `aria-label` when `icon_only`)
- `icon` - Icon name rendered before the label; omit it for text-only views, the norm in `mode: :selector` (default: `nil`)
- `href` - Path this view links to
- `active` - Explicit active state; when omitted it is autodetected by matching the request path against `href` (query strings ignored)
- `**options` - Additional HTML attributes for the link, e.g. `data: { turbo_action: "replace" }`

#### Dropdown

Action menu that opens on click, on hover, or as a popover. One component: `ActionsDropdown`
is a preset of this one, not a second implementation.

```erb
<%= render Bali::Dropdown::Component.new(align: :end) do |dd| %>
  <% dd.with_trigger { "Options" } %>
  <% dd.with_item(name: "Edit", href: "/edit", icon: "pencil") %>
  <% dd.with_item(name: "Delete", href: "/things/1", method: :delete, icon: "trash-2") %>
<% end %>
```

**Options:**
- `align` - horizontal axis: `:start` (default), `:center`, `:end`
- `direction` - the side the menu opens towards: `:top`, `:bottom`, `:left`, `:right`.
  Left out, daisyUI's default (below the trigger) applies. It composes with `align:`.
- `width` - `:sm` (w-40), `:md` (w-52, default), `:lg` (w-64), `:xl` (w-80)
- `popover` - move the menu into a popper on `<body>` so no ancestor's `overflow` can clip
  it (default: `false`). What a dropdown inside a scrollable table needs.
- `hoverable` - open on hover as well, through daisyUI's CSS (default: `false`)
- `close_on_click` - close when the reader clicks outside (default: `true`)
- `menu` - `<ul role="menu">` semantics (default: `true`). Pass `false` when the panel holds
  a form or checkboxes rather than menu items: `role="menu"` exposes children it does not
  allow and puts a screen reader into menu mode over a form.

**Items.** `with_item` builds the right element from what the item does, and `icon:`
means the same in all of them:

| The item… | Write | Renders |
|---|---|---|
| navigates | `href:` | `<a>` (`Bali::Link`) |
| mutates state | `href:` + `method: :post/:patch/:put` | a real `button_to` styled as an item — the transition survives without JavaScript (#641) |
| deletes | `href:` + `method: :delete` | `button_to` via `DeleteLink`, with the confirm dialog |
| opens a remote modal/drawer | `href:` + `modal: true` (or `{ id: }`) / `drawer:` | `<a>` that fetches the href into the overlay |
| opens an overlay already on the page | `modal: { id:, local: true }` / `drawer:` — no `href:` | a real `<button>` that opens the named overlay as it is; nothing is fetched |
| runs JavaScript | `tag: :button` + `data: { action: }` | a real `<button>` |
| heads a section | `tag: :title` | a heading, not a menuitem |

```erb
<% dd.with_item(tag: :title, name: "Export") %>            <%# section heading %>
<% dd.with_item(name: "CSV", href: "/x.csv", icon: "download") %>
<% dd.with_item(name: "Approve", href: "/x/approval", method: :post, icon: "check") %>
<% dd.with_item(name: "Delete", href: "/x", method: :delete) %>   <%# DeleteLink + confirm %>
<% dd.with_item(name: "Edit health", icon: "heart-pulse",
                modal: { id: "health-modal", local: true }) %>    <%# no fetch %>
<% dd.with_item(tag: :button, name: "Duplicate", icon: "copy",
                data: { action: "thing#duplicate" }) %>    <%# a real <button> %>
```

The local mode requires the `id:` — an open event that names no overlay is a broadcast,
and a broadcast opens every shared overlay on the page (#854). Render the modal it names
on the same page with a matching `id:` and `shared: false` (a drawer with `drawer_id:` and
`shared: false`), so it only ever answers by name. See
[Overlays and the top layer](overlays-and-the-top-layer.md) for the full contract.

**Keyboard**, and it is the same in both modes. Tab reaches the trigger, Enter or Space
opens it, `↓` / `↑` walk the items, Escape closes it and puts the focus back on the trigger,
and `aria-expanded` follows what is on screen rather than the path that got there — daisyUI
opens the CSS dropdown from `:focus-within` without any JavaScript running, so an attribute
set by hand goes stale the moment somebody uses a mouse.

#### ActionsDropdown

`Bali::Dropdown` with its trigger already chosen: the ⋯ button of a table row. Takes every
Dropdown keyword plus `icon:` for the trigger (default `"ellipsis-h"`).

```erb
<%= render Bali::ActionsDropdown::Component.new(align: :end, popover: true) do |c| %>
  <% c.with_item(name: "Edit", icon: "pencil", href: edit_movie_path(movie)) %>
  <% c.with_item(name: "Delete", icon: "trash-2", href: movie_path(movie), method: :delete) %>
<% end %>
```

#### Stepper

Step indicator for multi-stage flows. Steps accept an optional `sublabel:`
(event date, actor, status note) rendered as a smaller muted line under the
title, or a free content block for arbitrary markup.

```erb
<%= render Bali::Stepper::Component.new(current: 2) do |s| %>
  <% s.with_step(title: "Proposed", sublabel: "07/01 · Luis Pérez") %>
  <% s.with_step(title: "Approved", sublabel: "07/03 · Ana Gutiérrez") %>
  <% s.with_step(title: "Published") do %>
    <span class="text-xs opacity-60">release #12</span>
  <% end %>
  <% s.with_step(title: "Active") %>
<% end %>
```

**Options:**
- `current` - Zero-based index of the active step
- `orientation` - `:horizontal` (default) or `:vertical`
- `color` - DaisyUI step color for completed/active steps

#### WorkflowSteps

Steps of a flow with a verdict per step. Stepper is a wizard by index — one
`current:` and every step's look derives from its position; WorkflowSteps gives
every step its own semantic state, which is the shape of an approval chain, a
signature round or an onboarding checklist. Timeline is chronological; this is
positional.

```erb
<%= render Bali::WorkflowSteps::Component.new do |c| %>
  <% c.with_step(title: "Submitted", state: :success,
                 assignee: "Luis Pérez", date: "Jul 1, 2026") %>
  <% c.with_step(title: "Legal review", state: :error,
                 assignee: "Ana Gutiérrez", date: "Jul 4, 2026") do %>
    Rejected: missing appendix B.
  <% end %>
  <% c.with_step(title: "Finance sign-off", state: :skipped) %>
  <% c.with_step(title: "Director signature", state: :pending) %>
<% end %>
```

**Options:**
- `variant` - `:vertical` (default) or `:horizontal`
- `progress` - The N/M bar. On by default in `:horizontal`; `false` drops it.
  Asking for one on `:vertical` raises — that shape has no header for it.
- HTML attributes for the root element pass through.

**Step options:**
- `title` - The step's name (required)
- `state` - `:success`, `:error`, `:warning`, `:current` (ring emphasis),
  `:pending`, or `:skipped` (required)
- `assignee` - Who the step belongs to, rendered with a user icon
- `date` - Preformatted date/time text; the component does not format
- `number` - Circle content, overriding the automatic numbering
- Content block - Free markup rendered under the meta lines (a rejection
  comment, a `Bali::Tag`, links)

The connector under each circle takes the state of the **next** step, so the
line arrives coloured at the step that owns that verdict — the component
computes this; callers only declare states. Auto-numbering counts the real
route only: a `:skipped` step renders muted with a dash instead of a number and
consumes no position (an explicit `number:` always wins).

Both markers say the state in colour and nothing else — a number is a position,
not a verdict — so every step also renders an `sr-only` span with the state's
name next to its marker. The six strings live under
`bali_view.workflow_steps.states.*` (en/es) and a host overrides them like any
other Bali key when its domain has better words: "Signed", "Returned",
"Waiting on legal".

##### The horizontal quick flow

`variant: :horizontal` renders the same steps as a row of cards with an N/M bar
on top — the shape for a summary card or a table cell, where the whole chain
has to fit in a glance.

```erb
<%= render Bali::WorkflowSteps::Component.new(variant: :horizontal) do |c| %>
  <% c.with_step(title: "Submitted", state: :success, date: "Jul 1") %>
  <% c.with_step(title: "Legal review", state: :current, assignee: "Carmen Ríos") %>
  <% c.with_step(title: "Director signature", state: :pending) %>
<% end %>
```

Same `with_step` API. What changes:

- **The marker is a dot**, so `number:` and the auto-numbering do not apply.
  `:skipped` draws a hollow dot rather than the dash — with no number to read,
  two greys at that size were the same dot.
- **No connectors.** The bar already says how far the flow got.
- **N counts the steps with a verdict** — `:success`, `:error`, `:warning` and
  `:skipped`. A skipped step is settled and it is still one of the dots on
  screen, so counting it keeps N/M matching what the reader can count.
  `:pending` and `:current` are the two that have not happened yet.
- **The bar takes the flow's verdict**: `progress-error` if any step was
  rejected, `progress-warning` if any came back with observations, neutral
  otherwise.
- The dot is decorative; the state name is announced by the same `sr-only`
  span the vertical variant uses (see below).

The cards wrap on their own (`auto-fit` from 11rem), so a long chain becomes
rows instead of shrinking each card past reading width.

##### The decision form is the host's

Approving or rejecting a step is not part of this component and is not planned
to be: it owns the route, the params and the policy. The shape worth copying,
which is the same in every approval screen, is in the `decision_pattern`
Lookbook preview:

```erb
<%= form_with url: decision_path(request), method: :post, builder: Bali::FormBuilder do |f| %>
  <%= f.text_area_group :notes, label: "Notes", rows: 3, required: true %>
  <%= f.submit_field "Approve", variant: :success,
        name: "decision", value: "approve", formnovalidate: true %>
  <%= f.submit_field "Reject", variant: :error, style: :outline,
        name: "decision", value: "reject",
        data: { turbo_confirm: "Reject this request?" } %>
<% end %>
```

One form, two submits told apart by `name:`/`value:` — the controller reads
`params[:decision]` and the notes are typed once whichever way it goes.
`required: true` plus `formnovalidate` on Approve is what makes the browser
demand a reason to reject and ask nothing to approve, with no JavaScript and no
second field. `turbo_confirm` goes on the destructive half only.

#### Pagination

Pagination controls (DaisyUI `join` buttons) built from a Pagy object; renders nothing when there is only one page.

```erb
<%= render Bali::Pagination::Component.new(pagy: @pagy, size: :sm, variant: :outline) %>
```

**Options:**
- `pagy` - The Pagy pagination object (required)
- `size` - Button size: `:xs`, `:sm`, `:md`, `:lg` (default: `:md`)
- `variant` - Button variant: `:default`, `:outline`, `:ghost` (default: `:default`)
- `url` - Base URL for the page links (default: `nil`). Only needed when the Pagy was **not** built by the `pagy()` helper — a bare `Pagy::Offset.new` carries no request and cannot build a URL. When given it wins over the Pagy's own URLs, so it has to carry any query string that must survive paging.
- `fragment` - Anchor appended to every link, e.g. `'#results'`, so a paginator halfway down the page does not send the reader back to the top
- `data` - Data attributes for every link, e.g. `{ turbo_frame: 'movies' }` to page inside a Turbo Frame

```erb
<%# Paging a section without leaving it %>
<%= render Bali::Pagination::Component.new(
      pagy: @pagy, fragment: '#results', data: { turbo_frame: 'movies' }) %>
```

From the controller, `pagy(scope, fragment: '#results')` and `pagy(scope, path: '/movies')` do the same two jobs, and are the better place for them when the whole page paginates.

Everything the component knows about Pagy goes through `Bali::Pagination::PagyAdapter`, the only file in the gem that calls anything Pagy does not promise (`series` is protected; the request lives in an ivar with no reader). Patch the adapter, not the component, if a Pagy upgrade ever calls for it.

#### PaginationFooter

Footer row combining a "Showing X-Y of Z items" summary with `Pagination` controls. This is *the* summary-plus-controls band in the library — `Bali::DataTable` renders it instead of an inline copy, and anything else that needs a listing footer should too. Renders nothing without a Pagy object, and nothing when there is neither a summary nor controls left to draw — including `count == 0`, where "Showing 0-0 of 0 movies" said nothing worth saying.

```erb
<%= render Bali::PaginationFooter::Component.new(pagy: @pagy, item_name: 'movies') %>
```

**Options:**
- `pagy` - Pagy object for pagination (required)
- `item_name` - Name for items in the summary text (default: `nil`, falls back to "items")
- `show_summary` - Whether to show the summary text (default: `true`)
- `show_pagination` - Whether to show pagination controls (default: `true`)
- `size`, `variant`, `url`, `fragment`, `data` - forwarded to `Pagination` (see above). Note that `data` lands on each page **link**, not on the wrapper — `turbo_frame:` is only useful where the navigation happens. Put wrapper attributes in `data-*` keys of your own if you need them there.
- `divider` - sit under a rule at the foot of a listing instead of standing on its own (default: `false`). The vertical space moves above the line and a `border-t` draws it, because a footer that closes a listing should not pad below itself. This is what `DataTable` passes.
- any other option becomes an HTML attribute on the wrapper `div`

The spacing is deliberately **not** something you pass through `class:`. The standalone band carries `py-4`, and adding `pt-4` on top of it leaves both on one element: Tailwind resolves that pair by stylesheet order rather than by the order you wrote them, and nothing you can add cancels the bottom half of a `py-*`. `divider:` swaps the whole spacing set instead of layering a second one on it.

Slots: `with_controls` replaces the `Pagination` component with your own nav.

```erb
<%= render Bali::PaginationFooter::Component.new(pagy: @pagy) do |footer| %>
  <% footer.with_controls { pagy_nav(@pagy) } %>
<% end %>
```

The sentence and the fallback item name come from `bali_view.pagination.summary` and `bali_view.pagination.default_item_name`, in en and es. That one pair is what `DataTable` uses too.

---

### Data Display Components

#### Table

Data table with optional sorting and pagination.

```erb
<%= render Bali::Table::Component.new(zebra: true) do |table| %>
  <% table.with_header(name: "Name", sort: :name) %>
  <% table.with_header(name: "Email") %>
  <% table.with_header(name: "Status") %>

  <% @users.each do |user| %>
    <%# The row's cells are raw <td> tags — there is no with_cell slot. %>
    <% table.with_row do %>
      <td><%= user.name %></td>
      <td><%= user.email %></td>
      <td><%= render Bali::Tag::Component.new(text: user.status, color: status_color(user)) %></td>
    <% end %>
  <% end %>
<% end %>
```

**Sorting** — `sort:` needs a `form:` (a `Bali::FilterForm`); without one the header raises
`Bali::Table::Component::MissingFilterForm`. The value is a **Ransack** attribute, so
sorting through an association takes its path, not the column: `sort: :studio_name` for a
`belongs_to :studio`, never the name of a Ruby `alias_method` — Ransack cannot see those and
drops the sort in silence.

Every sortable column paints a dimmed double chevron that brightens on hover and on keyboard
focus, so a sortable header is distinguishable from a fixed one before it is clicked; the
active one shows a single chevron in the sort direction. The `<th>` carries `aria-sort`
(`ascending` / `descending` / `none`), which is what announces the state — the indicator is
`aria-hidden`. Headers without `sort:` get no `aria-sort` and no indicator.

**Row selection** — `selectable: true` renders the checkbox column plus a select-all
header, wired to the `bulk-actions` Stimulus controller. Every row needs a `record_id:`
(missing one raises `Bali::Table::Row::Component::IncompatibleOptions`), and the `<tr>`
itself becomes the selectable item: it carries the record id, the `selected` class and its
own checkbox. Double-clicking a row toggles it too.

```erb
<%= render Bali::Table::Component.new(form: @filter_form, selectable: true) do |table| %>
  <% table.with_header(name: "Name", sort: :name) %>

  <% @movies.each do |movie| %>
    <% table.with_row(record_id: movie.id) do %>
      <td><%= movie.name %></td>
    <% end %>
  <% end %>
<% end %>
```

The controller must live on an **ancestor** element — `DataTable#with_bulk_actions` puts it
on the DataTable container for you. Standalone, wrap the table in a
`Bali::BulkActions::Component`: its default `variant: :floating` renders the fixed bottom
bar with the counter and the action buttons, and it emits the controller itself.

```erb
<%= render Bali::BulkActions::Component.new do |bulk| %>
  <% bulk.with_action(label: 'Archive', href: bulk_archive_movies_path, variant: :info) %>

  <%= render Bali::Table::Component.new(selectable: true) do |table| %>
    <%# ... %>
  <% end %>
<% end %>
```

This is the replacement for the `bulk_actions:` array that `Bali::Table` accepted in v2;
passing it now raises `ArgumentError` (see the migration guide). The selection column shifts
every other column by one: a column selector's 0-based indexes must account for it.

**Row grouping** — pass `group:` to `with_row` to render a group-header row
whenever the value changes between consecutive rows. The header spans every
column (including the selection column when present) and shows the group
value plus the count of rows in that run (e.g. `Norte (12)`).

```erb
<%= render Bali::Table::Component.new do |table| %>
  <% table.with_header(name: "Leader") %>
  <% table.with_header(name: "Role") %>

  <%# leaders must already be ordered by area %>
  <% @leaders.each do |leader| %>
    <% table.with_row(group: leader.area_name) do %>
      <td><%= leader.name %></td>
      <td><%= leader.role %></td>
    <% end %>
  <% end %>
<% end %>
```

Caveats:

- **Ordering is the caller's responsibility.** The component never re-sorts;
  it only compares each row's `group:` against the previous row. The same value
  reappearing later starts a *new* group header. Sort server-side by the group
  field so equal values are adjacent. When you drive grouping through
  `Bali::FilterForm#group_by` (see **Query-aware grouping** below) this is
  handled for you, and user column sorts remain compatible as a *secondary*
  sort.
- **Pagination splits groups.** With Pagy a group that spans a page boundary
  restarts on the next page, because each page only sees its own slice of rows.
  Pass `group_counts:` (below) so the header still shows the group's *global*
  total plus a "showing N" hint on the split page.
- **Zebra striping shifts.** `table-zebra` stripes by `:nth-child`, so injected
  header rows offset the alternating background of the data rows. This is
  cosmetic and expected.
- **Group headers are not sticky.** They scroll with the table body even when
  `sticky_headers: true` (which only pins the `<thead>`), so the two never
  overlap.
- Rows given `group: nil` (or with no `group:` while other rows have one) are
  collected under a localized "Ungrouped" header (i18n
  `bali_view.table.ungrouped`). When **no** row has a `group:`, the table renders
  exactly as it does without the feature — no header rows.

**Query-aware grouping (FilterForm + DataTable)** — driving grouping through
`Bali::FilterForm` upgrades the page-local behavior above: groups are ordered by
the query, counts are global, and the "Agrupar por" control persists the choice
in the URL.

Declare groupable attributes on the form (DSL or constructor):

```ruby
class MoviesFilterForm < Bali::FilterForm
  group_by_attribute :genre, label: "Género"
  group_by_attribute :status
end

# or, without subclassing:
Bali::FilterForm.new(Movie.all, params, group_by_attributes: [:genre, :status])
```

`group_by` is a **whitelisted top-level param** (not a `q[...]` predicate). The
raw value only takes effect when it matches a declared attribute — anything else
is ignored, so it can never reach `.group()`/`.order()` (Ransack does not
authorize `.group`). When **applied**, the form:

- orders the query by the group field **first**, keeping any user column sort as
  the **secondary** sort — so column sorting and grouping now coexist
  (sort-within-groups); and
- exposes `group_counts`, the **global** per-group totals over the full filtered
  (unpaginated) result.

##### State vs. application (three predicates, three questions)

Grouping only **applies in table mode**: a table is the only surface of
contiguous rows where a group band means something. In cards or a timeline the
same ordering would rearrange the content invisibly, with nothing on screen to
explain it. So outside a grouping mode the control **hides**, the grouping is
**suspended** — and the `group_by` param **survives** in the URL and in the
hidden fields of the filter forms, so switching back to the table finds the
grouping exactly as it was left.

| Question | API | Governs |
|----------|-----|---------|
| Is a grouping **chosen**? (state) | `group_by`, `group_by_active?` | Preservation: hidden fields, filters cache, saved-view payload |
| Does this display mode **apply** grouping? (mode) | `group_by_applies?` | Visibility of the "Group by" control |
| Is it **being applied** right now? | `group_by_applied`, `group_by_applied?` | Ordering, `group_counts`, the `group:` value of each row |
| Chosen but not applied here | `group_by_suspended?` | The "Grouped by Genre — applies in table view" hint the DataTable paints where the control used to be |

Use `group_by_applied` (not `group_by`) wherever you paint the grouping, and
never null out `group_by` yourself to suspend it: the state has to survive.

Three options tune it:

- `group_by_modes:` — display modes that apply grouping (default `[:table]`).
  `[]` means *no* mode applies it: the param is still preserved and still saved
  into a view, it is simply never applied.
- `view_param:` — the URL param carrying the display mode (default `:view`).
  It must be the **same** one you give the DataTable; a DataTable whose
  `view_param:` disagrees with its form raises `ArgumentError` at build time,
  because desynced there is nothing visible to give the bug away.
- `display_mode:` — the mode the listing is going to **render**. Only needed when
  the URL cannot say it: a listing whose first declared view is not a grouping
  mode lands with no `?view=`, and the form — which only sees the URL — would
  assume the grouping applies and sort the cards by group with nothing on screen
  to explain it. Pass the same value you give the DataTable
  (`display_mode: params[:view] || :grid`). While the two disagree the DataTable
  raises `ArgumentError` on render.

Known limit: an invalid `?view=` (hand-typed) makes the DataTable fall back to
the first declared view while the form suspends — a table with no bands. The
state survives and the next click fixes it. That one does **not** raise: a
user can type it, and a 500 is not the answer to a typo.

"No grouping" leaves `?group_by=` (empty) in the URL rather than dropping the
param: with filter persistence on, an absent param means "restore the cached
state", so removing it resurrected the grouping the user just turned off.

Wire it into the view — `DataTable` auto-renders the "Agrupar por" control
whenever the form declares group_by attributes, and the `Table` shows global
counts when you pass `group_counts:`:

```erb
<%= render Bali::DataTable::Component.new(url: request.path, filter_form: @filter_form, pagy: @pagy) do |c| %>
  <% c.with_simple_filters %>          <%# control renders itself beside the filters %>
  <% c.with_table do %>
    <%= render Bali::Table::Component.new(form: @filter_form, group_counts: @filter_form.group_counts) do |t| %>
      <%= t.with_header(name: "Name", sort: :name) %>
      <%= t.with_header(name: "Genre", sort: :genre) %>
      <% @movies.each do |movie| %>
        <% applied = @filter_form.group_by_applied %>
        <%= t.with_row(group: applied && movie.public_send(applied)) do %>
          <td><%= movie.name %></td>
          <td><%= movie.genre %></td>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

A split group then reads e.g. `Norte (30) — showing 25` (i18n
`bali_view.table.group_partial`). The count lookup is tolerant of string-vs-symbol
keys and falls back to the page-local count on a miss.

Constraints:

- **Do not `.reorder` the relation after `result`** when grouping — it drops the
  group-first ordering and rows stop cohering into groups. Let the form own the
  order.
- **`group_by` travels with the state, always.** The "Agrupar por" links carry
  it, the filter forms round-trip it as a hidden field, the filters cache stores
  it and a saved view records it — including while it is suspended in card mode.
  Suspension is a derived predicate, never `@group_by = nil`.

#### Avatar

User avatar display: an image when there is one, derived initials when there is not.

```erb
<%# Image avatar %>
<%= render Bali::Avatar::Component.new(
  src: user.avatar_url,
  name: user.name,
  size: :md,
  shape: :circle
) %>

<%# No image: `name:` derives the initials and a stable background color %>
<%= render Bali::Avatar::Component.new(name: 'Ana García López') %>

<%# Explicit initials override the derivation %>
<%= render Bali::Avatar::Component.new(initials: 'AG') %>
```

**Options:**
- `src` - Image URL (default: nil)
- `name` - Full name; derives two initials and a deterministic background when no image renders (default: nil)
- `initials` - Explicit initials, overriding the `name:` derivation (default: nil)
- `size` - `:xs`, `:sm`, `:md`, `:lg`, `:xl` (default: `:md`)
- `shape` - `:square`, `:rounded`, `:circle` (default: `:circle`)
- `mask` - `:heart`, `:squircle`, `:hexagon`, `:triangle`, `:diamond`, `:pentagon`, `:star` (default: nil)
- `status` - `:online`, `:offline` presence indicator (default: nil)
- `ring` - Ring color: `:primary`, `:secondary`, `:accent`, `:neutral`, `:success`, `:warning`, `:error`, `:info` (default: nil)

**Initials rule:** first letter of the *first* and the *last* word — "Ana García López" → AL,
"María de la Luz" → ML; a single word yields one letter. Unicode-aware upcase.

**Deterministic color:** the name is hashed (`Bali::Utils::ColorCalculator#deterministic_color`)
into the fixed `Bali::Status` palette minus `slate`/`gray`, rendered as an inline style — the same
person gets the same color on every render, process and DaisyUI theme. Collisions (two people, one
color) are expected. The manual `placeholder` slot still exists for fully custom content and keeps
the static neutral background.

**Precedence:** picture slot > `src:` > `placeholder` slot > `name:`/`initials:`.

**Accessibility:** with `name:`, an initials avatar gets `role="img"`, `aria-label` and `title`
with the full name; an image avatar uses the name as `alt` (explicit `alt:` wins) plus `title`.

#### Tag (Badge)

Labels and status indicators.

```erb
<%= render Bali::Tag::Component.new(text: "New", color: :primary) %>
<%= render Bali::Tag::Component.new(text: "Pending", color: :warning, style: :outline) %>
<%= render Bali::Tag::Component.new(text: "Docs", href: "/docs", color: :info, size: :sm) %>
<%= render Bali::Tag::Component.new(text: "Custom", custom_color: "#3b82f6") %>
<%= render Bali::Tag::Component.new(text: "Done", icon: "check", color: :success) %>
```

**Options:**
- `text` - Label; falls back to the block content when omitted (default: nil)
- `href` - Renders an `<a>` instead of a `<div>` (default: nil)
- `color` - `:neutral`, `:primary`, `:secondary`, `:accent`, `:ghost`, `:info`, `:success`, `:warning`, `:error` (default: nil, daisyUI's own)
- `size` - `:xs`, `:sm`, `:md`, `:lg`, `:xl` (default: nil, which renders like `:md`)
- `style` - `:outline`, `:soft`, `:dash` (default: nil)
- `custom_color` - Hex string applied as an inline background, with the text color picked for contrast (default: nil)
- `rounded` - Fully rounded pill (default: false)
- `icon` - Icon name, drawn before the text at the pill's own font-size so it fits every badge size (default: nil)

**Slots:** `with_icon(name, **options)` — the `icon:` keyword written as a slot; it takes
`Bali::Icon` options (`size:`, `class:`, …) and wins over the keyword when both are given.

**Enum sugar:** `Bali::Tag.for(value, map:, i18n_scope:, default:, **tag_options)` turns a
domain value plus a host-owned `value => color/options` map into a ready-to-render Tag,
resolving the label through i18n. An unmapped value raises unless `default:` is given. The
full recipe — and when to reach for `Status.for` instead — is in the
[enum badges guide](enum-badges.md).

An unknown `color:` or `size:` raises `ArgumentError` naming the valid values. The Bulma
names v2 accepted (`:danger`, `:small`, `light: true`, …) are gone; the error names their
replacement, and the full table is in the [migration guide](migration-v2-to-v3.md).

**A Tag never wraps.** daisyUI's `.badge` is a fixed-height box, so a wrapped label renders
its extra lines outside the pill. The component sets `white-space: nowrap`, which means a
long tag widens its container instead of breaking — inside `Bali::Table` the table scrolls,
inside a fixed-width card the pill overhangs. Opt out per call site with
`class: "whitespace-normal"`; the rule is in `@layer components`, so a plain utility wins.

#### Status

Colorful, SmartSuite-style status pill with optional inline editing. Presentational and domain-agnostic — colors come from a fixed palette or a hex string, rendered as inline styles so it looks the same across DaisyUI themes with no Tailwind safelist.

```erb
<%# Read-only %>
<%= render Bali::Status::Component.new(
      selected: record.status,
      options: Model.status_options) %>

<%# Editable (auto-submits via Turbo); readonly toggles by permission %>
<%= render Bali::Status::Component.new(
      id: dom_id(record, :status),
      selected: record.status,
      options: Model.status_options,
      form: { url: record_status_path(record), method: :patch, param: "model[status]" },
      readonly: !policy(record).manage?,
      clearable: true) %>
```

**Options:**
- `selected` - Currently selected value, matched against each option's `value:` (default: nil)
- `options` - Array of `{ value:, label:, color: }` or `{ value:, label:, custom_color: }`. `color:` takes either the fixed status palette (`:slate :gray :red :orange :amber :yellow :green :teal :blue :indigo :violet :pink`), which deliberately does not follow the theme, or one of the semantic names shared with every other component (`:neutral :primary :secondary :accent :info :success :warning :error :ghost`), which does. `custom_color:` takes a hex — in v2 a hex went in `color:` (default: `[]`)
- `form` - `{ url:, method:, param: }`; when present (and `readonly:` is false) the pill becomes clickable and opens a portaled panel of colored option rows that submits via Turbo on selection (default: nil)
- `readonly` - Forces the read-only pill even when `form:` is given, e.g. permission-gated call sites (default: false)
- `clearable` - Adds a clear (X) button and a "no status" row to the panel; only applies when editable (default: false)
- `size` - `:xs`, `:sm`, `:md` (default: `:sm`)
- `placeholder` - Text shown when nothing is selected (default: i18n `bali_view.status.no_status`, "No status")
- `**html_options` - Additional HTML attributes for the wrapper `span`; the consumer owns the Turbo target id via `id:` passthrough

The consuming controller responds with a Turbo Stream replacing the element identified by the `id:` you pass.

**Enum sugar:** `Bali::Status.for(value, map:, i18n_scope:, default:, **status_options)`
mirrors `Bali::Tag.for`: one host-owned `value => color/options` map builds the whole
`options:` array (labels through i18n), so the same map powers the editable panel too. An
unmapped selected value raises unless `default:` is given. Recipe and the Tag vs Status
criterion: [enum badges guide](enum-badges.md).

**Public palette:** the twelve fixed pairs are public API — `Bali::Status.palette(:green)`
returns `{ bg: "#16a34a", fg: "#fff" }` (raising on an unknown name), for painting
something that is *not* a pill (a Gantt bar, a chart slice) in the same colour as the
pill for the same state. Public means frozen: changing a hex is a breaking change.

#### Progress

Progress bar indicator.

```erb
<%= render Bali::Progress::Component.new(value: 75, max: 100, color: :primary) %>
```

#### ImageGrid

Responsive image gallery with optional lightbox and empty state.

```erb
<%= render Bali::ImageGrid::Component.new(columns: 4, expandable: true) do |grid| %>
  <% grid.with_empty_state do %>
    <p class="text-sm text-base-content/60"><%= t('bali_view.image_grid.empty_state.title') %></p>
    <%= render Bali::Link::Component.new(name: t('bali_view.image_grid.empty_state.add_image'),
          href: new_image_path, variant: :primary) %>
  <% end %>
  <% @images.each do |image| %>
    <% grid.with_image(full_src: image.full_url) { image_tag image.thumb_url } %>
  <% end %>
<% end %>
```

The `empty_state` slot renders inside a dashed-border centered box instead of
the grid when there are no images; it is ignored when images are present.
i18n keys `bali_view.image_grid.empty_state.{title,add_image}` ship in en/es.

#### BooleanIcon

Displays a boolean as a coloured icon plus an `sr-only` name — a green check for true, a red cross for false, and a neutral dash for nil. Useful in table cells and lists.

The value is **ternary**. `nil` is missing data, not `false`: announcing "No" for a column nobody filled in states something the record does not say. Pass `value: false` explicitly if an unset value should read as no.

```erb
<%= render Bali::BooleanIcon::Component.new(value: movie.indie) %>

<%# The default name is generic; supply the subject where the surrounding markup doesn't %>
<%= render Bali::BooleanIcon::Component.new(value: movie.indie, label: t('.indie_film')) %>
```

**Options:**
- `value` - `true`, `false`, or `nil` for "not specified". Any other truthy value still reads as true (required)
- `label` - Accessible name for this cell. Defaults to `bali_view.boolean_icon.true` / `.false` / `.blank` — "Yes" / "No" / "Not specified" (default: nil)
- `**options` - Additional HTML attributes for the wrapper div

The icon is `aria-hidden`, so the `sr-only` label is the only accessible name the component has. Without it the colour is the sole difference between the two states, which also fails WCAG 1.4.1.

#### Chart

Renders a Chart.js chart (bar, line, pie, doughnut, polarArea) with theme-aware colors, optionally wrapped in a DaisyUI card.

```erb
<%= render Bali::Chart::Component.new(
  data: {
    labels: %w[Mon Tue Wed Thu Fri],
    datasets: [
      { label: 'Sales', data: [120, 190, 300, 250, 420] },
      { label: 'Returns', data: [20, 30, 25, 35, 40] }
    ]
  },
  type: :bar,
  title: 'Weekly Sales Report',
  legend: true,
  card_style: :default
) %>
```

**Options:**
- `type` - Chart type or array of types for mixed charts: `:bar`, `:line`, `:pie`, `:doughnut`, `:polarArea` (default: `:bar`)
- `data` - Simple hash `{ "Mon" => 10 }` or multi-series `{ labels: [...], datasets: [...] }` (default: `{}`)
- `title` - Chart title shown in the card header (default: nil)
- `legend` - Show the legend (default: false)
- `display_percent` - Display values as percentages (default: false)
- `order` - Dataset draw order, one entry per dataset (default: `[]`)
- `y_axis_ids` - Y-axis IDs per dataset for multi-axis charts (default: `[]`)
- `options` - Custom Chart.js options, deep-merged over defaults (default: `{}`)
- `card_style` - Card wrapper: `:default`, `:bordered`, `:compact`, `:none` (default: `:none`)
- `height` - Height preset: `:sm`, `:md`, `:lg`, `:xl` (default: `:md`)
- `use_theme_colors` - Use DaisyUI theme colors for series, grid, and tooltips (default: true)
- `color` - Semantic name the palette starts from (`:neutral :primary :secondary :accent :info :success :warning :error :ghost`). A single-series chart is painted in it; a multi-series one cycles from it (default: nil, i.e. `:primary` first)
- `custom_color` - Hex colour the palette starts from. It drops the theme palette entirely and the remaining series fall back to the fixed hex list, because a canvas cannot resolve a `var()` and a chart cannot mix the two (default: nil)
- `aria_label` - Accessible name for the canvas. Falls back to `title:`, then to `bali_view.chart.default_label` (default: nil)

**Slots:** `with_data_table` — a real `<table>` rendered `sr-only` next to the canvas.

Everything Chart.js draws is pixels, so the canvas is `role="img"` with a name. A name is not
a number: `with_data_table` is the only way a screen reader user reads a value off the chart.

```erb
<%= render Bali::Chart::Component.new(data: @sales, title: t('.weekly_sales')) do |c| %>
  <% c.with_data_table do %>
    <table>
      <caption><%= t('.weekly_sales') %></caption>
      <thead><tr><th scope="col"><%= t('.day') %></th><th scope="col"><%= t('.sales') %></th></tr></thead>
      <tbody>
        <% @sales.each do |day, total| %>
          <tr><th scope="row"><%= day %></th><td><%= total %></td></tr>
        <% end %>
      </tbody>
    </table>
  <% end %>
<% end %>
```

#### DataTable

Complete data table wrapper with filters, quick search, summary, and pagination. Integrates with `Bali::FilterForm` — when a `filter_form` is given, `with_filters_panel` auto-configures attributes, filter groups, and search.

The component owns three bands: a **bare** toolbar (identical in every display mode), the **content**, and a bare footer (summary + pagination). The surface travels with the content slot, so the host does **not** wrap the DataTable in `Bali::Card`.

The canonical composition — the seven toolbar control families, row selection and
pagination — is the `Complete` scenario of the DataTable preview, and the same body inside
a page is `bali/index_page/complete`. Copy one of those rather than assembling from the
option list below.

```erb
<%= render Bali::DataTable::Component.new(filter_form: @filter_form, url: movies_path, pagy: @pagy) do |dt| %>
  <% dt.with_filters_panel(search: { placeholder: 'Search movies...' }) %>
  <% dt.with_table do %>
    <%= render Bali::Table::Component.new(form: @filter_form) do |t| %>
      <% t.with_header(name: 'Name', sort: :name) %>
      ...
    <% end %>
  <% end %>
<% end %>
```

**Options:**
- `url` - Base URL for filtering/sorting links (required). It is also the base for the **page**
  links, but only when the `pagy` cannot build its own — that is, when it was not created by
  the `pagy()` helper and so carries no request. With the helper (the normal case) Pagy keeps
  building them from the real request, which is what preserves an applied filter across a page
  change; `url:` is a filtering base and does not carry the query string, so letting it win
  would drop that filter. When it *is* used, the listing composes it the way the view switch and
  "Group by" do: `url` plus the current query string, minus the one-shot params.
- `filter_form` - `Bali::FilterForm` instance for Ransack integration (default: nil)
- `pagy` - Pagy object for pagination (default: nil)
- `show_summary` - Show record summary (default: true when pagy present). Suppressed either way when there are no results — a "Showing 0-0 of 0" line under an empty table tells nobody anything.
- `summary_position` - `:top` or `:bottom` (default: `:bottom`). At the bottom it is the left half of a [`PaginationFooter`](#paginationfooter), which the DataTable renders rather than duplicating.
- `item_name` - Item name used in the summary text (default: `bali_view.pagination.default_item_name`)
- `table_class` - CSS class for the content scroll wrapper (default: `"overflow-x-auto"`)
- `display_mode` - Display mode requested by the host, typically `params[:view]`. It does
  **not** select a slot — there is only one content band, and the host chooses what to
  declare, reading the already-validated value from `dt.display_mode` (see
  `with_view_switch`). Omitted, it falls back to `params[<view_param>]` and then to the
  first declared view, so a switch still works if you forget to wire it; pass it explicitly
  when the mode does not come from the URL.
- `view_param` - URL param that carries the view (default: `:view`)
- `id` - Listing identity: the container id, the column selector's `querySelector` target
  (`#<id> table`) and the localStorage key of its columns (`bali:columns:<id>`) — one name
  for everything the listing persists. Resolved in this order: explicit `id:`, then
  `filter_form.storage_id`, then a random hex. The value is sanitized into a valid CSS
  identifier (case preserved). With the random hex the id cannot survive the next render,
  so **column persistence turns itself off** rather than writing a key nothing can read
  back. `with_column_selector` and `with_saved_views` take no `table_id:` — they read this.

If the host replaces the listing over Turbo Streams, target the **resolved** id — not the raw
`storage_id`, which is not the same string whenever sanitizing changes it (`'admin/movies'` →
`admin-movies`). Turbo looks the target up with `getElementById`, so a miss replaces nothing
and reports nothing:

```erb
<%= turbo_stream.replace Bali::DataTable::ListingIdentity.for(@filter_form) do %>
  <%= render 'listing' %>
<% end %>
```

`Bali::DataTable::ListingIdentity.for` accepts the form (or a raw value) and applies exactly
the rule the component applies.

**That recipe is only correct from a request that already carries the listing's state.** It
re-renders the listing from `params`, so it needs the grouping, the filters and the sort the
page had. `index` has them. A form submitted from inside a `Modal` or `Drawer` does not: the
controller posts to the **form's** action with `fetch`, adding only `layout=false`, so
`request.query_parameters` is `{"layout" => "false"}` and nothing else. Re-rendering from
there answers 200 with an ungrouped, unfiltered listing, and writes that single param into the
toolbar's links and into every ransack `sort_link` on the way out. Nothing raises.

From an overlay, ask Turbo to revisit the page instead — the browser's URL is the one that
still has the state:

```erb
<%# create.turbo_stream.erb, answering a form inside a Drawer %>
<%= turbo_stream.refresh(method: :morph, scroll: :preserve) %>
```

The controller renders no listing at all on that branch; `index` rebuilds it from the real
URL. `method: :morph` keeps scroll and focus instead of repainting the page, and the overlay
still closes, because closing is what the stream response itself triggers.

One thing to know before relying on it: Turbo drops a refresh whose `X-Turbo-Request-Id` it
has seen recently (`isRecentRequest`). `Modal`/`Drawer` submit through plain `fetch`, not
`Turbo.fetch`, so they never send that header and the refresh always fires. A host that
submits the same form through `Turbo.fetch`, or from inside a `turbo-frame`, has to send the
listing's params along and go back to the `replace` above.

**Content slot.** There is exactly ONE content band, and it decides its own surface:

| Slot | Surface | Scroll wrapper |
|------|---------|----------------|
| `with_table` | yes (a table needs a background of its own) | yes |
| `with_grid` | no (the cards *are* the surface) | no |
| `with_content(surface:, scroll:)` | `surface:` (default `true`) | `scroll:` (default `false`) |

`with_table` and `with_grid` are sugar over `with_content`. Extra keywords go straight to
the `Bali::Card` surface (`style:`, `class:`, `shadow:`, `body_class:`). Content that brings
its own chrome — a calendar, a map — passes `surface: false`.

Declaring two content slots raises `Bali::DataTable::Component::DuplicateContent`: to
alternate between modes, pick which one you declare with an `if` on `dt.display_mode`.

```erb
<% if dt.display_mode == :grid %>
  <% dt.with_grid do %>...<% end %>
<% else %>
  <% dt.with_table do %>...<% end %>
<% end %>
```

**View switch.** `with_view_switch` puts a `Bali::ViewSwitch` in the toolbar. Unlike the
standalone component, each view declares a `value:` — the DataTable builds the href itself,
merging the current query string so filters, sorting, grouping and the applied
`saved_view` survive the mode change (`page` is dropped, so switching returns to page one).
`href:` is still accepted per view, for a mode that lives on another route.

```erb
<%= render Bali::DataTable::Component.new(
      url: movies_path, filter_form: @filter_form, pagy: @pagy,
      display_mode: params[:view]) do |dt| %>
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

`dt.display_mode` is the value **validated against the declared views**: an unknown
`?view=` falls back to the first declared view instead of leaving the listing empty, so a
raw URL param never reaches the content unchecked. Declare the switch before reading it.
`aria_label:`, `size:`, `icon_only:` and any HTML attribute pass through to
`Bali::ViewSwitch` (the DataTable defaults it to `icon_only: :responsive`).

Passing `display_mode:` also makes the view travel as a hidden field on the filter forms,
so applying a filter or a search from the cards view does not drop the user back into the
table. A filter submit rebuilds the URL from `url:` — which hosts pass without a query
string — so anything that must survive it has to be an explicit hidden field; the active
`group_by` travels the same way.

**Toolbar layout.** The row reads left to right as
`search + filters · group by · columns ￨ saved views · persistence` and, pinned to the far
right, the view switch. The left side is the **state of the listing and how it is
remembered**, the right side is **how it is displayed** — the display mode is not part of a
saved view's payload, which is why the view switch is the only thing on that side. The
vertical rule between `columns` and `saved views` marks the boundary between the two left
subgroups; it is rendered only when both sides have content and hidden below the breakpoint
(see below).

Four home groups back this: `left` (filters, group by, columns), `memory` (saved views,
the filter-persistence bookmark), `host` (your `toolbar_buttons`) and `right` (the view
switch, alone). Host buttons get their own group precisely so the view switch stays pinned
to the edge: inside `right` the JS orders by priority and they landed to its right.
Export is NOT a toolbar control — it lives in the page's `⋯` menu, see
[Secondary page actions](#secondary-page-actions-and-export).

**Narrow viewports.** Below `sm` (640px) the toolbar folds its secondary controls into a
`⋯` menu and unfolds them on the way back. The nodes are **moved**, never duplicated: two
copies of the column selector would be two Stimulus controllers driving one table. Survival
order lives in `OVERFLOW_PRIORITIES` — search/filters and the view switch stay in the row;
group by, columns, saved views, the persistence bookmark and host `toolbar_buttons`
collapse. Three consequences worth knowing:

- **The order inside a group** is defined by `OVERFLOW_PRIORITIES`, not by the template:
  expanding re-sorts each group by descending priority, which is what lets the controller be
  stateless across Turbo reconnects. **The order of the groups** is the template's. The
  numbers descend in reading order, so the `⋯` lists the collapsed controls in the same
  order the row does.
- The separator is not a control: it carries no priority and is not an `item`, so it can
  never travel into the `⋯`. The controller only hides it — when a collapse empties either
  of the two groups it flanks, and by CSS (`max-sm:hidden`) when the bundle has not loaded.
  An empty group is hidden too, so it does not keep stealing the row's `gap`.
- The `⋯` is a server-side decision (it is not rendered when nothing is collapsible), so a
  host that adds or removes `toolbar_buttons` from JavaScript after render can leave the
  gate stale. The controller hides an empty `⋯`, but it cannot create one.

Anything placed in a collapsible slot (`with_toolbar_button` is arbitrary host content)
must therefore:

1. have an **idempotent `connect()`** — moving a node fires `disconnect()` then `connect()`;
2. carry **no `data-turbo-permanent`**;
3. keep its label readable inside the menu — mark a label that hides on mobile with the
   `toolbar-control-label` class, or, for a `Bali::Button`/`Bali::Link`, pass
   `responsive: false` (their responsive mode hides the label below `sm`, which inside the
   `⋯` leaves an anonymous icon).

**Row selection and bulk actions**

```erb
<%= render Bali::DataTable::Component.new(url: movies_path, filter_form: @filter_form) do |dt| %>
  <% dt.with_bulk_actions do |bulk| %>
    <% bulk.with_action(label: 'Mark as done', href: bulk_actions_path(bulk_action: 'mark_done'), variant: :success) %>
    <% bulk.with_action(label: 'Delete', href: bulk_actions_path(bulk_action: 'delete'), variant: :error) %>
  <% end %>

  <% dt.with_table do %>
    <%= render Bali::Table::Component.new(form: @filter_form, selectable: true) do |t| %>
      <% @movies.each do |movie| %>
        <% t.with_row(record_id: movie.id, select_label: movie.name) do %>...<% end %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

Pass `select_label:` on every selectable row: without it all the checkboxes share the label
"Select row", and in a screen reader's form-controls rotor a 25-row page is 25 identical
entries.

`with_bulk_actions` renders a `Bali::BulkActions(variant: :toolbar)` contextual row that
**replaces the toolbar** while a selection exists and restores it when it is cleared. The
`bulk-actions` Stimulus controller goes on the DataTable container, so the bar and the
table rows share one scope. Each action is its own form carrying `selected_ids` (a JSON
array injected by the controller); a parameter of your own goes in the action's
`with_control` slot, or in its query string. When the DataTable has a `pagy`, the bar also
offers to act on the whole filtered result and re-emits the `filter_form`'s `q[...]` so the
server can rebuild the same scope — see [BulkActions](#bulkactions).

Slots: `with_filters_panel`, `with_simple_filters`, `with_content` (`with_table` / `with_grid`), `with_summary`, `with_toolbar_button`, `with_view_switch`, `with_saved_views`, `with_column_selector`, `with_bulk_actions`, `with_custom_pagy_nav`.

Export is not one of them: `page.with_export` on the surrounding page component puts it in
the page's `⋯` — see [Secondary page actions](#secondary-page-actions-and-export).

#### DescriptionList

A set of label/value pairs laid out in the component's own responsive grid — the middle ground between `LabelValue` (one pair you place yourself) and `PropertiesTable` (one set read as a table). Renders one `<dl>` whose items are `<div><dt/><dd/></div>` cells, with `dt`/`dd` reusing LabelValue's typography.

```erb
<%= render Bali::DescriptionList::Component.new(columns: 2) do |c| %>
  <% c.with_item(label: 'Name', value: 'Juan Perez') %>
  <% c.with_item(label: 'Email', value: 'juan@example.com') %>
  <% c.with_item(label: 'Status') do %>
    <%= render Bali::Tag::Component.new(text: 'Active', color: :success) %>
  <% end %>
<% end %>
```

**Options:**
- `columns` - Grid columns: `1`, `2`, or `3`; `2` and `3` collapse to one column on small screens (default: 2)
- `layout` - `:stacked` (label above value) or `:horizontal` (label and value side by side inside each cell) (default: :stacked)
- `**options` - Additional HTML attributes for the `<dl>`

**Slots:** `with_item(label:, value:)` — items accept block content instead of `value:` for rich values (a `Tag`, a link, any HTML), and pass extra HTML attributes through to the item's `<div>`.

**LabelValue, DescriptionList, or PropertiesTable?** They render the same information and read differently.

| | LabelValue | DescriptionList | PropertiesTable |
|---|---|---|---|
| Markup | one `<dl>` per pair | one `<dl>`, a grid cell per pair | one `<table>`, `<th scope="row">` per row |
| Layout | you place each pair — a grid cell, a card, a column | its own responsive grid | rows, stacked, zebra-striped |
| Screen reader | a run of them is a run of separate one-pair lists | one list announced once | one set, with table navigation and a row count |

Use `PropertiesTable` when the pairs form **one set read top to bottom**, which is most detail
pages. Use `DescriptionList` when the pairs form one set but want **a grid, not table rows** —
the dense header block of a show page, a two-column details card. Use `LabelValue` for a pair
that stands on its own, or when each pair needs its own placement in a layout neither grid can
express.

#### Gantt

Timeline of scheduled work: groups (one nesting level), items (sub-items, milestones as
diamonds), dependencies and a server-computed critical path, all described by one frozen data
contract (`Bali::Gantt::Data`). **One renderer:** the React Flow island — drag to move,
resize to change duration, draw dependencies, plus zoom, search, filtering, the column
selector, colour-by, the minimap and fullscreen. A read-only board is the same island with
no `urls:` and `editable`/`manageable` left false. The server-rendered `:static` renderer
was removed in #970; the component always mounts the island, and the skeleton it renders
inside the mount is the loading state (React retires it from inside its first commit, so no
frame shows an empty box). **It needs JavaScript** — a `<noscript>` notice inside the mount
says so.

```erb
<%= render Bali::Gantt::Component.new(
  data: gantt.to_h,                 # the contract — see Bali::Gantt::Data
  zoom: params[:gantt_zoom],        # :auto/:day/:week/:month; :auto resolves server-side
  statuses: gantt.statuses,         # [{ value:, label:, color: }]
  catalogs: gantt.catalogs,
  editable: true, manageable: true, # a viewer passes neither, and no urls
  urls: { patch: schedule_path(project), schedule: schedule_path(project),
          dependencies: dependencies_path(project) },
  id: dom_id(project, :gantt)       # also the broadcast target
) %>
```

**Options:**
- `data` - The Gantt document: `{ window (optional), groups: [], items: [], dependencies: [], critical_ids: [] }`; contract, renames and validation rules documented in `Bali::Gantt::Data`
- `zoom` / `zoom_param` - Zoom level (`:auto` default, resolved server-side against the window so the island does not rescale on mount) and the namespaced query param it persists into (default: `gantt_zoom`)
- `statuses` - Status catalog `[{ value:, label:, color: }]` — `color` is a daisyUI variable name (`'--color-info'`) or `nil` for neutral
- `catalogs` / `i18n` / `editable` / `manageable` / `urls` / `date_locale` - Island catalogs (`{ statuses:, priorities: }`, defaults to `statuses`), its string table (defaults to `Bali::Gantt::Translations.island`), what the visitor may do, the endpoints (`patch:`, `dependencies:`, `schedule:`, `item_template:`, `new_group:`, `new_item:` — an unknown key raises) and the date-fns locale
- Removed in #970 and refused by name: `mode`, `fallback`, `limit`, `zoom_links`, `group_label`, `color_by`

**The island (npm):** `bali-view-components/gantt` exports `GanttController` (a
`ReactIslandController` subclass — see `docs/api/react-island.md`); `/gantt-entry` is the
dedicated bundler entry (registers on `window.Stimulus`, emits the island CSS) and
`/gantt-loader` lazy-loads it on first sight of `data-controller="gantt"`. Optional peers:
`react`, `react-dom`, `@xyflow/react >= 12`, `date-fns`, `@rails/request.js`. The controller's
values mirror the props: `data`, `catalogs` (`{ statuses:, priorities: }`), `i18n`
(`Bali::Gantt::Translations.island`), `editable`/`manageable`, `patchUrl`/`dependenciesUrl`/
`scheduleUrl`, `itemUrlTemplate`, `newGroupUrl`/`newItemUrl`, `zoomParam`, `dateLocale`. The
mutation contract (PATCH item / POST-DELETE dependency → always the complete document; 422
`{errors}` → rollback; 404 → re-GET) has an executable reference in the dummy's
`Admin::Projects::SchedulesController`, and the Lookbook previews `bali/gantt/default` /
`editable` / `stress` / `empty` exercise the island end to end.

**Full API, including the mutation and broadcast contracts a host implements:**
`docs/api/gantt.md`.

#### Heatmap

Grid visualization that shows magnitude as color intensity across two dimensions, e.g. activity by day and hour.

```erb
<%= render Bali::Heatmap::Component.new(
  data: {
    Mon: { 9 => 5, 10 => 8, 11 => 3 },
    Tue: { 9 => 3, 10 => 6, 11 => 9 }
  },
  color: :primary
) do |c| %>
  <% c.with_x_axis_title('Days') %>
  <% c.with_y_axis_title('Hours') %>
  <% c.with_hovercard_title('Clicks by hour of day') %>
  <% c.with_legend_title('Clicks') %>
<% end %>
```

**Options:**
- `data` - Hash of `{ x_label => { y_label => value } }` (required)
- `color` - Semantic name (`:neutral :primary :secondary :accent :info :success :warning :error :ghost`). The ramp is built from the DaisyUI theme variable, so it repaints when the theme changes; in v2 these were hardcoded hex and `:primary` was indigo whatever the theme said (default: `:primary`)
- `custom_color` - Hex base colour for the ramp; does not follow the theme. In v2 a hex went in `color:` (default: nil)
- `cell_size` - Cell size in pixels (default: 28)
- `responsive` - Stretch to fill container width (default: true)

Slots: `with_x_axis_title`, `with_y_axis_title`, `with_legend_title`, `with_hovercard_title`.

The value lived only in the hover card through v2, which put every number behind a mouse. The
axis labels are `<th scope="col">` (x, at the foot) and `<th scope="row">` (y), so both axes
reach each cell as headers, and each cell carries its value as `sr-only` text — a coloured
cell with no text is an empty cell to a screen reader. Nothing moved visually.

#### Icon

Renders an icon by name, resolving Lucide icons first (1,600+ available), then kept brand/regional icons, then legacy Bali icons.

```erb
<%= render Bali::Icon::Component.new('check', size: :large) %>
<%= render Bali::Icon::Component.new('alert', class: 'text-error') %>
```

**Options:**
- `name` - Icon name: Bali name, Lucide name, or kept brand/regional icon (required, positional)
- `tag_name` - Wrapper HTML tag (default: `:span`)
- `size` - `:small`, `:medium`, `:large`, or an integer in pixels (default: nil, renders at 16px)
- `**options` - Additional HTML attributes (e.g. `class`)

#### InfoLevel

> **Deprecated in v3, removed in 4.0.** Each item is a stat card with a third design of its
> own; the one that stays is [StatCard](#statcard), which is also what
> `DashboardPage#with_stat` renders since v3. For a row of figures, a grid of StatCard.

Horizontal row of heading/title stat items, useful for profile counts or summary metrics.

```erb
<%= render Bali::InfoLevel::Component.new(align: :center) do |c| %>
  <% c.with_item do |i| %>
    <% i.with_heading('Posts') %>
    <% i.with_title('128') %>
  <% end %>
  <% c.with_item do |i| %>
    <% i.with_heading('Followers') %>
    <% i.with_title('12.3K') %>
  <% end %>
<% end %>
```

**Options:**
- `align` - Item alignment: `:start`, `:center`, `:end`, `:between` (default: `:center`)
- `**options` - Additional HTML attributes

Slots: `with_item` (each item takes `with_heading` and `with_title`, as text or block).

#### LabelValue

Displays a small bold label above its value — a common pattern on show pages. Renders as a single-pair `<dl>`: `<dt>` for the label, `<dd>` for the value.

```erb
<%= render Bali::LabelValue::Component.new(label: 'Name', value: 'Juan Perez') %>

<%# Block content is used when value: is nil %>
<%= render Bali::LabelValue::Component.new(label: 'URL') do %>
  <a href="#" class="link link-primary">Download link</a>
<% end %>
```

**Options:**
- `label` - Label text shown above the value (required)
- `value` - Value to display; when nil, block content is rendered instead (default: nil)
- `**options` - Additional HTML attributes

**LabelValue, DescriptionList, or PropertiesTable?** LabelValue is the right call for a pair
that stands on its own, or when each pair needs its own placement in a layout — every instance
is its own one-pair list, so a run of them is a run of lists, not one set. When the pairs form
one set, reach for `DescriptionList` (its own grid) or `PropertiesTable` (table rows) — the
full comparison lives under [DescriptionList](#descriptionlist).

It was a `<div>` holding a `<label>` through v2. A `<label>` with no control to point at
labels nothing: the text and the value beside it were two unrelated nodes in the
accessibility tree.

#### List

Vertical list of rows (DaisyUI `list`) where each item has a title, subtitle, optional actions, and extra content.

```erb
<%= render Bali::List::Component.new do |c| %>
  <% c.with_item do |i| %>
    <% i.with_title('First item') %>
    <% i.with_subtitle('Description of the first item') %>
    <% i.with_action do %>
      <%= render Bali::Button::Component.new(name: 'Delete', variant: :error, size: :sm, icon: 'trash-2') %>
    <% end %>
  <% end %>
<% end %>
```

**Options:**
- `borderless` - Remove the outer border and rounded box (default: false)
- `relaxed_spacing` - Add extra vertical padding to rows (default: false)
- `**options` - Additional HTML attributes

Slots: `with_item` (each item takes `with_title`, `with_subtitle`, and repeatable `with_action`; extra block content renders in the middle column).

#### LocationsMap

Interactive Google Map with location markers, optional info views, clustering, and linked location cards. Requires a Google Maps JavaScript API key in `Bali.google_maps_key`, which falls back to the `GOOGLE_MAPS_KEY` environment variable.

```erb
<%= render Bali::LocationsMap::Component.new(zoom: 12, clustered: false) do |c| %>
  <% c.with_location(latitude: 32.5253, longitude: -117.0166) %>
  <% c.with_location(latitude: 32.5284, longitude: -117.0197, color: 'green') %>
  <% c.with_location(latitude: 32.5162, longitude: -117.0129) do |location| %>
    <% location.with_info_view { tag.p('This is an info view') } %>
  <% end %>
  <% c.with_card(latitude: 32.5253, longitude: -117.0166) { tag.p('Card 1') } %>
<% end %>
```

**Options:**
- `center_latitude` - Map center latitude (default: 32.5036383, Tijuana)
- `center_longitude` - Map center longitude (default: -117.0308968)
- `zoom` - Initial map zoom level (default: 12)
- `clustered` - Enable marker clustering (default: false)

**Slots:** `with_location` (markers, support `color`, `label`, `icon_url`, and a nested `with_info_view`), `with_card` (cards rendered beside the map that highlight when their marker is clicked).

#### PropertiesTable

Displays key-value pairs in a zebra-striped table — useful for showing object attributes on detail pages.

```erb
<%= render Bali::PropertiesTable::Component.new do |c| %>
  <% c.with_property(label: 'Name', value: 'John Doe') %>
  <% c.with_property(label: 'Email', value: 'john@example.com') %>
  <% c.with_property(label: 'Member Since', value: 'January 2024') %>
<% end %>
```

**Options:**
- `**options` - Additional HTML attributes for the table (e.g. `class`)

**Slots:** `with_property(label:, value:)` — properties also accept block content for rich values like tags or links.

Prefer this over `LabelValue` or `DescriptionList` when the pairs form one set read top to bottom — the comparison of the three lives under [DescriptionList](#descriptionlist).

#### QrCode

A QR code generated server-side and rendered as inline SVG — no JavaScript, no image request, nothing to serve.

It needs the [`rqrcode`](https://github.com/whomwah/rqrcode) gem, which Bali deliberately does **not** depend on: most apps never render a QR code and would carry the gem for nothing. Add it to the host's Gemfile:

```ruby
gem 'rqrcode', '~> 3.1'
```

Without it the first render raises `Bali::QrCode::Component::MissingDependency` — a `LoadError` subclass whose message repeats that line, so an app that forgets is told what to add rather than left with `cannot load such file`.

```erb
<%= render Bali::QrCode::Component.new(payload: movie_url(@movie)) %>

<%# TOTP enrolment: name it, or the screen reader announces only "QR code" %>
<%= render Bali::QrCode::Component.new(
      payload: @totp.provisioning_uri,
      size: 240,
      level: :q,
      label: t('.scan_with_your_authenticator')
    ) %>
```

**Options:**
- `payload` - What the code encodes — a URL, an `otpauth:` URI, plain text (required)
- `size` - Rendered edge length in pixels (default: 200)
- `level` - Error correction: `:l`, `:m`, `:q`, `:h`. Denser levels survive a dirtier or partly covered surface and make the code bigger for the same payload (default: :m)
- `label` - Accessible name. Defaults to `bali_view.qr_code.label` — "QR code", which says nothing about what scanning it does (default: nil)
- `**options` - Additional HTML attributes for the `svg` element

The code is always black on white and includes the spec's four-module quiet zone. Neither is configurable: a scanner reads dark-on-light, so theme colours would leave the code unreadable under a dark theme — while still looking like a QR code — and one rendered flush against its neighbours is one some scanners never find.

The SVG carries a `viewBox`, so `class: 'w-full h-auto'` overrides `size` where a fluid code is wanted.

#### QrScanner

The other half of [QrCode](#qrcode): a camera viewfinder that decodes QR codes in the browser and announces each one as a DOM event. One app prints the label, another reads it.

It needs the [`qr-scanner`](https://github.com/nimiq/qr-scanner) npm package, an **optional** peer Bali does not bundle — loaded with a dynamic `import()` the first time a scanner connects:

```sh
yarn add qr-scanner
```

Without it the component renders its "unavailable" state and the console names the line to run, rather than failing silently.

```erb
<%= render Bali::QrScanner::Component.new %>

<%# Inside a modal, or anywhere the prompt should follow a deliberate press %>
<%= render Bali::QrScanner::Component.new(autostart: false) %>

<%# Keep reading, front camera, own wording under the viewfinder %>
<%= render Bali::QrScanner::Component.new(
      camera: :user,
      stop_on_scan: false,
      hint: t('.scan_the_label_on_the_box')
    ) %>
```

**Options:**
- `camera` - `:environment` (rear — the one pointed at the thing being scanned) or `:user` (front) (default: :environment)
- `autostart` - Ask for the camera as soon as the component connects. `false` renders an idle state with a button instead (default: true)
- `stop_on_scan` - Release the camera after the first code and show the "scan again" state. `false` keeps reading and keeps emitting (default: true)
- `highlight` - Draw qr-scanner's scan-region frame and code outline over the picture (default: true)
- `hint` - The line under the viewfinder. `false` drops it (default: the localized "Point the camera at the QR code.")
- `**options` - Additional HTML attributes for the container

##### Reading a code

The component decodes and announces; it never decides what a code means. Everything past that is one listener:

```js
document.addEventListener('bali:qr-scanner:scan', ({ detail }) => {
  const input = document.querySelector('#token')
  input.value = detail.value
  input.form.requestSubmit()
})
```

| Event | `detail` |
|---|---|
| `bali:qr-scanner:scan` | `{ value, result }` — `value` is the decoded string; `result` is qr-scanner's own result object, which also carries `cornerPoints` |
| `bali:qr-scanner:error` | `{ state, error }` — `state` is `'denied'` or `'unavailable'`; `error` is what the browser threw |

Both bubble from the component's own element, so a listener can sit on it or on `document`.

##### A camera needs a secure context

`getUserMedia` is only exposed over **https, or http on `localhost`**. On any other host over plain http the browser exposes no camera at all — and it arrives looking exactly like a device that has none, which is why the controller says so in the console rather than leaving you to check the hardware. Testing from a phone against a dev machine means https or a tunnel; the IP address on your LAN will not do.

##### The states

Six, and every one of them is in the document from the first render — the controller shows one by taking `hidden` off it. A host restyles `denied` from a stylesheet, and a test asserts on visibility rather than on text that was never there.

| State | When |
|---|---|
| `idle` | `autostart: false`, before the button is pressed |
| `requesting` | The permission prompt is up |
| `scanning` | The camera is live. The only state with no panel — the picture is the state |
| `scanned` | A code was read and `stop_on_scan` released the camera |
| `denied` | The visitor, or a policy, refused |
| `unavailable` | No camera, one another application is holding, or no secure context |

The current one is on the container as `data-qr-scanner-state`, so `.qr-scanner-component[data-qr-scanner-state="scanning"]` is a selector a host can hang its own rules on.

The panels are white on a dark scrim under every theme, deliberately: what they sit on is the camera preview — black before the stream arrives, arbitrary photography after — not a themed surface. Same reasoning as the always-black-on-white [QrCode](#qrcode).

#### Rate

Star rating built on DaisyUI's rating classes, with Rails form integration, auto-submit, and readonly display modes.

```erb
<%# Form input %>
<%= render Bali::Rate::Component.new(form: f, method: :rating, value: 3) %>

<%# Readonly display %>
<%= render Bali::Rate::Component.new(value: 4, readonly: true) %>
```

**Options:**
- `value` - Current rating value (required)
- `form` - Rails form builder for form integration (default: nil)
- `method` - Model attribute name for the input (default: nil)
- `scale` - Range of selectable ratings (default: 1..5)
- `size` - Star size: `:xs`, `:sm`, `:md`, `:lg` (default: :md)
- `color` - Star color: `:warning`, `:primary`, `:secondary`, `:accent`, `:success`, `:error`, `:info` (default: :warning)
- `auto_submit` - Submit the form immediately when a star is clicked (default: false)
- `readonly` - Display-only mode with disabled inputs (default: false)

#### Skeleton

Loading placeholder with preset patterns for common layouts (text, paragraphs, cards, avatars, buttons, modals, lists).

```erb
<%= render Bali::Skeleton::Component.new(variant: :paragraph, lines: 3) %>
<%= render Bali::Skeleton::Component.new(variant: :list, lines: 4) %>
```

**Options:**
- `variant` - Preset pattern: `:text`, `:paragraph`, `:card`, `:avatar`, `:button`, `:modal`, `:list` (default: :text)
- `size` - Line height / avatar size: `:xs`, `:sm`, `:md`, `:lg` (default: :sm)
- `lines` - Number of lines/items for `:paragraph` and `:list` variants (default: 3)

#### StatCard

Metric card showing a title, value, and colored icon — ideal for dashboard KPI rows.

```erb
<%= render Bali::StatCard::Component.new(
  title: 'Total Users',
  value: '1,234',
  icon: 'users',
  color: :primary
) do |c| %>
  <% c.with_footer { tag.span('+12% from last month', class: 'text-success') } %>
<% end %>
```

**Options:**
- `title` - Metric label (required)
- `value` - Metric value to display (required)
- `icon` - Bali/Lucide icon name; omit it and the card renders without one (default: nil). `icon_name:` still works, warns through `Bali.deprecator`, and goes away in v4
- `color` - Icon accent: `:neutral`, `:primary`, `:secondary`, `:accent`, `:info`, `:success`, `:warning`, `:error`, `:ghost` (default: :primary)
- `custom_color` - Hex icon accent, applied inline instead of the semantic pair (default: nil)
- `href` - Renders the whole card as an `<a>` (KPI drill-down to its listing) with a hover shadow affordance. Don't wrap the card in `link_to` anymore; and the footer must not contain links then — an `<a>` inside an `<a>` is invalid HTML (default: nil)

**Slots:** `with_footer` — optional footer for trends or status text.

This is the one stat card. `DashboardPage#with_stat` renders it, and both `InfoLevel` and
DashboardPage's own inline card — the other two designs — are gone or deprecated in v3.

#### Tags

Groups multiple Tag components in a wrapping flex container with configurable gap spacing. Renders nothing when no items are given.

```erb
<%= render Bali::Tags::Component.new(gap: :sm) do |c| %>
  <% c.with_item(text: 'Ruby', color: :primary) %>
  <% c.with_item(text: 'Rails', color: :success, style: :outline) %>
  <% c.with_item(text: 'Docs', href: '/docs', color: :info) %>
<% end %>
```

**Options:**
- `gap` - Spacing between tags: `:none`, `:xs`, `:sm`, `:md`, `:lg` (default: :sm)

**Slots:** `with_item(text:, href:, **options)` — each item accepts any `Bali::Tag` option (`color`, `style`, `size`, `rounded`); `href` renders it as a link.

#### Timeago

Displays relative time ("5 minutes ago") using date-fns for localized formatting, with optional auto-refresh.

```erb
<%= render Bali::Timeago::Component.new(article.created_at, add_suffix: true) %>

<%# Live-updating timestamp %>
<%= render Bali::Timeago::Component.new(user.last_seen_at, add_suffix: true, refresh_interval: 30000) %>
```

**Options:**
- `datetime` - The time to display, passed as the first positional argument (required)
- `add_suffix` - Append "ago"/"in" to the output (default: false)
- `refresh_interval` - Auto-refresh interval in milliseconds, `nil` disables (default: nil)
- `include_seconds` - Include seconds for distances under a minute (default: true)

#### Timeline

Vertical timeline for chronological sequences of events, using DaisyUI's timeline with headers, icons, and color variants.

```erb
<%= render Bali::Timeline::Component.new(position: :left) do |c| %>
  <% c.with_header(text: 'Start', color: :primary) %>
  <% c.with_item(heading: 'January 2022', icon: 'check', color: :success) do %>
    <p>Timeline event 1</p>
  <% end %>
  <% c.with_item(heading: 'February 2022') do %>
    <p>Timeline event 2</p>
  <% end %>
  <% c.with_header(text: 'End') %>
<% end %>
```

**Options:**
- `position` - Timeline layout: `:left`, `:center`, `:right` (default: :left)
- `compact` - Collapse to a single column (DaisyUI `timeline-compact`); every content box lands on the end side, so `position:` no longer alternates (default: false)

**Slots:** `with_header(text:, color:, custom_color:, class:)` (badge separators) and `with_item(heading:, icon:, color:, custom_color:, state:, timestamp:, href:)` with block content. Any other `with_item` option becomes an HTML attribute of the content box — `data: { action: 'click->drawer#open' }` makes the box Stimulus-clickable.

`color:` takes a semantic name (`:neutral :primary :secondary :accent :info :success :warning :error :ghost`); `custom_color:` takes a hex. An item defaults to `:ghost`, which leaves the marker and the connecting line their DaisyUI colour — in v2 that value was spelled `:default`. `color: :outline` is gone from headers: it named a style, not a colour, so pass `color: :primary, class: 'badge-outline'`.

`state:` is tracking sugar over `icon:`/`color:`: `:done` renders a `circle-check` primary marker, `:current` a `circle-dot` primary marker, and `:pending` the plain circle with a muted heading. Explicit `icon:`/`color:` win over the state's defaults (`state: :done, color: :success` for the green check). The line below an item takes the colour of the item that follows it, so the coloured line runs exactly as far as the journey has. `timestamp:` (a string, or anything `l`-localizable; the `with_timestamp` slot replaces it when the metadata needs markup) renders muted on the free side of the line — or inside the box when compact. `href:` renders the content box as a link with hover feedback.

Every entry renders exactly once. Which side of the line an item lands on is decided in Ruby, and for `position: :center` it alternates across items, so a header between two items does not flip the alternation.

**Tracking preset** — the custody-chain / itinerary look (event + date + author per entry):

```erb
<%= render Bali::Timeline::Component.new(compact: true) do |c| %>
  <% c.with_item(state: :done, heading: 'Package received',
                 timestamp: 'Jul 28, 09:14 · A. García') %>
  <% c.with_item(state: :done, heading: 'Left warehouse',
                 timestamp: 'Jul 28, 11:02 · R. Ortiz') %>
  <% c.with_item(state: :current, heading: 'In transit', href: shipment_path(@shipment)) %>
  <% c.with_item(state: :pending, heading: 'Delivered') %>
<% end %>
```

#### TreeView

File/folder-style navigation tree with expandable nested sections. Branches containing the `current_path` expand automatically and the active item is highlighted.

```erb
<%= render Bali::TreeView::Component.new(current_path: request.path) do |c| %>
  <% c.with_item(name: 'Home', path: '/') %>
  <% c.with_item(name: 'Documentation', path: '/docs') do |docs| %>
    <% docs.with_item(name: 'Introduction', path: '/docs/introduction') %>
    <% docs.with_item(name: 'Installation', path: '/docs/installation') %>
  <% end %>
<% end %>
```

**Options:**
- `current_path` - Path of the active item, used for highlighting and auto-expanding branches (default: nil)

**Slots:** `with_item(name:, path:)` — items nest recursively via a block to build sub-trees.

---

### Interactive Components

#### The shared button taxonomy

`Button`, `Link` (in button dress), `DeleteLink` and `BulkActions::Action` all render
DaisyUI's `.btn`, and they take the same three keywords for it. The three are independent
axes and they compose:

| Keyword | Means | Values |
|---|---|---|
| `variant:` | the colour | `:neutral :primary :secondary :accent :info :success :warning :error :ghost :link` |
| `style:` | the fill | `:outline`, `:soft` |
| `size:` | the scale | `:xs :sm :md :lg :xl` |

```erb
<%= render Bali::Button::Component.new(name: 'Discard', variant: :error, style: :outline, size: :sm) %>
<%= render Bali::Link::Component.new(name: 'Discard', href: path, variant: :error, style: :outline, size: :sm) %>
```

A value outside its table raises `ArgumentError` at construction rather than rendering a
button with no colour at all. The message names the keyword that does take it, so
`variant: :outline` is told to become `style: :outline`. The tables live in
`Bali::ButtonTaxonomy`.

#### Button

Primary interactive element for actions.

```erb
<%# Basic %>
<%= render Bali::Button::Component.new(name: 'Save', variant: :primary) %>

<%# With icon %>
<%= render Bali::Button::Component.new(name: 'Add', variant: :success, icon: 'plus') %>

<%# Loading state — `loading:` already disables the button, no second keyword needed %>
<%= render Bali::Button::Component.new(name: 'Processing...', loading: true) %>

<%# Icon slots %>
<%= render Bali::Button::Component.new(name: 'Next', variant: :primary) do |btn| %>
  <% btn.with_icon_right('arrow-right') %>
<% end %>
```

**Options:**
- `name` - Button text
- `variant` - Colour (see the shared taxonomy above)
- `style` - `:outline` or `:soft`
- `size` - Size modifier
- `icon` - Left icon name. `icon_name:` still works, warns through `Bali.deprecator`, and goes away in v4
- `type` - The HTML attribute: `:button`, `:submit`, `:reset`. Never a look
- `disabled` - Disable button
- `loading` - Draw a spinner beside the label and disable the button (`disabled` plus `aria-busy`). A button that is waiting is not one you can press, and it keeps its box: `loading` on the `<button>` itself is a daisyUI 5 spinner, not a modifier
- `modal` / `drawer` - `{ id:, local: true }` opens an overlay already rendered on the page, by name and with no fetch (`id:` is mandatory). Only the local mode: a button has no href to fetch, so the remote mode stays on `Link`

#### Link

Navigation links, optionally styled as buttons.

```erb
<%# Plain link %>
<%= render Bali::Link::Component.new(name: 'View Details', href: item_path(@item)) %>

<%# Link styled as button %>
<%= render Bali::Link::Component.new(
  name: 'Create New',
  href: new_item_path,
  variant: :primary  # Button styling
) %>
```

**When to use Button vs Link:**
- Use `Button` for **actions** (submit, click handlers)
- Use `Link` for **navigation** (goes to a URL)

**Overlay triggers.** `modal: true` fetches the href into the shared modal;
`modal: { id: }` addresses the modal with that id; `modal: { id:, local: true }` opens a
modal already rendered on the page as it is — no fetch, and the `id:` is mandatory.
`{ size: }` composes with all three, and `drawer:` has the same contract.

#### Tooltip

Contextual information on hover or focus. The block is the balloon; the `trigger` slot is
what opens it.

```erb
<%= render Bali::Tooltip::Component.new(placement: :top) do |c| %>
  <% c.with_trigger do %>
    <%= render Bali::Button::Component.new(name: 'Export', variant: :ghost) %>
  <% end %>
  <p>Downloads the current slice as CSV.</p>
<% end %>
```

**Options:**
- `placement` - `:top` (default), `:bottom`, `:left`, `:right`
- `trigger_event` - tippy trigger string, `"mouseenter focusin"` by default. `"click"` and
  `"manual"` are the other useful values.
- `append_to` - `:body` (default since v3.1, #992), `:parent`, or a CSS selector. The default
  portals the balloon to `<body>` so it escapes ancestors whose `overflow` would clip it —
  AppLayout's own `<main>` under `viewport_locked` is one. Pass `:parent` to keep the balloon
  inside the trigger's subtree. Inside an open modal/drawer the balloon goes to the top-layer
  host regardless, so it never paints under an overlay.

**Keyboard.** The default trigger is `focusin` rather than tippy's `focus` because the
element tippy watches is the wrapper around the slot, and a `focus` on the caller's own
control inside the slot does not reach it — `focusin` bubbles and does. When the slot holds
nothing focusable (the classic `?` help tip), the controller gives the wrapper `tabindex="0"`
so the balloon has a keyboard route at all; when the slot brought its own button or link it
does not, so there is no second, unnamed tab stop in front of it.

**The balloon takes markup, including markup with no text in it.** The block is rendered
into a `<template>` and handed to tippy with `allowHTML`, so an image preview, an icon
legend or a small inline chart is a supported balloon — the `markup_content` preview shows
two. The one case that builds nothing is a tooltip with *no* content: `with_trigger` and no
block. That one gets no tippy instance and no `tabindex`, because a balloon that will never
open should not claim a stop in the tab order.

#### HelpTip

The help icon with a tooltip, packaged (#993): the "?" next to a heading, a label or a
domain term. `FieldGroupWrapper` renders a field's `tooltip:` option through this same
component, so the icon on a form field and the one in a table header are one drawing — no
hand-rolled Tooltip + Icon pair per call site.

```erb
<%= render Bali::HelpTip::Component.new(t('.sipoc_help')) %>
<%= render Bali::HelpTip::Component.new(text, icon: 'circle-help', placement: :right) %>

<%# Rich content, as a block %>
<%= render Bali::HelpTip::Component.new do %>
  <p>SIPOC: suppliers, inputs, process, outputs, customers.</p>
<% end %>
```

**Options:**
- First positional: the balloon text (or pass a content block instead)
- `icon` - icon name, `"info-circle"` by default (Bali::Icon pipeline)
- `placement` - `:top` (default), `:bottom`, `:left`, `:right`
- Everything else passes through to `Bali::Tooltip` (`append_to:`, `class:`, `data:`, …)

The trigger is keyboard-reachable out of the box, and the balloon inherits Tooltip's
`:body` portal default, so it escapes clipping ancestors without per-call opt-ins.

#### Kanban

Kanban board built on SortableList with drag-and-drop between columns. Each
column maps to a status value sent to the server on drop. Columns accept an
optional `footer` slot rendered outside the sortable list (never draggable) —
the classic "+ add card" action.

```erb
<%= render Bali::Kanban::Component.new(resource_name: "task", group_name: "board",
      layout: :flow, height: :viewport) do |k| %>
  <% k.with_column(title: "To Do", status: "todo", color: :ghost) do |col| %>
    <% col.with_card(update_url: task_path(task), label: task.title) { render TaskCard.new(task:) } %>
    <% col.with_footer do %>
      <%= link_to "+ Add card", new_task_path(status: :todo) %>
    <% end %>
  <% end %>
  <% k.with_column(title: "Brand", status: "brand", custom_color: "#7c3aed") %>
  <% k.with_column(title: "Blocked", status: "blocked", disabled: true) %>
<% end %>
```

**Layout and height are board-level.** `layout: :grid` (the default) places up
to 4 columns side by side and stacks on mobile; `layout: :flow` puts every
column on a single horizontally scrolling row (`w-72` each) — the shape for
boards with 5+ status columns. `height:` is opt-in: `nil` (default) lets the
board grow with its content; `:viewport` caps it to
`calc(100vh - var(--bali-kanban-offset, 17rem))` — override
`--bali-kanban-offset` on any ancestor to match your app's header chrome — and
any string is taken as a height utility class (`height: "h-[40rem]"`). On a
height-capped board each column's card list scrolls internally; there is no
separate `scrollable:` knob, and no per-column `max_height:` — bound the board,
not the columns (a one-off column cap is a `max-h-*` utility via the column's
`class:` option).

**An empty column stays a visible drop target.** When a column has no cards its
list keeps a 100px floor and a dashed border. The affordance is CSS `:has()`,
not a render-time `cards.empty?` flag, so it tracks the drag live: drag the
last card out and it appears, hover a drag over the empty column and it yields
to SortableJS's preview. Both rules live in `kanban/index.css` inside
`@layer components` — a host utility on the list still wins.

`disabled: true` on `with_column` freezes that column (forwarded to the
underlying SortableList): its cards cannot be dragged out and it stops
accepting drops. To only stop specific cards from *leaving* a live column,
render those cards with `data: { sortable_item_pull: "false" }` instead.

##### Wiring the drop PATCH

A drop sends one `PATCH` to the dragged card's `update_url` — there is no
board-level endpoint. With `resource_name: "task"` and the default
`list_param_name: "status"` the body is:

```
task[position] = 3        # 1-based position within the target column
task[status]   = "done"   # the target column's `status:`
```

`position` is **1-based** (SortableJS's `newIndex + 1`), which is what
`acts_as_list` and `positioning` expect for `insert_at`. Without
`resource_name:` the params arrive unnamespaced (`position`, `status`). The
Rails side is one member route and a permit:

```ruby
# config/routes.rb
resources :tasks, only: [] do
  patch :move, on: :member
end

# app/controllers/tasks_controller.rb
def move
  task = Task.find(params[:id])
  task.update!(status: params.require(:task)[:status])
  task.insert_at(params.require(:task)[:position].to_i) # acts_as_list

  head :ok # the board already moved the card client-side
end
```

`response_kind: :html` (default) expects any successful response and leaves the
DOM as the drop left it. Use `response_kind: :turbo_stream` when the server
re-renders — e.g. to refresh the per-column count badges and `aria-label`s,
which are server-rendered and go stale after a client-side drop. Cards without
`update_url:` still drag (the DOM moves) but send nothing — fine for a demo,
wrong for persistence.

A column's header indicator is a `Bali::Tag`, so `color:` takes the same semantic names it does (`:neutral :primary :secondary :accent :info :success :warning :error :ghost`) and `custom_color:` takes a hex. A name outside that list raises — the private `BADGE_COLORS` table this component used to keep answered `:ghost` to anything it did not recognise.

**A drop is announced.** Moving a card changes the DOM and nothing else — focus stays put, no
text changes — so the board renders a `role="status" aria-live="polite"` region and writes
into it on every drop: *"Design landing page moved to Done, position 1 of 2"*. The sentence
comes from `bali_view.kanban.card_moved` and is interpolated in the browser.

`label:` on a card is what the announcement calls it. The default is the card's own text,
truncated to 60 characters, which reads badly on a card that leads with a date or an avatar
rather than a title.

Each column's card stack is `role="list"` with an `aria-label` carrying the count
(`bali_view.kanban.column_label`), including `"Backlog, 0 cards"` — an empty column used to
have no badge, no cards and no name at all. Each card is `role="listitem"`. That label is
rendered on the server, so after a client-side drop it is as stale as the count badge next to
it; both refresh when the page does.

The `kanban` Stimulus controller ships in the core bundle and `registerAll` picks it up. An
app that registers controllers one at a time needs `application.register('kanban',
KanbanController)`.

#### ConfirmDialog

DaisyUI-styled `<dialog>` that replaces Turbo's native `window.confirm` for
every `data-turbo-confirm` (including `DeleteLink` and `ActionsDropdown`
delete items). Auto-installed via `registerAll` — no per-app code needed.

```erb
<%# Any turbo confirm gets the styled dialog automatically %>
<%= button_to "Delete", thing_path(thing), method: :delete,
      data: { turbo_confirm: "Delete this thing?" } %>

<%# Per-trigger customization %>
<%= button_to "Close project", close_project_path(project),
      data: {
        turbo_confirm: "Close this project?",
        bali_confirm_title: "Close project",
        bali_confirm_variant: "warning",
        bali_confirm_accept: "Close it"
      } %>
```

Opt out globally with `window.BALI_DISABLE_CONFIRM_DIALOG = true` before
`registerAll` runs.

#### BulkActions

Selectable item list with a floating action bar that appears when items are selected, showing a counter and bulk action buttons.

```erb
<%= render Bali::BulkActions::Component.new do |c| %>
  <% c.with_action(label: 'Archive', href: bulk_archive_users_path, variant: :info) %>
  <% c.with_action(label: 'Delete', href: bulk_delete_users_path, variant: :error) %>

  <% @users.each do |user| %>
    <% c.with_item(record_id: user.id, class: 'flex items-center gap-3 p-3') do %>
      <input type="checkbox" class="checkbox checkbox-sm">
      <p><%= user.name %></p>
    <% end %>
  <% end %>
<% end %>
```

**Options:**
- `variant` - `:floating` (default, fixed bar at the bottom) or `:toolbar` (contextual row
  with a counter, the actions and a clear button — what `DataTable#with_bulk_actions` uses).
  `:floating` wrapped around a `Bali::Table(selectable: true)` is the standalone replacement
  for the `Bali::Table(bulk_actions:)` array removed in v3.
- `standalone` - Emit the `data-controller="bulk-actions"` (default: `true`). `false` when
  the controller already lives on an ancestor, as inside a `DataTable`. Two nested
  `bulk-actions` controllers split the targets between them and the bar stops seeing the
  items, silently.
- `total_count` - Size of the **filtered result**, not of the page. Turns on the "select all
  N results" offer described below (default: `nil`, no offer). A `DataTable` fills it from
  its own `pagy`.
- `filter_params` - The `q[...]` in effect, re-emitted as hidden fields inside every action's
  form. Accepts `[name, value]` pairs or a nested hash (`{ q: { name_cont: 'Iron' } }`). Only
  used together with `total_count`. A `DataTable` fills it from its `filter_form`.
- `**options` - HTML attributes for the wrapper (e.g. `class`, `data`)

**Action options** (`with_action`): `label:`, `href:`, `method:` (default `:post`;
`:get` renders a link instead of a form), `variant:`, `size:`, `target:`, plus a
`with_control` slot. The two below.

Selection is **per page** unless you opt into `total_count:`: the controller only knows the
DOM it was rendered with, so paginating, filtering or switching display mode clears it (all
of those re-render the node that carries the controller). Record ids go through `parseInt`,
so non-numeric ids (UUIDs) serialize as `null` in the `selected_ids` payload.

##### An input that travels with one action

`with_control` mounts your own markup **inside that action's form**, right before the
submit, so its value is posted alongside `selected_ids` with no JavaScript in between —
"assign this driver to the 12 selected shipments" in one submit.

```erb
<% c.with_action(label: 'Assign driver', href: bulk_assign_shipments_path) do |action| %>
  <% action.with_control do %>
    <%= select_tag :driver_id, options_from_collection_for_select(@drivers, :id, :name),
                   class: 'select select-xs', id: nil %>
  <% end %>
<% end %>
```

- A control on a `method: :get` action raises `ArgumentError`: a GET action renders a link,
  and a link has no form to carry the value anywhere.
- **Ids are per document.** Two actions mounting the same widget repeat its id, and the
  `<label for>` of the first one wins. Give each an explicit `id:`, or `id: nil` when there
  is no label pointing at it.

`target:` picks the browsing context — `target: '_blank'` on a "Print" action opens the
result in a new tab and the page keeps its selection, because it never navigates. It reaches
the `<form target>` of a form action and the `<a target>` of a GET one.

##### Nested forms

Every action is its own `<form>`. If the listing already lives inside a form of yours, the
HTML parser hoists the inner ones out and the action silently stops working. Render that
action's form **outside** the listing and point a plain submit at it with the HTML `form`
attribute:

```erb
<%= form_with url: bulk_archive_movies_path, id: 'bulk-archive', class: 'hidden' %>

<%= form_with model: @report do |f| %>
  <%# ... the DataTable lives here ... %>
  <%= render Bali::Button::Component.new(name: 'Archive', form: 'bulk-archive',
                                         type: :submit) %>
<% end %>
```

##### Acting on the whole filtered result

Pass `total_count:` and, once the selection covers the whole page, the bar offers to extend
it to every record the current filters match. Inside a `DataTable` nothing is declared: N
comes from its `pagy` and the filters from its `filter_form`.

Unchecking any row leaves the mode and goes back to page selection (the Gmail behaviour);
the checkboxes are never disabled.

**What the POST carries.** While the mode is on, `selected_ids` goes out **empty** and this
travels instead:

```
select_all_filtered=true
q[g][0][m]=or
q[g][0][name_cont]=Iron
q[status_eq]=draft
```

`select_all_filtered` is `"false"` outside the mode, and the `q[...]` fields are present
either way — the flag is what tells the server whether to read them or to use the ids. They
are the filters **as applied**, not the query string of the request, which is what makes
them right when filter persistence restored the state from cache rather than from the URL.

**Only the `q[...]` travel.** What Bali re-emits is the Ransack state its `FilterForm`
owns: the builder's groups, `filter_attribute` values, simple filters, the quick search and
date ranges. Anything else narrowing your listing — a nav tab, `group_by`, a `?archived=1`
of your own, a scope you apply in the controller before handing the relation over — is
invisible to it and **will not travel**, which is the one way the bulk can still act on a
wider set than the listing showed. (This is narrower on purpose than `preserved_params`,
which preserves the whole query string so a GET filter submit does not lose the page you
were on.) If your listing is cut outside `q`, pass `filter_params:` yourself with those
params added — the option overrides the auto-population.

**On the server, run the same code the index runs.** There is no second query object to
write:

```ruby
def bulk_archive
  movies = if ActiveModel::Type::Boolean.new.cast(params[:select_all_filtered])
    MovieFilterForm.new(policy_scope(Movie), params).result
  else
    policy_scope(Movie).where(id: JSON.parse(params[:selected_ids]))
  end

  movies.update_all(archived_at: Time.current)
  redirect_back fallback_location: movies_path
end
```

Cast the flag; do not just test it for truthiness. It travels on **every** POST, and outside
the mode it travels as the string `"false"` — which is truthy in Ruby. A plain
`if params[:select_all_filtered]` acts on the entire filtered result every single time,
including the POST where the user picked three rows.

Two things to get right at scale:

- **Enqueue instead of blocking.** "All 12,480 results" is not a request-cycle amount of
  work. Pass the params to a job (`BulkArchiveJob.perform_later(current_user, params[:q])`),
  have it rebuild the same scope, and answer immediately with "we are working on it".
- **Confirm the destructive ones.** `data: { turbo_confirm: '...' }` on the action goes
  through Bali's confirm dialog. A mis-click that hits 12,480 records is not undoable by
  reloading.

A GET action has no hidden fields, so it carries the same params in its href; any `q[...]`
the href already had is dropped first, because the listing's current state is the one that
counts.

#### Carousel

Image/content carousel powered by Glide.js with optional arrows, bullets, autoplay, and multi-slide layouts.

```erb
<%= render Bali::Carousel::Component.new(slides_per_view: 3, gap: 16, autoplay: :slow) do |c| %>
  <% c.with_arrows %>
  <% c.with_bullets %>

  <% @images.each do |image| %>
    <% c.with_item do %>
      <%= image_tag image, class: 'w-full rounded-lg' %>
    <% end %>
  <% end %>
<% end %>
```

**Options:**
- `slides_per_view` - Number of slides visible at once (default: `1`)
- `start_at` - Index of the initial slide (default: `0`)
- `autoplay` - `:disabled`, `:slow` (5s), `:medium` (3s), `:fast` (1.5s), or milliseconds (default: `:disabled`)
- `gap` - Space between slides in pixels (default: `0`)
- `focus_at` - Which slide to focus: `:center` or an index (default: `:center`)
- `breakpoints` - Hash of responsive settings passed to Glide.js (default: `nil`)
- `peek` - Pixels of adjacent slides to show at the edges (default: `nil`)

#### Chat

Conversation surface: a scrollable container, a bubble, and a typing indicator. Three
components that compose, so a host that only wants bubbles never mounts the controller.

```erb
<%= turbo_stream_from @conversation %>

<%= render Bali::Chat::Component.new(id: 'messages', class: 'h-[60vh]') do |chat| %>
  <% @messages.each do |message| %>
    <%= render Bali::Chat::Message::Component.new(
          id: dom_id(message),
          position: message.mine? ? :end : :start,
          color: message.mine? ? :primary : nil,
          author: message.author_name,
          timestamp: message.created_at
        ) do |bubble| %>
      <% bubble.with_avatar { render Bali::Avatar::Component.new(initials: message.initials, size: :xs) } %>
      <%= markdown(message.content) %>
    <% end %>
  <% end %>

  <%= render Bali::Chat::TypingIndicator::Component.new %>

  <% chat.with_footer do %>
    <%= render 'form' %>
  <% end %>
<% end %>
```

and the append is an ordinary Turbo Stream against the container's `id`:

```ruby
turbo_stream.append 'messages', partial: 'messages/message', locals: { message: }
```

**`Bali::Chat::Component`** — the scroll region and the append target.

- `id` - DOM id of the scrollable region; what a Turbo Stream appends into (default:
  `'chat-messages'`). One per chat on the page.
- `threshold` - Pixels short of the bottom that still count as "at the bottom"
  (default: `64`)
- `messages_class` - Extra classes for the scrollable region — its padding and the gap
  between messages
- `**options` - HTML attributes for the wrapper. **The height goes here**: the wrapper is a
  flex column with no size of its own, so `class: 'h-[60vh]'` (or a max-height, or a flex
  parent) is what makes the region scroll.
- `with_footer` slot - The composer, rendered below the scroll region with a top border

**The container follows a new message only when the reader was already at the bottom.**
Scrolled up in the history, their position is left alone; back at the bottom, it follows
again. That decision is taken from the position recorded by the last real `scroll` event,
because an append grows `scrollHeight` while `scrollTop` stays put — measuring after the
fact reads "at the bottom" as "scrolled up by exactly the new message".

**`Bali::Chat::Message::Component`** — one bubble, over daisyUI's `chat` grid.

- `position` - `:start` (the other party, left) or `:end` (the reader, right). daisyUI's
  own names, so they flip under `dir="rtl"` without help.
- `color` - daisyUI bubble colour (`:primary`, `:neutral`, `:accent`, …). `nil` keeps the
  default `base-300` bubble.
- `author` / `timestamp` - Fill the header. The timestamp renders as a `<time>` with a
  machine-readable `datetime`; `timestamp_format:` is the `I18n.l` format (default: `:short`).
- `bubble_class` - Extra classes for the bubble: a width cap (`max-w-[82%]`), a border, or
  the `prose` wrapper a Markdown body wants
- `with_avatar` / `with_header` / `with_footer` slots - The `chat-image`, `chat-header` and
  `chat-footer` cells. `with_header` replaces the `author`/`timestamp` pair.

**The body is passed through untouched — no escaping, no sanitising.** Rendering Markdown
from a language model, and cleaning it, stays with the host, which is where the policy
belongs. Pass content you have already made safe.

**`Bali::Chat::TypingIndicator::Component`** — the "…is typing" bubble.

- `id` - DOM id and Turbo Stream target (default: `'chat-typing-indicator'`)
- `visible` - Whether it starts shown (default: `false`)
- `position` / `color` / `author` / `bubble_class` / `with_avatar` - As on the bubble, so
  the indicator matches the message it stands in for
- `label` - What it announces; read by screen readers whether or not it is drawn, since
  three dots say nothing (default: from the locale files)
- `show_label` - Also draw the label next to the dots (default: `false`)

**It stays in the DOM and hides behind a class.** Toggle it from the server by replacing it
with itself:

```erb
<%= turbo_stream.replace 'chat-typing-indicator' do %>
  <%= render Bali::Chat::TypingIndicator::Component.new(visible: true) %>
<% end %>
```

Removing it instead would destroy the very id the next stream targets, and every later
replace would silently do nothing. From the page, the container's controller toggles it —
the indicator registers itself as a `chat` target, so a composer can do
`data: { action: 'turbo:submit-end->chat#showTyping' }`. `chat#showTyping` also scrolls
down unconditionally: sending is participating, not reading.

#### Clipboard

Copy-to-clipboard button with visual success feedback (shown for 2 seconds after copying).

```erb
<%= render Bali::Clipboard::Component.new do |c| %>
  <% c.with_trigger('Copy') %>
  <% c.with_success_content('Copied!') %>
  <% c.with_source('https://example.com/api/v1/token/abc123xyz') %>
<% end %>
```

**Options:**
- `**options` - HTML attributes for the wrapper; customize feedback duration with `data: { clipboard_success_duration_value: 3000 }`

#### DeleteLink

Delete button that submits a DELETE request and automatically triggers the styled ConfirmDialog (danger variant) before submitting.

```erb
<%= render Bali::DeleteLink::Component.new(model: @movie) %>
<%= render Bali::DeleteLink::Component.new(href: movie_path(@movie), name: 'Remove', size: :sm, icon: true) %>
<%= render Bali::DeleteLink::Component.new(href: movie_path(@movie), style: :outline, icon: 'circle-x') %>
```

**Options:**
- `model` - Record used to build the URL and the confirmation message (default: `nil`)
- `href` - Explicit URL; either `model` or `href` is required (default: `nil`)
- `name` - Button label (default: translated "Delete")
- `confirm` - Custom confirmation message (default: `nil`, generated from model)
- `variant` - Colour, from the shared taxonomy (default: `:ghost`)
- `style` - `:outline` or `:soft` (default: `nil`)
- `size` - `:xs`, `:sm`, `:md`, `:lg`, `:xl` (default: `nil`)
- `disabled` - Disable the button (default: `false`)
- `disabled_hover_url` - URL for a hover card explaining why deletion is disabled (default: `nil`)
- `skip_confirm` - Skip the confirmation dialog (default: `false`)
- `icon` - `true` for the trash icon, or the name of any other icon (default: `false`)
- `authorized` - When `false`, the component does not render (default: `true`)
- `plain` - Render as a plain text link instead of a button (default: `false`)
- `form_class` - Extra classes for the wrapping form (default: `nil`)

The destructive red is `text-error` on top of `variant: :ghost`, the default. It also
applies to `variant: :link`; those two are the variants with no colour of their own. Name
any other colour and it owns the button.

Disabled renders `<button aria-disabled="true">`, focusable and inert, not the `<a disabled>`
it used to be — HTML has no `disabled` attribute on an anchor. It stays in the tab order on
purpose, because the hover card is where the reason lives.

#### HoverCard

Popup card that displays content on hover (or click), positioned with Tippy.js. Content can be inline or lazy-loaded from a URL.

```erb
<%= render Bali::HoverCard::Component.new(placement: 'top', hover_url: user_summary_path(@user)) do |c| %>
  <% c.with_trigger do %>
    <button class="btn btn-primary">Hover me!</button>
  <% end %>
<% end %>
```

**Options:**
- `hover_url` - URL to fetch content from asynchronously (default: `nil`)
- `placement` - Tippy.js placement, e.g. `auto`, `top`, `bottom-start`, `right-end` (default: `"auto"`)
- `open_on_click` - Open on click instead of hover (default: `false`)
- `append_to` - Where to append the popup: `'body'`, `'parent'`, or CSS selector (default: `"body"`)
- `z_index` - Z-index for the popup (default: `9999`)
- `content_padding` - Add padding around the content (default: `true`)
- `arrow` - Show an arrow pointing to the trigger (default: `true`)

#### Reveal

Collapsible content section toggled by a trigger with a rotating chevron indicator.

```erb
<%= render Bali::Reveal::Component.new(opened: false) do |c| %>
  <% c.with_trigger do |trigger| %>
    <% trigger.with_title do %>
      <span class="text-lg font-semibold">Click to see contents</span>
    <% end %>
  <% end %>

  <p>This content is hidden until you click the trigger above.</p>
<% end %>
```

**Options:**
- `opened` - Render with the content revealed initially (default: `false`)

#### SortableList

Drag-and-drop sortable list using SortableJS; supports handles, nested lists, and cross-list moves — this component powers the Kanban board. Dropping an item sends a PATCH to that item's `update_url` with its new `position` (and `list_id` for cross-list moves).

```erb
<%= render Bali::SortableList::Component.new(group_name: 'tasks', list_id: list.id) do |s| %>
  <% @tasks.each do |task| %>
    <% s.with_item(update_url: task_path(task)) do %>
      <%= task.name %>
    <% end %>
  <% end %>
<% end %>
```

**Options:**
- `resource_name` - Resource name to namespace params, e.g. `'task'` sends `task[position]` (default: `nil`)
- `position_param_name` - Name of the position param sent to the server (default: `"position"`)
- `list_param_name` - Name of the list param sent to the server (default: `"list_id"`)
- `group_name` - Group name linking multiple lists so items can move between them (default: `nil`)
- `list_id` - Identifier for this list in cross-list moves (default: `nil`)
- `response_kind` - `:html` or `:turbo_stream` (default: `:html`)
- `handle` - CSS selector for the drag handle; without one, whole items are draggable (default: `nil`)
- `disabled` - Disable dragging (default: `false`)
- `animation` - Drag animation duration in milliseconds (default: `150`)

---

### Form Components

#### Filters

Advanced filter controls for data tables with Ransack integration. Every condition
compiles to a `q[...]` param — to filter by an attribute that is not a column (a value
derived in Ruby), see the [derived attributes guide](derived-filters.md): a `ransacker`
makes it a first-class popover attribute with no new API.

```erb
<%= render Bali::Filters::Component.new(
  url: products_path,
  filter_form: @filter_form,
  available_attributes: [
    { key: :name, label: 'Name', type: :text },
    { key: :status, label: 'Status', type: :select, options: Status.options }
  ]
) %>
```

**Features:**
- Multiple filter groups with AND/OR combinators
- Type-specific operators (text, number, date, select, boolean)
- Quick search with clear button (x) for easy clearing
- Filter persistence with bookmark toggle. Inside a `DataTable` the bookmark is painted
  by the toolbar as its own control and the panel receives `persistence_toggle: false`:
  two `filter-persistence` controllers over one `storage_id` fight over localStorage and
  the cookie. The panel's "Auto-saved" hint does not depend on the toggle. Persistence
  reads and writes `Rails.cache`, so it needs a real cache store: under `:null_store` —
  which is what a generated `development.rb` uses unless `tmp/caching-dev.txt` exists —
  every write is silently dropped and nothing is ever restored.

  **Wire it with `Bali::Filterable` (#999).** Persistence needs three things only the
  request can answer — `storage_id`, `context:` and `persist_enabled:` — and forgetting any
  of them renders perfectly and never restores. The concern closes the circuit:

  ```ruby
  class ApplicationController < ActionController::Base
    include Bali::Filterable
  end

  # In the action — storage_id derives from controller_path, persist_enabled from the
  # toggle's cookie, context from Bali.filter_context (current_user&.id by default):
  @filter_form = filter_form(AccountsFilterForm, policy_scope(Account))
  ```

  Every explicit kwarg still wins (`storage_id: "bulk_provision_#{@app.id}"`, `context:`,
  `persist_enabled:`, and anything the form takes). Configure the identity once:
  `Bali.filter_context = ->(controller) { controller.current_account&.id }`. A DataTable
  whose toggle is about to render over a form nobody wired warns in dev/test.
- Date range "between" operator with Flatpickr

**Modes:**
- `popover: true` (default) - Compact dropdown with search input
- `popover: false` - Inline card layout

**Search Clear Button:**

The search input includes a clear button (x) that appears when text is entered. Clicking it:
- Clears the search input
- Submits `clear_search=1` to clear persisted search
- Preserves other filters

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `url` | String | Required | Form action URL |
| `filter_form` | FilterForm | Required | FilterForm instance |
| `available_attributes` | Array | Required | Filterable attributes (`filter_form.available_attributes` when driven by a FilterForm) |
| `popover` | Boolean | `true` | Use popover mode |
| `storage_id` | String | `nil` | Enable persistence |
| `persistence_toggle` | Boolean | `true` | Render the bookmark inside the panel (DataTable turns it off) |

#### Quick search (`search:`)

Both filter surfaces — the `Filters` panel and `DataTable`'s `SimpleFilters` — take the same
`search:` hash. You declare the **columns**; Bali derives the Ransack parameter from them
(`[:name, :email]` becomes `q[name_or_email_cont]`), so a listing that moves from one surface
to the other keeps searching the same thing.

| Key | Type | Description |
|--------|------|-------------|
| `fields` | Array&lt;Symbol&gt; | Columns to search. Absent or empty, no search box renders |
| `value` | String | Current search value, rendered back into the box |
| `placeholder` | String | Placeholder text |
| `label` | String | Accessible name for the input |
| `icon` | String | Icon name — the submit button in `Filters`, a leading addon in `SimpleFilters` |
| `width` | String | Tailwind width classes for the box |

```erb
<%= render Bali::Filters::Component.new(
  url: movies_path,
  available_attributes: [...],
  search: { fields: %i[name genre], value: params.dig(:q, :name_or_genre_cont) }
) %>
```

A `FilterForm` that declares `search_fields` fills this in on its own — including `label:`
(the box's `aria-label`, the only accessible name that survives typing) and `width:` since
v3.1 (#982): `search_fields :name, :email, icon: 'search', label: t('.search_label')`. Inside
a `DataTable` the hash is only for overrides:

```erb
<% dt.with_simple_filters(search: { placeholder: 'Search movies...' }) %>
```

Any key outside that table raises `ArgumentError`. For a standalone search box not attached to
a filter panel, use the FormBuilder's `search_group`.

#### Calendar

Month, week, or day calendar that displays events grouped by date, with optional navigation header and custom day templates.

```erb
<%= render Bali::Calendar::Component.new(
  start_date: Date.current,
  period: :month,
  events: @events,
  template: 'events/calendar_event'
) do |c| %>
  <% c.with_header(route_path: events_path) %>
  <% c.with_footer { 'Custom footer content' } %>
<% end %>
```

**Options:**
- `template` - Path to an HTML partial rendered for each day's events (default: nil)
- `start_date` - Date or string to center the calendar on (default: `Date.current`)
- `period` - Calendar view, one of `:month`, `:week`, or `:day` (default: `:month`)
- `events` - Array of events; each must respond to `start_attribute` (default: `[]`)
- `start_attribute` - Method called on each event for its start date (default: `:start_time`)
- `end_attribute` - Method called on each event for its end date, enables multi-day events (default: `:end_time`)
- `weekdays_only` - Show only Monday-Friday (default: false)
- `show_date` - Display the day number in each cell (default: true)
- `weekly_title_class` - Extra classes for the day number, aimed at week view (default: nil)

**Slots:** `header` (navigation with period switch, accepts `route_path:` and `period_switch:`), `footer`.

`start_date` and `period` normally arrive from the query string — the header's prev/next
and period links write them back to `route_path` — so both degrade rather than raise:
anything `Date.parse` cannot read becomes `Date.current`, and any period outside
`:month`/`:week`/`:day` becomes `:month`. Handing `params[:start_time]` straight to the
component is safe.

The component renders its own `Bali::Card`, so do not wrap it in another one.

#### ImageField

Image preview with an optional file input overlay for uploading/replacing an image, plus a hover clear button.

```erb
<%= form_with(model: @user) do |f| %>
  <%= render Bali::ImageField::Component.new(src: @user.avatar_url, size: :lg) do |c| %>
    <% c.with_input(form: f, method: :avatar) %>
  <% end %>
<% end %>
```

**Options:**
- `src` - URL of the current image; falls back to the placeholder when nil (default: nil)
- `placeholder_url` - Image shown when there is no `src` or after clearing (default: `https://placehold.jp/128x128.png`)
- `size` - One of `:xs`, `:sm`, `:md`, `:lg`, `:xl` (default: `:md`)
- `**options` - Additional HTML attributes for the container (e.g. `class`)

**Slots:** `input` (file input, takes `form:` and `method:`), `clear_button` (override the default clear button).

#### RichTextEditor

**Deprecated in v3, removed in v4 — use [BlockEditor](#blockeditor) for new work.** It ships
behind `Bali.rich_text_editor_enabled`, which defaults to `false`: with the flag off the
component renders nothing at all.

TipTap-based rich text editor for editing or displaying HTML content, with a hidden input for form submission.

```erb
<%= render Bali::RichTextEditor::Component.new(
  html_content: @post.body,
  output_input_name: 'post[body]',
  editable: true,
  placeholder: 'Start typing...'
) %>
```

**Options:**
- `html_content` - Initial HTML content to load into the editor (default: nil)
- `output_input_name` - Name of the hidden input that receives the edited HTML (default: nil)
- `editable` - Enable editing; false renders read-only content (default: false)
- `placeholder` - Placeholder text shown when empty (default: "Start typing...")
- `images_url` - Endpoint for image uploads (default: nil)
- `page_hyperlink_options` - Options for internal page hyperlinks (default: `[]`)

Only renders when `Bali.rich_text_editor_enabled` is true.

#### DirectUpload

Uploads files from the browser directly to cloud storage (S3, GCS, Azure) via Active Storage's DirectUpload API, with drag & drop, progress, and client-side validation.

```erb
<%= form_with(model: @document) do |f| %>
  <%= render Bali::DirectUpload::Component.new(
    form: f,
    method: :attachments,
    multiple: true,
    max_files: 5,
    accept: 'application/pdf,image/*'
  ) %>
<% end %>
```

**Options:**
- `form` - Rails form builder object (required)
- `method` - Attachment attribute name, e.g. `:file`, `:images` (required)
- `multiple` - Allow selecting multiple files (default: false)
- `max_files` - Maximum number of files when `multiple: true` (default: 10)
- `max_file_size` - Maximum file size in megabytes (default: 10)
- `accept` - Accepted file types, MIME types or extensions (default: `"*"`)
- `drop_zone` - Show the drag & drop area (default: true)
- `auto_upload` - Upload files immediately on selection (default: true)

Requires Active Storage and CORS configuration on the bucket — see the [DirectUpload setup guide](direct-upload-setup.md). Client-side validation is UX only; always validate on the server.

#### RecurrentEventRuleForm

Form control for building RFC 5545 RRULE strings (e.g. `FREQ=WEEKLY;BYDAY=MO,WE,FR`) with controls for frequency, interval, weekdays, and end conditions.

```erb
<%= form_with(model: @event, builder: Bali::FormBuilder) do |form| %>
  <%= render Bali::RecurrentEventRuleForm::Component.new(
    form: form,
    method: :schedule,
    value: 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR;COUNT=10'
  ) %>
<% end %>
```

Also available through the form builder as `form.recurrent_event_rule_field :schedule` or `form.recurrent_event_rule_group :schedule`.

**Options:**
- `form` - The form builder instance (required)
- `method` - The attribute name, e.g. `:schedule` (required)
- `value` - Pre-populate with an existing RRULE string (default: nil)
- `disabled` - Disable all form controls (default: false)
- `skip_end_method` - Hide the "End" section for rules that never end (default: false)
- `frequency_options` - Array of allowed frequencies from `yearly`, `monthly`, `weekly`, `daily`, `hourly` (default: all)

---

### Feedback Components

#### Toast

An `Alert` that closes itself. Put it inside a `ToastContainer` to float it over the
page — positioning is the container's job.

```erb
<%= render Bali::Toast::Component.new(color: :success) do %>
  Changes saved successfully!
<% end %>

<%= render Bali::Toast::Component.new(color: :error, duration: nil) do %>
  <strong>Error:</strong> Please fix the following issues.
<% end %>
```

**Options:**
- `color` - `:neutral`, `:info`, `:success`, `:warning`, `:error` (default: `:info`)
- `duration` - Milliseconds before it closes itself; `nil` never does (default: `3000`)
- `closable` - Render the close button (default: `true`)
- `icon` - `true` for the icon that goes with the colour, a name for a specific one,
  `nil` for none (default: `true`)
- `title`, `style`, `role` - forwarded to `Bali::Alert`

#### Loader

Loading indicator.

```erb
<%= render Bali::Loader::Component.new(size: :lg, color: :primary) %>
```

#### ToastContainer

The fixed stack a `Toast` lives in. Give it the whole flash hash and every key it
recognises comes out as a toast; `Bali::AppLayout` renders one for you.

```erb
<%= render Bali::ToastContainer::Component.new(flash: flash) %>

<%= render Bali::ToastContainer::Component.new(position: :top_end) do |c| %>
  <% c.with_toast(color: :info) { 'One toast.' } %>
<% end %>
```

**Options:**
- `flash` - The flash hash. `notice`/`success` render as success, `alert`/`error`/`danger`
  as error, and `warning`/`info` as themselves; any other key is ignored (default: `nil`)
- `position` - One of `top`/`middle`/`bottom` crossed with `start`/`center`/`end`,
  e.g. `:top_end` (default: `:bottom_end`)
- `duration` - Passed down to every toast it builds from the flash (default: `3000`)

#### Alert

Inline alert box (DaisyUI `alert`) with an optional title or custom header slot.

```erb
<%= render Bali::Alert::Component.new(title: 'Heads up', color: :warning, style: :soft) do %>
  Your subscription expires in 3 days.
<% end %>
```

**Options:**
- `title` - Header text shortcut; use the `with_header` slot for custom markup (default: `nil`)
- `size` - Text size: `:small`, `:regular`, `:medium`, `:large` (default: `:regular`)
- `color` - Alert color: `:neutral`, `:info`, `:success`, `:warning`, `:error` (default: `:info`).
  daisyUI has no other alert colours; an unknown name raises
- `style` - Alert style: `:soft`, `:outline`, `:dash` (default: `nil`, solid)
- `icon` - `true` for the icon that goes with the colour, a name for a specific one,
  `nil` for none (default: `nil`)
- `closable` - Render a close button wired to the `alert` Stimulus controller (default: `false`)
- `dismiss_id` - Remember the dismissal in localStorage under this key (default: `nil`)
- `duration` - Milliseconds before it closes itself; this is what makes a `Toast` (default: `nil`)
- `role` - `:alert`, `:status` or `:note`. Without it, `:alert` for `color: :error` and
  `:status` for everything else

#### EmptyState

Standard empty state: a centered block with an optional icon in a soft circle, a title, an optional description and an optional CTA. Use it anywhere a section has nothing to show yet (grids, panels, tabs, kanban columns) so every blank state looks the same. `Bali::Table` renders its built-in empty state through this component, so tables and standalone sections match.

```erb
<%= render Bali::EmptyState::Component.new(
      icon: 'inbox',
      title: t('.empty_title'),
      description: t('.empty_description')) do |empty_state| %>
  <% empty_state.with_cta do %>
    <%= render Bali::Link::Component.new(
          name: t('.new'), href: new_thing_path,
          icon: 'plus', variant: :primary, size: :sm) %>
  <% end %>
<% end %>
```

**Options:**
- `title` - Main message (required)
- `description` - Muted secondary line below the title (default: `nil`)
- `icon` - Icon name rendered inside a soft `bg-base-200` circle (default: `nil`)
- `size` - Vertical padding and icon scale: `:sm` (compact, for cells/panels), `:md`, `:lg` (full page) (default: `:md`)
- `**options` - Additional HTML attributes for the wrapper `div` (e.g. `id:`, extra `class:`)

**Slots:**
- `with_cta` - Optional call-to-action (a `Bali::Link`, button, drawer trigger, etc.) rendered below the text

#### FeedbackWidget

Floating feedback button that opens a `Bali::Drawer` with an embedded Opina iframe, and
polls a badge endpoint for the unread count.

The embed's JWT is **not** passed in the frame's URL — a bearer credential in a URL is
written to the server's access log, offered in the `Referer` of anything the embed loads,
and kept in browser history. The widget sends it to the frame with `postMessage` once it
has loaded, as `{ type: 'bali:feedback:token', token }`, addressed to the Opina origin and
never to `*`. The Opina instance has to listen for that message; see the migration guide.

```erb
<%= render Bali::FeedbackWidget::Component.new(
  project_slug: 'my-project',
  opina_url: 'https://opina.example.com',
  secret: Rails.application.credentials.opina_secret,
  user_id: current_user.id,
  email: current_user.email
) %>
```

**Options:**
- `project_slug` - The project slug in Opina (required)
- `opina_url` - Base URL of the Opina instance (required)
- `token` - Pre-built JWT token for embed authentication (default: `nil`)
- `secret` - Opina shared secret to generate the token automatically (default: `nil`; either `token` or `secret` is required)
- `user_id` - User ID for token generation, required when using `secret` (default: `nil`)
- `email` - User email for token generation, required when using `secret` (default: `nil`)
- `user_name` - User display name for token generation (default: `nil`)
- `title` - Drawer header title (default: `nil`, falls back to "Feedback")
- `token_expires_in` - Token expiry in seconds (default: `3600`)
- `badge_interval` - Polling interval in ms for the badge count (default: `300000`)

---

### Documents & Editors

#### BlockEditor

Notion-style block editor (BlockNote) with rich text, slash commands, mentions, entity references, comments, and PDF/DOCX export. See the [BlockEditor API](../api/block-editor.md) for the full reference.

```erb
<%= render Bali::BlockEditor::Component.new(
  editable: true,
  placeholder: 'Start writing...',
  input_name: 'document[content]',
  initial_content: @document.content,
  mentions_url: '/users',
  export: true
) %>
```

**Options:**
- `initial_content` - Initial document as BlockNote JSON (Hash/Array or JSON string) (default: nil)
- `input_name` - Hidden input name for form submission (default: nil)
- `format` - Serialization format for the hidden input, `:json` or `:html` (default: :json)
- `editable` - Whether the editor accepts input (default: true)
- `placeholder` - Placeholder text for the empty editor (default: nil)
- `upload_url` - Image upload endpoint; `:auto` resolves the engine's upload route (default: :auto)
- `export` - Enable export; `true` for PDF+DOCX or an array like `[:pdf]` (default: false)
- `comments` - Inline comments config hash (`url:`, `user:`, `users:`) (default: false)

See the component class for the full list (`ai_url`, `mentions`, `references_url`, `multi_column`, `table_of_contents`, `theme`, ...).

#### DocumentEditor

Full-screen document editing overlay wrapping BlockEditor with app bar, table of contents, comments sidebar, version history (preview and restore past versions), auto-save, and Cmd+S manual save.

Comments and export are BlockEditor concerns and travel inside `config:` — passed as
top-level keywords they fall into `**options` and are painted as HTML attributes, with
neither feature enabled and no warning.

```erb
<%= render Bali::DocumentEditor::Component.new(
  title: @document.title,
  initial_content: @document.content,
  document_url: document_path(@document),
  close_url: document_path(@document),
  versions_url: document_versions_path(@document),
  config: {
    comments: { url: '/block_editor_comments', user: current_user_json, users: users_json },
    export: true
  }
) do |editor| %>
  <% editor.with_toolbar do %>
    <span class="badge badge-ghost">Draft</span>
  <% end %>
<% end %>
```

**Options:**
- `title` - Document title shown in the app bar (required)
- `initial_content` - Document content as BlockNote JSON (required)
- `document_url` - URL where saves are PATCHed (required)
- `close_url` - URL for the close button (default: document_url)
- `versions_url` - Version history endpoint; enables the versions panel with preview/restore (default: nil). Pass `:auto` to use the mounted engine's own endpoint (see the content versions section of `engines.md`), which also requires `record:`
- `restore_version_url` - Where a restore is POSTed; also accepts `:auto` (default: `"#{document_url}/restore_version"`)
- `record` - The versioned record, used only to resolve the `:auto` URLs. Without it the history panel does not render
- `editable` - Read-only when false (default: true)
- `auto_save` - Save automatically while editing (default: true)
- `auto_save_delay` - Auto-save debounce in ms (default: 30000)

See the component class for the full list (`comments`, `export`, `input_name`, `ai_url`, `mentions_url`, `references_url`, ...).

#### DocumentPage

Document-centric page with a three-panel layout: table of contents, read-only BlockEditor content, and a collapsible metadata panel.

```erb
<%= render Bali::DocumentPage::Component.new(
  title: 'Q2 2026 Product Roadmap',
  subtitle: 'Last edited 2 hours ago',
  breadcrumbs: [{ name: 'Documents', href: documents_path }, { name: 'Roadmap' }],
  initial_content: @document.content
) do |page| %>
  <% page.with_title_tag do %>
    <%= render Bali::Tag::Component.new(text: 'Published', color: :success, size: :sm) %>
  <% end %>
  <% page.with_action do %>
    <%= render Bali::Link::Component.new(name: 'Edit', href: edit_document_path(@document), variant: :ghost, icon: 'pencil') %>
  <% end %>
  <% page.with_metadata do %>
    <p>Owner: Ana</p>
  <% end %>
<% end %>
```

**On top of [the shared surface](#the-shared-surface)** (`DocumentPage` is a page template;
its options live there too):
- `initial_content` - BlockNote JSON; renders the editor and TOC when present (default: nil)
- `toc_open` / `metadata_open` - Initial panel visibility (default: true)
- `with_metadata` / `with_subheader` slots, plus any leftover keyword becoming an HTML
  attribute on the container

The content slot is `with_body`, like the other four. It was called `with_preview` in v2 —
that name still works and warns through `Bali.deprecator` until 4.0. With `initial_content`
the three-panel layout takes over and `body` is not rendered; the `sidebar` slot is the
simple layout's only, since the panels are the wide layout's own columns.

---

### Page Templates

#### The shared surface

The five page templates (`DashboardPage`, `DocumentPage`, `FormPage`, `IndexPage`,
`ShowPage`) include `Bali::PageComponents::Shared`, which is where every option and slot
below is defined. Learn it once; the per-component sections that follow only list what each
one adds.

**Options:**
- `title` - Page title (required)
- `subtitle` - Text under the title (default: nil)
- `breadcrumbs` - Array of `{ name:, href:, icon: }` hashes (default: [])
- `back` - Back link, e.g. `{ href: path }` (default: nil)
- `max_width` - Content width: `:sm` (`max-w-xl`), `:md` (`max-w-3xl`), `:lg`
  (`max-w-5xl`), `:xl` (`max-w-7xl`), `:"2xl"` (`max-w-screen-2xl`) or `:full`. The default
  is `:full` — a no-op, so the page is as wide as the container the app already put it in —
  except `FormPage` (`:md`), because a single column of fields stretched across a wide
  screen is the wrong shape. An unknown value raises `ArgumentError`.
- `sidebar_width` - Share of the grid the sidebar takes when the `sidebar` slot is filled:
  `:default` (a third), `:narrow` (a quarter) or `:wide` (a half). Below `lg` the sidebar
  always stacks under the body.
- `context` - Where the page is rendering: `:auto` (default), `:page` or `:drawer`. See
  [One view for the page and the drawer](#one-view-for-the-page-and-the-drawer).

**Slots:**
- `with_action` (many) - Primary actions, top right
- `with_secondary_action` (many) - Actions that live in the `⋯` menu next to them; see
  [Secondary page actions and export](#secondary-page-actions-and-export)
- `with_export(url:, formats:, params:)` - Export section inside that same `⋯`
- `with_title_tag` (many) - Badges rendered beside the title
- `with_nav` - Second-level navigation between the header and the body; see
  [Two-level navigation](#two-level-navigation-nav-slot)
- `with_body` - The page content, `mt-6` under whatever precedes it
- `with_sidebar` - Right-hand column; turns the body into the two-column grid

#### DashboardPage

Dashboard layout with page header, stat cards grid, and a body area for charts and cards.

```erb
<%= render Bali::DashboardPage::Component.new(title: 'Dashboard', subtitle: 'Welcome back, Ana') do |page| %>
  <% page.with_action do %>
    <%= render Bali::Button::Component.new(name: 'Export', variant: :ghost, icon: 'download') %>
  <% end %>
  <% page.with_stat(label: 'Total Movies', value: '1,234', icon: 'film', color: :primary) %>
  <% page.with_stat(label: 'Revenue', value: '$45.2K', icon: 'dollar-sign', color: :success, change: '+12.5%') %>
  <% page.with_body do %>
    <%= render Bali::Card::Component.new(style: :bordered) { 'Recent activity...' } %>
  <% end %>
<% end %>
```

**On top of [the shared surface](#the-shared-surface):**
- `stats_columns` - Stat cards per row: 2, 3, or 4 (default: 4)
- `with_stat(label:, value:, icon:, change:, color:, href:)` - One `Bali::StatCard` per
  call. `change` becomes the card's footer; `href` makes that whole card a link (the
  StatCard renders as an `<a>`).

The `nav` slot lands between the header and the stats.

#### IndexPage

Standard listing page with breadcrumbs, title, action buttons, and a body area for tables.

```erb
<%= render Bali::IndexPage::Component.new(
  title: 'Movies',
  subtitle: '24 movies total',
  breadcrumbs: [{ name: 'Dashboard', href: root_path, icon: 'home' }, { name: 'Movies' }]
) do |page| %>
  <% page.with_action do %>
    <%= render Bali::Link::Component.new(name: 'New Movie', href: new_movie_path, variant: :primary, icon: 'plus') %>
  <% end %>
  <% page.with_body do %>
    <%# DataTable goes here %>
  <% end %>
<% end %>
```

Nothing beyond [the shared surface](#the-shared-surface).

The body takes the DataTable **bare**: the surface travels with the DataTable's content
slot, so wrapping it in a `Bali::Card` produces a card inside a card in grid mode. The
canonical composition — page chrome plus a DataTable with the seven toolbar control
families, row selection and pagination — is the `Complete` scenario of the IndexPage
preview (`bali/index_page/complete` in Lookbook). Copy that.

#### ShowPage

Record detail page with breadcrumbs, title with tags, actions, and an optional two-column layout with sidebar.

```erb
<%= render Bali::ShowPage::Component.new(
  title: 'The Matrix',
  subtitle: 'Added 2 days ago',
  breadcrumbs: [{ name: 'Movies', href: movies_path }, { name: 'The Matrix' }],
  back: { href: movies_path }
) do |page| %>
  <% page.with_title_tag do %>
    <%= render Bali::Tag::Component.new(text: 'Released', color: :success, size: :sm) %>
  <% end %>
  <% page.with_action do %>
    <%= render Bali::Link::Component.new(name: 'Edit', href: edit_movie_path(@movie), variant: :ghost, icon: 'pencil') %>
  <% end %>
  <% page.with_body do %>
    <%= render Bali::Card::Component.new(style: :bordered) { 'Details...' } %>
  <% end %>
  <% page.with_sidebar do %>
    <%= render Bali::Card::Component.new(style: :bordered) { 'Stats...' } %>
  <% end %>
<% end %>
```

Nothing beyond [the shared surface](#the-shared-surface).

#### FormPage

New/edit page that wraps form content in a centered Card, with an optional sidebar column for help text.

```erb
<%= render Bali::FormPage::Component.new(
  title: 'New Movie',
  breadcrumbs: [{ name: 'Movies', href: movies_path }, { name: 'New' }],
  back: { href: movies_path }
) do |page| %>
  <% page.with_body do %>
    <%= form_with model: @movie do |f| %>
      <%# form fields %>
    <% end %>
  <% end %>
  <% page.with_sidebar do %>
    <p class="text-base-content/60">Tips for filling out this form.</p>
  <% end %>
<% end %>
```

**On top of [the shared surface](#the-shared-surface):**
- `card` - Wrap the body in a Card. Defaults to `nil`, which lets `context` decide: a page
  gets the Card, a drawer does not. An explicit `true`/`false` always wins. `max_width`
  defaults to `:md` here.

#### One view for the page and the drawer

`context:` lets one template serve a full page and a Modal/Drawer, so a `new`/`edit`/`show`
view does not need an `if drawer_request?` around two nearly identical renders.

```erb
<%= render Bali::FormPage::Component.new(
  title: t('.title'),
  back: { href: movies_path }
) do |page| %>
  <% page.with_body do %>
    <%= render 'form', movie: @movie, drawer: page.drawer? %>
  <% end %>
<% end %>
```

| value | meaning |
|---|---|
| `:auto` | the default: ask the request |
| `:page` | full page chrome, whatever the request says |
| `:drawer` | overlay chrome, whatever the request says |

In a drawer the component drops the **breadcrumbs**, the **back button** and — on `FormPage`
— the **Card**. The first two are ways out of a page, and a drawer is closed rather than
left; the Card is the panel the drawer already draws. They are dropped even when passed,
which is the point: the one surviving call site passes `back:`.

**How `:auto` decides.** It asks the view context for `drawer_request?`, which
`Bali::LayoutConcern` defines as `params[:layout] == "false"` and exposes as a helper — so
the component never reads `params` itself. An app that already declares its own
`drawer_request?` helper is detected with no change to its controllers; a view context with
no such helper (a Lookbook preview, a unit test) renders a page.

```ruby
class ApplicationController < ActionController::Base
  include Bali::LayoutConcern
end

module Admin
  class BaseController < ApplicationController
    # NOT `layout 'admin'` — a `layout` call in a subclass overrides the concern's and
    # takes the layout skipping with it.
    self.conditional_layout = 'admin'
  end
end
```

**Escape hatches.** `card:` always wins, `card: true` inside a drawer included. For the
breadcrumbs and the back button the hatch is `context: :page`, which restores the whole page
chrome inside a drawer request; `context: :page, card: false` combines them.

**When you still have to branch.** `page.drawer?` is public and yielded with the component,
for differences that are behavioural rather than chrome — a Cancel that closes an overlay and
a Cancel that navigates are two different elements. Pass it into partials rather than reading
`params` there.

#### Secondary page actions and export

All five page components (`IndexPage`, `ShowPage`, `FormPage`, `DashboardPage`,
`DocumentPage`) share one hole for **secondary** actions: a `⋯` menu rendered next to the
primary action, inside the same group. Use it for what acts ON the page but does not
deserve a button of its own — export, import, print.

```erb
<%= render Bali::IndexPage::Component.new(title: 'Movies') do |page| %>
  <% page.with_action do %>
    <%= render Bali::Link::Component.new(name: 'New Movie', href: new_movie_path, variant: :primary) %>
  <% end %>

  <% page.with_export(url: movies_path) %>
  <% page.with_secondary_action(name: 'Import', icon: 'upload', href: import_movies_path) %>

  <% page.with_body do %>
    <%# DataTable goes here %>
  <% end %>
<% end %>
```

`with_secondary_action(**options, &block)` takes the same options as
`Bali::Dropdown#with_item` (`href:`, `icon:`, `method:`, `tag: :link | :button |
:title`, `authorized:`), because it *is* an item of that dropdown. The `⋯` is not rendered
when nothing is declared — a button that opens an empty menu is a bug.

**`with_export(url:, formats: %i[csv excel pdf], params: nil)`** renders a section titled
*Export filtered* with one item per format. The name is a promise the links keep: each href
carries the same slice of data the user is looking at — filters, search, sort, grouping and the applied
saved view — merged from the current query string. Two parameters are deliberately dropped
(`Bali::DataTable::ToolbarHref::TRANSIENT_PARAMS`): `page`, because exporting page 3 of a
listing is never what "export" means, and `clear_filters`, which on the server *deletes* the
user's stored filters as a side effect of the click. Pass `params: {}` to opt out and export
everything on purpose, or an explicit hash to override.

Export is **not** a DataTable toolbar control. It acts on the page, not on how the listing
looks, which is also what gives import and print somewhere to land later. Because the `⋯`
lives in the PageHeader — outside the node a filter submit's turbo-stream replaces — the
links carry an `export-links` Stimulus controller that re-syncs their hrefs from
`window.location`, on connect and on `turbo:load` / `turbo:before-stream-render` /
`turbo:submit-end`. A stream render is not a visit, so `turbo:load` alone never fires for
the case that matters and the first filter would freeze the links on the slice of the
initial page load — the exact bug they exist to fix. The re-sync **merges** over the link's
own query string rather than replacing it, so params baked into `url:` survive, and it is
switched off entirely when you passed `params:` yourself: that href is your decision, not a
photo of the URL.

The host still has to answer the format: a controller whose `respond_to` only declares
`html` returns **406** for `?format=csv`.

#### Two-level navigation (`nav` slot)

All five page templates accept a `nav` slot rendered **between the PageHeader and the body**
(in `DashboardPage`, before the stat cards) with standardized spacing (`mt-4`), so section
navigation no longer needs to be embedded in the body by hand. `FormPage` and `DocumentPage`
gained it in v3, when the slot moved into `PageComponents::Shared`.

The recommended recipe for hubs with two navigation levels:

- **Level 1** - `Bali::Tabs style: :border` (icon + label, default size), one tab per section.
- **Level 2** - `Bali::Tabs style: :box, size: :sm` (no icons), one tab per sub-section.
- Both levels use `href:` tabs (full-page navigation, active tab auto-detected from the
  current path) and keep the active section **in the PATH**, never in the query string —
  GET filter forms would drop it otherwise.

```erb
<%= render Bali::ShowPage::Component.new(title: @project.name, back: { href: projects_path }) do |page| %>
  <% page.with_nav do %>
    <%= render Bali::Tabs::Component.new(style: :border) do |tabs| %>
      <% tabs.with_tab(title: t('.summary'), icon: 'layout-dashboard', href: project_path(@project)) %>
      <% tabs.with_tab(title: t('.quality'), icon: 'shield-check', href: project_quality_path(@project, section: 'tests')) %>
    <% end %>

    <%# Second level, shown within the active section %>
    <div class="mt-2">
      <%= render Bali::Tabs::Component.new(style: :box, size: :sm) do |tabs| %>
        <% tabs.with_tab(title: t('.tests'), href: project_quality_path(@project, section: 'tests')) %>
        <% tabs.with_tab(title: t('.defects'), href: project_quality_path(@project, section: 'defects')) %>
      <% end %>
    </div>
  <% end %>
  <% page.with_body do %>
    <%# Section content %>
  <% end %>
<% end %>
```

See the `IndexPage` "With nav" preview in Lookbook for a rendered example.

---

### Utilities

#### ThemeSampler

Lookbook-only preview gallery that renders Bali components (buttons, tags, cards, alerts, form inputs) under a DaisyUI theme to compare color palettes at a glance.

```erb
<%# Not a renderable component — browse it in Lookbook instead: %>
<%# http://localhost:3001/lookbook/preview/bali/theme_sampler/costa_norte %>
```

**Options:**
- None — there is no `Bali::ThemeSampler::Component` class; it exists only as a Lookbook preview (`app/components/bali/theme_sampler/preview.rb`) using a theme-specific layout (e.g. Costa Norte).

---

## Custom CSS Classes

Add custom classes with the `class` option:

```erb
<%= render Bali::Card::Component.new(class: 'my-custom-class hover:shadow-lg') %>
```

Classes are merged with component's default classes.

---

## Data Attributes for Stimulus

Pass data attributes for Stimulus controllers:

```erb
<%= render Bali::Button::Component.new(
  name: 'Toggle',
  data: {
    controller: 'toggle',
    action: 'click->toggle#switch',
    toggle_target: 'button'
  }
) %>
```

---

## Component Composition

Build complex UIs by composing multiple components:

```erb
<%= render Bali::Card::Component.new(style: :bordered) do |card| %>
  <% card.with_header { "User Profile" } %>

  <div class="flex items-center gap-4">
    <%= render Bali::Avatar::Component.new(src: @user.avatar, size: :lg) %>
    <div>
      <h3 class="font-bold"><%= @user.name %></h3>
      <%= render Bali::Tag::Component.new(text: @user.role, color: :info) %>
    </div>
  </div>

  <% card.with_actions do %>
    <%= render Bali::Button::Component.new(name: 'Edit', variant: :ghost) %>
    <%= render Bali::Button::Component.new(name: 'Message', variant: :primary) %>
  <% end %>
<% end %>
```

---

## Lookbook Previews

Browse all components and their variations in Lookbook:

```bash
cd spec/dummy && bin/dev
```

Open [http://localhost:3001/lookbook](http://localhost:3001/lookbook)

Each component has interactive previews showing:
- All variants and sizes
- Slot usage examples
- State variations (loading, disabled, etc.)
- Real-world use cases

---

## Best Practices

### DO

- Use semantic variants (`:success` for confirmations, `:error` for destructive actions)
- Compose components rather than duplicating HTML
- Use slots for complex content
- Pass data attributes for Stimulus integration

### DON'T

- Mix raw HTML with DaisyUI classes when a component exists
- Override component styles with inline styles
- Use `Button` for navigation (use `Link` instead)
- Skip accessibility attributes (components handle most, but add `aria-label` when needed)

---

## Next Steps

- [FormBuilder Guide](form-builder.md) - Enhanced form helpers
- [Component Patterns](../reference/component-patterns.md) - Internal patterns for contributors
- [Accessibility Guide](accessibility.md) - WCAG compliance details
