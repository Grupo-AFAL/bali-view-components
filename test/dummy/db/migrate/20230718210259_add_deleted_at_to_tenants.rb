class AddDeletedAtToTenants < ActiveRecord::Migration[7.0]
  def change
    add_column :tenants, :deleted_at, :datetime
  end
end
