# frozen_string_literal: true

module Admin
  module Movies
    class BulkActionsController < BaseController
      include BulkActionable

      private

      def after_bulk_action_path
        admin_movies_path
      end
    end
  end
end
