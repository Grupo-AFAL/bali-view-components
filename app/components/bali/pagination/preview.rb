# frozen_string_literal: true

module Bali
  module Pagination
    class Preview < ApplicationViewComponentPreview
      # @param page select { choices: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] }
      # @param total_items number
      # @param items_per_page number
      # @param size select { choices: [xs, sm, md, lg] }
      # @param variant select { choices: [default, outline, ghost] }
      def default(page: 3, total_items: 100, items_per_page: 10, size: :md, variant: :default)
        # Pagy 43.x uses Pagy::Offset with `limit` instead of `items`
        pagy = Pagy::Offset.new(count: total_items.to_i, page: page.to_i, limit: items_per_page.to_i)
        render Bali::Pagination::Component.new(pagy: pagy, size: size.to_sym, variant: variant.to_sym, url: '/lookbook')
      end

      # @label Many Pages
      # @param page number
      def many_pages(page: 25)
        pagy = Pagy::Offset.new(count: 500, page: page.to_i, limit: 10)
        render Bali::Pagination::Component.new(pagy: pagy, url: '/lookbook')
      end
    end
  end
end
