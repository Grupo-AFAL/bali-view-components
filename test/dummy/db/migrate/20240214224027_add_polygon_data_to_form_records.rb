class AddPolygonDataToFormRecords < ActiveRecord::Migration[7.1]
  def change
    add_column :form_records, :polygon_data, :jsonb, default: {}
  end
end
