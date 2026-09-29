class CreateStudios < ActiveRecord::Migration[8.0]
  def change
    create_table :studios do |t|
      t.string :name
      t.string :country
      t.integer :status
      t.string :size
      t.integer :founded_year

      t.timestamps
    end
  end
end
