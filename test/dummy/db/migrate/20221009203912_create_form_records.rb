class CreateFormRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :form_records do |t|
      t.boolean :boolean
      t.decimal :currency
      t.date :date
      t.datetime :datetime
      t.date :end_date
      t.string :email
      t.decimal :number
      t.string :password
      t.decimal :percentage
      t.text :text
      t.integer :select
      t.integer :time

      t.timestamps
    end
  end
end
