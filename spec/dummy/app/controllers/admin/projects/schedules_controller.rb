# frozen_string_literal: true

module Admin
  module Projects
    # Reference (executable) implementation of the Bali::Gantt mutation
    # contract (#705, decisions D15/D17) — what the island's scheduleClient.js
    # talks to:
    #
    #   GET   → the complete document (the island re-syncs after a 404)
    #   PATCH { item: { id, starts_on, duration_days } }
    #         → 200 with the COMPLETE recalculated document (reconcile),
    #           404 when the item no longer exists (client re-GETs),
    #           422 { errors: [...] } on validation failure (client rolls back)
    #
    # The server is authoritative: it recomputes rollups and the critical path
    # on every mutation and always answers with the whole document, never a
    # patch.
    class SchedulesController < BaseController
      # Dummy-only: the island exercises these endpoints from Lookbook
      # previews, and Lookbook's preview controller does not enable forgery
      # protection — `csrf_meta_tags` in the preview layout emits nothing, so
      # request.js has no token to send. A real host serves the island from
      # its own pages and keeps CSRF protection on.
      skip_forgery_protection

      def show
        render json: gantt_document
      end

      def update
        item = params.require(:item)
        task = project.tasks.find_by(id: item[:id])
        return head :not_found if task.nil?

        starts_on = Date.iso8601(item.require(:starts_on))
        duration_days = Integer(item.require(:duration_days))
        if duration_days < 1
          return render json: { errors: [ 'duration_days must be at least 1' ] },
                        status: :unprocessable_entity
        end

        task.update!(start_date: starts_on, due_date: starts_on + duration_days - 1)
        render json: gantt_document
      rescue ArgumentError, Date::Error, ActionController::ParameterMissing
        render json: { errors: [ 'starts_on must be an ISO8601 date and duration_days an integer' ] },
               status: :unprocessable_entity
      end

      private

      def project
        @project ||= Project.find(params[:project_id])
      end

      def gantt_document
        ProjectGantt.new(project).to_h
      end
    end
  end
end
