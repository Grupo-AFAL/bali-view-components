# frozen_string_literal: true

module BulkActionable
  extend ActiveSupport::Concern

  BULK_ACTIONS = %w[delete mark_done mark_draft].freeze

  def create
    movie_ids = params[:movie_ids]

    if movie_ids.blank?
      redirect_to after_bulk_action_path, alert: "No movies selected."
      return
    end

    action = params[:bulk_action]
    unless BULK_ACTIONS.include?(action)
      redirect_to after_bulk_action_path, alert: "Unknown action."
      return
    end

    movies = Movie.where(id: movie_ids)
    count = movies.count

    case action
    when "delete"     then movies.destroy_all
    when "mark_done"  then movies.update_all(status: :done)
    when "mark_draft" then movies.update_all(status: :draft)
    end

    redirect_to after_bulk_action_path, notice: "#{count} movie(s) #{action.humanize.downcase}."
  end
end
