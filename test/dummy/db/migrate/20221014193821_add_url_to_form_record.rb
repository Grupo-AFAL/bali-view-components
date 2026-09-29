class AddUrlToFormRecord < ActiveRecord::Migration[7.0]
  def change
    add_column :form_records, :url, :string
  end
end
