# frozen_string_literal: true

module DemoWidgets
  # THE CHECK LADDER, passing. Named so TRUE IS GOOD — "categorised", not
  # "uncategorised" — which is what lets the card colour itself green without a
  # polarity declaration.
  class SchemaHealth < Bali::Widget::CheckBase
    include WidgetRoutes

    default_size :small

    check do |c|
      c.value { Movie.where(genre: nil).none? }
      c.pass { "All #{Movie.count} categorised" }
      c.fail { "#{Movie.where(genre: nil).count} missing a genre" }
    end

    view_all_path { admin_movies_path }
  end
end
