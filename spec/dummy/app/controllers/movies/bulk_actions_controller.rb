# frozen_string_literal: true

module Movies
  class BulkActionsController < ApplicationController
    include BulkActionable

    private

    def after_bulk_action_path
      movies_path
    end
  end
end
