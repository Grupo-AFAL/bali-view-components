# frozen_string_literal: true

module Bali
  # Exposed to host app views (see the engine initializer). Publishes the
  # digested paths of a React island's bundle so that the generic loader
  # (`startIslandLoader` in `bali-view-components/react-island`) can inject
  # them the first time the island appears in the DOM.
  #
  # They travel as <meta> instead of <link>/<script> because the bundle must
  # not load on every page, and because drawers/modals inject content with
  # innerHTML, where a <script> never executes — only the server knows the
  # digested path, hence the meta indirection.
  #
  # `name` is the island's controller identifier (e.g. "gantt"); the emitted
  # tags are `bali-<name>-js` and `bali-<name>-css`, which is what the loader
  # derives from the same name. `block_editor_meta_tags` is the block editor's
  # wrapper around this helper.
  module ReactIslandHelper
    # Pass `css: nil` (the default) if the entry emits no stylesheet of its own.
    def react_island_meta_tags(name, js:, css: nil)
      tags = [ tag.meta(name: "bali-#{name}-js", content: asset_path(js)) ]
      tags << tag.meta(name: "bali-#{name}-css", content: asset_path(css)) if css

      safe_join(tags, "\n")
    end
  end
end
