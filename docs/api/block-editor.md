# Bali::BlockEditor::Component

A rich text editor powered by [BlockNote](https://www.blocknotejs.org/) and React, integrated into Rails via a Stimulus controller. Provides a modern block-based editing experience with support for rich text, code blocks, tables, multi-column layouts, file uploads, @mentions, #entity references, AI assistance, and PDF/DOCX export.

## Prerequisites

### npm Dependencies

```bash
yarn add @blocknote/core @blocknote/react @blocknote/mantine react react-dom
yarn add @blocknote/xl-multi-column  # Multi-column layouts (XL package)
yarn add shiki                       # Syntax highlighting for code blocks

# Optional - for export functionality (XL packages)
yarn add @blocknote/xl-pdf-exporter @react-pdf/renderer
yarn add @blocknote/xl-docx-exporter docx

# Optional - for AI assistance (XL package)
yarn add @blocknote/xl-ai ai
```

### BlockNote XL Package Licensing

The BlockEditor relies on several **BlockNote XL** packages for advanced features. These packages are **dual-licensed** and may require a paid subscription depending on your project:

| Package | Feature | License |
|---------|---------|---------|
| `@blocknote/core`, `@blocknote/react`, `@blocknote/mantine` | Core editor | **MPL 2.0** -- Free for all projects, including commercial and closed-source |
| `@blocknote/xl-multi-column` | Multi-column layouts | **GPL-3.0** or Commercial |
| `@blocknote/xl-pdf-exporter` | PDF export | **GPL-3.0** or Commercial |
| `@blocknote/xl-docx-exporter` | DOCX export | **GPL-3.0** or Commercial |
| `@blocknote/xl-ai` | AI assistance | **GPL-3.0** or Commercial |

**What this means for your application:**

- **Open-source projects (GPL-3.0 compatible):** XL packages are free to use under GPL-3.0.
- **Closed-source / proprietary applications:** You must purchase a [BlockNote Business subscription](https://www.blocknotejs.org/pricing) ($390/month) for a commercial license to use any XL package.

**Commercial license terms:**
- Covers **one application** (single production domain) per license
- Includes **5 developer seats**
- Auto-renews monthly; XL packages must not be used in production if the subscription lapses

**Startup/non-profit discounts** are available for seed-stage startups and non-profits with fewer than 5 employees. See [BlockNote Pricing](https://www.blocknotejs.org/pricing) for details.

> **Note:** Since the BlockEditor component uses `@blocknote/xl-multi-column` by default for multi-column layouts, any closed-source application using this component will need a commercial license. If you want to avoid the subscription, you would need to fork the component and remove the multi-column dependency -- but this also removes multi-column layout support from the slash menu.

### Rails Configuration

Enable the component in your Bali initializer:

```ruby
# config/initializers/bali.rb
Bali.config do |config|
  config.block_editor_enabled = true
end
```

The component will not render unless `block_editor_enabled` is `true`.

### Stimulus Controller Registration

Register the controller in your JavaScript entry point:

```javascript
import { BlockEditorController } from 'bali-view-components'

application.register('block-editor', BlockEditorController)
```

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
- `:json` (default) -- Serializes as BlockNote JSON. Lossless round-trip. Recommended for storage.
- `:html` -- Serializes as HTML. Lossy (some block-level metadata may be lost).

### Loading HTML Content

If you have existing HTML content (e.g., from a legacy Trix editor), use `html_content:` instead of `initial_content:`. The editor will parse the HTML into blocks on mount.

```erb
<%= render Bali::BlockEditor::Component.new(
  html_content: @post.body_html,
  input_name: 'post[content]',
  format: :json
) %>
```

---

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `initial_content` | `String`, `Hash`, `Array` | `nil` | BlockNote JSON content to load |
| `html_content` | `String` | `nil` | HTML string to parse into blocks on mount |
| `input_name` | `String` | `nil` | Hidden input `name` attribute for form submission |
| `format` | `Symbol` | `:json` | Serialization format: `:json` or `:html` |
| `editable` | `Boolean` | `true` | Whether the editor is editable |
| `placeholder` | `String` | `nil` | Placeholder text shown when editor is empty |
| `images_url` | `String`, `:auto` | `:auto` | Upload endpoint URL. `:auto` resolves from engine routes |
| `theme` | `Symbol` | `:light` | Editor theme: `:light` or `:dark` |
| `export` | `Boolean`, `Array` | `false` | Enable export buttons. `true` for both, or `[:pdf]`, `[:docx]`, `[:pdf, :docx]` |
| `export_filename` | `String` | `'document'` | Base filename for exported files (without extension) |
| `ai_url` | `String` | `nil` | AI chat endpoint URL. Enables AI features when set |
| `mentions_url` | `String` | `nil` | Remote mentions search endpoint URL |
| `mentions` | `Array` | `nil` | Static list of mentionable users |
| `references_url` | `String` | `nil` | Entity reference search endpoint URL |
| `references_resolve_url` | `String` | `nil` | Batch entity reference resolution endpoint URL |
| `references_config` | `Hash` | `nil` | Custom entity type display configuration |
| `**options` | `Hash` | `{}` | Additional HTML attributes passed to the wrapper div |

---

## Built-in Features (No Integration Required)

These features work out of the box with zero configuration:

- **Rich text** -- Bold, italic, underline, strikethrough, inline code
- **Headings** -- Levels 1-3
- **Lists** -- Bullet, numbered, checklist, toggle
- **Blockquotes**
- **Tables** -- Resizable with header rows
- **Code blocks** -- Syntax highlighting via Shiki for 20+ languages
- **Multi-column layouts** -- 2 and 3 column layouts via slash menu (XL package -- see [Licensing](#blocknote-xl-package-licensing))
- **Dividers**
- **Slash menu** -- Type `/` to access all block types

### Supported Code Languages

JavaScript, TypeScript, Python, Ruby, HTML, CSS, JSON, Bash, SQL, YAML, Markdown, XML, Java, Go, Rust, PHP, C, C++, C#, Swift, Kotlin, Plain Text.

---

## File Uploads

File uploads allow users to drag-and-drop or paste images and files into the editor.

### Option A: Engine Routes (Recommended)

Mount the Bali engine in your routes and the upload URL auto-resolves:

```ruby
# config/routes.rb
mount Bali::Engine => '/bali'
```

The engine provides `POST /bali/block_editor/uploads` which:
- Validates file type via MIME type detection (not just extension)
- Validates file size (default 10MB max)
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
  images_url: '/api/uploads'
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
  images_url: nil
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

Entity references require two endpoints:

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

## PDF and DOCX Export

> **Licensing:** PDF and DOCX export use XL packages (`@blocknote/xl-pdf-exporter`, `@blocknote/xl-docx-exporter`). Free for open-source projects under GPL-3.0; closed-source applications require a [BlockNote Business subscription](https://www.blocknotejs.org/pricing). See [Licensing](#blocknote-xl-package-licensing).

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

These are dynamically imported only when the user clicks an export button.

---

## AI Assistance

> **Licensing:** AI features use the XL package `@blocknote/xl-ai`. Free for open-source projects under GPL-3.0; closed-source applications require a [BlockNote Business subscription](https://www.blocknotejs.org/pricing). See [Licensing](#blocknote-xl-package-licensing).

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

These are dynamically imported only when `ai_url` is configured, so they don't affect bundle size for editors without AI.

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
  images_url: :auto,

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

The CSS is lazy-loaded via Vite only when the BlockEditor component is used on a page.

---

## Architecture

The BlockEditor uses a **custom Stimulus controller** that manages a React component lifecycle:

1. **Mount** -- On Stimulus `connect()`, dynamically imports React, ReactDOM, and BlockNoteEditorWrapper, then creates a React root
2. **Turbo cleanup** -- Listens for `turbo:before-cache` to unmount the React root before Turbo caches the page
3. **Disconnect** -- Unmounts the React root on Stimulus `disconnect()`

AI modules (`@blocknote/xl-ai`, `ai`) are only imported when `ai_url` is configured, keeping the base bundle lean.

### File Structure

```
app/components/bali/block_editor/
  component.rb                  # Ruby ViewComponent class
  component.html.erb            # ERB template
  index.js                      # Stimulus controller + export logic
  BlockNoteEditorWrapper.jsx    # React component (main editor)
  inlineContent.jsx             # Mention and EntityReference definitions
  useFileUpload.js              # File upload hook
  useContentSync.js             # Hidden input sync hook (debounced 300ms)
  useMentions.js                # @mentions suggestion hook
  useEntityReferences.jsx       # #entity references suggestion + resolution hook
  constants.js                  # Supported languages, max upload size
  index.css                     # DaisyUI overrides for BlockNote/Mantine
  preview.rb                    # Lookbook previews
```

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
| Full Featured | `/lookbook/inspect/bali/block_editor/full_featured` | All features enabled |
| With AI | `/lookbook/inspect/bali/block_editor/with_ai` | AI assistance |

---

## Accessibility

- Keyboard accessible -- all block operations available via keyboard shortcuts
- Slash menu navigable with arrow keys and Enter
- Suggestion menus (mentions, references) support keyboard navigation
- Focus management handled by BlockNote core
- Semantic HTML output for screen readers

## See Also

- [BlockNote Documentation](https://www.blocknotejs.org/docs)
- [BlockNote Pricing & XL Licensing](https://www.blocknotejs.org/pricing)
- [BlockNote XL Commercial License Terms](https://www.blocknotejs.org/legal/blocknote-xl-commercial-license)
- [DaisyUI Components](https://daisyui.com/components/)
- [Lookbook Preview](/lookbook/inspect/bali/block_editor)
