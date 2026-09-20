# frozen_string_literal: true

module DemoWidgets
  class RecentMovies < Bali::Widget::ListBase
    include WidgetRoutes

    default_size :medium
    # A slower interval than ProjectProgress, so the demo shows two tiles on
    # their own clocks rather than one shared tick.
    refresh_every 60.seconds

    list { Movie.order(created_at: :desc) }

    row do |r|
      r.title :name
      r.subtitle { |movie| join(movie.genre, movie.status.humanize) }
      r.href { |movie| admin_movie_path(movie) }
    end

    view_all_path { admin_movies_path }
  end
end
