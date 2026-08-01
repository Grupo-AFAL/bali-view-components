# frozen_string_literal: true

module Bali
  module Pagination
    class Preview < ApplicationViewComponentPreview
      # A Pagy built by hand carries no request, so the links come out relative
      # (`?page=2`) — which inside the preview is exactly the `page` param below, so the
      # buttons actually work here.
      # @param page select { choices: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] }
      # @param total_items number
      # @param items_per_page number
      # @param size select { choices: [xs, sm, md, lg] }
      # @param variant select { choices: [default, outline, ghost] }
      def default(page: 3, total_items: 100, items_per_page: 10, size: :md, variant: :default)
        # Pagy 43.x uses Pagy::Offset with `limit` instead of `items`
        pagy = Pagy::Offset.new(count: total_items.to_i, page: page.to_i, limit: items_per_page.to_i)
        render Bali::Pagination::Component.new(pagy: pagy, size: size.to_sym, variant: variant.to_sym)
      end

      # @label Many Pages
      # @param page number
      def many_pages(page: 25)
        pagy = Pagy::Offset.new(count: 500, page: page.to_i, limit: 10)
        render Bali::Pagination::Component.new(pagy: pagy)
      end

      # `url:` is the base for a Pagy that cannot build its own URLs, and it wins when given:
      # it has to carry whatever query string must survive the page change.
      # @label Explicit URL
      def explicit_url
        pagy = Pagy::Offset.new(count: 100, page: 3, limit: 10)
        render Bali::Pagination::Component.new(pagy: pagy, url: '/admin/movies?q=batman')
      end

      # Paging a section halfway down the page without jumping to the top, and without
      # reloading the whole page. From the controller, `pagy(scope, fragment: '#results')`
      # does the same job.
      # @label Fragment and data attributes
      def fragment_and_data
        pagy = Pagy::Offset.new(count: 100, page: 3, limit: 10)
        render Bali::Pagination::Component.new(
          pagy: pagy,
          url: '/admin/movies',
          fragment: '#results',
          data: { turbo_frame: 'movies' }
        )
      end
    end
  end
end
