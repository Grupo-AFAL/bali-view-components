# frozen_string_literal: true

module BulkActionable
  extend ActiveSupport::Concern

  def create
    movie_ids = params[:movie_ids]

    if movie_ids.blank?
      redirect_to after_bulk_action_path, alert: "No movies selected."
      return
    end

    movies = Movie.where(id: movie_ids)

    notice = case params[:bulk_action]
    when "delete"
               movies.destroy_all
               "#{movie_ids.size} movie(s) deleted."
    when "mark_done"
               movies.update_all(status: :done)
               "#{movie_ids.size} movie(s) marked as done."
    when "mark_draft"
               movies.update_all(status: :draft)
               "#{movie_ids.size} movie(s) marked as draft."
    end

    redirect_to after_bulk_action_path, notice: notice
  end
end
