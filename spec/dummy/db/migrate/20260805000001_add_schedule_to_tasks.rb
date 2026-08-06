# frozen_string_literal: true

# Cronograma real para las tareas del dummy (#704): el Gantt de admin/projects
# necesita fechas, fases (los grupos del contrato), hitos y avance de verdad —
# inventarlos en la vista mentiría sobre lo que el componente recibe.
class AddScheduleToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :start_date, :date
    add_column :tasks, :due_date, :date
    add_column :tasks, :phase, :string
    add_column :tasks, :milestone, :boolean, default: false, null: false
    add_column :tasks, :percent_complete, :integer
  end
end
