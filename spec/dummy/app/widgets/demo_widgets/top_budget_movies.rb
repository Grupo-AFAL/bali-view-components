# frozen_string_literal: true

module DemoWidgets
  class TopBudgetMovies < Bali::Widget::ListBase
    include WidgetRoutes

    default_size :large

    order_by({ budget: :desc })
    row_title :name
    row_subtitle { |movie| subtitle(movie.genre, currency(movie.budget)) }
    row_href { |movie| admin_movie_path(movie) }
    view_all_path { admin_movies_path }

    # `Movie.budgeted` is the model's own scope (`budget: 1..`) — reused rather
    # than re-spelled, the way a host widget leans on its domain's scopes.
    def scope = Movie.budgeted

    private

    def currency(amount)
      ActionController::Base.helpers.number_to_currency(amount, precision: 0)
    end
  end
end
