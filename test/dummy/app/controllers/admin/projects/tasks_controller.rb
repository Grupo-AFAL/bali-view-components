# frozen_string_literal: true

module Admin
  module Projects
    class TasksController < BaseController
      def update
        @task = Task.find(params[:id])
        new_status = task_params[:status]
        new_position = task_params[:position].to_i - 1 # SortableJS sends 1-indexed

        Task.transaction do
          # Temporarily remove from ordering
          @task.update!(status: new_status, position: -1)

          # Get current order of the target column (excluding moved task)
          ordered_ids = @task.project.tasks
                             .where(status: new_status)
                             .where.not(id: @task.id)
                             .order(:position)
                             .pluck(:id)

          # Insert at target position
          ordered_ids.insert(new_position, @task.id)

          # Batch update positions with single query
          updates = ordered_ids.each_with_index.map { |id, i| "WHEN #{id} THEN #{i}" }
          Task.where(id: ordered_ids).update_all("position = CASE id #{updates.join(' ')} END")
        end

        head :ok
      end

      private

      def task_params
        params.expect(task: [ :position, :status ])
      end
    end
  end
end
