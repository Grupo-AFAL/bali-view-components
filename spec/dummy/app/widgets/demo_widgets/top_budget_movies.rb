# frozen_string_literal: true

module DemoWidgets
  class TopBudgetMovies < Bali::Widget::ListBase
    include WidgetRoutes

    default_size :large

    list { Movie.budgeted.order(budget: :desc) }

    row do |r|
      r.title :name
      r.subtitle { |movie| join(movie.genre, currency(movie.budget)) }
      r.href { |movie| admin_movie_path(movie) }
    end

    view_all_path { admin_movies_path }

    private

    def currency(amount)
      ActionController::Base.helpers.number_to_currency(amount, precision: 0)
    end
  end
end
