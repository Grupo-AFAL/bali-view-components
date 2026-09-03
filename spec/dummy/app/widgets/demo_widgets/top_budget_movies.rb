# frozen_string_literal: true

module DemoWidgets
  class TopBudgetMovies < Bali::Widget::ListBase
    include WidgetRoutes

    default_size :large

    # NO `view_all_path`, deliberately: a nil one is a legitimate state and the
    # header simply drops its link. Every other list here declares one, so this
    # is the tile that shows what the other shape looks like.

    list { Movie.budgeted.order(budget: :desc) }

    row do |r|
      r.title :name
      r.subtitle { |movie| join(movie.genre, currency(movie.budget)) }
      r.href { |movie| admin_movie_path(movie) }
    end


    private

    def currency(amount)
      ActionController::Base.helpers.number_to_currency(amount, precision: 0)
    end
  end
end
