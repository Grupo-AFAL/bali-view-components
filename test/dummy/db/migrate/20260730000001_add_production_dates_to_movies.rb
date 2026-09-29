# frozen_string_literal: true

# Fechas reales de producción para que el tercer modo del listado de películas sea
# honesto: los paneles de admin/analytics las inventaban en la vista.
class AddProductionDatesToMovies < ActiveRecord::Migration[8.1]
  def change
    add_column :movies, :production_starts_on, :date
    add_column :movies, :production_ends_on, :date
  end
end
