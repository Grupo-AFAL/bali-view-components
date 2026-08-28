# frozen_string_literal: true

module DemoWidgets
  class TopBudgetMovies < Bali::Widget::ListBase
    include WidgetRoutes

    default_size :large

    list scope: Movie.budgeted, order_by: { budget: :desc }

    row_title :name
    row_subtitle { |movie| subtitle(movie.genre, currency(movie.budget)) }
    row_href { |movie| admin_movie_path(movie) }
    view_all_path { admin_movies_path }

    private

    def currency(amount)
      ActionController::Base.helpers.number_to_currency(amount, precision: 0)
    end
  end
end
