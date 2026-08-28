# frozen_string_literal: true

module DemoWidgets
  class RecentMovies < Bali::Widget::ListBase
    include WidgetRoutes

    default_size :medium

    list { Movie.order(created_at: :desc) }

    row do |r|
      r.title :name
      r.subtitle { |movie| join(movie.genre, movie.status.humanize) }
      r.href { |movie| admin_movie_path(movie) }
    end

    view_all_path { admin_movies_path }
  end
end
