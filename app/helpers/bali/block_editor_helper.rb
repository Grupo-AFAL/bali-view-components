# frozen_string_literal: true

module Bali
  # Exposed to host app views (see the engine initializer). Publishes the
  # digested paths of the editor bundle so that
  # `bali-view-components/block-editor-loader` can inject them the first time
  # a block editor appears in the DOM.
  #
  # The block editor was the first React island; the generic mechanics now
  # live in Bali::ReactIslandHelper and this remains as the editor's
  # ergonomic spelling (not deprecated — it is the established API of the
  # gem's largest island).
  module BlockEditorHelper
    include Bali::ReactIslandHelper

    # Pass `css: nil` if the entry emits no stylesheet of its own.
    def block_editor_meta_tags(js: "editor.js", css: "editor.css")
      react_island_meta_tags("block-editor", js: js, css: css)
    end
  end
end
