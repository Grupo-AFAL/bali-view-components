# Declared navigation: one structure for the side menu, the command palette and the analytics modules — Design

Date: 2026-11-07
Status: Reviewed (DHH, approved with changes, applied) — 2026-11-07
Issue: #1522 · handbook ADR `2026-10-18-modulos-desde-el-menu`, point 4

## Purpose

Six apps declare their menu in six shapes, and bali-analytics needs the same facts (which
controller belongs to which part of the menu, and what the menu calls it) that each app types a
second time into `dashboard_modules`. This spec puts one declaration in Bali — app modules
(optional) → sections → items — that draws `Bali::SideMenu` and `Bali::Command` through their
existing slots, answers "where does this `controller_path` belong?", ships a test the apps
include, and leaves in the host only what really differs: how a permission is decided.

## What the six apps declare today

Read on `origin/main` on 2026-11-07 (afal-apps `bb9ce8573`, gobierno-corporativo `451123fce`,
costa-norte `53cd183`, centinela-web `85227c8`, identity `a647ed61`, garita `b404bdc`).

| App | Declaration (lines) | Levels | Titles | Gate | Knows its controllers | Analytics level | Guard test |
|---|---|---|---|---|---|---|---|
| afal-apps | `Navigation` (761) + `NavigationHelper` (117) | modules → items → groups | I18n | permission keys (`user.can?`), `->(user)` | yes: `namespaces` on module and item, longest wins | module | no |
| gobierno-corporativo | `NavigationHelper` (903): `MODULE_CONTROLLER_PATHS`, `MODULE_DEFINITIONS`, `COMMAND_PALETTE_ENTRIES`; `shared/_side_menu` (355, by hand) | modules → sections → items → groups | I18n | permission, `policy(…)` in the view, `->(user)` with `Pundit.policy!` in the palette | yes: 407 exact controller paths | module | yes, `navigation_helper_test.rb:497` |
| costa-norte | `NavigationHelper` (278): `MODULES`, `MODULE_DEFINITIONS`, `side_menu_sections` | modules → sections → items | I18n | `policy(…)`, `can?`, inside the helper | per module, by prefix | mixed: Pack Track and Configuración by section, Inventario whole | yes, `navigation_helper_test.rb:67` |
| centinela-web | `Navigation` (126) | sections → items | literal Spanish | `->(user)` | no | section | no |
| identity | `Navigation` (103) + `NavigationHelper` (74) | sections → items | I18n | `[subject, :query?]` (Pundit) + operator function | no: `extra_active` route helpers | section, plus «Inicio de sesión», which is not in the menu | no |
| garita | `NavigationHelper#navigation_sections` (70) | sections → items | literal Spanish | `policy(…)`, `can?`, inside the helper | no | section | no |

### Premises of #1522 that did not hold

- **"Each app declares its menu once and both components come out of it."** Not in
  gobierno-corporativo (GC): controller map, module list, palette list and side menu ERB are four
  lists, and they have already contradicted each other (#923, quoted in the helper).
- **costa-norte's names.** No `MODULE_CONTROLLER_PATHS` or `COMMAND_PALETTE_ENTRIES` any more:
  `MODULES` plus `side_menu_sections`, and the palette is derived from the sections.
- **"Section titles by I18n."** centinela-web and garita write literal Spanish.
- **"GC has a guard."** So does costa-norte, deciding what is navigable by `klass <
  ::ApplicationController` — the criterion §5 takes.
- **Exact matching is needed.** GC's 407 exact entries are 137 namespace roots plus one entry whose
  module differs from its root's (`conversations/product_request_submissions` → Datos, under
  `conversations` → Documentos), which "most specific wins" (§2) already expresses.

## Decisions

1. **A Ruby class with a small DSL, subclassed by the host** (`class Navigation <
   Bali::Navigation::Base` in `app/models/`), as hosts subclass `Bali::FilterForm`. The tree
   carries behaviour and is validated when the class body runs; plain hashes are where GC drifted.
   It reloads with Zeitwerk; the base class lives in `lib/bali/`. The node types live in the
   `Bali::Navigation` module and not in the base class: inherited, they would shadow the host's
   own `Location` (costa-norte, centinela-web) or `Node` (GC) inside the declaration's lambdas.
