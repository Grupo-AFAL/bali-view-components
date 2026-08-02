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

### `@blocknote/*` moves to `>= 0.52.1` — only matters if you render the BlockEditor

| | v2 | v3.0 |
|---|---|---|
| `@blocknote/core` `/react` `/mantine` | `>= 0.51.0` declared, `0.46.2` actually tested | `>= 0.52.1`, and 0.52.1 is what is tested |

The old bound was fiction: nothing inside the declared range had ever been run. v3 pins the
demo app to 0.52.1 and declares that same version, so the floor now means something.

- **Below 0.51 — a real break.** The editor writes its hidden input *during* the form's
  `submit` event and cannot await anything there, which requires the synchronous parsers and
  serialisers BlockNote introduced in 0.51. On older versions a form submitted inside the
  500 ms debounce window posts the previous content and the user's last edits vanish with no
  error.
- **0.51.x — a warning, not a break.** Nothing in the component calls a 0.52-only API, so it
  will most likely keep working, but you are outside the declared range and outside what
  anyone tested, and your package manager will say so.
- **Upgrade all seven together.** Mixing versions between `@blocknote/core` and
  `@blocknote/react` is not a build error. It shows up as a suggestion menu that never opens
  or content that silently fails to serialise, which is far more expensive to diagnose.

```bash
yarn add @blocknote/core@0.52.1 @blocknote/react@0.52.1 @blocknote/mantine@0.52.1
```

