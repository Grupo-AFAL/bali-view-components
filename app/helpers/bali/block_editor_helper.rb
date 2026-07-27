# frozen_string_literal: true

module Bali
  # Exposed to host app views (see the engine initializer). Publishes the
  # digested paths of the editor bundle so that
  # `bali-view-components/block-editor-loader` can inject them the first time
  # a block editor appears in the DOM.
  #
  # They travel as <meta> instead of <link>/<script> because the bundle must
  # not load on every page, and because drawers/modals inject content with
  # innerHTML, where a <script> never executes — only the server knows the
  # digested path, hence the meta indirection.
  module BlockEditorHelper
    # Pass `css: nil` if the entry emits no stylesheet of its own.
    def block_editor_meta_tags(js: "editor.js", css: "editor.css")
      tags = [ tag.meta(name: "bali-block-editor-js", content: asset_path(js)) ]
      tags << tag.meta(name: "bali-block-editor-css", content: asset_path(css)) if css

      safe_join(tags, "\n")
    end
  end
end
