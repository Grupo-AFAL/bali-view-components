# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed (breaking)

- **DataTable + IndexPage — the index page becomes a default instead of an assembly kit.** Every listing feature added over the last cycles — saved views, row grouping, the column selector, export, the `ViewSwitch` segmented control — landed as its own isolated slot with its own isolated preview. None were ever composed together, so there was no single place showing what a Bali index is supposed to look like with everything on, and the pieces had drifted into three partially overlapping implementations of "display mode" and "export". v3.0 defines that composition and makes composing it wrong take effort. The canonical reference is rendered live: `bali/index_page/complete` in Lookbook (the same body without the page layer is `bali/data_table/complete`), the only place where all seven control families are on at once; `/admin/movies` in the dummy app is the same composition end to end against real controllers, routes and Turbo Streams, saved views included — the only family it leaves out is host toolbar buttons. Step-by-step instructions, including the two breaks that fail silently, are in [the v2 → v3 migration guide](docs/guides/migration-v2-to-v3.md).

  | Removed | Replacement |
  |---|---|
  | `with_actions_panel` | `with_bulk_actions` |
  | `with_actions_panel(export_formats:)` | `page.with_export(url:)` on the page component |
  | `dt.with_export` | `page.with_export(url:)` on the page component |
  | `with_actions_panel(grid_display_mode_enabled:)` | `with_view_switch` |
  | `Bali::DataTable::ActionsPanel::Component`, `Bali::DataTable::Action::Component` | *(deleted)* |
  | URL param `data_display_mode` | URL param `view` (rename with `view_param:`) |
  | `with_column_selector(table_id:)`, `with_saved_views(table_id:)` | resolved from `filter_form.storage_id` |
  | `Bali::Table(id:)` as the column-selector target | the DataTable container id |
  | `render Bali::Card` around the DataTable in the host | the content slot's surface |
  | `toolbar_class:` | *(deleted — the toolbar is bare by design)* |

  **The surface moved from the host to the component.** Each view used to write `render Bali::Card { render DataTable }`, so whether the toolbar sat inside a card depended on the page, and grid mode produced cards nested in a card. There is now ONE content band that decides its own surface: `with_table` brings a card plus `overflow-x-auto`, `with_grid` brings none (the cards *are* the surface), and `with_content(surface:, scroll:)` is the general form both are sugar over — a Gantt or a map passes `surface: false`. `display_mode:` no longer selects between two hardcoded slots: the host declares what it wants, so adding kanban, calendar or map views to an app requires no change in Bali. Declaring two content slots now raises `DuplicateContent`; in v2 the second silently won and the host got a mode it never chose. Hosts delete their `Bali::Card` wrapper — leaving it is not a crash, just a card inside a card.

  **One listing, one name.** A listing's identity used to be written four times (`Bali::Table(id:)`, `with_column_selector(table_id:)`, `with_saved_views(table_id:)`, `FilterForm(storage_id:)`), with the `#`-prefix normalization duplicated verbatim in two components; column persistence was keyed by `table_id` while the saved-views store was keyed by `storage_id`. `table_id:` is removed (passing it raises `ArgumentError: unknown keyword: :table_id`) and `DataTable` resolves the identity once: explicit `id:`, else `filter_form.storage_id`, else a random hex. The value is sanitized into a valid CSS identifier (case preserved; a leading digit gets a `listing-` prefix, because `#123 table` makes `querySelector` throw), the container renders with it, and the column selector targets `#<id> table` rather than the table element. Both controls derive their strings from the same place (`Bali::DataTable::ListingIdentity`): the saved-views controller finds the selector by comparing that exact attribute, so two separate derivations lost the columns on save without failing anywhere. With no stable identity (the random hex) column persistence turns itself OFF instead of writing a key nothing can ever read back.

  **The view switch replaced the legacy toggle, and preserves the query string.** `with_view_switch` puts a `Bali::ViewSwitch` in the toolbar, but the hrefs are built by the DataTable: each view declares `value:` and the component merges the current query string, dropping `page` and KEEPING `saved_view` — these links are navigation, not a filter submit, so filters, sorting, grouping and the applied view survive a mode change (in v2 each mode was a loose page and lost all of it). `dt.display_mode` returns the value validated against the declared views, so an unknown `?view=` falls back to the first one instead of leaving the listing empty. The active view now also travels as a hidden field on filter submits, the way `group_by` already did, so filtering from the cards view no longer drops the user back into the table. This retires `ActionsPanel`'s toggle and its competing export dropdown, which also closes **#653**: the toggle built its links with `Utils::Url#add_query_params`, whose Symbol-over-String merge duplicated a param already in the URL, and that code is no longer on this path.

  **Row selection belongs to the component.** `Bali::Table` gains `selectable: true`, rendering the checkbox column and select-all header every app used to hand-write; the `<tr>` is the selectable item (it carries `record_id:`, required, and the `selected` class) and it is mutually exclusive with the legacy `bulk_actions:` array (`IncompatibleOptions`). `with_bulk_actions` renders a `Bali::BulkActions(variant: :toolbar)` contextual row — counter, actions, clear — that REPLACES the toolbar row while a selection exists and restores it on clear, so the two never compete for space. This retires the `hidden md:block` desktop panel plus its `md:hidden` mobile COPY, the duplication that made two Stimulus controllers drive one listing. `Bali::BulkActions` gains `variant: :floating | :toolbar` and `standalone:`; the floating bar is unchanged and stays available outside a DataTable. The `bulk-actions` controller goes on the DataTable CONTAINER, never on the bar: two nested controllers of the same identity split the targets and the bar would never see the rows, silently. The controller now derives `selectedIds` from the DOM instead of counting incrementally — which is what keeps select-all, clear and a Turbo cache restore in sync with what is on screen — and gains `toggleItem`, `toggleAll`, `clear`, an indeterminate select-all and server-rendered plural labels (no i18n interpolation in JS). Note the payload: each action is its own form whose only hidden field is `selected_ids`, so a controller reading `params[:movie_ids]` or hand-written `name="x[]"` checkboxes stops receiving anything, and extra parameters travel in the action's query string.

  **The toolbar is one bare row, and it folds instead of duplicating.** Left is which data is shown, right is how it is shown, identical in every display mode. Below `sm` (640px) the secondary controls MOVE into a `⋯` menu and move back on the way up — never duplicated, because two copies of the column selector are two controllers driving one table and two copies of saved views duplicate the ids in its rename forms (the bug fixed in #669). The new `toolbar-overflow` controller is registered by `registerAll` and exported from the package root. Survival order (`OVERFLOW_PRIORITIES`): search/filters and the view switch stay; saved views, group by, columns, export and host `toolbar_buttons` collapse. It is a fixed `matchMedia` threshold, not measurement, and all state lives in the DOM, so a Turbo reconnect or a turbo-stream replace cannot strand a control inside the menu; `turbo:before-cache` always caches the expanded layout. Consequences: the toolbar order is now defined by `OVERFLOW_PRIORITIES` rather than by the template (expanding re-sorts by priority, which is what makes the controller stateless); the `⋯` is not rendered at all when nothing is collapsible, and is served hidden so it never flashes an empty menu; the view switch defaults to `icon_only: :responsive` (a new `Bali::ViewSwitch` mode that collapses only the label below `sm` while keeping `title`/`aria-label`, so the buttons never lose their accessible name); collapsible labels are marked `toolbar-control-label` so the new `data_table/index.css` can bring them back inside the menu, where there is room; and dropdowns nested in the menu render in flow, because absolutely positioned ones escaped the viewport on a phone. Anything a host puts in `with_toolbar_button` must have an idempotent `connect()` and no `data-turbo-permanent`.

  **Two things to check while migrating.** Users' stored column preferences reset ONCE, because the localStorage key changes from `bali:columns:<table_id>` to `bali:columns:<id>`; the old keys are orphaned and nothing cleans them up. That reset is also the fix for two different listings sharing one memory through a copy-pasted `table_id` (`/movies` and `/admin/movies` both used `#movies-table`). And the container id changed, so a host doing `turbo_stream.replace "data-table-#{@filter_form.id}"` must switch to `turbo_stream.replace Bali::DataTable::ListingIdentity.for(@filter_form)` — this is **the break that leaves no trace**: Turbo resolves the target with `getElementById`, so a miss replaces nothing, raises nothing and logs nothing. Target the RESOLVED identity, not the raw `storage_id`: it is the same string only when the `storage_id` is already a slug (`'admin/movies'` renders as `admin-movies`, `'2026_reports'` as `listing-2026_reports`), and `ListingIdentity.for` is the public entry point that applies exactly the component's rule. Render the DataTable from a partial shared by `index.html.erb` and `index.turbo_stream.erb` while you are there; the stream replaces the node that carries the selection controller, so the two branches have to produce the same DOM.

- **DataTable toolbar — the row is regrouped and gets a separator.** It now reads `search + filters · group by · columns ￨ saved views · persistence` on the left, with the view switch pinned to the right: **left is the state of the listing and how it is remembered, right is how it is displayed**. The display mode does not travel inside a saved view's payload, so the view switch is the only thing left on that side; saved views, the persistence bookmark and the column selector moved off the right. The `⋯` collapse behaviour is unchanged. Two things a host may notice. The home groups are now three — `left`, `memory` and `right` — so CSS or tests matching `[data-toolbar-overflow-group="right"]` for saved views or the column selector need to point at the new group; and `OVERFLOW_PRIORITIES` was renumbered (group by `40`, columns `35`, saved views `30`, persistence `25`), because the priority is not only the survival order: expanding re-sorts each group by descending priority, so it *is* the visual order inside a group. The numbers descend in reading order, which is what keeps the `⋯` listing collapsed controls in the same order as the row. The vertical rule between `columns` and `saved views` is deliberately NOT a control: it carries no priority and is not an `item`, so it can never travel into the `⋯`; the controller only hides it when a collapse empties either group it flanks, plus `max-sm:hidden` for the no-JS case. Empty groups are hidden as well — a group with no children is still a flex item and keeps stealing the row's `gap` from the search field on a phone.

- **Export leaves the DataTable toolbar and moves to the page's `⋯`.** `dt.with_export` is gone — calling it raises `NoMethodError`, on purpose — and the export now hangs off the surrounding page component: `page.with_export(url: movies_path)`. Exporting is an action ON the page, not a control of how the listing is displayed, and putting it next to the primary action is what gives import and print somewhere to land later instead of another loose toolbar button. `Bali::DataTable::Export::Component` stays where it is (same class, same `view_components.bali.data_table.export.*` scope) and remains usable standalone; what disappeared is the slot, `export` from `OVERFLOW_PRIORITIES` and the export branch of the toolbar's right group. Its `method:` keyword is also gone: under Turbo it only emitted a `data-method="get"` that does nothing, and the links now carry `data-turbo="false"` instead, because a CSV is not a response Turbo Drive can render — the visit used to stall halfway instead of starting the download. Hosts move one line from the DataTable block to the page block, and must answer the format: a controller whose `respond_to` only declares `html` returns 406 for `?format=csv`.

### Added

- **A sortable column now looks sortable.** `Bali::Table::Header` painted an arrow only on the column that was ALREADY sorted, because Ransack's `default_arrow` is `nil` — so every other sortable header rendered as bare text, indistinguishable from a fixed one, and the only way to find out a column could be sorted was to click it. Ransack's own indicator is switched off (`hide_indicator: true`) and the component builds the label: a dimmed `chevrons-up-down` on every sortable header that brightens on hover and on keyboard focus, and a single directional chevron at full opacity on the active one. The `<th>` also gains `aria-sort` (`ascending` / `descending` / `none`), which the table had never emitted in any form: the indicator is `aria-hidden`, so the state is announced once, by the right element — Ransack's old text arrow was read out as "black down-pointing triangle". Headers without `sort:` are untouched (no `aria-sort`, no indicator), and the sort href is unchanged. One trap if you extend this: `sort_link` merges every option that is not `class:` or `data:` into the HREF, so an innocent `title:` on the link comes back as `&title=...` in the sort URL; a test pins the query string to `q[s]` alone.
- **Page components get a first-class hole for secondary actions** — `page.with_secondary_action(**options, &block)` and `page.with_export(url:, formats:, params:)`, shared by all FIVE page components (`IndexPage`, `ShowPage`, `FormPage`, `DashboardPage`, `DocumentPage`) through `Bali::PageComponents::Shared`. They render a `⋯` dropdown next to the primary action, inside the same group; the menu is not rendered at all when nothing is declared, because a button that opens an empty menu is a bug. `with_secondary_action` takes the same options as `Bali::Dropdown#with_item` (it *is* an item of that dropdown, so it inherits the menuitem role and the Link/DeleteLink selection instead of every host re-writing them), and stores the ARGUMENTS rather than rendered content — the same pattern as `DashboardPage#with_stat`. `with_export` renders a section titled "Export filtered" with one item per format. Two consequences worth knowing: `renders_many :actions` moved up into the concern, so the four page components that declared it no longer do, and `FormPage` — the only one whose PageHeader carried no block — now renders an actions bar, which it never did before. Supporting pieces: `Bali::Dropdown` gains `tag: :title` (`Bali::Dropdown::Title::Component`), the section heading that lets a menu group items without opening a submenu, which the column selector and saved views were already hand-rolling; a menu whose only items are titles still does not render.
- **DataTable filter-persistence bookmark is its own toolbar control** — `Bali::Filters::PersistenceToggle::Component`. The bookmark that decides whether a listing remembers its filters used to be a button INSIDE the filters panel, and `Bali::DataTable::SimpleFilters` carried a hand-copied second version of the same markup inside its GET form. It is now one component the DataTable renders as an independent toolbar item, next to the filters node where it already sat, so the `⋯` menu can treat it on its own and the upcoming toolbar regrouping can move it without touching the panel. `Filters` and `SimpleFilters` gain `persistence_toggle:` (default `true`): used standalone they keep painting it exactly as before, and the DataTable forces it to `false` — two `filter-persistence` controllers over one `storage_id` fight over localStorage and the cookie. The flag turns off the CONTROL only; the panel still receives `persist_enabled` and keeps its "Auto-saved" hint. The DataTable captures the storage id RESOLVED by the slot rather than re-deriving it from the filter form, so a host passing `storage_id:` straight to the slot still gets a bookmark. Two side benefits: the toggle leaves the panel's `data-turbo-permanent` subtree (which the overflow contract forbids for anything collapsible), and the button finally has an accessible name — both its icons are `aria-hidden` svgs and `data-tip` is invisible to a screen reader, so it had none. New i18n key `bali.filters.persistence_label` ("Remember filters" / "Recordar filtros"); the existing `bali.filters.persistence_enabled` / `persistence_disabled` keys did NOT move, so host overrides keep working.
- **DataTable SavedViews** - the dropdown now signals the ACTIVE view: the trigger button shows its name (with a filled bookmark icon) and the matching item gets the `active` class. Active is the view applied by URL (`?saved_view=`), or — because persistence rewrites the URL clean on the way back — the personal view whose payload matches the form's CURRENT state (`FilterForm#view_matches_current_state?`), or the static `default_views` shortcut whose URL query describes that same state. One winner, no double marking. The dropdown also gains `max-h-[70vh] overflow-y-auto` and full-width rows so long lists stay usable.
- **DataTable GroupByControl** - accepts explicit `options:`, `current:`, `param:`, `include_none:` and `label:`, so a surface whose grouping does not live in a FilterForm (e.g. a server-rendered Gantt with its own grouping param) can reuse the SAME "Group by" dropdown instead of hand-rolling a lookalike control. The FilterForm-driven path is unchanged and remains the default.

- **DataTable saved views (B2)** — named filter combinations. `Bali::FilterForm` gains `saved_views_store:`, a `list/find/save/delete` contract (Bali defines the WHAT, the store decides the WHERE — same spirit as the `Rails.cache` persistence); `?saved_view=<id>` REPLACES the filter state with the view's payload (attributes gated by the declared ones, `group_by` re-passes the whitelist) and flows through the normal persistence so the applied view becomes the listing's last state — always overwriting it: an applied view whose payload is EMPTY (a "show everything" view) also beats stale cached filters instead of being mistaken for "no filters submitted". New `Bali::DataTable::SavedViews` component (`with_saved_views` slot): apply/save-current/rename/delete, plus static `default_views` shortcuts ("Suggested" section). The column selector gains per-device persistence (localStorage keyed by table) and visible columns travel INSIDE the saved view (a Stimulus controller injects them on save; an applied view wins over the device memory).

  The engine SHIPS the default implementation of that contract, so adopting saved views in an app is: `bin/rails bali:install:migrations && bin/rails db:migrate`, mount `Bali::Engine`, and `dt.with_saved_views` on a DataTable whose FilterForm passes `storage_id:` plus `saved_views_store: :default, saved_views_owner: current_user` — zero models, controllers or routes in the app. Pieces: table `bali_saved_views` (POLYMORPHIC `owner` on purpose: phase 2 — team/role views — changes the owner, not the schema; `jsonb` payload on PostgreSQL, `json` elsewhere), model `Bali::SavedView` (payload sliced to the FilterForm contract, accepts Hash or JSON string, invalid JSON → `{}`), `Bali::SavedView::Store` (scoped to one owner + one `storage_id`, upsert by name; also reachable as `Bali::SavedView.store_for(owner, storage_id)` for the explicit one-liner), and `Bali::SavedViewsController` (create/update/destroy; everything scoped to the owner — a foreign view is a 404, never a 403 that confirms existence). The engine controller does NOT inherit the host's ApplicationController hooks, so authorization lives in config: `Bali.saved_views_owner` (default `controller.try(:current_user)`) resolves the owner and `Bali.saved_views_authorize` (default: owner present, otherwise 403) gates every mutation. That also means a `current_user` living in a host concern (bali-auth's case) does not exist on the engine controller by itself — the host either teaches it (`Bali::SavedViewsController.include YourAuthConcern` in a `to_prepare`, skipping the concern's own before_actions) or configures `saved_views_owner`. When `with_saved_views` gets no `url:`, it defaults to the mounted engine routes with the form's `storage_id` in the query string (no `storage_id` → the dropdown does not render). An app-provided store still works unchanged — team-shared views remain just another store implementation.

- **BlockEditor** - the install boilerplate every consuming app had to write by hand now ships with Bali (extracted from the first real adoption, in afal-apps). Three pieces: `bali-view-components/block-editor-entry`, a self-registering bundler entry that turns the app's `editor.js` into a single import (it registers on the existing `window.Stimulus` — a standalone bundle starting a second Stimulus application mounts every controller twice); `bali-view-components/block-editor-loader`, a tiny module for the MAIN bundle that watches the DOM and injects the editor's `<link>`/`<script>` the first time a `block-editor` appears — necessary because drawers inject content with `innerHTML`, where `<script>` never executes, so a view-level `<script>` silently left the editor unmounted; and `Bali::BlockEditorHelper#block_editor_meta_tags`, exposed to host views by the engine, which publishes the digested asset paths the loader reads (only the server knows them). The meta names are now a contract inside one library instead of a convention copied between apps.

- **BlockEditor** - `format: :markdown` with a matching `markdown_content:`, serialising through `blocksToMarkdownLossy` / `tryParseMarkdownToBlocks`. This is what lets an application adopt the editor WITHOUT migrating stored data: search, plain-text exports, APIs and LLM prompts keep reading the same column. Verified against 14 real documents: 12 round-trip word-for-word, GFM tables and nested checklists survive intact, and the first save normalises whitespace and list markers before converging. Known loss (silent, inherent to Markdown): underline, text/background colour, alignment, merged cells, and text in `<angle brackets>`, which Markdown reads as an HTML tag.
- **BlockEditor** - `preset:` — `:full` (default) or `:simple`, which cuts the UI down to bold/italic/strike/code/link plus block type, with no slash menu, side menu or file panel, and takes the border and scale of a form field. The preset restricts the UI only, never the schema: an editor that could not represent something already stored would destroy it on the next save.
- **BlockEditor** - `Bali.block_editor_syntax_highlighting` (default `true`) plus a per-component `syntax_highlighting:` override. Whether `shiki` is installed is an installation-level fact, so an app decides it once in the initializer rather than at every call site — and leaving it on WITHOUT installing shiki logs an error the first time someone inserts a code block. `shiki` was always in the import graph, and it bundles every grammar it ships: on a real application, turning it off took the editor bundle from **14.3 MB to 4.0 MB** (`@shikijs/*` alone accounted for 9.08 MB, 64% of the graph).
- **FormBuilder** - `f.rich_text_group :field` and `f.block_editor_group :field` (`lib/bali/form_builder/rich_text_fields.rb`), giving the component the same ergonomics as Rails' own `rich_text_area`: the input name, the current value and the storage format are derived from the form object. `rich_text_group` defaults to the simple preset and Markdown storage. Not to be confused with the pre-existing `rich_text_area_group`, which is the ActionText/Trix helper.
- **BlockEditor** - declares the peer dependencies it actually imports. The ~35 `@tiptap/*` packages the Rich Text Editor needs existed only as a code comment that named three and trailed off in an ellipsis; `shiki`, `lowlight`, `highlight.js`, `tippy.js`, `lodash.throttle` and `@rails/request.js` were undeclared entirely. The paid `@blocknote/xl-*` packages were REMOVED from `peerDependencies` and documented separately, so nobody installs a commercial licence by reflex.
- **BlockEditor** - a component rendered while `Bali.block_editor_enabled` is false now logs a warning naming the flag, and shows a visible placeholder in development. It used to render an empty string: no markup, no error, and `assert_response :success` still passing — the most common way this component is mis-installed.
- **BlockEditor** - `--bali-block-editor-min-height` custom property, so a form can size an editor the way it sizes a textarea's `rows` instead of every instance claiming 200px.

### Fixed

- **The end-to-end reference page was missing two of the things it exists to demonstrate.** `/admin/movies` in the dummy app is what the migration guide points at, and it had no saved views and no way to sort by studio — so the composition it documented was not the one v3 describes. Saved views are now wired the way the guide says to adopt them: `saved_views_store: :default` plus `saved_views_owner: current_user` on the FilterForm, `dt.with_saved_views` with no `url:` (it falls back to the mounted engine routes), and `Bali.saved_views_owner` set in the initializer — that last one is not optional, because `Bali::SavedViewsController` does not inherit the host's `ApplicationController` and the default resolver's `controller.try(:current_user)` returns `nil` there, which 403s every save, rename and delete while the dropdown itself still renders fine. The Studio column becomes sortable through the association's Ransack path (`sort: :studio_name`), which is also what the canonical Lookbook preview now shows.
- **A dead quick search that answered 200 with every row.** The reference listing searched `name_or_genre_or_tenant_name_cont`, and `tenant` on that model is an `alias_method` for the `studio` association — a Ruby method Ransack cannot see. Ransack does not raise on an unreachable field inside a combined predicate: it drops the WHOLE condition, so typing anything into the search box returned the complete unfiltered set with no error, no log line and a 200. Fixed by searching the association's real Ransack path (`studio_name`). Worth internalising rather than just reading, because it is a property of Ransack and not of this app: one bad field kills the entire quick search, and only an assertion on the result SET can catch it — a request test asserting `assert_response :ok` passes throughout.
- **Export ignored the filters.** Exporting a filtered listing silently exported everything. `/admin/movies?q[name_cont]=dune&group_by=status` rendered `href="/admin/movies?format=csv"` — no filters, no search, no sort, no grouping — because `export_url` was `"#{url}#{separator}format=#{format}"` and hosts pass a bare path, so there was never a query string to carry. The user filtered a listing down to three rows, clicked export and got twenty, with nothing anywhere saying so. The href is now built with the shared `Bali::DataTable::ToolbarHref`, the same helper the group-by and view-switch links already used, so the export carries the same slice of data the user is looking at. Using the shared helper rather than `request.fullpath` is load-bearing twice over: `TRANSIENT_PARAMS` drops `page`, because exporting page 3 of a listing is never what "export" means, and drops `clear_filters`, which on the server runs `Rails.cache.delete(cache_key)` — a user sitting on `?clear_filters=true` would have wiped their stored filters as a side effect of clicking export. The new `params:` keyword decides the source: `nil` (default) reads the current request, an explicit hash overrides it, `{}` opts out and exports everything on purpose. Because the `⋯` now lives in the PageHeader — outside the node a filter submit's turbo-stream replaces — the links also carry a new `export-links` Stimulus controller that re-syncs their hrefs from `window.location` on connect; without it the first filter would freeze them on the slice from the initial page load and reintroduce the same bug through the back door. One caveat when verifying: with filter persistence ON and a clean URL, the correct href looks byte-for-byte like the buggy one (`/admin/movies?format=csv`) because the export request re-enters the same controller and restores the same state from the cache. Check it with persistence OFF, which is the default.

- **DataTable / BulkActions** - selecting a row no longer pushes the listing down. The contextual selection row replaces the toolbar in the same slot but measured 18px taller (`py-2` contributed 16, `border` 2), so every selection and every clear shifted the layout. The outline is now a `ring` (a box-shadow: zero layout cost) with no vertical padding, and both rows declare the same explicit `min-h-8` — the height of a daisyUI `sm` control, which is what the toolbar already measured by accident. A test pins the two constants together so they cannot drift. Because that leaves the row exactly as tall as an `sm` button, the contextual bar sizes its own actions at `xs`: inside a tinted surface of fixed height, `sm` buttons sit flush against the edges and read as cramped, while `xs` leaves 4px of air without changing the height. The floating bar has no such ceiling and keeps `sm`; an explicit `size:` on an action wins over both.
- **Pagination** - the current page was indistinguishable from the others. The markup was already correct (`btn-active` + `aria-current="page"`), but daisyUI 5's `btn-active` barely darkens a plain `btn`, so the page you were on looked exactly like the ones you weren't. It now carries `btn-active btn-primary`, the same marker the rest of Bali uses for "this is the selected one" (see `ViewSwitch::View`). The existing test passed throughout, because it asserted the class rather than the visible distinction; it now pins both.
- **Dependencies** - three security advisories cleared. `rails` 8.1.3 → 8.1.3.1 for CVE-2026-66066 / GHSA-xr9x-r78c-5hrm, possible arbitrary file read and remote code execution in Active Storage variant processing — the only one that reaches production code in a consuming app. On the JS side, `js-yaml` (5.2.1 → 5.2.2) and `brace-expansion` (5.0.4 → 5.0.9) clear two high-severity denial-of-service advisories (exponential parsing time in flow collections; exponential-time expansion of consecutive non-expanding `{}` groups); both are transitive dev dependencies, pinned through the existing `resolutions` block.
- **DataTable** - a host that declares `with_view_switch` but forgets `display_mode:` no longer gets a switch whose links change the URL and never change the view. `display_mode` now falls back to `params[<view_param>]` (the component already had the query string in hand — it builds those very hrefs with it) and then to the first declared view.
- **DataTable / GroupByControl / ViewSwitchControl** - the toolbar's navigation links no longer corrupt a `url:` that already carries a query string. `"#{url}?#{query}"` turned `admin_movies_path(scope: 'archived')` into `/admin/movies?scope=archived?view=grid`, which Rack parses as one corrupt `scope` and no `view`: the click did not change the view and poisoned the scope. Both controls now build the href through the shared `Bali::DataTable::ToolbarHref`, which parses the base URL and merges. Export, SavedViews and Filters already handled this shape.
- **DataTable** - the listing identity is now public as `Bali::DataTable::ListingIdentity.for(filter_form)`. The docs told hosts to target `@filter_form.storage_id` in `turbo_stream.replace` while the component renders the SANITIZED value, so any `storage_id` that is not already a slug pointed the stream at nothing — silently, which is exactly the failure mode that section of the migration guide exists to prevent.
- **DataTable** - the `⋯` gate now looks at what the toolbar actually RENDERS, not at which slots were declared. `with_saved_views` on a form without a store leaves `render?` false, but the slot predicate stayed true, so a phone got an empty wrapper inside the menu and a "More options" button that opened a blank panel.
- **DataTable** - the `⋯` panel is no longer declared as a menu. It holds whole widgets (nested dropdowns, column checkboxes, the rename form), and `role="menu"` exposed children that role does not allow and put screen readers in menu mode over a form. `Bali::Dropdown` gains `menu: false` for a generic popover container, and its keyboard handler now ignores events raised inside a NESTED dropdown (both controllers were processing the same keydown, so one arrow skipped two items and Escape inside an input closed the outer container) and inside form controls, where arrows belong to the field.
- **DataTable toolbar overflow** - crossing the breakpoint no longer drops keyboard focus on the floor. `closeOpenDropdowns` blurred the active element and the collapse moved it, leaving focus on `<body>` with no ring and no announcement — on a zoom to 400%, the 320px viewport WCAG requires. Focus is now restored to the same control, or to the `⋯` trigger when the control ended up inside the closed menu.
- **DataTable toolbar overflow** - `OVERFLOW_THRESHOLD` is emitted as the controller's `threshold` value instead of being duplicated as a JS default, so moving it cannot leave the server-side `⋯` gate and the client-side collapse rule disagreeing.
- **BulkActions** - selection changes are announced. The counter and the contextual bar changed with no live region at all, so a screen-reader user selecting rows got no confirmation the selection existed — and no hint that the toolbar with search and filters had just left the page (WCAG 2.1 SC 4.1.3). A `role="status"` region now lives permanently in the DOM (a region that appears together with its text is not announced).
- **BulkActions** - the clear (✕) button no longer throws focus to `<body>`. It lives inside the bar it hides, so activating it made the focused element `display:none`; focus now moves to the select-all checkbox, or to the first control of the restored toolbar.
- **ViewSwitch** - the active view is marked with `aria-current="page"` instead of `aria-pressed`. These are `<a>` elements that navigate, and browsers drop `pressed` on `role=link`: the active mode was expressed by colour only and the three links sounded identical to a screen reader (axe reported `aria-allowed-attr` on every one of them).
- **DataTable ColumnSelector / Export / SavedViews** - the trigger buttons carry an explicit `aria-label`. Their visible label lives in a `hidden sm:inline` span, so on a phone — until the JS moved them into the `⋯`, and forever if the bundle failed — they were icons with no accessible name. The saved-views label is computed, not static, so it never contradicts the visible text (Label in Name).
- **Table** - `selectable: true` no longer leaves the empty state one column short. The empty row's `colspan` used `headers.count`, which ignored the selection column and counted hidden headers.
- **Table Row** - `select_label:` gives the row checkbox the record's name. Without it every row's checkbox is called "Select row", and a screen reader's form-controls rotor lists N indistinguishable entries.
- **Filters** - the preserved-state hidden fields (`view`, `group_by`, host params) no longer produce duplicate element ids: in popover mode they are rendered in BOTH forms, and the id was derived from the name.
- **Filters** - clearing the search or the filters preserves the listing state. Both handlers rebuilt the URL from `urlValue` alone — which hosts pass without a query string — so the `view` hidden field this release added precisely to survive filter round-trips was dropped, and clearing a search from the cards view landed the user back in the table.
- **DataTable SavedViews** - applying a saved view keeps the current display mode (the view switch already preserves `saved_view`; the reverse direction did not), and saving a view from a mode with no column selector uses the columns the APPLIED view imposed rather than the device's older localStorage memory.
- **DataTable SavedViews** - the `saved-views` Stimulus controller shipped with the component but was never registered (nor exported) by `registerAll`, so "Save current view", rename and the column-capture on save were dead in every host app. It now registers alongside `column-selector`.
- **Filters** - the persistence toggle no longer promotes a server-rendered `false` into a durable user preference. `connect()` synced the cookie unconditionally, so merely VISITING a listing where persistence is off by context (a deep-link that disables restoring, e.g. a triage view) wrote `bali_persist_<id>=0` for a year — and rewrote it on every visit, silently disabling the feature everywhere until the user found the bookmark button. Only an explicit toggle (which is what writes localStorage) may write the cookie now.
- **Filters** - submitting the quick search no longer flips an applied `OR` to `AND`. The hidden `q[m]` carried the COMPONENT's default (`:and`) rather than the applied combinator, so a two-group OR silently narrowed to AND on the next search — and with persistence on, the corrupted state was written to the cache. `combinator:` now defaults to nil, DataTable auto-populates it from the FilterForm's applied value (new `FilterGroupParser#applied_combinator`), and `q[m]` is emitted only when the state actually carried one.
- **Filters** - a `between` condition with both ends blank no longer emits a phantom group. `{start: "", end: ""}` is a Hash, so it passed `present?` and produced `q[g][i][m]`/`q[m]` with no condition at all — enough for the server to treat "search only" as "new filters" and cache a ghost state.
- **Filters** - `saved_view` joins `EXCLUDED_PARAMS`. When a host passes the current URL as `url:`, preserving it made the server re-apply the view's payload on the next submit, silently discarding the filters or search the user had just typed.
- **Filters** - the pushed history URL no longer describes the PREVIOUS filter. `buildUrl()` appended the popover form's params and then the search form's, which since the hidden-field fix carries the applied state too — on nested parse the last key wins, so editing or removing a condition and applying left the old one in the URL (definitive under `turbo_stream: true`).
- **DataTable SimpleFilters** - same tooltip fix as `Filters`: the localized texts sat on the button child where Stimulus never looks, so `connect()` overwrote the server-rendered `data-tip` with the English fallback on every load.
- **DataTable SavedViews** - a view whose payload normalizes to EMPTY (the headline "save my column layout", or a "show everything" view) no longer matches by state. It described the clean state, so it was marked active on every visit while its columns were NOT applied — `columns` only applies via `?saved_view=`. Such views are recognized only when applied by URL.
- **DataTable SavedViews** - a shortcut or view stays marked after a round-trip through the builder or the search box. The builder always re-emits `m` per group (and `q[m]`) even when the original state carried none, which broke the comparison; no-op combinators (a single-condition group, a single group) are now normalized away — never where AND vs OR actually changes the result.
- **DataTable SavedViews** - `default_views` matching now understands `group_by` (a top-level param, outside `q`) and the quick-search predicate (which the form keeps in `search_value`, not `attributes`). Translating less produced both false positives (a grouping-only shortcut normalized to empty and matched anything) and false negatives (a search shortcut never matched).
- **DataTable SavedViews** - the rename inputs get unique ids; N views produced N+1 duplicate `id="name"` (invalid HTML, confused autofill).
- **DataTable SavedViews** - saving from a mode without a column selector in the DOM (a card grid, a Gantt) now falls back to the selector's per-device memory instead of dropping `columns`, so a view no longer "forgets" half its state depending on where it was saved from.
- **FilterForm** - the persisted state now includes `group_by`. Coming back to a listing restored the filters but lost the grouping, and a saved view that groups stopped being recognized as active.
- **FilterForm** - clearing the search no longer restores cached state when persistence is OFF. That branch read the cache before the `persist_enabled` check, so the clear-search button became a back door for filters the URL no longer described.
- **FilterForm** - an explicit `group_by` in params now wins over an applied view's payload. With `?saved_view=` still in the URL (the grouping links preserve the query), the payload overwrote the click and the control looked dead.
- **DataTable** - explicit `preserved_params` MERGE with the active `group_by` instead of replacing it; a host preserving its own params silently dropped the grouping on every filter/search submit.
- **DataTable GroupByControl** - the one-shot commands (`clear_filters`/`clear_search`) no longer ride along in the option hrefs. They are actions, not navigation state: carrying them re-executed the wipe on every later grouping click, and a shared link repeated it on every open.
- **DataTable GroupByControl** - the trigger gets an explicit `aria-label`: its text lives in a `max-sm:hidden` span, leaving an icon-only button with no accessible name on mobile.
- **JS entry** - `ColumnSelectorController` is exported from the package root alongside `SavedViewsController`; selective imports of it failed to build.
- **Filters** - submitting the quick search no longer WIPES the applied filters. The search form only carried the search input, so the server read "empty attributes + new search" as the new state — clearing active filters on screen and, with persistence on, overwriting the stored state too. The applied `q[g][...]`/`q[m]` state now travels as hidden fields in the search form (the consolidated `between` operator expands back to its `gteq`/`lteq` pair; empty builder rows stay out).
- **Filters** - the persistence toggle tooltip ignored the localized texts and always fell back to hardcoded English ("Filter persistence enabled…"). The controller read `this.data.get(...)` on its own element while the ERB placed the attributes on the button CHILD, where Stimulus never looks. The tooltips are now proper Stimulus values on the controller element.

- **Engine** - v2.17.0 broke EVERY host app at boot with `uninitialized constant Bali::BlockEditorHelper`. Two stacked causes, each invisible in this repo: (1) the engine assigns (not appends) its `eager_load_paths` and `app/helpers` was not on the list, so the constant was not autoloadable in a host — masked here because Lookbook pushes the engine's dirs into the dummy's autoloader; (2) the helper was exposed via `on_load(:action_controller_base)`, and any host that loads `ActionController::Base` during boot (any gem requiring it does) fires that hook before Zeitwerk is set up, so the constant raises even with the path declared — masked here because the dummy never loads it that early. `app/helpers` is now declared, the exposure moved to `config.to_prepare`, a test pins the engine config itself, and the fix was verified against a real host app.
- **BlockEditor** - the header comment of `bali-view-components/block-editor` told installers to `yarn add @blocknote/xl-multi-column` — one of the paid GPL-3.0/commercial packages that v2.16.0 deliberately removed from `peerDependencies`. It now lists only the free packages.
- **SlimSelect** - `include_blank`/`prompt` on a GROUPED (optgroup) option list no longer destroys the list. The placeholder promotion shipped in v2.16.0 prepended a flat option, and Rails decides between `options_for_select` and `grouped_options_for_select` by looking only at the FIRST element — so every optgroup was flattened into garbage options and `selected:` stopped matching. Grouped lists keep Rails' plain `include_blank` behavior (the blank renders as a regular option, as before v2.16.0); flat lists keep the placeholder promotion.
- **BlockEditor** - an application that installs only the free MPL-2.0 packages can now BUILD. The four paid `@blocknote/xl-*` packages and their companions (`ai`, `docx`, `@react-pdf/renderer`) were loaded through `import()` calls nested inside `Promise.all([...])`. esbuild only treats a dynamic import as optional when it can attribute the failure to a surrounding `try`, which it cannot do for an import in an argument list — so it demanded all of them at BUILD time, even for an app that never enables AI or exporting. Measured on a real app: `yarn build` failed with **27 errors**; after awaiting each import on its own line it builds clean. This matters beyond ergonomics: those four packages are `GPL-3.0 OR PROPRIETARY`, so "just install what the library asks for" quietly pulled a closed-source app into a paid commercial licence. Same fix applied to `shiki`.
- **BlockEditor** - compatible with BlockNote >= 0.51 again. Its parsers stopped returning promises in 0.51, and the HTML path still called `.then()` on the result, which throws on a plain array. The peer range moved to `>=0.51.0` for a second reason: 0.47 corrupts table data in two ways (a `|` inside a cell is not escaped on export, so re-parsing drops a cell; and a table with no header row promotes the first data row to a header).
- **BlockEditor** - a form submitted within the 500 ms sync debounce posted the PREVIOUS content, losing the user's last edits with no error. The controller now also flushes on the form's `submit` event. Drawers that submit over fetch hit this on every fast save.
- **BlockEditor** - the editor rendered in English regardless of the application locale. It now follows `I18n.locale` (BlockNote ships ~23 locales) and accepts an explicit `locale:`.
- **BlockEditor** - documentation corrected: the import example named the package root, which does not export `BlockEditorController` (the subpath `bali-view-components/block-editor` does), and two passages claimed the XL packages had no build-time cost.


## [v2.16.0] - 2026-07-26

### Fixed

- **SlimSelect** - the widget no longer dies (search stops filtering, clicks stop selecting, only the arrow toggles it) after a Turbo restoration visit. Turbo caches a page snapshot while controllers are still connected, so the snapshot already contained the `.ss-main` widget SlimSelect injects; on back/forward — or any navigation to an already-cached page — the controller reconnected and stacked a second, event-less widget over the dead cached one. The controller now tears SlimSelect down on `turbo:before-cache` (so the stored snapshot stays clean) and defensively removes any stale `.ss-main` before re-initializing. Only reproducible through Turbo navigation, not a hard reload — which is why it surfaced in normal app use but not in isolated page loads.
- **SlimSelect** - `include_blank` / `prompt` now render a proper SlimSelect placeholder instead of a selectable, checkmarked option. Rails emits a plain empty `<option>`; SlimSelect only treats an option as a placeholder — muted and excluded from the selectable list — when it carries `data-placeholder="true"`, so the "choose one" blank previously showed up inside the dropdown as a pickable row with a selected checkmark. `slim_select_field` now promotes the blank of a flat option list to a `data-placeholder="true"` option.

## [v2.15.0] - 2026-07-22

### Added

- **ViewSwitch** - new `Bali::ViewSwitch::Component` (#636), a DaisyUI `join` of buttons to switch between sibling views of the same content (list / table / board / schedule). Each view is a real link (`with_view(name:, icon:, href:)`); the active view (`btn-active btn-primary` + `aria-pressed`) is autodetected by matching the request path against `href` via `Bali::PathHelper#active_path?` (same logic as `Tabs::Trigger`), with an explicit `active:` override. Default look is icon + label; `icon_only: true` renders square buttons where the name becomes the native tooltip (`title`) and the accessible label (`Bali::Tooltip` wrapping was rejected: a wrapper between `.join` and `.join-item` breaks DaisyUI's border collapse between adjacent buttons). Sizes `:xs`-`:xl` (default `:sm`); per-view options passthrough supports `data: { turbo_action: 'replace' }`. Replaces the ad-hoc view toggles consuming apps keep reinventing; migrating the `DataTable::ActionsPanel` table/grid toggle to this component is a follow-up.
- **EmptyState** - new `Bali::EmptyState::Component`, the standard empty state for sections with nothing to show (#640): a centered flex-col block with an optional icon in a soft `bg-base-200` circle, a required `title:` (`text-base-content`), an optional `description:` (`text-base-content/60`) and an optional CTA via the `cta` slot (a `Bali::Link`, button or drawer trigger). `size:` controls vertical padding and icon scale — `:sm` (`py-4`, compact for cells/panels), `:md` (`py-8`, default, matches the Table empty state) and `:lg` (`py-12`, full page). Extra HTML attributes pass through to the wrapper `div`. Replaces the per-app zoo of dashed boxes and loose `<p>` tags documented in afal-apps and gobierno-corporativo.
- **IndexPage / ShowPage / DashboardPage** - new `nav` slot (`renders_one :nav`) rendered between the `PageHeader` and the body (in `DashboardPage`, before the stat cards) inside a `.page-nav` wrapper with standardized spacing (`mt-4`), for second-level navigation that pages previously had to embed in the body by hand with ad-hoc margins (#637). Documented the two-level navigation recipe (level 1 `Tabs style: :border` with icon+label, level 2 `Tabs style: :box, size: :sm`, both with `href:` tabs and the active section in the PATH so GET filter forms don't drop it) in the components guide, plus a new `IndexPage` "With nav" Lookbook preview. Pages without a `nav` slot render unchanged.

### Changed

- **Table** - the built-in empty state now renders through `Bali::EmptyState::Component` (#640), so tables and standalone empty sections look identical. API unchanged (`with_no_records_notification` / `with_no_results_notification` / `with_new_record_link` behave as before); custom notification content now sits inside the exact same centered container as the component (single source of truth via `Bali::EmptyState::Component.container_classes`). Visual nuance: the default "No records"/"No results" message is now the EmptyState title (`font-medium text-base-content`) instead of the previous muted `text-base-content/60` paragraph, and the `py-8` padding moved from the `td.empty-table` to the inner container.
- **FilterForm** - unified filter DSL (#644). `filter_attribute` is now the single declaration from which BOTH filter UIs derive: the advanced `Filters` popover (as always, via `available_attributes`) and, with `simple: true`, the inline `SimpleFilters` row (via `simple_filters_config`). New kwargs: `simple:` / `advanced:` (which UIs offer the attribute), `input:` (simple widget override, e.g. `type: :select, input: :slim_select`; validated against the widget list, invalid values raise at class-definition time), `predicate:`, `blank:`, `default:`, `icon:`, `collection:` (alias of `options:`), and `step:`/`placeholder_min:`/`placeholder_max:` for `:number_range` (previously reachable only through instance-level hashes). `options:`/`collection:`, `label:` and `blank:` also accept **zero-arity procs resolved per-instance with `instance_exec`** — inside them you can use `scope` (the relation the controller passed in, typically already narrowed to the policy scope) and per-request `I18n`, removing the two reasons apps had to bypass the class DSL (overriding `available_attributes` wholesale, or building `simple_filters:` hashes in the controller). Both escape hatches remain supported.

### Deprecated

- **FilterForm** - `simple_filter` is now a thin alias of `filter_attribute(..., simple: true, advanced: false)` and is soft-deprecated (no runtime warning; existing forms keep working unchanged and stay out of the advanced popover, exactly as before). New code should declare one `filter_attribute` per attribute. Note for exotic procs: collection procs now run under `instance_exec` (receiver = the form instance instead of the class where the lambda was defined); lambdas referencing constants/models — every known usage — are unaffected.

### Fixed

- **Selects** - long option labels no longer overlap the chevron in narrow selects on Chrome ≥ 135 (#638). DaisyUI 5.5 opts every `.select` into Chrome's customizable select (`appearance: base-select`), a mode that ignores the author's `overflow`/`text-overflow` — labels stopped truncating at the content edge and ran over the arrow painted in the padding area (most visible in the narrow field/operator selects of `Bali::Filters`, where the `truncate` class became a no-op). `bali/forms.css` now reverts `.select` to the classic rendering under `@supports (appearance: base-select)`, restoring the ellipsis before the chevron. Cost: Chrome's styled native popup (`::picker(select)`) is lost — the dropdown looks like Firefox/Safari and Chrome < 135; the visible arrow (DaisyUI `background-image`) is unchanged. Includes a regression Lookbook preview (`Form::Select` → "Narrow With Long Labels").
- **FilterForm** - `simple_filter type: :date` no longer silently discards the declared `predicate:` (#644). `simple_filter :created_at, type: :date, predicate: :gteq` — the DSL docstring's own example — used to filter by `created_at_eq`; it now honors `:gteq`. `:date_range` still has no single predicate (handled as a range). Also, unknown widget `type:` values now raise `ArgumentError` at class-definition time instead of silently rendering a plain select.
- **IndexPage** - accepts `back:` with the same contract as `ShowPage`/`FormPage` and forwards it to the `PageHeader` back button (#639). Nested listings under a resource (e.g. an initiative's approval requests) no longer need to render a `ShowPage` just to inherit the back link. Defaults to `nil` — existing index pages render unchanged.

## [v2.14.0] - 2026-07-21

### Added

- **Table** - row grouping (#621). Pass `group:` to `with_row` and `Bali::Table::Component` emits a group-header row whenever the value changes between consecutive rows, showing the group value and the count of rows in that run (e.g. `Norte (12)`). Grouping assumes caller-controlled order (the component never re-sorts), so on its own it is incompatible with user-driven column sorting and a group may continue across Pagy page boundaries (both addressed by the query-aware grouping below); rows with `group: nil` fall under a localized "Ungrouped" header (i18n `bali.table.ungrouped`). When no row is grouped the table renders exactly as before. Group headers are not sticky and never overlap `sticky_headers:`. Server-rendered markup only — no JS.
- **FilterForm / DataTable / Table** - query-aware grouping v2 (#621). `Bali::FilterForm` gains a `group_by_attribute` DSL (and `group_by_attributes:` constructor option) exposing a whitelisted top-level `group_by` param. When active, the form orders the query by the group field **first** — keeping any user column sort as the secondary sort, so grouping and sorting now coexist (sort-within-groups) — and exposes `group_counts`, the **global** per-group totals over the full filtered (unpaginated) result. The raw param can never reach `.group()`/`.order()`: `resolve_group_by` only returns a declared attribute (Ransack does not authorize `.group`). `Bali::Table` accepts `group_counts:` and shows the global total in each group header (`Norte (30)`), appending a partial hint (`Norte (30) — mostrando 25`, i18n `bali.table.group_partial`) when Pagy split the group; lookup is tolerant of string-vs-symbol keys and falls back to the page-local count. `Bali::DataTable` auto-renders an "Agrupar por" dropdown (links that merge `group_by` into the current URL, preserving filters/search/sort and resetting `page`) whenever the form declares group_by attributes, and carries an active `group_by` through the GET filter forms as a hidden field so applying filters does not drop it. `group_by` is not persisted in the filters cache (URL-only). en/es i18n included.
- **FormBuilder date fields** - date/datetime/time fields auto-fill a `placeholder:` hinting at what the field will parse, unless the caller already passed one explicitly. Derived from the effective `alt_format:` (or an i18n string for verbose formats like `F j, Y`). Part of #620.

### Changed

- **FormBuilder date fields (behavior change, #620)** - date/datetime/time fields are now **typeable by default** and display dates in a **numeric format**. Two ecosystem-wide default flips in the `datepicker` Stimulus controller: `allowInput` now defaults to `true` (the visible input accepts typed dates instead of being read-only, so flatpickr no longer sets `readonly`), and the default display `altFormat` for the date portion changed from the verbose `'F j, Y'` ("Enero 5, 2026") to numeric `'d/m/Y'` ("05/01/2026"). Time portions were already numeric and are unchanged. Combined with the auto-derived placeholder above, every date/datetime/time field now shows a `dd/mm/yyyy`-style hint by default. **Opt out per field with `allow_input: false`** to restore the read-only, pick-from-popup behavior (renders `readonly`, no placeholder). Explicit `alt_format:` and `placeholder:` still override the defaults. The controller also closes the calendar on Escape while typing — flatpickr's own `allowKeydown` gate ignores Escape when `allowInput` is on and focus is in the input, which left the calendar stuck open (and broke the drawer's Escape guard from #619). This changes the rendered display format and typing behavior of every date field across AFAL apps.

### Fixed

- **DocumentPage** - the three-panel body (TOC + content + metadata) now stacks vertically below the `lg` breakpoint instead of crushing the content column to ~1 word per line on mobile (#631). Both side panels go full-width and static (drop `sticky`) with adjusted borders; the TOC panel gets a bounded, scrollable height (`max-h-72`) so a long table of contents doesn't push content off-screen, while metadata flows full height. Content padding narrows (`px-4`) and the header toolbar wraps instead of overflowing. Pure Tailwind utility additions (`max-lg:*` + toolbar `flex-wrap`) — no JS changes, desktop (`≥lg`) layout is unchanged.
- **PageHeader** - actions bar no longer overlaps the title/subtitle at narrow viewports (<640px) on `ShowPage`, `IndexPage`, `DashboardPage`, and `DocumentPage` (#625). Regression from #507: giving the title side `flex-1 min-w-0` made it contribute zero width to the flex line, so `Level`'s `max-sm:flex-wrap` never fired. `PageHeader` now stacks its `Level` vertically on mobile (`max-sm:flex-col max-sm:items-stretch`) with both sides and the actions bar taking `max-sm:w-full`, instead of relying on wrapping. Desktop layout and the #507 long-title truncation are unchanged; `Bali::Level::BASE_CLASSES` is untouched for other consumers.
- **Drawer / Modal** - a form inside a `Bali::Drawer` no longer silently discards typed input when the user presses Escape or clicks the overlay (#619). The drawer now tracks edits and, while the form is dirty, asks for confirmation (via the DaisyUI `confirmDialog`, not `window.confirm`) before closing; a successful submit still closes without prompting. A flatpickr calendar opened inside the drawer also gets its own Escape now — the first Escape closes the calendar, the second closes the drawer. Confirm-on-close is **on by default** for `Bali::Drawer::Component` (opt out per-drawer with `dismissable_without_confirm: true`, or customize the copy with `confirm_close_message:`). `Bali::Modal::Component` gains the same guard as **opt-in** via `confirm_on_close: true` (+ optional `confirm_close_message:`); modal default behavior is unchanged. The mechanism lives in the base `ModalController` (`DrawerController` inherits it).

## [v2.13.0] - 2026-07-19

### Added

- **Status** - new `Bali::Status::Component`, a colorful SmartSuite-style status pill. Presentational and domain-agnostic: pass `options: [{value:, label:, color:}]` + `selected:`. Colors come from a fixed vibrant palette (`:slate :gray :red :orange :amber :yellow :green :teal :blue :indigo :violet :pink`) or a hex escape, rendered as inline styles (theme-independent, no Tailwind safelist). Pass `form: { url:, method:, param: }` to make it editable — click opens a portaled (`position: fixed`, escapes DataTable overflow) panel of colored option rows; selecting a row submits the form natively (respond with a Turbo Stream that replaces the wrapper). `readonly:` forces the read-only pill even when `form:` is given (permission-gated call sites), `clearable:` adds an X + a "no status" row, and `size:` is `:xs/:sm/:md`. The consumer owns the Turbo target id via `id:` passthrough.
### Security

- Bumped `loofah` 2.25.1 → 2.25.2 (resolves GHSA-5qhf-9phg-95m2, GHSA-8whx-365g-h9vv — `javascript:` URI restriction bypass — and GHSA-9wjq-cp2p-hrgf — SVG `href` local-reference bypass) and `rails-html-sanitizer` 1.7.0 → 1.7.1 (resolves GHSA-cj75-f6xr-r4g7, possible XSS). Both are transitive Rails sanitization gems; lockfile-only within existing version constraints. Surfaced by `bundler-audit` (0 open GitHub Dependabot alerts). Full test suite passes; `bundler-audit` and `yarn audit` both clean.

### Changed

- Rolled up all open Dependabot version bumps into one update. npm: `daisyui` 5.6.17 → 5.6.18. Gems (dev): `yard` 0.9.44 → 0.9.45, `simplecov` 0.22.0 → 1.0.2 (1.0 vendors its former runtime deps `docile`/`simplecov-html`/`simplecov_json_formatter`, which drop out of the lockfile). CI: `actions/setup-node` v6 → v7 across all workflows. Supersedes Dependabot PRs #615–#618.

### Fixed

- **Dev server (dummy app)** - `bin/dev` no longer dies on startup. Two bugs in `spec/dummy` broke it: (1) four `@source` directives in `app/assets/tailwind/application.css` had one extra `../` and pointed at non-existent directories, which is harmless for `tailwindcss build` but makes `--watch` fail with `ENOENT`; corrected to the real `app/{views,helpers,javascript}` and `public` paths (the dummy app's own sources are now scanned for classes too). (2) Tailwind v4's `--watch` exits when stdin closes under foreman, tearing down the whole process group — `Procfile.dev` now uses `tailwindcss:watch[always]` (`--watch=always`) so the watcher stays alive. Dev-only; no consumer-facing change.

## [v2.12.1] - 2026-07-17

### Added

- **DataTable / SimpleFilters** - `SimpleFilters::Component` now accepts `storage_id:` and `persist_enabled:`, rendering the same bookmark persistence toggle as `Bali::Filters` (wired to the `filter-persistence` Stimulus controller, which stores the user's on/off preference in `localStorage` + a `bali_persist_<storage_id>` cookie for server-side access). `DataTable#with_simple_filters` auto-populates both from the `FilterForm` (mirroring `with_filters_panel`), so screens using SimpleFilters no longer lose their filters on redirects. The toggle only renders when a `storage_id` is present; restoring filter *values* remains the consuming app's server-side responsibility. Backwards compatible.
- **Tooltip** - new `append_to:` option (default `:parent`) controls where the balloon is portaled in the DOM. Pass `:body` or a CSS-selector String to portal the balloon out of ancestors with `overflow` (wide tables in `overflow-x-auto`, cards with `overflow-hidden`) that would otherwise clip it. Balloon styling now applies via a global `bali` tippy theme (`.tippy-box[data-theme~='bali']`) so it renders correctly wherever the box is appended. Backwards compatible — the default `:parent` behavior and appearance are unchanged.

## [v2.12.0] - 2026-07-16

### Added

- **Message** - new `dismissible:` option renders an integrated close button wired to a `message` Stimulus controller; optional `dismiss_id:` persists the dismissed state in `localStorage` across reloads. Adds first-class live-region semantics via `role:` (`:alert`/`:status`/`:note`) plus `polite:`/`assertive:` sugar, rendered explicitly instead of relying on splat order. Non-dismissible messages render unchanged.
- **SideMenu** - items accept `active_when:` (String prefix, Regexp, Array, or Proc) to keep the parent item highlighted on nested full-page routes (e.g. `/departments/:id/merges/new`) without the over-matching of `match: :starts_with`. Matching logic lives in `Bali::PathHelper#active_extra_path?`; existing `match:` behavior is unchanged.
- **SideMenu** - `with_list(title:)` now accepts `badge:` and `badge_color:` to render a badge next to a section title (e.g. `Pendientes` with a `3` badge), matching the existing item-level badge contract and palette. Sections without a badge render unchanged.

### Changed

- **Docs** - documentation refresh: component counts corrected (75+ components), README categories and status table now list every component (Kanban, ConfirmDialog, DocumentEditor, DirectUpload, page templates, etc.), the components guide now documents all 74 components with per-component sections (usage example + options verified against each initialize signature), organized into categories including new Documents & Editors, Page Templates and Utilities sections, plus the Modal/Drawer turbo_stream submit pattern, the form-builder guide documents `input_name:`/`input_id:` for non-model forms, the AI dev guide catalog (.claude/CLAUDE.md) covers the full component set, and MIGRATION_STATUS.md is marked complete (historical).
- **Tooling** - slimmed the AI dev guide (`.claude/CLAUDE.md`) to point at `docs/` and `app/components/bali/` as the single source of truth for the component inventory instead of an in-file catalog that drifts out of sync; removed dead hook config (`.claude/hooks.json`, which Claude Code never reads, and a `SessionStart` hook referencing a non-existent `check-dependency-versions.sh`); fixed the `frontend-ui-ux-engineer` agent model alias. No effect on the published gem.
- Batch-bumped 5 open Dependabot PRs into one update. Gems: `propshaft` 1.3.1 → 1.3.2, `pagy` 43.4.4 → 43.6.0. npm: `daisyui` 5.6.13 → 5.6.17 (root and dummy), `@babel/preset-env` 7.29.5 → 7.29.7, `cypress` 15.18.0 → 15.18.1. Compiled CSS rebuilt against the new daisyUI.

### Security

- Bumped `view_component` 4.10.0 → 4.12.0 (resolves CVE-2026-54497 and the High-severity `around_render` HTML-safety bypass CVE-2026-54498) and `websocket-driver` 0.8.0 → 0.8.2 (resolves CVE-2026-54463/54464/54465 and the malformed Host header DoS). Lockfile-only within existing version constraints; full test suite passes.

## [v2.11.0] - 2026-07-05

### Added

- **FeedbackWidget** - `TokenGenerator`/`Component` now accept an optional `user_name:` kwarg that adds a `name` claim to the embed JWT (e.g. `"Ana López"`). Omitted entirely from the payload when not given, so existing integrations are unaffected.
- **ImageGrid** - new `empty_state` slot rendered inside a dashed-border centered box instead of the grid when there are no images — typically an "add image" action. Ignored when images are present; grids without the slot render unchanged. Adds `bali.image_grid.empty_state.*` i18n keys (en/es) used by the Lookbook preview.
- **Stepper** - steps accept a `sublabel:` option rendered as a smaller muted line under the title (event date, actor, status note), or a free content block via `with_step(title:) { ... }` for arbitrary markup. Works in both orientations; steps without sublabel render unchanged.
- **Kanban** - `Kanban::Column` accepts an optional `footer` slot rendered after the card list and outside the `SortableList`, for non-draggable per-column actions like "+ add card". Columns without a footer render unchanged.

### Changed

- Consolidated dependency refresh covering all 15 open Dependabot PRs. Gems: `tailwindcss-rails` 4.4.0 → 4.6.0, `caxlsx` 4.4.2 → 4.5.0, `sqlite3` 2.9.2 → 2.9.5, `brakeman` 8.0.4 → 8.0.5, `rrule` git `4d40a71` → `7e11c7e` (0.8.0). npm: `cypress` 15.14.2 → 15.18.0, `playwright` 1.59.1 → 1.61.1, `daisyui` 5.5.19 → 5.6.13 (root and dummy). CI: `actions/checkout` v6 → v7 across all workflows. Compiled CSS rebuilt against the new daisyUI/Tailwind.

### Fixed

- **Modal/Drawer** - the shared `submit` handler now detects `text/vnd.turbo-stream.html` responses and applies them with `Turbo.renderStreamMessage` (closing the modal/drawer on success) instead of injecting the raw `<turbo-stream>` markup as inert HTML. Enables the standard partial-update pattern (close drawer + refresh sections + toast) for forms submitted with `data-turbo="true"`; redirect and HTML-error responses behave as before.
- **DocumentEditor** - "Back to current" now restores the real document after previewing several versions in a row. `previewVersion` captured the editor state on every call, so a second preview overwrote the saved current document with the first previewed version — exiting preview then restored that version read-only, and saving in that state could overwrite the document with old content.
- **FormBuilder** - `select_group`/`select_field` and `slim_select_group`/`slim_select_field` now honor `input_name:` and `input_id:` options instead of silently dropping them, so non-model forms can namespace the rendered `<select>` under a param key (e.g. `thing[approver_id]`). Explicit `name:`/`id:` in html options still win.
- **Forms** - `.control` field wrappers now shrink inside CSS grid columns (`min-width: 0`), so a select/slim-select holding a long selected option truncates with ellipsis instead of overflowing `minmax(0, 1fr)` columns. `.ss-main` also gets a defensive `max-width: 100%`.

### Security

- Resolve all 11 open Dependabot alerts (4 high, 5 moderate, 2 low), all npm. Re-resolved transitive dependencies in `yarn.lock` (`form-data` 4.0.6, `systeminformation` 5.31.12, `tmp` 0.2.7, `js-yaml` 5.2.1, `@babel/core` 7.29.7) and `spec/dummy/yarn.lock` (`linkify-it` 5.0.2, `markdown-it` 14.3.0). Added Yarn `resolutions` for `qs` (^6.15.2) and `uuid` (^11.1.1) whose parent ranges could not reach the patched versions, and bumped the dummy app's `esbuild` to ^0.28.1. Dev/test-only surface (Cypress, eslint/standard, esbuild, BlockNote markdown chain) — no runtime gem code affected.

## [v2.10.0] - 2026-06-30

### Added

- **Confirm dialog** - Bali now replaces Turbo's native `window.confirm` with a DaisyUI-styled `<dialog>`, auto-installed via `registerAll`. It applies to every `data-turbo-confirm` (including `DeleteLink` and `ActionsDropdown` delete items), renders as real DOM in the top layer so automated browser tools (e.g. Claude in Chrome) can operate it, and supports per-trigger customization through `data-bali-confirm-{title,variant,accept,cancel}` (`variant`: `danger`/`warning`/`info`). `DeleteLink` now renders a red destructive confirm button with localized title/labels (en/es). Opt out with `window.BALI_DISABLE_CONFIRM_DIALOG`. Exports `confirmDialog` / `installConfirmDialog` for manual setup or apps that register controllers selectively. The Turbo Native `SignOut` keeps its own native confirm.

## [v2.9.3] - 2026-06-26

### Changed

- **Filters** - searchable single-select (SlimSelect) for select-type filter values, plus layout fixes that keep the value input roomy. The advanced-filter condition's single-value `select` (used for `is`/`is not` on select-type attributes) now mounts the `slim-select` controller, adding a type-to-filter search box — helpful when an attribute has many options. The SlimSelect uses the `slim-select-sm` variant so its height matches the field/operator `select-sm`. The field and operator selectors keep compact fixed widths (`sm:w-36` / `sm:w-28`) and truncate long labels with an ellipsis (e.g. "Último Inicio de Sesión", "es exactamente") instead of growing — so the value input keeps its space; both stay full-width on mobile. Both the server-rendered ERB and the JavaScript that rebuilds the value input on attribute/operator change emit equivalent markup, so dynamically added conditions get the same searchable select. The multi-select (`is any of` / `is not any of`) is unchanged. Adds a `bali.filters.search` i18n key (en/es).

### Security

- Bump `concurrent-ruby` 1.3.6 → 1.3.7 and `nokogiri` 1.19.3 → 1.19.4 (bundler-audit advisories).

## [v2.9.2] - 2026-06-19

### Fixed

- **SimpleFilters** - el buscador de texto del DataTable ahora sale del autofill de gestores de contraseñas (`autocomplete="off"` + `data-1p-ignore`/`data-lpignore`/`data-form-type="other"`). Un buscador no es un campo de credenciales, pero su `name` puede contener tokens como `name`/`email` (p. ej. `q[name_or_email_cont]` cuando se buscan esas columnas), lo que hacía que 1Password/LastPass/Dashlane ofrecieran login al enfocarlo. Aplica a todos los consumidores sin configuración.
### Changed

- **DataTable::SimpleFilters** - Filter controls now render their `label:` as a visible caption above each control (select, slim_select, toggle/radio group, number range, date). Previously `label:` was accepted in the filter config but only rendered for `:boolean` toggles (inline) and used as a `:date` placeholder fallback — for the common `select` dropdowns it was silently ignored, so a row of dropdowns all reading "All"/"Todas" gave no indication of what each one filtered. The label renders only when present (filters without `label:` are unchanged), boolean toggles keep their existing inline label (no duplicate caption), and the filter row switched from `items-center` to `items-end` so the Apply/Clear buttons and search input stay aligned with the bottom of the now taller label+control stacks.

### Fixed

- **SideMenu** - Expandable groups (`group_behavior: :expandable`) with subitems were unreachable when the sidebar was collapsed to icon-rail width. Hovering the parent icon showed only a tooltip with the parent's name; children required expanding the rail to navigate. They now open a hover/focus flyout to the right of the rail with the parent name as a title and child links beneath, mirroring the established `:dropdown` mode pattern. Hover/focus opens it; ArrowRight/Enter opens it via keyboard with arrow keys to navigate inside; Escape closes via an `is-suppressed` class cleared on the next `mouseleave`/`focusout`. On coarse pointers, first tap opens the panel without navigating so children remain reachable on touch. A 120ms intent delay throttles open, a 300ms close delay forgives cursor drift, and a 24px transparent `::before` bridge covers the gap between the narrower trigger (icon + `p-2`) and the rail's right edge so `:hover` stays continuous during traversal. The panel position is anchored by JS to the sidebar's `getBoundingClientRect().right` (via `setProperty(..., 'important')` so it wins against the CSS reset that defuses DaisyUI's CSS Anchor Positioning fallback). Children rendering is shared with `:dropdown` mode via a new `render_subitem_link` helper; `render_parent_link`, `flyout_classes`, and `render_flyout_trigger` consolidate the rest. Adds a new `SideMenuFlyoutController` Stimulus controller — registered automatically by `registerAll`
- **SideMenu** - Expandable groups (accordion variant) no longer open on mobile. The mobile-expansion override applied `display: flex !important` to every `.side-menu-expanded` element, including the `<div class="collapse side-menu-expanded">` accordion wrapper. DaisyUI's collapse relies on `display: grid` for its `grid-template-rows: max-content 0fr` → `1fr` open/close animation; the forced flex made title and content side-by-side flex items, so expandable groups appeared indented and never opened. A higher-specificity `.collapse.side-menu-expanded { display: grid !important }` restores grid

### Removed

- **SideMenu** - Drop the unused `Bali::SideMenu::Item::Component#collapse_id` method. Was defined for a checkbox-driven DaisyUI collapse pattern that never materialized in the template and used `object_id` for the id, which is non-deterministic between requests

## [v2.9.1] - 2026-05-10

### Fixed

- **SimpleFilters** - `:slim_select` filters now preserve their value after submission. The `slim_select_field` branch of the template wasn't passing `filter[:value]` (or `filter[:default]`), so the `<option>` rendered without `selected`. SlimSelect reads `option.selected` from the DOM, so the dropdown showed the placeholder text instead of the chosen option even though the URL carried the param. The `:select` branch already handled this via `options_for_select`; this brings `:slim_select` in line (#553)

## [v2.9.0] - 2026-05-10

### Changed

- **Dependencies** - Bump `cypress` 15.11.0 → 15.13.0, `playwright` 1.58.2 → 1.59.1, `@babel/preset-env` 7.29.0 → 7.29.2, and refresh transitive dependencies (`@babel/plugin-transform-modules-systemjs` 7.29.0 → 7.29.4, `lodash` 4.17.23 → 4.18.1, `flatted` 3.4.1 → 3.4.2). Bump `actions/github-script` 8 → 9 in CI workflows (#551, #536, #515, #520, #516, #537)

### Fixed

- **SlimSelect** - `slim_select_field` now accepts `content_width:` to forward SlimSelect's upstream `contentWidth` setting (`">240px"` grow-to-fit, `"<500px"` cap, `"320px"` fixed). `Bali::DataTable::SimpleFilters` defaults to `">240px"` so dropdowns with long option labels (department / job-title catalogs) grow past the trigger instead of wrapping to 2-3 lines. Also fixes `.ss-option` zero vertical padding so wrapped lines no longer merge with adjacent items, removes a legacy `.slim-select-sm .ss-search input` override that was clobbering the new search-icon padding, and scopes the inline `No Results` / `Press "Enter" to add {value}` prompt so it stops inheriting the top search bar's padding, border, and magnifier icon (#548)
- **Breadcrumb** - DaisyUI's `.breadcrumbs { padding-block: .5rem }` was beating the component's `pt-0` utility in host apps where the daisyUI plugin layer ends up after `@layer utilities` (Tailwind v4 + daisyUI plugin ordering varies per host). Move the override into the component's unlayered `index.css` so it wins regardless of layer ordering and drop the now-redundant `pt-0` utility (#530)
- **FormBuilder** - `translate_attribute` routes through `ActiveModel::Translation#human_attribute_name` so labels resolve from `activemodel.attributes.*` (form objects) as well as `activerecord.attributes.*`. Previously the `activerecord.*` namespace was hardcoded and form-object translations silently fell back to humanize (#538)
- **FormBuilder** - `select_group`, `text_area_group`, `time_zone_select_group`, and `slim_select_field` now apply DaisyUI's element-specific error classes (`select-error` / `textarea-error`) instead of always using `input-error`. Validation errors on these fields actually paint the field red now (#545)
- **FilterForm** - Default search placeholder is localized via `bali.filter_form.search_placeholder_with_fields`, and field labels resolve through `human_attribute_name`, so apps running in non-English locales no longer get a hardcoded "Search by ..." string (#539)
- Fix Ruby 4.0 warnings: parenthesize double-splat in ERB templates, silence intentional method overrides, fix indentation
- Fix pagination end alignment conflict between Rubocop and Ruby 4.0
- **SimpleFilters** - Fix `simple_filter` DSL defaulting date/date_range predicate to `:eq` instead of `nil`, causing incorrect field names (`q[created_at_eq]` instead of `q[created_at]`)
- **SideMenu** / **Topbar** - Brand row and Topbar both derive their height from the shared `--bali-chrome-height` variable (defaults to 3.5rem) so the bottom-border divider stays aligned across the seam if the value changes (#544)
- **SideMenu** - Replace `shadow-lg` on the fixed variant with a 1px right border on desktop (shadow stays on mobile overlay) — eliminates the shadow seam where sidebar meets the topbar
- **SideMenu** - `menu_switcher` dropdown now uses `<details><summary>` instead of focus-based dropdown — fixes mobile-tap reliability (focus pattern is fragile on iOS Safari)
- **SideMenu** - When sidebar is collapsed, the `menu_switcher` stays visible as an icon-only button (was hidden) with a tooltip on hover and a right-side popout for switching modules

### Added

- **ImageGrid** - New `expandable:` option on `Bali::ImageGrid::Component` and `Bali::ImageGrid::Image::Component`. When enabled, clicking an image opens it in a fullscreen lightbox with backdrop fade-in, image fade + scale-in, and a CSS spinner while the full-size image preloads. Pass `full_src:` to load a higher-resolution image; otherwise the thumbnail's `src` is reused. Closes on ESC, backdrop click, or close button; restores focus to the trigger. The grid-level `expandable:` propagates to every image but can be overridden per-image (#550)
- **AppLayout** - Auto-render a mobile-only topbar (hamburger + optional `app_name:` title) when `fixed_sidebar: true`, a sidebar is present, and no custom `topbar` slot was provided. Without this fallback the sidebar was unreachable on mobile, forcing every consuming app to copy/paste the same `lg:hidden` trigger row. Custom topbars still take precedence (#506)
- **AppLayout** - New `viewport_locked:` parameter that locks the body to 100vh and scrolls only the inner `<main>`, matching the Linear/Notion app-shell pattern. Defaults to the value of `fixed_sidebar` so existing pages keep working; pass explicitly to decouple (e.g. `fixed_sidebar: true, viewport_locked: false` for a fixed sidebar with normal page scroll)
- **SideMenu** - New `with_brand` slot for icon + text or arbitrary brand content (the existing `brand:` text param keeps working as a fallback)
- **Topbar** - New component for the top-of-content bar inside `Bali::AppLayout`'s `with_topbar` slot. Slots: `brand`, `search`, `actions` (many), `user_menu`. Built-in mobile sidebar trigger via `mobile_trigger_id:` (defaults to `SideMenu::MOBILE_TRIGGER_ID`)
- **Command** - New ⌘K-style command palette / launcher. Modal panel with search input, grouped results (`:searchable` / `:recent` / `:action` modes), keyboard navigation (↑/↓/⏎/Esc), substring highlighting, and a global ⌘K (Mac) / Ctrl+K (Windows/Linux) shortcut. Composable trigger slot, density variants (`:default` / `:compact`), and window events (`bali:command:open` / `close` / `toggle`)
- **DocumentEditor / DocumentPage** - Forward `references_url`, `references_resolve_url`, and `references_config` to the inner `BlockEditor` so the `#` entity-reference picker and entity chip icons/colors work when the editor is used via `DocumentEditor` or `DocumentPage` (#541)
- **Icon** - Numeric pixel sizes alongside the named presets: `Bali::Icon::Component.new('clapperboard', size: 24)` renders a 24×24 wrapper with a 24×24 SVG. Inline `style` + `--bali-icon-size` variable, no Tailwind safelist needed (#544)
- **Command** - i18n keys (`bali.command.placeholder`, `no_results`, `navigate`, `open_action`, `close`) are now in the en/es locale files so consumers can override / translate without monkey-patching. Inline `default:` fallbacks remain (#544)
- **SimpleFilters** - Configurable search input width via `search[:width]` option; widened defaults from `w-32 sm:w-80` to `w-48 sm:w-96`
- **SlimSelect** - Search row redesign: magnifier icon prefix, no boxed background, no input border. Selected options use blue text plus a checkmark on the right with no background tint. Trigger focus outline unchanged
- **SlimSelect** - Added 8px detached gap between input and dropdown menu for improved visual separation
- **SlimSelect** - Matched focus ring style with DaisyUI native selects (2px outline with 2px offset)
- **SlimSelect** - Added support for placing search box at the bottom when dropdown opens upwards
- **SlimSelect** - Matched native select dimensions (40px regular / 32px small) and border-radius (4px)
- **SlimSelect** - Optimized internal padding and density to match standard DaisyUI elements
- **SimpleFilters** - Enhanced configuration to support SlimSelect by default for improved usability
- **SimpleFilters** - Added `boolean` filter type: toggle switch for boolean columns (active, published, featured)
- **SimpleFilters** - Added `radio_group` filter type: single-select segmented buttons for mutually exclusive choices
- **SimpleFilters** - Added `number_range` filter type: min/max inputs for numeric columns (price, amount, quantity)

### Fixed

- **SimpleFilters** - Fix mass-assignment vulnerability by replacing blanket `permit!` with targeted parameter permitting
- **SimpleFilters** - Fix thread-safety bug: remove class-level attribute mutation from initializer that could corrupt state under concurrent requests
- **CSS** - Add DaisyUI v5 structural variable fallbacks (`--border`, `--radius-box`, etc.) so custom themes that only define colors don't silently break component borders and radii
- **Pagination** - Load Pagy 43.x `series` helper explicitly to prevent `NoMethodError` on paginated views
- **FilterForm** - Fix `simple_filters` keyword arg shadowing the instance method in `initialize`
- **Tests** - Restore corrupted `filter_form_test.rb` (82 tests were silently disabled by null-byte corruption)

## [v2.8.0] - 2026-03-23

### Added

- **Kanban** - Drag-and-drop board component composing SortableList, with Column and Card slots
- **FeedbackWidget** - Floating button with drawer for Opina feedback integration, includes JWT TokenGenerator

## [v2.7.4] - 2026-03-13

### Removed

- **SideMenu** - Removed deprecated `collapsable:` parameter and `collapsable?` alias. Use `collapsible:` instead.

## [v2.7.3] - 2026-03-11

### Changed

- **DocumentPage** - Remove internal padding from header and subheader areas; relies on app layout padding instead

## [v2.7.2] - 2026-03-11
- Bump bundler to 4.0.10 (consolidates AFAL fleet on one bundler version; see Grupo-AFAL/dev-sandbox#6)

### Added

- **DocumentEditor** - `toolbar` slot for custom content between the document title and action buttons in the app bar
- **DocumentPage** - `subheader` slot for custom content between the page header and content area

## [v2.7.1] - 2026-03-10

### Added

- **DocumentEditor** - Save status indicator showing "Saving..." / "Saved at HH:MM:SS" in the app bar
- **DocumentEditor** - Version preview loads content into the editor in read-only mode with a dismissible "Previewing Version X" banner, instead of opening raw JSON in a new tab
- **BlockEditor** - Pre-populate UserStore cache with known users before rendering comments, preventing crashes on resolved threads

### Fixed

- **BlockEditor** - Fix comment thread marks (`.bn-thread-mark`) missing highlight, cursor, and click behavior in the editor
- **BlockEditor** - Fix reply Save/Cancel buttons appearing blank in floating thread composer
- **BlockEditor** - Fix emoji reaction tooltip missing visual styles when portaled to `<body>`
- **DocumentEditor** - Auto-save now triggers correctly on content changes via `input` event delegation
- **DocumentEditor** - Version history panel redesigned with version badges, author avatars, italic summaries, and polished Preview/Restore buttons with icons
- **BlockEditor** - Fix "User resolved thread, but their data could not be found" crash by gating comments rendering on UserStore readiness
- **BlockEditor** - Fix comments sidebar losing all CSS when portaled into DocumentEditor side panel (added `bn-mantine` class to portal container)
- **BlockEditor** - Fix emoji reaction chips rendering unstyled — override Mantine CSS variables with DaisyUI-compatible colors, backgrounds, and hover states
- **BlockEditor** - Fix selected thread showing blue border on only 3 sides — use outline instead of border for consistent selection indicator
- **BlockEditor** - Fix resolved thread hover toolbar invisible due to opacity dimming the entire thread — target only comment text and header for dimming
- **BlockEditor** - Fix delete comment clearing body but not removing the thread — destroy thread when no active comments remain
- **BlockEditor** - Fix emoji picker popover rendering behind comments sidebar panel (z-index)

## [v2.7.0] - 2026-03-09

### Added

- **DocumentPage** and **DocumentEditor** components (#507)

## [v2.6.0] - 2026-03-09

### Added

- **DocumentPage** - Three-panel sticky layout (TOC | Content | Metadata) unified with DocumentEditor visual language
- **DocumentPage** - Toggle buttons in PageHeader for TOC and metadata panels
- **DocumentPage** - BlockEditor readonly support with TOC portal, plus slot-based fallback for preview/content
- **DocumentPage** - Stimulus controller (`document-page`) for panel visibility toggling
- **DocumentEditor** - `input_name` parameter and Stimulus value for configurable form field name
- **DocumentEditor** - `close_url` parameter and Stimulus value for explicit close navigation
- **DocumentEditor** - `**options` passthrough for custom HTML attributes on root element
- **SideMenu** - `bottom_group` slot for upward-expanding dropdown menus at sidebar bottom
- **AppLayout** - New layout component with flash messages, modal, and drawer infrastructure
- **AppLayout** - Login/register preview layouts and body_container presets
- **IndexPage** - Page layout component for standard list/table pages with breadcrumbs, header, and actions
- **ShowPage** - Page layout component for detail pages with optional sidebar
- **FormPage** - Page layout component for new/edit form pages with card wrapper
- **DashboardPage** - Page layout component with configurable stat cards grid
- **BlockEditor** - AI endpoint concern (`BlocknoteAi`) for proxying AI chat requests in Rails apps
- **BlockEditor** - Integration documentation for setting up AI features (`docs/blocknote-ai-rails-integration.md`)

### Fixed

- **DocumentEditor** - Replace all `innerHTML` with `createElement` + `textContent` to prevent XSS in version rendering
- **DocumentEditor** - Use Bali Dropdown component instead of raw DaisyUI HTML for export menu
- **Filters** - Fix horizontal scroll on mobile caused by DaisyUI tooltip pseudo-element on persistence button
- **SideMenu** - Force expanded sidebar view on mobile via CSS override (regardless of collapse state from localStorage)
- **SideMenu** - Hide collapse toggle on mobile, show X close button instead for fixed sidebars
- **SideMenu** - Support mobile close button for non-collapsible fixed sidebars
- **PageComponents** - Add flex-wrap to actions bar to prevent overflow on mobile
- **BlockEditor** - Prevent page scroll jump when opening AI menu via slash command or formatting toolbar on long pages

### Changed

- **Columns** - Refactored to use Tailwind flex/grid classes with responsive breakpoints, removing custom CSS
- **Dependencies** - Batch update: @babel/core, @babel/eslint-parser, @babel/preset-env, standard, daisyui, brakeman, minitest, pagy, rubocop, sqlite3, view_component; add minimatch resolution (security)
- **CI** - Bump GitHub Actions: checkout v6, setup-node v6, upload-artifact v7, github-script v8
- **Testing** - Migrated entire test suite from RSpec to Minitest (2,331 tests), aligning with AFAL handbook standards
- **Build** - Replaced Vite with esbuild (jsbundling-rails) for JavaScript bundling in dummy app
- **Security** - Added Brakeman and bundler-audit for security scanning, Dependabot configuration
- **CI** - Added security scanning workflow, updated action versions to v4 and Node 20
- **RuboCop** - Switched from rubocop-rails to rubocop-rails-omakase base configuration
- **Engine** - Added CSRF protection to `Bali::ApplicationController`

## [v2.5.0] - 2026-02-22

### Added

- **SimpleFilters** - Optional search input with `search:` parameter for quick text search
- **FilterForm** - New `simple_search_config` convenience method for SimpleFilters integration
- **PageHeader** - Default `mb-6` margin for consistent spacing

### Fixed

- **SubmitButton** - Loading spinner is now visible on form submission. Fixed two issues: `Bali::FormHelper` was not included in the dummy app (controller never connected), and DaisyUI 5's disabled button styling made the spinner invisible. The button now preserves its primary color at reduced opacity during loading.
- **Tabs::Trigger** - Now respects explicit `active:` parameter when `href` is present
- **PathHelper** - `active_path?` strips query params from both path arguments symmetrically

## [v2.4.2] - 2026-02-20

### Fixed

- **Engine** - Preview files (`preview.rb`) are now excluded from Zeitwerk autoloading, preventing `uninitialized constant` errors when eager loading is enabled in consuming apps that don't have Lookbook installed. Preview discovery by Lookbook is unaffected.

## [v2.4.1] - 2026-02-19

### Fixed

- **SideMenu::Item** - Data attributes (e.g. `data: { turbo_method: :delete }`) passed to `with_item` are now correctly forwarded to the rendered anchor tag in both expanded and collapsed states

## [v2.4.0] - 2026-02-19

### Added

- **BlockEditor** - New `comments:` option enables inline commenting via BlockNote's built-in comments extension. Supports in-memory mode (session-only, default) and REST-backed mode (`comments_url:`) for database persistence. Configure the current user with `comments_user:` and collaborators with `comments_users:` or `comments_users_url:`.

### Fixed

- **FormBuilder** - `submit_actions` button row now has consistent top margin (`mt-6`) to prevent buttons from appearing flush against the last form field
- **Modal** - Prevent modal from closing when clicking browser autocomplete options inside modal forms
- **StepNumberInput** - Guard `disconnect()` with `hasInputTarget` check to prevent error when target element is already removed from DOM ([ENJOY-KITCHEN-JS-B](https://enjoy-kitchen.sentry.io/issues/ENJOY-KITCHEN-JS-B))

## [v2.3.0] - 2026-02-18

### Added

- **SideMenu** - New `with_bottom_item` slot to pin items at the bottom of the sidebar, outside the scrollable area. Useful for user profile, logout, and account settings links. Supports multiple items and the full `Item::Component` API (icon, badge, authorized, active state, disabled, target, match type). Works in both fixed and collapsable sidebar modes.
- **BlockEditor** - New `table_of_contents:` option renders a sticky sidebar extracted from the document's heading blocks (H1–H3). Updates in real-time as headings are added or edited. Clicking any entry smooth-scrolls to that heading. Layout collapses to a vertical list on narrow viewports.

## [v2.2.0] - 2026-02-18

### Added

- **BlockEditor V2** - New rich text editor powered by BlockNote + React
  - Syntax-highlighted code blocks via Shiki
  - Multi-column layout support via `@blocknote/xl-multi-column`
  - PDF and DOCX export via `@blocknote/xl-pdf-exporter` and `@blocknote/xl-docx-exporter`
  - File upload support with Active Storage integration (images, video, audio, and general files)
  - AI assistance via `@blocknote/xl-ai` (optional, requires `ai_url` configuration)
  - **@mentions** support with configurable user search endpoint (`mentions_url`)
  - **#entity references** with per-type color differentiation (tasks, projects, documents, etc.)
    - Customizable entity type configuration via `references_config` parameter
    - Color-coded inline chips with type labels
    - Suggestion menu with grouped results, colored dots, and icon badges
    - Batch resolution of entity references on editor load
  - PDF and DOCX export support for mentions and entity references
  - Compact suggestion menu styling for better density

### Changed

- **BlockEditor** - Extracted `BlockNoteEditorWrapper` into focused modules for maintainability
- **BlockEditor** - CSS lazy-loaded only when the editor is used (no longer bundled globally)
- **Ruby 4.0 compatibility** - Replace removed `CGI.parse` with `Rack::Utils.parse_query` in `Utils::Url` and `Calendar::Header`
- **Ruby version** - Updated development Ruby version to 4.0.1

### Fixed

- **BlockEditor** - Fixed PDF export crash caused by `Infinity` value in `toggleListItem` blocks
- **BlockEditor** - Fixed PDF/DOCX export with custom inline content types (mentions, entity references)
- **BlockEditor** - Fixed table cell structure handling in entity reference batch resolution
- **BlockEditor** - Resolved relative URLs for images in PDF/DOCX export
- **BlockEditor** - Improved code block and link styling
- **BlockEditor** - Removed client-side file type restriction for uploads
- **BlockEditor** - Added video, audio, and SVG MIME types to upload allowlist
- **BlockEditor** - Increased default max upload size from 10MB to 50MB for video/audio support
- **BlockEditor** - Upload errors now show descriptive toast messages instead of generic failure
- **lefthook-linux-arm64** - Moved to `optionalDependencies` to prevent CI failures on x64 runners

## [v2.1.1] - 2026-02-12

### Added

- **Costa Norte Theme** - Custom DaisyUI 5 theme for Costa Norte brand (teal/gold palette)
  - Opt-in CSS file at `css/themes/costa-norte.css` with all 18 DaisyUI color variables in OKLCH
  - npm package export `./css/themes/*.css` for consumer apps
  - Lookbook theme sampler preview and dedicated layout
  - Usage documentation in `docs/guides/custom-themes.md`
- **Navbar Burger** - Allow burger to render as a link when `href` is provided
  - Renders an `<a>` tag instead of a `<button>` for navigation use cases

### Changed

- **Navbar** - Allow custom background colors via `color: nil` with `class:` option
  - Pass `color: nil` to skip preset color classes, then provide custom classes via `class:`
  - Example: `Bali::Navbar::Component.new(color: nil, class: 'bg-indigo-600 text-white')`
- **FormBuilder** - Replace `class_names` with `token_list` in step number fields

### Fixed

- **SideMenu + Navbar** - Fixed mobile sidebar toggle from Navbar hamburger
  - SideMenu Stimulus controller was scoped to its own element, unreachable from Navbar burger
  - Overlay referenced a non-existent checkbox ID for non-collapsable fixed menus
  - Introduced checkbox+label pattern (matching DaisyUI drawer convention) for cross-component toggling
  - Added `type: :sidebar` burger variant that renders a `<label>` targeting the mobile trigger checkbox
  - Added global window events (`bali:side-menu:toggle`, `bali:side-menu:open`, `bali:side-menu:close`) for programmatic control
  - Added `mobile_trigger_id` parameter to SideMenu for custom checkbox IDs
  - Backwards compatible: existing `is-active` class approach still works
- **SubmitButton** - Use a spinner `<span>` element instead of adding loading classes directly to the button, avoiding style conflicts
- **FormBuilder RadioFields** - Fix data attribute merging to properly support both shared and per-item data attributes
- **Utils** - Add nil-safety to `conditional_classes` when no conditional names are passed

### Chores

- Add dangerous command deny list to `.claude/settings.json`
- Add CLAUDE.md context files for components, views, config directories

## [v2.1.0] - 2026-02-04

### Added

- **DataTable SimpleFilters** - New lightweight inline filter UI for CRUD views
  - Alternative to complex Filters component for simple filtering needs
  - Renders inline select dropdowns without AND/OR groupings, popovers, or badges
  - Auto-configures from FilterForm via `with_simple_filters` slot
  - New `SimpleFiltersConfiguration` concern for FilterForm DSL support
  - Supports instance-level configuration via `simple_filters:` parameter
  - Includes `simple_filters_config`, `simple_filters_enabled?`, `simple_filters_active?` methods

- **PaginationFooter Component** - Standardized pagination footer with summary and controls
  - Combines summary text (e.g., "Showing 1-10 of 100 items") with pagination controls
  - Summary on left, pagination buttons on right
  - Supports custom `item_name`, `show_summary`, and `show_pagination` options
  - Auto-hides pagination when only one page exists

- **Columns Component** - Added Bulma-compatible column system with Tailwind implementation
  - Tailwind display utilities support on Column component
- **Filters Component** - Added preserved query params support for maintaining URL state
- **Filters Component** - Added turbo_stream support and refactored controller submission logic
- **FilterForm** - Made `ransack_params` public for component access
- **SideMenu Component** - Added `target` and `rel` attributes support for menu items

### Changed

- **ImageField Component** - Render input using `raw_file_field` to bypass custom form builder wrappers
- **ImageField Component** - Wrap icon in span and remove `text-base-content` class from icon styling

### Fixed

- **Drawer & Modal Components** - Adjusted z-index values and positioning to improve layering behavior
- **SlimSelect** - Fixed `slim_select_field` to deep merge data attributes instead of overwriting

### Dependencies

- **ViewComponent** - Upgraded from 3.x to 4.2.0
  - Updated preview configuration: `config.view_component.preview_paths` → `config.view_component.previews.paths`

- **Pagy** - Upgraded from 8.x to 43.2.8 (major API redesign)
  - `Pagy::Backend`/`Pagy::Frontend` modules → `Pagy::Method`
  - `Pagy.new()` → `Pagy::Offset.new()`
  - `items:` parameter → `limit:`
  - `pagy.prev` → `pagy.previous`
  - `Pagy::DEFAULT` → `Pagy::OPTIONS`
  - Added fallback URL builder for contexts without request object (e.g., Lookbook previews)
  - Updated `Pagination::Component` and `DataTable` previews for new API

## [v2.0.5] - 2026-02-03

### Added

- **Form::Errors Component** - New component for displaying form validation error summaries
  - Renders error list using `Bali::Message::Component` with error styling
  - Only renders when model has errors (`render?` returns false otherwise)
  - Supports optional `title` parameter for custom header text
  - FormBuilder integration via `f.error_summary` helper method

- **DirectUpload Component** - Auto-clear files on successful Turbo form submission
  - Listens for `turbo:submit-end` event on parent form
  - Clears file list when `event.detail.success` is true (2xx response)
  - Files remain on failed submissions so users can retry

### Fixed

- **DirectUpload Component** - Fixed field name generation when using `form_with url:` without a model
  - Previously generated `[method][]` instead of `method[]` when `form.object_name` was empty
  - Now correctly handles empty object names for both single and multiple file modes

### Changed

- **Release Skill** - Rewritten with two-phase PR workflow
  - Phase 1: Creates release prep PR with changelog updates for review
  - Phase 2: After merge, bumps version, tags, and publishes GitHub release
  - New `--continue` flag to run Phase 2 after PR is merged
  - State persistence via `.release-pending.json` between phases

## [2.0.4] - 2026-01-30

### Added

- **Link Component** - Dynamic size support for Modal and Drawer
  - New nested options syntax: `modal: { size: :lg }` and `drawer: { size: :lg }`
  - Backward compatible: `modal: true` and `drawer: true` still work with default sizes

### Changed

- **Drawer Component** - Standardized size names to match other Bali components
  - `narrow` → `sm`
  - `medium` → `md` (default)
  - `wide` → `lg`
  - `extra_wide` → `xl`
  - Added `full` size option

## [2.0.3] - 2026-01-30

### Changed

- **JavaScript Imports** - Redesigned import strategy for standard npm package usage
  - Converted all internal `bali/...` imports to relative paths
  - Added `exports` field to package.json for proper module resolution
  - Consuming apps no longer need complex bundler alias configuration
  - Import from `'bali-view-components'` instead of internal paths

## [2.0.2] - 2026-01-28

### Added

- **Link Component** - Added `soft` and `outline` styles to `Bali::Link::Component`
- **Message Component** - Added style variants (`soft`, `outline`, `dash`) to `Bali::Message::Component`
- **Notification Component** - Added `style` options and updated tag's rounded class
- **Tag Component** - Added a new preview page showcasing all variations and combinations
- **SlimSelect** - Added `results_text` support and `resultsText` option for grouping AJAX results
- **Utility** - Added `.box` utility class
- **Translations** - Added "results" translation key for select menu in English and Spanish

### Changed

- **Drawer Component** - Refactored overlay visibility and z-index
- **Tag Component** - Made `text` attribute optional, falling back to content
- **Dropdown Component** - Render dropdown menu items as plain links
- **Internal** - Relocated component-specific CSS variables to `bali-` prefixed variables and updated `build_url` calls


## [2.0.1] - 2026-01-27

### Changed

- **Filters Component** - Consolidated `AdvancedFilters` and `Filters` into a single unified `Filters` component
  - Removed separate `AdvancedFilters` component (functionality merged into `Filters`)
  - Added search input with clear button (x) for easy clearing of persisted search
  - Improved filter persistence handling with `clear_search` parameter

### Fixed

- **FilterForm** - Refactored into focused concerns for better maintainability
  - Extracted `SearchConfiguration` concern for search DSL and methods
  - Extracted `FilterGroupParser` concern for Ransack grouping parsing
  - Fixed search persistence bug where clearing search text didn't clear persisted value

### Dependencies

- Added `lucide-rails` as runtime dependency for icon rendering
- Updated `@source` directive documentation for Tailwind v4 configuration

## [2.0.0] - 2026-01-26 - Tailwind + DaisyUI Migration

**This is a major release migrating all 60+ components from Bulma CSS to Tailwind + DaisyUI 5.**

### Infrastructure

- Added Tailwind CSS build step to CI pipeline for proper asset compilation

### Breaking Changes

- **`Bali::Link::Component`** - `type:` parameter deprecated. Use `variant:` instead.
  - Added backwards compatibility: passing `type:` still works but logs deprecation
  - New `variant:` supports: `:primary`, `:secondary`, `:accent`, `:info`, `:success`, `:warning`, `:error`, `:ghost`, `:link`, `:neutral`
  - New `size:` parameter: `:xs`, `:sm`, `:md`, `:lg`, `:xl`
  - New `plain:` parameter for links without button styling
  - New `authorized:` parameter for permission-based rendering

  ```ruby
  # Before
  render Bali::Link::Component.new(href: '/users', name: 'Users', type: :primary)

  # After
  render Bali::Link::Component.new(href: '/users', name: 'Users', variant: :primary)
  ```

- **`Bali::Card::Component`** - `footer_items` slot removed. Use `actions` slot instead.
  - New slot structure: `header`, `title`, `image`, `actions`
  - Actions render inside `card-actions` container with proper DaisyUI styling

  ```ruby
  # Before
  render Bali::Card::Component.new do |c|
    c.with_footer_item { render Bali::Button::Component.new(name: 'Save') }
  end

  # After
  render Bali::Card::Component.new do |c|
    c.with_action { render Bali::Button::Component.new(name: 'Save') }
  end
  ```

- **`Bali::Filters::Component`** - Consolidated filter component (replaces old Filters and AdvancedFilters)
  - Multiple filter groups with AND/OR combinators between groups
  - Multiple conditions within each group with AND/OR combinators
  - Type-specific operators for text, number, date, select, and boolean fields

- **`Bali::Breadcrumb::Item::Component`** - `href` is now optional (was required).
  - Items without `href` are automatically marked as active
  - Parameter order changed: `name:` is now the primary parameter
  - Links only show underline on hover (not by default)
  - Active items render as non-clickable `<span>` elements with `cursor-default`
  - Removed legacy BEM classes (`breadcrumb-component`, `breadcrumb-item-component`)
  - Added `aria-current="page"` to active items for accessibility

  ```ruby
  # Before
  c.with_item(href: '/page', name: 'Current', active: true)

  # After (simplified - no href means auto-active)
  c.with_item(name: 'Current')
  ```

- **`Bali::Tag::Component`** - `tag_class:` parameter deprecated. Use `color:` instead.

- **`Bali::Calendar::Component`** - `all_week:` parameter deprecated. Use `weekdays_only:` instead.

- **CSS Class Changes** - All Bulma classes replaced with DaisyUI equivalents:
  - `is-primary` → `btn-primary`, `badge-primary`, etc.
  - `is-danger` → `*-error` (DaisyUI uses "error" not "danger")
  - `is-small/medium/large` → `*-sm/md/lg`
  - `columns` → `grid grid-cols-*`
  - `card-content` → `card-body`
  - `notification` → `alert`
  - See `docs/migration/BREAKING_CHANGES.md` for complete mapping

### Added

- **`Bali::FilterForm`** - Enhanced filter form with Ransack groupings support
  - Dynamic add/remove for both conditions and groups
  - Pre-populated filters from URL params
  - Quick search integration and reset functionality
  - Date range "between" operator uses Flatpickr range mode
  - Locale-aware date formats: `M j, Y` for English, `j M Y` for Spanish

- **`Bali::Button::Component`** - Proper ViewComponent (was previously a helper)
  - Full DaisyUI button support with variants, sizes, states
  - Loading state with spinner
  - Icon support (left and right)
  - Disabled state

- **`Bali::Avatar::Group::Component`** - Display grouped avatars with overlap styling
- **`Bali::Avatar::Upload::Component`** - Avatar with upload/edit functionality

- **`Bali::Card::Action::Component`** - Card action button/link for footer actions

- **`Bali::DataTable::ColumnSelector::Component`** - Toggle table column visibility
  - Supports hiding columns by default
  - Works by column index, no coordination needed between selector and table cells

- **`Bali::DataTable::Export::Component`** - Export data table to various formats

- **`Bali::DirectUpload::Component`** - Direct file upload with progress indication

- **`Bali::Modal::Header::Component`** - Modal header slot component
- **`Bali::Modal::Body::Component`** - Modal body slot component
- **`Bali::Modal::Actions::Component`** - Modal actions/footer slot component

- **`Bali::Pagination::Component`** - Standalone pagination component using Pagy

- **Icon System Overhaul** - New Lucide-based icon resolution pipeline
  - 1,600+ Lucide icons available directly
  - Backwards compatible: old Bali icon names still work (mapped to Lucide equivalents)
  - Kept icons: brand logos (Visa, Mastercard, PayPal), social (WhatsApp, Facebook), regional (flags)
  - Custom icons: app-specific via `Bali.custom_icons`
  - New `size:` parameter: `:small`, `:medium`, `:large`

- **Stimulus Controllers**
  - `advanced-filters` - Main filter UI controller
  - `filter-group` - Filter group management
  - `condition` - Individual condition management
  - `column-selector` - Table column visibility toggle

- **Dependencies**
  - Added `pagy` gem (~> 8.0) for pagination
  - Added `lucide-rails` gem for Lucide icon integration

### Changed

- **All 60+ Components** - Migrated from Bulma SCSS to Tailwind + DaisyUI 5
  - Removed all `.scss` files, using `.css` with `@apply` or inline Tailwind classes
  - Components now use DaisyUI semantic classes (`btn`, `card`, `modal`, etc.)
  - Responsive design using Tailwind breakpoints

- **`Bali::Calendar::Component`** - Refactored with improved API (backward compatible)
  - `start_date` now accepts `Date` objects directly (strings still work)
  - New `weekdays_only:` parameter replaces confusing `all_week:` (deprecated but still works)
  - Extracted `EventGrouper` class for cleaner event grouping logic
  - Added helper methods: `month_view?`, `week_view?`, `show_weekends?`, `weekdays_only?`
  - Preview consolidated from 7 methods to 3 with `@param` annotations
  - Added 14 new tests (33 total)

- **`Bali::DataTable::Component`** - Uses consolidated `Filters` component with Ransack groupings support
  - New `filters_panel` slot accepts `available_attributes:` for defining filterable fields
  - New `toolbar_buttons` slot for right-aligned buttons (column selector, export, etc.)
  - Added sorting examples using Ransack's `sort_link` helper
  - Added pagination examples using Pagy

- **`Bali::Modal::Component`** - New slot-based API
  - Uses native `<dialog>` element with DaisyUI modal styling
  - New slots: `header`, `body`, `actions`
  - Backdrop click to close
  - Escape key to close

- **`Bali::Dropdown::Component`** - Migrated to DaisyUI dropdown
  - Uses `dropdown`, `dropdown-content`, `menu` classes
  - Supports positioning: `dropdown-end`, `dropdown-top`, `dropdown-left`, `dropdown-right`

- **`Bali::Table::Component`** - Migrated to DaisyUI table
  - Uses `table`, `table-zebra`, `table-pin-rows`, `table-pin-cols` classes
  - Sticky headers supported via `table-pin-rows`

- **`Bali::Tabs::Component`** - Migrated to DaisyUI tabs
  - Uses `tabs`, `tabs-box`, `tab`, `tab-active` classes

- **`Bali::Tooltip::Component`** - Migrated to DaisyUI tooltip
  - Uses `tooltip`, `tooltip-*` positioning classes
  - Removed Tippy.js dependency for simple tooltips

- **`Bali::Timeline::Component`** - Migrated to DaisyUI timeline
  - Uses `timeline`, `timeline-start`, `timeline-middle`, `timeline-end` classes

- **`Bali::Stepper::Component`** - Migrated to DaisyUI steps
  - Uses `steps`, `step`, `step-primary/secondary/etc` classes

- **`Bali::Progress::Component`** - Migrated to DaisyUI progress
  - Uses `progress`, `progress-primary/secondary/etc` classes

- **`Bali::Notification::Component`** - Migrated to DaisyUI alert
  - Uses `alert`, `alert-info/success/warning/error` classes

- **`Bali::Loader::Component`** - Migrated to DaisyUI loading
  - Uses `loading`, `loading-spinner/dots/ring/ball/bars/infinity` classes

- **`Bali::SideMenu::Component`** - Migrated to DaisyUI menu
  - Uses `menu`, `menu-title`, DaisyUI collapse for nested items
  - Improved collapsed state with tooltips

- **Form Components** - All 27+ form field components migrated
  - Inputs use `input`, `input-bordered`, `input-*` classes
  - Selects use `select`, `select-bordered` classes
  - Checkboxes use `checkbox`, `checkbox-*` classes
  - File inputs use `file-input`, `file-input-bordered` classes

### Removed

- **SCSS Files** - All component `.scss` files removed (replaced with `.css` or inline Tailwind)
- **Bulma Dependencies** - No longer requires Bulma CSS framework
- **`Bali::Card::FooterItem::Component`** - Removed, use `actions` slot instead

### Migration Guide

See `docs/migration/BREAKING_CHANGES.md` for:
- Complete Bulma → DaisyUI class mapping table
- Per-component migration examples
- Step-by-step upgrade instructions

## [1.4.23] - 2025-12-12

### Changed

- `Bali::SideMenu::Item::Component` to display a tooltip when the menu is collapsed.

## [1.4.22] - 2025-12-12

### Changed

- Update filter form submission to prevent default behavior, update URL, and enable custom search input button options.

## [1.4.21] - 2025-11-28

### Added

- `Bali::DataTable::Action::Component` to encapsulate action rendering with optional description tooltips.

### Changed

- `Bali::DataTable::ActionsPanel::Component` now uses `Bali::DataTable::Action::Component` for rendering actions, enabling support for action descriptions via tooltips.

## [1.4.20] - 2025-11-27

### Added

- `Rrule::EnglishHumanizer` service to convert RRule objects to human-readable English text.
- `Rrule::SpanishHumanizer` service to convert RRule objects to human-readable Spanish text.
- `Bali::Concerns::GlobalIdAccessors` concern to define GlobalID getter and setter methods for ActiveRecord associations.
- `rrule` gem dependency for recurrence rule handling.

### Changed

- Updated `Bali::RecurrentEventRuleForm::Component` to display humanized recurrence rules in English and Spanish.
- Added RRule override to support `humanize` method with locale parameter.

## [1.4.19] - 2025-11-25

### Added

- `is-borderless` class support to `Bali::List::Component` to remove the border styling.

## [1.4.18] - 2025-11-18

### Changed

- Add more space between collection filters with multiple options and few options

## [1.4.17] - 2025-10-28

### Changed

- Allow `Bali::DataTable::ActionsPanel::Component` to render custom actions.

### Fixed

- Avoid non query param conversion to array when adding new ones to a url.

## [1.4.16] - 2025-10-28

### Changed

- Allow `Bali::Filters::Component` to receive options such as data.

## [1.4.15] - 2025-10-27

### Added

- `authorized?` method to `Bali::Link::Component` and `Bali::DeleteLinkComponent`
- `items` slot to `Bali::ActionsDropdown` component.

### Changed

- Use `Bali::Link::Component` for `items` slot instead of `Bali::Dropdown::Item::Component` in `Bali::Dropdown::Component`

## [1.4.14] - 2025-10-22

### Added

- `grid`, `list` icons.
- `Bali::DataTable::ActionsPanel::Component` component.

## [1.4.13] - 2025-09-24

### Added

- `checkbox-reveal-controller.js` stimulus controller.
- `Bali::Image::Component` component. This component renders an image and allow to render an input to change and clear the image

## [1.4.12] - 2025-09-24

### Fixed

- maintain collapsed side menu after redirections

## [1.4.11] - 2025-09-23

### Added

- `menu_switches` slot to `Bali::SideMenu::Component`.
- `collapsable` attribute to `Bali::SideMenu::Component`.

## [1.4.10] - 2025-09-12

### Added

- `after-change-fetch-url-value` to `slim-select-controller.js`. When this value is present the controller will peform a fetch request after the value of the select has changed.

## [1.4.9] - 2025-09-09

### Changed

- `Bali::Filters::Component` to render the right input for each `ransack` predicate.

## [1.4.8] - 2025-09-04

### Changed

- `time_period_select_field` and `time_period_select_field_group` to `Bali::FormBuilder`
- `Bali::TimePeriods::SelectOptions` as default time periods for `time_period_select_*` fields.

## [1.4.7] - 2025-08-29

### Changed

- `Bali::RecurrentEventRuleForm` component.
- `recurrent_event_rule_field` and `recurrent_event_rule_field_group` to `Bali::FormBuilder`

## [1.4.6] - 2025-07-28

### Changed

- `submit` function of `ModalController` to check and report inputs validity

## [1.4.5] - 2025-07-29

### Changed

- Upgrade `gems` and `importmap`
- Replace `code climate` with `qlty`

## [1.4.4] - 2025-06-11

### Changed

- `datepicker-controller` and `date fields` to support disabling specific dates.

## [1.4.3] - 2025-05-29

### Changed

- `slim-select` to support rendering custom HTML for remote search results.

## [1.4.2] - 2025-04-23

### Changed

- `Bali::SideMenu::Component` component to preserve scroll position when a link has been clicked

- `Bali::SideMenu::Item::Component` component to add `is-list` class when items are present.

## [1.4.1] - 2025-03-27

### Changed

- `Table` component to allow bulk actions to render a modal and add custom style

## [1.4.0] - 2024-02-20

### Updated

- Upgrade `rails` to version `8.0.1`
- Upgrade `ruby` to version `3.3.7`
- Updated `gems` and importmap

## [1.3.3] - 2024-02-25

### Fixed

- value was displayed as `undefined` when adding a suffix or prefix in a pie or doughnut chart.

## [1.3.2] - 2024-01-30

### Fixed

- Redirection issues when attempting to open a restricted modal.

## [1.3.1] - 2024-12-20

### Changed

- Set `modal` attribute to `false` when link is disabled (`Bali::Link::Component`)

## [1.3.0] - 2024-10-18

### Changed

- Upgrade to `rails` to `7.2`
- Update `gems` and `importmap`

## [1.2.5] - 2024-09-17

### Changed

- Added `submit-actions` class name to `submit_actions` fields helper.

## [1.2.4] - 2024-07-25

### Changed

- Updated `rails` to version `7.1.4`

## [1.2.3] - 2024-07-25

### Changed

- Updated gems and npm packages

## [1.2.2] - 2024-06-06

### Fixed

- Cannot read properties of undefined (reading 'destroy') in `stimulus` controllers.
- Missing target element "menu" for "navbar" controller

## [1.2.1] - 2024-05-20

### Fixed

- Incorrect `for` attribute value in radio buttons of `radio_buttons_field_group` when value is a datetime

## [1.2.0] - 2024-05-06

### Changed

- import `GoogleMapsLoader` dynamically
- import `tippy` dynamically
- import `Sortable` dynamically
- import `Chart` dynamically
- import `MarkerClusterer` dynamically
- import `createPopper` dynamically

## [1.1.1] - 2024-05-09

### Fixed

- imports with relative paths were failing in `js` files.

## [1.1.0] - 2024-03-08

### Added

- Button to clear polygons in coordinates polygon field
- Button to clear holes in coordinates polygon field

## [1.0.0] - 2024-04-17

### Changed

- Migrated from `jsbundling-rails` to `importmaps-rails`

## [0.76.0] - 2024-04-17

### Added

- Updated `gems` and `npm` packages

## [0.75.0] - 2024-02-28

### Added

- `Bali::Commands::XlsxExport` class. This class allows us to use DSL in xlsx export.

## [0.74.1] - 2024-02-19

### Fixed

- Fix InputOnChangeController#change. Updated to use the new Slim Select 2.0 API.

## [0.74.0] - 2024-02-15

### Changed

- Allow `DrawingMapsController` to draw and export multiple polygons classified into shells and holes. As a result, the value from `coordinates_field` and `coordinated_field_group` has changed from `[{ lat: , lng:}]` to `{ shells: [{ lat: , lng:}], holes: [{ lat: , lng:}] }`. This format `[{ lat: , lng:}]` is still working to initilize the polygons within the map, but changes in the map will be store using the new format.

## [0.73.0] - 2024-01-31

### Fixed

- Slim select does not render

## [0.73.0] - 2024-01-30

### Changed

- Updated gems and npm packages

## [0.72.0] - 2024-01-26

### Added

- `Bali::Commands::CsvExport` class. This class allows us to use DSL in csv export.

## [0.71.1] - 2024-01-22

### Fixed

- Use `as` attribute of `form_for` in the `id` of the radio buttons when using `radio_buttons_group`

## [0.71.0] - 2023-11-28

### Added

- `Bali::BulkActions::Component` component. This component enables you to double-click on multiple DOM elements, selecting them, and subsequently applying an action.

## [0.70.0] - 2023-10-06

### Added

- `Cards` to `LocationsMap::Component`. These cards help to display detailed information for each marker. When a marker is clicked on, all cards matching the latitude and longitude of the marker will have the `is-selected` class added to them.

## [0.69.0] - 2023-09-19

### Changed

- Unify the data structure of the `Chart` component and `Chart.js`.

## [0.68.1] - 2023-09-19

### Fixed

- `name` attribute of the html `label` element of `switch_field_group`.

## [0.68.0] - 2023-09-19

### Added

- Add `display_percent` option on `Chart::Component` for automatically calculating and displaying percentages on the tooltip

## [0.67.3] - 2023-08-23

### Added

- `youtube` icon
- `title` to `mexican flag` icon
- `title` to `usa flag` icon
- `title` to `shopping cart` icon

### Changed

- color of the `facebook` and `instagram` icons to `currentColor`

### Changed

- `facebook` and `instagram` icons to fill with the current color.

## [0.67.2] - 2023-08-23

### Added

- `.is-margin-auto` CSS style
- `.is-circle` CSS style
- `.is-unclosable` CSS stlye to notification component. This css style hides the button to close the notification
- `icon_tag` helper method
- `Bali::TenancyTestsHelper`
- `Bali::TestsHelper`
- `Bali::Concerns::Mailers::RecipientsSanitizer`. This concern includes `send_mail` method, which removes inactive emails before sending mail.
- `Bali::Concerns::Mailers::UtmParams`
- `Bali::FlashNotifications::Component`

## [0.67.1] - 2023-08-15

### Changed

- Add CSS classes for different widths for select fields

## [0.67.0] - 2023-08-11

### Added

- Add ability to add custom filters on the Filters::Component
- Create `Bali::Types::DateRangeValue` to support :date_range type in `attribute` method

## [0.66.3] - 2023-08-08

### Added

- Custom class in the `currency_field_group` label when it renders a tooltip.

### Fixed

- Issue when an input field has an add-on and error

## [0.66.2] - 2023-07-18

### Added

- `Bali::Concerns::SoftDelete`
- `Bali::Concerns::Controllers::DeviceConcern`
- `GeocodeAdddressController` (javascript)
- `ios_naitve_app_user_agent` and `android_native_app_user_agent` as `Bali` configuration

## [0.66.1] - 2023-07-12

### Fixed

- Skip rendering for `ActionsDropdown::Component` when no content is present

## [0.66.0] - 2023-06-16

### Added

- Add `allow_input` to datepicker to be able to manually enter a date

## [0.65.1] - 2023-06-13

### Changed

- Relax ruby dependency to allow greater than `3.2`
- Update `library_version.thor` script to autodetect current version and increment it.
- Update Library authors

## [0.65.0] - 2023-06-07

### Changed

- Allow to add attributs to the FilterForm where only 1 value can be selected

### Fixed

- `TableController` check for elements presence before updating.

## [0.64.0] - 2023-06-05

### Added

- Add ability to add bulk actions to a `Table::Component`

## [0.63.0] - 2023-06-01

### Added

- Allow to persist the `FilterForm` filters across requests

## [0.62.0] - 2023-05-25

### Added

- Allow `slim_select_field` to autocomplete options from the server.

## [0.61.8] - 2023-05-23

### Changed

- Allow to add custom data attributes to `add/subtract` buttons in the step number field.

## [0.61.7] - 2023-05-14

### Fixed

- Pass the correct `route_path` argument instead of `route_name` to `Calendar::Header`

## [0.61.6] - 2023-04-18

### Changed

- Allows adding `custom icons` from the host application to the `Bali::Icon::Component`.

## [0.61.5] - 2023-03-31

### Added

- `Bali::Concerns::DateRangeAttribute` concern. This concern allows to define date range attributes, for example, `date_range_attribute :date_range, default: Time.zone.now.all_day`
- `max_date` option to `date_field_group` and `date_field`. you to set a maximum date that can be selected

## [0.61.4] - 2023-03-30

### Changed

- Renamed `route_name` to `route_path` in `Calendar` component. `route_path` expects a string, for example, `/lookbook`.

## [0.61.3] - 2023-03-26

### Fixed

- Fix `ransack` deprecation warning by avoiding passing a nil value to the `sort_link` method.

## [0.61.2] - 2023-03-14

### Added

- Add prefix and suffix to axis labels (`Chart` component)
- Prevent the tooltip title from being truncated (`Chart` component)
- Add prefix and suffix to tooltip label (`Chart` component)

## [0.61.1] - 2023-03-14

### Fixed

- Allow `TimeValue` to receive date string without seconds

## [0.61.0] - 2023-03-13

### Added

- Add `Message::Component`

### Changed

- Upgrade Gems

## [0.60.0] - 2023-03-13

### Changed

- `TimeValue`now returns a `Time` object when retrieved from DB to be able to format it.
- `time_field_group` is updated to handle a `Time` value instead of a `String`

## [0.59.2] - 2023-03-10

### Added

- Added sticky headers for table component.

## [0.59.1] - 2023-03-11

### Fixed

- Correctly scope the previous `ActionsDropddown::Component` css change.

## [0.59.0] - 2023-03-11

### Added

- Added a `readonly` option for the `Rate::Component` for display only purposes.

### Changed

- Add bottom-margin to `ActionsDropddown::Component` when placed inside a `.buttons` element to align with other buttons.

## [0.58.2] - 2023-02-20

### Changed

- Allow to override the `submit-on-change` `method` and `action` values throught the StimulusJS controller

## [0.58.1] - 2023-02-15

### Changed

- Ability to add multiple actions in a `List::Item::Component`
- Ability to add content in the middle of a `List::Item`

## [0.58.0] - 2023-02-11

### Changed

- Add ability to manage multiple files in a File Input

## [0.57.1] - 2023-02-02

### Added

- `@tiptap/pm` to `package.json` as `dependency`

### Fixed

- `Module not found` error when compiling assets in host application.

## [0.57.0] - 2023-01-31

### Fixed

- Added `Bali::Concerns::NumericAttributesWithCommas`. This concern complements the `percentage_field_group` and `currency_field_group` methods by removing the `commas` before saving the value to the DB.

## [0.56.3] - 2023-01-29

### Fixed

- Perform `Filters::Component` request with a `turbo_stream` format

## [0.56.2] - 2022-12-22

### Added

- Add `question-circle` icon

## [0.56.1] - 2022-12-20

### Added

- Add ability to specify a `submitter` on the `SubmitOnChange` controller in order to specify a different formaction and formmethod

## [0.56.0] - 2022-12-16

### Added

- Dispatch the `modal:success` event when the form is successfully submitted.

## [0.52.7] - 2022-12-06

### Added

- Allow to specity vertical alignment as a param for `Level::Component`

## [0.52.6] - 2022-12-02

### Changed

- Align file field ergonomics with other form inputs

## [0.52.5] - 2022-12-02

### Added

- Display all files selected in `file-input`

## [0.52.4] - 2022-12-02

### Fixed

- Fix `radio_field_group` display when it has an error.

## [0.52.3] - 2022-11-30

### Added

- Add `disabled` support for `Link::Component`

## [0.55.2] - 2022-11-30

### Added

- Add ability to display an icon in the trigger of the reveal component.

## [0.55.1] - 2022-11-16

### Added

- Add ability to hide `Table::Component` th

## [0.55.0] - 2022-11-16

### Added

- `Page Hyperlinks` to `Rich Text Editor`.

## [0.54.3] - 2022-11-15

### Added

- Add option to pass a container class to the `Navbar::Component`

## [0.54.2] - 2022-11-14

### Added

- `additional query params` to filters component. This helps to add query parameters not related to the form.

## [0.54.1] - 2022-11-11

### Updated

- Add a parameter to the `datepicker controller` to decide whether or not the alt input should be rendered.

## [0.54.0] - 2022-11-08

### Added

- Create `RichTextEditor::Component`

## [0.53.3] - 2022-10-21

### Added

- `wallet`, `wallet-alt`, `oxxo` icons.

## [0.53.2] - 2022-10-19

### Added

- Add option to specify a tooltip for a form label

## [0.53.1] - 2022-10-18

### Added

- Add `modal.fullwidth` class for full width modals
- Allow multiple CSS classes for the modal wrapper

## [0.53.0] - 2022-10-18

### Added

- Add `sparkles` icon

## [0.52.0] - 2022-10-17

### Changed

- Upgraded ruby and JS dependencies.

## [0.51.0] - 2022-10-15

### Added

- Create `ActionsDropdown::Component`

## [0.50.6] - 2022-10-14

### Added

- Add `chair`, `box-archive` and `file-export` icons
- Add option to add `custom-color` on tags

## [0.50.5] - 2022-10-14

### Added

- Add `url_field_group` form helper

## [0.50.4] - 2022-10-14

### Added

- Allow `SideMenu::Item` to render custom content

## [0.50.3] - 2022-10-13

### Added

- Add option to override when a `SideMenu::Item` should be active.

## [0.50.2] - 2022-10-12

### Added

- Add `align` option for `InfoLevel::Component`

## [0.50.1] - 2022-10-11

### Added

- `filters-alt` icon
- `closeOnClickOutside` as a value in `popup controller`. Default value is `true`.

## [0.50.0] - 2022-10-09

### Added

- Add `mode: range` for the `date_field` helper to allow for a range selection
- Create a preview for the `date_field`

## [0.49.0] - 2022-09-29

### Added

- Create `Hero::Component`

## [0.48.0] - 2022-09-29

### Added

- Create `LabelValue::Component` for displaying general values.

## [0.47.0] - 2022-09-27

### Updated

- `submit_actions` to display the cancel button in native apps when it is not being displayed inside a modal.

## [0.46.2] - 2022-09-27

### Fixed

- Display errors for `boolean_field_group` and fix styles when there are errors.

## [0.46.1] - 2022-09-27

### Fixed

- Add `is-danger` to datepicker input when there are errors.

## [0.46.0] - 2022-09-22

### Added

- `TurboNativeApp::SignOut` component.

## [0.45.1] - 2022-09-21

### Fixed

- Updated `GanttChart::Component` timeline headers calculation to fix current day flag and chart offset.

## [0.45.0] - 2022-09-15

### Updated

- Link component to add support for `native apps` when the `modal` attribute is set to `true`.
- Notification component to add `native-app` class. This class is useful for customizing the notification component when it appears in a native app.

## [0.44.0] - 2022-09-15

### Added

- Added a list footer to `GanttChart::Component`.

## [0.43.1] - 2022-09-13

### Fixed

- `dartsass-rails` requires replacing `image-url` with `url` to display icons/images.

## [0.43.0] - 2022-09-05

### Added

- Create `Progress::Component` for displaying a progress bar with percentage.

## [0.42.0] - 2022-08-30

### Added

- Create `List::Component` for displaying elements in a basic list

### Fixed

- Don't create a tippy instance when the contents are empty

## [0.41.2] - 2022-08-30

- Include third party CSS from the following libraries:
  - Trix
  - SlimSelect
  - Flatpickr

## [0.41.1] - 2022-08-29

- Allow `datepicker-controller` to enable/disabled weekends.

## [0.41.0] - 2022-08-27

- Migrate from `sassc-rails` to `dartsass-rails`
- Create new `PropertiesTable::Component`
- Add `Card::Header::Component` slot.
- Add `icon` option for `DeleteLink::Component` and add customize styles when it's inside a dropdown
- Add back button option for `PageHeader::Component`
- Update `more` icon

## [0.40.8] - 2022-08-27

- Add `month_field_group` method to generate fields with labels for date/year only inputs.

## [0.40.7] - 2022-08-24

- Added `badge-percent` icon.

## [0.40.6] - 2022-08-24

- Updated `GanttChart::Component` css to consider 4th level tasks.

## [0.40.5] - 2022-08-24

- Updated `Bali::Table::Component`. Fixes the `id` assignment for the table when `id` is defined inside `options`.

## [0.40.4] - 2022-08-24

- Updated `Bali::Table::Component`. Added an `id` to the `no records` row when the table is empty.

## [0.40.3] - 2022-08-24

- Add `infinity` icon.

## [0.40.2] - 2022-08-22

Fixes issue where using the back button resulted in the URL changing but the page not being updated. This was caused by manually manipulating the history object (history.pushState), because this interferes with how Turbo manages the restoration visits.

- removed `submitForm` function. Recommended approach is to call `form.requestSubmit()`

## [0.40.1] - 2022-08-18

Add `GanttChart::TaskActions::Component` displaying a menu with options for each task:

- Opening details
- Indent
- Outdent
- Delete

Refactor `HoverCard::Component` to use tippy to simplify and handle more options.

## [0.40.0] - 2022-08-18

Create `GanttChart::Component` for a full fledged Gantt Chart with the following functionality:

- Display a sortable and nestable list of tasks
- Fold/Unfold the nested lists
- Actions for changing the timescale between Day, Week and Month
- Button for focusing today's date and a today marker
- Draggable and Resizable tasks
- Visualize dependencies between tasks
- Display of milestones
- Resizable width of the task list
- Visualize weekends

## [0.39.1] - 2022-08-16

- Fix `Navbar` transparency.

## [0.39.0] - 2022-08-15

- Added `Clipboard` component. Copy text to clipboard.
- Added `copy`, `link-alt` icons.

## [0.38.1] - 2022-08-15

- Clean up event listeners from all StimulusJS controllers
- Override `SlimSelect#destroy` function to check for the presence of slim elements before removing them.

## [0.38.0] - 2022-08-14

- Convert `HelpTip` to a more general `Tooltip`. To create a HelpTip out of a Tooltip simply set a `<span>?</span>` as a trigger and add the class `help-tip` to the root component.

## [0.37.1] - 2022-08-12

- Update `ModalController` to check for targets (Wrapper and Background) existence before attempting action.

## [0.37.0] - 2022-08-5

- `radio-buttons-group-controller` was created.
- Update `ModalController` to look for `data-turbo` attribute in the form if it was not present in the `event.target`.

## [0.36.0] - 2022-08-4

- Update `radio-toggle-controller` to accept multiple values in current value.

## [0.35.1] - 2022-08-3

- Remove `stroke` attribute from `rect` and add `stroke` and `fill` in `svg` icons.

## [0.35.0] - 2022-08-3

- Add `under-modal` class to hide the hover-card when is necessary.

## [0.34.0] - 2022-08-3

- Add `open_on_click` property to `HoverCard::Component` to open the content on click.

## [0.33.0] - 2022-07-29

- Add `show_border` to `Reveal::Component` to show or hide the `border-bottom` just below the trigger.

## [0.32.2] - 2022-07-28

- Add `new` to CRUD actions to display an active tab when current_path is matched.

## [0.32.1] - 2022-07-28

- Remove `stimulus-chartjs` dependency.

## [0.32.0] - 2022-07-25

- Add `Timeago::Component`.

## [0.31.0] - 2022-07-25

- Add `Heatmap::Component`.

## [0.30.6] - 2022-07-18

- Add `crud` match type to `SideMenu::Item`. So it only considers items as active when current_path is one of the CRUD actions (index, show, edit.)

## [0.30.5] - 2022-07-18

- Add `starts_with` match type to `SideMenu::Item`. So it only considers items as active when current_path starts with the item's HREF

## [0.30.4] - 2022-07-18

- Only consider exact URL matches for displaying a `SideMenu::Item` as active. This fixes a problem where 2 items had a similar URL and both were considered active.

## [0.30.3] - 2022-07-14

- `step-number-input` controller was updated to be able to set a custom step.

## [0.30.2] - 2022-07-14

- Updated `PageHeader::Component` CSS to prevent overflow.

## [0.30.1] - 2022-07-12

- Updated `PageHeader::Component`, title and subtitle slots now receive an optional tag param to specify the size of the heading. New default title size is `h3` and subtitle is `h5`.

## [0.30.0] - 2022-07-11

- Create `Tags::Component` to display tags groups.
- Create `Tag::Component` to display individual tags.

## [0.29.0] - 2022-07-08

- Create `Rate::Component` to give feedback on something.

## [0.28.1] - 2022-07-08

- Allowed `InfoLevel::Component` to receive a block on its heading and title.

## [0.28.0] - 2022-07-08

- Create `Timeline::Component` to display contents in a vertical timeline

## [0.27.1] - 2022-07-07

- Update README with component updates
- Add `ImageGrid::Component` tests
- Add `Column::Component` previews
- Standardize on expect(page) syntax instead of using subject + is_expected

## [0.27.0] - 2022-07-07

- Added the `TrixAttachmentsController` for handling attachments in the `Trix` editor.

## [0.26.1] - 2022-07-07

- Fixed an issue when using icons in the content of `Reveal::Component`

## [0.26.0] - 2022-07-07

- Create `Reveal::Component` to display hidden content that can be revealed.

## [0.25.2] - 2022-07-06

- Upgrade dependencies.

## [0.25.1] - 2022-07-06

- Export `domHelpers`.

## [0.25.0] - 2022-07-05

- Add `Avatar::Component`. With this component we'll be able to see a preview of the image we want as an avatar.

## [0.24.4] - 2022-07-05

- Let `DeleteLink::Component` receive form classes for the `buttton_to` tag.

## [0.24.3] - 2022-07-05

- Add `type="button"` to Carousel controls (`arrows`, `bullets`).

## [0.24.2] - 2022-07-05

- Wrap card image slot in `slot` instead of `div`.

## [0.24.1] - 2022-07-05

- Set SideMenu list with optional title

## [0.24.0] - 2022-07-05

- `arrows` and `bullets` slots were added to `Carousel` component.

## [0.23.4] - 2022-07-05

- Fix SideMenu parent item when sub item is selected

## [0.23.3] - 2022-07-04

- Fix SideMenu sub items show only when active

## [0.23.2] - 2022-07-04

- Set `Delete` as default name for `DeleteLink::Component`

## [0.23.1] - 2022-07-04

- Add `Tabs::Trigger::Component`. In addition, a tab will cause the entire page to be reloaded when `href` is present.

## [0.23.0] - 2022-07-01

- Add `toInt` and `toFloat` JS formatters

## [0.22.0] - 2022-07-01

- Create `Carousel::Component`.

## [0.21.0] - 2022-07-01

- Create `SortableList::Component` to sort items in a list.

## [0.20.1] - 2022-07-01

- Display `SideMenu::Component` child items when item is active.

## [0.20.0] - 2022-07-01

- Create `Breadcrumb::Component` to improve the navigation experience

## [0.19.1] - 2022-07-01

- Custom notifications have been added for `no results/no records` in the table component.

## [0.19.0] - 2022-07-01

- Create `Stepper::Component` to display steps completed in a process

## [0.18.0] - 2022-06-30

- Added a `FormHelper` to add the `submit-button-controller` to the `form_for` method.

## [0.17.1] - 2022-06-30

- Update `hyphenize_keys` to return a hash in which the keys are symbols instead of strings.

## [0.17.0] - 2022-06-30

- Create `BooleanIcon::Component` and update Component Generator templates.

## [0.16.0] - 2022-06-30

- Added non-component stylesheets (`box`, `code`, `container`, `flatpickr_customizations`, `forms`, `general`, `panel`, `slim_select_customizations`, `switch`, `typography`, `variables`). In addition missing Hover Card styles (Frontend helpers) have been added to the Hover card.

## [0.15.3] - 2022-06-30

-Reorganize specs to have all tests within a bali/ folder.

## [0.15.2] - 2022-06-30

- Improve `FormBuilder` testing.

## [0.15.1] - 2022-06-29

- Pass the `options` parameter to the `SideMenu::Item::Component`.

## [0.15.0] - 2022-06-28

- Added `FormBuilder` and `FieldGroupWrapperComponent`.

## [0.14.0] - 2022-06-28

- Added `SideMenu::Component`.

## [0.13.0] - 2022-06-28

- Added Stimulus JS Controllers
  [`auto-play-audio`, `autocomplete-address`, `checkbox-toggle`, `elements-overlap`,
  `focus-on-connect`, `input-on-change`, `print`, `radio-toggle`, `submit-button`].

## [0.12.0] - 2022-06-24

- Added utils methods.

## [0.11.0] - 2022-06-23

- Added `wide` css class to `Dropdown::Component`.

## [0.10.0] - 2022-06-23

- Added conditional layout concern.

## [0.9.0] - 2022-06-22

- Added Time Value class and its corresponding tests.

## [0.8.1] - 2022-06-22

- Remove double validation in `Link::Component`.

## [0.8.0] - 2022-06-21

- Fix style in `Link::Component`.

## [0.7.0] - 2022-06-21

- Added FilterForm class and its corresponding tests.

## [0.6.0] - 2022-06-21

- Added Notification Component.

## [0.5.0] - 2022-06-17

- Completed `Loader` component.

## [0.3.0] - 2022-06-16

- Completed `Tabs` component. Added loading tab content on demand.

## [0.2.0] - 2022-06-15

- Completed `Link` and `Calendar` components.

## [0.1.0] - 2022-06-10

- `Navbar` component was added.
