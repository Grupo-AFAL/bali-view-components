# Navigation

An app declares its navigation once, as a subclass of `Bali::Navigation::Base`. `Bali::SideMenu`
and `Bali::Command` draw themselves from it with one keyword, and `Navigation.locate` says where
any controller belongs. The design and the measurements behind it are in
`docs/superpowers/specs/2026-11-07-declared-navigation-design.md`.

Bali's own types (`Bali::Navigation::Item`, `::Location`, `::Menu`…) live in the
`Bali::Navigation` module, not in the base class, so inside your class and its lambdas `Location`
or `Item` is still your model: `gate: -> { policy(Location).index? }` asks about yours.

## A first navigation

```ruby
# app/models/navigation.rb
class Navigation < Bali::Navigation::Base
  app_module :work, title: "Work", icon: "briefcase", controllers: %w[projects] do
    item :projects, title: "Projects", icon: "folder-kanban", path: "/projects", controllers: %w[projects]
    item :calendar, title: "Calendar", icon: "calendar-days", path: "/calendar", controllers: %w[calendars],
                    hint: "The team's calendar"
    item :inbox, title: "Inbox", icon: "inbox", path: "/inbox", controllers: %w[inbox], badge: -> { 4 }
    group :settings, title: "Settings", icon: "settings" do
      item :members, title: "Members", path: "/settings/members", controllers: %w[settings/members]
      item :billing, title: "Billing", path: "/settings/billing", controllers: %w[settings/billing]
    end
    section :reports, title: "Reports" do
      item :monthly, title: "Monthly", icon: "chart-pie", path: "/reports/monthly", controllers: %w[reports]
      item :exports, title: "Exports", icon: "file-down", path: "/reports/exports", menu: false
    end
  end

  app_module :administration, title: "Administration", icon: "shield", controllers: %w[admin] do
    item :users, title: "Users", icon: "users", path: "/admin/users", controllers: %w[admin/users]
    item :roles, title: "Roles", icon: "key-round", path: "/admin/roles", controllers: %w[admin/roles]
  end
end
```

This is the navigation of the SideMenu and Command previews «From a navigation», and
`test/bali/navigation/guide_example_test.rb` runs it as written here. The layouts:

```erb
<%= render Bali::SideMenu::Component.new(current_path: request.path, navigation: Navigation,
                                         fixed: true, collapsible: true) do |menu| %>
  <% menu.with_brand do %>…<% end %>
<% end %>

<%= render Bali::Command::Component.new(navigation: Navigation, class: "max-w-xs") %>
```

`navigation:` fills the slots the components already have, ahead of anything the block adds:
the block keeps `with_brand`, `with_switcher`, `with_bottom_item` and any extra `with_list` or
`with_group`. Without `navigation:` both render exactly what they did before.

## The levels

- **`app_module`** — an entry of the module switcher. Optional: either every top-level node is a
  module, or every one is a `section`. Items written directly in a module form a section headed
  by the module's title.
- **`section`** — a list of the side menu. `heading: false` draws it without a heading and keeps
  its title for the palette and for `locate`.
- **`group`** — an expandable entry; it holds items and has no path.
- **`item`** — a destination.

Keys are unique across the navigation, and `Navigation.find(key)` returns any node. Titles come
from I18n — `navigation.modules.<key>`, `navigation.sections.<key>`, `navigation.items.<key>`
(groups too) — unless `title:` gives a literal; `i18n_scope "admin.nav"` moves the scope.

## Gates

A gate is a lambda with no arguments, run with `instance_exec` in the view: `policy`,
`current_user`, `params` and the route helpers are there.

```ruby
item :trips, path: :trips_path, gate: -> { policy(Trip).index? }
```

An app whose gates are data declares once how to read them, before the first one:

```ruby
authorize { |keys| Array(keys).any? { current_user.can?(it) } }      # permission keys
authorize { |(subject, query)| policy(subject).public_send(query) }  # Pundit pairs
```

Visibility comes from gates alone. An item shows when its gate passes; a module, section or group
when its own gate passes and something drawn inside it shows — so a module whose only visible
items are `menu: false` is not offered. A module lands on its first item drawn in the side menu
that opens in place (no `target:`) unless it declares `landing:`. A module whose drawn items all
open elsewhere has no such item, and its switch would come out as `<a href="">`: that module
declares `landing:`.

