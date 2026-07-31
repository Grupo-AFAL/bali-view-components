# frozen_string_literal: true

# Fechas reales de producción para que el modo timeline del listado de películas sea
# honesto: el Gantt de admin/analytics las inventaba en la vista.
class AddProductionDatesToMovies < ActiveRecord::Migration[8.1]
  def change
    add_column :movies, :production_starts_on, :date
    add_column :movies, :production_ends_on, :date
  end
end
