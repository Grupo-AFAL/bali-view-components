# Lexxy Rich Text Editor

`Bali::Lexxy::Component` wraps [Lexxy](https://github.com/basecamp/lexxy) -- Basecamp's rich text editor built on Meta's Lexical framework. It provides native Action Text integration, mentions/tagging via `<lexxy-prompt>`, file attachments via Active Storage, and form submission via ElementInternals.

## Prerequisites

Add the Lexxy gem and npm package to your project:

```ruby
# Gemfile
gem 'lexxy', '~> 0.7.4.beta'
```

If using a JavaScript bundler (esbuild, Vite, webpack):

```bash
yarn add @37signals/lexxy
```

Import Lexxy in your JavaScript entry point:

```javascript
// With import maps (propshaft)
import 'lexxy'

// With JS bundler (Vite, esbuild, webpack)
import '@37signals/lexxy'
```

Add the stylesheet to your layout:

```erb
<%= stylesheet_link_tag "lexxy" %>
```

---

## Standalone Component

### Basic Usage

```erb
<%= render Bali::Lexxy::Component.new(
      name: "post[body]",
      placeholder: "Write something..."
    ) %>
```

### With Mentions and Tags

Use prompt slots to enable `@mentions` and `#tags`:

```erb
<%= render Bali::Lexxy::Component.new(
      name: "post[body]",
      placeholder: "Write something..."
    ) do |editor| %>
  <% editor.with_prompt(
       trigger: "@",
       name: "mention",
       src: "/people/search",
       remote_filtering: true,
       empty_results: "No users found"
     ) %>
  <% editor.with_prompt(
       trigger: "#",
       name: "tag",
       src: "/tags/search"
     ) %>
<% end %>
```

### Inline / Comment Mode

Single-line editor without toolbar, for comments or chat inputs:

```erb
<%= render Bali::Lexxy::Component.new(
      name: "comment[body]",
      placeholder: "Add a comment...",
      toolbar: false,
      multi_line: false,
      attachments: false
    ) %>
```

### Markdown Mode

```erb
<%= render Bali::Lexxy::Component.new(
      name: "post[body]",
      markdown: true,
      placeholder: "Write in markdown..."
    ) %>
```

---

## Form Builder

### lexxy_editor_group

Renders the editor wrapped in a `fieldset` with label and error handling:

```erb
<%= form_with model: @post, builder: Bali::FormBuilder do |f| %>
  <%= f.lexxy_editor_group :body, placeholder: "Write your post..." %>
<% end %>
```

### lexxy_editor_group with Prompts

Pass a block to configure prompt slots:

```erb
<%= form_with model: @post, builder: Bali::FormBuilder do |f| %>
  <%= f.lexxy_editor_group :body, placeholder: "Write your post..." do |editor| %>
    <% editor.with_prompt(trigger: "@", name: "mention", src: people_path) %>
  <% end %>
<% end %>
```

### lexxy_editor (without wrapper)

For custom layouts where you need just the editor:

```erb
<%= f.lexxy_editor :body, placeholder: "Write..." %>
```

---

## Component Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | String | nil | Form field name (e.g., `"post[body]"`) |
| `value` | String | nil | Pre-populated HTML content |
| `placeholder` | String | nil | Placeholder text |
| `toolbar` | Boolean/String | true | `false` hides toolbar, String = external toolbar element ID |
| `attachments` | Boolean | true | Enable file attachments |
| `markdown` | Boolean | false | Enable markdown shortcuts |
| `multi_line` | Boolean | true | Allow multi-line input |
| `rich_text` | Boolean | true | Enable rich text formatting |
| `required` | Boolean | false | HTML required attribute |
| `disabled` | Boolean | false | HTML disabled attribute |
| `autofocus` | Boolean | false | HTML autofocus attribute |
| `preset` | Symbol | nil | Lexxy preset name |
| `class` | String | nil | Additional CSS classes on wrapper |
| `data` | Hash | nil | Data attributes on editor element |

## Prompt Slot Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `trigger` | String | required | Character that opens the prompt (`@`, `#`, `/`) |
| `name` | String | required | Content type name (becomes `application/vnd.actiontext.[name]`) |
| `src` | String | nil | URL for loading suggestions |
| `remote_filtering` | Boolean | false | Server-side filtering vs client-side |
| `insert_editable_text` | Boolean | false | Insert as editable HTML instead of attachment |
| `empty_results` | String | nil | Message shown when no matches found |
| `supports_space_in_searches` | Boolean | false | Allow spaces in search queries |

---

## Rendered HTML

The component renders standard web component elements:

```html
<div class="lexxy-component">
  <lexxy-editor name="post[body]" placeholder="Write something...">
    <lexxy-prompt trigger="@" name="mention" src="/people" remote-filtering></lexxy-prompt>
    <lexxy-prompt trigger="#" name="tag" src="/tags"></lexxy-prompt>
  </lexxy-editor>
</div>
```

Lexxy's web components handle all interactivity -- no Stimulus controller is needed.

---

## Migration from Trix / TipTap

### From `rich_text_area_group` (Trix)

```diff
- <%= f.rich_text_area_group :body %>
+ <%= f.lexxy_editor_group :body %>
```

### From `Bali::RichTextEditor::Component` (TipTap)

```diff
- <%= render Bali::RichTextEditor::Component.new(
-       form: f, name: :body,
-       page_hyperlink_options: @pages
-     ) %>
+ <%= render Bali::Lexxy::Component.new(
+       name: "#{f.object_name}[body]",
+       value: f.object&.body.to_s
+     ) do |editor| %>
+   <% editor.with_prompt(trigger: "@", name: "page", src: pages_path) %>
+ <% end %>
```

Both `rich_text_area_group` and `Bali::RichTextEditor` are deprecated and will be removed in v3.0.

---

## Lookbook Previews

View all previews in Lookbook at:

- **Default**: `/lookbook/inspect/bali/lexxy/default`
- **With Content**: `/lookbook/inspect/bali/lexxy/with_content`
- **Inline Editor**: `/lookbook/inspect/bali/lexxy/inline_editor`
- **Markdown Mode**: `/lookbook/inspect/bali/lexxy/markdown_mode`
- **With Mentions**: `/lookbook/inspect/bali/lexxy/with_mentions`
- **Form Builder**: `/lookbook/inspect/bali/lexxy/form_builder`
