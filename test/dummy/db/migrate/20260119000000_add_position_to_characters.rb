# frozen_string_literal: true

class AddPositionToCharacters < ActiveRecord::Migration[8.0]
  def change
    add_column :characters, :position, :integer, default: 0
  end
end
