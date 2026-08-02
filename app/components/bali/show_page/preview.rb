# frozen_string_literal: true

module Bali
  module ShowPage
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Show page with breadcrumbs, title with tags, actions, two-column layout with sidebar.
      def default
        render_with_template(template: "bali/show_page/previews/default")
      end

      # @label Without Sidebar
      # Full-width show page without a sidebar column.
      def without_sidebar
        render_with_template(template: "bali/show_page/previews/without_sidebar")
      end

      # @label Width and sidebar width
      # `max_width:` and `sidebar_width:` resolve through the SAME two tables in the five
      # page components (#684). ShowPage, IndexPage and DocumentPage default to
      # `max_width: :full`, a no-op, so inheriting the option moved no layout. The cap only
      # bites once the viewport is wider than it: compare at mobile and at 1024px+.
      # @param max_width select { choices: [full, sm, md, lg, xl, 2xl] }
      # @param sidebar_width select { choices: [default, narrow, wide] }
      def widths(max_width: :full, sidebar_width: :default)
        render_with_template(
          template: "bali/show_page/previews/widths",
          locals: { max_width: max_width.to_sym, sidebar_width: sidebar_width.to_sym }
        )
      end

      # @label Page or drawer
      # `context:` is declared in `Bali::PageComponents::Shared`, so ShowPage answers to it
      # exactly as FormPage does — the two `if drawer_request?` show views in afal-apps have
      # the same shape as the forty form ones. The difference is that ShowPage has no Card to
      # give up: `:drawer` drops the breadcrumbs and the back button, and that is all.
      # See FormPage's "Page or drawer" scenario for the whole contract.
      # @param context select { choices: [auto, page, drawer] }
      def page_or_drawer(context: :auto)
        render_with_template(
          template: "bali/show_page/previews/context",
          locals: { context: context.to_sym }
        )
      end

      # @label With Many Actions
      # Long title, long subtitle, and 4 actions. At narrow viewports (<640px)
      # the actions bar stacks below the title/subtitle instead of overlapping it (#625).
      def with_many_actions
        render_with_template(template: "bali/show_page/previews/with_many_actions")
      end
    end
  end
end
