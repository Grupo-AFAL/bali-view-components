# frozen_string_literal: true

module Bali
  module IndexPage
    class Preview < ApplicationViewComponentPreview
      # Same fixtures as `bali/data_table/complete`: this preview is that composition PLUS
      # the page layer. Sharing them is what guarantees it does not drift.
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

      # @label Secondary actions menu
      # The `⋯` takes its width and its trigger's accessible name from the page:
      # `secondary_actions_width:` (Bali::Dropdown's scale) and `secondary_actions_label:`
      # (#1230). Below `sm` the trigger wraps to the left of the row and the menu still opens
      # inside the screen (#1231). Click, Enter, Space or ↓ open it; focus alone does not.
      # @param secondary_actions_width select { choices: [sm, md, lg, xl] }
      # @param secondary_actions_label text
      def with_secondary_actions(secondary_actions_width: :xl,
                                 secondary_actions_label: "More calendar actions")
        render_with_template(
          template: "bali/index_page/previews/with_secondary_actions",
          locals: { secondary_actions_width: secondary_actions_width.to_sym,
                    secondary_actions_label: secondary_actions_label.presence }
        )
      end
    end
  end
end