## Paths

`path:` (and `landing:`) is a Symbol — a `main_app` route helper —, a String, or a lambda run in
the view, which is what reaches an engine's routes (`-> { bali_auth_admin.roles_path }`). Paths
are resolved only when drawn. One that resolves to nil draws a disabled item and stays out of the
palette; an item whose destination may not exist says so in its gate:

```ruby
item :assisted_reset, path: -> { pasaporte_assisted_reset_url },
                      gate: -> { pasaporte_assisted_reset_url.present? }
```

## Where a controller belongs

A `controllers:` entry is a namespace: itself and everything below it at a `/` (`admin` claims
`admin/users`, never `administrations`). Modules, sections and items take them.
`Navigation.locate(controller_path)` returns a `Bali::Navigation::Location` (`app_module`,
`section`, `item`; the group is `item.parent`), or nil. The winning claim is:

1. the entry with the most segments;
2. on a tie, the one its ancestors support — whose ancestors' longest matching entry has the most
   segments, which is also what makes an item beat its own module on the same entry;
3. on a tie, the first declared.

The side menu applies the same rules to what the person may open, and then tells apart items that
share a controller by their path's query: the one whose parameters the request carries, the most
of them first (`/inbox` and `/inbox?tab=notices`). The item it places is active; the rest are not;
and when no drawn item is placed, the item's `match:` (default `:crud`) decides as before.

A controller that serves screens of several modules declares what the request counts as:

```ruby
current_controller_path do
  controller_path == "versions" && params[:business_process_id] ? "business_processes" : controller_path
end
```

Controllers that deliberately have no place go in `outside_menu "sessions", "flightdeck"`.

## The palette

Pages are every item the person may open, with a path and without `target:` (the palette
navigates in place). `menu: false` offers an item in the palette only. Each page is found by its
title, its group, section and module, its `hint:` (also the link's `title` in the side menu) and
its `keywords:` (a String, an Array or a lambda). With modules, a modules group is listed on open
and the pages as you type; without, the pages are listed on open. The group names are
`bali_view.command.navigation.modules` and `.pages`, which a host renames in its own locale.

## Outside a view

`navigation_for(Navigation)` is the menu of one request, memoized on the view so the side menu,
the palette and the page share it and each gate runs at most once. The switcher stops at each
module's first visible item, but the palette lists every page the person may open: with the
palette on the page, every gate of every visible module runs once per request.

A model or a job builds a menu against any object that answers what the gates call:
`Navigation.menu(context)`. What it can ask depends on what that object has:

- **gates only**: `app_modules`, `find(key)`, and — in a navigation without modules —
  `sections` and `items(section)`;
- **`controller_path`** too (or `current_controller_path`): `location`, `current_app_module`, and
  `sections` in a navigation with modules; `request` as well, and those items' paths, when items
  share a controller and differ by query;
- **`main_app`**, or whatever the path lambdas call: `path(item)`, `landing(app_module)`,
  `palette_entries`; `badge(item)` needs what the badge calls.

## The test

```ruby
require "bali/testing/navigation"

class NavigationTest < ActiveSupport::TestCase
  include Bali::Testing::Navigation

  test "every screen has a place" do
    assert_navigation_covers_routes Navigation
  end

  test "every title is translated" do
    assert_navigation_translated Navigation, locale: :es
  end
end
```

`assert_navigation_covers_routes` walks the routes, mounted engines included, and fails with every
controller descending from `ApplicationController` (`base:`) that nothing places, and with every
entry that reaches no routed controller.

## Migrating

Whatever shape the app starts from, the PR deletes the old declaration and its helper, renders
the two components with `navigation:`, replaces the app's own guard test with the one above, and
reports `git diff --shortstat`: it has to come out negative.

- **A data module** (`Navigation` with `Item`/`Section` structs and a `nav_path` helper): each
  struct becomes a DSL call. A gate `->(user) { … }` becomes `-> { … current_user … }`; the
  helpers that filtered by permission, resolved paths and marked the active item go.
- **A helper that builds entries with literals** (`navigation_sections`): each entry becomes an
  `item` with its gate, and the item claims its controller in `controllers:`.
- **A controller → module map**: each key moves to the item or section that owns it, as a
  namespace — a nested controller is already claimed by its root, so only the roots remain.