If you also render the paid XL features (`multi_column:`, `export:`, `ai_url:`), bump
`@blocknote/xl-multi-column`, `@blocknote/xl-pdf-exporter`, `@blocknote/xl-docx-exporter` and
`@blocknote/xl-ai` to the same 0.52.1. Their licences are unchanged from 0.46 — see the
[licence facts](../api/block-editor.md#licence-facts-as-of-blocknote-0521), which are pending
review by legal.

Two upstream table bugs present in 0.47 are fixed by this move: a `|` typed inside a table
cell no longer drops a column, and a table with no header row no longer promotes its first
data row to the header. If your stored content has tables, this is a reason to upgrade rather
than a cost of it.

**Your build needs Node >= 22.** `@blocknote/core` 0.52 depends on `lib0` `1.0.0-rc.22`, whose
`engines.node` is `">=22"`. On Node 20 the install itself fails — `Found incompatible module` —
so you find out at `yarn install`, not in production. Bump your CI and your Dockerfile before
bumping the package. This applies only if you render the BlockEditor; nothing else in Bali
raises the Node floor.

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
| `Bali::GanttChart::*` (component and sub-components) | nothing in v3 — see [The Gantt chart is gone](#the-gantt-chart-is-gone) |
| The `bali-view-components/gantt` npm entry | nothing — remove the import |

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

## The document editor contract changes

Only relevant if you render `Bali::DocumentEditor::Component`, `Bali::DocumentPage::Component`
or `Bali::BlockEditor::Component`. v3.1 packages a document engine on top of these, which
freezes them — so the awkward parts are being fixed now rather than inherited.

### Every URL the controller calls is now declared

The Stimulus controller used to assemble two of its own endpoints by string interpolation,
which made your `routes.rb` a guess it was making:

| | v2 | v3.0 |
|---|---|---|
| Restore a version | `POST "#{document_url}/restore_version"`, built in JS | `restore_version_url:`, a declared value |
| Fetch one version | `GET "#{versions_url}/#{id}"`, built in JS | `url` on each version in the versions JSON |

`restore_version_url:` **defaults to the old interpolated path**, so an app whose routes already
matched needs no change. Name it when they do not:

```erb
<%= render Bali::DocumentEditor::Component.new(
      title: @doc.title,
      initial_content: @doc.content,
      document_url: document_path(@doc),
      versions_url: document_versions_path(@doc),
      restore_version_url: restore_document_revision_path(@doc)
    ) %>
```

For per-version URLs, add a `url` to each entry your versions endpoint returns. When the field
is absent the controller still derives `"#{versions_url}/#{id}"`, so existing endpoints keep
working — but the derived form is a fallback now, not the contract.

```ruby
# The versions JSON. `id`, `version_number`, `author_name` and `created_at` are required;
# `summary` and `url` are optional.
render json: @document.versions.map { |v|
  {
    id: v.id,
    version_number: v.version_number,
    author_name: v.author_name,
    created_at: v.created_at,
    summary: v.summary,
    url: document_version_path(@document, v)
  }
}
```

### The PATCH payload root is no longer hardcoded to `document`

The auto-save sent `{ document: { title:, content: } }` and named the hidden input
`document[content]`, regardless of what your model was called. Both now follow `param_key:`:

| | v2 | v3.0 |
|---|---|---|
| Payload root | always `document` | `param_key:`, default `:document` |
| `input_name` default | always `document[content]` | `"#{param_key}[content]"` |

```erb
<%# Payload becomes { article: { title:, content: } }, input becomes article[content] %>
<%= render Bali::DocumentEditor::Component.new(..., param_key: :article) %>
```

Nothing changes for an app whose model *is* a `Document`. An app that was working around the
hardcoded root — permitting `params[:document]` for an `Article` — can now delete that
workaround. An explicit `input_name:` still wins over the derived one.

### `DocumentEditor` and `DocumentPage` stop mirroring BlockEditor's options

This one **breaks a call site**. Both components used to re-declare BlockEditor keyword
arguments purely to forward them — twelve in `DocumentEditor`, three in `DocumentPage`. They
now take one `config:` instead.

```erb
<%# v2 %>
<%= render Bali::DocumentEditor::Component.new(
      title: @doc.title, initial_content: @doc.content, document_url: document_path(@doc),
      comments: { url: comments_path, user: current_user_hash },
      export: true, export_filename: "roadmap",
      ai_url: "/ai", mentions_url: "/users",
      references_url: "/refs", references_resolve_url: "/refs/resolve"
    ) %>

<%# v3 %>
<%= render Bali::DocumentEditor::Component.new(
      title: @doc.title, initial_content: @doc.content, document_url: document_path(@doc),
      config: {
        comments: { url: comments_path, user: current_user_hash },
        export: true, export_filename: "roadmap",
        ai_url: "/ai", mentions_url: "/users",
        references_url: "/refs", references_resolve_url: "/refs/resolve"
      }
    ) %>
```

The moved keys are `ai_url`, `mentions_url`, `mentions`, `references_url`,
`references_resolve_url`, `references_config`, `comments`, `export`, `export_filename`,
`multi_column`, `upload_url` and `syntax_highlighting`. Anything else `DocumentEditor` takes —
`title:`, `initial_content:`, `document_url:`, `close_url:`, `versions_url:`, `editable:`,
`auto_save:`, `auto_save_delay:`, `input_name:` — is unchanged, because it is genuinely the
editor's own rather than a forwarded copy.

`config:` accepts a Hash or a `Bali::BlockEditor::Config`. Building the object once is the
point of the change — an app with one editor setup can now declare it in a helper and hand the
same value to every editor:

```ruby
def editor_config
  Bali::BlockEditor::Config.new(mentions_url: users_path, references_url: refs_path)
end
```

`BlockEditor::Component` itself is **not** breaking: it keeps every keyword argument it had and
merely gains `config:`. Where both are given, the explicit keyword wins, so a shared bundle can
be overridden one feature at a time:

```erb
<%# The app-wide config, but with AI off for this one editor %>
<%= render Bali::BlockEditor::Component.new(config: editor_config, ai_url: nil) %>
```

`DocumentPage` gains the other nine features as a side effect: it forwarded only the three
`references_*` keys, so it could never render mentions at all — not by decision, just by
omission.

### Two editors on one page no longer share an error toast

`useFileUpload` looked its container up with a global
`document.querySelector('[data-controller="block-editor"]')`. That was wrong twice: the exact
attribute match found nothing once a host put a second controller on the same element
(`data-controller="block-editor analytics"`), so upload errors vanished silently; and with two
editors it resolved to whichever came first in the document regardless of which one failed.
Errors are now appended inside the editor that raised them. No API change.

### Deleting a comment thread removes its highlight

`RESTThreadStore#deleteThread` left the highlight in the document. The removal passed a
freshly built mark to ProseMirror's `removeMark`, which matches on every attribute; BlockNote's
comment mark carries `orphan` as well as `threadId`, so the rebuilt mark only matched while
`orphan` was `false`. `orphan: true` is what BlockNote sets on a comment whose thread it can no
longer resolve — the exact state around a deletion. No API change.

`comments:` also takes `poll_interval:` now (milliseconds, default 5000; `0` turns polling
off), which was previously reachable only from JavaScript.

## RichTextEditor is deprecated

`Bali::RichTextEditor::Component` warns through `Bali.deprecator` and is **removed in 4.0**. It
still renders exactly as before in v3 — this is a warning, not a behaviour change.

Migrate to `Bali::BlockEditor::Component`, which reads and writes the same HTML:

```erb
<%# v2 %>
<%= render Bali::RichTextEditor::Component.new(
      html_content: @post.body, output_input_name: "post[body]", editable: true
    ) %>

<%# v3 %>
<%= render Bali::BlockEditor::Component.new(
      html_content: @post.body, input_name: "post[body]", format: :html, editable: true
    ) %>
```

`output_input_name:` becomes `input_name:`, and `format: :html` is what keeps the field
round-tripping HTML rather than BlockNote JSON. Content already stored as HTML is parsed on
mount, so there is no data migration.

**`images_url:` has no direct equivalent, and it is the part of this migration that needs work
on your side.** It is a *picker*: a `GET` that returns an HTML grid of already-uploaded images
for the user to choose from (`useImage.js` drops the response straight into a panel).
BlockEditor's `upload_url:` is a different thing — a `POST` that takes one file and answers
`{ "url": "..." }`. Renaming the option would point an endpoint that returns HTML at a request
that expects JSON. Give `upload_url:` an upload action instead; the engine ships one at
`/bali/block_editor/uploads` and it is the default, so most apps can simply drop `images_url:`.
The browse-existing-images panel itself has no BlockEditor equivalent — if you rely on it, that
is a custom block to build, and worth raising before you migrate.

If you want the smaller, single-line editor rather than the full block UI, pass
`preset: :simple`, which cuts the toolbar down to inline formatting and turns the slash menu
off without restricting what the schema can represent.

Removing `RichTextEditor` in 4.0 is what drops roughly thirty-five `@tiptap/*` optional peer
dependencies, plus `lowlight` and `highlight.js`, from the package. Until then nothing is
removed and `Bali.deprecator.silence { ... }` will quiet the warning if you need time.

## The Gantt chart is gone

`Bali::GanttChart::Component`, its nine sub-components, `GanttChartController`,
`GanttFoldableItemController`, the `bali-view-components/gantt` entry point and the
`bali_view.gantt_chart.*` strings are all removed. There is no v3 replacement, and no
deprecation cycle: no application in the group renders it (afal-apps adopted it in its PR
#203 and replaced it with a React island in #206), so the compatibility shim would have
had no one to serve.

If you do render it, you have three options:

1. **Wait for v3.1.** A new `Bali::Gantt` is planned there, built for read-only portfolio
   views, with the per-row `color_by:` that #667 asked for. It is not an API-compatible
   revival of this one — the drag/resize/dependency editor is not coming back.
2. **Server-render the view yourself.** afal-apps#426 did exactly this for a portfolio
   Gantt: `position: sticky` plus `<details>` for the parent/child folding, no JavaScript.
   A read-only chart uses almost none of what the component carried.
3. **Vendor the v2 component.** It is MIT and self-contained; copy
   `app/components/bali/gantt_chart/` out of the v2 tag into your app. You then own the
   two daisyUI v3 colour aliases it reads (`--in`, `--b3`), which no v5 theme defines.

Remove the import and the bundler alias:

```javascript
// delete
import { registerGantt } from 'bali-view-components/gantt'
registerGantt(application)
```

```javascript
// vite.config.js — delete the alias too
{ find: 'bali/gantt', replacement: resolve(baliGemPath, 'app/frontend/bali/gantt.js') },
```

The export is removed from `package.json` rather than left as a throwing stub, so a stale
import fails at build time instead of rendering an empty container at runtime. `sortablejs`
stays an optional peer: Kanban and SortableList still need it.

**#667 is closed by this removal, not solved by it.** A portfolio Gantt whose bar colour
encodes project status has no v3 answer; the workaround recorded on the issue (one CSS class
per status, fighting the component's inline `style` with `!important`) dies with the
component. If that view matters to you, it is the one to raise against the v3.1 `Bali::Gantt`
design.

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
worked. Both keys now ship in **`bali_view.pagination.*`** in en and es — see
[Pagination](#pagination-one-footer-one-summary-key-one-adapter) for why they landed there
and not under `pagination_footer`. Rename yours or delete it; leaving it under the old path
is silently dead.

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

## Pagination: one footer, one summary key, one adapter

v2 had three implementations of the same band — summary on the left, page controls on the
right. `Bali::PaginationFooter` was one, the bottom of `Bali::DataTable` was a second copy
of it inline, and `Bali::Pagination` sat under both. Two of them built the summary sentence
independently, so one string had two translation keys and a host had to find both.

`DataTable` now renders `PaginationFooter`. Nothing about its own API changed —
`show_summary:`, `summary_position:`, `item_name:` and `with_custom_pagy_nav` all keep
working — but three things move underneath it.

**The summary key.** One key survives, and it is not the one you would guess from the
component name:

| v2 / earlier v3 betas | v3.0 |
|---|---|
| `bali_view.data_table.summary` | `bali_view.pagination.summary` |
| `bali_view.data_table.default_item_name` | `bali_view.pagination.default_item_name` |
| `bali_view.pagination_footer.summary` | `bali_view.pagination.summary` |
| `bali_view.pagination_footer.default_item_name` | `bali_view.pagination.default_item_name` |

It lives under `pagination` because that is the family: the aria labels for the page buttons
were already there, and `pagination_footer` is one of two components that render the
sentence. Both keys ship in en and es. The old paths resolve to nothing — an override left
behind is dead, not merged.

**A summary of nothing is now nothing.** With `count == 0` the footer printed
"Showing 0-0 of 0 movies" under an empty table. It is suppressed, in the footer and in
`summary_position: :top` alike, and a footer with neither summary nor controls left to draw
no longer emits its container or its vertical padding. If your tests assert on that string
for an empty result set, they are asserting on the bug.

**`url:` on `Bali::Pagination::Component` is honoured now, which is the breaking part.** Pagy
43 injects the request into every Pagy the `pagy()` helper builds, and the component took the
branch that let Pagy build its own URLs — so `url:` was silently dropped for anyone using the
standard helper. It now wins whenever it is given:

```erb
<%# v2: url: ignored, links kept ?q=batman  →  v3: links are /movies?page=2, no q %>
<%= render Bali::Pagination::Component.new(pagy: @pagy, url: '/movies') %>
```

Drop the `url:` and let Pagy build the links (that is what `pagy(scope, path: '/movies')` is
for), or put the query string you need into the value you pass. `url:` is still what a Pagy
built by hand needs — `Pagy::Offset.new(...)` carries no request and cannot build a URL at
all.

Two parameters arrive in exchange, both forwarded by `PaginationFooter` along with the
`size:`/`variant:`/`url:` it used to swallow:

```erb
<%= render Bali::PaginationFooter::Component.new(
      pagy: @pagy,
      fragment: '#results',                 # every link keeps the reader where they were
      data: { turbo_frame: 'movies' }) %>   # page inside a Turbo Frame
```

`pagy(scope, fragment: '#results')` does the same thing from the controller, and is the
better place for it when the whole page paginates. The anonymous `**options` bucket on
`Pagination::Component.new` is gone; it never reached the template, so nothing that passed
through it ever had an effect. `data:` reaches each page **link**, not the wrapper — that is
where a `turbo_frame:` has to be to do anything.

Honouring `url:` also made a latent bug reachable, so it is fixed here: with **countless**
pagination the link does not carry the page number but `"5+4"`, the page plus the last page
Pagy knows about, and Bali used to build that query with `Rack::Utils`, which escaped the `+`
to `%2B` and lost half the value. The query is now built by Pagy itself. Nothing to do on your
side; if you had worked around it, you can stop.

**Everything Bali knows about Pagy now lives in `Bali::Pagination::PagyAdapter`.** If you
subclassed or monkey-patched the component to survive a Pagy upgrade, patch the adapter
instead — it is the only file that calls anything Pagy does not promise.

### The footer's spacing, if you compose it yourself

`DataTable`'s footer is pixel-identical to v2's — same gap, same padding, same rule above it,
measured A/B. Getting there needed one API decision worth knowing about if you render
`PaginationFooter` yourself: **its spacing is a set you swap, not one you add to.**

Standing on its own the band carries `gap-2 py-4`. Passing `class: 'mt-4 pt-4 border-t'` to
put it under a rule does *not* replace that — you end up with `py-4` and `pt-4` on one
element, `pt-4` redundant and `py-4` still padding the bottom, because no `pt-*` cancels the
bottom half of a `py-*` and Tailwind settles the top half by stylesheet order rather than by
the order you wrote the classes. Use the flag instead:

```erb
<%= render Bali::PaginationFooter::Component.new(pagy: @pagy, divider: true) %>
```

`divider: true` swaps the whole set for `gap-4 mt-4 pt-4 border-t border-base-200`: the
breathing room goes above the line, and nothing pads below a band that closes a listing.

One thing about the footer did change shape: on a phone the summary now sits above the
controls rather than below, because the inline version carried `order-*` utilities that
flipped them and the shared one does not. Same height, same spacing, reversed reading order.

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

### `context:` — one view for the page and for the drawer

The five page components take a `context:`, and it is what lets you delete the
`if drawer_request?` at the top of every `new`/`edit`/`show` template. Nothing is renamed and
nothing is removed, so **a host that keeps its `if` keeps working unchanged** — this is worth
doing when you next touch the file, not as a migration sweep.

```erb
<%# v2 — the two branches differ by exactly two arguments %>
<% if drawer_request? %>
  <%= render Bali::FormPage::Component.new(title: t(".title"), card: false) do |page| %>
    <% page.with_body do %><%= render "form" %><% end %>
  <% end %>
<% else %>
  <%= render Bali::FormPage::Component.new(title: t(".title"),
                                           back: { href: vendors_path }) do |page| %>
    <% page.with_body do %><%= render "form" %><% end %>
  <% end %>
<% end %>

<%# v3 — one call, both contexts %>
<%= render Bali::FormPage::Component.new(title: t(".title"),
                                         back: { href: vendors_path }) do |page| %>
  <% page.with_body do %><%= render "form" %><% end %>
<% end %>
```

`context:` takes three values:

| value | meaning |
|---|---|
| `:auto` | the default: ask the request |
| `:page` | full page chrome, whatever the request says |
| `:drawer` | overlay chrome, whatever the request says |

Inside a drawer the component drops the **breadcrumbs**, the **back button** and — on
`FormPage` — the **Card**. The first two are ways *out* of a page, and a drawer is closed
rather than left; the Card is the panel the drawer already draws. They are dropped even when
you pass them, because the whole point is that the one surviving call site does pass `back:`.

**Why the component never reads `params`.** `Bali::LayoutConcern` now defines
`drawer_request?` — `params[:layout] == "false"`, the same value its layout switch has always
read — and exposes it as a helper. `context: :auto` asks the view context for that helper and
renders a page when it is not there. Two consequences worth knowing:

- **If your controllers already declare a `drawer_request?` helper of their own — the very
  pattern this replaces — autodetection works with no change to them at all.** That is the
  common case: the helper is what the deleted `if` was calling.
- If they do not, `include Bali::LayoutConcern` in `ApplicationController`. A controller with
  a layout of its own must then declare it as `self.conditional_layout = "admin"` rather than
  `layout "admin"`: a `layout` call in a subclass overrides the concern's and takes the
  layout skipping with it.

**The escape hatches.** `card:` is an ordinary argument and always wins, `card: true` inside
a drawer included. For the breadcrumbs and the back button the escape hatch is
`context: :page`, which restores the whole page chrome inside a drawer request; combine the
two (`context: :page, card: false`) and every arrangement is reachable.

**When the host still has to branch.** `page.drawer?` is public and yielded with the
component, because some differences are behavioural rather than chrome: a Cancel that
*closes* an overlay and a Cancel that *navigates* are two different elements. Pass it down
(`render "form", drawer: page.drawer?`) instead of reading `params` in the partial. A page
component decides its own chrome; it does not decide what your buttons do.

Lookbook cannot issue a drawer request, so a preview of the drawer variant has to force it —
see the "Page or drawer" scenarios of `FormPage` and `ShowPage`.

### 4. Give `PageHeader` an `h2` if your layout already owns the page's `h1`

The page title is now the page's `h1`. In v2 it was an `h3` and no page component emitted an
`h1` at all, so the heading outline of every Bali page started at level 3. All five page
components inherit this through `PageHeader`, and so does `PageHeader` used directly.

**This is the only edit most hosts owe.** If the surrounding layout — your own application
layout, a shell, a navbar brand — already renders an `h1`, the page now has two, and two
`h1`s is the same kind of axe failure the empty `h6` was:

```erb
<%# The layout already renders <h1>Costa Norte</h1> %>

<%# v2: the title was an h3 and the layout's h1 stood alone %>
<%= render Bali::ShowPage::Component.new(title: @shipment.folio) %>

<%# v3: hand the page component the level it should use %>
<%= render Bali::ShowPage::Component.new(title: @shipment.folio) do |page| %>
  <% page.with_title(@shipment.folio, tag: :h2) %>
<% end %>
```

Check it the way the acceptance criterion was checked — in the rendered DOM, not by reading
the template:

```js
document.querySelectorAll('h1').length                                    // must be 1
[...document.querySelectorAll('h1,h2,h3,h4,h5,h6')]
  .filter(h => !h.textContent.trim())                                     // must be []
```

The better fix, where you control the layout, is to drop the layout's `h1` — a site name is
not the page's heading — and let the page component name the page.

### `PageHeader`: `tag:` is semantic, `class:` is the size

`Bali::PageHeader::Component::HEADING_SIZES` is **gone**. The title slot used to derive its
font size from the heading level through that table (`h1` → `text-4xl` … `h6` → `text-base`),
which would have turned the `h1` default and the `tag: :h2` migration above into visual
changes: the title would have grown to 36px, then shrunk to 30px for anyone doing the
accessible thing. The size now lives in `TITLE_CLASSES` and does not move with the tag.

```erb
<%# v2: the tag chose the size %>
<% c.with_title('Movies', tag: :h1) %>          <%# → text-4xl %>

<%# v3: the tag is the element, the class is the size %>
<% c.with_title('Movies', tag: :h1, class: 'text-4xl') %>
```

Rendered sizes are unchanged if you pass nothing: `text-2xl` for the title, `text-sm` for
the subtitle.

Three more shape changes in the same component:

- **The subtitle is a `<p>`, not an `<h6>`.** It describes the title instead of opening a
  section. Pass `tag:` if you really want a heading. CSS keyed on `h6.subtitle` needs
  `.subtitle`.
- **Nothing renders when there is nothing to render.** No title text and no block means no
  heading element; same for the subtitle. If you leaned on the empty `h6` as a spacer, it is
  gone — put the space on your own content.
- **A block is the CONTENT of the heading, not a replacement for it.**
  `with_title { tag.h3(...) }` produced an `h3` inside an `h3`, which the parser splits into
  an empty heading plus yours. Pass the text, or put non-heading markup in the block.

### `PageHeader`: title tags moved out of the heading, and the back button got a name

`title_tags` is a slot on `PageHeader` itself now, and the badges render as siblings of the
heading rather than inside it — inside, they joined the heading's accessible name ("The
Matrix Action Released"). The markup goes from `h1 > div.flex > [title, tags]` to
`div.page-header-title > [h1.title, tags]`. **CSS or tests keyed on `.title .badge` need
`.page-header-title .badge`.**

The back button carries `aria-label` from `bali_view.page_header.back` ("Go back" /
"Volver"), skipped when you pass a visible `name:`. Override it per call site with
`back: { href: path, 'aria-label': 'Back to shipments' }`, or globally by defining
`bali_view.page_header.back` in your own `config/locales` — host locale files win now.

`Bali::Icon` renders `aria-hidden="true"` by default. Lucide already hid its own `<svg>`;
the kept, custom and legacy icon sources did not, and the attribute now sits on the wrapper
where it covers all four. If an icon of yours is genuinely the only carrier of meaning, pass
`"aria-hidden": false` — and give it an accessible name, or it is still announced as nothing.

### `PageHeader`: what changes below `sm`

Under `sm` the back button takes a row of its own instead of standing in a gutter beside the
title. Measured at 375px: the title went from 291px of usable width starting 52px in, to the
full 343px starting at the page's left edge, in line with the breadcrumb above it and the
body below it. The cost is 44px of header height on mobile pages that have a back button.
Desktop geometry does not change.

Pass `responsive: false` to `PageHeader` to keep the v2 inline arrangement at every width.
Page components do not forward that option; they always stack.

### `Level` and `InfoLevel` are deprecated

Both keep working and warn until 4.0. `Level` → flex utilities
(`flex justify-between items-center gap-4`), or `Bali::PageHeader::Component` for a page
header. `InfoLevel` → a grid of `Bali::StatCard::Component`.

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

## `Bali::Tag` drops the Bulma names, and stops wrapping

Two changes to one small component, both of which can reach an app that never touched a
`DataTable`.

### The Bulma names raise instead of resolving

`COLORS` and `SIZES` carried a block of Bulma aliases marked "deprecated, remove in v2.0".
They are gone, and an unrecognised value now raises `ArgumentError` at construction rather
than dropping the class:

| v2 | v3 |
|---|---|
| `color: :danger` | `color: :error` |
| `color: :link` | `color: :primary` |
| `color: :black` | `color: :neutral` |
| `color: :dark` | `color: :neutral` |
| `color: :light` | `color: :ghost` |
| `color: :white` | `color: :ghost` |
| `size: :small` | `size: :sm` |
| `size: :medium` | `size: :md` |
| `size: :large` | `size: :lg` |
| `size: :normal` | `size: :md` (or drop it — `md` is the default) |
| `light: true` | `style: :outline` |

The error names the replacement, so a missed call site reads
`Bali::Tag::Component: color :danger is a Bulma name removed in v3. Use color: :error.`
rather than rendering an uncoloured tag. A value in neither list gets the list of valid
ones instead. `light:` is rejected the same way even though it is no longer a keyword
argument: it would otherwise be swallowed by `**options` and rendered as a `light="true"`
HTML attribute, which is the silent no-op this whole change exists to remove.

Only `Bali::Tag` changed. `Bali::Icon` and `Bali::Message` have their own `:small` /
`:danger` scales and still accept them.

The knock-on to watch: `Bali::Kanban::Column` passes its `color:` straight through to a
Tag, and its own `badge_class` tolerates an unknown value by falling back to `:ghost`. A
column declared with a colour outside `Bali::Tag::COLORS` used to render ghost-coloured
and now raises.

```
grep -rn "Tag::Component" app/ | grep -E ":danger|:link|:black|:dark|:white|:small|:medium|:large|:normal|light:"
```

### A Tag is single-line now

daisyUI 5 gives `.badge` a fixed `height: var(--size)` and no white-space control, so a
label the container squeezes wrapped its extra lines *outside* the pill — the reported
symptom was role names "disappearing" from a table. `Bali::Tag` now sets `white-space:
nowrap` and a `1.2` line-height on itself.

**The trade is deliberate and it is visible.** A tag that used to wrap now keeps its full
width, so a container that has somewhere to put it grows and a container that does not gets
a tag sticking out of it:

- Inside `Bali::Table` (or anything else with `overflow-x-auto`), the table widens and the
  container scrolls. This is the fix.
- Inside a fixed-width box with no horizontal scroll — a narrow card, a sidebar panel — the
  pill now overhangs its box instead of breaking. Measured on a 256px card, a
  28-character tag overhangs by 9px.

If a specific call site really wants the old wrapping, opt out per tag. The rule ships in
`@layer components`, so a plain utility class beats it — no `!` variant:

```erb
<%= render Bali::Tag::Component.new(text: role, class: "whitespace-normal") %>
```

That restores the v2 rendering, broken pill included. `Bali::Timeline::Header` is
unaffected either way: it emits `.badge` markup directly rather than rendering a Tag.
## One `color:` across the library

Seven components used to keep seven private colour maps. They agree now, through
`Bali::Color`:

| Keyword | Takes | Follows the DaisyUI theme? |
|---|---|---|
| `color:` | `:neutral :primary :secondary :accent :info :success :warning :error :ghost` | Yes |
| `custom_color:` | a hex string (`#rgb`, `#rrggbb`, and the alpha forms) | No |

The seven are `Tag`, `Status`, `Heatmap`, `Chart`, `Timeline::Item` /
`Timeline::Header`, `StatCard` and `Kanban::Column`. A value outside the list
raises `ArgumentError` at construction instead of falling back; the message names
the component and the valid values, and a removed Bulma name is told its
replacement.

### The renames

| v2 | v3 | Where |
|---|---|---|
| `icon_name: 'users'` | `icon: 'users'` | `Bali::StatCard`. Deprecated shim warns through `Bali.deprecator`; removed in v4 |
| `color: :default` | `color: :ghost` | `Bali::Timeline::Item`. Also the default, so dropping it entirely works too |
| `color: :outline` | `color: :primary, class: 'badge-outline'` | `Bali::Timeline::Header`. It named a style, not a colour |
| `color: '#7c3aed'` | `custom_color: '#7c3aed'` | `Bali::Heatmap`, and each option hash of `Bali::Status` |
| `color: :chartreuse` (anything unknown) | raises | `Bali::Heatmap`, `Bali::StatCard`, `Bali::Kanban::Column` used to fall back silently |

```
grep -rn "StatCard::Component" app/ | grep icon_name
grep -rn "Timeline::\(Item\|Header\)\|with_item\|with_header" app/ | grep -E ":default|:outline"
grep -rn "Heatmap::Component" app/ | grep -E "color: *[\"']#"
```

`icon_name:` on `Bali::Link`, `Bali::Button` and `Bali::ImageField::Input` did
**not** change. `StatCard` did, and so did `DeleteLink` — see "One taxonomy for
every button" below.

### Heatmap follows the theme now, and that is a visual change

`Bali::Heatmap`'s "DaisyUI colour presets" were hardcoded hex: `:primary` was
`#6366f1` whatever theme the host had chosen. The ramp is built from
`var(--color-*)` now, so a host that picked `:primary` expecting indigo will see
its own primary. Measured on the nine ramps side by side, moving from `light` to
a custom theme changes 6 of 9 — `:primary` from indigo to that theme's teal,
`:secondary` from pink to gold.

If you were relying on the old fixed colours, name them: `custom_color: '#6366f1'`
reproduces the v2 `:primary` exactly, and the other six were `#8b5cf6`
(secondary), `#f59e0b` (accent *and* warning), `#22c55e` (success), `#3b82f6`
(info) and `#ef4444` (error).

### Status opens in the dark now

`Bali::Status`'s panel hardcoded `#fff` with `#6b7280` text and `#d1d5db` borders,
so under any dark theme it opened as a white rectangle. It reads
`--color-base-100` / `--color-base-content` now. Nothing to change in a call site;
if your app patched around it with its own CSS, that patch is what to remove.

The twelve fixed status colours are unchanged and still do not follow the theme —
that is the point of them. They are simply joined by the semantic names, so
`color: :success` on a status option now means what it means everywhere else.

### Chart takes a colour

New, not a break: `Bali::Chart::Component.new(color: :success)` starts the palette
at that colour, so a single-series chart is painted in it. `custom_color:` takes a
hex and drops the theme palette entirely — a `<canvas>` cannot resolve a `var()`,
so a chart cannot mix a hex with theme colours; the remaining series fall back to
the fixed hex list.

### Removed constants

`Bali::Heatmap::Component::COLOR_PRESETS`,
`Bali::Kanban::Column::Component::BADGE_COLORS`, and `Bali::Utils::ColorPicker`'s
`THEME_COLORS`, `CSS_VAR_MAP`, `FALLBACK_COLORS`, `.gradient`, `.theme_color` and
`.theme_color_with_alpha`. `Bali::Color::NAMES` and `Bali::Color.css` replace what
was reachable of them.

## One taxonomy for every button

`Button`, `Link` in button dress, `DeleteLink` and `BulkActions::Action` all render
DaisyUI's `.btn`, and each carried its own table of modifiers. They disagreed on the axis
DaisyUI 5 is most careful to separate: `Button` listed `outline` next to `primary`, as if a
border and a colour were the same kind of thing; `Link` spelled that same thing
`style: :outline`; `DeleteLink` offered neither and took only `size:`, capped at `lg`;
`BulkActions::Action` kept a fourth private map and built its size class by interpolation,
which Tailwind's scanner cannot see. Learning one of the four taught you nothing about the
other three.

There is one table now, `Bali::ButtonTaxonomy`, and three independent keywords:

| Keyword | Means | Values |
|---|---|---|
| `variant:` | the colour | `:neutral :primary :secondary :accent :info :success :warning :error :ghost :link` |
| `style:` | the fill | `:outline`, `:soft` |
| `size:` | the scale | `:xs :sm :md :lg :xl` |

`ghost` and `link` are styles in DaisyUI's own docs, not colours. They stay under `variant:`
because that is where every call site already writes them, and because they are mutually
exclusive with a colour in practice. The axis that moved is the one that was genuinely
duplicated.

### `Bali::Link` no longer takes `type:`

It was deprecated in v2.0 and it is gone. *Rejected*, not ignored: `<a type="primary">` is
valid HTML, so letting it fall through to `**options` would have rendered an attribute
nobody asked for instead of the colour they did ask for.

```erb
<%# v2 %>
<%= render Bali::Link::Component.new(name: 'Create', href: new_path, type: :primary) %>
<%# v3 %>
<%= render Bali::Link::Component.new(name: 'Create', href: new_path, variant: :primary) %>
```

```
grep -rn "Link::Component" app/ | grep "type:"
```

`Bali::Button`'s `type:` is untouched. It always meant the HTML attribute (`:button`,
`:submit`, `:reset`) and still does — the collision between the two meanings is the reason
`Link` lost its own.

### `Button(variant: :outline)` becomes `Button(style: :outline)`

```erb
<%# v2 %>
<%= render Bali::Button::Component.new(name: 'Sign in', variant: :outline) %>
<%# v3 %>
<%= render Bali::Button::Component.new(name: 'Sign in', style: :outline) %>
```

```
grep -rn "Button::Component" app/ | grep "variant: *:outline"
```

Nothing else moved: `variant: :primary`, `:ghost`, `:link` and the rest are unchanged on
both `Button` and `Link`.

### Unknown values raise

All three keywords validate, on all four components. A name outside its table raises
`ArgumentError` at construction instead of silently rendering a button with no colour — the
failure mode that let a stale `:danger` survive two majors past its removal note by merely
looking plain. The message names the keyword that does take the value:

```
Bali::Button::Component: variant: :outline is a fill, not a colour. Use style: :outline.
Bali::Link::Component: variant: :danger is a Bulma name removed in v3. Use variant: :error.
```

This is the change most likely to find call sites for you. If you build a `variant:` from a
database column or a config file, that path now raises where it used to render something
colourless — check it before deploying, not after.

### `DeleteLink` gains the taxonomy, and merges its two icon keywords

`variant:`, `style:` and `size:` work on `DeleteLink` too, and `size: :xl` exists where the
private table stopped at `lg`. The default is unchanged: `variant: :ghost` plus the
destructive `text-error`, which is exactly what the old hardcoded `btn btn-ghost text-error`
produced. `text-error` also applies to `variant: :link` — those two are the variants with no
colour of their own. Name any other colour and it owns the button, because `btn-error` with
`text-error` on top is red on red.

`icon:` said whether and `icon_name:` said which. One keyword says both now:

```erb
<%# v2 %>
<%= render Bali::DeleteLink::Component.new(href: path, icon: true) %>
<%= render Bali::DeleteLink::Component.new(href: path, icon_name: 'circle-x') %>
<%# v3 %>
<%= render Bali::DeleteLink::Component.new(href: path, icon: true) %>
<%= render Bali::DeleteLink::Component.new(href: path, icon: 'circle-x') %>
```

`icon_name:` still works and warns through `Bali.deprecator`; it is removed in v4. It is the
same rename `StatCard` made, so the note further up about `Link`, `Button` and
`ImageField::Input` keeping their `icon_name:` now has a second exception.

`Dropdown#with_item` and `ActionsDropdown#with_item` are unaffected: they still take
`icon_name:` for every item, delete items included, and translate it. An item is not the
place to make a caller notice which of the two components it is about to become.

### `DeleteLink`'s disabled state is a button, not an anchor

```html
<!-- v2 -->
<a disabled class="btn btn-ghost text-error btn-disabled">Delete</a>
<!-- v3 -->
<button type="button" aria-disabled="true" class="btn btn-ghost text-error btn-disabled">Delete</button>
```

HTML has no `disabled` attribute on an anchor, so v2's disabled state existed only as paint:
the accessibility tree saw an ordinary run of text, and a screen reader announced neither a
control nor that it was unavailable. `aria-disabled` on a real button says both.

Deliberately **not** `disabled`, and deliberately no `tabindex="-1"`: either one takes the
button out of the tab order, and with it the hover card that `disabled_hover_url` renders,
which is the only place the reason for the disabled state is written. Focusable and inert is
the point.

If you style that state by selector, `a[disabled]` and `a.btn-disabled` no longer match;
`.btn-disabled` still does. The disabled state also draws its icon now, which it used to
drop.

### `BulkActions::Action`

`variant:` accepts `:link` and the two `style:` values it never had, and its size class comes
from the shared table instead of `"btn-#{size}"`. That interpolation was invisible to
Tailwind's scanner, so those classes only ever shipped because some other component happened
to spell them out. Nothing to change at your call sites.

## Timeline renders each entry once, and its slots lose the `tag_` prefix

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

## Three alerts become two: `Alert` and `Toast`

`Bali::Message`, `Bali::Notification` and `Bali::FlashNotifications` all wrapped the same
daisyUI `.alert`. They are now:

| v2 | v3 |
|---|---|
| `Bali::Message::Component` | `Bali::Alert::Component` |
| `Bali::Notification::Component` | `Bali::Toast::Component`, inside a `Bali::ToastContainer::Component` |
| `Bali::FlashNotifications::Component` | `Bali::ToastContainer::Component` |

All three old names keep working and warn through
[`Bali.deprecator`](#balideprecator). They translate their own keywords, so nothing has to
change on the day you upgrade. They are removed in 4.0.

```
grep -rn "Bali::Message::Component\|Bali::Notification::Component\|Bali::FlashNotifications::Component" app/
grep -rn "data-controller=\"\(message\|notification\)\"" app/
```

### The keywords

| v2 | v3 | Where |
|---|---|---|
| `type: :success` | `color: :success` | `Notification`. One keyword for a colour across the library |
| `color: :primary` / `:link` | `color: :info` | `Message`. Both rendered `alert-info` |
| `color: :secondary` | `color: :neutral` | `Message`. It rendered a bare `.alert` |
| `color: :danger` | `color: :error` | Both |
| `dismissible: true` | `closable: true` | `Message` |
| the `is-unclosable` class | `closable: false` | `Notification`. Nothing in the gem ever set the class |
| `delay: 5000` | `duration: 5000` | `Notification` |
| `dismiss: false` | `duration: nil` | `Notification`. `dismiss:` was the timer, never the button |
| `fixed: true` + `position: :top_right` | a `ToastContainer(position: :top_end)` around it | `Notification` |
| `notice:` / `alert:` | `flash: flash` | `FlashNotifications` |

`color:` now takes `:neutral :info :success :warning :error` and nothing else, because
daisyUI has no other alert colours — there is no `alert-primary`. **An unknown name raises
`ArgumentError`** at construction rather than falling back, and the message names its
replacement when there is one. The old fallbacks were how `:primary`, `:secondary` and
`:link` survived two majors past Bulma: every one of them silently rendered `alert-info`.

`role:` is unchanged and still wins over everything, but the default is not: it is derived
from the colour now. `:error` announces as `alert`, and everything else — including
`:warning` — as `status`. In v2 every `Message` was `role="alert"`, so an informational
banner interrupted the screen reader mid-sentence. `polite:` and `assertive:` still work as
sugar. An unknown `role:` raises instead of falling back to `alert`.

### A toast does not position itself any more

```erb
<%# v2 %>
<%= render Bali::Notification::Component.new(type: :success, position: :top_right) do %>
  Saved.
<% end %>

<%# v3 %>
<%= render Bali::ToastContainer::Component.new(position: :top_end) do |c| %>
  <% c.with_toast(color: :success) { 'Saved.' } %>
<% end %>
```

The container spells its nine corners as `top`/`middle`/`bottom` crossed with
`start`/`center`/`end` — `:top_end`, `:bottom_start`, `:middle_center` — which are daisyUI's
own names and are direction-aware. `:top_right` and `:bottom_right` are the only two v2 had;
the deprecated `Notification` still accepts them and maps them for you.

A `Bali::Toast` rendered on its own is simply an inline alert that closes itself, which is
what `Notification(fixed: false)` was. That still works and needs no container.

### The flash

`Bali::AppLayout` renders the container for you and reads the **whole** flash hash. In v2 it
read `flash[:notice]` and `flash[:alert]` and dropped everything else, so `flash[:warning]`
and `flash[:info]` never appeared.

| flash key | renders as |
|---|---|
| `notice`, `success` | success |
| `alert`, `error`, `danger` | error |
| `warning` | warning |
| `info` | info |
| anything else | nothing — `flash[:timedout]` and friends are state, not messages |

If you render the container yourself:

```erb
<%= render Bali::ToastContainer::Component.new(flash: flash) %>
```

### The Stimulus controllers merge

`MessageController` and `NotificationController` are replaced by a single `AlertController`,
registered under the identifier `alert`. **`message` and `notification` no longer register**,
so any hand-written `data-controller="notification"` or `data-controller="message"` in your
own templates has to be renamed, and so do the values on it:

| v2 attribute | v3 attribute |
|---|---|
| `data-notification-delay-value` | `data-alert-duration-value` |
| `data-notification-dismiss-value` | dropped — `duration` absent means no timer |
| `data-notification-animation-class` | `data-alert-leaving-class` |
| `data-message-dismiss-id-value` | `data-alert-dismiss-id-value` |
| `data-turbo-cache="false"` | `data-turbo-temporary` |

`import { MessageController }` and `import { NotificationController }` from the npm package
stop resolving; import `AlertController` instead.

### The animation classes are gone from the global namespace

`.slideInRight` and `.fadeOutRight` — animate.css names the package was squatting in every
host's global namespace — are removed from `bali/general.css`. They are replaced by
`.toast-component` (enter) and `.toast-leaving` (leave) in
`app/components/bali/toast/index.css`. If your app used either class on its own markup, copy
the keyframes into your own stylesheet; nothing in Bali emits them any more.

The controller no longer waits for `animationend` to remove a toast. It reads the leaving
animation's duration back out of `getComputedStyle` and removes the element on a timer, so
a toast leaves even when the animation never runs — a background tab, or a leaving class you
pointed the controller at and never styled. If you replaced Bali's auto-dismiss with your own
because notifications used to stay on screen forever, that is the bug, and you can drop the
replacement. Setting `data-alert-leaving-class` to a class of any duration works without
telling the controller how long it takes; a class with no animation removes the element at
once, which is also what `prefers-reduced-motion: reduce` produces.

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
grep -rn "hovercard:\|sortable-list:\|interact:on\|direct-upload:" app/
grep -rn "useDispatch\|use-dispatch\|baliDispatchDebugEnabled" app/ config/
# alerts and toasts — the class names, the keywords and the Stimulus identifiers
grep -rn "Bali::Message::Component\|Bali::Notification::Component\|Bali::FlashNotifications::Component" app/
grep -rn "data-controller=\"\(message\|notification\)\"\|MessageController\|NotificationController" app/
grep -rn "is-unclosable\|slideInRight\|fadeOutRight" app/
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

## The sidebar's hidden checkboxes are gone

The mobile drawer and the desktop collapse were driven by two `<input type="checkbox">`
elements with `class="hidden"`, flipped by `<label for=…>`. Neither was reachable by keyboard,
which made the sidebar pointer-only on mobile. Both are now state classes owned by
`SideMenuController`, and every control is a `<button>`.

**Nothing to do if you only used the components.** The renames below are the whole surface.

| Removed | Replacement |
|---|---|
| `Bali::SideMenu::Component::MOBILE_TRIGGER_ID` | `Bali::SideMenu::Component::DEFAULT_ID` (`"side-menu"`) — now the sidebar's DOM `id` |
| `SideMenu.new(mobile_trigger_id:)` | `SideMenu.new(id:)` |
| `Topbar.new(mobile_trigger_id:)` | `Topbar.new(menu_id:)` (`nil` still means "no hamburger") |
| `Navbar::Burger.new(trigger_id:)` | `Navbar::Burger.new(menu_id:)` |
| `input.side-menu-mobile-trigger` | `.side-menu-component.is-active` |
| `input.side-menu-collapse-trigger` | `.side-menu-component.is-collapsed` |
| `bali_view.side_menu.toggle_mobile` | `bali_view.side_menu.trigger.toggle` |
| `bali_view.side_menu.toggle_collapse` | *(deleted — the collapse buttons use `collapse` / `expand`, which already existed)* |

If you wrote your own hamburger — a `<label for="side-menu-mobile-trigger">`, or a button with
`data-action="navbar#toggleSideMenu"` — replace it with the component:

```erb
<%= render Bali::SideMenu::Trigger::Component.new %>
<%# a sidebar with a custom id: %>
<%= render Bali::SideMenu::Trigger::Component.new(menu_id: "reports-menu") %>
```

`navbar#toggleSideMenu` still works — it dispatches the same `bali:side-menu:toggle` window
event — but a control wired to it gets no `aria-expanded` and no focus restoration.

Any CSS of your own that reached for those checkboxes stops matching. The common one is the
content offset:

```css
/* before */
.app-layout--has-fixed-sidebar:has(.side-menu-collapse-trigger:checked) .app-layout-content { … }
/* after */
.app-layout--has-fixed-sidebar:has(.side-menu-component.is-collapsed) .app-layout-content { … }
```

Also drop any `padding-top` you added to the sidebar's first section: an untitled first list
now gets the same `pt-3` a titled one gets from its label.

### `AppLayout(fixed_sidebar:)` now defaults to `true`, and a mismatch raises

`AppLayout` defaulted to `false` while `SideMenu` defaulted to `fixed: true`, so the two
defaults together produced a pinned sidebar over content that was never offset for it. They
agree now, and `AppLayout` raises in development and test when the sidebar it rendered
disagrees with the flag.

If you were relying on the old default, pass both:

```erb
<%= render Bali::AppLayout::Component.new(fixed_sidebar: false) do |layout| %>
  <% layout.with_sidebar do %>
    <%= render Bali::SideMenu::Component.new(current_path: request.path, fixed: false) %>
  <% end %>
<% end %>
```

`viewport_locked:` follows suit: its default is now whether a fixed sidebar was *actually*
rendered into the slot, not the raw flag. `fixed_sidebar: true` with an empty sidebar slot no
longer locks the page to the viewport. Passing `viewport_locked:` explicitly is unaffected.

### `AppLayout` renders a skip link and owns `<main>`'s id

The layout now emits `<a class="bali-skip-link" href="#main-content">` as the first focusable
element of the page and `<main id="main-content" tabindex="-1">` as its target. **If your app
already renders its own skip link inside the layout's body slot, remove it** — otherwise
keyboard users get two — or pass `skip_link: false`. If you were selecting `main` by a
different id, note that it has one now.

### `SideMenu` becomes a `<nav>` and `Topbar` a `<header>`

`SideMenu`'s root element is a `<nav aria-label>` and its sections are `ul`/`li`; `Topbar`'s is
a `<header>`. Both keep their classes (`.side-menu-component`, `.bali-topbar`), so CSS and
tests that select on those are fine; `div.bali-topbar` and `.side-menu-component > div` are
not.

## What breaks, and what replaces it

| Removed | Replacement |
|---|---|
| `Bali::Link(type:)` | `variant:` *(raises — deprecated since v2.0)* |
| `Bali::Button(variant: :outline)` | `style: :outline` |
| `Bali::DeleteLink(icon_name:)` | `icon:`, which now takes a name too *(deprecated shim until v4)* |
| `<a disabled>` from a disabled `Bali::DeleteLink` | `<button aria-disabled="true">` |
| `Bali::StatCard(icon_name:)` | `icon:` *(deprecated shim until v4)* |
| `Bali::Message::Component` | `Bali::Alert::Component` *(deprecated shim until v4)* |
| `Bali::Notification::Component` | `Bali::Toast::Component` + `Bali::ToastContainer::Component` *(deprecated shim until v4)* |
| `Bali::FlashNotifications::Component` | `Bali::ToastContainer::Component` *(deprecated shim until v4)* |
| `Message(dismissible:)` | `closable:` |
| `Notification(delay:, dismiss:)` | one `duration:` in ms; `nil` never auto-closes |
| `Notification(type:)` | `color:` |
| `Notification(fixed:, position:)` | `ToastContainer(position:)`, spelled `:top_end` not `:top_right` |
| the `is-unclosable` class | `closable: false` |
| `MessageController` / `NotificationController` | `AlertController`, identifier `alert` |
| `.slideInRight` / `.fadeOutRight` | `.toast-component` / `.toast-leaving` |
| `Bali::Timeline::Item(color: :default)` | `color: :ghost` |
| `Bali::Timeline::Header(color: :outline)` | `color: :primary, class: 'badge-outline'` |
| A hex in `Bali::Heatmap(color:)` or a `Bali::Status` option's `color:` | `custom_color:` |
| `Bali::Heatmap::Component::COLOR_PRESETS` | `Bali::Color::NAMES` / `Bali::Color.css` |
| `Bali::Kanban::Column::Component::BADGE_COLORS` | `Bali::Tag::Component::COLORS` |
| `ColorPicker.gradient` / `.theme_color` / `.theme_color_with_alpha` | `Bali::Color.gradient` / `.css` / `.with_alpha` |
| `Bali::SideMenu::Component::MOBILE_TRIGGER_ID` | `Bali::SideMenu::Component::DEFAULT_ID` |
| `SideMenu(mobile_trigger_id:)` | `SideMenu(id:)` |
| `Topbar(mobile_trigger_id:)` | `Topbar(menu_id:)` |
| `Navbar::Burger(trigger_id:)` | `Navbar::Burger(menu_id:)` |
| `c.with_tag_item` / `c.with_tag_header` on `Bali::Timeline` | `c.with_item` / `c.with_header` *(deprecated shim until v4)* |
| `Bali::Timeline::Header(tag_class:)` | `color:` plus `class:` *(deprecated shim until v4)* |
| `bali_view.data_table.summary` | `bali_view.pagination.summary` |
| `bali_view.data_table.default_item_name` | `bali_view.pagination.default_item_name` |
| `bali_view.pagination_footer.*` | `bali_view.pagination.*` |
| `Bali::Pagination::Component.new(**options)` | `fragment:` and `data:`, which reach the links |
| the DataTable's inline footer markup | `Bali::PaginationFooter::Component` |
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

## The calendar drops `all_week:` and brings its own card

`all_week:` was deprecated in 2.x and is now gone, together with the `#all_week` reader a
template could call. It read backwards — `all_week: false` was how you *hid* the weekend —
and supporting both spellings needed a `nil` default on a boolean just to tell "not given"
from "given as false".

```erb
<%# v2 %>
<%= render Bali::Calendar::Component.new(all_week: false) %>   <%# hide the weekend %>
<%= render Bali::Calendar::Component.new(all_week: true) %>    <%# show it %>

<%# v3.0 %>
<%= render Bali::Calendar::Component.new(weekdays_only: true) %>
<%= render Bali::Calendar::Component.new(weekdays_only: false) %>  <%# the default %>
```

**This one does not raise.** The component still takes `**options` and ignores them, so a
leftover `all_week: false` is swallowed and the calendar quietly renders seven columns
instead of five. It fails as a layout change, not as an error, which is why it is worth
grepping for rather than waiting to see:

```
grep -rn "all_week:" app/          # the keyword argument
grep -rn "\.all_week\b" app/       # the reader, if a template called it
```

Careful with the second one: `Date#all_week` is ActiveSupport's and is unrelated.

Two smaller changes come with it. `weekly_title_class` is now a declared keyword argument
rather than a key fished out of `**options`; same behaviour, same name, nothing to change.
And the component **renders `Bali::Card` itself** instead of writing `.card`/`.card-body`
divs by hand — so if you wrapped it in your own `Bali::Card`, remove that wrapper or you
get a card inside a card. The markup is otherwise the same three elements;
`.calendar-component > .card > .card-body` still matches, `.month-view` and `.week-view`
are still on the card, and the card's `shadow` became `shadow-sm`, which compiles to an
identical `box-shadow` in Tailwind 4.

### `start_date` and `period` stop raising on junk input

Not a migration step — a behaviour change you should know about because it removes a 500
from your app. Both parameters normally arrive from the query string (the header's
prev/next links write them back to `route_path`), and both used to raise on input a
visitor controls: `?start_date=zzz` was an unrescued `Date::Error`, `?period[]=1` a
`NoMethodError`. Anything unparseable now becomes `Date.current`, and any unknown period
becomes `:month`.

The component does **not** validate — a wrong date and a typo both silently become today.
If your UI needs to tell the user their date was rejected, check the param in the
controller before handing it over; the component only guarantees it will not take the page
down.

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

## Six components get the accessibility they were missing

Each of these showed something on screen and nothing at all to the accessibility tree.
Three of the six change markup a host may be selecting on, one changes what a value means,
and one raises where it used to render.

### `BooleanIcon`: `nil` is no longer `false`

`value: nil` used to collapse into `false` through `!!value` and render the red ✗. It now
renders a neutral dash and announces "Not specified". If you were relying on nil reading
as "no" — a nullable boolean column where unset means no — say so:

```erb
<%# before: nil painted a red ✗ %>
<%= render Bali::BooleanIcon::Component.new(value: movie.indie) %>

<%# after, if you want the old behaviour for nil %>
<%= render Bali::BooleanIcon::Component.new(value: !!movie.indie) %>
```

Everything that is not `nil` keeps the old coercion: a truthy non-boolean is still true.

Every state now renders an `sr-only` name next to the icon — "Yes" / "No" /
"Not specified", from `bali_view.boolean_icon.true` / `.false` / `.blank`. The default is
correct but context-free; pass `label:` where the surrounding markup does not supply the
subject:

```erb
<%= render Bali::BooleanIcon::Component.new(value: movie.indie, label: t('.indie_film')) %>
```

### `LabelValue` renders a `<dl>`, not a `<div>` with a `<label>`

| Before | After |
|---|---|
| `<div class="mb-2">` | `<dl class="mb-2">` |
| `<label class="font-bold text-xs …">` | `<dt class="font-bold text-xs …">` |
| `<div class="min-h-6">` | `<dd class="min-h-6">` |

Every class name is unchanged, so CSS keyed on them still applies. Selectors and tests
that name the *element* do not:

```
grep -rn "div.mb-2\|label.font-bold\|div.min-h-6" app/ test/ spec/
```

Reach for `Bali::PropertiesTable::Component` instead when the pairs form one set read top
to bottom — it renders a single `<table>` of `<th scope="row">` rows, so a screen reader
gets table navigation over the whole set. `LabelValue` is right for a pair that stands on
its own, or when each pair needs its own placement in a grid.

### `Tabs` with `href:` renders a `<nav>`, and mixing raises

When **every** tab has an `href:`, the component renders `<nav aria-label>` with plain
links and `aria-current="page"` on the active one. Gone from those links: `role="tab"`,
`aria-selected`, and the `id="tab-N"` they used to carry (it existed to be the
`aria-labelledby` target of a panel that does not exist here). The wrapper loses
`data-controller="tabs"` too — there is no panel to switch. The `.tabs` / `.tab` /
`.tab-active` classes are all unchanged, so CSS keyed on them still applies.

```erb
<%# renders <nav aria-label="Section navigation"> %>
<%= render Bali::Tabs::Component.new(label: 'Project sections') do |tabs| %>
  <% tabs.with_tab(title: 'Summary', href: project_path(@project), active: true) %>
  <% tabs.with_tab(title: 'Quality', href: project_quality_path(@project)) %>
<% end %>
```

Pass `label:` whenever a page has more than one of these; the default is
`bali_view.tabs.navigation`.

**Mixing the two modes now raises `ArgumentError`.** This used to render, badly:

```erb
<%# raises %>
<%= render Bali::Tabs::Component.new do |tabs| %>
  <% tabs.with_tab(title: 'Overview', href: '/overview') %>
  <% tabs.with_tab(title: 'Details', active: true) { 'inline panel' } %>
<% end %>
```

Split it into two components, or drop `href:` from all of them — `src:` is how a panel
loads its content on demand without leaving the page.

```
grep -rn "with_tab(" app/ | grep "href:"
```

Tabs with panels are untouched: same roles, same controller, same markup.

### `Chart` names its canvas, and can carry a real table

The canvas is `role="img"` with a name — `aria_label:`, else `title:`, else a translated
generic. Nothing to change unless you were selecting on `canvas.chart` having no `role`.

A name is not a number. The new `data_table` slot renders `sr-only` beside the canvas and
is the only way a screen reader user reads a value off the chart:

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

### `Heatmap` axis labels are `<th>`

The x labels stay at the foot of the chart and the y labels on the left — nothing moves
visually — but they are `<th scope="col">` and `<th scope="row">` now, and each data cell
carries its value as `sr-only` text. Only a selector naming `tfoot td` or `tbody td` for a
label breaks; the classes are unchanged and the axis labels pick up `font-normal` so the
weight matches what the `<td>` rendered.

### `Kanban` announces drops, and its columns are lists

Each column's card stack is `role="list"` with an `aria-label` carrying the count
(`"Backlog, 0 cards"` for an empty one), each card is `role="listitem"`, and the board
renders one `role="status" aria-live="polite"` region that announces every drop.

The board also gains an outer `<div class="kanban-component">` to hold the controller and
that region. The grid used to be the root element, so a host that made the Kanban a flex or
grid *item* is now positioning the wrapper; `class:` still lands on the grid.

Two things to do in a host app:

1. **Register the `kanban` Stimulus controller.** `registerAll` picks it up with no
   change. An app that registers controllers one at a time has to add it:

   ```js
   import { KanbanController } from 'bali-view-components'
   application.register('kanban', KanbanController)
   ```

2. **Pass `label:` on cards that do not lead with their title.** The announcement uses the
   card's own text by default, truncated to 60 characters, which reads badly on a card
   whose first line is a date or an avatar:

   ```erb
   <% col.with_card(update_url: task_path(task), label: task.title) do %>
     …
   <% end %>
   ```

The column label is server-rendered, so after a client-side drop it is exactly as stale as
the count badge beside it. Both refresh together when the page re-renders.

`SortableList`'s `bali:sortable-list:end` event now also carries `item`, `from`, `to`,
`oldIndex` and `newIndex` alongside the `order` and `toListId` it always had. Additive —
existing listeners keep working.
## The field caption becomes a `<label for>`, and every control gets a name

A `<legend>` names the `<fieldset>` around a control, never the control itself. Every
`*_field_group` in v2 was therefore an input with no accessible name. Check it the way this
change was verified — the HTML is not evidence, because a `for` pointing at an id nobody
emits looks perfect and names nothing:

```
# DevTools → Elements → Accessibility pane, on any form field.
# "Name" must be the caption text, not empty.
```

The caption is a `<label for="<the input's real id>">` in the 18 families that wrap exactly
one labelable control, and stays a `<legend>` in the groups that hold several:
`boolean_field_group`, `radio_field_group`, `radio_buttons_group`,
`coordinates_polygon_field_group`, `block_editor_group`, `rich_text_area_group`,
`direct_upload_field_group` and `recurrent_event_rule_field_group`. In those, the controls
already carry names of their own, and a second `<label for>` on a control that has one does
not replace its name — it concatenates with it.

### What to grep for

```
grep -rn "legend.fieldset-legend\|legend\.fieldset" app/ test/ spec/
grep -rn "field-[a-z_]*\"\|#field-" app/ test/ spec/
grep -rn "_select_div\|_period\"" app/ test/ spec/
```

| v2 | v3 |
|---|---|
| `<legend class="fieldset-legend">` | `<label class="fieldset-legend" id="<field_id>_label" for="<field_id>">` (single-control families) |
| `<fieldset id="field-synopsis">` | `<fieldset id="movie_synopsis_field">` |
| `<div id="status_select_div">` (SlimSelect wrapper) | `<div id="movie_status_select_div">` |
| `<select id="created_at_period">` (time period) | `<select id="movie_created_at_period">` |
| `<select id="freq">`, `id="interval"`, `id="bymonth"`… (recurrence) | `id="<field_id>_freq"`, `_interval`, `_yearly_on_1_bymonth`… |
| `<label class="label cursor-pointer" for="movie_indie">` around a checkbox | same `<label>`, no `for` — the wrapping association names it |

The three hand-built ids all ignored the object name, the index and any nested-attribute
path, so **two forms for the same model on one page emitted each of them twice**. They now
come from Rails' `field_id`, so the form index keeps them apart. The
`field_group_wrapper/two_forms_same_model` preview is that case, deliberately.

### A 6 px layout change comes with it

daisyUI's `.fieldset` is `display: grid` with `gap: .375rem` and `padding-block: .25rem`, and
a rendered `<legend>` is **not** a grid item: it is placed above the anonymous grid box and
escapes both. An ordinary `<label>` is a grid item, so it picks them up. Measured on
`form/text/with_help_text_and_errors`:

| | caption top | fieldset height |
|---|---|---|
| v2 (`<legend>`) | 16 px | 126 px |
| v3 (`<label>`) | 20 px | 132 px |

Each field group is 6 px taller and its caption sits 4 px lower. Nothing in Bali neutralises
it: daisyUI exposes no custom property for either value, so the fix would hard-code copies of
two of its literals. If the density matters to you, set it yourself once, on your side:

```css
/* Unlayered, because .fieldset is daisyUI and layers beat specificity. */
.fieldset > label.fieldset-legend { margin-block-start: -0.25rem; margin-block-end: -0.625rem; }
```

### Errors and help are announced now

The control carries `aria-invalid="true"` when the field has an error, and an
`aria-describedby` naming only the paragraphs that are actually in the DOM — the error id
when there is an error, the help id when `help:` was passed, both when both. If you added
either attribute by hand around Bali, remove yours: writing `aria: { invalid: }` and
`"aria-invalid" =>` both emits the attribute twice. Bali skips whichever spelling you already
used, so your value wins, but two sources of truth for the same state is worth collapsing.

### Names that did not exist before

- The icon-only search submits in `search_field_group`, `Bali::Filters` and
  `Bali::SearchInput` were announced as "button". They carry an i18n'd `aria-label`
  (`bali_view.form_builder.search.submit`, `bali_view.filters.submit_search`,
  `bali_view.search_input.submit`). Override them like any other key.
- `Bali::DataTable::SimpleFilters` captions were `<label>` elements with no `for`. They are a
  `<label for>` over a single control, and a `<span>` naming a `role="group"` over several.
  Its documented-but-never-rendered `search: { label: }` option now becomes the search box's
  `aria-label`.
- `RecurrentEventRuleForm`'s twelve selects and number inputs had no captions at all; the new
  `bali_view.recurrent_event_rule_form.*_label` keys name them. It also takes an `id:` now,
  for the one case the derived ids cannot tell apart: the same attribute rendered twice in
  one form, where Rails would repeat ids too.
- With `altInput` on (the default), flatpickr builds a **new** input and turns the original
  into `type="hidden"`, copying only placeholder/disabled/required/tabIndex. The `<label for>`
  and both aria attributes therefore stopped applying to the field the user types into.
  `DatepickerController` forwards them after init. If you wrapped a Bali date field to work
  around the missing name, drop the workaround.

### Still unnamed

BlockNote's ProseMirror `contenteditable` — the editor creates it client-side, so there is no
id at render time and naming it needs an `aria-labelledby` the editor writes when it mounts.
SlimSelect's dropdown search input and its `role="combobox"` trigger are named by that
library. The bare `*_field` helpers never rendered a caption; that is the `_group` variant's
job, and they are unchanged.

## The FormBuilder's dead daisyUI 4 classes are gone

daisyUI 5 removed `label-text`, `label-text-alt`, `input-bordered`, `textarea-bordered` and
`form-control`. Check it against your own compiled CSS — the count is zero:

```
grep -c "\.label-text\|\.input-bordered\|\.textarea-bordered\|\.form-control" app/assets/builds/tailwind.css
```

Because they define nothing, **removing them changes no pixel**. What changes is what a
selector can find. Grep your app for the five names and expect hits in three places:

```
grep -rn "label-text\|input-bordered\|textarea-bordered\|form-control" app/ test/ spec/
```

1. **System tests and CSS that select Bali's markup.** `input.input-bordered`,
   `textarea.textarea-bordered`, `span.label-text`, `p.label-text-alt` and `.form-control`
   no longer match anything the FormBuilder renders. Rewrite them against the class that is
   still there (`input.input`, `textarea.textarea`) or against the new one below.
2. **Your own templates.** Bali does not touch them; they keep working exactly as they do
   today, which is to say the classes keep doing nothing. Sweep them at your own pace.
3. **Anything that relied on `label-text-alt` for small type.** It never delivered that in
   v2 either — the size came from `.fieldset`'s own `font-size: .75rem`, inherited by every
   child, and it still does.

| v2 (dead in daisyUI 5) | v3 |
|---|---|
| `<p class="label-text-alt text-error">` (the error) | `<p class="fieldset-label text-error" id="<field_id>_error">` |
| `<p class="label-text-alt">` (the help) | `<p class="fieldset-label" id="<field_id>_help">` |
| `<span class="label-text">` inside a checkbox/toggle/radio label | `<span>` — the wrapping `.label` styles it, as in daisyUI 5's own markup |
| `input input-bordered w-full` | `input w-full` |
| `textarea textarea-bordered w-full` | `textarea w-full` |

`select-bordered` is **not** in that table and has not been removed: it is the one class of
the family with live definitions, in Bali's own SlimSelect stylesheet.

### A field with help and an error now shows both

In v2, `field_helper` was `if errors? … elsif help`, so an error replaced the help text.
Both render now, error first. Two consequences worth grepping for:

- a test asserting one paragraph under a control (`assert_selector('.control + p', count: 1)`)
  finds two whenever the field has help **and** is invalid;
- checkboxes, toggles, ranges, and textareas with a character counter never rendered `help:`
  at all. If you passed `help:` to any of them and worked around the silence with your own
  markup, that markup is now duplicated by the real one.

Both paragraphs carry ids derived with Rails' `field_id` — `movie_synopsis_error` and
`movie_synopsis_help`. Nothing points `aria-describedby` at them yet; that is a later change.

## Checkboxes and toggles: `label:` splits into `label:` and `text:`

`boolean_field_group`, `check_box_group` and `switch_field_group` used one `label:`
for two different captions, and rendered both. `boolean_field_group :indie` produced
a `<legend>Indie</legend>` **and** a `<span>Indie</span>` beside the box, so the
control was announced "Indie Indie" — the duplicate label this release removes.

The two captions now have a key each:

| Key | What it renders | Default |
|---|---|---|
| `text:` | the caption inside the `<label>` wrapping the control, which is where the control's accessible name comes from | the translated attribute name |
| `label:` | a `<legend>` over the fieldset | **none** — no legend unless you ask for one |

**What you have to change.** Every call passing `label:` to these three helpers, or
to the bare `boolean_field` / `switch_field`, means `text:` today:

```erb
<%# before — one caption asked for, two rendered %>
<%= f.switch_field_group :email_notifications, label: t(".email_notifications") %>

<%# after %>
<%= f.switch_field_group :email_notifications, text: t(".email_notifications") %>
```

Leaving `label:` in place is not an error and does not lose the string, but it moves
that string into the legend and puts the *attribute name* back beside the control —
which is the duplicate again, wearing different words. Keep `label:` only where you
genuinely want a caption over the group:

```erb
<%= f.boolean_field_group :indie, label: "Distribution", text: "This is an indie film" %>
```

`text:` is a Bali option, so it is stripped before the hash reaches Rails and never
lands on the input as an attribute. `text: false` renders no inline caption; do that
only alongside a `label:`, or the control ends up with no accessible name at all.

The bare `boolean_field` and `switch_field` no longer read `label:` for anything.

### `switch_field_group` and `range_field_group` render through the same wrapper now

Both used to build a `<fieldset>` by hand. They go through `FieldGroupWrapper` like
the other seventeen families, which changes their markup:

- the fieldset gains `w-full` and an `id` derived from `field_id`
  (`movie_indie_field`). It had **no id at all** before, so two forms for the same
  model on one page were indistinguishable;
- both gain `tooltip:`, `label: false`, `field_class:` and `field_data:`, which the
  hand-rolled wrappers never supported;
- `range_field_group`'s caption loses `text-sm font-medium`. It is a plain
  `.fieldset-legend` now, like every other group's. **If you relied on that weight,
  style `.fieldset-legend` yourself.**

`range_field` also stops building its input through `@template.range_field(object_name, …)`.
Handing the view helper a bare object name discarded the form index, so two indexed
forms emitted the same `id` *and* the same `name` — the caption's `for` pointed at an
id nobody emitted, and on submit the second slider's value overwrote the first. It
delegates normally now, so an indexed form finally produces `movie_2_rating` /
`movie[2][rating]`. **Any selector hardcoding the un-indexed id inside an indexed
form stops matching**, which is the bug going away, not a regression.

## Currency and percentage follow the locale, and lose their inert `step`

`currency_field_group` and `percentage_field_group` are one implementation now
(`numeric_field_group`), and three things change.

**The `pattern` is built from the active locale.** It was the frozen English literal
`^(\d+|\d{1,3}(,\d{3})*)(\.\d+)?$`, so an amount typed the correct Spanish way —
`1.234,56` — was rejected by the browser before it ever reached the server. Both
separators now come from Rails' `number.format.delimiter` and `number.format.separator`.
An app with `rails-i18n` gets the right pattern per locale for free; an app without it
resolves to Rails' English defaults in every locale and behaves exactly as before.
`pattern_type: :number_with_commas` still works and now resolves this way — the name
is a misnomer kept for compatibility, and `:localized_number` is its real name.

**`step: "0.01"` is gone.** These render `type="text"` — they have to, or the
thousands delimiter cannot survive being typed — and `step` is inert on a text input.
It validated nothing and only misled whoever read the markup next. **If you were
passing `step:` yourself, it never did anything either.**

**`inputmode="decimal"` is set,** so a phone opens the numeric keypad instead of the
alphabetic one. Pass your own `inputmode:` to override it.

The server side moved with it. `Bali::Concerns::NumericAttributesWithCommas` stripped
commas and nothing else, so under a Spanish locale it turned `"1.234,56"` into
`1.23456` — no exception, no validation error, just a number four orders of magnitude
too small. It now removes the locale's delimiter and normalises its separator. **If
you worked around this with a setter of your own, remove it before it double-parses.**

## `dynamic_fields` renders buttons, and the method is `dynamic_fields_group`

`link_to_add_fields` and `link_to_remove_fields` emit `<button type="button">`
instead of `<a href="#">`. Nothing there navigates, so an anchor was announced as a
link going nowhere and the `#` jumped the page to the top on any activation the
Stimulus action did not swallow. It also broke the maximum-size cap: `connect()`
disables the add control once the association is full, and `disabled` is inert on an
`<a>`, so the control looked capped and stayed clickable.

**Any CSS or test selecting `a.btn`, `a[href="#"]` or an `<a>` inside these stops
matching.** The helpers keep their `link_to_` prefix — renaming them is a separate
change — so only the markup moves.

Separately, `docs/guides/form-builder.md` documented a `dynamic_fields` method that
does not exist. It is and always was `dynamic_fields_group`.

## `ImageField` stops calling a third party on every render

`Bali::ImageField::Component`'s placeholder was `https://placehold.jp/128x128.png`,
so rendering the component fired a request at a host nobody in this project controls:
it leaked the page's Referer, put a stranger's uptime in front of a form field, and
left the component broken behind an offline or egress-filtered network. It is an
inline SVG data URI now.

Nothing to change unless you were passing `placeholder_url:` — that still works — or
asserting on the old URL in a test. The placeholder art itself changes.

## Checklist

```
grep -rn "with_actions_panel\|with_export\|table_id:\|data_display_mode\|toolbar_class:" app/
grep -rn "label-text\|input-bordered\|textarea-bordered\|form-control" app/ test/ spec/
grep -rn "legend.fieldset-legend\|#field-\|_select_div\|aria-invalid" app/ test/ spec/
grep -rn "with_tag_item\|with_tag_header\|tag_class:" app/
grep -rn "all_week:" app/                             # silently ignored now, shows the weekend
grep -rn "Bali::Card.*Calendar\|Calendar" app/views   # the Calendar renders its own card

grep -rn "with_preview" app/                          # DocumentPage's body slot
grep -rn "Bali::Level\|Bali::InfoLevel" app/          # deprecated, removed in 4.0
grep -rn "turbo_stream.replace \"data-table-" app/
grep -rn "Tag::Component" app/ | grep -E ":danger|:link|:black|:dark|:white|:small|:medium|:large|:normal|light:"
grep -rn "Bali::Card.*DataTable\|render Bali::Card" app/views/**/index*
# any listing that groups and already used `view`, or that does not start on the table?
grep -rn "group_by_attribute" app/
grep -rn "view=\|params\[:view\]" app/views app/controllers
# pagination: dead summary keys, and url: that now wins instead of being dropped
grep -rn "data_table:\|pagination_footer:" config/locales
grep -rn "Bali::Pagination.*url:" app/
# a11y: markup that moved under your selectors
grep -rn "div.mb-2\|label.font-bold\|div.min-h-6" app/ test/   # LabelValue is a <dl> now
grep -rn "with_tab(" app/ | grep "href:"                        # mixing href and panels raises
grep -rn "BooleanIcon" app/                                     # value: nil no longer means false
# do you render the BlockEditor, and are all @blocknote/* on the same >= 0.52.1?
grep -rn "BlockEditor::Component\|block_editor_group" app/
node -e 'const d=require("./package.json").dependencies||{};for(const k of Object.keys(d))if(k.startsWith("@blocknote/"))console.log(k,d[k])'
# events — these break with no error at all, see the table above
grep -rn "openModal\|openDrawer\|modal:success" app/
grep -rn "hovercard:\|sortable-list:\|interact:on\|direct-upload:" app/
grep -rn "useDispatch\|use-dispatch\|baliDispatchDebugEnabled" app/ config/
# sidebar: the checkboxes are gone, and so are their labels and CSS hooks
grep -rn "MOBILE_TRIGGER_ID\|mobile_trigger_id\|trigger_id:" app/
grep -rn "side-menu-mobile-trigger\|side-menu-collapse-trigger" app/
grep -rn "toggleSideMenu" app/
grep -rn "fixed_sidebar" app/views app/components   # must agree with SideMenu(fixed:)
grep -rn "#main-content\|skip.to.main" app/          # AppLayout renders its own skip link
# checkboxes and toggles: label: now means the legend, text: means the inline caption
grep -rn "boolean_field\|check_box_group\|switch_field" app/ | grep "label:"
# currency/percentage: step never did anything, and the pattern follows the locale now
grep -rn "currency_field_group\|percentage_field_group" app/ | grep "step:"
grep -rn "NumericAttributesWithCommas\|gsub(\",\"" app/models/   # drop your own comma setter
# dynamic_fields: these are <button> now
grep -rn "link_to_add_fields\|link_to_remove_fields" app/ test/
grep -rn "placehold.jp" app/ test/                   # ImageField's placeholder is a data URI
```

Then walk the sidebar with the keyboard at a phone width: Tab to the hamburger, Enter,
Tab through the items, Escape — focus has to come back to the hamburger.

Then load each index page in a browser and check, in this order: the toolbar is not inside
a card, filtering over Turbo Streams still replaces the listing, selecting a row swaps the
toolbar for the contextual bar, and the column selector still hides the column you named.
