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

      # Privado a propósito: Lookbook toma los métodos públicos como escenarios, y esto no es
      # uno. La guarda queda escrita en cada escenario en vez de envolver al render, para que
      # el panel Source siga mostrando la llamada al componente, que es lo que un host copia.
      def why_this_is_empty
        render_with_template(template: 'bali/rich_text_editor/previews/disabled')
      end
    end
  end
end
