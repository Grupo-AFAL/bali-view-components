# frozen_string_literal: true

module AdminHelper
  def movie_status_color(movie)
    movie.done? ? :success : :warning
  end

  def studio_status_color(studio)
    case studio.status
    when "active" then :success
    when "inactive" then :error
    else :warning
    end
  end
end
