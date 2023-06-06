# frozen_string_literal: true

class TableController < ApplicationController
  def bulk_action
    selected_ids = JSON.parse(params[:selected_ids])

    Rails.logger.info("Bulk Action IDS: #{selected_ids}")
  end
end
