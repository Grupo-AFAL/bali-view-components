# frozen_string_literal: true

module Bali
  module BlockEditor
    class Preview < ApplicationViewComponentPreview
      # @param editable toggle
      # @param placeholder text
      def default(editable: true, placeholder: 'Start typing...')
        render BlockEditor::Component.new(
          editable: editable,
          placeholder: placeholder
        )
      end

      def readonly
        render BlockEditor::Component.new(
          initial_content: sample_content.to_json,
          editable: false
        )
      end

      def with_initial_content
        render BlockEditor::Component.new(
          initial_content: sample_content.to_json,
          editable: true
        )
      end

      def with_form_input
        render BlockEditor::Component.new(
          editable: true,
          input_name: 'post[content]',
          placeholder: 'Write your post...'
        )
      end

      # @label Mentions (Static)
      # Type `@` to mention someone from a static list.
      # Pass `mentions:` with an array of strings or
      # `{id:, name:}` hashes.
      # @param placeholder text
      def with_mentions(placeholder: 'Type @ to mention someone...')
        render BlockEditor::Component.new(
          editable: true,
          placeholder: placeholder,
          mentions: sample_users
        )
      end

      # @label Mentions (Remote)
      # Type `@` to search users from a server endpoint.
      # Pass `mentions_url:` pointing to a JSON API that
      # accepts a `?q=` query param and returns
      # `[{id:, name:}, ...]`.
      #
      # This preview uses the dummy app's `/users` endpoint.
      # @param placeholder text
      def with_remote_mentions(placeholder: 'Type @ to search users...')
        render BlockEditor::Component.new(
          editable: true,
          placeholder: placeholder,
          mentions_url: '/users'
        )
      end

      # Full-featured editor with all capabilities enabled.
      # Includes: rich text, code blocks, multi-column, tables,
      # mentions, export, and form integration.
      #
      # @param placeholder text
      # @param format select { choices: [json, html] }
      def full_featured(placeholder: 'Start writing...', format: :json)
        render BlockEditor::Component.new(
          editable: true,
          placeholder: placeholder,
          input_name: 'document[content]',
          format: format.to_sym,
          export: true,
          export_filename: 'my-document',
          mentions_url: '/users',
          initial_content: full_featured_content.to_json
        )
      end

      # Requires the AI chat server running:
      #   cd spec/dummy && ANTHROPIC_API_KEY=sk-ant-... node server/ai-chat.mjs
      #
      # Type `/ai` in the editor or select text and click the AI button in the toolbar.
      # @param placeholder text
      def with_ai(placeholder: 'Type /ai to use AI assistance...')
        render BlockEditor::Component.new(
          editable: true,
          placeholder: placeholder,
          ai_url: 'http://localhost:3456/api/ai/chat'
        )
      end

      private

      def sample_users
        [
          { id: 1, name: 'Alice Johnson' },
          { id: 2, name: 'Bob Smith' },
          { id: 3, name: 'Carlos Rivera' },
          { id: 4, name: 'Diana Park' },
          { id: 5, name: 'Elena Voss' },
          { id: 6, name: 'Federico Martinez' },
          { id: 7, name: 'Grace Chen' },
          { id: 8, name: 'Hugo Nakamura' }
        ]
      end

      # rubocop:disable Metrics/MethodLength
      def sample_content
        [
          # Heading Level 1
          {
            type: 'heading',
            content: [{ type: 'text', text: 'Block Editor Showcase', styles: {} }],
            props: { level: 1 }
          },
          # Heading Level 2
          {
            type: 'heading',
            content: [{ type: 'text', text: 'Text Formatting', styles: {} }],
            props: { level: 2 }
          },
          # Paragraph with inline styles
          {
            type: 'paragraph',
            content: [
              { type: 'text', text: 'This is ', styles: {} },
              { type: 'text', text: 'bold', styles: { bold: true } },
              { type: 'text', text: ', ', styles: {} },
              { type: 'text', text: 'italic', styles: { italic: true } },
              { type: 'text', text: ', ', styles: {} },
              { type: 'text', text: 'underlined', styles: { underline: true } },
              { type: 'text', text: ', ', styles: {} },
              { type: 'text', text: 'strikethrough', styles: { strike: true } },
              { type: 'text', text: ', and ', styles: {} },
              { type: 'text', text: 'inline code', styles: { code: true } },
              { type: 'text', text: ' text.', styles: {} }
            ]
          },
          # Heading Level 3
          {
            type: 'heading',
            content: [{ type: 'text', text: 'Lists', styles: {} }],
            props: { level: 3 }
          },
          # Bullet list items
          {
            type: 'bulletListItem',
            content: [{ type: 'text', text: 'First bullet item', styles: {} }]
          },
          {
            type: 'bulletListItem',
            content: [{ type: 'text', text: 'Second bullet item with ', styles: {} },
                      { type: 'text', text: 'bold text', styles: { bold: true } }]
          },
          {
            type: 'bulletListItem',
            content: [{ type: 'text', text: 'Third bullet item', styles: {} }]
          },
          # Numbered list items
          {
            type: 'numberedListItem',
            content: [{ type: 'text', text: 'First numbered item', styles: {} }]
          },
          {
            type: 'numberedListItem',
            content: [{ type: 'text', text: 'Second numbered item', styles: {} }]
          },
          {
            type: 'numberedListItem',
            content: [{ type: 'text', text: 'Third numbered item', styles: {} }]
          },
          # Check list items
          {
            type: 'checkListItem',
            content: [{ type: 'text', text: 'Completed task', styles: {} }],
            props: { checked: true }
          },
          {
            type: 'checkListItem',
            content: [{ type: 'text', text: 'Pending task', styles: {} }],
            props: { checked: false }
          },
          {
            type: 'checkListItem',
            content: [{ type: 'text', text: 'Another pending task', styles: {} }],
            props: { checked: false }
          },
          # Heading Level 3
          {
            type: 'heading',
            content: [{ type: 'text', text: 'Blockquote', styles: {} }],
            props: { level: 3 }
          },
          # Quote
          {
            type: 'quote',
            content: [
              { type: 'text', text: 'The best way to predict the future is to invent it.',
                styles: { italic: true } },
              { type: 'text', text: ' — Alan Kay', styles: {} }
            ]
          },
          # Divider
          { type: 'divider' },
          # Heading Level 3
          {
            type: 'heading',
            content: [{ type: 'text', text: 'Code Block', styles: {} }],
            props: { level: 3 }
          },
          # Code block with syntax highlighting
          {
            type: 'codeBlock',
            content: [{ type: 'text', styles: {},
                        text: "function greet(name) {\n  " \
                              "return `Hello, \#{'{'}name\#{'}'}!`;\n" \
                              "}\n\nconsole.log(greet('World'));" }],
            props: { language: 'javascript' }
          },
          # Heading Level 3
          {
            type: 'heading',
            content: [{ type: 'text', text: 'Table', styles: {} }],
            props: { level: 3 }
          },
          # Table
          {
            type: 'table',
            content: {
              type: 'tableContent',
              rows: [
                { cells: [[{ type: 'text', text: 'Feature', styles: { bold: true } }],
                          [{ type: 'text', text: 'Status', styles: { bold: true } }],
                          [{ type: 'text', text: 'Notes', styles: { bold: true } }]] },
                { cells: [[{ type: 'text', text: 'Rich Text', styles: {} }],
                          [{ type: 'text', text: 'Supported', styles: {} }],
                          [{ type: 'text', text: 'Bold, italic, underline, code', styles: {} }]] },
                { cells: [[{ type: 'text', text: 'Code Blocks', styles: {} }],
                          [{ type: 'text', text: 'Supported', styles: {} }],
                          [{ type: 'text', text: 'With syntax highlighting', styles: {} }]] },
                { cells: [[{ type: 'text', text: 'Images', styles: {} }],
                          [{ type: 'text', text: 'Optional', styles: {} }],
                          [{ type: 'text', text: 'Requires images_url config', styles: {} }]] }
              ]
            }
          },
          # Toggle list items
          {
            type: 'heading',
            content: [{ type: 'text', text: 'Toggle List', styles: {} }],
            props: { level: 3 }
          },
          {
            type: 'toggleListItem',
            content: [{ type: 'text', text: 'Click to expand this toggle', styles: {} }]
          },
          {
            type: 'toggleListItem',
            content: [{ type: 'text', text: 'Another collapsible section', styles: {} }]
          },
          # Final paragraph
          {
            type: 'paragraph',
            content: [
              { type: 'text', text: 'Type ', styles: {} },
              { type: 'text', text: '/', styles: { code: true } },
              { type: 'text',
                text: ' to see the slash command menu with all available block types.', styles: {} }
            ]
          }
        ]
      end
      # rubocop:enable Metrics/MethodLength

      def full_featured_content # rubocop:disable Metrics/MethodLength
        [
          {
            type: 'heading',
            content: [{ type: 'text', text: 'Project Update', styles: {} }],
            props: { level: 1 }
          },
          {
            type: 'paragraph',
            content: [
              { type: 'text', text: 'Hey ', styles: {} },
              { type: 'mention', props: { user: 'Alice Johnson', id: '1' } },
              { type: 'text', text: ' and ', styles: {} },
              { type: 'mention', props: { user: 'Bob Smith', id: '2' } },
              { type: 'text', text: ', here is the latest update on the project.', styles: {} }
            ]
          },
          {
            type: 'heading',
            content: [{ type: 'text', text: 'Completed Tasks', styles: {} }],
            props: { level: 2 }
          },
          {
            type: 'checkListItem',
            content: [{ type: 'text', text: 'Set up development environment', styles: {} }],
            props: { checked: true }
          },
          {
            type: 'checkListItem',
            content: [{ type: 'text', text: 'Implement core editor features', styles: {} }],
            props: { checked: true }
          },
          {
            type: 'checkListItem',
            content: [
              { type: 'text', text: 'Add mentions support (assigned to ', styles: {} },
              { type: 'mention', props: { user: 'Carlos Rivera', id: '3' } },
              { type: 'text', text: ')', styles: {} }
            ],
            props: { checked: true }
          },
          {
            type: 'checkListItem',
            content: [{ type: 'text', text: 'Write documentation', styles: {} }],
            props: { checked: false }
          },
          {
            type: 'heading',
            content: [{ type: 'text', text: 'Code Example', styles: {} }],
            props: { level: 2 }
          },
          {
            type: 'codeBlock',
            content: [{ type: 'text', styles: {},
                        text: "render BlockEditor::Component.new(\n  " \
                              "mentions: [\n    " \
                              "{ id: 1, name: 'Alice' },\n    " \
                              "{ id: 2, name: 'Bob' }\n  " \
                              "],\n  export: true\n)" }],
            props: { language: 'ruby' }
          },
          {
            type: 'paragraph',
            content: [
              { type: 'text', text: 'Type ', styles: {} },
              { type: 'text', text: '@', styles: { code: true } },
              { type: 'text', text: ' to mention someone, ', styles: {} },
              { type: 'text', text: '/', styles: { code: true } },
              { type: 'text', text: ' for the slash menu, or use the export buttons below.',
                styles: {} }
            ]
          }
        ]
      end
    end
  end
end
