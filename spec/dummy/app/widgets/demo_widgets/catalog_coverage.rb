# frozen_string_literal: true

module DemoWidgets
  # THE RING AT ITS SMALLEST. A goal REPLACES the number as the headline, so a
  # `small` progress tile is a ring and its label — no chart, no rows, and the
  # whole tile is one link.
  class CatalogCoverage < Bali::Widget::ProgressBase
    include WidgetRoutes

    default_size :small

    goal do |g|
      g.value { by_status.fetch("done", 0) }
      g.max { by_status.values.sum }
      g.label { "of #{by_status.values.sum}" }
    end

    view_all_path { admin_movies_path }

    private

    def by_status = @by_status ||= Movie.group(:status).count
  end
end
