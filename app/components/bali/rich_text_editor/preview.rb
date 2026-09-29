# frozen_string_literal: true

module Bali
  module RichTextEditor
    # Rich Text Editor
    # ----------------
    # **Deprecated in v3, removed in v4** — use `Bali::BlockEditor::Component`.
    #
    # This component sits behind `Bali.rich_text_editor_enabled`, which the package ships as
    # `false`: its `render?` returns that flag, so with the flag off it emits nothing at all
    # and every scenario below would be a blank page — indistinguishable from a component that
    # is simply broken. The scenarios say so instead of rendering nothing (#844).
    #
    # Boot the dummy with `ENABLE_RICH_TEXT_EDITOR=1 bin/dev` to see the real editor.
    class Preview < ApplicationViewComponentPreview
      # @param html_content text
      def default(html_content: '')
        return why_this_is_empty unless Bali.rich_text_editor_enabled

        render Bali::RichTextEditor::Component.new(html_content: html_content, editable: true)
      end

      # @param html_content text
      def readonly(html_content: '')
        return why_this_is_empty unless Bali.rich_text_editor_enabled

        render Bali::RichTextEditor::Component.new(html_content: html_content, editable: false)
      end

      private

      # Private on purpose: Lookbook takes public methods as scenarios, and this is not one.
      # The guard is written in each scenario instead of wrapping the render, so that the
      # Source panel keeps showing the component call, which is what a host copies.
      def why_this_is_empty
        render_with_template(template: 'bali/rich_text_editor/previews/disabled')
      end
    end
  end
end
