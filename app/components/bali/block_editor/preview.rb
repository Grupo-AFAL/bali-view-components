# frozen_string_literal: true

module Bali
  module BlockEditor
    # rubocop:disable Metrics/ClassLength
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

      # @label Two Editors On One Page
      # Two independent editors in the same document. This is the case that broke:
      # `useFileUpload` looked its container up with a global
      # `document.querySelector('[data-controller="block-editor"]')`, so an upload
      # error was reported against whichever editor came first in the DOM rather
      # than the one that failed, and both toasts landed on the same fixed corner.
      #
      # Editor B's `upload_url` points at a 404 on purpose, so its uploads fail on
      # demand and the toast has somewhere wrong it could go.
      def two_editors
        render_with_template(locals: {
          content_a: [ paragraph("Editor A. Uploads work here.") ],
          content_b: [ paragraph("Editor B. Uploads are unconfigured here on purpose.") ]
        })
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

      # @label Entity References
      # Type `#` to reference entities like tasks, projects, or documents.
      # Pass `references_url:` pointing to a JSON API that accepts `?q=`
      # and returns `[{entityType:, entityId:, entityName:}, ...]`.
      # Pass `references_resolve_url:` for batch name resolution on load.
      #
      # This preview uses the dummy app's `/entity_references` endpoint.
      # @param placeholder text
      def with_entity_references(placeholder: 'Type # to reference an entity...')
        render BlockEditor::Component.new(
          editable: true,
          placeholder: placeholder,
          references_url: '/entity_references',
          references_resolve_url: '/entity_references/resolve'
        )
      end

      # Full-featured editor with all capabilities enabled.
      # Includes: rich text, code blocks, multi-column, tables,
      # mentions, entity references, comments, export, AI, and form integration.
      #
      # Multi-column and AI require XL packages (see docs for licensing).
      # AI requires ANTHROPIC_API_KEY environment variable set on the Rails server.
      #
      # @param placeholder text
      # @param format select { choices: [json, html] }
      # @param multi_column toggle
      # @param table_of_contents toggle
      # @param comments toggle
      def full_featured(placeholder: 'Start writing...', format: :json, multi_column: true,
                        table_of_contents: false, comments: false)
        comments_config = if comments
                            { url: demo_comments_url, user: sample_comments_user,
                              users: sample_comments_users }
                          else
                            false
                          end
        render BlockEditor::Component.new(
          editable: true,
          placeholder: placeholder,
          input_name: 'document[content]',
          format: format.to_sym,
          multi_column: multi_column,
          table_of_contents: table_of_contents,
          comments: comments_config,
          export: true,
          export_filename: 'my-document',
          ai_url: '/block_editor/ai',
          mentions_url: '/users',
          references_url: '/entity_references',
          references_resolve_url: '/entity_references/resolve',
          initial_content: full_featured_content.to_json
        )
      end

      # @label With Table of Contents
      # Renders a TOC sidebar extracted from the document's headings.
      # The TOC updates in real-time as headings are added or edited.
      # Clicking any item scrolls the editor to that heading.
      # @param editable toggle
      def with_table_of_contents(editable: true)
        render BlockEditor::Component.new(
          editable: editable,
          table_of_contents: true,
          initial_content: sample_content.to_json
        )
      end

      # @label With Comments (In-Memory)
      # Enables inline commenting with in-memory storage.
      # Comments are lost on page reload — useful for quick demos.
      #
      # Select text and click the comment button in the toolbar
      # to start a thread. The sidebar shows all threads.
      # @param editable toggle
      def with_comments(editable: true)
        render BlockEditor::Component.new(
          editable: editable,
          comments: { user: sample_comments_user, users: sample_comments_users,
                      threads: sample_comment_threads },
          initial_content: commented_document.to_json
        )
      end

      # @label With Comments (Persistent)
      # Enables inline commenting with database persistence, through the engine's own
      # endpoints. Comments survive page reloads. Requires the dummy app server
      # running (`cd spec/dummy && bin/dev`).
      #
      # **This is not the API you write.** A host passes the record the threads belong
      # to and lets Bali resolve the URL:
      #
      #     comments: { url: :auto, commentable: @document, user: ... }
      #
      # A preview owns no record, so it spells the resolved path out instead — see
      # `demo_comments_url` and docs/guides/engines.md.
      # @param editable toggle
      def with_persistent_comments(editable: true)
        render BlockEditor::Component.new(
          editable: editable,
          comments: { url: demo_comments_url, user: sample_comments_user,
                      users: sample_comments_users },
          initial_content: sample_content.to_json
        )
      end

      # Requires ANTHROPIC_API_KEY environment variable set on the Rails server.
      #
      # Type `/ai` in the editor or select text and click the AI button in the toolbar.
      # @param placeholder text
      def with_ai(placeholder: 'Type /ai to use AI assistance...')
        render BlockEditor::Component.new(
          editable: true,
          placeholder: placeholder,
          ai_url: '/block_editor/ai'
        )
      end

      private

      # The engine scopes every comment endpoint to the record the threads belong to
      # (#706), and a preview owns no record — so the two previews that need real
      # persistence name the dummy app's first seeded document by hand. In an app the
      # equivalent is `comments: { url: :auto, commentable: record }`, which resolves to
      # exactly this path; nobody should copy the literal.
      def demo_comments_url
        '/bali/block_editor_comments?commentable_type=Document&commentable_id=1'
      end

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

      def sample_comments_user
        { id: '1', username: 'Alice Johnson', avatar_url: '' }
      end

      def sample_comments_users
        [
          { id: '1', username: 'Alice Johnson', avatar_url: '' },
          { id: '2', username: 'Bob Smith', avatar_url: '' },
          { id: '3', username: 'Carlos Rivera', avatar_url: '' },
          { id: '4', username: 'Diana Park', avatar_url: '' }
        ]
      end

      # A comment lives in TWO places and needs both to render as a real one: a thread in
      # the store, and a `comment` mark on the text it is anchored to. Seeding only the
      # store gets threads in the sidebar, each labelled "Original content deleted" —
      # measured — because nothing in the document points at them.
      #
      # The mark cannot travel in the blocks array `initial_content` usually takes:
      # BlockNote's comment mark declares `blocknoteIgnore`, so the block serializer skips
      # it by design. It travels in the OTHER shape `initial_content` accepts — ProseMirror
      # JSON, the `{ type: "doc" }` form the component detects and loads through
      # `setContent` precisely because it preserves comment marks. Hence this document
      # rather than `sample_content`.
      #
      # The ids are fixed so the two halves can refer to each other from Ruby.
      def commented_document
        pm_doc(
          pm_block("preview-block-1", pm_heading(2, [ pm_text("Comments") ])),
          pm_block("preview-block-2", pm_paragraph([
                                                     pm_text("Select any text and use the comment button in the toolbar to " \
                                                             "start a thread. The two threads in the sidebar arrived with " \
                                                             "the document.")
                                                   ])),
          pm_block("preview-block-3", pm_paragraph([
                                                     pm_text("Keyboard shortcuts are listed in the slash menu.",
                                                             thread_id: "preview-thread-1")
                                                   ])),
          pm_block("preview-block-4", pm_paragraph([
                                                     pm_text("The export formats follow the spec.",
                                                             thread_id: "preview-thread-2")
                                                   ]))
        )
      end

      # The ProseMirror shape BlockNote reads: every block is wrapped in a `blockContainer`
      # inside one `blockGroup`. Taken from `_tiptapEditor.getJSON()` on a real document
      # rather than written from the schema, so it stays the shape the editor emits.
      PM_BLOCK_ATTRS = {
        backgroundColor: "default", textColor: "default", textAlignment: "left"
      }.freeze

      def pm_doc(*containers)
        { type: "doc", content: [ { type: "blockGroup", content: containers } ] }
      end

      def pm_block(id, node)
        { type: "blockContainer", attrs: { id: id }, content: [ node ] }
      end

      def pm_paragraph(runs)
        { type: "paragraph", attrs: PM_BLOCK_ATTRS, content: runs }
      end

      def pm_heading(level, runs)
        { type: "heading", attrs: PM_BLOCK_ATTRS.merge(level: level, isToggleable: false), content: runs }
      end

      def pm_text(text, thread_id: nil)
        run = { type: "text", text: text }
        return run if thread_id.nil?

        run.merge(marks: [ { type: "comment", attrs: { orphan: false, threadId: thread_id } } ])
      end

      # A preview called "With Comments" that opens with none exercises nothing, and the
      # preview sweep still counts it a 200. It is what made #832 — a thread card wider
      # than the sidebar it sits in — invisible: reproducing that needed a comment created
      # by hand through the UI first.
      #
      # Two threads on purpose, because the sidebar's width is what breaks: a short one
      # that fits, and one carrying a long URL with nothing to break on, which is the
      # string that overflows a fixed-width card.
      def sample_comment_threads
        [
          {
            id: 'preview-thread-1',
            comments: [
              comment_body('preview-comment-1', '2',
                           'Should this section mention the keyboard shortcuts too?')
            ]
          },
          {
            id: 'preview-thread-2',
            comments: [
              comment_body('preview-comment-2', '3',
                           'Reference for the spec we agreed on: ' \
                           'https://example.com/very/long/path/that/never/breaks/' \
                           'because-it-has-no-spaces-anywhere-in-it-at-all'),
              comment_body('preview-comment-3', '1', 'Linked, thanks.')
            ]
          }
        ]
      end

      # The body of a comment is a BlockNote document, not a string.
      def comment_body(id, user_id, text)
        {
          id: id,
          userId: user_id,
          body: [ paragraph(text) ]
        }
      end

      # rubocop:disable Metrics/MethodLength
      def paragraph(text)
        { type: 'paragraph', content: [ { type: 'text', text: text, styles: {} } ] }
      end

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
                          [{ type: 'text', text: 'Requires upload_url config', styles: {} }]] }
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
            type: 'paragraph',
            content: [
              { type: 'text', text: 'Related to ', styles: {} },
              { type: 'entityReference',
                props: { entityType: 'project', entityId: '1', entityName: 'Q4 Release' } },
              { type: 'text', text: ' and ', styles: {} },
              { type: 'entityReference',
                props: { entityType: 'task', entityId: '3', entityName: 'Fix login bug' } },
              { type: 'text', text: '.', styles: {} }
            ]
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
    # rubocop:enable Metrics/ClassLength
  end
end