2. **Whatever depends on the person or the request is a lambda run with `instance_exec` in the
   view** — gate, path, landing, badge, keywords — because `main_app`, engine proxies, `policy`,
   `current_user` and `params` exist there and only there. Bali never names a user, a permission
   or Pundit; one hook, `authorize`, reads gates an app writes as data.
3. **One matching rule**: a `controllers:` entry is a namespace — itself and everything below it
   at a `/`. No exact form, no Regexp (premise above).
4. **Most specific wins, at any level** (§2): a module claims `td_flow`, an item `td_flow/projects`.
5. **Visibility is derived, from gates alone**: an item shows when its gate passes; a container
   when its own gate passes and something drawn inside it shows. Paths are resolved only when
   drawn, so a menu can be built outside a view (§3). That retires afal-apps' `group` gate union,
   costa-norte's "a module shows when it has a link" and centinela-web's `reachable` block.
6. **A module lands on its first visible item drawn in the side menu that opens in place** (no
   `target:`) unless it declares `landing:`.
7. **Each component gains one keyword, `navigation:`**, filling the slots it already has.
8. **Bali exposes `locate`, `Location` and `title(locale:)`, not a `dashboard_modules` hash** (§6):
   at initializer time the host's class cannot load and its translations have not loaded — GC
   (`to_prepare` with hand-typed labels) and identity (`after_routes_loaded`) each work around
   exactly that. How bali-analytics reads them is that repo's to design.
9. **The upper level is `app_module`**: `module` is a Ruby keyword. Its I18n key stays
   `navigation.modules.<key>`, as in afal-apps, GC and costa-norte.

## 1. The declaration

