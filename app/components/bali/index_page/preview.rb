# frozen_string_literal: true

module Bali
  module IndexPage
    class Preview < ApplicationViewComponentPreview
      # Mismas fixtures que `bali/data_table/complete`: este preview es esa composición MÁS
      # la capa de página. Compartirlas es lo que garantiza que no derive.
      include Bali::DataTable::Preview::CanonicalIndex

      # @label Complete (Live DB)
      # **The canonical index page.** Page chrome (breadcrumbs, title, primary action, the
      # `⋯` of secondary actions) plus a DataTable with the seven toolbar control families,
      # row selection and pagination. Copy this composition when building an index.
      #
      # - The DataTable goes in bare: the surface travels with its content slot, so there is
      #   no `Bali::Card` around it
      # - `?view=` switches the content band (table / cards / timeline) while keeping
      #   filters, sorting, grouping and the applied saved view
      # - Export lives in the page's `⋯` (`page.with_export`), not in the toolbar: it acts
      #   ON the page. Its links carry the active filters — filter the listing and the
      #   hrefs follow
      # - Below `sm` the secondary toolbar controls fold into the toolbar's own `⋯` menu
      # @param view select { choices: [table, grid, timeline] }
      # @param group_by select { choices: ["", genre, status] }
      def complete(view: :table, q: {}, page: 1, group_by: nil, saved_view: nil)
        render_with_template(
          template: "bali/index_page/previews/complete",
          locals: canonical_index_locals(view: view, q: q, page: page,
                                         group_by: group_by, saved_view: saved_view)
        )
      end

      # @label Default
      # Standard index page with breadcrumbs, title, action button, and body area.
      def default
        render_with_template(template: "bali/index_page/previews/default")
      end

      # @label With nav (two-level navigation)
      # Second-level navigation via the `nav` slot, rendered between the page
      # header and the body. Recipe: level 1 `Tabs style: :border` (icon+label),
      # level 2 `Tabs style: :box, size: :sm`, both with `href:` tabs.
      def with_nav
        render_with_template(template: "bali/index_page/previews/with_nav")
      end

      # @label With Back Button
      # Nested index page (e.g. a resource's sub-listing) with a back link to
      # its parent, same contract as ShowPage/FormPage (#639).
      def with_back
        render_with_template(template: "bali/index_page/previews/with_back")
      end
    end
  end
end
