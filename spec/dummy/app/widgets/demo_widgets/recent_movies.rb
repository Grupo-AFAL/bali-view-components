# frozen_string_literal: true

module DemoWidgets
  class RecentMovies < Bali::Widget::ListBase
    include WidgetRoutes

    default_size :medium

    order_by({ created_at: :desc })
    row_title :name
    row_subtitle { |movie| subtitle(movie.genre, movie.status.humanize) }
    row_href { |movie| admin_movie_path(movie) }
    view_all_path { admin_movies_path }

    def scope = Movie.all
  end
end
