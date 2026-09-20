class AddIndieToMovies < ActiveRecord::Migration[8.0]
  def change
    add_column :movies, :indie, :boolean
  end
end
