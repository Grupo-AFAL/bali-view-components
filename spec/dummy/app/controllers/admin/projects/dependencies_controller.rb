# frozen_string_literal: true

module Admin
  module Projects
    # Dependency half of the Bali::Gantt mutation contract (#705) — see
    # SchedulesController for the item half. Both mutations answer with the
    # COMPLETE recalculated document; validation failures (self-link, cycle,
    # duplicate) come back as 422 { errors: [...] } so the island rolls back
    # its optimistic edge.
    class DependenciesController < BaseController
      # Same dummy-only reason as SchedulesController: Lookbook previews have
      # no CSRF token to send. Hosts keep forgery protection on.
      skip_forgery_protection

      def create
        dependency = params.require(:dependency)
        record = TaskDependency.new(
          predecessor: project.tasks.find_by(id: dependency[:predecessor_id]),
          successor: project.tasks.find_by(id: dependency[:successor_id]),
          lag_days: dependency[:lag_days] || 0
        )
        if record.predecessor.nil? || record.successor.nil?
          return head :not_found
        end

        if record.save
          render json: gantt_document
        else
          render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        record = TaskDependency.where(predecessor_id: project.tasks.select(:id))
                               .find_by(id: params[:id])
        return head :not_found if record.nil?

        record.destroy!
        render json: gantt_document
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
