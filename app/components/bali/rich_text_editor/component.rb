# frozen_string_literal: true

module Bali
  module RichTextEditor
    class Component < ApplicationViewComponent
      attr_reader :html_content, :output_input_name, :images_url, :page_hyperlink_options

      def initialize(
        html_content: nil,
        output_input_name: nil,
        editable: false,
        placeholder: nil,
        images_url: nil,
        **options
      )
        @editable = editable
        @html_content = html_content
        @placeholder = placeholder
        @output_input_name = output_input_name
        @images_url = images_url
        @page_hyperlink_options = options.delete(:page_hyperlink_options) || []

        @base_options = prepend_class_name(options,
                                           "rich-text-editor-component rich-editor-content input")
        @base_options = prepend_controller(@base_options, "rich-text-editor")

        warn_deprecated
      end

      # The default placeholder is a translation and `t` needs the view context,
      # so the controller values can only be resolved once the render started.
      def options
        @options ||= prepend_values(@base_options, "rich-text-editor", controller_values)
      end

      def controller_values
        {
          content: @html_content || "",
          editable: @editable,
          placeholder: @placeholder || t(".placeholder"),
          images_url: @images_url
        }
      end

      def editable?
        @editable
      end

      def render?
        Bali.rich_text_editor_enabled
      end

      private

      # Deprecated in v3, removed in v4. It keeps working here exactly as before --
      # this is a warning, not a behaviour change.
      #
      # The deprecation has to land in v3.0 to earn the removal in v4, and the
      # removal is worth a lot: this component is the only reason the package
      # declares roughly thirty-five `@tiptap/*` optional peers plus `lowlight` and
      # `highlight.js`. BlockEditor covers the same ground on a maintained stack,
      # reads and writes HTML through `html_content:`/`format: :html`, and is the
      # component the rest of v3 is built around.
      def warn_deprecated
        Bali.deprecator.warn(
          "Bali::RichTextEditor::Component is deprecated and is removed in 4.0. " \
          "Migrate to Bali::BlockEditor::Component, which reads and writes the same HTML: " \
          "see the RichTextEditor section of docs/guides/migration-v2-to-v3.md."
        )
      end
    end
  end
end
