class AddIndieToStudios < ActiveRecord::Migration[8.1]
  def change
    add_column :studios, :indie, :boolean, default: false
  end
end