| Class method | Options | Notes |
|---|---|---|
| `authorize { \|gate\| … }` | — | Runs in the view for every gate that is not a Proc. Declared first. |
| `i18n_scope "admin.nav"` | — | Default `"navigation"`. identity's keys live under `admin.nav.items` / `.sections`, read by its topbar and 15 test assertions. |
| `current_controller_path { … }` | — | Runs in the view; what the request counts as. Default `controller_path`. |
| `app_module key, …` | `icon:`, `gate:`, `landing:`, `controllers:`, `title:` | Optional level. Either every top-level node is an `app_module` or none is. |
| `section key, …` | `gate:`, `controllers:`, `title:`, `heading: false` | Inside a module or at the top. `heading: false` draws no heading (identity's main section) and keeps the title for the palette and `locate`. |
| `group key, …` | `icon:`, `gate:`, `title:` | An expandable entry; children only, no path. One level. |
| `item key, …` | `path:` (required), `icon:`, `gate:`, `controllers:`, `badge:`, `target:`, `hint:`, `keywords:`, `menu:`, `match:`, `title:` | A destination. |
| `outside_menu *namespaces` | — | Navigable controllers that deliberately have no place. |

- **Titles** default to `t("<scope>.modules.<key>")`, `.sections.<key>`, `.items.<key>` (groups
  too, as in afal-apps); a String `title:` is used as written. Items written directly in an
  `app_module` form a section headed by the module's title (afal-apps' one list, GC's first one).
- **`path:`** is a Symbol (a `main_app` route helper), a String (a URL) or a Proc, resolved only
  when drawn; nil there draws the item disabled, as `Bali::SideMenu::Item` does with a blank
  `href`, and leaves it out of the palette. An item whose destination may not exist says so in its
  gate (centinela-web: `gate: -> { pasaporte_assisted_reset_url.present? }`).
- **`gate:`** is a zero-arity Proc, or any value, handed as written to `authorize`. **`badge:`**
  is a literal, or a zero-arity Proc run only when the item is drawn.
- **`target:`** keeps the item out of the palette, which navigates in place. **`hint:`** is the
  link's `title` and palette search text — centinela-web draws both today for its two Pasaporte
  links; **`keywords:`** is search text only (afal-apps' `navigation.formerly`).
- **`menu: false`**: in the palette and in `locate`, not in the side menu (afal-apps'
  `palette_extras`, GC's org charts, costa-norte's «Nuevo envío»). **`match:`** is the path
  matching used when no claim decides; default `:crud`. Keys are unique; `find(key)` returns any node.

Raised while the class body runs, naming the node: a duplicate key; a Proc option (`gate:`,
`path:`, `landing:`, `badge:`, `keywords:`) taking arguments (afal-apps' and centinela-web's
`->(user)`: "it runs in the view, use current_user"); a non-Proc gate before `authorize`; top-level
modules mixed with sections; an item or group at the top level; a module, section or group without
items, or with none drawn in the side menu (all `menu: false`, the items written directly in a
module included); items written directly in a module after its sections; a module with nothing
that opens in place and no `landing:`; a `match:` the side menu does not know; a `controllers:`
entry with a leading or trailing `/` or a `#`; an item without `path:`. Every DSL method carries
YARD.

### garita, complete

```ruby
class Navigation < Bali::Navigation::Base
  section :monitoring, title: "Monitoreo" do
    item :dashboard, title: "Panel", icon: "layout-dashboard", path: :root_path, controllers: %w[dashboard]
    item :webhook_events, title: "Eventos", icon: "inbox", path: :webhook_events_path,
         gate: -> { policy(WebhookEvent).index? }, controllers: %w[webhook_events]
    item :deliveries, title: "Entregas", icon: "send", path: :deliveries_path,
         gate: -> { policy(Delivery).index? }, controllers: %w[deliveries]
  end

  section :configuration, title: "Configuración" do
    item :webhook_sources, title: "Fuentes", icon: "webhook", path: :webhook_sources_path,
         gate: -> { policy(WebhookSource).index? }, controllers: %w[webhook_sources]
    item :consumer_applications, title: "Consumidores", icon: "app-window", path: :consumer_applications_path,
         gate: -> { policy(ConsumerApplication).index? }, controllers: %w[consumer_applications]
    item :subscriptions, title: "Suscripciones", icon: "git-branch", path: :subscriptions_path,
         gate: -> { policy(Subscription).index? }, controllers: %w[subscriptions]
  end

  section :administration, title: "Administración", controllers: %w[bali_auth/admin] do
    item :users, title: "Usuarios", icon: "users", path: :admin_users_path,
         gate: -> { policy(User).index? }, controllers: %w[admin/users]
    item :roles, title: "Roles y accesos", icon: "shield-check", path: -> { bali_auth_admin.roles_path },
         gate: -> { current_user.can?("roles.index") }
    item :sessions, title: "Sesiones", icon: "monitor", path: -> { bali_auth_admin.sessions_path },
         gate: -> { current_user.can?("roles.index") && BaliAuth.session_tracking_enabled? }
    item :audit_logs, title: "Auditoría", icon: "scroll-text", path: -> { bali_auth_admin.audit_logs_path },
         gate: -> { current_user.can?("roles.index") }
  end

  outside_menu "flightdeck", "bali_analytics" # completed from the first run of §5's assertion
end
```

`webhook_sources` claims `webhook_sources/secrets`, so the item stays active on a source's secret
page, which `:crud` path matching misses today.

### afal-apps, every feature it uses

```ruby
class Navigation < Bali::Navigation::Base
  PORTAL_VALUE_NEW_UNTIL = Date.new(2026, 12, 15)

  authorize { |keys| Array(keys).any? { current_user.can?(it) } }

  app_module :general, icon: "layout-grid", controllers: %w[home inboxes] do
    item :tasks, icon: "checklist", path: :tasks_path, controllers: %w[tasks]
    item :wellness, icon: "heart", path: :wellness_dashboard_path, gate: "wellness.access", controllers: %w[wellness]
  end

  app_module :tdflow_portal, icon: "lightbulb", controllers: %w[td_flow/portal],
             gate: -> { current_user.tdflow_portal? || current_user.tdflow_involved? },
             landing: -> { current_user.tdflow_portal? ? main_app.td_flow_portal_root_path : main_app.td_flow_portal_proposals_path } do
    item :portal_home, icon: "home", path: :td_flow_portal_root_path, gate: "tdflow.access",
         controllers: %w[td_flow/portal/home]
    item :portal_proposals, icon: "clipboard-check", path: :td_flow_portal_proposals_path,
         controllers: %w[td_flow/portal/proposals td_flow/initiatives],
         badge: -> { TDFlow::Initiative.involving(current_user).count.nonzero? }
    item :portal_value, icon: "sparkles", path: :td_flow_portal_value_showcase_path, gate: "tdflow.access",
         controllers: %w[td_flow/portal/value_showcase],
         badge: -> { t("navigation.badges.new") if Date.current < PORTAL_VALUE_NEW_UNTIL }
  end

  app_module :tdflow, icon: "folder-kanban", gate: TDFlow::PortalAccess::MODULE_PERMISSIONS,
             controllers: %w[td_flow] do
    item :tdflow_home, icon: "house", path: :td_flow_root_path, controllers: %w[td_flow/landings],
         gate: -> { TDFlow::HomePolicy.new(current_user, :home).show? },
         badge: -> { TDFlow::Home.pending_count(current_user).nonzero? }
    item :tdflow_portfolio, icon: "briefcase", path: :td_flow_initiatives_path,
         gate: TDFlow::PortalAccess::BACK_OFFICE_PERMISSIONS + %w[tdflow.access], controllers: %w[td_flow/initiatives]
    group :tdflow_projects_group, icon: "list-checks" do
      item :tdflow_projects, icon: "list-checks", path: :td_flow_projects_path,
           gate: TDFlow::ProjectPolicy::INDEX_READERS, controllers: %w[td_flow/projects]
    end
    item :tdflow_report_schedules, icon: "calendar-clock", path: :td_flow_report_schedules_path,
         gate: "tdflow.manage", menu: false
  end

  app_module :marketing, icon: "megaphone", gate: Marketing::PERMISSIONS, controllers: %w[marketing],
                        landing: :marketing_root_path do
    item :marketing_cedis_catalog, icon: "external-link", path: -> { Marketing::CEDIS_CATALOG_URL },
         gate: "marketing.request", target: "_blank"
  end

  app_module :administration, icon: "shield", gate: -> { current_user.admin? }, controllers: %w[admin bali_auth] do
    item :admin_users, icon: "users", path: :admin_users_path
    item :admin_roles, icon: "shield", path: -> { bali_auth_admin.roles_path }
  end
end
```

The layouts then shrink to the brand and one keyword each:

```erb
<%= render Bali::SideMenu::Component.new(current_path: request.path, navigation: Navigation,
                                         fixed: true, collapsible: true) do |c| %>
  <% c.with_brand do %>…<% end %>
<% end %>

<%= render Bali::Command::Component.new(navigation: Navigation, class: "max-w-xs",
                                        placeholder: t("navigation.command_palette.placeholder")) %>
```

## 2. The query: `Navigation.locate(controller_path)`

Returns `Bali::Navigation::Location` — `Data.define(:app_module, :section, :item)`, nil where not
applicable; the group is `item.parent` — or nil when nothing claims the path. `outside_menu`
entries compete like any claim and, when one wins, the answer is nil too. Pure: no view, no
person. Every node answers `key`, `title(locale: I18n.locale)`, `controllers` and `parent`.

A claim is a node plus one of its entries that is the path or a `/`-prefix of it (`admin` claims
`admin/users`, never `administrations`). All the entries matching one path are prefixes of it, so
they nest, and comparing them by segments is comparing them by length. The winning claim is:

1. **the entry with the most segments**; entries tie only when they are the same string;
2. on a tie, **the claim its ancestors support**: the one whose ancestors' longest matching entry
   has the most segments (none counts as zero) — this is also what makes an item beat its own
   module when both name the same entry;
3. on a tie, **declaration order**.

| Path | Result | Rule |
|---|---|---|
| `td_flow/portal/value_showcase` | portal › «Aporte de valor» | 1: three segments beat the back-office module's `td_flow` |
| `conversations/product_request_submissions` (GC) | Datos | 1: two segments beat Documentos' `conversations` |
| `td_flow/initiatives` | back-office › «Portafolio» | 2: ties with «Mis propuestas» on 1; only the back-office module (`td_flow`) supports it |
| `td_flow/scoring_configs` | the first of afal-apps' six Configuración tabs | 3: same entry, same support |

Without rule 2, `td_flow/initiatives` would go to the portal, declared first. `locate` is what
bali-analytics and the tests read; the side menu applies the same rules to what the person can see.

## 3. The menu of one request: `navigation_for(Navigation)`

A view helper (registered on `ActionController::Base`, like `Bali::ThemeHelper`) returning a
`Bali::Navigation::Menu` memoized on the view. view_component 4.23's `Base#helpers` hands every
component the original view context, so side menu, palette and the host's breadcrumb share one
menu and each gate runs at most once per request. The menu is lazy: the switcher and the landings
stop at a module's first visible item, and a navigation without modules never asks where the
request is to list its sections. The palette walks every page, so with the palette on the page
every gate of every visible module runs once.

- `app_modules` — the visible ones, in order. A module whose only visible items are `menu: false`
  is not one: it would open an empty side menu, so neither it nor its items are offered.
- `location` — `locate` over visible nodes only, with one more tie-break before declaration
  order, for items that share a controller and differ by query (afal-apps' Configuración tabs on
  `td_flow/scoring_configs`; GC's «Bandeja» and «Notificaciones», `inbox` and `inbox?tab=notices`).
  An item matches when every parameter of its path's query is in `request.query_parameters` with
  the same value — an item without a query matches with zero; among those that match, the most
  parameters wins. So `?tab=notices` picks «Notificaciones», no query picks «Bandeja», and when no
  tab matches the order decides. Only tied items' paths are resolved for this.
- `current_app_module` — the location's, or the first visible one (afal-apps' and costa-norte's
  fallback; GC's `:my_space` is its first).
- `sections` (the current module's), `items(section)` — visible, in order.
- `path(node)`, `landing(app_module)`, `badge(item)`; `active(item)` is `true` for the drawn
  winner, `false` for the others while there is one, and `nil` otherwise, so `match:` decides.
- `find(key)` — a visible node or nil (centinela-web's `FREQUENT_KEYS`, identity's operator tabs).

So a portal requester on `td_flow/initiatives` gets the portal with «Mis propuestas» active (the
back-office is not visible to them) and the TD team gets the back-office: afal-apps'
`current_nav_module` without its two code paths. `current_controller_path` takes GC's two
exceptions out of `current_module`:

```ruby
current_controller_path do
  if controller_path == "versions" && params[:business_process_id] then "business_processes"
  elsif controller_path == "conversations" && @conversation&.data_access_interview? then "access_requests"
  else controller_path
  end
end
```

A reader outside a view (afal-apps' `TDFlow::FeedbackItem` asks which modules a user may see)
builds `Bali::Navigation::Menu.new(Navigation, context)` against any object answering what its
gates call: visibility never resolves a path.

## 4. Drawing it

`navigation: nil`, the default of both, renders exactly what each renders today.

**`Bali::SideMenu::Component.new(navigation:)`** fills, in `before_render`, ahead of the host's block:

- `with_menu_switch(title:, icon:, href: landing, active:)` per visible module. The switcher still
  needs two (`multiple_menus?`) and a navigation without modules adds none, so `menu_switches`
  keeps its meaning and enjoykitchen's hand-written switches keep working;
- `with_list(title:)` per visible section of the current module;
- `with_item(name:, icon:, href:, match:, active:, badge:, target:, title:)` per drawn item, `title:`
  being the hint and `name:` a `<span>` when the item has `title_class:` (§10); `Item::Component`
  compacts its options, so a nil one keeps the written-out fast path of `Item#leaf_link_attributes`.
  A group is a `with_item(name:, icon:, badge:)` holding its children, drawn without their icons
  under `item_icons: false`.

The block keeps `with_brand`, `with_switcher` (costa-norte's «Integración»), `with_bottom_item`
and any further `with_list`, drawn after the navigation's.

**`Bali::Command::Component.new(navigation:)`** adds, before the host's groups:

- with modules: a modules group (`mode: :navigation`, each visible module to its landing) and a
  pages group (`:searchable`); without: one pages group in `:navigation`, as identity and garita
  do today;
- one entry per visible item not carrying `target:`: `title`, `meta` (its module's title, else its
  section's), `icon`, `href`, `search` (title, group, section, module, hint, keywords).

Group names are `bali_view.command.navigation.modules` / `.pages` («Módulos», «Páginas»); a host
renames one in its own locale. «Frecuentes», create actions and anything else stay host groups.

## 5. The test the apps include

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

`assert_navigation_covers_routes(navigation, base: ::ApplicationController, routes:
Rails.application.routes)` walks the routes, engines included (`route.app.engine?`, as
costa-norte's test and bali-analytics' `RouteActions` do), keeps the controllers descending from
`base` — what can draw the layout — and lists those neither placed by `locate` nor named by
`outside_menu`. It also fails on an entry that reaches no routed controller: today a typo in a
namespace claims nothing and nobody notices. `assert_navigation_translated` runs every default-key
title through `I18n.exists?`, because titles become analytics module names. Required explicitly, like
`bali/testing/widget_catalog`: it constantizes every routed controller.

## 6. What bali-analytics gets

`Navigation.locate(controller)`, the `Location` it returns and each node's `title(locale:)` — the
module of a `controller#action` and the function name are one call away, at whichever level the
app groups by (afal-apps and GC by module, centinela-web, identity and garita by section,
costa-norte both). How that is configured, and the reload and I18n timing it has to respect, is a
follow-up issue in bali-analytics. Controllers that never were in a menu stay in
`dashboard_modules` and `dashboard_action_names` there: identity declares `outside_menu "home",
"rodauth"` (and its reset screens) here and keeps «Inicio de sesión» in its hand-written map.

## 7. Migration, app by app

Each app's PR reports `git diff --shortstat` as is and must be net negative — the pilot included.
In every app: subclass, render with `navigation:`, delete the helper and the app's own guard, add
§5. The behaviour notes below are to be verified in that app's PR.

- **garita (pilot).** Goes: `Entry`, `navigation_sections`, `administration_entries` and the
  helper's header (40 of its 70 lines), the side menu loop (7) and the «Secciones» palette group
  (8): 55 lines, measured. In: §1's declaration (31 lines), §5's test (~10) and the two
  `navigation:` keywords — about 43, so roughly −12. Stays: `quick_actions` («Acciones»),
  `INTERNAL_TOOLS`. «Secciones» reads «Páginas» unless garita overrides the key.
- **afal-apps.** Goes: `Item`, `Mod`, `item`, `group`, `modules`, `find`, `module_for`, all of
  `NavigationHelper`, most of both partials, and the finance `landing` (the default reaches the
  same screen for every preset, and Prodigia's explorer instead of a credentials page an
  explorer-only role cannot open). `->(user)` becomes `-> { … current_user … }`. A module keeps
  `gate:` where its `visibility:` is narrower than its items' gates (Finanzas leaves
  `finance.fiscal.downloads` out on purpose); the role tests decide. Readers to rewrite: the
  cafeteria, daycare and home landings, `TDFlow::FeedbackItem` (§3), `FeedbackItem::Section`
  (`locate`), `AgentQueries::FeedbackCounts` (`find(key).controllers`), the eight
  `test/models/navigation*_test.rb`, `test/integration/side_menu_test.rb`.
- **gobierno-corporativo.** Goes: the 407-entry map (≈137 roots, on the nodes that own them),
  `COMMAND_PALETTE_ENTRIES` (the org charts become `menu: false` items), `MODULE_DEFINITIONS` with
  its six `enabled: false` placeholders, `current_module`, `visible_module_definitions`,
  `module_dashboard_path` (a `landing:` stays where it is not the first visible item: Mi espacio's
  inbox, Procesos' home), `command_palette_entries`, `palette_title_key`, the hand-written side
  menu (its `policy(…)` checks become gates), and the hand-written «Páginas frecuentes» palette
  group, whose pages become `frequent: true` (§10). Stays: §3's `current_controller_path`; the
  Datos badge moves to `group … badge:` (§10). For that PR to decide: the palette offering every
  menu entry instead of a curated list — measured, 29 of the side menu's 75 static entries are not
  in today's palette: 20 behind a `policy(…)` (11 inline, 9 inside an enclosing `if policy`), 2
  publisher-hidden, the docs link (`target:`, stays out) and 6 open to the whole module — and
  `publisher_hidden_label`'s struck-through titles (a title is data, without HTML; the span is
  `title_class:`, §10). Its Datos master catalogs are a loop over `Mdm::CatalogRegistry`, which the
  class body can run the same way.
- **costa-norte.** Goes: `MODULES`, `MODULE_DEFINITIONS`, `current_module`, `module_for`,
  `visible_module_definitions`, `module_dashboard_path`, `menu_module`, `side_menu_sections`,
  `sections_for`, `nav_item`, the three `*_sections`, both layout loops. Stays: the «Integración»
  switcher, «Frecuentes», `module_breadcrumbs`; «Nuevo envío» becomes a `menu: false` item.
- **centinela-web.** Goes: `Item`, `Section`, `sections_for`, `items_for`, `frequent_for`,
  `reachable` (its two Pasaporte links put the URL's presence in their gate), `nav_path`,
  `visible_nav_sections`, and `FREQUENT_KEYS`, whose items become `frequent: true` (§10). One pages
  group with the section as `meta` replaces one group per section.
- **identity.** Goes: `Item`, `Section`, `extra_active` (the archives controller goes on the audit
  logs item), `nav_sections`, `nav_item_visible?`, `nav_item_allowed?` (now `authorize {
  |(subject, query)| policy(subject).public_send(query) }`), `command_palette_entries`. Stays:
  `AdminHost.link` in path lambdas, the operator function in the gate, the docs bottom item.
  The main section uses `heading: false`.

`docs/guides/navigation.md` gives the recipe for each starting shape (data module, helper with
literals, controller map); its examples run as written in the dummy app.

## 8. Out of scope

- bali-analytics reading the navigation (§6): another repo and release. Until it ships, every app
  keeps `dashboard_modules` and `dashboard_action_names` as they are.
- Retired by the review: a `Location#group` (it is `item.parent`) and sections without items.
- Migrating any app; garita's pilot is the next stage.
- Moving controllers or redesigning a menu (#1522; the ADR keeps namespaces following the domain).
- afal-apps' and costa-norte's `_external_side_menu`: one-screen menus for another audience.
- Entries that depend on data (costa-norte's «Integración» options), HTML in titles,
  «Frecuentes», create actions: host code over the same slots.
- Exact or Regexp entries, groups with their own path, a third level under a section: no reader.
- Inferring an item's controller from its route: the same item written with a lambda would claim
  something different from the one written with a Symbol.

## 9. Open decisions

None for Bali. The two visible changes GC's migration has to settle are listed in §7 so that
nobody settles them by accident.

## 10. Amended 2026-11-08

Migrating centinela-web, GC and afal-apps took four options §1 did not have; §4 and §7 above are
updated for them. Of §8's host code, «Frecuentes» can now be declared (costa-norte's, which lists
modules, stays in the host), and GC's struck-through titles become `title_class:`.
`item … frequent:` brings «Frecuentes» into Bali: the palette opens on the frequent pages this
person may open, and the modules and the pages wait for a query. `group … badge:` draws GC's Datos
count on its group row. `item … title_class:` wraps the title in a `<span>` wherever the side menu
draws it, which is GC's struck-through markup, so its titles stay data without HTML.
`group … item_icons: false` draws a group's items without icons in the side menu, as afal-apps
and GC's Documentos draw them, while the palette keeps them. `docs/guides/navigation.md` carries
the contract.
