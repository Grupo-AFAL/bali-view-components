# frozen_string_literal: true

module Bali
  module PaginationFooter
    class Preview < Lookbook::Preview
      # @param item_name text
      # @param show_summary toggle
      # @param show_pagination toggle
      # @param current_page select { choices: [1, 2, 3, 4, 5] }
      def default(item_name: 'items', show_summary: true, show_pagination: true, current_page: 1)
        pagy = Pagy.new(count: 47, page: current_page.to_i, items: 10)

        render Component.new(
          pagy: pagy,
          item_name: item_name,
          show_summary: show_summary,
          show_pagination: show_pagination
        )
      end

      # Single page (no pagination controls shown)
      def single_page
        pagy = Pagy.new(count: 5, page: 1, items: 10)

        render Component.new(pagy: pagy, item_name: 'studios')
      end

      # Summary only (pagination hidden)
      def summary_only
        pagy = Pagy.new(count: 47, page: 1, items: 10)

        render Component.new(pagy: pagy, item_name: 'movies', show_pagination: false)
      end

      # Pagination only (summary hidden)
      def pagination_only
        pagy = Pagy.new(count: 47, page: 2, items: 10)

        render Component.new(pagy: pagy, show_summary: false)
      end
    end
  end
end
