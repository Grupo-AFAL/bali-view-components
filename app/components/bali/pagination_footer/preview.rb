# frozen_string_literal: true

module Bali
  module PaginationFooter
    class Preview < ApplicationViewComponentPreview
      # @param item_name text
      # @param show_summary toggle
      # @param show_pagination toggle
      # @param current_page select { choices: [1, 2, 3, 4, 5] }
      def default(item_name: 'items', show_summary: true, show_pagination: true, current_page: 1)
        pagy = Pagy::Offset.new(count: 47, page: current_page.to_i, limit: 10)

        render Bali::PaginationFooter::Component.new(
          pagy: pagy,
          item_name: item_name,
          show_summary: show_summary,
          show_pagination: show_pagination
        )
      end

      # Single page (no pagination controls shown)
      def single_page
        pagy = Pagy::Offset.new(count: 5, page: 1, limit: 10)

        render Bali::PaginationFooter::Component.new(pagy: pagy, item_name: 'studios')
      end

      # Summary only (pagination hidden)
      def summary_only
        pagy = Pagy::Offset.new(count: 47, page: 1, limit: 10)

        render Bali::PaginationFooter::Component.new(pagy: pagy, item_name: 'movies', show_pagination: false)
      end

      # Pagination only (summary hidden)
      def pagination_only
        pagy = Pagy::Offset.new(count: 47, page: 2, limit: 10)

        render Bali::PaginationFooter::Component.new(pagy: pagy, show_summary: false)
      end

      # No results: nothing to describe and nowhere to page to, so the footer does not draw
      # at all. This preview is blank on purpose.
      # @label No results
      def no_results
        pagy = Pagy::Offset.new(count: 0, page: 1, limit: 10)

        render Bali::PaginationFooter::Component.new(pagy: pagy, item_name: 'movies')
      end

      # Size and variant travel all the way to Pagination's buttons.
      # @label Small outlined controls
      def small_outlined
        pagy = Pagy::Offset.new(count: 47, page: 2, limit: 10)

        render Bali::PaginationFooter::Component.new(pagy: pagy, item_name: 'movies', size: :sm, variant: :outline)
      end
    end
  end
end
