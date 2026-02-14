# frozen_string_literal: true

module Bali
  module Lexxy
    class Preview < ApplicationViewComponentPreview
      # @!group Basic

      # Default Editor
      # ---------------
      # Rich text editor powered by Lexxy (Basecamp's Lexical-based editor).
      # Supports toolbar, file attachments, markdown shortcuts, and more.
      # @param toolbar toggle
      # @param attachments toggle
      # @param markdown toggle
      # @param multi_line toggle
      # @param rich_text toggle
      # @param disabled toggle
      # @param placeholder text
      def default(toolbar: true, attachments: true, markdown: false, multi_line: true,
                  rich_text: true, disabled: false, placeholder: 'Write something...')
        render Bali::Lexxy::Component.new(
          name: 'post[body]',
          placeholder: placeholder,
          toolbar: toolbar,
          attachments: attachments,
          markdown: markdown,
          multi_line: multi_line,
          rich_text: rich_text,
          disabled: disabled
        )
      end

      # With Content
      # ---------------
      # Editor pre-populated with HTML content.
      def with_content
        render Bali::Lexxy::Component.new(
          name: 'post[body]',
          value: '<h1>Hello World</h1><p>This is <strong>pre-populated</strong> content.</p>'
        )
      end

      # @!endgroup

      # @!group Variations

      # Inline Editor
      # ---------------
      # Single-line editor without toolbar, suitable for comments or inline editing.
      # @param placeholder text
      def inline_editor(placeholder: 'Add a comment...')
        render Bali::Lexxy::Component.new(
          name: 'comment[body]',
          placeholder: placeholder,
          toolbar: false,
          multi_line: false,
          attachments: false
        )
      end

      # Markdown Mode
      # ---------------
      # Editor with markdown shortcuts enabled, plain text output.
      # @param placeholder text
      def markdown_mode(placeholder: 'Write in markdown...')
        render Bali::Lexxy::Component.new(
          name: 'post[body]',
          placeholder: placeholder,
          markdown: true
        )
      end

      # @!endgroup

      # @!group Integration

      # With Mentions
      # ---------------
      # Editor with `@user` and `#tag` prompt triggers for mentions and tagging.
      # Uses `<lexxy-prompt>` elements to configure each trigger type.
      def with_mentions
        render_with_template
      end

      # Form Builder
      # ---------------
      # Usage within a Bali form builder via `f.lexxy_editor_group`.
      # Renders with fieldset wrapper and legend label.
      def form_builder
        render_with_template
      end

      # @!endgroup
    end
  end
end
