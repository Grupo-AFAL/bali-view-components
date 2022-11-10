# frozen_string_literal: true

module Bali
  module RichTextEditor
    class Preview < ApplicationViewComponentPreview
      # @param html_content text
      def default(html_content: '')
        render RichTextEditor::Component.new(html_content: html_content, editable: true)
      end

      # @param html_content text
      def readonly(html_content: '')
        render RichTextEditor::Component.new(html_content: html_content, editable: false)
      end
    end
  end
end
