# frozen_string_literal: true

module DemoWidgets
  class TopBudgetMovies < Bali::Widget::Base
    include Rails.application.routes.url_helpers

    sized :large

    def call
      list_from(scope, view_all_path: admin_movies_path)
    end

    private

    # `Movie.budgeted` is the model's own scope (`budget: 1..`) — reused here
    # rather than re-spelled, the same way a host widget would lean on its
    # domain's existing scopes instead of inventing widget-only ones.
    def scope
      Movie.budgeted.order(budget: :desc)
    end

    def row(movie)
      Bali::Widget::Row.new(
        title: movie.name,
        subtitle: subtitle(movie.genre, currency(movie.budget)),
        href: admin_movie_path(movie)
      )
    end

    def currency(amount)
      ActionController::Base.helpers.number_to_currency(amount, precision: 0)
    end
  end
end
