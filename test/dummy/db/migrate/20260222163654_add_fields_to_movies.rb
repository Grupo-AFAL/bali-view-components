class AddFieldsToMovies < ActiveRecord::Migration[8.1]
  def change
    add_column :movies, :synopsis, :text
    add_column :movies, :rich_description, :text
    add_column :movies, :release_date, :date
    add_column :movies, :budget, :decimal
    add_column :movies, :contact_email, :string
    add_column :movies, :website_url, :string
    add_column :movies, :time_zone, :string
    add_column :movies, :rating, :decimal
  end
end
