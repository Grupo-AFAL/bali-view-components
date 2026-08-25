# frozen_string_literal: true

module DemoWidgets
  class RecentMovies < Bali::Widget::Base
    include Rails.application.routes.url_helpers

    sized :medium

    def call
      list_from(Movie.order(created_at: :desc), view_all_path: admin_movies_path)
    end

    private

    def row(movie)
      Bali::Widget::Row.new(
        title: movie.name,
        subtitle: subtitle(movie.genre, movie.status.humanize),
        href: admin_movie_path(movie)
      )
    end
  end
end
