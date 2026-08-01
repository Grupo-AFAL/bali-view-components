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
    end
  end
end
