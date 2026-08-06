# Bali::BlockEditor::Component

A rich text editor powered by [BlockNote](https://www.blocknotejs.org/) and React, integrated into Rails via a Stimulus controller. Provides a modern block-based editing experience with support for rich text, code blocks, tables, multi-column layouts, file uploads, @mentions, #entity references, inline comments, AI assistance, and PDF/DOCX export.

Content can be stored as BlockNote JSON, HTML or **Markdown**, and the UI comes in two sizes -- a full block editor or a cut-down `:simple` preset for description fields. For forms, `Bali::FormBuilder` wraps both behind [`f.rich_text_group` / `f.block_editor_group`](#formbuilder-helpers).

## Installation

Everything in this section is **free software** (MPL-2.0 or MIT) and needs no commercial licence. The paid BlockNote XL packages are deliberately *not* part of it -- see [BlockNote XL packages](#blocknote-xl-packages-paid-opt-in).

### Step 1 -- npm packages

```bash
yarn add @blocknote/core @blocknote/react @blocknote/mantine \
         @mantine/core @mantine/hooks \
         react react-dom
```

The three `@mantine/*` entries are easy to miss: `@blocknote/mantine` needs `@mantine/core` and `@mantine/hooks` and does not bring them along.

Code blocks are syntax-highlighted by default, which needs one more package:

```bash
yarn add shiki
```

You can skip `shiki` if you render the component with `syntax_highlighting: false` (see [Syntax highlighting](#syntax-highlighting)). Leaving highlighting on *without* `shiki` installed still builds, but code blocks fail at runtime and the console shows `` BlockEditor: syntax highlighting is on but `shiki` could not be loaded ``.

All of these are declared as **optional** peer dependencies of `bali-view-components`, so your package manager will neither install them for you nor warn when they are missing. Minimum versions come from `package.json`: `@blocknote/*` `>= 0.52.1`, `@mantine/*` `>= 8.3.0`, `react` / `react-dom` `>= 18.0.0`.

**Keep every `@blocknote/*` package on the same version.** Mixing, say, `@blocknote/core` 0.52.1 with `@blocknote/react` 0.51.0 is not a build error -- the packages share types and internal ProseMirror plugin keys across the boundary, so a mismatch surfaces as a menu that never opens or content that silently fails to serialise. Upgrade them as a set.

> **Node >= 22 is required to install this.** `@blocknote/core` 0.52 depends on `lib0` `1.0.0-rc.22`, which declares `engines.node: ">=22"`. On Node 20, `yarn install` stops with `error lib0@1.0.0-rc.22: The engine "node" is incompatible with this module` and `Found incompatible module` -- an install-time failure, not a runtime one, so you will see it immediately rather than in production. This repository's own CI moved from Node 20 to 22 for exactly this reason. `lib0` is the only package in the tree that asks for 22.

### Step 2 -- esbuild flags

Bali's assets are bundled with esbuild. Two settings are required; both were found by building a real application, and each fails as a hard build error rather than a warning:

```javascript
// esbuild.config.mjs
const config = {
  entryPoints: ['app/javascript/application.js'],
  bundle: true,
  format: 'esm',
  jsx: 'automatic',
  outdir: 'app/assets/builds',

  // The BlockNote/Mantine packages expose their stylesheets through the
  // "style" export condition (e.g. the `@blocknote/mantine/style.css` that
  // BlockNoteEditorWrapper.jsx imports). Without this, those subpaths do
  // not resolve and the build fails.
  conditions: ['style'],

  loader: {
    // Without these, the build stops with a batch of "No loader is configured
    // for '.woff2' files" errors (18 in the app this was measured on) coming
    // from the fonts BlockNote and Mantine ship with their CSS.
    //
    // Use `dataurl`, NOT `file`: with Propshaft, esbuild's content hash in the
    // emitted filename is mistaken for Propshaft's own digest, stripped, and
    // the font 404s.
    '.woff': 'dataurl',
    '.woff2': 'dataurl',
    '.ttf': 'dataurl',
    '.eot': 'dataurl'
  }
}
```

The same thing on the CLI:

```bash
esbuild app/javascript/application.js --bundle --format=esm --jsx=automatic \
  --conditions=style \
  --loader:.woff=dataurl --loader:.woff2=dataurl \
  --loader:.ttf=dataurl --loader:.eot=dataurl \
  --outdir=app/assets/builds
```

> **Link the CSS, or the editor looks broken and nothing fails.** The editor's stylesheets are imported from JavaScript, so esbuild emits them as a **separate file** next to the bundle -- an `application.js` entry point produces `app/assets/builds/application.css`. If your layout only has `javascript_include_tag "application"`, add the matching `stylesheet_link_tag "application"`. Otherwise every test still passes, nothing is logged, and the editor simply renders unstyled.

### Step 3 -- Rails configuration

Enable the component in your Bali initializer:

```ruby
# config/initializers/bali.rb
Bali.config do |config|
  config.block_editor_enabled = true
end
```

The component does not render unless `block_editor_enabled` is `true`. When it is `false` the component logs a warning through `Rails.logger.warn` on every render, and in `development` it also renders a visible red dashed notice in place of the editor. In every other environment it renders an empty string -- which is why `assert_response :success` happily passes on a page whose editor never appeared.

### Step 4 -- Create a dedicated entry

The BlockEditor controller is **not** exported from the package root (`bali-view-components`), because pulling it in would drag React and BlockNote into every bundle. Give it its own bundler entry — the whole file is one line:

```javascript
// app/javascript/editor.js
import 'bali-view-components/block-editor-entry'
```

A dedicated entry matters for two reasons: the editor imports CSS from JS (in its own entry esbuild emits it as `editor.css`; inside the main entry it would be appended to your application stylesheet), and the editor weighs several MB that only capture screens need.

The entry registers the controller on the Stimulus application your app exposes as `window.Stimulus` — it deliberately does **not** start a second application, because two applications scanning the same DOM mount every controller twice. If your app does not set `window.Stimulus`, either expose it or use the [manual registration](#alternative----bundle-it-eagerly) below.

### Step 5 -- Load it lazily

Loading the entry from the form view does not work: Bali drawers and modals inject their content with fetch + `innerHTML`, and `<script>` tags inserted through `innerHTML` never execute — the editor stays unmounted with an empty div and no error. Loading it in every layout wastes several MB on pages with no editor.

Two pieces solve this. Import the loader once in your MAIN bundle (it weighs nothing):

```javascript
// app/javascript/application.js
import 'bali-view-components/block-editor-loader'
```

And publish the digested asset paths in your layout's `<head>` (the helper is exposed to host views by the engine):

```erb
<%= block_editor_meta_tags %>
```

The loader watches the DOM and injects the editor's `<link>` and `<script>` the first time a `block-editor` controller appears — full page, Turbo navigation or drawer alike. `block_editor_meta_tags` defaults to assets named `editor.js` / `editor.css`; pass `js:`/`css:` to override, or `css: nil` if your entry emits no stylesheet.

### Alternative -- bundle it eagerly

If your app uses the editor on most pages (or you prefer no indirection), skip Step 5 and register the controller straight into your main bundle:

```javascript
import { registerBlockEditor } from 'bali-view-components/block-editor'

registerBlockEditor(application)
```

This is the setup the lazy path replaces: everything travels in `application.js`, on every page.

---

## BlockNote XL packages (paid, opt-in)

> **This section is pending review by legal and is not legal advice.** What follows separates two
> different kinds of statement, and you should treat them differently. The "Licence facts" block
> below is *measured* -- every line in it was read out of the installed package metadata and the
> repository, and can be re-checked with the commands given. Everything after it summarises what
> the BlockNote project publishes about its own commercial terms; it is a convenience restatement
> of an upstream marketing page, it is not verified, and whether any of it makes a given
> deployment compliant is a question for the legal team, not for this document. Do not treat this
> page as a clearance to ship the XL packages.

Four optional features are built on **BlockNote XL** packages, licensed `GPL-3.0 OR PROPRIETARY`.

### Licence facts as of `@blocknote/*` 0.52.1

Measured on the versions this repository installs. Re-check with
`npm view @blocknote/<pkg>@<version> license`, and for what ships in the published gem/npm
package, the `files` array in the repository root `package.json`.

| Package | `license` field at 0.52.1 | `license` field at 0.46.2 | Reached from |
|---|---|---|---|
| `@blocknote/core` | `MPL-2.0` | `MPL-2.0` | static import, always |
| `@blocknote/react` | `MPL-2.0` | `MPL-2.0` | static import, always |
| `@blocknote/mantine` | `MPL-2.0` | `MPL-2.0` | static import, always |
| `@blocknote/xl-ai` | `GPL-3.0 OR PROPRIETARY` | `GPL-3.0 OR PROPRIETARY` | `import()` in `index.js`, only when `ai_url:` is set |
| `@blocknote/xl-multi-column` | `GPL-3.0 OR PROPRIETARY` | `GPL-3.0 OR PROPRIETARY` | `import()` in `index.js`, only when `multi_column: true` |
| `@blocknote/xl-pdf-exporter` | `GPL-3.0 OR PROPRIETARY` | `GPL-3.0 OR PROPRIETARY` | `import()` in `exportPdf()`, only when the user clicks Export PDF |
| `@blocknote/xl-docx-exporter` | `GPL-3.0 OR PROPRIETARY` | `GPL-3.0 OR PROPRIETARY` | `import()` in `exportDocx()`, only when the user clicks Export DOCX |

Their non-BlockNote companions are permissively licensed: `ai` is `Apache-2.0`, `docx` is `MIT`,
`@react-pdf/renderer` is `MIT`, `@mantine/core` and `@mantine/hooks` are `MIT`, `shiki` is `MIT`.

Four further facts, each checkable:

1. **The 0.52 upgrade changes no licence.** All seven `@blocknote/*` packages declare exactly the
   same `license` string at 0.52.1 as they did at 0.46.2. The upgrade moves versions, not terms.
2. **No XL code is distributed by this project.** The four XL packages appear in
   `bali-view-components` only as module specifier strings inside dynamic `import()` calls. They
   are absent from `dependencies` and from `peerDependencies`, they are not vendored, and the
   `files` array of the published npm package (`app/**/*`, `lib/bali/**/*.rb`, `MIT-LICENSE`,
   `README.md`) contains no XL code. Installing `bali-view-components` installs no XL package.
   `bali-view-components` itself is `MIT`.
3. **They are installed in `spec/dummy`.** The demo/test application lists all four in its
   `package.json` so the features can be exercised. `spec/dummy` is not published to npm and is
   not part of the gem.
4. **Reaching for them is a deliberate act by the host application.** A host must both install
   the package and turn the feature on. Neither happens by default, and an app that does neither
   builds and runs with no XL package present.

**What is NOT settled here:** whether AFAL's own use of any XL package -- in `spec/dummy`, in a
host application, or in CI -- is covered by GPL-3.0 or requires a commercial licence, and what
the terms of such a licence are. That determination belongs to legal and must be made before GA.

| Package | Feature | Enabled by | License |
|---------|---------|-----------|---------|
| `@blocknote/core`, `@blocknote/react`, `@blocknote/mantine` | Core editor | always | **MPL-2.0** -- free for any project, including closed-source |
| `@blocknote/xl-multi-column` | Multi-column layouts | `multi_column: true` | **GPL-3.0 or commercial** |
| `@blocknote/xl-pdf-exporter` + `@react-pdf/renderer` | PDF export | `export: true` / `export: [:pdf]` | **GPL-3.0 or commercial** |
| `@blocknote/xl-docx-exporter` + `docx` | DOCX export | `export: true` / `export: [:docx]` | **GPL-3.0 or commercial** |
| `@blocknote/xl-ai` + `ai` | AI assistance | `ai_url: '...'` | **GPL-3.0 or commercial** |

**These packages are not declared as peer dependencies of `bali-view-components`, on purpose.** Listing them as peers led people to install them reflexively -- and installing them is the act that puts a closed-source app on the hook for the licence. Install them explicitly, only after deciding you are entitled to:

```bash
# Multi-column layouts
yarn add @blocknote/xl-multi-column

# PDF export
yarn add @blocknote/xl-pdf-exporter @react-pdf/renderer

# DOCX export
yarn add @blocknote/xl-docx-exporter docx

# AI assistance
yarn add @blocknote/xl-ai ai
```

**What BlockNote publishes about these terms** (unverified restatement -- read the source before relying on any of it, and see the review notice at the top of this section):

- **Open-source projects (GPL-3.0 compatible):** described as free to use under GPL-3.0.
- **Closed-source / proprietary applications:** described as requiring a [BlockNote Business subscription](https://www.blocknotejs.org/pricing) for a commercial licence to use any XL package. Pricing, seat counts and the scope of a licence are stated on that page; they have changed before and are deliberately not copied here.
- Startup and non-profit discounts are mentioned on the same page.

Whether any of that applies to a particular deployment is a legal determination, not an engineering one.

### How "optional" actually works at build time

Every XL import in this component is a dynamic `import()` inside a `try`, **awaited one per line**. That shape is load-bearing, not style:

```javascript
// index.js
try {
  const xlAi = await import('@blocknote/xl-ai')
  await import('@blocknote/xl-ai/style.css')
  const aiLocales = await import('@blocknote/xl-ai/locales')
  const aiSdk = await import('ai')
  // ...
} catch (error) { /* feature stays off */ }
```

esbuild only treats a dynamic import as optional when it can attribute the failure to a surrounding `try`, and it cannot do that for an import nested in a `Promise.all` argument list. While these imports were grouped in a `Promise.all`, an application that installed only the free core **did not compile at all** -- 27 esbuild resolution errors for packages it had deliberately not bought. That is fixed; keep the one-await-per-line shape if you touch this code.

What this does and does not buy you:

- An app that never installs the XL packages **builds and runs**. Turning the corresponding feature on at render time logs a console error and the feature stays off.
- An app that *does* install them gets them in the bundle as separate chunks, loaded on demand: the multi-column chunk when `multi_column: true`, the AI chunk when `ai_url` is set, the exporter chunks when the user clicks an export button. The base editor bundle stays free of them.

---

## Basic Usage

### Minimal Editor

```erb
<%= render Bali::BlockEditor::Component.new(
  editable: true,
  placeholder: 'Start typing...'
) %>
```

### Read-Only Display

```erb
<%= render Bali::BlockEditor::Component.new(
  initial_content: @document.content,
  editable: false
) %>
```

### Inside a Form

When `input_name` is provided, the editor syncs its content to a hidden input field. Use `format:` to control the serialization format.

```erb
<%= form_with model: @post do |f| %>
  <%= render Bali::BlockEditor::Component.new(
    initial_content: @post.content,
    input_name: 'post[content]',
    format: :json,
    placeholder: 'Write your post...'
  ) %>

  <%= f.submit 'Save' %>
<% end %>
```

**Format options:**
- `:json` (default) -- Serializes as BlockNote JSON. Lossless round-trip. Recommended when the content never leaves the editor.
- `:html` -- Serializes as HTML via `blocksToHTMLLossy`. Lossy (some block-level metadata may be lost).
- `:markdown` -- Serializes as Markdown via `blocksToMarkdownLossy`. Lossy, but keeps the column readable by everything else in the app: search, plain-text exports, APIs, LLM prompts.

Each format has a matching input prop, so the stored value is *parsed* rather than shown as raw source:

| `format:` | Load the stored value with | Parsed by |
|-----------|---------------------------|-----------|
| `:json` | `initial_content:` | `JSON.parse` (or `setContent` for ProseMirror JSON) |
| `:html` | `html_content:` | `editor.tryParseHTMLToBlocks` |
| `:markdown` | `markdown_content:` | `editor.tryParseMarkdownToBlocks` |

Before the editor mounts, the hidden input already carries the **original** content for the configured format. A form submitted without ever touching the editor round-trips the stored value instead of blanking the column.

### Loading HTML Content

If you have existing HTML content (e.g., from a legacy Trix editor), use `html_content:` instead of `initial_content:`. The editor parses the HTML into blocks on mount.

```erb
<%= render Bali::BlockEditor::Component.new(
  html_content: @post.body_html,
  input_name: 'post[content]',
  format: :json
) %>
```

### Storing Markdown

Use `format: :markdown` with `markdown_content:` to keep a plain `text` column that stays legible outside the editor.

```erb
<%= render Bali::BlockEditor::Component.new(
  markdown_content: @post.body,
  input_name: 'post[body]',
  format: :markdown
) %>
```

Markdown is a lossy target by construction (BlockNote names the serializer `blocksToMarkdownLossy`): anything Markdown cannot express -- including this component's custom inline content, `@mentions` and `#entity references` -- is not guaranteed to survive a round-trip. Use `:json` when fidelity matters more than legibility.

---

## Presets

`preset:` chooses how much editing UI is exposed.

| `preset:` | Formatting toolbar | Side menu (drag handle / `+`) | Slash menu (`/`) | File panel |
|-----------|-------------------|-------------------------------|------------------|------------|
| `:full` (default) | complete | yes | yes | yes |
| `:simple` | block type select, bold, italic, strikethrough, inline code, link | no | no | no |

```erb
<%= render Bali::BlockEditor::Component.new(
  markdown_content: @task.description,
  input_name: 'task[description]',
  format: :markdown,
  preset: :simple
) %>
```

`@mentions` and `#entity references` still work under `:simple` when their respective options are configured -- the preset only removes the three menus listed above.

> **The simple preset restricts the UI, never the schema.** Tables, images, columns and every other block spec stay registered even though nothing in the simple UI can insert them. This is deliberate: if the schema could not represent a construct already present in stored content, merely opening a record and saving it would silently destroy that part of the document.

---

## Syntax highlighting

Code blocks are highlighted with [Shiki](https://shiki.style/) by default (`syntax_highlighting: true`). Turning it off swaps in BlockNote's plain code block and never loads `shiki`:

```erb
<%= render Bali::BlockEditor::Component.new(syntax_highlighting: false) %>
```

**This is the single biggest lever on bundle size.** `shiki` pulls in the whole grammar set, and the grammars dwarf the highlighter itself. In one application, turning highlighting off took the built bundle from **14.3 MB to 3.6 MB**.

Highlighting on is worth it for documentation-style content; for a description field or a comment box it rarely is. `shiki` is only needed when highlighting is on -- see [Step 1](#step-1----npm-packages).

---

## FormBuilder helpers

`Bali::FormBuilder` exposes the editor the way Rails exposes `rich_text_area`: bind a plain text column and get an editor, with no wiring at the call site.

```erb
<%= form_with model: @task, builder: Bali::FormBuilder do |f| %>
  <%= f.rich_text_group :description %>
  <%= f.block_editor_group :body, preset: :full, format: :json %>
<% end %>
```

| Helper | Preset | Default format | Use for |
|--------|--------|----------------|---------|
| `f.rich_text_group` / `f.rich_text` | `:simple` | `:markdown` | Description and note fields: bold/italic/lists over a plain text column |
| `f.block_editor_group` / `f.block_editor` | `:full` | `:markdown` | Full block editing; pass `format: :json` for BlockNote's native document JSON |

The `*_group` variants wrap the field in `Bali::FieldGroupWrapper` (label, hint, errors); the bare variants render just the editor. Both derive `input_name` from the attribute and read the current value from the model through the prop matching `format:`, so no `markdown_content:` / `html_content:` / `initial_content:` is needed at the call site. Any other option is forwarded to `Bali::BlockEditor::Component`.

> **Not to be confused with `f.rich_text_area_group`.** That one is the ActionText/Trix helper and has nothing to do with this component -- different editor, different storage, different dependencies. The name similarity is unfortunate; check which one you are calling.

---

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `initial_content` | `String`, `Hash`, `Array` | `nil` | BlockNote JSON (or ProseMirror JSON) content to load |
| `html_content` | `String` | `nil` | HTML string to parse into blocks on mount |
| `markdown_content` | `String` | `nil` | Markdown string to parse into blocks on mount |
| `input_name` | `String` | `nil` | Hidden input `name` attribute for form submission |
| `format` | `Symbol` | `:json` | Serialization format: `:json`, `:html` or `:markdown` |
| `preset` | `Symbol` | `:full` | UI preset: `:full` or `:simple` (see [Presets](#presets)) |
| `syntax_highlighting` | `Boolean` | `true` | Highlight code blocks with Shiki. `false` never loads `shiki` |
| `editable` | `Boolean` | `true` | Whether the editor is editable |
| `placeholder` | `String` | `nil` | Placeholder text shown when editor is empty |
| `upload_url` | `String`, `:auto` | `:auto` | Upload endpoint URL. `:auto` resolves from engine routes |
| `theme` | `Symbol` | `:light` | Editor theme: `:light` or `:dark` |
| `export` | `Boolean`, `Array` | `false` | Enable export. `true` for both, or `[:pdf]`, `[:docx]`, `[:pdf, :docx]` |
| `export_filename` | `String` | `'document'` | Base filename for exported files (without extension) |
| `show_export_buttons` | `Boolean` | `true` | Render the built-in export buttons. `false` keeps export enabled but hides them, for callers driving `block-editor#exportPdf` / `#exportDocx` from their own UI |
| `ai_url` | `String` | `nil` | AI chat endpoint URL. Enables AI features when set |
| `mentions_url` | `String` | `nil` | Remote mentions search endpoint URL |
| `mentions` | `Array` | `nil` | Static list of mentionable users |
| `references_url` | `String` | `nil` | Entity reference search endpoint URL |
| `references_resolve_url` | `String` | `nil` | Batch entity reference resolution endpoint URL |
| `references_config` | `Hash` | `nil` | Custom entity type display configuration |
| `multi_column` | `Boolean` | `false` | Enable multi-column layouts (requires `@blocknote/xl-multi-column`) |
| `table_of_contents` | `Boolean` | `false` | Enable table of contents sidebar |
| `table_of_contents_container_id` | `String` | `nil` | DOM id to portal the table of contents into, instead of rendering it beside the editor |
| `comments` | `Hash` | `nil` | Inline comments configuration -- see [Comments](#comments). Comments are on when a Hash is given |
| `comments_container_id` | `String` | `nil` | DOM id to portal the threads sidebar into, instead of rendering it beside the editor |
| `**options` | `Hash` | `{}` | Additional HTML attributes passed to the wrapper div |

---

## Built-in Features (No Integration Required)

These features work out of the box with zero configuration:

- **Rich text** -- Bold, italic, underline, strikethrough, inline code
- **Headings** -- Levels 1-3
- **Lists** -- Bullet, numbered, checklist, toggle
- **Blockquotes**
- **Tables** -- Resizable with header rows
- **Code blocks** -- Syntax highlighting via Shiki for 22 languages (opt out with `syntax_highlighting: false`)
- **Dividers**
- **Slash menu** -- Type `/` to access all block types (`preset: :full` only)
- **Inline comments** -- MPL-2.0, no XL package required (see [Comments](#comments))

### Opt-in Features (XL Packages)

These features require explicit opt-in **and installing the corresponding paid-licence packages yourself** -- they are not peer dependencies (see [BlockNote XL packages](#blocknote-xl-packages-paid-opt-in)):

- **Multi-column layouts** -- 2 and 3 column layouts via slash menu (`multi_column: true`)
- **PDF/DOCX export** -- Export editor content to PDF or DOCX files (`export: true`)
- **AI assistance** -- AI-powered text generation and editing (`ai_url: '...'`)

If an XL package is not installed, the build still succeeds and the feature simply does not activate: the loader logs a console error and moves on. If it *is* installed, it lands in a separate chunk that is only fetched when the feature is used, so the base editor bundle stays free of it. See [How "optional" actually works at build time](#how-optional-actually-works-at-build-time) for why the code is written the way it is.

### Supported Code Languages

JavaScript, TypeScript, Python, Ruby, HTML, CSS, JSON, Bash, SQL, YAML, Markdown, XML, Java, Go, Rust, PHP, C, C++, C#, Swift, Kotlin, Plain Text.

---

## File Uploads

File uploads allow users to drag-and-drop or paste images, videos, audio, and other files into the editor.

### Option A: Engine Routes (Recommended)

Mount the Bali engine in your routes and the upload URL auto-resolves:

```ruby
# config/routes.rb
mount Bali::Engine => '/bali'
```

The engine provides `POST /bali/block_editor/uploads` which:
- Validates file type via MIME type detection (not just extension)
- Validates file size -- the effective default is **50 MB** (`Bali::BlockEditorUploadsController::MAX_FILE_SIZE`), used whenever `block_editor_max_upload_size` is left unset
- Blocks dangerous extensions (`.exe`, `.bat`, `.sh`, etc.)
- Creates an Active Storage unattached blob and returns `{ url: "..." }`

Configure authorization and limits:

```ruby
# config/initializers/bali.rb
Bali.config do |config|
  config.block_editor_enabled = true

  # Authorization - receives the controller instance
  config.block_editor_upload_authorize = ->(controller) {
    controller.current_user.present?
  }

  # Custom upload handler (optional, defaults to Active Storage)
  config.block_editor_upload_handler = ->(file, controller) {
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type
    )
    Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
  }

  # Customize allowed types and size
  config.block_editor_allowed_upload_types = ['image/jpeg', 'image/png', 'image/webp']
  config.block_editor_max_upload_size = 5.megabytes
end
```

### Option B: Custom Upload Endpoint

Point to your own endpoint:

```erb
<%= render Bali::BlockEditor::Component.new(
  upload_url: '/api/uploads'
) %>
```

Or set it globally:

```ruby
Bali.config do |config|
  config.block_editor_upload_url = '/api/uploads'
end
```

**Your endpoint must:**
1. Accept `POST` with `multipart/form-data` containing a `file` field
2. Validate the CSRF token (`X-CSRF-Token` header)
3. Return JSON: `{ "url": "/path/to/uploaded/file" }`
4. Return a non-2xx status on failure

### Disabling Uploads

```erb
<%= render Bali::BlockEditor::Component.new(
  upload_url: nil
) %>
```

---

## @Mentions

Mentions let users type `@` to reference people. The suggestion menu appears with matching results.

### Static Mentions

Pass a list of users directly. Best for small, fixed lists.

```erb
<%= render Bali::BlockEditor::Component.new(
  mentions: [
    { id: 1, name: 'Alice Johnson' },
    { id: 2, name: 'Bob Smith' },
    { id: 3, name: 'Carlos Rivera' }
  ]
) %>
```

You can also pass simple strings:

```erb
<%= render Bali::BlockEditor::Component.new(
  mentions: ['Alice', 'Bob', 'Carlos']
) %>
```

### Remote Mentions

For larger user bases, point to a search endpoint:

```erb
<%= render Bali::BlockEditor::Component.new(
  mentions_url: '/api/users/search'
) %>
```

**Your endpoint must:**
1. Accept `GET` with a `?q=` query parameter
2. Return JSON: `[{ "id": 1, "name": "Alice Johnson" }, ...]`
3. Set `Accept: application/json` in the response

**Example Rails controller:**

```ruby
# app/controllers/api/users_controller.rb
class Api::UsersController < ApplicationController
  def search
    users = User.where('name ILIKE ?', "%#{params[:q]}%").limit(10)
    render json: users.map { |u| { id: u.id, name: u.name } }
  end
end
```

### Mention Data in Content

Mentions are stored in BlockNote JSON as inline content:

```json
{
  "type": "mention",
  "props": { "user": "Alice Johnson", "id": "1" }
}
```

---

## #Entity References

Entity references let users type `#` to reference domain objects like tasks, projects, or documents. Results are grouped by type with color-coded indicators.

### Setup

Entity references require two endpoints. **The engine ships both** — declare your
referenceable types once in `Bali.entity_reference_types` and point the editor at
`bali.entity_references_path` / `bali.resolve_entity_references_path`. That registry also
feeds `references_config`, so the chips get their icon, label and color without a second
declaration. See the entity references section of `docs/guides/engines.md`.

The rest of this section documents the wire contract, which is what you implement yourself
if you don't mount the engine:

```erb
<%= render Bali::BlockEditor::Component.new(
  references_url: '/api/entity_references',
  references_resolve_url: '/api/entity_references/resolve'
) %>
```

### Search Endpoint (`references_url`)

Called when the user types `#` followed by a query.

**Request:** `GET /api/entity_references?q=login`

**Response:**

```json
[
  { "entityType": "task", "entityId": "42", "entityName": "Fix login bug" },
  { "entityType": "project", "entityId": "7", "entityName": "Q4 Release" },
  { "entityType": "document", "entityId": "15", "entityName": "Login Flow Spec" }
]
```

**Example Rails controller:**

```ruby
# app/controllers/api/entity_references_controller.rb
class Api::EntityReferencesController < ApplicationController
  def index
    q = params[:q].to_s.downcase
    results = []

    results += Task.where('name ILIKE ?', "%#{q}%").limit(5).map do |t|
      { entityType: 'task', entityId: t.id, entityName: t.name }
    end

    results += Project.where('name ILIKE ?', "%#{q}%").limit(5).map do |p|
      { entityType: 'project', entityId: p.id, entityName: p.name }
    end

    render json: results
  end
end
```

### Resolve Endpoint (`references_resolve_url`)

Called once on editor load to resolve display names for entity references stored in the document. This allows names to stay up-to-date even if the referenced entity was renamed.

**Request:** `POST /api/entity_references/resolve`

```json
{
  "refs": [
    { "entityType": "task", "entityId": "42" },
    { "entityType": "project", "entityId": "7" }
  ]
}
```

**Response:**

```json
[
  { "entityType": "task", "entityId": "42", "entityName": "Fix login bug", "url": "/tasks/42" },
  { "entityType": "project", "entityId": "7", "entityName": "Q4 Release", "url": "/projects/7" }
]
```

When a `url` is returned, the entity reference chip becomes a clickable link.

**Example Rails controller:**

```ruby
def resolve
  refs = params[:refs] || []
  resolved = refs.filter_map do |ref|
    record = find_entity(ref[:entityType], ref[:entityId])
    next unless record

    {
      entityType: ref[:entityType],
      entityId: ref[:entityId],
      entityName: record.name,
      url: polymorphic_path(record)
    }
  end

  render json: resolved
end

private

def find_entity(type, id)
  case type
  when 'task' then Task.find_by(id: id)
  when 'project' then Project.find_by(id: id)
  when 'document' then Document.find_by(id: id)
  end
end
```

### Custom Entity Type Configuration

Override the default icons, labels, and colors per entity type:

```erb
<%= render Bali::BlockEditor::Component.new(
  references_url: '/api/entity_references',
  references_resolve_url: '/api/entity_references/resolve',
  references_config: {
    task:     { icon: "\u2610", label: 'Task',     color: 'info' },
    project:  { icon: "\u25C8", label: 'Project',  color: 'accent' },
    document: { icon: "\u25E7", label: 'Document', color: 'success' },
    invoice:  { icon: '$',      label: 'Invoice',  color: 'warning' }
  }
) %>
```

**Config options per type:**

| Key | Type | Description |
|-----|------|-------------|
| `icon` | `String` | Unicode character or emoji displayed in the chip |
| `label` | `String` | Type label for grouping in the suggestion menu |
| `color` | `String` | DaisyUI semantic color name (`info`, `accent`, `success`, `warning`, `error`, `secondary`, `primary`) or a CSS color value (`#ff0000`, `rgb(...)`, `var(--my-color)`) |

**Default configuration:**

| Type | Icon | Label | Color |
|------|------|-------|-------|
| `task` | &#x2610; | Task | `info` |
| `project` | &#x25C8; | Project | `accent` |
| `document` | &#x25E7; | Document | `success` |
| `default` | # | (none) | `secondary` |

### Entity Reference Data in Content

Entity references are stored in BlockNote JSON as inline content:

```json
{
  "type": "entityReference",
  "props": {
    "entityType": "task",
    "entityId": "42",
    "entityName": "Fix login bug",
    "url": "/tasks/42"
  }
}
```

---

## Comments

Inline commenting allows users to select text and attach comment threads, similar to Google Docs. Comments use BlockNote's built-in comments extension (free, MPL 2.0 license -- no XL package required).

### Basic Setup

Comments are configured through a single `comments:` **Hash**:

```erb
<%= render Bali::BlockEditor::Component.new(
  comments: {
    user: { id: current_user.id, username: current_user.name, avatar_url: current_user.avatar_url }
  }
) %>
```

| Key | Type | Description |
|-----|------|-------------|
| `user` | `Hash` | Current user authoring comments: `{ id:, username:, avatar_url: }`. `id` and `username` are required, `avatar_url` optional |
| `users` | `Array` | Static user list for resolution: `[{ id:, username:, avatar_url: }, ...]` |
| `users_url` | `String` | Remote endpoint for user resolution |
| `url` | `String` or `:auto` | REST API base URL for persistent thread storage (in-memory when omitted). `:auto` points at the engine's own endpoints and requires `commentable:` |
| `commentable` | Active Record | The host record the threads belong to. Only read when `url: :auto` |

> **Comments are on only when `comments:` is a non-empty Hash.** `comments: true` and `comments: {}` both leave them off, silently -- a truthy non-Hash is not a configuration. There is no separate `comments_user:` / `comments_url:` / `comments_users:` / `comments_users_url:` argument: passing those at the top level does not configure anything, they fall through to `**options` and end up as HTML attributes on the wrapper `div`.

### User Resolution

When displaying comments, the editor needs to resolve user IDs into display names and avatars. Two approaches are available:

#### Static User List

Pass a list of users directly. Best for small teams or preview contexts.

```erb
<%= render Bali::BlockEditor::Component.new(
  comments: {
    user: { id: '1', username: 'Alice', avatar_url: '' },
    users: [
      { id: '1', username: 'Alice', avatar_url: '/avatars/alice.jpg' },
      { id: '2', username: 'Bob', avatar_url: '/avatars/bob.jpg' },
      { id: '3', username: 'Carlos', avatar_url: '/avatars/carlos.jpg' }
    ]
  }
) %>
```

#### Remote User Resolution

For larger user bases, point to an endpoint that resolves user IDs:

```erb
<%= render Bali::BlockEditor::Component.new(
  comments: {
    user: { id: current_user.id, username: current_user.name, avatar_url: current_user.avatar_url },
    users_url: '/api/users/resolve'
  }
) %>
```

**Your endpoint must:**
1. Accept `GET` with `?ids[]=1&ids[]=2` query parameters
2. Return JSON: `[{ "id": "1", "username": "Alice", "avatarUrl": "/avatars/alice.jpg" }, ...]`

**Example Rails controller:**

```ruby
class Api::UsersController < ApplicationController
  def resolve
    users = User.where(id: params[:ids])
    render json: users.map { |u|
      { id: u.id.to_s, username: u.name, avatarUrl: url_for(u.avatar) }
    }
  end
end
```

### How Comments Work

1. **Creating a comment**: Select text in the editor and click the comment button in the formatting toolbar. A floating composer appears to write the initial comment.
2. **Viewing threads**: Click on highlighted (commented) text to see the thread in a floating popover. The threads sidebar on the right shows all comment threads.
3. **Replying**: Click a thread to expand it and add replies.
4. **Resolving**: Mark threads as resolved when the discussion is complete. Resolved threads are dimmed in the sidebar.
5. **Reactions**: Add emoji reactions to individual comments.

### Storage

#### In-Memory (Default)

When `comments[:url]` is not provided, comments are stored **in-memory** -- they exist only for the duration of the editor session and are lost on page reload. This is suitable for previews, demos, and single-session review workflows.

#### The engine's own storage (`url: :auto`)

Since v3.1 the engine ships the storage itself -- three tables, three controllers and the
nine endpoints below. Point the editor at them with `:auto` plus the record the threads
belong to:

```erb
<%= render Bali::BlockEditor::Component.new(
  comments: {
    url: :auto,
    commentable: @document,
    user: { id: current_user.id.to_s, username: current_user.name },
    users_url: users_path
  }
) %>
```

It resolves to `bali.block_editor_threads_path(commentable_type:, commentable_id:)` for that
record; `RESTThreadStore` keeps the query string on all nine sub-requests, so the scope
travels for free. Passing `:auto` without a `commentable:` raises -- there is no unscoped
thread list.

Installing the migration and configuring who may comment on what
(`Bali.block_editor_commentables`, `Bali.block_editor_comments_user`,
`Bali.block_editor_comments_authorize`) is covered in
[docs/guides/engines.md](../guides/engines.md), together with the permission matrix and the
migration path for apps that already had their own tables.

#### REST Persistence (your own endpoints)

Pass `comments[:url]` to persist comments to a database via REST API:

```erb
<%= render Bali::BlockEditor::Component.new(
  comments: {
    url: '/api/comments',
    user: { id: current_user.id, username: current_user.name, avatar_url: current_user.avatar_url }
  }
) %>
```

The `RESTThreadStore` will:
- Load existing threads on mount
- Poll for updates every 5 seconds
- Persist all CRUD operations (create/update/delete threads, comments, and reactions)
- Include CSRF tokens for Rails compatibility

#### REST API Contract

Your server must implement these endpoints (all relative to `comments[:url]`):

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/` | List all threads with nested comments and reactions |
| `POST` | `/` | Create thread with `initial_comment` |
| `PATCH` | `/:threadId` | Update thread (resolve/unresolve) |
| `DELETE` | `/:threadId` | Delete thread |
| `POST` | `/:threadId/comments` | Add comment to thread |
| `PATCH` | `/:threadId/comments/:id` | Update comment body |
| `DELETE` | `/:threadId/comments/:id` | Soft-delete comment |
| `POST` | `/:threadId/comments/:id/reactions` | Add emoji reaction |
| `DELETE` | `/:threadId/comments/:id/reactions` | Remove emoji reaction (emoji in body) |

**Response format** (thread with nested comments):

```json
{
  "id": 1,
  "resolved": false,
  "resolved_by": null,
  "metadata": {},
  "created_at": "2026-01-15T10:30:00Z",
  "updated_at": "2026-01-15T10:30:00Z",
  "comments": [
    {
      "id": 1,
      "user_id": "1",
      "body": { "type": "doc", "content": [...] },
      "metadata": {},
      "created_at": "2026-01-15T10:30:00Z",
      "updated_at": "2026-01-15T10:30:00Z",
      "reactions": [
        { "emoji": "👍", "created_at": "2026-01-15T10:31:00Z", "user_ids": ["1", "2"] }
      ]
    }
  ]
}
```

Both `snake_case` and `camelCase` response keys are accepted.

### Comments Data

Comment thread positions are stored as marks in the ProseMirror document. The thread content (comments, replies, reactions) is managed by the ThreadStore independently of the document content.

---

## PDF and DOCX Export

> **Licensing:** PDF and DOCX export use XL packages (`@blocknote/xl-pdf-exporter`, `@blocknote/xl-docx-exporter`), which are **not** peer dependencies -- you install them yourself. Free for open-source projects under GPL-3.0; closed-source applications require a [BlockNote Business subscription](https://www.blocknotejs.org/pricing). See [BlockNote XL packages](#blocknote-xl-packages-paid-opt-in).

Add export buttons below the editor:

```erb
<%= render Bali::BlockEditor::Component.new(
  export: true,
  export_filename: 'my-document'
) %>
```

**Export options:**

```ruby
export: true           # Both PDF and DOCX buttons
export: [:pdf]         # PDF only
export: [:docx]        # DOCX only
export: [:pdf, :docx]  # Both (same as true)
export: false          # No export buttons (default)
```

Exports include support for:
- All standard block types (headings, lists, tables, code blocks, etc.)
- @mentions (rendered as `@Name`)
- #entity references (rendered as `#Name`)
- Images with relative URL resolution (Active Storage paths work correctly)

### npm Dependencies for Export

```bash
# PDF export
yarn add @blocknote/xl-pdf-exporter @react-pdf/renderer

# DOCX export
yarn add @blocknote/xl-docx-exporter docx
```

They are imported dynamically, inside a `try`, when the user clicks an export button -- not at page load, and never when `export: false` (the default). If they are not installed at all, the build still succeeds and clicking export logs `BlockEditor: PDF export failed` to the console.

---

## AI Assistance

> **Licensing:** AI features use the XL package `@blocknote/xl-ai`, which is **not** a peer dependency -- you install it yourself. Free for open-source projects under GPL-3.0; closed-source applications require a [BlockNote Business subscription](https://www.blocknotejs.org/pricing). See [BlockNote XL packages](#blocknote-xl-packages-paid-opt-in).

AI features add an AI button to the formatting toolbar and an `/ai` slash command. Requires a chat endpoint compatible with the AI SDK.

```erb
<%= render Bali::BlockEditor::Component.new(
  ai_url: 'http://localhost:3456/api/ai/chat'
) %>
```

### npm Dependencies for AI

```bash
yarn add @blocknote/xl-ai ai
```

They are imported dynamically, inside a `try`, only when `ai_url` is configured, so they land in a chunk that editors without AI never fetch. If they are not installed at all, the build still succeeds and setting `ai_url` logs `BlockEditor: Failed to load AI modules` to the console while the editor renders without AI.

### AI Chat Endpoint

The endpoint must implement the [AI SDK](https://sdk.vercel.ai/) streaming chat protocol.

**Example Node.js server:**

```javascript
// server/ai-chat.mjs
import { createServer } from 'http'
import Anthropic from '@anthropic-ai/sdk'

const anthropic = new Anthropic()

createServer(async (req, res) => {
  if (req.method !== 'POST') { res.writeHead(405).end(); return }

  const body = await new Promise(resolve => {
    let data = ''
    req.on('data', chunk => { data += chunk })
    req.on('end', () => resolve(JSON.parse(data)))
  })

  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Access-Control-Allow-Origin': '*'
  })

  const stream = anthropic.messages.stream({
    model: 'claude-sonnet-4-5-20250929',
    max_tokens: 1024,
    messages: body.messages
  })

  for await (const event of stream) {
    res.write(`data: ${JSON.stringify(event)}\n\n`)
  }

  res.end()
}).listen(3456)
```

### AI Capabilities

When enabled, users can:
- Type `/ai` in the slash menu to open the AI prompt
- Select text and click the AI button in the formatting toolbar
- Ask the AI to generate, rewrite, summarize, or translate content

---

## Full-Featured Example

An editor with all capabilities enabled:

```erb
<%= render Bali::BlockEditor::Component.new(
  # Content
  initial_content: @document.content,
  input_name: 'document[content]',
  format: :json,
  placeholder: 'Start writing...',

  # File uploads (auto-resolved from engine routes)
  upload_url: :auto,

  # Mentions
  mentions_url: '/api/users/search',

  # Entity references
  references_url: '/api/entity_references',
  references_resolve_url: '/api/entity_references/resolve',
  references_config: {
    task:     { icon: "\u2610", label: 'Task',     color: 'info' },
    project:  { icon: "\u25C8", label: 'Project',  color: 'accent' },
    document: { icon: "\u25E7", label: 'Document', color: 'success' }
  },

  # Multi-column layouts (XL package)
  multi_column: true,

  # Comments
  comments: {
    user: { id: current_user.id, username: current_user.name, avatar_url: current_user.avatar_url },
    users_url: '/api/users/resolve'
  },

  # Export
  export: true,
  export_filename: 'project-update',

  # AI (optional)
  ai_url: ENV['BLOCK_EDITOR_AI_URL'],

  # Appearance
  theme: :light
) %>
```

---

## Theming

The editor uses [Mantine](https://mantine.dev/) for its UI and respects DaisyUI theme colors via CSS variable overrides. Custom styles are in `app/components/bali/block_editor/index.css`.

```erb
<%# Light theme (default) %>
<%= render Bali::BlockEditor::Component.new(theme: :light) %>

<%# Dark theme %>
<%= render Bali::BlockEditor::Component.new(theme: :dark) %>
```

The stylesheets (`@blocknote/core/fonts/inter.css`, `@blocknote/mantine/style.css` and this component's `index.css`) are imported from `BlockNoteEditorWrapper.jsx`, so esbuild folds them into the CSS file it emits next to your JS bundle at build time. There is no runtime CSS loading and no Vite in this project -- if the bundle's stylesheet is not linked in the layout, the editor renders unstyled (see [Step 2](#step-2----esbuild-flags)).

---

## Architecture

The BlockEditor uses a **custom Stimulus controller** that manages a React component lifecycle:

1. **Turbo opt-out** -- `connect()` appends `<meta name="turbo-cache-control" content="no-cache">` if the page does not already have one. React's internal state (fiber tree, `__reactContainer$` expandos) does not survive Turbo's cache → preview → replace cycle, so the page is excluded from the Turbo cache rather than restored from it. The meta tag is removed again on `disconnect()`.
2. **Mount** -- `connect()` dynamically imports React, ReactDOM and `BlockNoteEditorWrapper`, then creates a React root.
3. **Submit flush** -- the wrapper hands the controller a `flush` callback, bound to the surrounding form's `submit` event (see [Content sync](#content-sync-and-form-submit)).
4. **Disconnect** -- destroys the tiptap/ProseMirror editor *before* unmounting the React root (ProseMirror plugins remove DOM nodes while destroying; if Turbo has already detached the tree, `removeChild` throws), then unmounts.

### Content sync and form submit

When `input_name` is set, the editor keeps a hidden input in sync with its content. Two writers:

- **Debounced** -- 500 ms after the last change (`SYNC_DELAY` in `useContentSync.js`).
- **On submit** -- the controller listens for `submit` on `this.element.closest('form')` (capture phase) and writes immediately, cancelling the pending debounce.

The second one is not an optimisation. With only the debounce, a form submitted inside the 500 ms window posted the **previous** content: the user's last edits vanished with no error and no validation failure. Drawers that submit over `fetch` hit this constantly. Serialisation is synchronous (BlockNote >= 0.51), so the value is in place before the browser reads the form. Measured on 0.52.1: the hidden input is still empty 3 ms after an edit, and holds the new content the moment a `submit` event is dispatched -- both well inside the 500 ms debounce window.

The `submit` event is what triggers the flush, so a form sent through the legacy `form.submit()` DOM call -- which fires no `submit` event -- still races the debounce. Use `form.requestSubmit()`, or let Turbo/Rails submit the form normally.

### Version compatibility

The peer range is `@blocknote/* >= 0.52.1`. **That bound is the version this component was actually exercised on, not the oldest one that might work.** `spec/dummy` pins 0.52.1 and the editor is verified against it by hand -- typing, formatting, lists, tables, file upload, undo and the submit flush -- before the bound is allowed to move. A range wider than what anyone has run is a promise the library cannot keep, which is exactly the state this bound was in before: it claimed `>= 0.51.0` while the dummy app ran 0.46.2, so no version in the declared range was under test.

The lower bound is not cosmetic:

- **0.51** made the parsers and serialisers **synchronous**. They returned promises before. Code that did `tryParseHTMLToBlocks(...).then(...)` throws on 0.51+ because `.then` is not a function on a plain array; this component no longer chains them. The same applies to `tryParseMarkdownToBlocks`, `blocksToMarkdownLossy` and `blocksToHTMLLossy` -- BlockNote's own documentation still describes some of these as async, and is wrong for current versions. The submit flush depends on this directly: it has to write the hidden input *during* the `submit` event, and it cannot await anything there.
- **0.47** has two table-corruption bugs, fixed in **0.52**: a `|` typed inside a table cell drops a column, and a table without a header row promotes its first data row to the header. On 0.52.1 a cell containing `A|B` survives a Markdown round-trip -- `blocksToMarkdownLossy` emits `A\|B` and the table keeps its three columns.

**Applications still on an older BlockNote.** Nothing in the component reaches for a 0.52-only API, so an app on 0.51.x will most likely keep working -- but it is outside the declared range and outside what is tested, and `yarn`/`npm` will emit an unmet-peer warning. Apps below 0.51 are a genuine break, not a warning: the synchronous-serialiser assumption behind the submit flush does not hold there. Upgrade the app before adopting v3, and upgrade all `@blocknote/*` packages together.

### File Structure

```
app/components/bali/block_editor/
  component.rb                  # Ruby ViewComponent class
  component.html.erb            # ERB template (incl. the disabled-in-development notice)
  index.js                      # Stimulus controller + export logic + submit flush
  BlockNoteEditorWrapper.jsx    # React component (main editor)
  inlineContent.jsx             # Mention and EntityReference definitions
  useFileUpload.js              # File upload hook
  useContentSync.js             # Hidden input sync hook (debounced 500ms + flush)
  useMentions.js                # @mentions suggestion hook
  useEntityReferences.jsx       # #entity references suggestion + resolution hook
  useComments.js                # Comments extension setup hook
  TableOfContents.jsx           # Table of contents sidebar
  InMemoryThreadStore.js        # In-memory ThreadStore for comments (no persistence)
  RESTThreadStore.js            # REST-backed ThreadStore for persistent comments
  constants.js                  # Supported languages, max upload size
  index.css                     # DaisyUI overrides for BlockNote/Mantine
  preview.rb                    # Lookbook previews
```

The FormBuilder helpers live outside this directory, in `lib/bali/form_builder/rich_text_fields.rb`.

---

## Lookbook Previews

| Preview | URL | Description |
|---------|-----|-------------|
| Default | `/lookbook/inspect/bali/block_editor/default` | Basic editable editor |
| Readonly | `/lookbook/inspect/bali/block_editor/readonly` | Non-editable display |
| With Initial Content | `/lookbook/inspect/bali/block_editor/with_initial_content` | Pre-loaded content |
| With Form Input | `/lookbook/inspect/bali/block_editor/with_form_input` | Form integration |
| Mentions (Static) | `/lookbook/inspect/bali/block_editor/with_mentions` | Static user list |
| Mentions (Remote) | `/lookbook/inspect/bali/block_editor/with_remote_mentions` | Server search |
| Entity References | `/lookbook/inspect/bali/block_editor/with_entity_references` | #references |
| Table of Contents | `/lookbook/inspect/bali/block_editor/with_table_of_contents` | Headings sidebar |
| Full Featured | `/lookbook/inspect/bali/block_editor/full_featured` | All features enabled |
| With Comments (In-Memory) | `/lookbook/inspect/bali/block_editor/with_comments` | Inline comments (session-only) |
| With Comments (Persistent) | `/lookbook/inspect/bali/block_editor/with_persistent_comments` | Inline comments with REST persistence |
| With AI | `/lookbook/inspect/bali/block_editor/with_ai` | AI assistance |

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| The page renders but there is no editor at all, and no error | `block_editor_enabled` is `false`, so the component renders an empty string. `assert_response :success` still passes | Set `config.block_editor_enabled = true`. In `development` you get a red dashed notice instead of silence; a `Rails.logger.warn` is emitted in every environment |
| The editor renders but looks unstyled / broken | The CSS esbuild emitted next to the JS bundle is not linked | Add `stylesheet_link_tag "application"` alongside `javascript_include_tag "application"` -- see [Step 2](#step-2----esbuild-flags) |
| Build fails with `No loader is configured for ".woff2" files` | Missing font loaders | Add the four `dataurl` loaders -- see [Step 2](#step-2----esbuild-flags) |
| Fonts 404 at runtime with a mangled digest in the path | Font loader set to `file` instead of `dataurl` under Propshaft | Use `dataurl` |
| A `*/style.css` subpath fails to resolve at build time | The `style` export condition is not enabled | Add `conditions: ['style']` |
| Console: `Failed to load editor. Ensure @blocknote/react, @blocknote/mantine, react, and react-dom are installed.` | A core package is missing | Run the [Step 1](#step-1----npm-packages) install, including the three `@mantine/*` |
| Console: `` syntax highlighting is on but `shiki` could not be loaded `` | `shiki` not installed while `syntax_highlighting` is `true` | `yarn add shiki`, or pass `syntax_highlighting: false` |
| Console: `Failed to load AI modules` / `PDF export failed` | The XL packages for that feature are not installed | Install them deliberately -- read [BlockNote XL packages](#blocknote-xl-packages-paid-opt-in) first |
| Content saved is one edit behind | The form was submitted through `form.submit()`, which fires no `submit` event, so the flush never ran | Use `form.requestSubmit()` or a normal Turbo/Rails submit |
| Comments never appear | `comments:` was given something other than a non-empty Hash | See [Comments](#comments) |
| `TypeError: ....then is not a function` while parsing content | BlockNote older than 0.51 (or third-party code chaining `.then` onto a now-synchronous parser) | Upgrade to `>= 0.52.1`, the declared and tested range |
| A menu never opens, or content silently fails to serialise, with no error | `@blocknote/*` packages installed at different versions | Pin them all to the same version -- see [Step 1](#step-1----npm-packages) |
| Console: `Maximum update depth exceeded` while typing, or when closing a drawer/modal that holds the editor -- yet the content saves correctly | A browser extension that rewrites the editor's DOM (Dark Reader, Grammarly, page translators) feeds attribute mutations into ProseMirror's DOM observer, and in BlockNote <= 0.52.1 the node views do not ignore non-content mutations, so the side menus re-render in a loop until React cuts it off ([TypeCellOS/BlockNote#2818](https://github.com/TypeCellOS/BlockNote/issues/2818); fixed upstream by [#2912](https://github.com/TypeCellOS/BlockNote/pull/2912), merged but not yet released) | No data is lost -- the hidden input is written outside React. Disable the extension for the app, or upgrade every `@blocknote/*` package (same version, as always) once a release containing the fix ships |

---

## Accessibility

- Keyboard accessible -- all block operations available via keyboard shortcuts
- Slash menu navigable with arrow keys and Enter (`preset: :full`)
- Suggestion menus (mentions, references) support keyboard navigation
- Focus management handled by BlockNote core
- Semantic HTML output for screen readers

## See Also

- [BlockNote Documentation](https://www.blocknotejs.org/docs)
- [BlockNote Pricing & XL Licensing](https://www.blocknotejs.org/pricing)
- [BlockNote XL Commercial License Terms](https://www.blocknotejs.org/legal/blocknote-xl-commercial-license)
- [DaisyUI Components](https://daisyui.com/components/)
- [Lookbook Preview](/lookbook/inspect/bali/block_editor)
